/*================================================================================
	
	----------------------------
	-*- [ZP] Class: Survivor -*-
	----------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fun>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <amx_settings_api>
#include <cs_maxspeed_api>
#include <cs_player_models_api>
#include <cs_weap_models_api>
#include <cs_ham_bots_api>
#include <zp50_core>
#include <zp50_gamemodes>

//Vars
new g_msgScreenFade, g_msgScreenShake, flash_sprite_index
//Knockback strengh and radius
new Float:KRADIUS=300.0, Float:KPOWER=2500.0
//Shockwave sprite
new flashwave[] = "sprites/shockwave.spr"

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Default models
new const models_survivor_player[][] = { "leet", "sas" }

new Array:g_models_survivor_player

#define PLAYERMODEL_MAX_LENGTH 32
#define MODEL_MAX_LENGTH 64

new g_models_survivor_weapon[MODEL_MAX_LENGTH] = "models/v_m249.mdl"
new const entclas[] = "survivor_shield"
new const model[] = "models/zombie_plague/aura8.mdl"

#define TASK_AURA 100
#define ID_AURA (taskid - TASK_AURA)

#define flag_get(%1,%2) (%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2) (flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))

#define ValidTouch(%1) ( is_user_alive(%1) && zp_core_is_zombie(%1) )

// CS Player CBase Offsets (win32)
const PDATA_SAFE = 2
const OFFSET_ACTIVE_ITEM = 373

// Weapon bitsums
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)
const GRENADES_WEAPONS_BIT_SUM = (1<<CSW_HEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_SMOKEGRENADE)

// Ammo Type Names for weapons
new const AMMOTYPE[][] = { "", "357sig", "", "762nato", "", "buckshot", "", "45acp", "556nato", "", "9mm", "57mm", "45acp",
			"556nato", "556nato", "556nato", "45acp", "9mm", "338magnum", "9mm", "556natobox", "buckshot",
			"556nato", "9mm", "762nato", "", "50ae", "556nato", "762nato", "", "57mm" }

// Max BP ammo for weapons
new const MAXBPAMMO[] = { -1, 52, -1, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120,
			30, 120, 200, 32, 90, 120, 90, 2, 35, 90, 90, -1, 100 }
			
			
new const survivor_weapons[][] = {"weapon_m249", "weapon_m4a1", "weapon_ak47", "weapon_xm1014"}
new const survivor_weapons_mdl[][] = {"models/v_m249.mdl", "models/v_m4a1.mdl", "models/v_ak47.mdl", "models/v_xm1014.mdl"}

#define PRIMARY_ONLY 1
#define SECONDARY_ONLY 2
#define GRENADES_ONLY 4

new Float:CampoColors[3] = 
{ 
	255.0 , // r
	0.0 ,   // g
	100.0     // b
}

new g_MaxPlayers
new g_IsSurvivor

new jump_left[33]

new Float:g_LastUseTime[33]

new cvar_survivor_health, cvar_survivor_base_health, cvar_survivor_speed, cvar_survivor_gravity
new cvar_survivor_glow
new cvar_survivor_aura, cvar_survivor_aura_color_R, cvar_survivor_aura_color_G, cvar_survivor_aura_color_B
new cvar_survivor_weapon, cvar_survivor_weapon_block, cvar_shield_cooldown, cvar_shield_length

public plugin_init()
{
	register_plugin("[ZP] Class: Survivor", ZP_VERSION_STRING, "ZP Dev Team")
	
	register_clcmd("drop", "clcmd_drop")
	RegisterHam(Ham_Touch, "weaponbox", "fw_TouchWeapon")
	RegisterHam(Ham_Touch, "armoury_entity", "fw_TouchWeapon")
	RegisterHam(Ham_Touch, "weapon_shield", "fw_TouchWeapon")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled")
	
	register_clcmd("+use", "func_nade_explode")
	register_concmd("+use", "func_nade_explode")
	
	register_forward(FM_CmdStart, "CmdStart");
	register_forward(FM_Touch, "fw_touch")
	register_logevent("logevent_round_end", 2, "1=Round_End")
	register_forward(FM_EmitSound, "EmitSound");
	
//	register_event("HLTV", "NowaRunda", "a", "1=0", "2=0");
	
	g_MaxPlayers = get_maxplayers()
	
	cvar_survivor_health = register_cvar("zp_survivor_health", "0")
	cvar_survivor_base_health = register_cvar("zp_survivor_base_health", "100")
	cvar_survivor_speed = register_cvar("zp_survivor_speed", "0.95")
	cvar_survivor_gravity = register_cvar("zp_survivor_gravity", "1.25")
	cvar_survivor_glow = register_cvar("zp_survivor_glow", "1")
	cvar_survivor_aura = register_cvar("zp_survivor_aura", "1")
	cvar_survivor_aura_color_R = register_cvar("zp_survivor_aura_color_R", "0")
	cvar_survivor_aura_color_G = register_cvar("zp_survivor_aura_color_G", "0")
	cvar_survivor_aura_color_B = register_cvar("zp_survivor_aura_color_B", "150")
	cvar_survivor_weapon = register_cvar("zp_survivor_weapon", "weapon_m249")
	cvar_survivor_weapon_block = register_cvar("zp_survivor_weapon_block", "1")
	cvar_shield_cooldown = register_cvar("zp_surv_shield_cooldown", "24")
	cvar_shield_length = register_cvar("zp_surv_shield_length", "8")
	
	g_msgScreenFade = get_user_msgid("ScreenFade")
	g_msgScreenShake = get_user_msgid("ScreenShake")
}

public plugin_precache()
{
	// Initialize arrays
	g_models_survivor_player = ArrayCreate(PLAYERMODEL_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "SURVIVOR", g_models_survivor_player)
	
	// If we couldn't load from file, use and save default ones
	new index
	if (ArraySize(g_models_survivor_player) == 0)
	{
		for (index = 0; index < sizeof models_survivor_player; index++)
			ArrayPushString(g_models_survivor_player, models_survivor_player[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "SURVIVOR", g_models_survivor_player)
	}
	
	// Load from external file, save if not found
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Weapon Models", "V_WEAPON SURVIVOR", g_models_survivor_weapon, charsmax(g_models_survivor_weapon)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Weapon Models", "V_WEAPON SURVIVOR", g_models_survivor_weapon)
	
	
	// Precache models
	new player_model[PLAYERMODEL_MAX_LENGTH], model_path[128]
	for (index = 0; index < ArraySize(g_models_survivor_player); index++)
	{
		ArrayGetString(g_models_survivor_player, index, player_model, charsmax(player_model))
		formatex(model_path, charsmax(model_path), "models/player/%s/%s.mdl", player_model, player_model)
		precache_model(model_path)
		// Support modelT.mdl files
		formatex(model_path, charsmax(model_path), "models/player/%s/%sT.mdl", player_model, player_model)
		if (file_exists(model_path)) precache_model(model_path)
	}
	
	precache_model(g_models_survivor_weapon)
	precache_model(model)
	flash_sprite_index = precache_model(flashwave)
}

public plugin_natives()
{
	register_library("zp50_class_survivor")
	register_native("zp_class_survivor_get", "native_class_survivor_get")
	register_native("zp_class_survivor_set", "native_class_survivor_set")
	register_native("zp_class_survivor_get_count", "native_class_survivor_get_count")
}

public clcmd_drop(id)
{
	// Should sniper stick to his weapon?
	if (flag_get(g_IsSurvivor, id) && get_pcvar_num(cvar_survivor_weapon_block))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public client_disconnect(id)
{
	flag_unset(g_IsSurvivor, id)
	remove_task(id+TASK_AURA)
}

// Ham Weapon Touch Forward
public fw_TouchWeapon(weapon, id)
{
	// Should survivor stick to his weapon?
	if (get_pcvar_num(cvar_survivor_weapon_block) && is_user_alive(id) && flag_get(g_IsSurvivor, id))
		return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

// Ham Player Killed Forward
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	if (flag_get(g_IsSurvivor, victim))
	{
		// Remove survivor aura
		if (get_pcvar_num(cvar_survivor_aura))
			remove_task(victim+TASK_AURA)
	}
}

public zp_fw_core_spawn_post(id)
{
	if (flag_get(g_IsSurvivor, id))
	{
		// Remove survivor glow
		if (get_pcvar_num(cvar_survivor_glow))
			set_user_rendering(id)
		
		// Remove survivor aura
		if (get_pcvar_num(cvar_survivor_aura))
			remove_task(id+TASK_AURA)
		
		// Remove survivor weapon model
		new weapon_name[32]
		get_pcvar_string(cvar_survivor_weapon, weapon_name, charsmax(weapon_name))
		new weapon_id = get_weaponid(weapon_name)
		cs_reset_player_view_model(id, weapon_id)
		
		// Remove survivor flag
		flag_unset(g_IsSurvivor, id)
	}
}

public zp_fw_core_infect(id, attacker)
{
	if (flag_get(g_IsSurvivor, id))
	{
		// Remove survivor glow
		if (get_pcvar_num(cvar_survivor_glow))
			set_user_rendering(id)
		
		// Remove survivor aura
		if (get_pcvar_num(cvar_survivor_aura))
			remove_task(id+TASK_AURA)
		
		// Remove survivor weapon model
		new weapon_name[32]
		get_pcvar_string(cvar_survivor_weapon, weapon_name, charsmax(weapon_name))
		new weapon_id = get_weaponid(weapon_name)
		cs_reset_player_view_model(id, weapon_id)
		
		// Remove survivor flag
		flag_unset(g_IsSurvivor, id)
	}
}

public zp_fw_core_cure_post(id, attacker)
{
	// Apply Survivor attributes?
	if (!flag_get(g_IsSurvivor, id))
		return;
	
	// Health
	if (get_pcvar_num(cvar_survivor_health) == 0)
		set_user_health(id, get_pcvar_num(cvar_survivor_base_health) * GetAliveCount())
	else
		set_user_health(id, get_pcvar_num(cvar_survivor_health))
	
	// Gravity
	set_user_gravity(id, get_pcvar_float(cvar_survivor_gravity))
	
	// Speed (if value between 0 and 10, consider it a multiplier)
	cs_set_player_maxspeed_auto(id, get_pcvar_float(cvar_survivor_speed))
	
	// Apply survivor player model
	new player_model[PLAYERMODEL_MAX_LENGTH]
	ArrayGetString(g_models_survivor_player, random_num(0, ArraySize(g_models_survivor_player) - 1), player_model, charsmax(player_model))
	cs_set_player_model(id, player_model)
	
	// Apply survivor weapon model
/*	new weapon_name[32]
	get_pcvar_string(cvar_survivor_weapon, weapon_name, charsmax(weapon_name))
	new weapon_id = get_weaponid(weapon_name)*/
//	cs_set_player_view_model(id, weapon_id, g_models_survivor_weapon)
	
	// Survivor glow
	if (get_pcvar_num(cvar_survivor_glow))
		set_user_rendering(id, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 25)
	
	// Survivor aura task
	if (get_pcvar_num(cvar_survivor_aura))
		set_task(0.1, "survivor_aura", id+TASK_AURA, _, _, "b")
	
	// Strip current weapons and give survivor weapon
	strip_weapons(id, PRIMARY_ONLY)
	strip_weapons(id, SECONDARY_ONLY)
	strip_weapons(id, GRENADES_ONLY)
//	give_item(id, weapon_name)
//	ExecuteHamB(Ham_GiveAmmo, id, MAXBPAMMO[weapon_id], AMMOTYPE[weapon_id], MAXBPAMMO[weapon_id])
	MenuBroni(id);
	
	if (zp_gamemodes_get_current() != zp_gamemodes_get_id("Armageddon"))
		print_chatColor(id, "\g[Survivor] \nWcisnij E aby uzyc ochronnej bariery na %i sekund.", get_pcvar_num(cvar_shield_length))
}

public MenuBroni(id){
	new menu=menu_create("Choose survivor weapon","menu_Handle");
	
	menu_additem(menu,"M249");//item=0
	menu_additem(menu,"M4A1");//item=1
	menu_additem(menu,"AK47");//item=1
	menu_additem(menu,"XM1014");//item=1
	
	menu_display(id, menu, 0);
	return PLUGIN_HANDLED;
}

public menu_Handle(id, menu, item){
	new weapon_id;
	if(0 <= item <= 3){
		weapon_id = get_weaponid(survivor_weapons[item])
		give_item(id, survivor_weapons[item])
		ExecuteHamB(Ham_GiveAmmo, id, MAXBPAMMO[weapon_id], AMMOTYPE[weapon_id], MAXBPAMMO[weapon_id])
		cs_set_player_view_model(id, weapon_id, survivor_weapons_mdl[item])
	}
	else{
		new weapon_name[32]
		get_pcvar_string(cvar_survivor_weapon, weapon_name, charsmax(weapon_name))
		weapon_id = get_weaponid(weapon_name)
		give_item(id, weapon_name)
		ExecuteHamB(Ham_GiveAmmo, id, MAXBPAMMO[weapon_id], AMMOTYPE[weapon_id], MAXBPAMMO[weapon_id])
		cs_set_player_view_model(id, weapon_id, g_models_survivor_weapon)
	}
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public surv_use_skill(id)
{
	if (!is_user_alive(id) || !flag_get(g_IsSurvivor, id))
		return
	
//	if(get_gametime() - g_LastUseTime[id] < get_pcvar_float(cvar_shield_cooldown))
//		return
		
	new xd = floatround(halflife_time()-g_LastUseTime[id])
	new czas = get_pcvar_num(cvar_shield_cooldown)-xd
	if(halflife_time()-g_LastUseTime[id] <= get_pcvar_num(cvar_shield_cooldown))
	{
		print_chatColor(id, "\g[Survivor] \nBariera gotowa za %i sekund", czas)
	}
	else
		crear_ent(id)
}

public crear_ent(id) 
{	
	new iEntity = create_entity("info_target")
	
	if(!is_valid_ent(iEntity))
		return PLUGIN_HANDLED
	
	new Float: Origin[3] 
	entity_get_vector(id, EV_VEC_origin, Origin) 
	
	entity_set_string(iEntity, EV_SZ_classname, entclas)
	
	entity_set_vector(iEntity,EV_VEC_origin, Origin)
	entity_set_model(iEntity,model)
	entity_set_int(iEntity, EV_INT_solid, SOLID_TRIGGER)
	entity_set_size(iEntity, Float: {-100.0, -100.0, -100.0}, Float: {100.0, 100.0, 100.0})
	entity_set_int(iEntity, EV_INT_renderfx, kRenderFxGlowShell)
	entity_set_int(iEntity, EV_INT_rendermode, kRenderTransAlpha)
	entity_set_float(iEntity, EV_FL_renderamt, 50.0)
		
	entity_set_vector(iEntity, EV_VEC_rendercolor, CampoColors)
	
	set_task(get_pcvar_float(cvar_shield_length), "DeleteEntity", iEntity)
	
	g_LastUseTime[id] = get_gametime()
	
	return PLUGIN_CONTINUE
}

public fw_touch(ent, touched)
{
	if (!pev_valid(ent)) 
		return FMRES_IGNORED

	static entclass[32]
	pev(ent, pev_classname, entclass, 31)
	
	if (equali(entclass, entclas))
	{	
		if(ValidTouch(touched))
		{
			new Float:pos_ptr[3], Float:pos_ptd[3], Float:push_power = 7.5
			
			pev(ent, pev_origin, pos_ptr)
			pev(touched, pev_origin, pos_ptd)
			
			for(new i = 0; i < 3; i++)
			{
				pos_ptd[i] -= pos_ptr[i]
				pos_ptd[i] *= push_power
			}
			set_pev(touched, pev_velocity, pos_ptd)
			set_pev(touched, pev_impulse, pos_ptd)
		}
	}
	return PLUGIN_HANDLED
}

public remove_ent() 
{
	remove_entity_name(entclas)
}  

public DeleteEntity(entity)
{
	if(is_valid_ent(entity)) 
		remove_entity(entity)
}

public logevent_round_end()
{
	new g_MaxPlayers = get_maxplayers()
	
	for (new i = 1; i <= g_MaxPlayers; i++)
	{
		if(!is_user_alive(i)) continue
		
		if (flag_get(g_IsSurvivor, i))
			strip_weapons(i, PRIMARY_ONLY)
	}
}

public native_class_survivor_get(plugin_id, num_params)
{
	new id = get_param(1)
	
//	if (!is_user_connected(id))
//	{
//		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
//		return -1;
//	}
	
	return flag_get_boolean(g_IsSurvivor, id);
}

public native_class_survivor_set(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	if (flag_get(g_IsSurvivor, id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Player already a survivor (%d)", id)
		return false;
	}
	
	flag_set(g_IsSurvivor, id)
	zp_core_force_cure(id)
	return true;
}

public native_class_survivor_get_count(plugin_id, num_params)
{
	return GetSurvivorCount();
}

// Survivor aura task
public survivor_aura(taskid)
{
	// Get player's origin
	static origin[3]
	get_user_origin(ID_AURA, origin)
	
	// Colored Aura
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_DLIGHT) // TE id
	write_coord(origin[0]) // x
	write_coord(origin[1]) // y
	write_coord(origin[2]) // z
	write_byte(50) // radius
	write_byte(get_pcvar_num(cvar_survivor_aura_color_R)) // r
	write_byte(get_pcvar_num(cvar_survivor_aura_color_G)) // g
	write_byte(get_pcvar_num(cvar_survivor_aura_color_B)) // b
	write_byte(2) // life
	write_byte(0) // decay rate
	message_end()
}

// Get Alive Count -returns alive players number-
GetAliveCount()
{
	new iAlive, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id))
			iAlive++
	}
	
	return iAlive;
}

// Get Survivor Count -returns alive survivors number-
GetSurvivorCount()
{
	new iSurvivors, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id) && flag_get(g_IsSurvivor, id))
			iSurvivors++
	}
	
	return iSurvivors;
}

// Strip primary/secondary/grenades
stock strip_weapons(id, stripwhat)
{
	// Get user weapons
	new weapons[32], num_weapons, index, weaponid
	get_user_weapons(id, weapons, num_weapons)
	
	// Loop through them and drop primaries or secondaries
	for (index = 0; index < num_weapons; index++)
	{
		// Prevent re-indexing the array
		weaponid = weapons[index]
		
		if ((stripwhat == PRIMARY_ONLY && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM))
		|| (stripwhat == SECONDARY_ONLY && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM))
		|| (stripwhat == GRENADES_ONLY && ((1<<weaponid) & GRENADES_WEAPONS_BIT_SUM)))
		{
			// Get weapon name
			new wname[32]
			get_weaponname(weaponid, wname, charsmax(wname))
			
			// Strip weapon and remove bpammo
			ham_strip_weapon(id, wname)
			cs_set_user_bpammo(id, weaponid, 0)
		}
	}
}

stock ham_strip_weapon(index, const weapon[])
{
	// Get weapon id
	new weaponid = get_weaponid(weapon)
	if (!weaponid)
		return false;
	
	// Get weapon entity
	new weapon_ent = fm_find_ent_by_owner(-1, weapon, index)
	if (!weapon_ent)
		return false;
	
	// If it's the current weapon, retire first
	new current_weapon_ent = fm_cs_get_current_weapon_ent(index)
	new current_weapon = pev_valid(current_weapon_ent) ? cs_get_weapon_id(current_weapon_ent) : -1
	if (current_weapon == weaponid)
		ExecuteHamB(Ham_Weapon_RetireWeapon, weapon_ent)
	
	// Remove weapon from player
	if (!ExecuteHamB(Ham_RemovePlayerItem, index, weapon_ent))
		return false;
	
	// Kill weapon entity and fix pev_weapons bitsum
	ExecuteHamB(Ham_Item_Kill, weapon_ent)
	set_pev(index, pev_weapons, pev(index, pev_weapons) & ~(1<<weaponid))
	return true;
}

// Get User Current Weapon Entity
stock fm_cs_get_current_weapon_ent(id)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(id) != PDATA_SAFE)
		return -1;
	
	return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM);
}

stock print_chatColor(id,const input[], any:...)
{
	new msg[191], players[32], count = 1;
	vformat(msg,190,input,3);
	replace_all(msg,190,"\g","^4");// green
	replace_all(msg,190,"\n","^1");// normal
	replace_all(msg,190,"\t","^3");// team
	
	if (id) players[0] = id; else get_players(players,count,"ch");
	for (new i=0;i<count;i++)
	if (is_user_connected(players[i]))
	{
		message_begin(MSG_ONE_UNRELIABLE,get_user_msgid("SayText"),_,players[i]);
		write_byte(players[i]);
		write_string(msg);
		message_end();
	}
} 

public EmitSound(id, iChannel, sound[], Float:fVol, Float:fAttn, iFlags, iPitch ) 
{
	if(equal(sound, "common/wpn_denyselect.wav"))
	{
		func_nade_explode(id);
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public NowaRunda()
{
	new iEnt = find_ent_by_class(-1, "survivor_shield");
	while(iEnt > 0) 
	{
		remove_entity(iEnt);
		iEnt = find_ent_by_class(iEnt, "survivor_shield");	
	}
}

public CmdStart(id, uc_handle)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED;
		
	new button = get_uc(uc_handle, UC_Buttons);
	new oldbutton = get_user_oldbutton(id);
	new flags = get_entity_flags(id);
	
	if(flag_get(g_IsSurvivor, id))
	{
		if((button & IN_JUMP) && !(flags & FL_ONGROUND) && !(oldbutton & IN_JUMP) && jump_left[id] > 0)
		{
			jump_left[id]--
			new Float:velocity[3];
			entity_get_vector(id,EV_VEC_velocity,velocity);
			velocity[2] = random_float(265.0,285.0);
			entity_set_vector(id,EV_VEC_velocity,velocity);
		}
		else if(flags & FL_ONGROUND)
		{
			if (jump_left[id] == 0)
			jump_left[id] = 1
		}
	}
	return FMRES_IGNORED;
}

public func_nade_explode(id){
	
	/*Blocked explode, your code goes here*/
		
	if (!is_user_alive(id) || !flag_get(g_IsSurvivor, id))
		return;
		
	new const Survivor[] = "Survivor Mode" 
	new SurvivorID = zp_gamemodes_get_id(Survivor)
	new xd = floatround(halflife_time()-g_LastUseTime[id])
	new czas;
	if(zp_gamemodes_get_current() == SurvivorID)
	{
		if(halflife_time()-g_LastUseTime[id] <= get_pcvar_num(cvar_shield_cooldown))
		{
			czas = get_pcvar_num(cvar_shield_cooldown)-xd
			print_chatColor(id, "\g[Survivor] \nBariera gotowa za %i sekund", czas)
			return;
		}
	}
	else
	{
		if(halflife_time()-g_LastUseTime[id] <= get_pcvar_num(cvar_shield_cooldown)*2)
		{
			czas = get_pcvar_num(cvar_shield_cooldown)*2-xd
			print_chatColor(id, "\g[Survivor] \nBariera gotowa za %i sekund", czas)
			return;
		}
	}

	g_LastUseTime[id] = get_gametime()
	
	SkillBariera(id);
	set_task(0.2, "SkillBariera", id);
	set_task(0.4, "SkillBariera", id);
}

public SkillBariera(id)
{
	//Making Shockwave
	flashbang_explode(id);

	//Knockback effect, calculation from hlsdk
	static Float:originF[3]
	pev(id, pev_origin, originF)
	static victim
	victim = -1
	new Float:fOrigin[3],Float:fDistance,Float:fDamage
	while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, originF, KRADIUS)) != 0){
		if (!is_user_alive(victim) || victim == id) continue
		if(!zp_core_is_zombie(victim)) continue;
		ScreenShake(victim)
		pev(victim, pev_origin, fOrigin)
		fDistance = get_distance_f(fOrigin, originF)
		fDamage = KPOWER - floatmul(KPOWER, floatdiv(fDistance, KRADIUS))//get the damage value
		fDamage *= EstimateDamage(originF, victim, 0)
		if ( fDamage < 0 ) continue
		CreateBombKnockBack(victim,originF,fDamage,KPOWER)
	}
}
public FlashEvent(id){
	message_begin(MSG_ONE, g_msgScreenFade, {0,0,0}, id)
	write_short(1)
	write_short(1)
	write_short(1)
	write_byte(0)
	write_byte(0)
	write_byte(0)
	write_byte(255)
	message_end()
}
public flashbang_explode(greindex){
	if(!pev_valid(greindex)) return;
	static Float:Orig[3];
	pev(greindex,pev_origin,Orig);
	ShockWave(Orig, 5, 20, 1000.0, {135, 206, 250})
}
//Nice Shockwave (from Alexander 3 public NPC)
stock ShockWave(Float:Orig[3], Life, Width, Float:Radius, Color[3]){
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Orig, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, Orig[0]) // x
	engfunc(EngFunc_WriteCoord, Orig[1]) // y
	engfunc(EngFunc_WriteCoord, Orig[2]) // z
	engfunc(EngFunc_WriteCoord, Orig[0]) // x axis
	engfunc(EngFunc_WriteCoord, Orig[1]) // y axis
	engfunc(EngFunc_WriteCoord, Orig[2]+Radius) // z axis
	write_short(flash_sprite_index) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(Life) // life (4)
	write_byte(Width) // width (20)
	write_byte(0) // noise
	write_byte(Color[0]) // red
	write_byte(Color[1]) // green
	write_byte(Color[2]) // blue
	write_byte(255) // brightness
	write_byte(0) // speed
	message_end()
}
//Knockback power and radius
stock CreateBombKnockBack(iVictim,Float:vAttacker[3],Float:fMulti,Float:fRadius){
	new Float:vVictim[3];
	pev(iVictim, pev_origin, vVictim);
	xs_vec_sub(vVictim, vAttacker, vVictim);
	xs_vec_mul_scalar(vVictim, fMulti * 0.7, vVictim);
	xs_vec_mul_scalar(vVictim, fRadius / xs_vec_len(vVictim), vVictim);
	set_pev(iVictim, pev_velocity, vVictim);
}
stock ScreenShake(id, amplitude = 8, duration = 6, frequency = 18){
	message_begin(MSG_ONE_UNRELIABLE, g_msgScreenShake, _, id)
	write_short((1<<12)*amplitude)
	write_short((1<<12)*duration)
	write_short((1<<12)*frequency)
	message_end()
}
//Damaging only enemy team
stock Float:EstimateDamage(Float:fPoint[3], ent, ignored) {
	new Float:fOrigin[3]
	new tr
	new Float:fFraction
	pev(ent, pev_origin, fOrigin)
	engfunc(EngFunc_TraceLine, fPoint, fOrigin, DONT_IGNORE_MONSTERS, ignored, tr)
	get_tr2(tr, TR_flFraction, fFraction)
	if ( fFraction == 1.0 || get_tr2( tr, TR_pHit ) == ent )//no valid enity between the explode point & player
	return 1.0
	return 0.6//if has fraise, lessen blast hurt
}