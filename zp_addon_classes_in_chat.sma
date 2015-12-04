/***************************************************************************\
		    =====================================
		     * || [ZP] Classes In Chat v1.1 || *
		    =====================================

	-------------------
	 *||DESCRIPTION||*
	-------------------

	This plugins adds classes in chat for eg:
	If a person is survivor and he says something then this is what it
	would look like
	[Survivor] Player: Hi I am a survivor
	To make the chat more interesting, the chat is in colors

	Original Plugin thread is located here:
	http://forums.alliedmods.net/showthread.php?t=120557

	---------------
	 *||CREDITS||*
	---------------

	- MeRcyLeZZ ----> For some of the natives
	- My Sister ----> For taking the some screen shots

	------------------
	 *||CHANGE LOG||*
	------------------
	
	v1.0 ====> - Initial Release
	v1.0 ====> - Re-wrote the whole plugin
		   - Removed the color chat include and added a new color chat
		      system.
		   - Fixed almost, all the bugs which were reported

\***************************************************************************/

#include <amxmodx>
#include <cstrike>
#include <zombieplague>

// Variables
new g_msg_saytext, g_msg_teaminfo, g_new_round

// Team names used by the team info message
new const team_names[][] =
{
	"UNASSIGNED",
	"TERRORIST",
	"CT",
	"SPECTATOR"
}

// Color indexes for color chat message
enum
{
	RED = 1,
	BLUE,
	GREY
}

public plugin_init()
{
	// Register the plugin
	register_plugin("[ZP] Classes In Chat", "1.1", "@bdul!")
	
	// Client say commands
	register_clcmd("say", "hook_say")
	register_clcmd("say_team", "hook_team_say")
	
	// Round start event
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	
	// Message IDs'
	g_msg_saytext = get_user_msgid("SayText")
	g_msg_teaminfo = get_user_msgid("TeamInfo")
	
	// This var should be set true to prevent a bug
	g_new_round = true
}

// Check for new round and update the var accordingly
public event_round_start() g_new_round = true
public zp_round_started() g_new_round = false

// Player's chat hook
public hook_say(id)
{
	// Retrieve the player's chat
	static chat[192], name[32], users_team
	read_args(chat, 191)
	remove_quotes(chat)
	
	// Trying to fool us ?
	if(!chat[0])
		return PLUGIN_CONTINUE
	
	// Retrieve player's name
	get_user_name(id, name, charsmax(name))
	
	// Retrieve player's team
	users_team = _:cs_get_user_team(id)
	
	// Alive user chat
	if (is_user_alive(id))
	{
		if (zp_get_user_zombie(id))
			color_chat(0, id, users_team, RED,  "^3[%s]^4 %s:^1 %s", zp_get_user_nemesis(id) ? "Nemesis" : "Zombie", name, chat)
		else
			color_chat(0, id, users_team, BLUE, "^3[%s]^4 %s:^1 %s", zp_get_user_survivor(id) ? "Survivor" : "Human", name, chat)
	}
	
	// Dead user's chat
	else color_chat(0, id, users_team, users_team, "^3[%s]^4 %s:^1 %s", users_team == _:CS_TEAM_SPECTATOR ? "SPEC" : "DEAD", name, chat)
	
	return PLUGIN_HANDLED
}

// Player's team say hook
public hook_team_say(id)
{
	// Retrieve the player's chat
	static chat[192], name[32], users_team
	read_args(chat, 191)
	remove_quotes(chat)
	
	// Trying to fool us ?
	if(!chat[0])
		return PLUGIN_CONTINUE
	
	// Retrieve player's name
	get_user_name(id, name, charsmax(name))
	
	// Retrieve player's team
	users_team = _:cs_get_user_team(id)
	
	// Alive user
	if (is_user_alive(id))
	{
		if (zp_get_user_zombie(id))
			color_chat(1, id, users_team, RED,  "^3[%s](Team Message)^4 %s:^1 %s", zp_get_user_nemesis(id) ? "Nemesis" : "Zombie", name, chat)
		else
			color_chat(g_new_round ? 0 : 1, id, users_team, BLUE, "^3[%s](Team Message)^4 %s:^1 %s", zp_get_user_survivor(id) ? "Survivor" : "Human", name, chat)
	}
	
	// Dead user's chat
	else color_chat(1, id, users_team, users_team, "^3[%s](Team Message)^4 %s:^1 %s", users_team == _:CS_TEAM_SPECTATOR ? "SPEC" : "DEAD", name, chat)
	
	return PLUGIN_HANDLED
}

// An improved color chat function
color_chat(team_format, player, player_team, color, const chat_msg[], ...)
{
	// Format the chat message
	static msg[192]
	vformat(msg, charsmax(msg) - 1, chat_msg, 6)
	
	// We need to display the chat message to only the player's team
	if (team_format)
	{
		// Get amount of players present
		static id, i, players[32], count
		get_players(players, count, "e", team_names[player_team])
		
		// Loop through them
		for (i = 0; i < count; i++)
		{
			// Save player's id so we dont re-index
			id = players[i]
			
			// Just in case...
			if (!id) continue;
			
			// Send the colored text message
			message_begin(MSG_ONE_UNRELIABLE, g_msg_saytext, _, id)
			write_byte(player)
			write_string(msg)
			message_end()
			
		}
	}
	else
	{
		// Do we need to change the player's team ?
		if (player_team == color)
		{
			// Send the colored text message
			message_begin(MSG_BROADCAST, g_msg_saytext)
			write_byte(player)
			write_string(msg)
			message_end()
		}
		else
		{
			// Change his team first
			message_begin(MSG_BROADCAST, g_msg_teaminfo)
			write_byte(player)
			write_string(team_names[color])
			message_end()
			
			// Send the colored text message
			message_begin(MSG_BROADCAST, g_msg_saytext)
			write_byte(player)
			write_string(msg)
			message_end()
			
			// Restore player's team
			message_begin(MSG_BROADCAST, g_msg_teaminfo)
			write_byte(player)
			write_string(team_names[player_team])
			message_end()
		}
	}
}