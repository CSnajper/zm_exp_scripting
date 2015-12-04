/*****************************************************\
===============================
|| [ZP] Aim Info Plugin v1.0 ||
===============================

||DESCRIPTION||
	When you aim at your friend, a hud message
	appears which shows you the Name, HP, 
	Armor and Ammo Packs of your friend.

||CREDITS||
	- AMX MOD X Team ----> For most of the natives
	- MeRcyLeZZ ----> For ZP 4.3
	- Sn!ff3r ----> For the Actual Aim info Plugin

\*****************************************************/
#include <amxmodx>
//#include <zombieplague>
#include <zp50_core>
#include <zp50_ammopacks>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#define LIBRARY_ASSASIN "zp50_class_assassin"
#include <zp50_class_assassin>
#define LIBRARY_SURVIVOR "zp50_class_survivor"
#define LIBRARY_SNIPER "zp50_class_sniper"
#include <zp50_class_sniper>
#include <zp50_class_survivor>


native get_user_level(id)

#define PLUGIN "Aim Info Plugin"
#define VERSION "1.0"
#define AUTHOR "@bdul!+Sn!ff3r"

new g_status_sync

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_event("StatusValue", "showStatus", "be", "1=2", "2!0")
	register_event("StatusValue", "hideStatus", "be", "1=1", "2=0")
	register_dictionary("zp_aim_info.txt");
    
	g_status_sync = CreateHudSyncObj()
}

public showStatus(id)
{
	if(!is_user_bot(id) && is_user_connected(id)) 
	{
		new name[32], pid = read_data(2)
		static class_name[32], transkey[64]
    
		get_user_name(pid, name, 31)
		new color1 = 0, color2 = 0
    
		new team1 = zp_core_is_zombie(id), team2 = zp_core_is_zombie(pid)
    
		if (team2 == 1)
			color1 = 255
		else
			color2 = 255
        
		if(zp_core_is_zombie(pid))
		{
			if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(pid))
				formatex(class_name, charsmax(class_name), "%L", pid, "CLASS_NEMESIS")
			else if (LibraryExists(LIBRARY_ASSASIN, LibType_Library) && zp_class_assassin_get(pid))
				formatex(class_name, charsmax(class_name), "%L", pid, "CLASS_ASSASIN")
			else
			{
				zp_class_zombie_get_name(zp_class_zombie_get_current(pid), class_name, charsmax(class_name))
				formatex(transkey, charsmax(transkey), "ZOMBIENAME %s", class_name)
				if (GetLangTransKey(transkey) != TransKey_Bad) formatex(class_name, charsmax(class_name), "%L", pid, transkey)
			}
		}
		else // humans
		{
			// Survivor Class loaded?
			if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(pid))
				formatex(class_name, charsmax(class_name), "%L", pid, "CLASS_SURVIVOR")
			else if (LibraryExists(LIBRARY_SNIPER, LibType_Library) && zp_class_sniper_get(pid))
				formatex(class_name, charsmax(class_name), "%L", pid, "CLASS_SNIPER")	
			else
			{
				zp_class_human_get_name(zp_class_human_get_current(pid), class_name, charsmax(class_name))
				
				// ML support for class name
				formatex(transkey, charsmax(transkey), "HUMANNAME %s", class_name)
				if (GetLangTransKey(transkey) != TransKey_Bad) formatex(class_name, charsmax(class_name), "%L", pid, transkey)
			}
		}
		set_hudmessage(color1, 50, color2, -1.0, 0.60, 1, 0.1, 6.0, 0.01, 0.01, -1)
		if (team1 == team2)    // friend
		{
			ShowSyncHudMsg(id, g_status_sync, "%L", LANG_PLAYER, "AIM_INFO", name, get_user_level(pid), class_name, get_user_armor(pid), zp_ammopacks_get(pid))
		}
		else ShowSyncHudMsg(id, g_status_sync, "%L", LANG_PLAYER, "AIM_INFO2", name, get_user_level(pid), class_name);
	}
}

public hideStatus(id)
{
	ClearSyncHud(id, g_status_sync)
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ ansicpg1252\\ deff0\\ deflang1033{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ f0\\ fs16 \n\\ par }
*/
