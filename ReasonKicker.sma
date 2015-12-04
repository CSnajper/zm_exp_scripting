#include <amxmodx>
#include <amxmisc>
#include <cstrike>

#define PLUGIN	"Reason_Kicker"
#define AUTHOR	"Tramp"
#define VERSION	"0.1"

new g_menuPosition[33];
new g_menuPlayers[33][32];
new g_menuPlayersNum[33];
new g_coloredMenus;
new g_kickReasons[7][128];
new g_lastCustom[33][128];
new g_inCustomReason[33];
new g_kickedPlayer;

#define MAXSLOTS 32

enum Color
{
	YELLOW = 1, // Yellow
	GREEN, // Green Color
	TEAM_COLOR, // Red, grey, blue
	GREY, // grey
	RED, // Red
	BLUE, // Blue
}

new TeamInfo;
new SayText;
new MaxSlots;

new TeamName[][] = 
{
	"",
	"TERRORIST",
	"CT",
	"SPECTATOR"
}

new bool:IsConnected[MAXSLOTS + 1];


public plugin_init()
{
	register_dictionary("common.txt")
	register_dictionary("admincmd.txt")
	register_dictionary("plmenu.txt")
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_cvar(PLUGIN, VERSION, FCVAR_SERVER|FCVAR_SPONLY);
	register_clcmd("amx_kickmenu", "cmdKickMenu", ADMIN_KICK, "- displays kick menu")
	register_clcmd("amx_customkickreason", "setCustomKickReason", ADMIN_KICK, "- configures custom ban message")
	register_menucmd(register_menuid("Kick Menu"), 1023, "actionKickMenu")
	register_menucmd(register_menuid("Kick Reason Menu"), 1023, "actionKickMenuReason")
	
	register_cvar("amx_kick_r1","");
	register_cvar("amx_kick_r2","");
	register_cvar("amx_kick_r3","");
	register_cvar("amx_kick_r4","");
	register_cvar("amx_kick_r5","");
	register_cvar("amx_kick_r6","");
	register_cvar("amx_kick_r7","");
	
	new k1[32], k2[32], k3[32], k4[32], k5[32], k6[32], k7[32];
	
	get_cvar_string("amx_kick_r1",k1, 31);
	get_cvar_string("amx_kick_r2",k2, 31);
	get_cvar_string("amx_kick_r3",k3, 31);
	get_cvar_string("amx_kick_r4",k4, 31);
	get_cvar_string("amx_kick_r5",k5, 31);
	get_cvar_string("amx_kick_r6",k6, 31);
	get_cvar_string("amx_kick_r7",k7, 31);
	
	set_task(320.0, "ads", 7777, "", 0, "b");

	g_kickReasons[0] = k1
	g_kickReasons[1] = k2
	g_kickReasons[2] = k3
	g_kickReasons[3] = k4
	g_kickReasons[4] = k5
	g_kickReasons[5] = k6
	g_kickReasons[6] = k7
	
	TeamInfo = get_user_msgid("TeamInfo");
	SayText = get_user_msgid("SayText");
	MaxSlots = get_maxplayers();
}

public cmdKickMenu(id, level, cid)
{
	if (cmd_access(id, level, cid, 1))
		displayKickMenu(id, g_menuPosition[id] = 0)

	return PLUGIN_HANDLED
}

public ads()
{
	
	for (new i = 1; i <= 32; i++)
	{
		if (is_user_connected(i))
		{
			ColorChat(i, GREY, " ");
			ColorChat(i, GREY, " ");
		}
	}
	
	
}

displayKickMenu(id, pos)
{
	if (pos < 0)
		return

	get_players(g_menuPlayers[id], g_menuPlayersNum[id])

	new menuBody[512]
	new b = 0
	new i
	new name[32]
	new start = pos * 8

	if (start >= g_menuPlayersNum[id])
		start = pos = g_menuPosition[id] = 0

	new len = format(menuBody, 511, g_coloredMenus ? "\y%L\R%d/%d^n\w^n" : "%L %d/%d^n^n", id, "KICK_MENU", pos + 1, (g_menuPlayersNum[id] / 8 + ((g_menuPlayersNum[id] % 8) ? 1 : 0)))
	new end = start + 8
	new keys = MENU_KEY_0

	if (end > g_menuPlayersNum[id])
		end = g_menuPlayersNum[id]

	for (new a = start; a < end; ++a)
	{
		i = g_menuPlayers[id][a]
		get_user_name(i, name, 31)

		if (access(i, ADMIN_IMMUNITY))
		{
			++b
		
			if (g_coloredMenus)
				len += format(menuBody[len], 511-len, "\d%d. %s^n\w", b, name)
			else
				len += format(menuBody[len], 511-len, "#. %s^n", name)
		} else {
			keys |= (1<<b)
				
			if (is_user_admin(i))
				len += format(menuBody[len], 511-len, g_coloredMenus ? "%d. %s \r*^n\w" : "%d. %s *^n", ++b, name)
			else
				len += format(menuBody[len], 511-len, "%d. %s^n", ++b, name)
		}
	}

	if (end != g_menuPlayersNum[id])
	{
		format(menuBody[len], 511-len, "^n9. %L...^n0. %L", id, "MORE", id, pos ? "BACK" : "EXIT")
		keys |= MENU_KEY_9
	}
	else
		format(menuBody[len], 511-len, "^n0. %L", id, pos ? "BACK" : "EXIT")

	show_menu(id, keys, menuBody, -1, "Kick Menu")
}

public actionKickMenu(id, key)
{
	switch (key)
	{
		case 8: displayKickMenu(id, ++g_menuPosition[id])
		case 9: displayKickMenu(id, --g_menuPosition[id])
		default:
		{
			/* new player = g_menuPlayers[id][g_menuPosition[id] * 8 + key]
			new authid[32], authid2[32], name[32], name2[32]
			
			get_user_authid(id, authid, 31)
			get_user_authid(player, authid2, 31)
			get_user_name(id, name, 31)
			get_user_name(player, name2, 31)
			
			new userid2 = get_user_userid(player)

			log_amx("Kick: ^"%s<%d><%s><>^" kick ^"%s<%d><%s><>^"", name, get_user_userid(id), authid, name2, userid2, authid2)

			show_activity_key("ADMIN_KICK_1", "ADMIN_KICK_2", name, name2);

			
			server_cmd("kick #%d", userid2)
			server_exec() */
			
			g_kickedPlayer = g_menuPlayers[id][g_menuPosition[id] * 8 + key]

			displayKickMenuReason(id)
		}
	}

	return PLUGIN_HANDLED
}

displayKickMenuReason(id)
{
	new menuBody[1024]
	new len = format(menuBody,1023, g_coloredMenus ? "\y%s\R^n\w^n" : "%s^n^n", "Reason")
	new i = 0;

	while (i < 7)
	{
		if (strlen(g_kickReasons[i])) 
			len+=format(menuBody[len],1023-len,"%d. %s^n",i+1,g_kickReasons[i])
		
		i++
	}
	
	len+=format(menuBody[len],1023-len,"^n8. Custom^n")
	if (g_lastCustom[id][0]!='^0')
		len+=format(menuBody[len],1023-len,"^n9. %s^n",g_lastCustom[id])

	len+=format(menuBody[len],1023-len,"^n0. %L^n",id,"EXIT")	
	
	len+=format(menuBody[len],1023-len, g_coloredMenus ? "^n\yTramp Kicker ver %s^n" : "^nTramp Kicker ver %s\w^n", VERSION)

	new keys = MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_3 | MENU_KEY_4 | MENU_KEY_5 | MENU_KEY_6 | MENU_KEY_7 | MENU_KEY_8 | MENU_KEY_0

	if (g_lastCustom[id][0]!='^0')
		keys |= MENU_KEY_9

	show_menu(id,keys,menuBody,-1,"Kick Reason Menu")
}

public actionKickMenuReason(id,key)
{
	switch (key)
	{
		case 9:
		{
			displayKickMenu(id,g_menuPosition[id])
		}

		case 7:
		{
			g_inCustomReason[id]=1
			client_cmd(id,"messagemode amx_customkickreason")

			return PLUGIN_HANDLED
		}

		case 8:
		{
			kickUser(id,g_lastCustom[id])
		}

		default:
		{
			kickUser(id,g_kickReasons[key])
		}
	}
	displayKickMenu(id,g_menuPosition[id] = 0)

	return PLUGIN_HANDLED
}

public setCustomKickReason(id,level,cid)
{
	if (!cmd_access(id,level,cid,1))
	{
		return PLUGIN_HANDLED
	}

	new szReason[128]
	read_argv(1,szReason,127)
	copy(g_lastCustom[id],127,szReason)

	if (g_inCustomReason[id])
	{
		g_inCustomReason[id]=0
		kickUser(id,g_lastCustom[id])
	}

	return PLUGIN_HANDLED
}

kickUser(id,kickReason[])
{
	new player = g_kickedPlayer;

	new name[32], name2[32], authid[32],authid2[32]
	get_user_name(player,name2,31)
	get_user_authid(player,authid2,31)
	get_user_authid(id,authid,31)
	get_user_name(id,name,31)
	
	
	new userid2 = get_user_userid(player);
	//client_print(0,print_chat,"Twoje id : %d ", userid2);

	log_amx("Kick: ^"%s<%d><%s><>^" kick ^"%s<%d><%s><>Powod: %s^"", name, get_user_userid(id), authid, name2, userid2, authid2, kickReason)
	log_to_file("6_kicki", "Kick: ^"%s<%d><%s><>^" kick ^"%s<%d><%s><>Powod: %s^"", name, get_user_userid(id), authid, name2, userid2, authid2, kickReason);
	
	set_hudmessage(0, 255, 0, 0.05, 0.35, 0, 6.0, 5.0, 0.5, 0.15, 7);
	show_hudmessage(0, "Gracz o nicku %s ^nZostal wywalony przez %s ^nPowod: %s", name2, name, kickReason);
	//client_print(0,print_chat,"Gracz o nicku %s ^nZostal wywalony przez %s ^nPowod: %s", name2, name, kickReason);

	server_cmd("kick #%d ^"%s^"",userid2,kickReason)
	

}

public client_putinserver(player)
{
	IsConnected[player] = true;
}

public client_disconnect(player)
{
	IsConnected[player] = false;
}

public ColorChat(id, Color:type, const msg[], {Float,Sql,Result,_}:...)
{
	static message[256];

	switch(type)
	{
		case YELLOW: // Yellow
		{
			message[0] = 0x01;
		}
		case GREEN: // Green
		{
			message[0] = 0x04;
		}
		default: // White, Red, Blue
		{
			message[0] = 0x03;
		}
	}

	vformat(message[1], 251, msg, 4);

	// Make sure message is not longer than 192 character. Will crash the server.
	message[192] = '^0';

	new team, ColorChange, index, MSG_Type;
	
	if(!id)
	{
		index = FindPlayer();
		MSG_Type = MSG_ALL;
	
	} else {
		MSG_Type = MSG_ONE;
		index = id;
	}
	
	team = get_user_team(index);	
	ColorChange = ColorSelection(index, MSG_Type, type);

	ShowColorMessage(index, MSG_Type, message);
		
	if(ColorChange)
	{
		Team_Info(index, MSG_Type, TeamName[team]);
	}
}

ShowColorMessage(id, type, message[])
{
	message_begin(type, SayText, _, id);
	write_byte(id)		
	write_string(message);
	message_end();	
}

Team_Info(id, type, team[])
{
	message_begin(type, TeamInfo, _, id);
	write_byte(id);
	write_string(team);
	message_end();

	return 1;
}

ColorSelection(index, type, Color:Type)
{
	switch(Type)
	{
		case RED:
		{
			return Team_Info(index, type, TeamName[1]);
		}
		case BLUE:
		{
			return Team_Info(index, type, TeamName[2]);
		}
		case GREY:
		{
			return Team_Info(index, type, TeamName[0]);
		}
	}

	return 0;
}

FindPlayer()
{
	new i = -1;

	while(i <= MaxSlots)
	{
		if(IsConnected[++i])
		{
			return i;
		}
	}

	return -1;
}