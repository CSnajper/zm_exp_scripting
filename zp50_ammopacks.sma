/*================================================================================
	
	-----------------------
	-*- [ZP] Ammo Packs -*-
	-----------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fakemeta>
#include <zp50_core>
#include <zp50_class_zombie>
#include <zp50_class_human>

#define is_user_valid(%1) (1 <= %1 <= g_MaxPlayers)

#define TASK_HIDEMONEY 100
#define ID_HIDEMONEY (taskid - TASK_HIDEMONEY)

native sprawdz_misje(id)
native dodaj_ile_juz(id, ile)
native sprawdz_ile_wykonano(id)
native dodaj_ap_staty(id)

const OFFSET_CSTEAMS = 114

// CS Player PData Offsets (win32)
const PDATA_SAFE = 2
const OFFSET_CSMONEY = 115

const HIDE_MONEY_BIT = (1<<5)

#define MAXPLAYERS 32

// CS Teams
enum
{
	FM_CS_TEAM_UNASSIGNED = 0,
	FM_CS_TEAM_T,
	FM_CS_TEAM_CT,
	FM_CS_TEAM_SPECTATOR
}

const OFFSET_LINUX = 5 // offsets 5 higher in Linux builds

new g_MaxPlayers
new g_MsgHideWeapon, g_MsgCrosshair
new g_AmmoPacks[MAXPLAYERS+1]

new cvar_starting_ammo_packs, cvar_disable_money

const MAX_STATS_SAVED = 64 
// Temporary Database vars (used to restore players stats in case they get disconnected)
new db_name[MAX_STATS_SAVED][32] // player name
new db_ammopacks[MAX_STATS_SAVED] // ammo pack count
new db_zombieclass[MAX_STATS_SAVED] // zombie class
new db_humanclass[MAX_STATS_SAVED] // zombie class
new db_slot_i // additional saved slots counter (should start on maxplayers+1)
new g_playername[33][32] // player's name

new g_maxplayers;

public plugin_init()
{
	register_plugin("[ZP] Ammo Packs", ZP_VERSION_STRING, "ZP Dev Team")
	
	g_MaxPlayers = get_maxplayers()
	g_MsgHideWeapon = get_user_msgid("HideWeapon")
	g_MsgCrosshair = get_user_msgid("Crosshair")
	
	register_logevent("logevent_round_end", 2, "1=Round_End")
	
	cvar_starting_ammo_packs = register_cvar("zp_starting_ammo_packs", "5")
	cvar_disable_money = register_cvar("zp_disable_money", "0")
	
	register_event("ResetHUD", "event_reset_hud", "be")
	register_message(get_user_msgid("Money"), "message_money")
	
	g_maxplayers = get_maxplayers();
}

public plugin_natives()
{
	register_library("zp50_ammopacks")
	register_native("zp_ammopacks_get", "native_ammopacks_get")
	register_native("zp_ammopacks_set", "native_ammopacks_set")
}

public native_ammopacks_get(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return g_AmmoPacks[id];
}

public native_ammopacks_set(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_valid(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	new amount = get_param(2)
	
	g_AmmoPacks[id] = amount
	if(sprawdz_misje(id) == 20)
		dodaj_ile_juz(id, 1)
	dodaj_ap_staty(id)
	return true;
}

public client_putinserver(id)
{
	// Cache player's name
	get_user_name(id, g_playername[id], charsmax(g_playername[]))
	
	if(sprawdz_ile_wykonano(id) >= 4)
		g_AmmoPacks[id] = get_pcvar_num(cvar_starting_ammo_packs) + 1
	else g_AmmoPacks[id] = get_pcvar_num(cvar_starting_ammo_packs)
	load_stats(id)
}

public client_disconnect(id)
{
	save_stats(id)
	remove_task(id+TASK_HIDEMONEY)
}

public event_reset_hud(id)
{
	// Hide money?
	if (get_pcvar_num(cvar_disable_money))
		set_task(0.1, "task_hide_money", id+TASK_HIDEMONEY)
}

// Hide Player's Money Task
public task_hide_money(taskid)
{
	// Hide money
	message_begin(MSG_ONE, g_MsgHideWeapon, _, ID_HIDEMONEY)
	write_byte(HIDE_MONEY_BIT) // what to hide bitsum
	message_end()
	
	// Hide the HL crosshair that's drawn
	message_begin(MSG_ONE, g_MsgCrosshair, _, ID_HIDEMONEY)
	write_byte(0) // toggle
	message_end()
}

public message_money(msg_id, msg_dest, msg_entity)
{
	// Disable money setting enabled?
	if (!get_pcvar_num(cvar_disable_money))
		return PLUGIN_CONTINUE;
	
	fm_cs_set_user_money(msg_entity, 0)
	return PLUGIN_HANDLED;
}

// Set User Money
stock fm_cs_set_user_money(id, value)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(id) != PDATA_SAFE)
		return;
	
	set_pdata_int(id, OFFSET_CSMONEY, value)
}

// Save player's stats to database
/*save_stats(id)
{
	// Check whether there is another record already in that slot
	if (db_name[id][0] && !equal(g_playername[id], db_name[id]))
	{
		// If DB size is exceeded, write over old records
		if (db_slot_i >= sizeof db_name)
			db_slot_i = g_MaxPlayers+1
		
		// Move previous record onto an additional save slot
		copy(db_name[db_slot_i], charsmax(db_name[]), db_name[id])
		db_ammopacks[db_slot_i] = db_ammopacks[id]
		db_zombieclass[db_slot_i] = db_zombieclass[id]
		db_humanclass[db_slot_i] = db_humanclass[id]
		db_slot_i++
	}
	
	// Now save the current player stats
	copy(db_name[id], charsmax(db_name[]), g_playername[id]) // name
	db_ammopacks[id] = g_AmmoPacks[id] // ammo packs
	db_zombieclass[id] = zp_class_zombie_get_current(id)
	db_humanclass[id] = zp_class_human_get_current(id) // zombie class
}

// Load player's stats from database (if a record is found)
load_stats(id)
{
	// Look for a matching record
	static i
	for (i = 0; i < sizeof db_name; i++)
	{
		if (equal(g_playername[id], db_name[i]))
		{
			// Bingo!
			g_AmmoPacks[id] = db_ammopacks[i]
			zp_class_zombie_set_next(id, db_zombieclass[i])
			zp_class_human_set_next(id, db_humanclass[i])
			return;
		}
	}
}*/

save_stats(id)
{
	// Check whether there is another record already in that slot
	if (db_name[id][0] && !equal(g_playername[id], db_name[id]))
	{
		// If DB size is exceeded, write over old records
		if (db_slot_i >= sizeof db_name)
			db_slot_i = g_maxplayers+1
		
		// Move previous record onto an additional save slot
		copy(db_name[db_slot_i], charsmax(db_name[]), db_name[id])
		db_ammopacks[db_slot_i] = db_ammopacks[id]
		db_zombieclass[db_slot_i] = db_zombieclass[id]
		db_humanclass[db_slot_i] = db_humanclass[id]
		db_slot_i++
	}
	
	// Now save the current player stats
	copy(db_name[id], charsmax(db_name[]), g_playername[id]) // name
	db_ammopacks[id] = g_AmmoPacks[id]  // ammo packs
	db_zombieclass[id] = zp_class_zombie_get_next(id) // zombie class
	db_humanclass[id] = zp_class_human_get_next(id) // zombie class
}

// Load player's stats from database (if a record is found)
load_stats(id)
{
	// Look for a matching record
	static i
	for (i = 0; i < sizeof db_name; i++)
	{
		if (equal(g_playername[id], db_name[i]))
		{
			// Bingo!
			g_AmmoPacks[id] = db_ammopacks[i]
			if(db_zombieclass[i] == -1)
				db_zombieclass[i] = 0
			zp_class_zombie_set_next(id, db_zombieclass[i])
			zp_class_human_set_next(id, db_humanclass[i])
			return;
		}
	}
}

// Log Event Round End
public logevent_round_end()
{
	static id, team
	for (id = 1; id <= g_maxplayers; id++)
	{
		// Not connected
		if (!is_user_connected(id))
			continue;
			
		team = fm_cs_get_user_team(id)
		
		// Not playing
		if (team == FM_CS_TEAM_SPECTATOR || team == FM_CS_TEAM_UNASSIGNED)
			continue;
			
		save_stats(id)
	}
}

// Get User Team
stock fm_cs_get_user_team(id)
{
	return get_pdata_int(id, OFFSET_CSTEAMS, OFFSET_LINUX);
}