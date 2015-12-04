#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <engine>
#include <fun>
#include <cstrike>
#include <zp50_core>
#include <zp50_items>

#define NADE_TYPE_PIPEBOMB 5688

const m_pPlayer = 41;
new const g_trailspr[] ="sprites/laserbeam.spr";
new const g_firespr[] = "sprites/zerogxplode.spr";
new const g_sound[] = "zombie_plague/pipe_beep.wav";
new const g_ringspr[] = "sprites/shockwave.spr";
new const g_vmodel[] = "models/zombie_plague/v_pipe.mdl";
new const g_pmodel[] = "models/zombie_plague/p_pipe.mdl";
new const g_wmodel[] = "models/zombie_plague/w_pipe.mdl";
new cvar_radius, cvar_damage
new g_trail, g_fire, g_MaxPlayers, g_pipe, bool: g_has_pipe[33]
new cvar_duration
new g_ring

public plugin_init()
{
	register_plugin("[ZP] Extra Item: Pipe Bomb", "1.0", "lambda");
	register_forward(FM_SetModel,"fw_SetModel", 1);
	RegisterHam(Ham_Think, "grenade", "fw_ThinkGren");
	RegisterHam(Ham_Item_Deploy, "weapon_smokegrenade", "fw_smDeploy", 1);
	
	// Cvars
	cvar_radius = register_cvar ( "zp_pipe_radius", "500");
	cvar_damage = register_cvar("zp_pipe_damage", "1400.0");
	cvar_duration = register_cvar("zp_pipe_duration", "4.0");
	
	g_pipe = zp_items_register("VIP Pipe Bomb", 40)
	
	g_MaxPlayers = get_maxplayers()
}

public plugin_precache()
{
	precache_model(g_vmodel);
	precache_model(g_pmodel);
	precache_model(g_wmodel);
	precache_sound(g_sound);
	g_fire = precache_model(g_firespr);
	g_trail = precache_model(g_trailspr);
	g_ring = precache_model(g_ringspr);
}

public plugin_natives()
{
					// Player natives //
	register_native("daj_pipe", "native_daj_pipe", 1);
}

public native_daj_pipe(id)
{
	g_has_pipe[id] = true;
	new was = cs_get_user_bpammo(id, CSW_SMOKEGRENADE);
	
	if(was >= 1)
		cs_set_user_bpammo(id, CSW_SMOKEGRENADE, was + 1);
	else
		give_item(id, "weapon_smokegrenade");
	
	replace_models(id);
}

public replace_models(id)
{
	if(get_user_weapon(id) == CSW_SMOKEGRENADE)
	{
		set_pev(id, pev_viewmodel2, g_vmodel);
		set_pev(id, pev_weaponmodel2, g_pmodel);
	}
}

public fw_smDeploy(const iEntity)
{
	if(pev_valid(iEntity) != 2)
		return HAM_IGNORED;
    
	new id = get_pdata_cbase(iEntity, m_pPlayer, 4);
    
	if(g_has_pipe[id] && !zp_core_is_zombie(id) && is_user_alive(id))
	{
		set_pev(id, pev_viewmodel2, g_vmodel);
		set_pev(id, pev_weaponmodel2, g_pmodel);
	}
    
	return HAM_IGNORED;
}

public zp_fw_items_select_pre(id, itemid)
{
	if(itemid != g_pipe)
		return ZP_ITEM_AVAILABLE

	if (zp_core_is_zombie(id))
	return ZP_ITEM_DONT_SHOW
	
	if (g_has_pipe[id])
	return ZP_ITEM_NOT_AVAILABLE
	
	return ZP_ITEM_AVAILABLE
}

public zp_fw_items_select_post(id, item)
{
	if(item == g_pipe)
	{
		g_has_pipe[id] = true;
		new was = cs_get_user_bpammo(id, CSW_SMOKEGRENADE);

		if(was >= 1)
			cs_set_user_bpammo(id, CSW_SMOKEGRENADE, was + 1);
		else
			give_item(id, "weapon_smokegrenade");
		
		replace_models(id);
		client_print(id, print_chat, "[ZM EXP] Kupiles PIPE BOMBE! Wybierz granat dymny aby z niej skorzystac. Celuj w Zombie :)")
	}
	
	return PLUGIN_CONTINUE;
}

public client_connect(id)
{
	g_has_pipe[id] = false
}

public client_disconnect(id)
{
	g_has_pipe[id] = false
}

public zp_fw_core_infect_post(id)
{
	g_has_pipe[id] = false;
}
		
public zp_fw_core_cure_post(id)
{
	g_has_pipe[id] = false;
}

public fw_SetModel(entity, const model[])
{
	static owner;
	owner = pev(entity, pev_owner);
	
	static Float:dmgtime
	pev(entity, pev_dmgtime, dmgtime)
	
	if(!pev_valid(entity) || !dmgtime || !g_has_pipe[owner])
		return FMRES_IGNORED;
	
	if (model[9] == 's' && model[10] == 'm')
	{
		entity_set_model(entity, g_wmodel);
		
		set_rendering(entity, kRenderFxGlowShell, 128, 0, 0, kRenderNormal, 16);
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_BEAMFOLLOW) // TE id
		write_short(entity) // entity
		write_short(g_trail) // sprite
		write_byte(10) // life
		write_byte(10) // width
		write_byte(128) // r
		write_byte(0) // g
		write_byte(0) // b
		write_byte(255) // brightness
		message_end()
		
		set_pev(entity, pev_flTimeStepSound, NADE_TYPE_PIPEBOMB)
		
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public fw_ThinkGren(entity) // Grenade think event
{
	if (!pev_valid(entity))
		return HAM_IGNORED;
		
	static owner;
	owner = pev(entity, pev_owner);
	
	static Float:dmgtime	
	pev(entity, pev_dmgtime, dmgtime)
	
	new duration1 = get_pcvar_num(cvar_duration)
	new Float:duration2 = float(duration1)
	
	if (!g_has_pipe[owner] || dmgtime > get_gametime())
		return HAM_IGNORED;
	
	if(pev(entity, pev_flTimeStepSound) == NADE_TYPE_PIPEBOMB)
	{
		g_has_pipe[owner] = false
		set_task(0.1, "hook", entity, _, _, "b");
		set_task(4.0, "deleteGren", entity)
		
		new Float:originF[3]
		pev(entity, pev_origin, originF);
		
		light(originF, duration1);
		return HAM_SUPERCEDE
	}
	
	return HAM_IGNORED;
}

public hook(entity)
{
	if (!pev_valid(entity))
	{
		remove_task(entity)
		return
	}
	
	
	static Float:entOrigin[3], flOrigin[3], PlayerPos[3], distance
	pev(entity, pev_origin, entOrigin);
	
	flOrigin[0] = floatround(entOrigin[0])
	flOrigin[1] = floatround(entOrigin[1])
	flOrigin[2] = floatround(entOrigin[2])

	for (new i = 1; i <= g_MaxPlayers; i++)
	{
		if(!is_user_alive(i) || !zp_core_is_zombie(i))
			continue
		
		get_user_origin(i, PlayerPos)
		
		distance = get_distance(PlayerPos, flOrigin)
		
		set_task(0.1, "beep", entity, _, _, "b");
		
		if (distance <= get_pcvar_num(cvar_radius)) 
		{
			new Float:fl_Velocity[3]
			
			if (distance > 25)
			{
				new Float:fl_Time = distance / 650.0
				
				fl_Velocity[0] = (flOrigin[0] - PlayerPos[0]) / fl_Time
				fl_Velocity[1] = (flOrigin[1] - PlayerPos[1]) / fl_Time
				fl_Velocity[2] = (flOrigin[2] - PlayerPos[2]) / fl_Time
			}
			else
			{
				fl_Velocity[0] = 0.0
				fl_Velocity[1] = 0.0
				fl_Velocity[2] = 0.0
			}
			
			entity_set_vector(i, EV_VEC_velocity, fl_Velocity)
		}
	}
}

public deleteGren(entity)
{
	if (!pev_valid(entity))
		return
	
	new Float:originF[3]
	pev(entity, pev_origin, originF);
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, originF[0])
	engfunc(EngFunc_WriteCoord, originF[1])
	engfunc(EngFunc_WriteCoord, originF[2])
	write_short(g_fire) //sprite index
	write_byte(25) // scale in 0.1's
	write_byte(10) // framerate
	write_byte(0) // flags
	message_end()
	
	static flOrigin[3], PlayerPos[3], distance
	pev(entity, pev_origin, originF);
	new attacker = pev(entity, pev_owner)
	
	flOrigin[0] = floatround(originF[0])
	flOrigin[1] = floatround(originF[1])
	flOrigin[2] = floatround(originF[2])
	
	for (new i = 1; i <= g_MaxPlayers; i++)
	{
		if(is_user_alive(i)) 
		{
			if(!is_user_alive(i) || !zp_core_is_zombie(i))
			continue
			
			get_user_origin(i, PlayerPos)
			
			distance = get_distance(PlayerPos, flOrigin)
			
			if (distance <= get_pcvar_num(cvar_radius)) 
			{
				if(get_user_health(i) - get_pcvar_float(cvar_damage) > 0)
					fakedamage(i, "Pipe Bomb", get_pcvar_float(cvar_damage), 256);
				else
					ExecuteHamB(Ham_Killed, i, attacker, 2)
					
				static Float: originP[3]
				pev(i, pev_origin, originP)
				
				originP[0] = (originF[0] - flOrigin[0]) * 10.0 
				originP[1] = (originP[1] - flOrigin[1]) * 10.0 
				originP[2] = (originP[2] - flOrigin[2]) + 550.0 - float(distance)
				
				set_pev(i, pev_velocity, originP)
			}
		}
	}
	
	remove_task(entity)
	remove_entity(entity)
}

public effect(const Float:originF[3]) // Explosion effect
{
	// Largest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+555.0) // z axis
	write_short(g_ring) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(128) // red
	write_byte(0) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	// Explosion sprite
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, originF[0])
	engfunc(EngFunc_WriteCoord, originF[1])
	engfunc(EngFunc_WriteCoord, originF[2])
	write_short(g_fire) //sprite index
	write_byte(25) // scale in 0.1's
	write_byte(10) // framerate
	write_byte(0) // flags
	message_end()
}

public light(const Float:originF[3], duration)  // Blast ring and small red light around nade from zombie_plague40.sma. Great thx, MeRcyLeZZ!!! ;)
{
	// Lighting
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, originF, 0);
	write_byte(TE_DLIGHT); // TE id
	engfunc(EngFunc_WriteCoord, originF[0]); // x
	engfunc(EngFunc_WriteCoord, originF[1]); // y
	engfunc(EngFunc_WriteCoord, originF[2]); // z
	write_byte(5); // radius
	write_byte(128); // r
	write_byte(0); // g
	write_byte(0); // b
	write_byte(51); //life
	write_byte((duration < 2) ? 3 : 0); //decay rate
	message_end();
	
	// Smallest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+385.0) // z axis
	write_short(g_ring) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(128) // red
	write_byte(0) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	// Medium ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+470.0) // z axis
	write_short(g_ring) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(128) // red
	write_byte(0) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	// Largest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+555.0) // z axis
	write_short(g_ring) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(128) // red
	write_byte(0) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
}

public beep(entity) // Plays loop beep sound before explosion
{
	//Bugfix
	if (!pev_valid(entity))
	{
		remove_task(entity);
		return;
	}
	
	emit_sound(entity, CHAN_WEAPON, g_sound, 1.0, ATTN_NORM, 0, PITCH_HIGH);
}

