#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <amx_settings_api>
#include <cs_weap_models_api>
#include <zombieplague>
#include <zp50_items>
#include <zp50_gamemodes>
#include <zp50_class_survivor>
#include <zp50_class_sniper>

new const gNazwaPluginu[] = "[ZP] Addon: Antidote Bomb";
new const gWersjaPluginu[] = "1.0";
new const gAutorPluginu[] = "MisieQ";

#define ITEM_NAME "Antidote Bomb"
#define ITEM_COST 15

#define MODEL_MAX_LENGTH 64
#define SOUND_MAX_LENGTH 64
#define SPRITE_MAX_LENGTH 64

native sprawdz_misje(id)
native dodaj_ile_juz(id, ile)
native get_user_xp(id)
native set_user_xp(id, amount)

new const ZP_SETTINGS_FILE[] = "zombieplague.ini"
new const sound_grenade_antidote_explode[][] = { "zombie_plague/grenade_antidote.wav" }
new const sound_grenade_antidote_player[][] = { "zombie_plague/player_antidote.wav" }
new g_model_grenade_antidote[MODEL_MAX_LENGTH] = "models/zombie_plague/v_grenade_antidote.mdl"
new g_sprite_grenade_trail[SPRITE_MAX_LENGTH] = "sprites/laserbeam.spr"
new g_sprite_grenade_ring[SPRITE_MAX_LENGTH] = "sprites/shockwave.spr"
new Array:g_sound_antidote_explode
new Array:g_sound_antidote_player
const Float:NADE_EXPLOSION_RADIUS = 240.0
const PEV_NADE_TYPE = pev_flTimeStepSound
const NADE_TYPE_ANTIDOTE = 6969
new g_pointer_exp
new g_exp

new g_ItemID, g_trailSpr, g_exploSpr, Antidote[33];
new g_AntidoteBombCounter, cvar_antidote_bomb_round_limit;

public plugin_init() {
	register_plugin(gNazwaPluginu, gWersjaPluginu, gAutorPluginu);
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0");
	
	register_forward(FM_SetModel, "fw_SetModel");
	RegisterHam(Ham_Think, "grenade", "fw_ThinkGrenade");
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHam(Ham_Item_Deploy, "weapon_hegrenade", "fw_ItemDeploy",1);
	
	g_ItemID = zp_items_register(ITEM_NAME, ITEM_COST);
	cvar_antidote_bomb_round_limit = register_cvar("zp_antidote_bomb_round_limit", "3");
	
	g_pointer_exp = get_cvar_pointer( "gxm_xp" );
	g_exp = get_pcvar_num(g_pointer_exp)
}

public plugin_precache()
{
	g_sound_antidote_explode = ArrayCreate(SOUND_MAX_LENGTH, 1)
	g_sound_antidote_player = ArrayCreate(SOUND_MAX_LENGTH, 1)
	
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "GRENADE ANTIDOTE EXPLODE", g_sound_antidote_explode)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "GRENADE ANTIDOTE PLAYER", g_sound_antidote_player)
	
	new index
	if (ArraySize(g_sound_antidote_explode) == 0)
	{
		for (index = 0; index < sizeof sound_grenade_antidote_explode; index++)
			ArrayPushString(g_sound_antidote_explode, sound_grenade_antidote_explode[index])
		
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "GRENADE ANTIDOTE EXPLODE", g_sound_antidote_explode)
	}
	if (ArraySize(g_sound_antidote_player) == 0)
	{
		for (index = 0; index < sizeof sound_grenade_antidote_player; index++)
			ArrayPushString(g_sound_antidote_player, sound_grenade_antidote_player[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "GRENADE ANTIDOTE PLAYER", g_sound_antidote_player)
	}

	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Weapon Models", "GRENADE ANTIDOTE", g_model_grenade_antidote, charsmax(g_model_grenade_antidote)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Weapon Models", "GRENADE ANTIDOTE", g_model_grenade_antidote)
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Grenade Sprites", "TRAIL", g_sprite_grenade_trail, charsmax(g_sprite_grenade_trail)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Grenade Sprites", "TRAIL", g_sprite_grenade_trail)
	if (!amx_load_setting_string(ZP_SETTINGS_FILE, "Grenade Sprites", "RING", g_sprite_grenade_ring, charsmax(g_sprite_grenade_ring)))
		amx_save_setting_string(ZP_SETTINGS_FILE, "Grenade Sprites", "RING", g_sprite_grenade_ring)
	
	new sound[SOUND_MAX_LENGTH]
	for (index = 0; index < ArraySize(g_sound_antidote_explode); index++)
	{
		ArrayGetString(g_sound_antidote_explode, index, sound, charsmax(sound))
		precache_sound(sound)
	}
	for (index = 0; index < ArraySize(g_sound_antidote_player); index++)
	{
		ArrayGetString(g_sound_antidote_player, index, sound, charsmax(sound))
		precache_sound(sound)
	}
	
	precache_model(g_model_grenade_antidote)
	g_trailSpr = precache_model(g_sprite_grenade_trail)
	g_exploSpr = precache_model(g_sprite_grenade_ring)
}

public client_disconnect(id)
{
    Antidote[id] = 0
}

public event_round_start()
{
	g_AntidoteBombCounter = 0
}

public zp_fw_items_select_pre(id, itemid, ignorecost)
{
	if (itemid != g_ItemID)
		return ZP_ITEM_AVAILABLE;
	
	if (zp_core_is_zombie(id) || zp_class_survivor_get(id) || zp_class_sniper_get(id))
		return ZP_ITEM_DONT_SHOW;
	
	static text[32]
	formatex(text, charsmax(text), "[%d/%d]", g_AntidoteBombCounter, get_pcvar_num(cvar_antidote_bomb_round_limit))
	zp_items_menu_text_add(text)
	
	
	if (g_AntidoteBombCounter >= get_pcvar_num(cvar_antidote_bomb_round_limit))
		return ZP_ITEM_NOT_AVAILABLE;

	return ZP_ITEM_AVAILABLE;
}

public zp_fw_items_select_post(id, itemid, ignorecost)
{
	if (itemid != g_ItemID)
		return;
	
	give_item(id, "weapon_hegrenade")
	Antidote[id] = 1
	g_AntidoteBombCounter++
}

public fw_ItemDeploy(wpn)
{
	if(Antidote[pev(wpn,pev_owner)])
		set_pev(pev(wpn,pev_owner),pev_viewmodel2,g_model_grenade_antidote)	
}

public fw_SetModel(entity, const model[])
{
	if (strlen(model) < 8)
		return;
	
	if (model[7] != 'w' || model[8] != '_')
		return;
	
	static Float:dmgtime
	pev(entity, pev_dmgtime, dmgtime)
	
	if (dmgtime == 0.0)
		return;
		
	if (zp_core_is_zombie(pev(entity, pev_owner)))
		return;
	
	if (model[9] == 'h' && model[10] == 'e')
	{
		if(Antidote[pev(entity, pev_owner)])
		{
			fm_set_rendering(entity, kRenderFxGlowShell, 0, 200, 0, kRenderNormal, 16);
		
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_BEAMFOLLOW) // TE id
			write_short(entity) // entity
			write_short(g_trailSpr) // sprite
			write_byte(10) // life
			write_byte(10) // width
			write_byte(255) // r
			write_byte(128) // g
			write_byte(0) // b
			write_byte(200) // brightness
			message_end()
		
			// Set grenade type on the thrown grenade entity
			set_pev(entity, PEV_NADE_TYPE, NADE_TYPE_ANTIDOTE)
		}
	}
}

public fw_ThinkGrenade(entity)
{
	if (!pev_valid(entity))
		return HAM_IGNORED;
	
	static Float:dmgtime
	pev(entity, pev_dmgtime, dmgtime)
	
	if (dmgtime > get_gametime())
		return HAM_IGNORED;
	
	switch (pev(entity, PEV_NADE_TYPE))
	{
		case NADE_TYPE_ANTIDOTE:
		{
			cure_explode(entity)
			return HAM_SUPERCEDE;
		}
	}
	
	return HAM_IGNORED;
}

public fw_PlayerKilled(victim, attacker, shouldgib)
{
    Antidote[victim] = 0	
}

cure_explode(ent)
{
	if (zp_gamemodes_get_current() == ZP_NO_GAME_MODE)
	{
		engfunc(EngFunc_RemoveEntity, ent)
		return;
	}
	
	static Float:origin[3]
	pev(ent, pev_origin, origin)
	
	create_blast(origin)
	
	static sound[SOUND_MAX_LENGTH]
	ArrayGetString(g_sound_antidote_explode, random_num(0, ArraySize(g_sound_antidote_explode) - 1), sound, charsmax(sound))
	emit_sound(ent, CHAN_WEAPON, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	new attacker = pev(ent, pev_owner)
	
	Antidote[attacker] = 0
	
	if (!is_user_connected(attacker) || zp_core_is_zombie(attacker))
	{
		engfunc(EngFunc_RemoveEntity, ent)
		return;
	}
	
	new victim = -1
	
	while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, origin, NADE_EXPLOSION_RADIUS)) != 0)
	{
		if (!is_user_alive(victim) || !zp_core_is_zombie(victim) || zp_core_is_first_zombie(victim) || zp_core_is_last_zombie(victim) || zp_get_user_nemesis(victim))
			continue;
		
		if (zp_core_get_zombie_count() == 1)
		{
//			ExecuteHamB(Ham_Killed, victim, attacker, 0)
			continue;
		}
		
		zp_core_cure(victim, attacker)
		
		set_user_xp(attacker, get_user_xp(attacker) + g_exp)
		
		if(sprawdz_misje(attacker) == 42)
			dodaj_ile_juz(attacker, 1)
		
		ArrayGetString(g_sound_antidote_player, random_num(0, ArraySize(g_sound_antidote_player) - 1), sound, charsmax(sound))
		emit_sound(victim, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}

	engfunc(EngFunc_RemoveEntity, ent)
}

create_blast(const Float:origin[3])
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, origin[0]) // x
	engfunc(EngFunc_WriteCoord, origin[1]) // y
	engfunc(EngFunc_WriteCoord, origin[2]) // z
	engfunc(EngFunc_WriteCoord, origin[0]) // x axis
	engfunc(EngFunc_WriteCoord, origin[1]) // y axis
	engfunc(EngFunc_WriteCoord, origin[2]+385.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(255) // red
	write_byte(128) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, origin[0]) // x
	engfunc(EngFunc_WriteCoord, origin[1]) // y
	engfunc(EngFunc_WriteCoord, origin[2]) // z
	engfunc(EngFunc_WriteCoord, origin[0]) // x axis
	engfunc(EngFunc_WriteCoord, origin[1]) // y axis
	engfunc(EngFunc_WriteCoord, origin[2]+470.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(255) // red
	write_byte(164) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, origin[0]) // x
	engfunc(EngFunc_WriteCoord, origin[1]) // y
	engfunc(EngFunc_WriteCoord, origin[2]) // z
	engfunc(EngFunc_WriteCoord, origin[0]) // x axis
	engfunc(EngFunc_WriteCoord, origin[1]) // y axis
	engfunc(EngFunc_WriteCoord, origin[2]+555.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(255) // red
	write_byte(200) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
}

stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
{
	static Float:color[3]
	color[0] = float(r)
	color[1] = float(g)
	color[2] = float(b)
	
	set_pev(entity, pev_renderfx, fx)
	set_pev(entity, pev_rendercolor, color)
	set_pev(entity, pev_rendermode, render)
	set_pev(entity, pev_renderamt, float(amount))
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
