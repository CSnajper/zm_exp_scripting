/*================================================================================
	
	-----------------------
	-*- [ZP] Deathmatch -*-
	-----------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <cs_ham_bots_api>
#include <zp50_gamemodes>
#include <zp50_class_nemesis>
#include <zp50_class_survivor>
#include <zp50_class_assassin>
#include <zp50_class_sniper>

#define TASK_RESPAWN 100
#define ID_RESPAWN (taskid - TASK_RESPAWN)

native rozgrzewka_on()

// Custom Forwards
enum _:TOTAL_FORWARDS
{
	FW_USER_RESPAWN_PRE = 0
}
new g_Forwards[TOTAL_FORWARDS]
new g_ForwardResult

new g_MaxPlayers
new g_GameModeStarted

new cvar_deathmatch, cvar_respawn_delay
new cvar_respawn_zombies, cvar_respawn_humans
new cvar_respawn_on_suicide

public plugin_init()
{
	register_plugin("[ZP] Deathmatch", ZP_VERSION_STRING, "ZP Dev Team")
	
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
	RegisterHamBots(Ham_Spawn, "fw_PlayerSpawn_Post", 1)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1)
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled_Post", 1)
	register_event("DeathMsg", "Death", "ade");
	
	cvar_deathmatch = register_cvar("zp_deathmatch", "0")
	cvar_respawn_delay = register_cvar("zp_respawn_delay", "5")
	cvar_respawn_zombies = register_cvar("zp_respawn_zombies", "1")
	cvar_respawn_humans = register_cvar("zp_respawn_humans", "1")
	cvar_respawn_on_suicide = register_cvar("zp_respawn_on_suicide", "0")
//	register_logevent("PoczatekRundy", 2, "1=Round_Start"); 
	
	g_MaxPlayers = get_maxplayers()
	
	g_Forwards[FW_USER_RESPAWN_PRE] = CreateMultiForward("zp_fw_deathmatch_respawn_pre", ET_CONTINUE, FP_CELL)
	
	set_task(10.0, "Sprawdz_team")
}

// Ham Player Spawn Post Forward
public fw_PlayerSpawn_Post(id)
{
	// Not alive or didn't join a team yet
	if (!is_user_alive(id) || !cs_get_user_team(id))
		return;
	
	// Remove respawn task
	remove_task(id+TASK_RESPAWN)
	
	set_task(2.0, "respawn_player_task", id+TASK_RESPAWN)
}

// Ham Player Killed Post Forward
public fw_PlayerKilled_Post(victim, attacker, shouldgib)
{
	// Respawn if deathmatch is enabled
	if (get_pcvar_num(cvar_deathmatch))
	{
		// Respawn on suicide?
		if (!get_pcvar_num(cvar_respawn_on_suicide) && (victim == attacker || !is_user_connected(attacker)))
			return;
		
		// Respawn if human/zombie?
		if ((zp_core_is_zombie(victim) && !get_pcvar_num(cvar_respawn_zombies)) || (!zp_core_is_zombie(victim) && !get_pcvar_num(cvar_respawn_humans)))
			return;
		
		// Set the respawn task
		set_task(get_pcvar_float(cvar_respawn_delay), "respawn_player_task", victim+TASK_RESPAWN)
	}
}

// Respawn Player Task (deathmatch)
public respawn_player_task(taskid)
{
	// Already alive or round ended
	if (is_user_alive(ID_RESPAWN) || is_user_hltv(ID_RESPAWN))
		return;
		
	if(zp_gamemodes_get_current() == ZP_NO_GAME_MODE)
	{
		zp_core_respawn_as_zombie(ID_RESPAWN, false)
		respawn_player_manually(ID_RESPAWN)
		return;
	}
	
	if(rozgrzewka_on() == 1){
		zp_core_respawn_as_zombie(ID_RESPAWN, false)
		respawn_player_manually(ID_RESPAWN)
		return;
	}
	
	new const Infection[] = "Infection Mode" 
	new InfectionID = zp_gamemodes_get_id(Infection)
	
	new const Multi[] = "Multiple Infection Mode" 
	new MultiID = zp_gamemodes_get_id(Multi)
	
	new const Survivor[] = "Survivor Mode" 
	new SurvivorID = zp_gamemodes_get_id(Survivor)
	
	new const Nemesis[] = "Nemesis Mode" 
	new NemesisID = zp_gamemodes_get_id(Nemesis)
	
	new const Assassin[] = "Assassin Mode" 
	new AssassinID = zp_gamemodes_get_id(Assassin)
	
	new const Sniper[] = "Sniper Mode" 
	new SniperID = zp_gamemodes_get_id(Sniper)
	
	// Get player's team
	new CsTeams:team = cs_get_user_team(ID_RESPAWN)
	
	// Player moved to spectators
	if (team == CS_TEAM_SPECTATOR || team == CS_TEAM_UNASSIGNED){
		if(zp_gamemodes_get_current() == InfectionID || zp_gamemodes_get_current() == MultiID || rozgrzewka_on() == 1 || zp_gamemodes_get_current() == ZP_NO_GAME_MODE){
			set_task(5.0, "respawn_player_task", taskid+TASK_RESPAWN)
			return;
		}
	}
	
	if (team != CS_TEAM_SPECTATOR && team != CS_TEAM_UNASSIGNED){
		if(zp_gamemodes_get_current() == SurvivorID){
			zp_core_respawn_as_zombie(ID_RESPAWN, true)
			return;
		}
		if(zp_gamemodes_get_current() == NemesisID){
			zp_core_respawn_as_zombie(ID_RESPAWN, false)
			return;
		}
		if(zp_gamemodes_get_current() == AssassinID){
			zp_core_respawn_as_zombie(ID_RESPAWN, false)
			return;
		}
		if(zp_gamemodes_get_current() == SniperID){
			zp_core_respawn_as_zombie(ID_RESPAWN, true)
			return;
		}
	}
	
	// Allow other plugins to decide whether player can respawn or not
	ExecuteForward(g_Forwards[FW_USER_RESPAWN_PRE], g_ForwardResult, ID_RESPAWN)
	if (g_ForwardResult >= PLUGIN_HANDLED)
		return;
	
	// Respawn as zombie?
	if (get_pcvar_num(cvar_deathmatch) == 2 || (get_pcvar_num(cvar_deathmatch) == 3 && random_num(0, 1)) || (get_pcvar_num(cvar_deathmatch) == 4 && zp_core_get_zombie_count() < GetAliveCount()/2))
	{
		if(rozgrzewka_on() == 1)
			zp_core_respawn_as_zombie(ID_RESPAWN, false)
		// Only allow respawning as zombie after a game mode started
		else if (g_GameModeStarted) zp_core_respawn_as_zombie(ID_RESPAWN, true)
	}
	
	respawn_player_manually(ID_RESPAWN)
}

// Respawn Player Manually (called after respawn checks are done)
respawn_player_manually(id)
{
	// Respawn!
	ExecuteHamB(Ham_CS_RoundRespawn, id)
}

public client_disconnect(id)
{
	// Remove tasks on disconnect
	remove_task(id+TASK_RESPAWN)
}

public zp_fw_gamemodes_start()
{
	g_GameModeStarted = true
}

public zp_fw_gamemodes_end()
{
	g_GameModeStarted = false
	
	// Stop respawning after game mode ends
	new id
	for (id = 1; id <= g_MaxPlayers; id++)
		remove_task(id+TASK_RESPAWN)
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

public client_putinserver(id)
{
//	new const Infection[] = "Infection Mode" 
//	new InfectionID = zp_gamemodes_get_id(Infection)
//	new const Multi[] = "Multiple Infection Mode" 
//	new MultiID = zp_gamemodes_get_id(Multi)
	

//	if(zp_gamemodes_get_current() == InfectionID || zp_gamemodes_get_current() == MultiID || rozgrzewka_on() == 1)
		set_task(2.0, "respawn_player_task", id+TASK_RESPAWN)
}

public Sprawdz_team()
{

/*	new const Infection[] = "Infection Mode"
	new InfectionID = zp_gamemodes_get_id(Infection)
	
	new const Multi[] = "Multiple Infection Mode"
	new MultiID = zp_gamemodes_get_id(Multi)*/
	
	new const Survivor[] = "Survivor Mode"
	new SurvivorID = zp_gamemodes_get_id(Survivor)
	
	new const Nemesis[] = "Nemesis Mode"
	new NemesisID = zp_gamemodes_get_id(Nemesis)
	
	new const Assassin[] = "Assassin Mode"
	new AssassinID = zp_gamemodes_get_id(Assassin)
	
	new const Sniper[] = "Sniper Mode"
	new SniperID = zp_gamemodes_get_id(Sniper)
	
	// Get player's team
//	new CsTeams:team = cs_get_user_team(id)
	
	for (new id; id<=32; id++)
	{
		if(!is_user_alive(id) || !is_user_connected(id) || zp_gamemodes_get_current() == ZP_NO_GAME_MODE)
			continue
		new CsTeams:team
		team = cs_get_user_team(id)
		
		if(team == CS_TEAM_SPECTATOR || team == CS_TEAM_UNASSIGNED)
			continue;
		
		if(zp_core_is_zombie(id) || zp_class_nemesis_get(id) || zp_class_assassin_get(id)){
			if(team != CS_TEAM_T)
			{
				user_kill(id, 1)
				cs_set_user_team(id, CS_TEAM_T)
			}
		}
		else if(zp_class_survivor_get(id) || zp_class_sniper_get(id)){
			if(team != CS_TEAM_CT)
			{
				user_kill(id, 1)
				cs_set_user_team(id, CS_TEAM_CT)
			}
		}
		else if(team != CS_TEAM_CT)
		{
			user_kill(id, 1)
			cs_set_user_team(id, CS_TEAM_CT)
		}
	}
	
	if(zp_gamemodes_get_current() == SurvivorID)
	{
		for(new id = 1; id<=get_playersnum(); id++)
		{
			if(!is_user_alive(id) || !is_user_connected(id) || zp_class_survivor_get(id))
				continue;
			
			new CsTeams:team = cs_get_user_team(id)
			
			if(team == CS_TEAM_SPECTATOR || team == CS_TEAM_UNASSIGNED)
				continue;
			
			if(team != CS_TEAM_T)
			{
				user_kill(id, 1)
				cs_set_user_team(id, CS_TEAM_T)
			}
		}
	}
	else if(zp_gamemodes_get_current() == NemesisID)
	{
		for(new id = 1; id<=get_playersnum(); id++)
		{
			if(!is_user_alive(id) || !is_user_connected(id) || zp_class_nemesis_get(id))
				continue;
			
			new CsTeams:team = cs_get_user_team(id)
			
			if(team == CS_TEAM_SPECTATOR || team == CS_TEAM_UNASSIGNED)
				continue;
			
			if(team != CS_TEAM_CT)
			{
				user_kill(id, 1)
				cs_set_user_team(id, CS_TEAM_CT)
			}
		}
	}
	else if(zp_gamemodes_get_current() == SniperID)
	{
		for(new id = 1; id<=get_playersnum(); id++)
		{
			if(!is_user_alive(id) || !is_user_connected(id) || zp_class_sniper_get(id))
				continue;
			
			new CsTeams:team = cs_get_user_team(id)
			
			if(team == CS_TEAM_SPECTATOR || team == CS_TEAM_UNASSIGNED)
				continue;
			
			if(team != CS_TEAM_T)
			{
				user_kill(id, 1)
				cs_set_user_team(id, CS_TEAM_T)
			}
		}
	}
	else if(zp_gamemodes_get_current() == AssassinID)
	{
		for(new id = 1; id<=get_playersnum(); id++)
		{
			if(!is_user_alive(id) || !is_user_connected(id) || zp_class_assassin_get(id))
				continue;
			
			new CsTeams:team = cs_get_user_team(id)
			
			if(team == CS_TEAM_SPECTATOR || team == CS_TEAM_UNASSIGNED)
				continue;
			
			if(team != CS_TEAM_CT)
			{
				user_kill(id, 1)
				cs_set_user_team(id, CS_TEAM_CT)
			}
		}
	}
	
	set_task(5.0, "Sprawdz_team")
	
	return PLUGIN_CONTINUE;
}

/*public PoczatekRundy()	
{
	set_task(2.0, "Sprawdz_dead", TASK_RESPAWN_START, _, _, "a", 5);
	
	return PLUGIN_CONTINUE;
}

public Sprawdz_dead()
{
	if(zp_gamemodes_get_current() == ZP_NO_GAME_MODE)
	{
		for (new id = 1; id <= g_MaxPlayers; id++)
		{
			new CsTeams:team = cs_get_user_team(id)
			
			if(team == CS_TEAM_SPECTATOR || team == CS_TEAM_UNASSIGNED)
				continue;
			
			if(!is_user_alive(id))
			{
				zp_core_respawn_as_zombie(id, false)
				respawn_player_manually(id)
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}*/

/*public zwroc_team(id){
	client_print(id, print_chat, "Zombie: %i, Nemek: %i", zp_core_is_zombie(id), zp_class_nemesis_get(id));
	client_print(id, print_chat, "Czlowiek: %i, Surv: %i", zp_core_is_zombie(id), zp_class_survivor_get(id));
}

public team_ct(id)
	cs_set_user_team(id, CS_TEAM_CT)

public team_tt(id)
	cs_set_user_team(id, CS_TEAM_T)*/