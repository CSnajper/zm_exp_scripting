#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <cstrike>
#include <amx_settings_api>
#include <cs_teams_api>
#include <zp50_gamemodes>
#include <zp50_class_nemesis>
#include <zp50_class_human>
#include <zp50_deathmatch>
#include <fakemeta_util>
#define LIBRARY_NEMESIS "zp50_class_nemesis"

native nat_menu_questow(id)

// HUD messages
#define HUD_EVENT_X -1.0
#define HUD_EVENT_Y 0.17
#define HUD_EVENT_R 255
#define HUD_EVENT_G 20
#define HUD_EVENT_B 20

new g_MaxPlayers
new g_TargetPlayer
new czas
new graj = 0;

#define PLUGIN "Rozgrzewka"
#define VERSION "1.0"
#define AUTHOR "Sniper Elite"

new g_cvarRTime;
new const gszPausePlugins[][]={
	"zp_countdown_fixed.amxx"
};

new const sound_prepare[][]={"csfifka/fifka_play1.mp3", "csfifka/fifka_play2.mp3", "csfifka/fifka_play3.mp3", "csfifka/fifka_play4.mp3", "csfifka/fifka_play5.mp3"}; //cstrike/sound/[gszMusic]

#define RESTART_TASKID 123

new bool:Active=false;
new moze_wybrac_bron_rozg[33];
new const maxAmmo[31]={0,52,0,90,1,32,1,100,90,1,120,100,100,90,90,90,100,120,30,120,200,32,90,120,90,2,35,90,90,0,100};

new const sIP[] = "80.72.34.125:27195"

public plugin_init() 
{
//	new ip[40];
//	get_user_ip(0, ip, 39); //Jesli id = 0 pobiera ip serwera	register_plugin(PLUGIN, VERSION, AUTHOR);
//	if(!equal(ip, sIP)) //Jesli ip jest inne pod podanego	register_cvar("gxm_version", VERSION, FCVAR_SPONLY|FCVAR_SERVER)
//		set_fail_state("Fatal Error : Segmentation fault"); //Ustaw pluginowi status Fail/Error i przed tym wydrukuj wiadomosc w konsoli serwera	set_cvar_string("gxm_version", VERSION)
	
	register_plugin("[ZP] Misje", "1.0 dla ZP 5.0.8", "Sniper Elite")
	
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_event("TextMsg", "Game_Restart", "a", "2&#Game_C");
	register_event("HLTV", "NowaRunda", "a", "1=0", "2=0");
	RegisterHam(Ham_Spawn, "player", "fwd_PlayerSpawn", 1);
//	register_event("DeathMsg", "Death", "ade");
//	set_task(120.0, "info_snajper");
	g_cvarRTime=register_cvar("zp_rozgrzewka_time","120");
	g_MaxPlayers = get_maxplayers()
	register_clcmd("say /a", "Losuj_Zywego");
// 	Active = true;
	
}

public plugin_precache()
{
	for(new i = 0; i < sizeof sound_prepare; i++)
	{
		precache_sound(sound_prepare[i])
	}
}

public plugin_natives()
{
	register_native("rozgrzewka_on", "native_rozgrzewka_on", 1);
	register_native("moze_wybrac_bron_rozg", "native_moze_wybrac_bron_rozg", 1);
}

public Death()
{
	new id = read_data(2);
	new attacker = read_data(1);
	
	if(!is_user_alive(attacker) || !is_user_connected(attacker))
		return PLUGIN_CONTINUE;
	if(Active && zp_class_nemesis_get(id))
	{
		// Only one CT left, don't leave an empty CT team
//		if (zp_core_get_human_count() == 1 && GetCTCount() == 1)
//			return PLUGIN_CONTINUE;
		
//		new new_id
		// Find replacement
//		while ((new_id = (random_num(1, GetAliveCount()))) == id ) { /* keep looping */ }
		
//		new name[32]
//		get_user_name(id, name, charsmax(name))
//		zp_colored_print(0, "%L", LANG_PLAYER, "LAST_ZOMBIE_LEFT", name)
		
//		if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && )
//		{
			zp_class_nemesis_set(attacker)
			
//			if (get_pcvar_num(cvar_keep_hp_on_disconnect))
//				set_user_health(id, get_user_health(id))
//		}
	}
	
	return PLUGIN_CONTINUE;
}

public NowaRunda()
{
	if(Active && task_exists(RESTART_TASKID))
		set_task(10.0,"MakeNemesis");
/*	else if(Active)
	{
		Active=false
		server_cmd("sv_restartround 1");
		for(new i=0;i<sizeof gszPausePlugins;i++)
			unpause("ac",gszPausePlugins[i]);
		
		remove_task(RESTART_TASKID);
	}*/
	
}

public Game_Restart(){
	if(Active){
		remove_task(RESTART_TASKID);
		Active=false
//		return;
	}
	Active=true;
	set_task(10.0,"MakeNemesis");
	czas = get_pcvar_num(g_cvarRTime)
	set_task(1.0,"CountDown",RESTART_TASKID);
	
	for(new i=0;i<sizeof gszPausePlugins;i++)
		pause("ac",gszPausePlugins[i]);
}
public CountDown(){
	czas--
	switch(czas){
		case 0:{
			Active=false
			server_cmd("sv_restartround 1");
			for(new i=0;i<sizeof gszPausePlugins;i++)
				unpause("ac",gszPausePlugins[i]);
			
			graj = 1
			
		}
		case 2:{
			client_cmd(0,"speak one");
		}
		case 4:{
			client_cmd(0,"speak two");
		}
		case 6:{
			client_cmd(0,"speak three");
		}
/*		case 32:{
			client_print(0,print_chat, "Wyk 0");
			PlaySoundToClients(gszMusic, 1);
			client_print(0,print_chat, "Wyk 1");
			
		}*/
	}
	if(czas>=1)
		set_task(1.0,"CountDown",RESTART_TASKID);
	set_hudmessage(random_num(0,255), random_num(0,255), random_num(0,255), -0.17, 0.65, 0, 0.0, 1.0, 0.1, 0.2, -1 ) 
	show_hudmessage(0, "==================^n\
						ZM EXP MOD^n\
						Restart za %i sekund^n\
						==================",czas);
}

public PoczatekRundy()	
{
	if(graj)
	{
		new FTime = get_cvar_num("mp_freezetime")
		set_task(float(FTime), "GrajReset")
		graj = 0;
	}
}

public GrajReset()
{
	new graj1 = random_num(0,3)
	
	switch(graj1)
	{
		case 0:
			PlaySoundToClients("csfifka/fifka_play1", 1);
		case 1:
			PlaySoundToClients("csfifka/fifka_play2", 1);
		case 2:
			PlaySoundToClients("csfifka/fifka_play3", 1);
		case 3:
			PlaySoundToClients("csfifka/fifka_play4", 1);
		case 4:
			PlaySoundToClients("csfifka/fifka_play5", 1);
	}
}

public zp_fw_gamemodes_choose_pre(game_mode_id, skipchecks)
{
	// Game mode allowed
	return PLUGIN_CONTINUE;
}

public zp_fw_gamemodes_choose_post(game_mode_id, target_player)
{
	// Pick player randomly?
	g_TargetPlayer = (target_player == RANDOM_TARGET_PLAYER) ? GetRandomAlive(random_num(1, GetAliveCount())) : target_player
}
public MakeNemesis()
{
	if(Active){
		new const Mode_nemesis[] = "Nemesis Mode" 
		new Mode_nemesis_id = zp_gamemodes_get_id(Mode_nemesis)
		zp_gamemodes_start(Mode_nemesis_id)
	}
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

// Get Random Alive -returns index of alive player number target_index -
GetRandomAlive(target_index)
{
	new iAlive, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id))
			iAlive++
		
		if (iAlive == target_index)
			return id;
	}
	
	return -1;
}

public Losuj_Zywego()
{
/*	new Players[32], Num, new_id, wylosowany;
	get_players(Players, Num, "a");
	
	if(Num)
	{
		wylosowany = random_num(1, Num)
		new_id = Players[wylosowany]
		client_print(0, print_chat, "Wylosowane ID: %i", new_id);
		return new_id
	}
	else
	{	
		client_print(0, print_chat, "DUPA !!!");
		return -1
	}*/

	new new_id, wylosowany, next = 0
	new tablica_zywych[34];
	for(new id = 1; id <= g_MaxPlayers; id++)
	{
		if(is_user_alive(id))
		{
			tablica_zywych[next] = id
			client_print(0, print_chat, "Zapisano id nr: %i do %i elementu tablicy", id, next);
			next++
		}
	}
	
//	do
//	{
		wylosowany = random_num(0, next)
		new_id = tablica_zywych[wylosowany]
		client_print(0, print_chat, "Wylosowany: %i, Wylosowane ID: %i", wylosowany, new_id);
//	}
//	while (new_id <= 0)
	
	return new_id
}

public native_rozgrzewka_on()
{
	return Active;
}

public native_moze_wybrac_bron_rozg(id)
{
	if(moze_wybrac_bron_rozg[id])
		MenuBroniRozgrzewka(id);
		
	return PLUGIN_CONTINUE;
}

PlaySoundToClients(const sound[], stop_sounds_first = 0)
{
	if (stop_sounds_first)
	{
		if (equal(sound[strlen(sound)-4], ".mp3"))
			client_cmd(0, "stopsound; mp3 play ^"sound/%s^"", sound)
		else
			client_cmd(0, "mp3 stop; stopsound; spk ^"%s^"", sound)
	}
	else
	{
		if (equal(sound[strlen(sound)-4], ".mp3"))
			client_cmd(0, "mp3 play ^"sound/%s^"", sound)
		else
			client_cmd(0, "spk ^"%s^"", sound)
	}
}

public info_snajper()
{
	client_print(0, print_chat, "Serwern stworzony przez CSnajper'a - CSnajper.eu");
	
	new num = random_num(60,600);
	set_task(float(num), "info_snajper");
}

//menu broni na rozgrzewce
public MenuBroniRozgrzewka(id){
	if(zp_core_is_zombie(id))
		return PLUGIN_CONTINUE;
	
	new Bron=menu_create("Wybierz Bron - Rozgrzewka","Bron_Handle")
	
	menu_additem(Bron,"Famas + Deagle");//item=0
	menu_additem(Bron,"Galil + Deagle");//item=0
	menu_additem(Bron,"M4A1 + Deagle");//item=0
	menu_additem(Bron,"AK47 + Deagle");//item=1
	menu_additem(Bron,"SG552 + Deagle");//item=1
	menu_additem(Bron,"AUG + Deagle");//item=1
	menu_additem(Bron,"G3SG1 + Deagle");//item=1
	
	menu_display(id, Bron,0);
	return PLUGIN_HANDLED;
}
public Bron_Handle(id, menu, item){

	if(zp_core_is_zombie(id) || !Active)
		return PLUGIN_CONTINUE;
	
	switch(item){
	case 0:{
			give_item(id, "weapon_famas");
			
			moze_wybrac_bron_rozg[id] = 0
		}
	case 1:{
			give_item(id, "weapon_galil");
			
			moze_wybrac_bron_rozg[id] = 0
		}
	case 2:{
			give_item(id, "weapon_m4a1");
			
			moze_wybrac_bron_rozg[id] = 0
		}
	case 3:{
			give_item(id, "weapon_ak47")
			
			moze_wybrac_bron_rozg[id] = 0
//			give_item(id,"ammo_762nato")
//			give_item(id,"ammo_762nato")
//			give_item(id,"ammo_762nato")
		}
	case 4:{
			give_item(id, "weapon_sg552");
			
			moze_wybrac_bron_rozg[id] = 0
			
		}		
	case 5:{
			give_item(id, "weapon_aug")
			
			moze_wybrac_bron_rozg[id] = 0
		}	
	case 6:{
			give_item(id, "weapon_g3sg1")
			
			moze_wybrac_bron_rozg[id] = 0
//			give_item(id,"ammo_762nato")
//			give_item(id,"ammo_762nato")
//			give_item(id,"ammo_762nato")		
		}
	}
	give_item(id, "weapon_deagle")
	give_item(id, "weapon_hegrenade");
	give_item(id, "weapon_flashbang");
	give_item(id, "weapon_smokegrenade");
	new weapons[32];
	new weaponsnum;
	get_user_weapons(id, weapons, weaponsnum);
	for(new i=0; i<weaponsnum; i++)
	if(is_user_alive(id))
		if(maxAmmo[weapons[i]] > 0)
			cs_set_user_bpammo(id, weapons[i], maxAmmo[weapons[i]]);
	
	menu_destroy(menu);
	
	if(zp_class_human_get_next(id) == ZP_INVALID_HUMAN_CLASS)
	{
		zp_class_human_show_menu(id)
	}
	else nat_menu_questow(id)
	
	return PLUGIN_HANDLED;
}

public fwd_PlayerSpawn(id)
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE;
	
	if(!zp_core_is_zombie(id))
		moze_wybrac_bron_rozg[id] = 1
		
	return PLUGIN_CONTINUE;
}
