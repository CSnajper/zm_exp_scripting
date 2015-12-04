#include "gunxpmod.cfg"
//#include <zp50_class_human>

#if defined ZOMBIE_BIOHAZARD
  #include <biohazard>
#endif
#if defined ZOMBIE_PLAGUE
  #include <zombieplague>
#endif

//#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <fun>
#include <cstrike>
#include <nvault>
#include <sqlx>
#include <hamsandwich>
#include <engine>
#include <dhudmessage>
#include <colorchat>
//misje
#include <zp50_core>
#include <zp50_gamemodes>
#include <zp50_colorchat>
#include <zp50_class_human>
#include <zp50_class_zombie>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#define LIBRARY_ASSASIN "zp50_class_assassin"
#include <zp50_class_assassin>
#define LIBRARY_SURVIVOR "zp50_class_survivor"
#include <zp50_class_survivor>
#define LIBRARY_SNIPER "zp50_class_sniper"
#include <zp50_class_sniper>
#define LIBRARY_AMMOPACKS "zp50_ammopacks"
#include <zp50_ammopacks>

#define PLUGIN	"Gun Xp Mod"
#define AUTHOR	"xbatista"
#define VERSION	"2.3 V2 by Sniper Elite"


#define OFFSET_PRIMARYWEAPON 116
#define TASK_SHOW_LEVEL 10113
#define fm_cs_set_user_nobuy(%1) set_pdata_int(%1, 235, get_pdata_int(%1, 235) & ~(1<<0) ) //no weapon buy
#define min_graczy 0
#define TASK_OFFSET 1500
#define TASK_LOAD_LEVEL 1550

//forward zp_fw_core_infect(id, attacker)
native get_user_xp(id)
native set_user_xp(id, amount)
native sprawdz_ile_wykonano(id)
native rozgrzewka_on()
native moze_wybrac_bron_rozg(id)

native sprawdz_misje_sql(id)
native nadaj_misje_sql(id, ile)
native nadaj_ile_wykonano_sql(id, ile)
native sprawdz_ile_juz_sql(id)
native nadaj_ile_juz_sql(id, ile)
native nat_menu_questow(id)

new PlayerXp[33];
new PlayerLevel[33];

//do nowego trybu zapisu
new ZapiszExp[6150]
new giLen=0, giMax=sizeof(ZapiszExp) - 1
new ilosc_wpisow = 0

new staty_level[10]
new staty_exp[10]
new staty_czas_online[10]
new staty_top_misje[10]
new staty_top10_points[10]
new staty_top10_level[10]
new staty_top10_ammopacks[10]
new staty_top10_dam_done[10]
new staty_top10_zm_kill[10]
new staty_top10_hm_infkill[10]
new staty_top10_nem_kill[10]
new staty_top10_sur_kill[10]
new staty_top10_ass_kill[10]
new staty_top10_sni_kill[10]

new name_top10[10][45]
new name_czas_online[10][45]
new name_top_misje[10][45]
new name_top_exp[10][45]

//szybsze przeladowanie broni + zmiana ilosci ammo
const NOCLIP_WPN_BS    = ((1<<2)|(1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_KNIFE)|(1<<CSW_C4))
const SHOTGUNS_BS    = ((1<<CSW_M3)|(1<<CSW_XM1014))
const m_pPlayer               = 41
const m_iId                    = 43
const m_flTimeWeaponIdle        = 48
const m_fInReload            = 54
const m_flNextAttack = 83
stock const Float:g_fDelay[31] = {
	0.00, 2.70, 0.00, 2.00, 0.00, 0.55,   0.00, 3.15, 3.30, 0.00, 4.50, 
	2.70, 3.50, 3.35, 2.45, 3.30,   2.70, 2.20, 2.50, 2.63, 4.70, 
	0.55, 3.05, 2.12, 3.50, 0.00,   2.20, 3.00, 2.45, 0.00, 3.40
}

const PEV_SPEC_TARGET = pev_iuser2

new g_Vault;
new g_remember_selection[33], g_kills[33], g_remember_selection_pistol[33];
new g_maxplayers, g_msgHudSync1, SayTxT, enable_grenades;
new levelspr, levelspr2, show_level_text, show_rank;
new save_type, xp_kill, xp_triple, enable_triple, triple_kills, xp_ultra, ultra_kills, enable_ultra, p_Enabled, level_style;
new enable_admin_xp, admin_xp;
new xp_die_zombie, xp_damage_xp, xp_damage_give;

new cvar_reward_ap_nemesis, cvar_reward_xp_nemesis, cvar_reward_ap_survivor, cvar_reward_xp_survivor, cvar_reward_ap_assassin, cvar_reward_xp_assassin, cvar_reward_ap_sniper, cvar_reward_xp_sniper;
new cvar_reward_ap_matka, cvar_reward_xp_matka, cvar_reward_ap_last, cvar_reward_xp_last

new min_licz_graczy;
new ilosc_graczy;
new bool:asysta_gracza[33][33];
new g_iDamage_asysta[33][33]
new damage2[33];
new doswiadczenie_za_asyste
new obrazenia_za_asyste

new wybral_bron[33] = 0
new bool:nocny_exp = false;

new g_stats_points[33], g_stats_ammopacks[33], g_stats_dam_done[33], g_stats_zm_kill[33], g_stats_hm_infkill[33], g_stats_deaths[33], g_stats_nem_kill[33], g_stats_sur_kill[33], g_stats_ass_kill[33], g_stats_sni_kill[33], g_stats_zm_win[33], g_stats_hm_win[33], g_stats_czas_online[33], g_stats_matki_kill[33], g_stats_last_hm_kill[33]

//exp x2
#define minut(%1) ((%1)*60.0)
new pcvarOdgodziny, pcvarDogodziny

/*================================================================================
						[MySQLx Vars, other]
=================================================================================*/

new mysqlx_host, mysqlx_user, mysqlx_db, mysqlx_pass;

//sql
new g_sqlTable[31] = "zm_expp"
new asked_sql[33];
new g_boolsqlOK = 0
new player_xp_old[33];
new Handle:g_SqlTuple
new database_user_created[33];
new bool:wczytalo[33] = false

new const WEAPONCONST[24][] = { "weapon_glock18", "weapon_usp", "weapon_p228", "weapon_fiveseven", "weapon_deagle", "weapon_elite", "weapon_tmp", 
"weapon_scout", "weapon_mac10", "weapon_awp", "weapon_ump45", "weapon_mp5navy", "weapon_p90", "weapon_m3", "weapon_famas", "weapon_galil", "weapon_xm1014", 
"weapon_m4a1", "weapon_ak47", "weapon_aug", "weapon_sg552", "weapon_m249", "weapon_g3sg1", "weapon_sg550"
}; // Give Weapons

new const WEAPONMDL[24][] = { "models/w_glock18.mdl", "models/w_usp.mdl", "models/w_p228.mdl", "models/w_fiveseven.mdl", "models/w_deagle.mdl", "models/w_elite.mdl", "models/w_tmp.mdl", 
"models/w_scout.mdl", "models/w_mac10.mdl", "models/w_awp.mdl", "models/w_ump45.mdl", "models/w_mp5.mdl", "models/w_p90.mdl", "models/w_m3.mdl", "models/w_famas.mdl", "models/w_galil.mdl", "models/w_xm1014.mdl", 
"models/w_m4a1.mdl", "models/w_ak47.mdl", "models/w_aug.mdl", "models/w_sg552.mdl", "models/w_m249.mdl", "models/w_g3sg1.mdl", "models/w_sg550.mdl"
}; // Blocks pick up weapon, don't change!

new const AMMOCONST[24] = { 17, 16, 1, 11, 26, 10, 23, 3, 7, 18, 12, 19, 30, 
21, 15, 14, 5, 22, 28, 8, 27, 20, 24, 13
}; // Weapons ID(CSW) don't change!

new const maxClip[31] = { -1, 13, -1, 10,  1,  7,  1,  30, 30,  1,  30,  20,  25, 30, 35, 25,  12,  20, 
	10,  30, 100,  8, 30,  30, 20,  2,  7, 30, 30, -1,  50 };

/*================================================================================
						[Plugin natives,precache,init]
=================================================================================*/

//new const sIP[] = "80.72.34.125:27195"

public plugin_init()
{
	register_concmd("give_exp", "cmd_give_exp", ADMIN_IMMUNITY, "give_exp <name> <amount>" );
	register_clcmd("say level", "showlevel");
	register_clcmd("say /level", "showlevel");
	register_clcmd("say /top20","showtop20");
	register_clcmd("say /online","showtop20");
	register_clcmd("say online","showtop20");
	register_clcmd("say /gracze","showtop20");
	register_clcmd("say gracze","showtop20");
	register_clcmd("say /menu","show_main_menu_info");
	register_clcmd("say menu","show_main_menu_info");
	register_clcmd("say bindy","pomoc_bindy_start");
	register_clcmd("say /pomoc","pomoc_info");
	register_clcmd("say pomoc","pomoc_info");
	register_clcmd("say /bindy","pomoc_bindy_start");
	register_clcmd("say /goldy","pomoc_goldy");
	register_clcmd("say goldy","pomoc_goldy");
	register_clcmd("say /gold","pomoc_goldy");
	register_clcmd("say gold","pomoc_goldy");
	register_clcmd("say bind","pomoc_bindy_start");
	register_clcmd("say /bind","pomoc_bindy_start");
	register_clcmd("say /b","pomoc_bindy_start");
	
	register_clcmd("say /top10", "top10")
	register_clcmd("say /top", "Staty")
	register_clcmd("say /staty", "Staty")
	register_clcmd("say staty", "Staty")
	register_clcmd("say /statystyki", "Staty")
	register_clcmd("say statystyki", "Staty")
	register_clcmd("say /top15", "Staty")
	
	register_clcmd("say /topxp", "top10_xp")
	register_clcmd("say /topmisje", "top10_misje")
	register_clcmd("say /toponline", "top10_online")
	
	register_clcmd("say /me", "moje_staty")
	
	p_Enabled = register_cvar( "gxm_enable", "1" ); // Plugin enabled? 1 = Yes, 0 = No.
	save_type = register_cvar("gxm_savetype","0"); // Save Xp to : 1 = MySQL, 0 = NVault.
	xp_kill = register_cvar("gxm_xp","10"); // How much xp gain if you killed someone?
	show_level_text = register_cvar("gxm_level_text","0"); // Show your level by : 1 = HUD message, 0 = Simple colored text message.
	show_rank = register_cvar("gxm_show_rank","1"); // Show rank in /top20? 1 = Yes, 0 = No.
	level_style = register_cvar("gxm_level_style","0"); // You will gain each level new gun : 1 = Yes, 0 = No,select your gun by menu.
	enable_grenades = register_cvar("gxm_grenades","1"); // Give to player grenades? 1 = Yes, 0 = No.
	min_licz_graczy = register_cvar("min_liczba_graczy","3"); // min graczy aby dawalo expa
	
	enable_triple = register_cvar("gxm_triple","1"); // Enable Triple Kill bonus xp? 1 = Yes, 0 = No.
	xp_triple = register_cvar("gxm_triple_xp","10"); // How much bonus xp give for Triple Kill?
	triple_kills = register_cvar("gxm_triple_kills","3"); // How much kills needed to give bonus xp?
	enable_ultra = register_cvar("gxm_ultra","1"); // Enable Ultra Kill bonus xp? 1 = Yes, 0 = No.
	xp_ultra = register_cvar("gxm_ultra_xp","20"); // How much bonus xp give for Ultra Kill?
	ultra_kills = register_cvar("gxm_ultra_kills","6"); // How much kills needed to give bonus xp?
	xp_die_zombie = register_cvar("zp_extra_probaxp","10"); // ile expa za zginiecie zm
	xp_damage_xp = register_cvar("zp_damage_need","2000"); // ile damage potrzeba aby dalo expa
	xp_damage_give = register_cvar("zp_damage_xp","10"); // ile expa ma dawac za osiagniecie pulapu DMG
	doswiadczenie_za_asyste = register_cvar("zp_asist_xp","10"); // ile expa ma dawac za asyste
	obrazenia_za_asyste = register_cvar("zp_asist_dmg","300"); // ile expa ma dawac za asyste
	
	cvar_reward_ap_nemesis = register_cvar("zp_reward_ap_nemesis","5");
	cvar_reward_xp_nemesis = register_cvar("zp_reward_xp_nemesis","50");
	cvar_reward_ap_survivor = register_cvar("zp_reward_ap_survivor","5");
	cvar_reward_xp_survivor = register_cvar("zp_reward_xp_survivor","50");
	cvar_reward_ap_assassin = register_cvar("zp_reward_ap_assassin","5");
	cvar_reward_xp_assassin = register_cvar("zp_reward_xp_assassin","50");
	cvar_reward_ap_sniper = register_cvar("zp_reward_ap_sniper","5");
	cvar_reward_xp_sniper = register_cvar("zp_reward_xp_sniper","50");
	cvar_reward_ap_matka = register_cvar("zp_reward_ap_matka","3");
	cvar_reward_xp_matka = register_cvar("zp_reward_xp_matka","20");
	cvar_reward_ap_last = register_cvar("zp_reward_ap_last","3");
	cvar_reward_xp_last = register_cvar("zp_reward_xp_last","20");
	
	enable_admin_xp = register_cvar("gxm_admin_xp","1"); // Enable Extra xp for killing? 1 = Yes, 0 = No.
	admin_xp = register_cvar("gxm_extra_xp","10"); // How much extra xp give to admins?
	
					// SQLx cvars
	mysqlx_host = register_cvar ("gxm_host", ""); // The host from the db
	mysqlx_user = register_cvar ("gxm_user", ""); // The username from the db login
	mysqlx_pass = register_cvar ("gxm_pass", ""); // The password from the db login
	mysqlx_db = register_cvar ("gxm_dbname", ""); // The database name 
	
					// Events //
	register_event("DeathMsg", "event_deathmsg", "a");
	register_event("CurWeapon","CurWeapon","be", "1=1");
//	register_event("StatusValue", "Event_StatusValue", "bd", "1=2")
	register_logevent("EventRoundEnd", 2, "1=Round_End");
	
	//info w sayu
	register_message(get_user_msgid("SayText"),"handleSayText");
	
	//asysta
	register_event("DeathMsg", "kiled", "ae");
	RegisterHam(Ham_TakeDamage, "player", "fwdamage",1);
	
	//xp za dmg
	register_event("Damage", "Damage", "be", "2!0", "3=0", "4!0")
	
	//bonusy goldow
	RegisterHam(Ham_TakeDamage, "player", "TakeDamage");
	new szWeapon[17]
	for(new i=1; i<=30; i++)
	{
		if( !(NOCLIP_WPN_BS & (1<<i)) && get_weaponname(i, szWeapon, charsmax(szWeapon)) )
		{
			if( !(SHOTGUNS_BS & (1<<i)) )
			{
				RegisterHam(Ham_Weapon_Reload, szWeapon, "Weapon_Reload_Post", 1)
			}
		}
	}
	
					// Forwards //
	RegisterHam(Ham_Spawn, "player", "fwd_PlayerSpawn", 1);
	
	register_forward(FM_Touch, "fwd_Touch");
	
					// Messages //
	#if defined NORMAL_MOD || defined ZOMBIE_SWARM
	register_message(get_user_msgid("StatusIcon"),	"Message_StatusIcon")
	#endif
	
					// Other //	
	register_menucmd(register_menuid("Main Menu"), 1023, "main_menu_info")
	
	register_dictionary("gunxpmod.txt");
	//sql
	set_task(1.0, "sql_start");
	
	set_task(500.0, "InfoAutor");
					
	SayTxT = get_user_msgid("SayText");
	
	g_msgHudSync1 = CreateHudSyncObj()
	g_maxplayers = get_maxplayers();
	
	nocny_exp = false
	
	//exp x2
	set_task(1.0, "Sprawdz");
	pcvarOdgodziny = register_cvar("eog_expodgodziny", "23");
	pcvarDogodziny = register_cvar("eog_expdogodziny", "9");
	
	set_task(60.0, "increaseMinutes", .flags="b")
	set_task(60.0, "TaskZapiszExp", 0, _, _, "b")
	
	//zmodyfikowany zapis do sql
	ResetujZapytanie()
}

public InfoAutor()
{
	ColorChat(0, GREEN, "[ZM EXP]^1 Paczka^4 ZM EXP^1 stworzona przez^4 CSnajper'a^1 (^4CSnajper.eu^1)");
}

public plugin_natives()
{
					// Player natives //
	register_native("get_user_xp", "native_get_user_xp", 1);
	register_native("gunxp_showmenu", "native_showmenu", 1);
	register_native("moze_wybrac_bron", "native_mozewybracbron", 1);
	register_native("set_user_xp", "native_set_user_xp", 1);
	register_native("get_user_level", "native_get_user_level", 1);
	register_native("set_user_level", "native_set_user_level", 1);
	register_native("nat_wczytalo", "native_wczytalo", 1);
	register_native("menu_pomocy", "native_menu_pomocy", 1);
	
	//statystyki
	register_native("dodaj_ap_staty", "native_dodaj_ap_staty", 1);
	register_native("show_stats", "native_show_stats", 1);
	register_native("daj_pkt_rank", "native_daj_pkt_rank", 1);
	register_native("get_user_max_level", "native_get_user_max_level", 1);
}

public native_dodaj_ap_staty(id)
{
	g_stats_ammopacks[id]++
	
	return PLUGIN_CONTINUE;
}public native_daj_pkt_rank(id, ile)
{
	g_stats_points[id] += ile
	
	return PLUGIN_CONTINUE;
}
public native_show_stats(id)
{
	if(get_gametime() < 30)
	{
		client_print(id, print_chat, "Musisz poczekac jeszcze %i sekund aby przegladac statystyki.", 30-floatround(get_gametime()))
		return PLUGIN_CONTINUE;
	}
	Staty(id)
	
	return PLUGIN_CONTINUE;
}

public plugin_precache()
{
	levelspr = engfunc(EngFunc_PrecacheModel, "sprites/xfire.spr");
	levelspr2 = engfunc(EngFunc_PrecacheModel, "sprites/xfire2.spr");
	
	engfunc(EngFunc_PrecacheSound, LevelUp);
	
	precache_model("models/gold/p_glock18.mdl")
	precache_model("models/gold/p_ak47.mdl")
	precache_model("models/gold/p_aug.mdl")
	precache_model("models/gold/p_awp.mdl")
	precache_model("models/gold/p_deagle.mdl")
	precache_model("models/gold/p_elite.mdl")
	precache_model("models/gold/p_famas.mdl")
	precache_model("models/gold/p_fiveseven.mdl")
	precache_model("models/gold/p_g3sg1.mdl")
	precache_model("models/gold/p_galil.mdl")
	precache_model("models/gold/p_m3.mdl")
	precache_model("models/gold/p_m4a1.mdl")
	precache_model("models/gold/p_m249.mdl")
	precache_model("models/gold/p_mac10.mdl")
	precache_model("models/gold/p_mp5.mdl")
	precache_model("models/gold/p_p90.mdl")
	precache_model("models/gold/p_p228.mdl")
	precache_model("models/gold/p_scout.mdl")
	precache_model("models/gold/p_sg550.mdl")
	precache_model("models/gold/p_sg552.mdl")
	precache_model("models/gold/p_tmp.mdl")
	precache_model("models/gold/p_ump45.mdl")
	precache_model("models/gold/p_usp.mdl")
	precache_model("models/gold/p_xm1014.mdl")
	precache_model("models/gold/v_glock18.mdl")
	precache_model("models/gold/v_ak47.mdl")
	precache_model("models/gold/v_aug.mdl")
	precache_model("models/gold/v_awp.mdl")
	precache_model("models/gold/v_deagle.mdl")
	precache_model("models/gold/v_elite.mdl")
	precache_model("models/gold/v_famas.mdl")
	precache_model("models/gold/v_fiveseven.mdl")
	precache_model("models/gold/v_g3sg1.mdl")
	precache_model("models/gold/v_galil.mdl")
	precache_model("models/gold/v_m3.mdl")
	precache_model("models/gold/v_m4a1.mdl")
	precache_model("models/gold/v_m249.mdl")
	precache_model("models/gold/v_mac10.mdl")
	precache_model("models/gold/v_mp5.mdl")
	precache_model("models/gold/v_p90.mdl")
	precache_model("models/gold/v_p228.mdl")
	precache_model("models/gold/v_scout.mdl")
	precache_model("models/gold/v_sg550.mdl")
	precache_model("models/gold/v_sg552.mdl")
	precache_model("models/gold/v_tmp.mdl")
	precache_model("models/gold/v_ump45.mdl")
	precache_model("models/gold/v_usp.mdl")
	precache_model("models/gold/v_xm1014.mdl")

}
public plugin_cfg()
{
	new ConfDir[32], File[192];
	
	get_configsdir( ConfDir, charsmax( ConfDir ) );
	formatex( File, charsmax( File ), "%s/gunxpmod.cfg", ConfDir );
	
	if( !file_exists( File ) )
	{
		server_print( "File %s doesn't exist!", File );
		write_file( File, " ", -1 );
	}
	else
	{	
		server_print( "%s successfully loaded.", File );
		server_cmd( "exec %s", File );
	}
	
    //Open our vault and have g_Vault store the handle.
	g_Vault = nvault_open( "gunxpmod" );

	//Make the plugin error if vault did not successfully open
	if ( g_Vault == INVALID_HANDLE )
		set_fail_state( "Error opening GunXpMod nVault, file does not exist!" );
}
/*public plugin_end()
{
	//Close the vault when the plugin ends (map change\server shutdown\restart)
	//nvault_close( g_Vault );
	
	new Handle:hConnection, iError, szError[256];

	if((hConnection = SQL_Connect(g_SqlTuple, iError, szError, 255)))
	{
		replace(ZapiszExp[giLen-1], giLen, ZapiszExp[giLen-1], "")
		
		giLen -= 1
		
		giLen += formatex(ZapiszExp[giLen], giMax-giLen," ON DUPLICATE KEY UPDATE `lvl`=VALUES(`lvl`), `exp`=VALUES(`exp`), `quest_gracza`=VALUES(`quest_gracza`), `ile_juz`=VALUES(`ile_juz`), `ile_wykonano`=VALUES(`ile_wykonano`), `totalpoints`=VALUES(`totalpoints`), `ammopacks`=VALUES(`ammopacks`), `dam_done`=VALUES(`dam_done`), `zm_kill`=VALUES(`zm_kill`), `hm_infkill`=VALUES(`hm_infkill`), `deaths`=VALUES(`deaths`), ")
		giLen += formatex(ZapiszExp[giLen], giMax-giLen,"`nem_kill`=VALUES(`nem_kill`), `sur_kill`=VALUES(`sur_kill`), `ass_kill`=VALUES(`ass_kill`), `sni_kill`=VALUES(`sni_kill`), `matki_kill`=VALUES(`matki_kill`), `last_hm_kill`=VALUES(`last_hm_kill`), `zm_win`=VALUES(`zm_win`), `hm_win`=VALUES(`hm_win`), `czas_online`=VALUES(`czas_online`)")
		
		log_to_file("test_zapis.log", "%s", ZapiszExp);
		
		new Handle:hQuery
		
		if(ilosc_wpisow > 0)
			hQuery = SQL_PrepareQuery(hConnection, ZapiszExp);
		else
		{
			ResetujZapytanie()
			log_to_file("sql.log", "Brak Wpisow");
		}

		if(SQL_Execute(hQuery))
		{
			log_to_file("sql.log", "Zapisano dane do bazy");
		}
		else
		{
			SQL_QueryError(hQuery, szError, 255);
			log_error(AMX_ERR_GENERAL, "Blad w zapytaniu !");
			log_error(AMX_ERR_GENERAL, "Kod bledu: %i", iError);
			log_error(AMX_ERR_GENERAL, "Tresc bledu: %s", szError);
		}

		SQL_FreeHandle(hQuery); // Niech was reka boska broni, przed zapomnieniem o tym
	}
	else
	{
		log_error(AMX_ERR_GENERAL, "Brak polaczenia z baza danych !");
		log_error(AMX_ERR_GENERAL, "Kod bledu: %i", iError);
		log_error(AMX_ERR_GENERAL, "Tresc bledu: %s", szError);
	}

	SQL_FreeHandle(hConnection);
}*/

public client_putinserver(id) {
	remove_task( TASK_SHOW_LEVEL + id );
	set_task(0.1, "task_show_level", TASK_SHOW_LEVEL + id)
	set_task(10.0, "wymus", id)
}
public wymus(id) {
	client_cmd(id, "cl_corpsestay 1")
}
public client_connect(id)
{
	g_remember_selection[id] = 0;
	g_remember_selection_pistol[id] = 0;
	asked_sql[id]=0
	wczytalo[id] = false
	PlayerXp[id] = 0
	PlayerLevel[id] = 0
	player_xp_old[id] = 0
	
	if(g_boolsqlOK)
		LoadLevel(id)
	else set_task(3.0, "Sprawdz_baze", id+TASK_LOAD_LEVEL);
}

public Sprawdz_baze(id)
{
	id -= TASK_LOAD_LEVEL
	if(g_boolsqlOK)
		LoadLevel(id)
	else
	{
		if(task_exists(id+TASK_LOAD_LEVEL))
			remove_task(id+TASK_LOAD_LEVEL)
			
		set_task(3.0, "Sprawdz_baze", id+TASK_LOAD_LEVEL);
	}
	return PLUGIN_CONTINUE;
}

public client_disconnect(id)
{
	if(wczytalo[id])
		DodajWpis(id)

	remove_task( TASK_SHOW_LEVEL + id );
}
public Message_StatusIcon(iMsgId, MSG_DEST, id) 
{ 
	if( !get_pcvar_num(p_Enabled) )
		return PLUGIN_HANDLED;
		
	static szIcon[5] 
	get_msg_arg_string(2, szIcon, 4) 
	if( szIcon[0] == 'b' && szIcon[2] == 'y' && szIcon[3] == 'z' ) 
	{ 
		if( get_msg_arg_int(1)) 
		{ 
			fm_cs_set_user_nobuy(id) 
			return PLUGIN_HANDLED;
		} 
	}  
	
	return PLUGIN_CONTINUE;
}
public fwd_Touch(ent, id)
{
	if (!is_user_alive(id) || !pev_valid( ent ) )
		return FMRES_IGNORED;
	if(zp_class_survivor_get(id) || zp_class_sniper_get(id))
		return FMRES_IGNORED;
	
	static szEntModel[32]; 
	pev( ent , pev_model , szEntModel , 31 ); 
    
	if(PlayerLevel[id] > 23)
	{
		for (new level_equip_id = PlayerLevel[id] - 24 + 1; level_equip_id < MAXLEVEL-24; level_equip_id++) 
		{ 
			if ( equali( szEntModel , WEAPONMDL[level_equip_id] ) ) 
			{ 
				return FMRES_SUPERCEDE; 
			}  
		} 
	}
	else
	{
		for (new level_equip_id = PlayerLevel[id] + 1; level_equip_id < MAXLEVEL-24; level_equip_id++) 
		{ 
			if ( equali( szEntModel , WEAPONMDL[level_equip_id] ) ) 
			{ 
				return FMRES_SUPERCEDE; 
			}  
		}
	}

	return FMRES_IGNORED;
}
public fwd_PlayerSpawn(id)
{
	if( !get_pcvar_num(p_Enabled) || !is_user_alive(id))
		return;
	
	if(!zp_core_is_zombie(id))
		wybral_bron[id] = 0
	
	g_kills[id] = 0
		
	#if defined ZOMBIE_SWARM
	if ( !get_pcvar_num(level_style) && cs_get_user_team(id) == CS_TEAM_CT )
	{
		StripPlayerWeapons(id);
			
		set_task(2.0, "show_main_menu_level", id)
	}
	#endif
		
	#if defined NORMAL_MOD || defined ZOMBIE_INFECTION
	if ( !get_pcvar_num(level_style))
	{
		StripPlayerWeapons(id);
			
		set_task(2.0, "show_main_menu_level", id)
	}
	#endif
		
	if( get_pcvar_num(show_level_text) )
	{
		remove_task( TASK_SHOW_LEVEL + id );		

		set_task(0.1, "task_show_level", TASK_SHOW_LEVEL + id)
	}
	
	#if defined ZOMBIE_SWARM	
	if ( get_pcvar_num(level_style) && cs_get_user_team(id) == CS_TEAM_CT )
	{
		set_task(0.3, "give_weapon", id);
	}
	#endif

	#if defined NORMAL_MOD || defined ZOMBIE_INFECTION || defined ZOMBIE_PLAGUE
	if ( get_pcvar_num(level_style) )
	{
		set_task(0.3, "give_weapon", id);
	}
	#endif
	
	for(new p = 1; p <= g_maxplayers; p++)
	{
		g_iDamage_asysta[id][p] = 0
		g_iDamage_asysta[p][id] = 0
	}

}

#if defined ZOMBIE_PLAGUE
public zp_user_humanized_post(id)
{
	if( !get_pcvar_num(p_Enabled) || !is_user_alive(id) || zp_class_survivor_get(id) || zp_class_sniper_get(id))
		return;
	StripPlayerWeapons(id);
	set_task(1.0, "show_main_menu_level", id);
}
#endif

#if defined ZOMBIE_BIOHAZARD
public event_infect(g_victim, g_attacker)
{
	if( !get_pcvar_num(p_Enabled) )
		return;
	
	new counted_triple = get_pcvar_num(xp_kill) + get_pcvar_num(xp_triple) + get_pcvar_num(enable_admin_xp) && get_user_flags(g_attacker) & ADMIN_LEVEL_H ? get_pcvar_num(admin_xp) : 0
	new counted_ultra = get_pcvar_num(xp_kill) + get_pcvar_num(xp_ultra) + get_pcvar_num(enable_admin_xp) && get_user_flags(g_attacker) & ADMIN_LEVEL_H ? get_pcvar_num(admin_xp) : 0
	
	if((1 <= g_attacker <= g_maxplayers))
	{
		if(g_victim != g_attacker)
		{
			g_kills[g_attacker]++;
			if(PlayerLevel[g_attacker] < MAXLEVEL-1) 
			{
				if ( g_kills[g_attacker] == get_pcvar_num(triple_kills) && get_pcvar_num(enable_triple) )
				{
					GiveXP(g_attacker, counted_triple)
					
					set_dhudmessage( 0, 255, 0, 0.5, 0.33, 1, 2.0, 2.0, 0.1, 1.0, false )
					show_dhudmessage(g_attacker, "%L", LANG_SERVER, "TRIPLE_XP", counted_triple + (get_pcvar_num(enable_admin_xp) && get_user_flags(g_attacker) & ADMIN_LEVEL_H ? get_pcvar_num(admin_xp) : 0))
//					set_hudmessage(0, 255, 50, 0.50, 0.33, 1, 2.0, 2.0)
//					show_hudmessage(g_attacker, "%L", LANG_SERVER, "TRIPLE_XP", counted_triple + (get_pcvar_num(enable_admin_xp) && get_user_flags(g_attacker) & ADMIN_LEVEL_H ? get_pcvar_num(admin_xp) : 0))
				}
				else if ( g_kills[g_attacker] == get_pcvar_num(ultra_kills) && get_pcvar_num(enable_ultra) )
				{
					GiveXP(g_attacker, counted_ultra)
					
					set_dhudmessage( 0, 255, 50, 0.5, 0.33, 1, 2.0, 2.0, 0.1, 1.0, false )
					show_dhudmessage(g_attacker, "%L", LANG_SERVER, "ULTRA_XP", counted_ultra + (get_pcvar_num(enable_admin_xp) && get_user_flags(g_attacker) & ADMIN_LEVEL_H ? get_pcvar_num(admin_xp) : 0))
//					set_hudmessage(0, 255, 50, 0.50, 0.33, 1, 2.0, 2.0)
//					show_hudmessage(g_attacker, "%L", LANG_SERVER, "ULTRA_XP", counted_ultra + (get_pcvar_num(enable_admin_xp) && get_user_flags(g_attacker) & ADMIN_LEVEL_H ? get_pcvar_num(admin_xp) : 0))
				}
				else
				{
					GiveXP(g_attacker, get_pcvar_num(xp_kill))
					
//					set_hudmessage(0, 255, 50, 0.50, 0.33, 1, 2.0, 2.0)
//					show_hudmessage(g_attacker, "+%i", (get_pcvar_num(enable_admin_xp) && get_user_flags(g_attacker) & ADMIN_LEVEL_H ? get_pcvar_num(admin_xp) : 0) + get_pcvar_num(xp_kill) )
					set_dhudmessage( 0, 255, 50, 0.5, 0.33, 1, 2.0, 2.0, 0.1, 1.0, false )
					show_dhudmessage(g_attacker, "+%i", (get_pcvar_num(enable_admin_xp) && get_user_flags(g_attacker) & ADMIN_LEVEL_H ? get_pcvar_num(admin_xp) : 0) + get_pcvar_num(xp_kill) )
				}
			}
		}
	}
}
#endif

#if defined ZOMBIE_PLAGUE
public zp_user_infected_post(g_victim, g_attacker)
{
	if( !get_pcvar_num(p_Enabled) )
		return;
	
	new counted_triple = get_pcvar_num(xp_kill) + get_pcvar_num(xp_triple)
	new counted_ultra = get_pcvar_num(xp_kill) + get_pcvar_num(xp_ultra)
	
	g_stats_deaths[g_victim]++
	
	if((1 <= g_attacker <= g_maxplayers))
	{
		if(g_victim != g_attacker)
		{
			g_kills[g_attacker]++;
			if(PlayerLevel[g_attacker] < MAXLEVEL-1) 
			{
				if ( get_pcvar_num(enable_admin_xp) && get_user_flags(g_attacker) & ADMIN_LEVEL_H)
				{
					GiveXP(g_attacker, get_pcvar_num(admin_xp))
				}
					
				if ( g_kills[g_attacker] == get_pcvar_num(triple_kills) && get_pcvar_num(enable_triple) )
				{
					GiveXP(g_attacker, counted_triple)
					
					set_dhudmessage( 0, 255, 0, 0.5, 0.33, 1, 2.0, 2.0, 0.1, 1.0, false )
					show_dhudmessage(g_attacker, "%L", LANG_SERVER, "TRIPLE_XP", przelicz_exp(g_attacker, counted_triple))					
//					set_hudmessage(0, 255, 50, 0.50, 0.33, 1, 2.0, 2.0)
//					show_hudmessage(g_attacker, "%L", LANG_SERVER, "TRIPLE_XP", counted_triple + (get_pcvar_num(enable_admin_xp) && get_user_flags(g_attacker) & ADMIN_LEVEL_H ? get_pcvar_num(admin_xp) : 0))

					if(zp_core_is_zombie(g_attacker))
						g_stats_hm_infkill[g_attacker]++
					else
						g_stats_zm_kill[g_attacker]++
					
					g_stats_points[g_attacker]++
				}
				else if ( g_kills[g_attacker] == get_pcvar_num(ultra_kills) && get_pcvar_num(enable_ultra) )
				{
					GiveXP(g_attacker, counted_ultra)
					set_dhudmessage( 0, 255, 50, 0.5, 0.33, 1, 2.0, 2.0, 0.1, 1.0, false )
					show_dhudmessage(g_attacker, "%L", LANG_SERVER, "ULTRA_XP", przelicz_exp(g_attacker, counted_ultra))
//					set_hudmessage(0, 255, 50, 0.50, 0.33, 1, 2.0, 2.0)
//					show_hudmessage(g_attacker, "%L", LANG_SERVER, "ULTRA_XP", counted_ultra + (get_pcvar_num(enable_admin_xp) && get_user_flags(g_attacker) & ADMIN_LEVEL_H ? get_pcvar_num(admin_xp) : 0))
				
					if(zp_core_is_zombie(g_attacker))
						g_stats_hm_infkill[g_attacker]++
					else
						g_stats_zm_kill[g_attacker]++
					
					g_stats_points[g_attacker]++
				}
				else
				{
					GiveXP(g_attacker, get_pcvar_num(xp_kill))
					
					set_dhudmessage( 0, 255, 50, 0.5, 0.33, 1, 2.0, 2.0, 0.1, 1.0, false )
					show_dhudmessage(g_attacker, "+%i", przelicz_exp(g_attacker, get_pcvar_num(xp_kill)))
//					set_hudmessage(0, 255, 50, 0.50, 0.33, 1, 2.0, 2.0)
//					show_hudmessage(g_attacker, "+%i", (get_pcvar_num(enable_admin_xp) && get_user_flags(g_attacker) & ADMIN_LEVEL_H ? get_pcvar_num(admin_xp) : 0) + get_pcvar_num(xp_kill) )
				
					if(zp_core_is_zombie(g_attacker))
						g_stats_hm_infkill[g_attacker]++
					else
						g_stats_zm_kill[g_attacker]++
					
					g_stats_points[g_attacker]++
				}
			}
		}
	}
}
#endif

public event_deathmsg()
{
	if( !get_pcvar_num(p_Enabled) )
		return;
	
	new g_attacker = read_data(1);
	new g_victim = read_data(2);
	
	g_stats_deaths[g_victim]++
	
	new k_name[32]
	new v_name[32]
	get_user_name(g_attacker, k_name, 31)
	get_user_name(g_victim, v_name, 31)
	
	new counted_triple = get_pcvar_num(xp_kill) + get_pcvar_num(xp_triple)
	new counted_ultra = get_pcvar_num(xp_kill) + get_pcvar_num(xp_ultra)
	new xp_diezombie = get_pcvar_num(xp_die_zombie)
	
	if((1 <= g_attacker <= g_maxplayers))
	{
		if(g_victim != g_attacker)
		{
			g_kills[g_attacker]++;
			if ( get_pcvar_num(enable_admin_xp) && get_user_flags(g_attacker) & ADMIN_LEVEL_H)
			{
				GiveXP(g_attacker, get_pcvar_num(admin_xp))
			}
					
			if ( g_kills[g_attacker] == get_pcvar_num(triple_kills) && get_pcvar_num(enable_triple) )
			{
				GiveXP(g_attacker, counted_triple)
				set_dhudmessage( 0, 40, 255, 0.5, 0.33, 1, 2.0, 2.0, 0.1, 1.0, false )
				show_dhudmessage(g_attacker, "%L", LANG_SERVER, "TRIPLE_XP", przelicz_exp(g_attacker, counted_triple))
//				set_hudmessage(0, 40, 255, 0.50, 0.33, 1, 2.0, 2.0)
//				show_hudmessage(g_attacker, "%L", LANG_SERVER, "TRIPLE_XP", counted_triple + (get_pcvar_num(enable_admin_xp) && get_user_flags(g_attacker) & ADMIN_LEVEL_H ? get_pcvar_num(admin_xp) : 0))
				
				if(zp_core_is_zombie(g_attacker))
				{
					g_stats_hm_infkill[g_attacker]++
				}
				else
				{
					g_stats_zm_kill[g_attacker]++
				}
				
				g_stats_points[g_attacker]++
			}
			else if ( g_kills[g_attacker] == get_pcvar_num(ultra_kills) && get_pcvar_num(enable_ultra) )
			{
				GiveXP(g_attacker, counted_ultra)
					
				set_dhudmessage( 0, 40, 255, 0.5, 0.33, 1, 2.0, 2.0, 0.1, 1.0, false )
				show_dhudmessage(g_attacker, "%L", LANG_SERVER, "ULTRA_XP", przelicz_exp(g_attacker, counted_ultra))
//				set_hudmessage(255, 30, 0, 0.50, 0.33, 1, 2.0, 2.0)
//				show_hudmessage(g_attacker, "%L", LANG_SERVER, "ULTRA_XP", counted_ultra + (get_pcvar_num(enable_admin_xp) && get_user_flags(g_attacker) & ADMIN_LEVEL_H ? get_pcvar_num(admin_xp) : 0))

				if(zp_core_is_zombie(g_attacker))
				{
					g_stats_hm_infkill[g_attacker]++
				}
				else
				{
					g_stats_zm_kill[g_attacker]++
				}
				
				g_stats_points[g_attacker]++
			}
			else
			{
				GiveXP(g_attacker, get_pcvar_num(xp_kill))
				
				set_dhudmessage( 0, 40, 255, 0.5, 0.33, 1, 2.0, 2.0, 0.1, 1.0, false )
				show_dhudmessage(g_attacker, "+%i", przelicz_exp(g_attacker, get_pcvar_num(xp_kill)))
//				set_hudmessage(0, 255, 50, 0.50, 0.33, 1, 2.0, 2.0)
//				show_dhudmessage(g_attacker, "+%i", (get_pcvar_num(enable_admin_xp) && get_user_flags(g_attacker) & ADMIN_LEVEL_H ? get_pcvar_num(admin_xp) : 0) + get_pcvar_num(xp_kill) )

				if(zp_core_is_zombie(g_attacker))
				{
					g_stats_hm_infkill[g_attacker]++
				}
				else
				{
					g_stats_zm_kill[g_attacker]++
				}
				
				g_stats_points[g_attacker]++
			}
			if(zp_core_is_zombie(g_victim) && g_attacker != 0){
				
				GiveXP(g_victim, xp_diezombie)
				
				set_dhudmessage( 0, 40, 255, 0.5, 0.33, 1, 2.0, 2.0, 0.1, 1.0, false )
				set_dhudmessage( 250, 0, 0, 0.75, 0.5, 2, 2.0, 3.0, 0.1, 1.0, false )
				show_dhudmessage( g_victim,"         +%i XP^n za Probe Zarazenia", przelicz_exp(g_victim, xp_diezombie))
			}
			if(zp_class_nemesis_get(g_victim))
			{
				ColorChat(0, GREEN, "[ZM EXP]^x03 %s^x01 dostal^x04 %i XP ^x01 oraz^x04 %i AP^x01 - zabil Nemesis ^x03(%s)", k_name, przelicz_exp(g_attacker, get_pcvar_num(cvar_reward_xp_nemesis)), get_pcvar_num(cvar_reward_ap_nemesis), v_name);
				zp_ammopacks_set(g_attacker, zp_ammopacks_get(g_attacker) + get_pcvar_num(cvar_reward_ap_nemesis))
				GiveXP(g_attacker, get_pcvar_num(cvar_reward_xp_nemesis))
				
				g_stats_nem_kill[g_attacker]++
				g_stats_points[g_attacker] += 50
			}
			if(zp_class_survivor_get(g_victim))
			{
				ColorChat(0, GREEN, "[ZM EXP]^x03 %s^x01 dostal^x04 %i XP ^x01 oraz^x04 %i AP^x01 - zabil Survivora ^x03(%s)", k_name, przelicz_exp(g_attacker, get_pcvar_num(cvar_reward_xp_survivor)), get_pcvar_num(cvar_reward_ap_survivor), v_name);
				zp_ammopacks_set(g_attacker, zp_ammopacks_get(g_attacker) + get_pcvar_num(cvar_reward_ap_survivor))
				GiveXP(g_attacker, get_pcvar_num(cvar_reward_xp_survivor))
				
				g_stats_sur_kill[g_attacker]++
				g_stats_points[g_attacker] += 50
			}
			if(zp_class_assassin_get(g_victim))
			{
				ColorChat(0, GREEN, "[ZM EXP]^x03 %s^x01 dostal^x04 %i XP ^x01 oraz^x04 %i AP^x01 - zabil Assassina ^x03(%s)", k_name, przelicz_exp(g_attacker, get_pcvar_num(cvar_reward_xp_assassin)), get_pcvar_num(cvar_reward_ap_assassin), v_name);
				zp_ammopacks_set(g_attacker, zp_ammopacks_get(g_attacker) + get_pcvar_num(cvar_reward_ap_assassin))
				GiveXP(g_attacker, get_pcvar_num(cvar_reward_xp_assassin))
				
				g_stats_ass_kill[g_attacker]++
				g_stats_points[g_attacker] += 50
			}
			if(zp_class_sniper_get(g_victim))
			{
				ColorChat(0, GREEN, "[ZM EXP]^x03 %s^x01 dostal^x04 %i XP ^x01 oraz^x04 %i AP^x01 - zabil Snajpera ^x03(%s)", k_name, przelicz_exp(g_attacker, get_pcvar_num(cvar_reward_xp_sniper)), get_pcvar_num(cvar_reward_ap_sniper), v_name);
				zp_ammopacks_set(g_attacker, zp_ammopacks_get(g_attacker) + get_pcvar_num(cvar_reward_ap_sniper))
				GiveXP(g_attacker, get_pcvar_num(cvar_reward_xp_sniper))
				
				g_stats_sni_kill[g_attacker]++
				g_stats_points[g_attacker] += 50
			}
			
			new const Infection[] = "Infection Mode" 
			new InfectionID = zp_gamemodes_get_id(Infection)
			
			new const Multi[] = "Multiple Infection Mode" 
			new MultiID = zp_gamemodes_get_id(Multi)
			
			if(zp_core_is_last_human(g_victim) && (zp_gamemodes_get_current() == InfectionID || zp_gamemodes_get_current() == MultiID))
			{
				ColorChat(0, GREEN, "[ZM EXP]^x03 %s^x01 dostal^x04 %i XP ^x01 oraz^x04 %i AP^x01 - zabil Ostatniego Czlowieka ^x03(%s)", k_name, przelicz_exp(g_attacker, get_pcvar_num(cvar_reward_xp_last)), get_pcvar_num(cvar_reward_ap_last), v_name);
				zp_ammopacks_set(g_attacker, zp_ammopacks_get(g_attacker) + get_pcvar_num(cvar_reward_ap_last))
				GiveXP(g_attacker, get_pcvar_num(cvar_reward_xp_last))
				
				g_stats_last_hm_kill[g_attacker]++
				g_stats_points[g_attacker] += 10
			}
			else if(zp_core_is_first_zombie(g_victim) && (zp_gamemodes_get_current() == InfectionID || zp_gamemodes_get_current() == MultiID))
			{
				ColorChat(0, GREEN, "[ZM EXP]^x03 %s^x01 dostal^x04 %i XP ^x01 oraz^x04 %i AP^x01 - zabil Matke Zombi ^x03(%s)", k_name, przelicz_exp(g_attacker, get_pcvar_num(cvar_reward_xp_matka)), get_pcvar_num(cvar_reward_ap_matka), v_name);
				zp_ammopacks_set(g_attacker, zp_ammopacks_get(g_attacker) + get_pcvar_num(cvar_reward_ap_matka))
				GiveXP(g_attacker, get_pcvar_num(cvar_reward_xp_matka))
				
				g_stats_matki_kill[g_attacker]++
				g_stats_points[g_attacker] += 10
			}
		}
	}
}

public Damage(id)
{
	new attacker_id = get_user_attacker(id)
	new damage = read_data(2);
	
	if(!is_user_connected(id) || !is_user_connected(attacker_id) || get_user_team(id) == get_user_team(attacker_id) || !is_user_alive(id) || zp_class_nemesis_get(attacker_id) || zp_class_survivor_get(attacker_id) || zp_class_sniper_get(attacker_id) || zp_class_assassin_get(attacker_id))
		return PLUGIN_CONTINUE;
	
	damage2[attacker_id] += damage
	g_stats_dam_done[attacker_id] += damage
	g_iDamage_asysta[attacker_id][id] += damage
	new damage_need = get_pcvar_num(xp_damage_xp)
	new xp_give = get_pcvar_num(xp_damage_give)
	if(ilosc_graczy >= min_graczy)
	{
		while(damage2[attacker_id]>damage_need)
		{
			damage2[attacker_id]-=damage_need;
			GiveXP(attacker_id, xp_give)
			set_dhudmessage( 250, 0, 0, 0.8, 0.4, 2, 2.0, 3.0, 0.1, 1.0, false )
			show_dhudmessage( attacker_id,"     +%i XP^n za %i DMG", przelicz_exp(attacker_id, xp_give), damage_need)
		}
	}
	return PLUGIN_CONTINUE;
}

/*public Event_StatusValue(id)
{
	new target = read_data(2)
  	if(target != id && target != 0 && get_pcvar_num(p_Enabled))
  	{
		static sName[32];
		get_user_name(target, sName, 31)
	
	// Format classname
	static class_name[32], transkey[64]
	
	if (zp_core_is_zombie(target)) // zombies
	{
		// Nemesis Class loaded?
		if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(target))
			formatex(class_name, charsmax(class_name), "%L", target, "CLASS_NEMESIS")
		else
		{
			zp_class_zombie_get_name(zp_class_zombie_get_current(target), class_name, charsmax(class_name))
			
			// ML support for class name
			formatex(transkey, charsmax(transkey), "ZOMBIENAME %s", class_name)
			if (GetLangTransKey(transkey) != TransKey_Bad) formatex(class_name, charsmax(class_name), "%L", target, transkey)
		}
	}
	else // humans
	{
		// Survivor Class loaded?
		if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_survivor_get(target))
			formatex(class_name, charsmax(class_name), "%L", target, "CLASS_SURVIVOR")
		else
		{
			zp_class_human_get_name(zp_class_human_get_current(target), class_name, charsmax(class_name))
			
			// ML support for class name
			formatex(transkey, charsmax(transkey), "HUMANNAME %s", class_name)
			if (GetLangTransKey(transkey) != TransKey_Bad) formatex(class_name, charsmax(class_name), "%L", target, transkey)
		}
	}

		set_hudmessage(255, 255, 255, 0.6, -1.0, 0, 0.0, 6.0, 0.0, 0.0, 2)
		ShowSyncHudMsg(target, g_msgHudSync1 , "%L", LANG_SERVER, "LEVEL_TEXT", sName, PlayerLevel[target], PlayerXp[target], LEVELS[PlayerLevel[target]], RANK[PlayerLevel[target]], RANKLEVELS[PlayerLevel[target]], class_name, zp_ammopacks_get(target), get_user_health(target), q_info_zadanie[quest_wyk[target]], ile_wykonano[target])
	}
}*/
public task_show_level(task)
{
	new id = task - TASK_SHOW_LEVEL
	
	set_task(1.0, "task_show_level", TASK_SHOW_LEVEL + id)	
	
	if(!get_pcvar_num(show_level_text) || !get_pcvar_num(p_Enabled) )
		return PLUGIN_CONTINUE;
	
	// Format classname
	static class_name[32], transkey[64]
	if(!is_user_alive(id))
	{
		new target = pev(target, PEV_SPEC_TARGET)
			
		if(!target || target == id)
			return PLUGIN_CONTINUE;
	
		static sName[32];
		get_user_name(target, sName, 31)
	
		// Format classname
		static class_name[32], transkey[64]
	
		if (zp_core_is_zombie(target)) // zombies
		{
			// Nemesis Class loaded?
			if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(target))
				formatex(class_name, charsmax(class_name), "%L", target, "CLASS_NEMESIS")
			else if (LibraryExists(LIBRARY_ASSASIN, LibType_Library) && zp_class_assassin_get(target))
				formatex(class_name, charsmax(class_name), "%L", target, "CLASS_ASSASIN")
			else
			{
				zp_class_zombie_get_name(zp_class_zombie_get_current(target), class_name, charsmax(class_name))
				
				// ML support for class name
				formatex(transkey, charsmax(transkey), "ZOMBIENAME %s", class_name)
				if (GetLangTransKey(transkey) != TransKey_Bad) formatex(class_name, charsmax(class_name), "%L", target, transkey)
			}
		}
		else // humans
		{
			// Survivor Class loaded?
			if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_survivor_get(target))
				formatex(class_name, charsmax(class_name), "%L", target, "CLASS_SURVIVOR")
			else if(LibraryExists(LIBRARY_SNIPER, LibType_Library) && zp_class_sniper_get(target))
				formatex(class_name, charsmax(class_name), "%L", target, "CLASS_SNIPER")
			else
			{
				zp_class_human_get_name(zp_class_human_get_current(target), class_name, charsmax(class_name))
				
				// ML support for class name
				formatex(transkey, charsmax(transkey), "HUMANNAME %s", class_name)
				if (GetLangTransKey(transkey) != TransKey_Bad) formatex(class_name, charsmax(class_name), "%L", target, transkey)
			}
		}

//		set_hudmessage(255, 255, 255, 0.6, -1.0, 0, 0.0, 6.0, 0.0, 0.0)
		set_hudmessage(0, 200, 250, -1.0, 0.65, 0, 0.55, 1.1, 0.0, 0.0, -1)
		ShowSyncHudMsg(id, g_msgHudSync1 , "%L", LANG_SERVER, "LEVEL_TEXT", sName, PlayerLevel[target], RANK[PlayerLevel[target]], class_name, zp_ammopacks_get(target), get_user_health(target), sprawdz_ile_wykonano(target))
		return PLUGIN_CONTINUE;
	}
	if (zp_core_is_zombie(id)) // zombies
	{
		// Nemesis Class loaded?
		if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(id))
			formatex(class_name, charsmax(class_name), "%L", id, "CLASS_NEMESIS")
		else if (LibraryExists(LIBRARY_ASSASIN, LibType_Library) && zp_class_assassin_get(id))
			formatex(class_name, charsmax(class_name), "%L", id, "CLASS_ASSASIN")
		else
		{
			zp_class_zombie_get_name(zp_class_zombie_get_current(id), class_name, charsmax(class_name))
			
			// ML support for class name
			formatex(transkey, charsmax(transkey), "ZOMBIENAME %s", class_name)
			if (GetLangTransKey(transkey) != TransKey_Bad) formatex(class_name, charsmax(class_name), "%L", id, transkey)
		}
	}
	else // humans
	{
		// Survivor Class loaded?
		if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_survivor_get(id))
			formatex(class_name, charsmax(class_name), "%L", id, "CLASS_SURVIVOR")
		else if(LibraryExists(LIBRARY_SNIPER, LibType_Library) && zp_class_sniper_get(id))
			formatex(class_name, charsmax(class_name), "%L", id, "CLASS_SNIPER")
		else
		{
			zp_class_human_get_name(zp_class_human_get_current(id), class_name, charsmax(class_name))
			
			// ML support for class name
			formatex(transkey, charsmax(transkey), "HUMANNAME %s", class_name)
			if (GetLangTransKey(transkey) != TransKey_Bad) formatex(class_name, charsmax(class_name), "%L", id, transkey)
		}
	}
		
	set_hudmessage(255, 0, 0, 0.02, 0.22, 0, 0.0, 1.1, 0.0, 0.0, 1);
	ShowSyncHudMsg(id, g_msgHudSync1 , "%L", LANG_SERVER, "LEVEL_HUD_TEXT", PlayerLevel[id], PlayerXp[id], LEVELS[PlayerLevel[id]], RANK[PlayerLevel[id]], RANKLEVELS[PlayerLevel[id]], class_name, zp_ammopacks_get(id), get_user_health(id))
	return PLUGIN_CONTINUE;
}

public showlevel(id)
{
	if ( !get_pcvar_num(p_Enabled) || get_pcvar_num(show_level_text) )
		return PLUGIN_HANDLED;
	
	client_printcolor(id, "%L", LANG_SERVER, "LEVEL_TEXT2", PlayerLevel[id] , PlayerXp[id], LEVELS[PlayerLevel[id]]);
	client_printcolor(id, "%L", LANG_SERVER, "LEVEL_TEXT3", RANK[PlayerLevel[id]], RANKLEVELS[PlayerLevel[id]]);
	
	return PLUGIN_HANDLED;
}
public descriptionx(id)
{
	new szMotd[2048], szTitle[64], iPos = 0
	format(szTitle, 63, "Info")
	iPos += format(szMotd[iPos], 2047-iPos, "<html><head><style type=^"text/css^">pre{color:#FFB000;}body{background:#000000;margin-left:8px;margin-top:0px;}</style></head><pre><body>")
	iPos += format(szMotd[iPos], 2047-iPos, "^n^n<b>%s</b>^n^n", szTitle)
	iPos += format(szMotd[iPos], 2047-iPos, "%L^n", LANG_SERVER, "DESCRIPTION")
	
	iPos += format(szMotd[iPos], 2047-iPos, "%L", LANG_SERVER, "DESCRIPTION2")
		
	show_motd(id, szMotd, szTitle)
	return PLUGIN_HANDLED;
}
public check_level(id)
{
	new level = 0
	if(PlayerLevel[id] < MAXLEVEL-1 && get_pcvar_num(p_Enabled))
	{
		while(PlayerXp[id] >= LEVELS[PlayerLevel[id]] && level < 3)
		{
			PlayerLevel[id]++;
			//resetowanie broni po zdobyciu zlotych
			if(PlayerLevel[id] == 24)
			{
				g_remember_selection[id] = 0;
				g_remember_selection_pistol[id] = 0;
			}
			level++
			if(is_user_alive(id))
			{	
				if ( get_pcvar_num(level_style) )
				{
					give_weapon(id);
				}
				
				new p_origin[3];
				get_user_origin(id, p_origin, 0);
				
				set_sprite(p_origin, levelspr, 30)
				set_sprite(p_origin, levelspr2, 30)
				
				g_stats_points[id] += 10
			}
			emit_sound(id, CHAN_ITEM, LevelUp, 1.0, ATTN_NORM, 0, PITCH_NORM);
			
			static name[32] ; get_user_name(id, name, charsmax(name));
			client_printcolor(0, "%L", LANG_SERVER, "LEVEL_UP", name, PlayerLevel[id]);
			log_to_file("5_zapis_poziomow", "%s zdobyl poziom %i", name, PlayerLevel[id]);
		}
	} 
}
// Main Menu Info
public show_main_menu_info(id)
{
	if ( !get_pcvar_num(p_Enabled) )
		return;
	
	static menu[510], iLen;
	iLen = 0;
    
	new xKeys3 = MENU_KEY_0|MENU_KEY_1;

    // Title
	iLen += formatex(menu[iLen], sizeof menu - 1 - iLen, "%L", LANG_SERVER, "TITLE_MENU_INFO")
	
	iLen += formatex(menu[iLen], sizeof menu - 1 - iLen, "\r1. \w%L", id, "INFO")
	if ( get_pcvar_num(show_rank) )
	{
		xKeys3 |= (MENU_KEY_2)
		
		iLen += formatex(menu[iLen], sizeof menu - 1 - iLen, "^n\r2. \wTop 20^n")
	}
	else
	{
		iLen += formatex(menu[iLen], sizeof menu - 1 - iLen, "^n\d2. Top 20^n")
	}
	
	if(find_plugin_byfile("gunxpmod_shop.amxx") != INVALID_PLUGIN_ID)
	{
		xKeys3 |= (MENU_KEY_3)
		
		iLen += formatex(menu[iLen], sizeof menu - 1 - iLen, "\r3. \w%L^n", id, "ITEM_LIST")
		if ( is_user_alive(id) )
		{
			xKeys3 |= (MENU_KEY_4)
			
			iLen += formatex(menu[iLen], sizeof menu - 1 - iLen, "\r4. \w%L^n", id, "UNLOCKS_SHOP_TEXT")
		}
	}
	
	iLen += formatex(menu[iLen], sizeof menu - 1 - iLen, "^n^n\r0.\w %L", id, "EXIT_MENU")

	show_menu(id, xKeys3, menu, -1, "Main Menu")
} 
public main_menu_info(id, key)
{
	switch (key)
	{
		case 0:
		{
			show_main_menu_info(id)
			
			descriptionx(id)
		}
		case 1:
		{
			showtop20(id)
			
			show_main_menu_info(id)
		}
		case 2:
		{
			show_main_menu_info(id)
			
			if(callfunc_begin( "display_items","gunxpmod_shop.amxx") == 1)
			{
				callfunc_push_int( id ); 
				callfunc_end();
			}
		}
		case 3:
		{
			if(callfunc_begin("item_upgrades","gunxpmod_shop.amxx") == 1)
			{
				callfunc_push_int( id ); 
				callfunc_end();
			}
		}
		case 9:
		{
			return PLUGIN_HANDLED;
		}
	}

	return PLUGIN_HANDLED;
}
// Main Menu Level Style
public show_main_menu_level(id)
{
	if(rozgrzewka_on() && is_user_alive(id) && !zp_core_is_zombie(id))
	{
		moze_wybrac_bron_rozg(id);
		return PLUGIN_CONTINUE;
	}
	if ( !is_user_alive(id) || !wczytalo[id])
		return;
	
	new szInfo[60], szChooseT[40], szLastG[80];
	formatex(szInfo, charsmax(szInfo), "%L", LANG_SERVER, "TITLE_MENU", PlayerLevel[id], PlayerXp[id], LEVELS[PlayerLevel[id]] );
	
	new menu = menu_create(szInfo , "main_menu_level");
	
	formatex(szChooseT, charsmax(szChooseT), "%L", LANG_SERVER, "CHOOSE_TEXT");
	menu_additem(menu, szChooseT, "1", 0);
	
	if(PlayerLevel[id] > 23)
	{
		if(PlayerLevel[id] > 28)
			formatex(szLastG, charsmax(szLastG), "%L", LANG_SERVER, "LAST_GUNS", RANK[g_remember_selection[id]], RANK[g_remember_selection_pistol[id]]);
		else formatex(szLastG, charsmax(szLastG), "%L", LANG_SERVER, "LAST_GUNS2", RANK[g_remember_selection_pistol[id]]);
	}
	else{
		if(PlayerLevel[id] > 5)
			formatex(szLastG, charsmax(szLastG), "%L", LANG_SERVER, "LAST_GUNS", RANK[g_remember_selection[id]], RANK[g_remember_selection_pistol[id]]);
		else formatex(szLastG, charsmax(szLastG), "%L", LANG_SERVER, "LAST_GUNS2", RANK[g_remember_selection_pistol[id]]);
	}
	
	menu_additem(menu, szLastG, "2", 0);
	
	new szExit[15];
	formatex(szExit, charsmax(szExit), "%L", LANG_SERVER, "EXIT_MENU");
	
	menu_setprop(menu, MPROP_EXITNAME, szExit);
	
	menu_display(id , menu , 0);
} 
public main_menu_level(id , menu , item) 
{ 
	if ( !is_user_alive(id) )
	{
		return PLUGIN_HANDLED;
	}
	
	#if defined ZOMBIE_PLAGUE
	if ( zp_has_round_started() && cs_get_user_team(id) == CS_TEAM_T )
		return PLUGIN_HANDLED;
	#endif
	
	if(zp_core_is_zombie(id))
		return PLUGIN_HANDLED;
	
	if(item == MENU_EXIT)
	{
		menu_destroy(menu); 
		return PLUGIN_HANDLED;
	}
	new data[6], iName[64];
	new access, callback;
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback);

	new item_id = str_to_num(data);
	
	switch (item_id)
	{
		case 1: // show pistols
		{
			if(PlayerLevel[id] > 23)
				show_menu_level_pistol_gold(id)
			else show_menu_level_pistol(id);
		}
		case 2: // last weapons
		{
			if(zp_class_survivor_get(id) || zp_class_sniper_get(id))
				return PLUGIN_CONTINUE;
			
			if(PlayerLevel[id] > 23)
			{
				if ( PlayerLevel[id] - 24 > MAX_PISTOLS_MENU - 1 )
				{
					give_weapon_menu(id, g_remember_selection[id], 1, 1);
					give_weapon_menu(id, g_remember_selection_pistol[id], 0, 0);
				}
				else if ( PlayerLevel[id] - 24 < MAX_PISTOLS_MENU )
				{
					give_weapon_menu(id, g_remember_selection_pistol[id], 1, 1);
				}
			}
			else
			{
				if ( PlayerLevel[id] > MAX_PISTOLS_MENU - 1 )
				{
					give_weapon_menu(id, g_remember_selection[id], 1, 1);
					give_weapon_menu(id, g_remember_selection_pistol[id], 0, 0);
				}
				else if ( PlayerLevel[id] < MAX_PISTOLS_MENU )
				{
					give_weapon_menu(id, g_remember_selection_pistol[id], 1, 1);
				}
			}
			if(zp_class_human_get_next(id) == ZP_INVALID_HUMAN_CLASS)
			{
				zp_class_human_show_menu(id)
			}
			else nat_menu_questow(id)
		}
	}

	menu_destroy(menu); 
	return PLUGIN_HANDLED;
}
// Menu Level Style Pistols
public show_menu_level_pistol(id)
{
	if ( !is_user_alive(id) )
		return;
	
	new szInfo[60];
	formatex(szInfo, charsmax(szInfo), "%L", LANG_SERVER, "TITLE_MENU", PlayerLevel[id], PlayerXp[id], LEVELS[PlayerLevel[id]] );
	
	new menu = menu_create(szInfo , "pistol_menu");
	
	for (new item_id = 0; item_id < MAX_PISTOLS_MENU; item_id++)
	{
		new szItems[60], szTempid[32];
			
		if ( PlayerLevel[id] >= GUN_LEVELS[item_id] )
		{
			formatex(szItems, charsmax(szItems), "%L", LANG_SERVER, "ACTIVE_MENU", RANK[item_id], GUN_LEVELS[item_id] )

			num_to_str(item_id, szTempid, charsmax(szTempid) );

			menu_additem(menu, szItems, szTempid, 0);
		}
			
		else
		{
			formatex(szItems, charsmax(szItems), "%L", LANG_SERVER, "INACTIVE_MENU", RANK[item_id], GUN_LEVELS[item_id] )
			menu_additem(menu, szItems, "999", 0, menu_makecallback("CallbackMenu"));
		}
	}
	
	new szNext[15], szBack[15], szExit[15];
	formatex(szBack, charsmax(szBack), "%L", LANG_SERVER, "BACK_MENU");
	formatex(szNext, charsmax(szNext), "%L", LANG_SERVER, "NEXT_MENU");
	formatex(szExit, charsmax(szExit), "%L", LANG_SERVER, "EXIT_MENU");
	
	menu_setprop(menu, MPROP_BACKNAME, szBack) 
	menu_setprop(menu, MPROP_NEXTNAME, szNext) 
	menu_setprop(menu, MPROP_EXITNAME, szExit) 
	
	menu_display(id , menu , 0); 
}
public show_menu_level_pistol_gold(id)
{
	if ( !is_user_alive(id) )
		return;
	
	new szInfo[60];
	formatex(szInfo, charsmax(szInfo), "%L", LANG_SERVER, "TITLE_MENU", PlayerLevel[id], PlayerXp[id], LEVELS[PlayerLevel[id]] );
	
	new menu = menu_create(szInfo , "pistol_menu");
	
	for (new item_id = 24; item_id < MAX_PISTOLS_MENU+24; item_id++)
	{
		new szItems[60], szTempid[32];
			
		if ( PlayerLevel[id] >= GUN_LEVELS[item_id] )
		{
			formatex(szItems, charsmax(szItems), "%L", LANG_SERVER, "ACTIVE_MENU", RANK[item_id], GUN_LEVELS[item_id] )

			num_to_str(item_id, szTempid, charsmax(szTempid) );

			menu_additem(menu, szItems, szTempid, 0);
		}
			
		else
		{
			formatex(szItems, charsmax(szItems), "%L", LANG_SERVER, "INACTIVE_MENU", RANK[item_id], GUN_LEVELS[item_id] )
			menu_additem(menu, szItems, "999", 0, menu_makecallback("CallbackMenu"));
		}
	}
	
	new szNext[15], szBack[15], szExit[15];
	formatex(szBack, charsmax(szBack), "%L", LANG_SERVER, "BACK_MENU");
	formatex(szNext, charsmax(szNext), "%L", LANG_SERVER, "NEXT_MENU");
	formatex(szExit, charsmax(szExit), "%L", LANG_SERVER, "EXIT_MENU");
	
	menu_setprop(menu, MPROP_BACKNAME, szBack) 
	menu_setprop(menu, MPROP_NEXTNAME, szNext) 
	menu_setprop(menu, MPROP_EXITNAME, szExit) 
	
	menu_display(id , menu , 0); 
}
public pistol_menu(id , menu , item) 
{ 
	if ( !is_user_alive(id) || zp_class_survivor_get(id) || zp_class_sniper_get(id))
	{
		return PLUGIN_HANDLED;
	}
	
	#if defined ZOMBIE_PLAGUE
	if ( zp_has_round_started() && cs_get_user_team(id) == CS_TEAM_T )
		return PLUGIN_HANDLED;
	#endif
	
	if(item == MENU_EXIT) 
	{ 
		menu_destroy(menu); 
		return PLUGIN_HANDLED;
	} 
	new data[6], iName[64];
	new access, callback;
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback);

	new item_id = str_to_num(data);
	
	if(PlayerLevel[id] > 23)
		item_id -= 24
	
	g_remember_selection_pistol[id] = item_id;
	
	give_weapon_menu(id, item_id, 1, 1);
	if(PlayerLevel[id] > 23)
	{
		if ( PlayerLevel[id]-24 > MAX_PISTOLS_MENU - 1 )
		{
			show_menu_level_gold(id);
		}
		else if(zp_class_human_get_next(id) == ZP_INVALID_HUMAN_CLASS)
		{
			zp_class_human_show_menu(id)
		}
		else nat_menu_questow(id)
	}
	else if ( PlayerLevel[id] > MAX_PISTOLS_MENU - 1 )
	{
		show_menu_level(id);
	}
	else if(zp_class_human_get_next(id) == ZP_INVALID_HUMAN_CLASS)
	{
		zp_class_human_show_menu(id)
	}
	else nat_menu_questow(id)

	menu_destroy(menu); 
	return PLUGIN_HANDLED;
}
// Menu Level Style Primary
public show_menu_level(id)
{
	if ( !is_user_alive(id) || PlayerLevel[id] < MAX_PISTOLS_MENU )
		return;
	
	new szInfo[100];
	formatex(szInfo, charsmax(szInfo), "%L", LANG_SERVER, "TITLE_MENU", PlayerLevel[id], PlayerXp[id], LEVELS[PlayerLevel[id]] );
	
	new menu = menu_create(szInfo , "level_menu");
	
	for (new item_id = MAX_PISTOLS_MENU; item_id < MAXLEVEL; item_id++)
	{
		new szItems[512], szTempid[32];
			
		if ( PlayerLevel[id] >= GUN_LEVELS[item_id] )
		{
			formatex(szItems, charsmax(szItems), "%L", LANG_SERVER, "ACTIVE_MENU", RANK[item_id], GUN_LEVELS[item_id] )

			num_to_str(item_id, szTempid, charsmax(szTempid) );

			menu_additem(menu, szItems, szTempid, 0);
		}
		else
		{
			formatex(szItems, charsmax(szItems), "%L", LANG_SERVER, "INACTIVE_MENU", RANK[item_id], GUN_LEVELS[item_id] )
			menu_additem(menu, szItems, "999", 0, menu_makecallback("CallbackMenu"));
		}
	}
	
	new szNext[15], szBack[15], szExit[15];
	formatex(szBack, charsmax(szBack), "%L", LANG_SERVER, "BACK_MENU");
	formatex(szNext, charsmax(szNext), "%L", LANG_SERVER, "NEXT_MENU");
	formatex(szExit, charsmax(szExit), "%L", LANG_SERVER, "EXIT_MENU");
	
	menu_setprop(menu, MPROP_BACKNAME, szBack) 
	menu_setprop(menu, MPROP_NEXTNAME, szNext) 
	menu_setprop(menu, MPROP_EXITNAME, szExit) 
	
	menu_display(id , menu , 0); 
}
public show_menu_level_gold(id)
{
	if ( !is_user_alive(id) || PlayerLevel[id] - 23 < MAX_PISTOLS_MENU )
		return;
	
	new szInfo[100];
	formatex(szInfo, charsmax(szInfo), "%L", LANG_SERVER, "TITLE_MENU", PlayerLevel[id], PlayerXp[id], LEVELS[PlayerLevel[id]] );
	
	new menu = menu_create(szInfo , "level_menu");
	
	for (new item_id = MAX_PISTOLS_MENU+24; item_id < MAXLEVEL; item_id++)
	{
		new szItems[512], szTempid[32];
			
		if ( PlayerLevel[id] >= GUN_LEVELS[item_id] )
		{
			formatex(szItems, charsmax(szItems), "%L", LANG_SERVER, "ACTIVE_MENU", RANK[item_id], GUN_LEVELS[item_id] )

			num_to_str(item_id, szTempid, charsmax(szTempid) );

			menu_additem(menu, szItems, szTempid, 0);
		}
		else
		{
			formatex(szItems, charsmax(szItems), "%L", LANG_SERVER, "INACTIVE_MENU", RANK[item_id], GUN_LEVELS[item_id] )
			menu_additem(menu, szItems, "999", 0, menu_makecallback("CallbackMenu"));
		}
	}
	
	new szNext[15], szBack[15], szExit[15];
	formatex(szBack, charsmax(szBack), "%L", LANG_SERVER, "BACK_MENU");
	formatex(szNext, charsmax(szNext), "%L", LANG_SERVER, "NEXT_MENU");
	formatex(szExit, charsmax(szExit), "%L", LANG_SERVER, "EXIT_MENU");
	
	menu_setprop(menu, MPROP_BACKNAME, szBack) 
	menu_setprop(menu, MPROP_NEXTNAME, szNext) 
	menu_setprop(menu, MPROP_EXITNAME, szExit) 
	
	menu_display(id , menu , 0); 
}
public level_menu(id , menu , item) 
{ 
	if ( !is_user_alive(id) || PlayerLevel[id] < MAX_PISTOLS_MENU || zp_class_survivor_get(id) || zp_class_sniper_get(id))
	{
		return PLUGIN_HANDLED;
	}
	
	#if defined ZOMBIE_PLAGUE
	if ( zp_has_round_started() && cs_get_user_team(id) == CS_TEAM_T )
		return PLUGIN_HANDLED;
	#endif
	
	if(item == MENU_EXIT) 
	{ 
		menu_destroy(menu); 
		return PLUGIN_HANDLED;
	}
	new data[6], iName[64];
	new access, callback;
	menu_item_getinfo(menu, item, access, data,5, iName, 63, callback);

	new item_id = str_to_num(data);
	
	if(PlayerLevel[id] > 23)
		item_id -= 24

	g_remember_selection[id] = item_id;
	
	give_weapon_menu(id, item_id, 0, 0);
	
	if(zp_class_human_get_next(id) == ZP_INVALID_HUMAN_CLASS)
	{
		zp_class_human_show_menu(id)
	}
	else nat_menu_questow(id)
	
	menu_destroy(menu); 
	return PLUGIN_HANDLED;
}
public CallbackMenu(id, menu, item) 
{ 
    return ITEM_DISABLED; 
}

// Selected by menu or remember selection and give item
public give_weapon_menu(id, selection, strip, givegren)
{
	#if defined ZOMBIE_SWARM
    if( is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT && get_pcvar_num(p_Enabled) ) 
    {
		if ( strip )
		{
			StripPlayerWeapons(id);
		}
		
		if ( get_pcvar_num(enable_grenades) && givegren )
		{
			give_item(id, FLASHBANG_LEVEL[PlayerLevel[id]]);
			give_item(id, HEGRENADE_LEVEL[PlayerLevel[id]]);
			give_item(id, SMOKEGRENADE_LEVEL[PlayerLevel[id]]);
		}
		
		give_item(id, WEAPONCONST[selection]);

		cs_set_user_bpammo(id, AMMOCONST[selection], AMMO2CONST[selection])
    }
	#endif
	
	#if defined ZOMBIE_INFECTION || defined NORMAL_MOD || defined ZOMBIE_PLAGUE
    if(is_user_alive(id) && get_pcvar_num(p_Enabled) && !zp_class_survivor_get(id) && !zp_class_sniper_get(id))
    {
		if ( strip )
		{
			StripPlayerWeapons(id);
		}
		
		if ( get_pcvar_num(enable_grenades) && givegren )
		{
			give_item(id, FLASHBANG_LEVEL[PlayerLevel[id]]);
			give_item(id, HEGRENADE_LEVEL[PlayerLevel[id]]);
			give_item(id, SMOKEGRENADE_LEVEL[PlayerLevel[id]]);
		}
		
		if(sprawdz_ile_wykonano(id) >= 11)
			cs_set_user_bpammo(id, CSW_SMOKEGRENADE, 2)
			
		if(sprawdz_ile_wykonano(id) >= 27)
			cs_set_user_bpammo(id, CSW_HEGRENADE, 2)
			
		if(sprawdz_ile_wykonano(id) >= 36)
			cs_set_user_bpammo(id, CSW_FLASHBANG, 2)
		
		give_item(id, WEAPONCONST[selection]);

		cs_set_user_bpammo(id, AMMOCONST[selection], AMMO2CONST[selection])
		
			if ( PlayerLevel[id] < MAX_PISTOLS_MENU && selection <= 5)
				wybral_bron[id] = 1
			else if(selection > 5)
				wybral_bron[id] = 1
    }
	#endif
	
}
public give_weapon(id)
{
	#if defined ZOMBIE_SWARM
	if( is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT && get_pcvar_num(p_Enabled)) 
	{
		StripPlayerWeapons(id);
		
		if ( get_pcvar_num(enable_grenades) && get_pcvar_num(level_style) )
		{
			give_item(id, FLASHBANG_LEVEL[PlayerLevel[id]]);
			give_item(id, HEGRENADE_LEVEL[PlayerLevel[id]]);
			give_item(id, SMOKEGRENADE_LEVEL[PlayerLevel[id]]);
		}
		
		give_item(id, WEAPONCONST[PlayerLevel[id]]);
			
		cs_set_user_bpammo(id, AMMOCONST[PlayerLevel[id]], AMMO2CONST[PlayerLevel[id]])
	}
	#endif
	
	#if defined ZOMBIE_INFECTION || defined NORMAL_MOD || defined ZOMBIE_PLAGUE
	if(is_user_alive(id) && get_pcvar_num(p_Enabled)) 
	{
		StripPlayerWeapons(id);
		
		if ( get_pcvar_num(enable_grenades) && get_pcvar_num(level_style) )
		{
			give_item(id, FLASHBANG_LEVEL[PlayerLevel[id]]);
			give_item(id, HEGRENADE_LEVEL[PlayerLevel[id]]);
			give_item(id, SMOKEGRENADE_LEVEL[PlayerLevel[id]]);
		}

		give_item(id, WEAPONCONST[PlayerLevel[id]]);

		cs_set_user_bpammo(id, AMMOCONST[PlayerLevel[id]], AMMO2CONST[PlayerLevel[id]])
//		if(PlayerLevel[id] < 6)
//			wybral_bron[id] = 1
	}
	#endif
}
public set_sprite(p_origin[3], sprite, radius)
{
	// Explosion
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, p_origin)
	write_byte(TE_EXPLOSION)
	write_coord(p_origin[0])
	write_coord(p_origin[1])
	write_coord(p_origin[2])
	write_short(sprite)
	write_byte(radius)
	write_byte(15)
	write_byte(4)
	message_end()
}
//Shows Top 20
/*public showtop20(id)
{
	if( !get_pcvar_num(p_Enabled) && !get_pcvar_num(show_rank) )
		return;
	
	static Sort[33][2];
	new players[32],num,count,index;
	get_players(players,num);
    
	for(new i = 0; i < num; i++)
	{
		index = players[i];
		Sort[count][0] = index;
		Sort[count][1] = PlayerXp[index];
		count++;
	}
    
	SortCustom2D(Sort,count,"CompareXp");
	new motd[1501],iLen;
	iLen = formatex(motd, sizeof motd - 1,"<body bgcolor=#000000><font color=#98f5ff><pre>");
	iLen += formatex(motd[iLen], (sizeof motd - 1) - iLen,"%s %-22.22s %3s^n", "#", "Name", "# Experience");
    
	new y = clamp(count,0,20);
	new name[32],kindex;
    
	for(new x = 0; x < y; x++)
	{
		kindex = Sort[x][0];
		get_user_name(kindex,name,sizeof name - 1);
		iLen += formatex(motd[iLen], (sizeof motd - 1) - iLen,"%d %-22.22s %d^n", x + 1, name, Sort[x][1]);
	}
	iLen += formatex(motd[iLen], (sizeof motd - 1) - iLen,"</body></font></pre>");
	show_motd(id,motd, "GunXpMod Top 20");
}*/
public CompareXp(elem1[], elem2[])
{
    if(elem1[1] > elem2[1])
        return -1;
    else if(elem1[1] < elem2[1])
        return 1;
    
    return 0;
} 
// Command to set player Level
public cmd_give_exp(id, level, cid) 
{
	if( !cmd_access(id, level, cid, 3) || !get_pcvar_num(p_Enabled) )
	{
		return PLUGIN_HANDLED;
	}
	
	new Arg1[64], Target
	read_argv(1, Arg1, 63)
	Target = cmd_target(id, Arg1, 0)
	
	new iLevel[32], Value
	read_argv(2, iLevel, 31)
	Value = str_to_num(iLevel)
	
	if(iLevel[0] == '-') 
	{
		console_print(id, "You can't have a '-' in the value!")
		return PLUGIN_HANDLED;
	}
	
	if(!Target) 
	{
		console_print(id, "Target not found!")
		return PLUGIN_HANDLED;
	}
	
	if(Value > 3000000)
	{
		console_print(id, "You can't set a more than 3000000!")
		return PLUGIN_HANDLED;
	}
	
	if(Value < 0)
	{
		console_print(id, "You can't set less than 0!")
		return PLUGIN_HANDLED;
	}
	
	new AdminName[32]
	get_user_name(id, AdminName, 31)
		
	new TargetName[32]
	get_user_name(Target, TargetName, 31)
	
	PlayerXp[Target] = PlayerXp[Target] + Value
	check_level(Target)
	
//	client_printcolor(Target, "/gADMIN: /ctr%s /yhas set your level to /g%d", AdminName, Value)

	return PLUGIN_HANDLED;
}

// ============================================================//
//                          [~ Saving datas ~]			       //
// ============================================================//
public sql_start()
{
	if ( !get_pcvar_num(p_Enabled) || !get_pcvar_num(save_type) )
		return;
		
	if(g_boolsqlOK) return;
	
	new szHost[64], szUser[32], szPass[32], szDB[128];
	
	get_pcvar_string( mysqlx_host, szHost, charsmax( szHost ) );
	get_pcvar_string( mysqlx_user, szUser, charsmax( szUser ) );
	get_pcvar_string( mysqlx_pass, szPass, charsmax( szPass ) );
	get_pcvar_string( mysqlx_db, szDB, charsmax( szDB ) );
	
	g_SqlTuple = SQL_MakeDbTuple(szHost, szUser, szPass, szDB);
		
	new q_command[2048]
	
	new iLen=0, iMax=sizeof(q_command) - 1
	
	iLen += formatex(q_command[iLen], iMax-iLen,"CREATE TABLE IF NOT EXISTS zm_expp ( ")
	iLen += formatex(q_command[iLen], iMax-iLen,"`nick` VARCHAR(48) NOT NULL, ")
	iLen += formatex(q_command[iLen], iMax-iLen,"`lvl` INT(3) DEFAULT 0, ")
	iLen += formatex(q_command[iLen], iMax-iLen,"`exp` INT(9) DEFAULT 0, ")
	iLen += formatex(q_command[iLen], iMax-iLen,"`quest_gracza` INT(3) DEFAULT -1, ")
	iLen += formatex(q_command[iLen], iMax-iLen,"`ile_juz` INT(9) DEFAULT 0, ")
	iLen += formatex(q_command[iLen], iMax-iLen,"`ile_wykonano` INT(9) DEFAULT 0, ")
	iLen += formatex(q_command[iLen], iMax-iLen,"`totalpoints` INT(9) DEFAULT 0, ")
	iLen += formatex(q_command[iLen], iMax-iLen,"`ammopacks` INT(6) DEFAULT 0, ")
	iLen += formatex(q_command[iLen], iMax-iLen,"`dam_done` INT(12) DEFAULT 0, ")
	iLen += formatex(q_command[iLen], iMax-iLen,"`zm_kill` INT(6) DEFAULT 0, ")
	iLen += formatex(q_command[iLen], iMax-iLen,"`hm_infkill` INT(6) DEFAULT 0, ")
	iLen += formatex(q_command[iLen], iMax-iLen,"`deaths` INT(6) DEFAULT 0, ")
	iLen += formatex(q_command[iLen], iMax-iLen,"`nem_kill` INT(4) DEFAULT 0, ")
	iLen += formatex(q_command[iLen], iMax-iLen,"`sur_kill` INT(4) DEFAULT 0, ")
	iLen += formatex(q_command[iLen], iMax-iLen,"`ass_kill` INT(4) DEFAULT 0, ")
	iLen += formatex(q_command[iLen], iMax-iLen,"`sni_kill` INT(4) DEFAULT 0, ")
	iLen += formatex(q_command[iLen], iMax-iLen,"`matki_kill` INT(4) DEFAULT 0, ")
	iLen += formatex(q_command[iLen], iMax-iLen,"`last_hm_kill` INT(4) DEFAULT 0, ")
	iLen += formatex(q_command[iLen], iMax-iLen,"`zm_win` INT(6) DEFAULT 0, ")
	iLen += formatex(q_command[iLen], iMax-iLen,"`hm_win` INT(6) DEFAULT 0, ")
	iLen += formatex(q_command[iLen], iMax-iLen,"`czas_online` INT(6) DEFAULT 0, ")
	iLen += formatex(q_command[iLen], iMax-iLen,"PRIMARY KEY (`nick`)) ")
	iLen += formatex(q_command[iLen], iMax-iLen,"DEFAULT CHARSET `utf8` COLLATE `utf8_general_ci`")
	
	SQL_ThreadQuery(g_SqlTuple, "QueryCreateTable", q_command);
}
public QueryCreateTable( FailState, Handle:hQuery, szError[ ], Errcode, iData[ ], iDataSize, Float:fQueueTime ) 
{
	if(FailState == TQUERY_CONNECT_FAILED) {
		log_to_file("sql.log", "Could not connect to SQL database.");
		return PLUGIN_CONTINUE;
	}
	if(FailState == TQUERY_QUERY_FAILED) {
		log_to_file("sql.log", "Table Query failed.");
		return PLUGIN_CONTINUE;
	}
	if(Errcode) {
		log_to_file("sql.log", "Error on Table query: %s", szError);
		return PLUGIN_CONTINUE;
	}
	g_boolsqlOK = 1;
	log_to_file("sql.log", "Prawidlowe polaczenie");
	
	set_task(30.0, "wczytaj_statystyki");
	
	return PLUGIN_CONTINUE;
}

public create_klass(id) {
	if(g_boolsqlOK) {
		if(!is_user_bot(id) && !database_user_created[id]) {
			new data[1];
			data[0] = id;
			
			new name[48], q_command[2048];
			
			get_user_name(id, name, 47);
			
			replace_all(name, 47, "'", "\'");
			strtolower(name)
			
			formatex(q_command, 2047, "INSERT INTO `%s` (`nick`,`lvl`,`exp`,`quest_gracza`,`ile_juz`,`ile_wykonano`,`totalpoints`,`ammopacks`,`dam_done`,`zm_kill`,`hm_infkill`,`deaths`,`nem_kill`,`sur_kill`,`ass_kill`,`sni_kill`,`matki_kill`,`last_hm_kill`,`zm_win`,`hm_win`,`czas_online`) VALUES ('%s',0,0,-1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)", g_sqlTable, name);
			
			SQL_ThreadQuery(g_SqlTuple, "create_klass_handle", q_command, data, 1);
			
			database_user_created[id] = 1;
		}
	}
	else sql_start();
}

public create_klass_handle(FailState, Handle:Query, Error[], Errcode, Data[], DataSize) {
	new id = Data[0];
	database_user_created[id] = 0;

	if(FailState == TQUERY_CONNECT_FAILED) {
		log_to_file("sql.log", "Could not connect to SQL database.");
		return PLUGIN_CONTINUE;
	}
	if(Errcode) {
		log_to_file("sql.log", "Error on create_klass query: %s", Error);
		return PLUGIN_CONTINUE;
	}
	if(FailState == TQUERY_QUERY_FAILED) {
		log_to_file("sql.log", "create_klass Query failed.");
		return PLUGIN_CONTINUE;
	}
	
	wczytalo[id] = true
	show_main_menu_level(id)

	return PLUGIN_CONTINUE;
}

/*SaveLevel(id)
{
	if(g_boolsqlOK) {
		if(!is_user_bot(id) && PlayerXp[id] != player_xp_old[id]) {
			new name[48], q_command[2048];
				
			get_user_name(id, name, 47);
				
			replace_all(name, 47, "'", "\'");
				
			format(q_command, 2047, "INSERT INTO `%s` (`nick`, `lvl`, `exp`, `quest_gracza`, `ile_juz`, `ile_wykonano`, `totalpoints`, `ammopacks`, `dam_done`, `zm_kill`, `hm_infkill`, `deaths`, `nem_kill`, `sur_kill`, `ass_kill`, `sni_kill`, `matki_kill`, `last_hm_kill`, `zm_win`, `hm_win`, `czas_online`) VALUES ('%s', %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d) ON DUPLICATE KEY UPDATE `exp` = VALUES(`exp`)", // 
			g_sqlTable, name, PlayerLevel[id], PlayerXp[id], sprawdz_misje_sql(id), sprawdz_ile_juz_sql(id), sprawdz_ile_wykonano(id), g_stats_points[id], g_stats_ammopacks[id], g_stats_dam_done[id], g_stats_zm_kill[id], g_stats_hm_infkill[id], g_stats_deaths[id], g_stats_nem_kill[id], g_stats_sur_kill[id], g_stats_ass_kill[id], g_stats_sni_kill[id], g_stats_matki_kill[id], g_stats_last_hm_kill[id], g_stats_zm_win[id], g_stats_hm_win[id], g_stats_czas_online[id]) //
				
			SQL_ThreadQuery(g_SqlTuple, "QuerySetData", q_command);
				
			player_xp_old[id] = PlayerXp[id];
		}
	}
	else sql_start();
	
	return PLUGIN_CONTINUE;
}

public QuerySetData( FailState, Handle:hQuery, szError[ ], Errcode, iData[ ], iDataSize, Float:fQueueTime )
{
	if(FailState == TQUERY_CONNECT_FAILED) {
		log_to_file("sql.log", "Could not connect to SQL database.");
		return PLUGIN_CONTINUE;
	}
	if(Errcode) {
		log_to_file("sql.log", "Error on Save_xp query: %s", szError);
		return PLUGIN_CONTINUE;
	}
	if(FailState == TQUERY_QUERY_FAILED) {
		log_to_file("sql.log", "Save_xp Query failed.");
		return PLUGIN_CONTINUE;
	}

	return PLUGIN_CONTINUE; 
}*/

LoadLevel(id)
{
	if(is_user_bot(id) || asked_sql[id])
		return PLUGIN_HANDLED;
	if(!module_exists("mysql"))
	{
		log_to_file("sql.log", "Modul mysql nie jest zaladowany gdy funkcja mysql sie odpala!");
		return PLUGIN_HANDLED;
	}
	
	if(g_boolsqlOK) {
		new data[1];
		data[0] = id;
		
		new name[48], q_command[2048];
		get_user_name(id, name, 47);
		replace_all(name, 47, "'", "\'");
		strtolower(name)
		
		formatex(q_command, 511, "SELECT * FROM `%s` WHERE `nick`='%s'", g_sqlTable, name);
		
		SQL_ThreadQuery(g_SqlTuple, "Load_xp_handle", q_command, data, 1);
		
		asked_sql[id] = 1;
	}
	else sql_start();

	return PLUGIN_HANDLED;
}
public Load_xp_handle(FailState, Handle:Query, Error[], Errcode, Data[], DataSize)
{
	new id = Data[0];
	asked_sql[id] = 0;
	new quest_gracza2
	new ile_juz2
	new ile_wykonano2

	if(FailState == TQUERY_CONNECT_FAILED) {
		log_to_file("sql.log", "Could not connect to SQL database.");
		return PLUGIN_CONTINUE;
	}
	if(FailState == TQUERY_QUERY_FAILED) {
		log_to_file("sql.log", "Load_xp Query failed.");
		return PLUGIN_CONTINUE;
	}
	if(Errcode) {
		log_to_file("sql.log", "Error on Load_xp query: %s", Error);
		return PLUGIN_CONTINUE;
	}

	if(SQL_MoreResults(Query))
	{
		PlayerLevel[id] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "lvl"))
		PlayerXp[id] =	SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "exp"))
		quest_gracza2 = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "quest_gracza"))
		ile_juz2 = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "ile_juz"))
		ile_wykonano2 = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "ile_wykonano"))
		
		nadaj_misje_sql(id, quest_gracza2)
		nadaj_ile_juz_sql(id, ile_juz2)
		nadaj_ile_wykonano_sql(id, ile_wykonano2)
		
		g_stats_points[id] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "totalpoints"))
		g_stats_ammopacks[id] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "ammopacks"))
		g_stats_dam_done[id] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "dam_done"))
		g_stats_zm_kill[id] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "zm_kill"))
		g_stats_hm_infkill[id] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "hm_infkill"))
		g_stats_deaths[id] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "deaths"))
		g_stats_nem_kill[id] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "nem_kill"))
		g_stats_sur_kill[id] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "sur_kill"))
		g_stats_ass_kill[id] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "ass_kill"))
		g_stats_sni_kill[id] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "sni_kill"))
		g_stats_matki_kill[id] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "matki_kill"))
		g_stats_last_hm_kill[id] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "last_hm_kill"))
		g_stats_zm_win[id] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "zm_win"))
		g_stats_hm_win[id] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "hm_win"))
		g_stats_czas_online[id] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "czas_online"))
		
		player_xp_old[id] = PlayerXp[id];
		
		wczytalo[id] = true
		if(PlayerLevel[id] > 23)
		{
			if(PlayerLevel[id] > 29)
				g_remember_selection_pistol[id] = 5
			else g_remember_selection_pistol[id] = PlayerLevel[id] - 24
			g_remember_selection[id] = PlayerLevel[id] - 24
		}
		else{
			if(PlayerLevel[id] > 5)
				g_remember_selection_pistol[id] = 5
			else g_remember_selection_pistol[id] = PlayerLevel[id]
			g_remember_selection[id] = PlayerLevel[id]
		}
		
		show_main_menu_level(id)
		
	}
	else
	{
		PlayerLevel[id] = 0
		PlayerXp[id] =	0
		
		nadaj_misje_sql(id, -1)
		nadaj_ile_juz_sql(id, 0)
		nadaj_ile_wykonano_sql(id, 0)
		
		g_stats_points[id] = 0
		g_stats_ammopacks[id] = 0
		g_stats_dam_done[id] = 0
		g_stats_zm_kill[id] = 0
		g_stats_hm_infkill[id] = 0
		g_stats_deaths[id] = 0
		g_stats_nem_kill[id] = 0
		g_stats_sur_kill[id] = 0
		g_stats_ass_kill[id] = 0
		g_stats_sni_kill[id] = 0
		g_stats_matki_kill[id] = 0
		g_stats_last_hm_kill[id] = 0
		g_stats_zm_win[id] = 0
		g_stats_hm_win[id] = 0
		g_stats_czas_online[id] = 0
		
		wczytalo[id] = true
		
		show_main_menu_level(id)
	}
	
	return PLUGIN_CONTINUE;
}

// ============================================================//
//                          [~ Natives ~]			       	   //
// ============================================================//
//pokaz menu
public native_showmenu(id)
{
	show_main_menu_level(id)
}
//moze wybrac bron?
public native_mozewybracbron(id)
{
	new aaa
	if(wybral_bron[id] == 0)
		aaa = 1
	else aaa = 0
	
	return aaa;
}
// Native: get_user_xp
public native_get_user_xp(id)
{
	return PlayerXp[id];
}
// Native: set_user_xp
public native_set_user_xp(id, amount)
{
	PlayerXp[id] = amount;
	check_level(id)
}
// Native: get_user_level
public native_get_user_level(id)
{
	return PlayerLevel[id];
}
// Native: set_user_xp
public native_set_user_level(id, amount)
{
	PlayerLevel[id] = amount;
}
// Native: Gets user level by Xp
public native_get_user_max_level(id)
{
	return LEVELS[PlayerLevel[id]];
}
// Native: did exp load?
public native_wczytalo(id)
{
	return wczytalo[id];
}
// Native: did exp load?
public native_menu_pomocy(id)
{
	pomoc_info(id);
}
// ============================================================//
//                          [~ Stocks ~]			       	   //
// ============================================================//
stock client_printcolor(const id, const input[], any:...)
{
	new count = 1, players[32];
	static msg[191];
	vformat(msg,190,input,3);
	replace_all(msg,190,"/g","^4");// green txt
	replace_all(msg,190,"/y","^1");// orange txt
	replace_all(msg,190,"/ctr","^3");// team txt
	replace_all(msg,190,"/w","^0");// team txt
	if (id) players[0] = id; else get_players(players,count,"ch");
	for (new i = 0; i < count; i++)
		if (is_user_connected(players[i]))
		{
			message_begin(MSG_ONE_UNRELIABLE, SayTxT, _, players[i]);
			write_byte(players[i]);
			write_string(msg);
			message_end();
		}
}	
public StripPlayerWeapons(id) 
{ 
	strip_user_weapons(id) 
	set_pdata_int(id, OFFSET_PRIMARYWEAPON, 0) 
	give_item(id, "weapon_knife");
} 

public GiveXP(id, ammount)
{
	new min_liczba_g = get_pcvar_num(min_licz_graczy)
	ilosc_graczy = get_playersnum()
	if(ilosc_graczy >= min_liczba_g)
	{
		if(nocny_exp)
		{
			ammount = floatround(ammount * 1.5)
		}
		if(get_user_flags(id) & ADMIN_LEVEL_H)
		{
			ammount = floatround(ammount * 1.2)
		}
		PlayerXp[id] += ammount
		check_level(id)
	}
	else client_print(0, print_chat, "Minimalna liczba graczy aby przyznawany byl exp wynosi: %i", min_liczba_g)
	return PLUGIN_CONTINUE;
}

public handleSayText(msgId,msgDest,msgEnt){
	new id = get_msg_arg_int(1);
	
	if(!is_user_connected(id))      return PLUGIN_CONTINUE;
	
	new szTmp[256],szTmp2[256];
	get_msg_arg_string(2,szTmp, charsmax( szTmp ) )
	
	new szPrefix[64]
	
	if(zp_class_nemesis_get(id))
		formatex(szPrefix,charsmax( szPrefix ),"^x04[Nemesis - %d]",PlayerLevel[id])
	else if(zp_class_assassin_get(id))
		formatex(szPrefix,charsmax( szPrefix ),"^x04[Assasin - %d]",PlayerLevel[id])
	else if(zp_class_survivor_get(id))
		formatex(szPrefix,charsmax( szPrefix ),"^x04[Survivor - %d]",PlayerLevel[id])
	else if(zp_class_sniper_get(id))
		formatex(szPrefix,charsmax( szPrefix ),"^x04[Sniper - %d]",PlayerLevel[id])
	else if(zp_core_is_zombie(id))
		formatex(szPrefix,charsmax( szPrefix ),"^x04[Zombie - %d]",PlayerLevel[id])
	else
		formatex(szPrefix,charsmax( szPrefix ),"^x04[Czlowiek - %d]",PlayerLevel[id])
	
	
	if(!equal(szTmp,"#Cstrike_Chat_All")){
		add(szTmp2,charsmax(szTmp2),szPrefix);
		add(szTmp2,charsmax(szTmp2)," ");
		add(szTmp2,charsmax(szTmp2),szTmp);
	}
	else{
		add(szTmp2,charsmax(szTmp2),szPrefix);
		add(szTmp2,charsmax(szTmp2),"^x03 %s1^x01 :  %s2");
	}
	
	set_msg_arg_string(2,szTmp2);
	
	return PLUGIN_CONTINUE;
}

//Exp za asyste
public fwdamage(id, ent, attacker, Float:damage, damagebits)
{
	if(is_user_connected(attacker) && is_user_connected(id) && get_user_team(id) != get_user_team(attacker) && !zp_core_is_zombie(attacker) && g_iDamage_asysta[attacker][id] >= get_pcvar_num(	obrazenia_za_asyste )){
		asysta_gracza[attacker][id] = true;
	}
}
public kiled()
{
	new attacker = read_data(1);
	new id = read_data(2);
	if(is_user_connected(attacker) && get_user_team(id) != get_user_team(attacker))
	{
		new asysta_xp = get_pcvar_num( doswiadczenie_za_asyste )
		for(new i=1; i<=32; i++)
		{
			if(asysta_gracza[i][id] && attacker != i && is_user_connected(i) && !zp_core_is_zombie(i) && get_user_team(i) != get_user_team(id))
			{
				GiveXP(i, asysta_xp)
				set_dhudmessage( 0, 250, 50, 0.8, 0.45, 2, 2.0, 3.0, 0.1, 1.0, false )
//				set_dhudmessage( 250, 0, 0, 0.75, 0.3, 2, 2.0, 3.0, 0.1, 1.0, false )
				show_dhudmessage( i,"ASYSTA: +%i XP", przelicz_exp(i, asysta_xp))
				asysta_gracza[i][id] = false;
				g_iDamage_asysta[attacker][id] = 0
			}
		}
	}
	return PLUGIN_CONTINUE;
}

public CurWeapon(id)
{
	remove_task(id+TASK_OFFSET)
	
	if(PlayerLevel[id] > 23)
	{
		switch(get_user_weapon(id))
		{
			case CSW_GLOCK18:
			{
				entity_set_string(id, EV_SZ_viewmodel, "models/gold/v_glock18.mdl")
				entity_set_string(id,EV_SZ_weaponmodel,"models/gold/p_glock18.mdl")
			}
			case CSW_AK47:
			{
				entity_set_string(id, EV_SZ_viewmodel, "models/gold/v_ak47.mdl")
				entity_set_string(id,EV_SZ_weaponmodel,"models/gold/p_ak47.mdl")
			}
			case CSW_AUG:
			{
				entity_set_string(id, EV_SZ_viewmodel, "models/gold/v_aug.mdl")
				entity_set_string(id,EV_SZ_weaponmodel,"models/gold/p_aug.mdl")
			}
			case CSW_AWP:
			{
				entity_set_string(id, EV_SZ_viewmodel, "models/gold/v_awp.mdl")
				entity_set_string(id,EV_SZ_weaponmodel,"models/gold/p_awp.mdl")
			}
			case CSW_DEAGLE:
			{
				entity_set_string(id, EV_SZ_viewmodel, "models/gold/v_deagle.mdl")
				entity_set_string(id,EV_SZ_weaponmodel,"models/gold/p_deagle.mdl")
			}
			case CSW_ELITE:
			{
				entity_set_string(id, EV_SZ_viewmodel, "models/gold/v_elite.mdl")
				entity_set_string(id,EV_SZ_weaponmodel,"models/gold/p_elite.mdl")
			}
			case CSW_FAMAS:
			{
				entity_set_string(id, EV_SZ_viewmodel, "models/gold/v_famas.mdl")
				entity_set_string(id,EV_SZ_weaponmodel,"models/gold/p_famas.mdl")
			}
			case CSW_FIVESEVEN:
			{
				entity_set_string(id, EV_SZ_viewmodel, "models/gold/v_fiveseven.mdl")
				entity_set_string(id,EV_SZ_weaponmodel,"models/gold/p_fiveseven.mdl")
			}
			case CSW_G3SG1:
			{
				entity_set_string(id, EV_SZ_viewmodel, "models/gold/v_g3sg1.mdl")
				entity_set_string(id,EV_SZ_weaponmodel,"models/gold/p_g3sg1.mdl")
			}
			case CSW_GALIL:
			{
				entity_set_string(id, EV_SZ_viewmodel, "models/gold/v_galil.mdl")
				entity_set_string(id,EV_SZ_weaponmodel,"models/gold/p_galil.mdl")
			}
			case CSW_M3:
			{
				entity_set_string(id, EV_SZ_viewmodel, "models/gold/v_m3.mdl")
				entity_set_string(id,EV_SZ_weaponmodel,"models/gold/p_m3.mdl")
			}
			case CSW_M4A1:
			{
				entity_set_string(id, EV_SZ_viewmodel, "models/gold/v_m4a1.mdl")
				entity_set_string(id,EV_SZ_weaponmodel,"models/gold/p_m4a1.mdl")
			}
			case CSW_M249:
			{
				entity_set_string(id, EV_SZ_viewmodel, "models/gold/v_m249.mdl")
				entity_set_string(id,EV_SZ_weaponmodel,"models/gold/p_m249.mdl")
			}
			case CSW_MAC10:
			{
				entity_set_string(id, EV_SZ_viewmodel, "models/gold/v_mac10.mdl")
				entity_set_string(id,EV_SZ_weaponmodel,"models/gold/p_mac10.mdl")
			}
			case CSW_MP5NAVY:
			{
				entity_set_string(id, EV_SZ_viewmodel, "models/gold/v_mp5.mdl")
				entity_set_string(id,EV_SZ_weaponmodel,"models/gold/p_mp5.mdl")
			}
			case CSW_P90:
			{
				entity_set_string(id, EV_SZ_viewmodel, "models/gold/v_p90.mdl")
				entity_set_string(id,EV_SZ_weaponmodel,"models/gold/p_p90.mdl")
			}
			case CSW_P228:
			{
				entity_set_string(id, EV_SZ_viewmodel, "models/gold/v_p228.mdl")
				entity_set_string(id,EV_SZ_weaponmodel,"models/gold/p_p228.mdl")
			}
			case CSW_SCOUT:
			{
				entity_set_string(id, EV_SZ_viewmodel, "models/gold/v_scout.mdl")
				entity_set_string(id,EV_SZ_weaponmodel,"models/gold/p_scout.mdl")
			}
			case CSW_SG550:
			{
				entity_set_string(id, EV_SZ_viewmodel, "models/gold/v_sg550.mdl")
				entity_set_string(id,EV_SZ_weaponmodel,"models/gold/p_sg550.mdl")
			}
			case CSW_SG552:
			{
				entity_set_string(id, EV_SZ_viewmodel, "models/gold/v_sg552.mdl")
				entity_set_string(id,EV_SZ_weaponmodel,"models/gold/p_sg552.mdl")
			}
			case CSW_TMP:
			{
				entity_set_string(id, EV_SZ_viewmodel, "models/gold/v_tmp.mdl")
				entity_set_string(id,EV_SZ_weaponmodel,"models/gold/p_tmp.mdl")
			}
			case CSW_UMP45:
			{
				entity_set_string(id, EV_SZ_viewmodel, "models/gold/v_ump45.mdl")
				entity_set_string(id,EV_SZ_weaponmodel,"models/gold/p_ump45.mdl")
			}
			case CSW_USP:
			{
				entity_set_string(id, EV_SZ_viewmodel, "models/gold/v_usp.mdl")
				entity_set_string(id,EV_SZ_weaponmodel,"models/gold/p_usp.mdl")
			}
			case CSW_XM1014:
			{
				entity_set_string(id, EV_SZ_viewmodel, "models/gold/v_xm1014.mdl")
				entity_set_string(id,EV_SZ_weaponmodel,"models/gold/p_xm1014.mdl")
			}
		}
	}
		
	return PLUGIN_CONTINUE;
}

public zp_fw_core_cure_post(id)
	fwd_PlayerSpawn(id)

//bonusy goldow
public TakeDamage(this, idinflictor, idattacker, Float:damage)
{
	if(!is_user_alive(this) || !is_user_connected(this) || !is_user_connected(idattacker) || get_user_team(this) == get_user_team(idattacker))
		return HAM_IGNORED;
	
	if(zp_core_is_zombie(idattacker))
		return HAM_IGNORED;
	
	if(PlayerLevel[idattacker] > 23)
		damage *= 1.1
		
	SetHamParamFloat(4, damage);
	return HAM_IGNORED;
}

public Weapon_Reload_Post(iEnt)
{
	new id = get_pdata_cbase(iEnt, m_pPlayer, 4)
	
	if(task_exists(id+TASK_OFFSET))
		return PLUGIN_HANDLED;
	
	if(PlayerLevel[id] > 23)
	{
		new Float:fDelay = g_fDelay[get_pdata_int(iEnt, m_iId, 4)] * 0.8
		if( get_pdata_int(iEnt, m_fInReload, 4))
		{
			set_pdata_float(id, m_flNextAttack, fDelay, 5)
			set_pdata_float(iEnt, m_flTimeWeaponIdle, fDelay + 0.5, 4)
		}
		set_task(fDelay,"Reload",id+TASK_OFFSET);
	}
	
	return PLUGIN_CONTINUE;
}

public Reload(id){
	
	id-=TASK_OFFSET;
	
	if(!is_user_alive(id) || !is_user_connected(id))
		return PLUGIN_HANDLED
	
	set_user_clip(id, maxClip[get_user_weapon(id)])
	
	return PLUGIN_HANDLED
}

stock set_user_clip(id, ammo)
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE;
	new weaponname[32], weaponid = -1, weapon = get_user_weapon(id, _, _);
	if(weapon == 0 || weapon == CSW_HEGRENADE || weapon == CSW_SMOKEGRENADE || weapon == CSW_FLASHBANG)
		return PLUGIN_CONTINUE;
	get_weaponname(weapon, weaponname, 31);
	while ((weaponid = find_ent_by_class(weaponid, weaponname)) != 0)
	if(entity_get_edict(weaponid, EV_ENT_owner) == id) 
	{
		set_pdata_int(weaponid, 51, ammo, 4);
		return weaponid;
	}
	return 0;
}

//exp x2
public Sprawdz()
{
	new timestr[3];
	
	get_time("%H", timestr, 2);
	new godzina = str_to_num(timestr);

	new bool:aktywne;
	
	new odgodziny = get_pcvar_num(pcvarOdgodziny),
	dogodziny = get_pcvar_num(pcvarDogodziny);
	
	if(odgodziny > dogodziny)
	{
		if(godzina >= odgodziny || godzina < dogodziny)
		aktywne = true;
	}
	else
	{
		if(godzina >= odgodziny && godzina < dogodziny)
		aktywne = false;
	}                                                                               
	
	if(aktywne)
	{
		nocny_exp = true;
		return;
	}

	get_time("%M", timestr, 2);
	new minuta = str_to_num(timestr);

	set_task(minut(60-minuta), "Sprawdz");
}

public przelicz_exp(id, ammount)
{
	if(nocny_exp)
	{
		ammount = floatround(ammount * 1.5)
	}
	if(get_user_flags(id) & ADMIN_LEVEL_H)
	{
		ammount = floatround(ammount * 1.2)
	}
	return ammount;
}

public pomoc_info(id){
	new pomoc=menu_create("Pliki Pomocy Serwera ZM EXP","pomoc_info_Handle");
	
	menu_additem(pomoc,"Ogolnie o serwerze");//item=0
	menu_additem(pomoc,"Jak grac Zombi oraz Ludzmi");//item=0
	menu_additem(pomoc,"Jak zdobywac EXP?");//item=1
	menu_additem(pomoc,"Bindy. Z czym to sie je?");//item=2
	menu_additem(pomoc,"O Zlotych Broniach");//item=3
	menu_additem(pomoc,"O VIP'ie");//item=4
	
	menu_display(id, pomoc,0);
	return PLUGIN_HANDLED;
}

public pomoc_info_Handle(id, menu, item){
	switch(item){
		case 0:{
			new opis[1501], iLen=0, iMax=sizeof(opis) - 1;
			iLen += formatex(opis[iLen], iMax-iLen, "Glownym zadaniem jako Zombi jest zarazenie lub zabicie wszystkich ludzi, natomiast zadaniem ludzi jest przetrwanie rundy.<br>");
			iLen += formatex(opis[iLen], iMax-iLen, "W wykonywaniu celow obu stron pomocny jest sklep (otworz menu klawiszem M lub wpisz na say'u /zpmenu i wybierz opcje 2) Waluta w sklepie sa paczki z amunicja ktore zdobywamy za zadawanie obrazen, zabijanie czy zarazanie wrogow.<br>");
			iLen += formatex(opis[iLen], iMax-iLen, "Za wykonywanie celow otrzymuje sie EXP. Po osiagnieciu okreslonej ilosci expa awansujesz do kolejnego poziomu i odblokujesz nowa bron. Na serwerze jest 46 poziomow do zdobycia (23 normalne oraz 23 zlote).<br>");
			iLen += formatex(opis[iLen], iMax-iLen, "Serwer poziada kilka trybow rozgrywki jak np. Nemesis czy Sniper. Sa to bosy za ktorych zabicie dostajemy zwykle kilka razy wiecej AmmoPackow oraz EXPA.<br>");
			iLen += formatex(opis[iLen], iMax-iLen, "Jezeli masz z czyms problem i nie znalazles odpowiedzi w plikach pomocy popros o pomoc adminow lub innych gracze ew. opisz swoj problem na forum xSteam.pl.<br>");
			iLen += formatex(opis[iLen], iMax-iLen, "Jezeli masz problem z gra zachecamy do kupna vipa w naszym automatycznym sklepie ktory znajdziesz pod adresem csfifka.pl/sklep.<br><br>");
			iLen += formatex(opis[iLen], iMax-iLen, "Wpisz /pomoc aby uzyskac odpowiedzi na pytania.");

			showpomoc(id,"Bindy<br>Z czym to sie je?",opis)
			pomoc_info(id)
			}
			case 1:{
				pomoc_jak_grac(id)
			}
		case 2:{
			new opis[1501], iLen=0, iMax=sizeof(opis) - 1;
			iLen += formatex(opis[iLen], iMax-iLen, "Exp na serwerze mozna zdobywac na kilka sposobow!<br>");
			iLen += formatex(opis[iLen], iMax-iLen, "Jako Czlowiek:<br>");
			iLen += formatex(opis[iLen], iMax-iLen, "- Zabijanie Zombi,<br>");
			iLen += formatex(opis[iLen], iMax-iLen, "- Zadanie okreslonej liczby obrazen,<br>");
			iLen += formatex(opis[iLen], iMax-iLen, "- Zabicie bosow jak Nemesis, Assasyn czy Matka daje kilkakrotnie wiecej expa oraz AP niz zabicie zwyklego Zombi,<br>");
			iLen += formatex(opis[iLen], iMax-iLen, "- Kupno Expa w sklepie za AP.<br><br>");
			iLen += formatex(opis[iLen], iMax-iLen, "Jako Zombi:<br>");
			iLen += formatex(opis[iLen], iMax-iLen, "- Zarazanie Ludzi,<br>");
			iLen += formatex(opis[iLen], iMax-iLen, "- Niszczenie LaserMin,<br>");
			iLen += formatex(opis[iLen], iMax-iLen, "- Ginac jako Zombi otrzymujesz expa za probe zarazenia rowna polowie expa za zarazenie,<br>");
			iLen += formatex(opis[iLen], iMax-iLen, "- Zabicie bosow jak Survivor, Sniper czy Ostatni Czlowiek daje kilkakrotnie wiecej expa oraz AP niz zabicie zarazenie zwyklego ocalenca,<br>");
			iLen += formatex(opis[iLen], iMax-iLen, "- Kupno Expa w sklepie za AP.<br><br>");
			iLen += formatex(opis[iLen], iMax-iLen, "Wpisz /pomoc aby uzyskac odpowiedzi na pytania.");
			showpomoc(id,"Bindy<br>Opis bindow na serwerze",opis)
			pomoc_info(id)
			}
		case 3:
			{
				pomoc_bindy_start(id)
			}
		case 4:
			{
				pomoc_goldy(id)
				pomoc_info(id)
			}
		case 5:
			{
				vip_info(id);
			}
	}
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public vip_info(id){
	new vip=menu_create("Szczegoly vipa","pomoc_vip_Handle");
	
	menu_additem(vip,"Korzyœci z posiadania Vip'a");//item=0
	menu_additem(vip,"Jak kupic Vip'a");//item=0
	
	menu_display(id, vip,0);
	return PLUGIN_HANDLED;
}

public pomoc_vip_Handle(id, menu, item){
	switch(item){
		case 0:{
				show_motd(id, "vip.txt", "Informacje o Vipie");
				vip_info(id)
			}
			case 1:{
				new opis[1501], iLen=0, iMax=sizeof(opis) - 1;
				iLen += formatex(opis[iLen], iMax-iLen, "VIP'a kupisz na stronie sklepu serwera<br>");
				iLen += formatex(opis[iLen], iMax-iLen, "www.sklep.zm.csnajpe.eu<br>");
				iLen += formatex(opis[iLen], iMax-iLen, "Instrukcje jak kupic Vip'a lub exp znajdziesz na stronie glownej sklepu (czytaj newsy).<br>");

				showpomoc(id,"V.I.P<br>Korzysci, jak kupic.",opis);
				
				vip_info(id);
			}
			default:
				pomoc_info(id)
	}
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public pomoc_jak_grac(id){
	new pomoc=menu_create("Jak Grac poszczegolnymi frakcjami","pomoc_jakgrac_Handle");
	
	menu_additem(pomoc,"Jak Grac Ludzmi");//item=3
	menu_additem(pomoc,"Jak Grac Zombi");//item=3
	
	menu_display(id, pomoc,0);
	return PLUGIN_HANDLED;
}

public pomoc_jakgrac_Handle(id, menu, item){
	switch(item){
		case 0:{
			new opis[1501], iLen=0, iMax=sizeof(opis) - 1;
			iLen += formatex(opis[iLen], iMax-iLen, "Chcesz jak najdluzej wytrzymac w kampie? Posluchaj tych rad:<br><br>");
			iLen += formatex(opis[iLen], iMax-iLen, "1. Wybieraj klase odpowiadajaca twojemu stylowi gry.<br>");
			iLen += formatex(opis[iLen], iMax-iLen, "2.Zabijaj mnowstwo Zombi aby szybko zdobywac poziom oraz nowe bronie.<br>");
			iLen += formatex(opis[iLen], iMax-iLen, "3. Kamp w 3-4 osoby w kampie - przy wiekszej ilosci osob pamietaj o Masce Antyinfekcyjnej - ochroni Cie oraz sojusznikow przed bomba infekcyjna.<br>");
			iLen += formatex(opis[iLen], iMax-iLen, "4. Ustalcie role w kampie oraz przekazujcie AP osobie najblizej wyjscia aby mogla stawiac LM'y.<br>");
			iLen += formatex(opis[iLen], iMax-iLen, "5. Jezeli Zombie uzyje Madnesa kup szybko Miny - zabija one obrazenia nawet wtedy gdy ZM jest niesmiertelne.<br><br>");

			showpomoc(id,"Ludzie<br>Jak Grac",opis)
			pomoc_jak_grac(id)
			}
		case 1:{
			new opis[1501], iLen=0, iMax=sizeof(opis) - 1;
			iLen += formatex(opis[iLen], iMax-iLen, "Zombi gra sie nieco trudniej niz ludzmi. Jednak znajac pare trickow mozna latwo ich dopasc:<br><br>");
			iLen += formatex(opis[iLen], iMax-iLen, "1. Pamietaj aby wybrac klase ktora najlepiej gra sie w danej chwili: duzo kamp na wysokosciach - Skoczny Zombi, ludzie sie zabunkrowali i nie mozesz przejsc ich obrony (laser min, min) - Grudy Zombie itd.<br>");
			iLen += formatex(opis[iLen], iMax-iLen, "2. Pamietaj aby idac w kampie do ludzi skakac (poruszamy sie wtedy szybciej gdy w nas strzelaja) oraz aby isc tylem (ciezej wtedy trafic cie w glowe).<br>");
			iLen += formatex(opis[iLen], iMax-iLen, "3. Gdy bijesz LaserMine, pamietaj aby uderzac ja PPM - szybciej ja niszczysz.<br>");
			iLen += formatex(opis[iLen], iMax-iLen, "4. Gdy ludzie za mocno sie okopali mozesz namowic innych zm do zorganizowania zbiorki AP na bombe infekcyjna.<br><br>");

			showpomoc(id,"Zombi<br>Jak Grac",opis)
			pomoc_jak_grac(id)
			}
		default:
			{
				pomoc_info(id)
			}
	}
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public pomoc_bindy_start(id){
	new pomoc=menu_create("Informacje o Bindach","pomoc_bindystart_Handle");
	
	menu_additem(pomoc,"Jak ustawic bindy?");//item=3
	menu_additem(pomoc,"Przydatne Bindy");//item=3
	
	menu_display(id, pomoc,0);
	return PLUGIN_HANDLED;
}

public pomoc_bindystart_Handle(id, menu, item){
	switch(item){
		case 0:{
			new opis[1501], iLen=0, iMax=sizeof(opis) - 1;
			iLen += formatex(opis[iLen], iMax-iLen, "Bindy umozliwiaja nam przypisac funkcje do klawiszy. Valve bardzo tepi ustawianie bindow graczom, dlatego w wiekszosci przypadkow aby uzyc mocy klasy bedziesz musial sam ustawic bind. Ale jak to zrobic..? Wszystko sprowadza sie do wpisania w konsole gry prostej formuly:<br>");
			iLen += formatex(opis[iLen], iMax-iLen, "bind klawisz moc<br>Wyjasnienie:<br>Za <b>klawisz</b> wpisujemy literke pod ktora chcemy miec szybki dostep do mocy<br><b>moc</b> - to specjalny uchwyt mocy, ale o nim za chwile<br>");
			iLen += formatex(opis[iLen], iMax-iLen, "Teraz pokaze wam przykladowy bind np. na stawianie min:<br>bind v +mina<br>Poczatek jest zawsze taki sam: <b>bind</b>, nastepnie literka pod ktora chcemy miec moc (w tym wypadku <b>V</b>) oraz uchwyt ktory jest specyficzny dla kazdej mocy (uchwyty wszystkich mocy podam pozniej). ");
			iLen += formatex(opis[iLen], iMax-iLen, "Dzieki temu klikajac klawisz V i majac miny w ekwipunku postawimy ja na ziemii.<br>");
			iLen += formatex(opis[iLen], iMax-iLen, "Uchwyty mocy dostepne sa w menu ktore wlasnie teraz powinienes miec po lewej stronie (opcja 2).<br><br>");

			showpomoc(id,"Bindy<br>Z czym to sie je?",opis)
			pomoc_bindy_start(id)
			}
		case 1:{
			new opis[1501], iLen=0, iMax=sizeof(opis) - 1;
			iLen += formatex(opis[iLen], iMax-iLen, "Krotkie przypomnienie jak ustawic bind:<br>bind klawisz moc<br>Slowo <b>bind</b> zawsze musi byc na poczatku, <b>klawisz</b> to litera/cyfra pod ktora chcemy miec moc, natomiast <b>moc</> to uchwyt, a przedstawiam je ponizej<br>");
			iLen += formatex(opis[iLen], iMax-iLen, "Miny - +mina<br>");
			iLen += formatex(opis[iLen], iMax-iLen, "Szybkie kupienie LM - 'say /lm'<br>");
			iLen += formatex(opis[iLen], iMax-iLen, "Postawienie LM - +setlaser<br>");
			iLen += formatex(opis[iLen], iMax-iLen, "Sciagniecie LM - +dellaser<br>");
			iLen += formatex(opis[iLen], iMax-iLen, "Menu ZombieMod - 'say /zpmenu'<br><br>");
			iLen += formatex(opis[iLen], iMax-iLen, "Jezeli brakuje jakis bindow, daj znac o tym na forum :)");

			showpomoc(id,"Bindy<br>Opis bindow na serwerze",opis)
			pomoc_bindy_start(id)
			}
		default:
			{
				pomoc_info(id)
			}
	}
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public pomoc_goldy(id)
{
	new opis[1501], iLen=0, iMax=sizeof(opis) - 1;
	iLen += formatex(opis[iLen], iMax-iLen, "Po wbiciu zwyklych broni tj. 23 poziomy kolejne 23 poziomy to zlote bronie. Niestety po zdobyciu 24 poziomu (pierwszy poziom zlotych broni) tracimy wszystkie bronie i znow startujemy od glocka.<br>");
	iLen += formatex(opis[iLen], iMax-iLen, "Zlote bronie takze ciezej sie expi, ale spokojnie - posiadaja one dodatkowe bonusy rozniace je od zwyklych broni jak np. szybsze przeladowanie oraz zwiekszone obrazenia<br>");
	iLen += formatex(opis[iLen], iMax-iLen, "Zlote bronie jak sama nazwa wskazuje posiadaja unikalny wyglad (niektore z nich):<br>");
	iLen += formatex(opis[iLen], iMax-iLen, "<img src=^"http://csfifka.pl/uploads/obrazy/zm_gold_weapons.jpg^" /><br>");
	iLen += formatex(opis[iLen], iMax-iLen, "Oraz unikalny skin tylko dla graczy ktorzy posiadaja Zlote Bronie (Gold Crysis):<br>");
	iLen += formatex(opis[iLen], iMax-iLen, "<img src=^"http://csfifka.pl/uploads/obrazy/zm_gold_crysis.jpg^" /><br>");
	
	showpomoc(id,"Bonusy z posiadania goldow",opis)
}

public showpomoc(id,itemname[],itemeffect[])
{
	new diabloDir[64]	
	new g_ItemFile[64]
	new amxbasedir[64]
	get_basedir(amxbasedir,63)
	
	format(diabloDir,63,"%s/diablo",amxbasedir)
	
	if (!dir_exists(diabloDir))
	{
		new errormsg[512]
		format(errormsg,511,"Blad: Folder %s/diablo nie mog³ byæ znaleziony. Prosze skopiowac ten folder z archiwum do folderu amxmodx",amxbasedir)
		show_motd(id, errormsg, "An error has occured")	
		return PLUGIN_HANDLED
	}
	
	
	format(g_ItemFile,63,"%s/diablo/pomoc.txt",amxbasedir)
	if(file_exists(g_ItemFile))
	delete_file(g_ItemFile)
	
	new Data[1501]
	
	//Header
	format(Data,1500,"<html><head><title>Pliki Pomocy</title></head>")
	write_file(g_ItemFile,Data,-1)
	
	//Background
	format(Data,1500,"<body text=^"#FFFF00^" background=^"http://csfifka.pl/uploads/codmocicons/cod_dark.jpg^">")
	write_file(g_ItemFile,Data,-1)
	
	//Table stuff
	format(Data,1500,"<table border=^"0^" cellpadding=^"0^" cellspacing=^"0^" style=^"border-collapse: collapse^" width=^"100%s^"><tr><td width=^"0^">","^%")
	write_file(g_ItemFile,Data,-1)

	//temat
	format(Data,1500,"<td width=^"0^"><p align=^"center^"><font color=^"#DDDDDD^"><b><u></u>%s</b></font><br><br>",itemname)
	write_file(g_ItemFile,Data,-1)
	
	//Effects
	format(Data,1500,"<font size=^"2^" color=^"#FFCC00^"><center>%s<center></font></font></td>",itemeffect)
	write_file(g_ItemFile,Data,-1)
	
	//end
	format(Data,1500,"</tr></table></body></html>")
	write_file(g_ItemFile,Data,-1)
	
	//show window with message
	show_motd(id, g_ItemFile, "Pliki Pomocy")
	
	return PLUGIN_HANDLED
}

public EventRoundEnd()
{
	for (new id=0; id < 33; id++) {
		if(!is_user_connected(id) || !is_user_alive(id)/* || ilosc_graczy < min_licz_graczy*/)
			continue;
		
		set_task(1.0,"czy_wygral_runde",id);
	}
}

public czy_wygral_runde(id)
{
	if(zp_core_get_human_count() <= 0 && zp_core_is_zombie(id))
	{
		g_stats_zm_win[id]++
		g_stats_points[id] += 3
	}
	else if(zp_core_get_zombie_count() <= 0 && !zp_core_is_zombie(id))
	{
		g_stats_hm_win[id]++
		g_stats_points[id] += 3
	}
	
	return PLUGIN_CONTINUE;
}

public increaseMinutes()
{
	new players[32], pnum, tempid
	get_players(players, pnum)
	
	for(new i; i<pnum; i++)
	{
		tempid = players[i]
		new CsTeams:team = cs_get_user_team(tempid)
		
		if(team != CS_TEAM_SPECTATOR && team != CS_TEAM_UNASSIGNED)
		{
			g_stats_czas_online[tempid]++
		}
	}
}

//statystyki

public wczytaj_statystyki()
{
	cmdTop10()
	cmdTop10_misje()
	cmdTop10_xp()
	cmdTop10_online()
}

public Staty(id){
	new Staty=menu_create("Statystyki ZM EXP","Staty_Handle");
	
	menu_additem(Staty,"\rTOP 10 Najlepszych Graczy");//item=0
	menu_additem(Staty,"Gracze Online");//item=1
	menu_additem(Staty,"\yTwoje Statystyki");//item=2
	menu_additem(Staty,"Top10 Zdobytego Expa");//item=3
	menu_additem(Staty,"Top10 Czasu Online");//item=4
	menu_additem(Staty,"Top10 Wykonanych Misji");//item=5
	menu_additem(Staty,"\yO Punktach Rankingowych");//item=6
	
	menu_display(id, Staty,0);
	return PLUGIN_HANDLED;
}
public Staty_Handle(id, menu, item)
{
	switch(item)
	{
		case 0:
		{
			top10(id)
			Staty(id)
		}
		case 1:
		{
			showtop20(id)
			Staty(id)
		}
		case 2:
		{
			moje_staty(id)
			Staty(id)
		}
		case 3:
		{
			top10_xp(id)
			Staty(id)
		}
		case 4:
		{
			top10_online(id)
			Staty(id)
		}
		case 5:
		{
			top10_misje(id)
			Staty(id)
		}
		case 6:
		{
			jak_zdobywac_punkty(id)
			Staty(id)
		}
	}
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public cmdTop10()
{
	SQL_ThreadQuery(g_SqlTuple, "top10Thread","SELECT * FROM zm_expp ORDER BY totalpoints DESC LIMIT 10")
}
public top10Thread(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
	if(FailState == TQUERY_CONNECT_FAILED)
		return set_fail_state("Could not connect to SQL database.")
	else if(FailState == TQUERY_QUERY_FAILED)
		return set_fail_state("Query failed.")
	
	if(Errcode)
		return log_amx("Error on query: %s",Error)
	
	new count = 0
	while(SQL_MoreResults(Query))
	{
		// columns start at 0
		staty_top10_level[count] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query,"lvl"))
		staty_top10_points[count] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query,"totalpoints"))
		staty_top10_ammopacks[count] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query,"ammopacks"))
		staty_top10_dam_done[count] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query,"dam_done"))
		staty_top10_zm_kill[count] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query,"zm_kill"))
		staty_top10_hm_infkill[count] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query,"hm_infkill"))
		staty_top10_nem_kill[count] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query,"nem_kill"))
		staty_top10_sur_kill[count] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query,"sur_kill"))
		staty_top10_ass_kill[count] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query,"ass_kill"))
		staty_top10_sni_kill[count] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query,"sni_kill"))
		SQL_ReadResult(Query, 0, name_top10[count], 44)
		
		count++
		
		SQL_NextRow(Query)
	}
	
	return PLUGIN_CONTINUE
}
public top10(id)
{
	new msg[4001]
	new len=0, iMax=sizeof(msg) - 1
	
	len += formatex(msg[len], iMax-len, "<html><body bgcolor=^"#33CCFF^"><center><b><font size=^"5^" color=^"black^">Top10 Serwera ZM EXP</font></b><br>Dane aktualizuja sie co zmiane mapy!")
	
	len += formatex(msg[len], iMax-len, "<table border=^"1^">")
	
	len += formatex(msg[len], iMax-len, "<tr><td>Poz.</font></td>")
	
	len += formatex(msg[len], iMax-len, "<td style=^"width: 40px;^">Nick</td>")
	
	len += formatex(msg[len], iMax-len, "<td>Punkty</td>")
	
	len += formatex(msg[len], iMax-len, "<td>Poziom</td>")
	
	len += formatex(msg[len], iMax-len, "<td>Czas Online</td>")
	
	len += formatex(msg[len], iMax-len, "<td>Wyk. Misji</td>")
	
	len += formatex(msg[len], iMax-len, "<td>Zadane DMG</td>")
	
	len += formatex(msg[len], iMax-len, "<td>Zdobyte AP</td>")
	
	len += formatex(msg[len], iMax-len, "<td>Zab. Zombi</td>")
	
	len += formatex(msg[len], iMax-len, "<td>Zab/Inf Ludzi</td></tr>")

	new count = 1
	for(new i = 0; i <= 9; i++)
	{
		if(equali(name_top10[i], ""))
			break;
		len += formatex(msg[len], iMax-len, "<tr><td>%i.</td>", count)
		
		len += formatex(msg[len], iMax-len, "<td>%s</td>", name_top10[i])
		
		len += formatex(msg[len], iMax-len, "<td>%i</td>", staty_top10_points[i])
		
		len += formatex(msg[len], iMax-len, "<td>%i</td>", staty_top10_level[i])
		
		len += formatex(msg[len], iMax-len, "<td>%i min.</td>", staty_czas_online[i])
		
		len += formatex(msg[len], iMax-len, "<td>%i</td>", staty_top_misje[i])
		
		len += formatex(msg[len], iMax-len, "<td>%i</td>", staty_top10_dam_done[i])
		
		len += formatex(msg[len], iMax-len, "<td>%i</td>", staty_top10_ammopacks[i])
		
		len += formatex(msg[len], iMax-len, "<td>%i</td>", staty_top10_zm_kill[i])
		
		len += formatex(msg[len], iMax-len, "<td>%i</td></tr>", staty_top10_hm_infkill[i])
		
		count++
	}
	
	len = formatex(msg[len], iMax-len, "</center></table></body></html>")
	
	show_motd(id, msg, "Top10")
	
	return PLUGIN_CONTINUE;
}

public showtop20(id)
{
	if( !get_pcvar_num(p_Enabled) && !get_pcvar_num(show_rank) )
		return;
	
	static Sort[33][2];
	new players[32],num,count,index;
	get_players(players,num);
    
	for(new i = 0; i < num; i++)
	{
		index = players[i];
		Sort[count][0] = index;
		Sort[count][1] = PlayerXp[index];
		count++;
	}
    
	SortCustom2D(Sort,count,"CompareXp");
	new msg[3001]
	new len=0, iMax=sizeof(msg) - 1
	
	len += formatex(msg[len], iMax-len, "<html><body bgcolor=^"#33CCFF^"><center><b><font size=^"5^" color=^"black^">Gracze Online</font></b>")
	
	len += formatex(msg[len], iMax-len, "<table border=^"1^">")
	
	len += formatex(msg[len], iMax-len, "<tr><td>Poz.</font></td>")
	
	len += formatex(msg[len], iMax-len, "<td style=^"width: 40px;^">Nick</td>")
	
	len += formatex(msg[len], iMax-len, "<td>Poziom</td>")
	
	len += formatex(msg[len], iMax-len, "<td>Exp</td>")
	
	len += formatex(msg[len], iMax-len, "<td>AP</td>")
	
	len += formatex(msg[len], iMax-len, "<td>Fragi</td>")
	
	len += formatex(msg[len], iMax-len, "<td>Zginiec</td></tr>")
    
	new y = clamp(count,0,20);
	new name[32],kindex, name_max=sizeof(name) - 1
    
	for(new i = 0; i < y; i++)
	{
		kindex = Sort[i][0];
		get_user_name(kindex,name,name_max);
//		iLen += formatex(motd[iLen], (sizeof motd - 1) - iLen,"%d %-22.22s %d^n", x + 1, name, Sort[x][1]);
		
		if(equali(name, ""))
			break;
		len += formatex(msg[len], iMax-len, "<tr><td>%i.</td>", i + 1)
		
		len += formatex(msg[len], iMax-len, "<td>%s</td>", name)
		
		len += formatex(msg[len], iMax-len, "<td>%i</td>", PlayerLevel[kindex])
		
		len += formatex(msg[len], iMax-len, "<td>%i</td>", PlayerXp[kindex])
		
		len += formatex(msg[len], iMax-len, "<td>%i</td>", zp_ammopacks_get(kindex))
		
		len += formatex(msg[len], iMax-len, "<td>%i</td>", get_user_frags(kindex))
		
		len += formatex(msg[len], iMax-len, "<td>%i</td></tr>", get_user_deaths(kindex))
		
	}
	len = formatex(msg[len], iMax-len, "</center></table></body></html>")
	show_motd(id,msg, "Gracze Online");
}

public moje_staty(id)
{
	new msg[3001]
	new len=0, iMax=sizeof(msg) - 1
	
	new Float:wsp = float(g_stats_zm_kill[id]) / float(g_stats_deaths[id])
	
	len += formatex(msg[len], iMax-len, "<html><body bgcolor=^"black^"><font color=^"yellow^" size=^"2^"><center><b><font size=^"5^" color=^"green^">Statystyki Serwera ZM EXP</font></b></center><br>")
	
	len += formatex(msg[len], iMax-len, "<b><font size=^"3^" color=^"red^">Twoje Punkty Rankingowe: %i</font></b><br><br>", g_stats_points[id])
	
	len += formatex(msg[len], iMax-len, "W ciagu przegranych %i minut na serwerze zdobyles %i AP zadajac %i obrazen, w tym:<br>", g_stats_czas_online[id], g_stats_ammopacks[id], g_stats_dam_done[id])
	
	len += formatex(msg[len], iMax-len, "- Zabiles %i Zombi,<br>", g_stats_zm_kill[id])
	
	len += formatex(msg[len], iMax-len, "- Zabiles/Zaraziles %i Ludzi,<br>", g_stats_hm_infkill[id])
	
	len += formatex(msg[len], iMax-len, "- Zabiles %i Matek Zombi,<br>", g_stats_matki_kill[id])
	
	len += formatex(msg[len], iMax-len, "- Zabiles %i Ostatnich Ludzi,<br>", g_stats_last_hm_kill[id])
	
	len += formatex(msg[len], iMax-len, "- Zabiles %i Nemesis,<br>", g_stats_nem_kill[id])
	
	len += formatex(msg[len], iMax-len, "- Zabiles %i Survivorow,<br>", g_stats_sur_kill[id])
	
	len += formatex(msg[len], iMax-len, "- Zabiles %i Assasynow,<br>", g_stats_ass_kill[id])
	
	len += formatex(msg[len], iMax-len, "- Zabiles %i Snajperow,<br>", g_stats_sni_kill[id])
	
	len += formatex(msg[len], iMax-len, "- Zginales/zostales zarazony %i raz(y),<br>", g_stats_deaths[id])
	
	len += formatex(msg[len], iMax-len, "- Wygrales %i rund(y) jako Zombi oraz %i rund(y) jako Czlowiek<br><br>", g_stats_zm_win[id], g_stats_hm_win[id])
	
	len += formatex(msg[len], iMax-len, "- Wykonales %i Misje/i<br><br>", sprawdz_ile_wykonano(id))
	
	len += formatex(msg[len], iMax-len, "- Twoj wspolczynik zabojstw/zarazen do zginiec wynosi: %0.1f<br>", wsp)
	
	len += formatex(msg[len], iMax-len, "</font></body></html>")
	
	show_motd(id, msg, "Moje Statystyki")
	
	return PLUGIN_CONTINUE;

}

public cmdTop10_xp()
{
	SQL_ThreadQuery(g_SqlTuple, "top10Thread_xp","SELECT * FROM zm_expp ORDER BY exp DESC LIMIT 10")
}
public top10Thread_xp(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
	if(FailState == TQUERY_CONNECT_FAILED)
		return set_fail_state("Could not connect to SQL database.")
	else if(FailState == TQUERY_QUERY_FAILED)
		return set_fail_state("Query failed.")
	
	if(Errcode)
		return log_amx("Error on query: %s",Error)
	
	new count = 0
	while(SQL_MoreResults(Query))
	{
		// columns start at 0
		staty_level[count] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query,"lvl"))
		staty_exp[count] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query,"exp"))
		SQL_ReadResult(Query, 0, name_top_exp[count], 44)
		
		count++
		
		SQL_NextRow(Query)
	}
	
	return PLUGIN_CONTINUE
}
public top10_xp(id)
{
	new msg[3001]
	new len=0, iMax=sizeof(msg) - 1
	
	len += formatex(msg[len], iMax-len, "<html><body bgcolor=^"#33CCFF^"><center><b><font size=^"5^" color=^"black^">Top10 Zdobytego Doswiadczenia</font></b><br>Dane aktualizuja sie co zmiane mapy!")
	
	len += formatex(msg[len], iMax-len, "<table border=^"1^">")
	
	len += formatex(msg[len], iMax-len, "<tr><td>Poz.</td>")
	
	len += formatex(msg[len], iMax-len, "<td style=^"width: 40px;^">Nick</td>")
	
	len += formatex(msg[len], iMax-len, "<td>Poziom</td>")
	
	len += formatex(msg[len], iMax-len, "<td>EXP</td></tr>")
	
	new count = 1
	for(new i = 0; i <= 9; i++)
	{
		if(equali(name_top_exp[i], ""))
			break;
		len += formatex(msg[len], iMax-len, "<tr><td>%i.</td>", count)
		
		len += formatex(msg[len], iMax-len, "<td>%s</td>", name_top_exp[i])
		
		len += formatex(msg[len], iMax-len, "<td>%i</td>", staty_level[i])
		
		len += formatex(msg[len], iMax-len, "<td>%i</td></tr>", staty_exp[i])
		
		count++
	}
	
	len = formatex(msg[len], iMax-len, "</center></table></body></html>")
	
	show_motd(id, msg, "Top10 Doswiadczenia")
	
	return PLUGIN_CONTINUE;
}

public cmdTop10_online()
{
	SQL_ThreadQuery(g_SqlTuple, "top10Thread_online","SELECT * FROM zm_expp ORDER BY czas_online DESC LIMIT 10")
}
public top10Thread_online(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
	if(FailState == TQUERY_CONNECT_FAILED)
		return set_fail_state("Could not connect to SQL database.")
	else if(FailState == TQUERY_QUERY_FAILED)
		return set_fail_state("Query failed.")
	
	if(Errcode)
		return log_amx("Error on query: %s",Error)
	
	new count = 0
	while(SQL_MoreResults(Query))
	{
		// columns start at 0
		staty_czas_online[count] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query,"czas_online"))
		SQL_ReadResult(Query, 0, name_czas_online[count], 44)
		
		count++
		
		SQL_NextRow(Query)
	}
	
	return PLUGIN_CONTINUE

}
public top10_online(id)
{
	new msg[3001]
	new len=0, iMax=sizeof(msg) - 1
	
	len += formatex(msg[len], iMax-len, "<html><body bgcolor=^"#33CCFF^"><center><b><font size=^"5^" color=^"black^">Top10 Czasu Online</font></b><br>Dane aktualizuja sie co zmiane mapy!")
	
	len += formatex(msg[len], iMax-len, "<table border=^"1^">")
	
	len += formatex(msg[len], iMax-len, "<tr><td>Poz.</td>")
	
	len += formatex(msg[len], iMax-len, "<td style=^"width: 40px;^">Nick</td>")
	
	len += formatex(msg[len], iMax-len, "<td>Czas spedzony na serwerze (min.)</td></tr>")

	new count = 1
	for(new i = 0; i <= 9; i++)
	{
		if(equali(name_czas_online[i], ""))
			break;
		len += formatex(msg[len], iMax-len, "<tr><td>%i.</td>", count)
		
		len += formatex(msg[len], iMax-len, "<td>%s</td>", name_czas_online[i])
		
		len += formatex(msg[len], iMax-len, "<td>%i</td></tr>", staty_czas_online[i])
		
		count++
	}
	
	len = formatex(msg[len], iMax-len, "</center></table></body></html>")
	
	show_motd(id, msg, "Top10 Czasu Online")
	
	return PLUGIN_CONTINUE;
}

public cmdTop10_misje()
{
//	g_Top10TempID_misje = id
	SQL_ThreadQuery(g_SqlTuple, "top10Thread_misje","SELECT * FROM zm_expp ORDER BY ile_wykonano DESC LIMIT 10")
}
public top10Thread_misje(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
	if(FailState == TQUERY_CONNECT_FAILED)
		return set_fail_state("Could not connect to SQL database.")
	else if(FailState == TQUERY_QUERY_FAILED)
		return set_fail_state("Query failed.")
	
	if(Errcode)
		return log_amx("Error on query: %s",Error)
	
	new count = 0
	while(SQL_MoreResults(Query))
	{
		// columns start at 0
		staty_top_misje[count] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query,"ile_wykonano"))
		SQL_ReadResult(Query, 0, name_top_misje[count], 44)
		
		count++
		
		SQL_NextRow(Query)
	}
	
	return PLUGIN_CONTINUE

}
public top10_misje(id)
{
	new msg[3001]
	new len=0, iMax=sizeof(msg) - 1
	
	len += formatex(msg[len], iMax-len, "<html><body bgcolor=^"#33CCFF^"><center><b><font size=^"5^" color=^"black^">Top10 Wykonanych Misji</font></b><br>Dane aktualizuja sie co zmiane mapy!")
	
	len += formatex(msg[len], iMax-len, "<table border=^"1^">")
	
	len += formatex(msg[len], iMax-len, "<tr><td>Poz.</td>")
	
	len += formatex(msg[len], iMax-len, "<td style=^"width: 40px;^">Nick</td>")
	
	len += formatex(msg[len], iMax-len, "<td>Wykonanaych Misji</td></tr>")
	
	new count = 1
	
	for(new i = 0; i <= 9; i++)
	{
		if(equali(name_top_misje[i], ""))
			break;
		len += formatex(msg[len], iMax-len, "<tr><td>%i.</td>", count)
		
		len += formatex(msg[len], iMax-len, "<td>%s</td>", name_top_misje[i])
		
		len += formatex(msg[len], iMax-len, "<td>%i</td></tr>", staty_top_misje[i])
		
		count++
	}
	
	len = formatex(msg[len], iMax-len, "</center></table></body></html>")
	
	show_motd(id, msg, "Top10 Wykonanych Misji")

	return PLUGIN_CONTINUE;
}

public jak_zdobywac_punkty(id)
{
	new msg[3001]
	new len=0, iMax=sizeof(msg) - 1
	
	len += formatex(msg[len], iMax-len, "<html><body bgcolor=^"black^"><font color=^"yellow^" size=^"2^"><center><b><font size=^"5^" color=^"red^">Punkty Rankingowe. Co i Jak?</font></b></center><br>")
	
	len += formatex(msg[len], iMax-len, "<b><font size=^"3^" color=^"green^">Twoje Punkty Rankingowe: %i</font></b><br><br>", g_stats_points[id])
	
	len += formatex(msg[len], iMax-len, "Punkty rankingowe ustalaja twoja pozycje w TOP 10 najlepszych graczy na serwerze.<br>Punkty rankingowe mozesz zdobywac na kilka sposobow:<br><br>")
	
	len += formatex(msg[len], iMax-len, "- Zabicie ZM/zarazenie czlowieka - 1 pkt.<br>")
	len += formatex(msg[len], iMax-len, "- Zabicie Matki/Ostatniego Czlowieka - 5 pkt.<br>")
	len += formatex(msg[len], iMax-len, "- Zabicie Nemesis, Survivor, Assasyna lub Snajpera - 50 pkt.<br>")
	len += formatex(msg[len], iMax-len, "- Zdobycie poziomu - 10 pkt.<br>")
	len += formatex(msg[len], iMax-len, "- Wykonanie Misji - 20 pkt.<br>")
	
	len += formatex(msg[len], iMax-len, "</font></body></html>")
	
	show_motd(id, msg, "Punkty Rankingowe | Co i jak?")
	
	return PLUGIN_CONTINUE;

}

public TaskZapiszExp()
{
	if(g_boolsqlOK)
	{
		for(new id = 1; id <= g_maxplayers; id++)
		{
			if(!is_user_connected(id) || is_user_hltv(id))
				continue;
			if(ilosc_wpisow >= 64)
			{
				ZakonczWpis_ZapiszExp();
			}
			DodajWpis(id);
		}
		ZakonczWpis_ZapiszExp()
	}
	else sql_start();
}
public ZapiszExpHandle(FailState, Handle:Query, Error[], Errcode, Data[], DataSize) {
	
	ResetujZapytanie()
	
	if(Errcode) {
		log_to_file("sql.log", "Error on Save_xp query: %s", Error);
		return PLUGIN_CONTINUE;
	}
	if(FailState == TQUERY_QUERY_FAILED) {
		log_to_file("sql.log", "Save_xp Query failed.");
		return PLUGIN_CONTINUE;
	}
	if(FailState == TQUERY_CONNECT_FAILED) {
		log_to_file("sql.log", "Could not connect to SQL database.");
		return PLUGIN_CONTINUE;
	}
	
//	client_print(0, print_chat,"Exp zostal zapisany");
	
	return PLUGIN_CONTINUE;
}
public ZakonczWpis_ZapiszExp()
{
	replace(ZapiszExp[giLen-1], giLen, ZapiszExp[giLen-1], "")
		
	giLen -= 1
		
	giLen += formatex(ZapiszExp[giLen], giMax-giLen," ON DUPLICATE KEY UPDATE `lvl`=VALUES(`lvl`), `exp`=VALUES(`exp`), `quest_gracza`=VALUES(`quest_gracza`), `ile_juz`=VALUES(`ile_juz`), `ile_wykonano`=VALUES(`ile_wykonano`), `totalpoints`=VALUES(`totalpoints`), `ammopacks`=VALUES(`ammopacks`), `dam_done`=VALUES(`dam_done`), `zm_kill`=VALUES(`zm_kill`), `hm_infkill`=VALUES(`hm_infkill`), `deaths`=VALUES(`deaths`), ")
	giLen += formatex(ZapiszExp[giLen], giMax-giLen,"`nem_kill`=VALUES(`nem_kill`), `sur_kill`=VALUES(`sur_kill`), `ass_kill`=VALUES(`ass_kill`), `sni_kill`=VALUES(`sni_kill`), `matki_kill`=VALUES(`matki_kill`), `last_hm_kill`=VALUES(`last_hm_kill`), `zm_win`=VALUES(`zm_win`), `hm_win`=VALUES(`hm_win`), `czas_online`=VALUES(`czas_online`)")
		
	log_to_file("test_zapis.log", "%s", ZapiszExp);
		
	if(ilosc_wpisow > 0)
		SQL_ThreadQuery(g_SqlTuple, "ZapiszExpHandle", ZapiszExp);
	else ResetujZapytanie();
	
	return;
}
public DodajWpis(id)
{
	if(!wczytalo[id] || is_user_hltv(id))
		return PLUGIN_CONTINUE;
	if(ilosc_wpisow >= 64)
	{
		ZakonczWpis_ZapiszExp();
	}
	new name[48];
	
	get_user_name(id, name, 47)
	replace_all(name, 47, "'", "\'")
	strtolower(name)
	
	giLen += formatex(ZapiszExp[giLen], giMax-giLen," ('%s',%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d),",
	name,PlayerLevel[id],PlayerXp[id],sprawdz_misje_sql(id),sprawdz_ile_juz_sql(id),sprawdz_ile_wykonano(id),g_stats_points[id],g_stats_ammopacks[id],g_stats_dam_done[id],g_stats_zm_kill[id],g_stats_hm_infkill[id],g_stats_deaths[id],g_stats_nem_kill[id],g_stats_sur_kill[id],g_stats_ass_kill[id],g_stats_sni_kill[id],g_stats_matki_kill[id],g_stats_last_hm_kill[id],g_stats_zm_win[id],g_stats_hm_win[id],g_stats_czas_online[id])
	
	ilosc_wpisow++
	
	return PLUGIN_CONTINUE;
}

public ResetujZapytanie()
{
	ZapiszExp = ""
	ilosc_wpisow = 0
	giLen=0, giMax=sizeof(ZapiszExp) - 1
	giLen += formatex(ZapiszExp[giLen], giMax-giLen,"INSERT INTO `zm_expp` (`nick`,`lvl`,`exp`,`quest_gracza`,`ile_juz`,`ile_wykonano`,`totalpoints`,`ammopacks`,`dam_done`,`zm_kill`,`hm_infkill`,`deaths`,`nem_kill`,`sur_kill`,`ass_kill`,`sni_kill`,`matki_kill`,`last_hm_kill`,`zm_win`,`hm_win`,`czas_online`) VALUES")
	
	return PLUGIN_CONTINUE;
}

