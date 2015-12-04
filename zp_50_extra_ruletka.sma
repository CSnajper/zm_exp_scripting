#include <amxmodx>
#include <fun>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <zp50_items>
#include <zp50_core>
#include <zp50_gamemodes>
#include <zp50_class_nemesis>
#include <zp50_class_assassin>
#include <zp50_class_survivor>
#include <zp50_class_sniper>
#include <zp50_ammopacks>

native get_user_xp(id)
native set_user_xp(id, amount)
native daj_bazooke(id)
native daj_miny(id, ile)
native daj_pipe(id)
native daj_bombe(id)
native daj_madness(id)

// Oryginalna wersja: T[h]E Dis[as]teR
// Spolszczenie oraz poprawki: Zryty

new g_itemid_ruletka
new SayText
new eliminator[33] = 0;
new Anti[33] = 0;
new Madness[33] = 0;

public plugin_init()
{
	register_plugin("[ZP] Ruletka dla ZP 5.0.8", "1.0", "Sniper Elite")
	
	g_itemid_ruletka = zp_items_register("Ruletka Mikolajkowa", 10)
	
	
	RegisterHam(Ham_Spawn, "player", "Odrodzenie", 1);
	register_forward(FM_CmdStart, "CmdStart");
	register_forward(FM_EmitSound, "EmitSound");
	
	register_clcmd("say /ruletka", "RuletkaCMD");
	register_clcmd("say ruletka", "RuletkaCMD");
	
//	register_concmd("zm_dajap", "cmd_dajap", ADMIN_IMMUNITY, "<name> <ap to add>"); 
	
	SayText = get_user_msgid("SayText")
}

public zp_fw_items_select_pre(id, itemid)
{
	if(itemid == g_itemid_ruletka)
	{
		if(zp_class_survivor_get(id) || zp_class_sniper_get(id) || zp_class_assassin_get(id) || zp_class_nemesis_get(id) /* || !(get_user_flags(id) & ADMIN_IMMUNITY)*/)
			return ZP_ITEM_DONT_SHOW;
		if(zp_gamemodes_get_current() != zp_gamemodes_get_id("Infection Mode") && zp_gamemodes_get_current() != zp_gamemodes_get_id("Multiple Infection Mode"))
			return ZP_ITEM_DONT_SHOW;
			
	}
	
	return ZP_ITEM_AVAILABLE;
}

public zp_fw_items_select_post(id, itemid, ignorecost)
{
	if(itemid == g_itemid_ruletka && zp_core_is_zombie(id))
	{
		ruletka_zombi(id)
	}
	else if(itemid == g_itemid_ruletka && !zp_core_is_zombie(id))
		ruletka_human(id)
	else
		log_to_file("debug.log", "Cos nie tak z pluginem ruletka");
		
	log_to_file("ruletka.log", "Zagrano w ruletke");
}

public ruletka_zombi(id)
{
	switch(random_num(1,100))
	{
		case 1..30:
		{
			client_printcolor(id, "!g[Ruletka] !yWylosowales:!t NIC!")
		}
		case 31..50:
		{
			new ilosc_ap = random_num(0,20)
			zp_ammopacks_set(id, zp_ammopacks_get(id) + ilosc_ap)
			client_printcolor(id, "!g[Ruletka] !yWylosowales:!t %i AP", ilosc_ap)
		}
		case 51..65:
		{
			new ilosc_expa = random_num(0,150)
			set_user_xp(id, get_user_xp(id) + ilosc_expa)
			client_printcolor(id, "!g[Ruletka] !yWylosowales:!t %i EXPA", ilosc_expa)
		}
		case 66..75:
		{
			new ile_hp = random_num(1,2)
			new ilosc_hp = ile_hp * 2000
			set_user_health(id, get_user_health(id) + ilosc_hp)
			client_printcolor(id, "!g[Ruletka] !yWylosowales:!t %i HP", ilosc_hp)
		}
		case 76..84:
		{
			if(Anti[id] || zp_core_is_first_zombie(id))
			{
				ruletka_zombi(id)
				return PLUGIN_HANDLED;
			}
			Anti[id] = 1;
			client_printcolor(id, "!g[Ruletka] !yWylosowales:!t ANTIDOTUM !y(wcisnij E aby uzyc)")
		}
		case 85..94:
		{
			if(Madness[id])
			{
				ruletka_zombi(id)
				return PLUGIN_HANDLED;
			}
			Madness[id] = 1;
			client_printcolor(id, "!g[Ruletka] !yWylosowales:!t ZOMBIE MADNESS !y(wcisnij E aby uzyc)")
		}
		case 95..100:
		{
			daj_bombe(id)
			client_printcolor(id, "!g[Ruletka] !yWylosowales:!t BOMBE INFEKCYJNA !y(wybierz GRANAT aby uzyc)")
		}
	}
	
	return PLUGIN_CONTINUE;
}

public ruletka_human(id)
{
	switch(random_num(1,100))
	{
		case 1..30:
		{
			client_printcolor(id, "!g[Ruletka] !yWylosowales:!t NIC!")
		}
		case 31..50:
		{
			new ilosc_ap = random_num(0,20)
			zp_ammopacks_set(id, zp_ammopacks_get(id) + ilosc_ap)
			client_printcolor(id, "!g[Ruletka] !yWylosowales:!t %i AP", ilosc_ap)
		}
		case 51..65:
		{
			new ilosc_expa = random_num(0,150)
			set_user_xp(id, get_user_xp(id) + ilosc_expa)
			client_printcolor(id, "!g[Ruletka] !yWylosowales:!t %i EXPA", ilosc_expa)
		}
		case 66..72:
		{
			daj_bazooke(id)
			client_printcolor(id, "!g[Ruletka] !yWylosowales:!t BAZOOKE !y(wybierz noz aby uzyc)")
		}
		case 73..79:
		{
			new ile_min = random_num(2,5)
			daj_miny(id, ile_min)
			client_printcolor(id, "!g[Ruletka] !yWylosowales:!t %i MIN !y(stawianie na C - wpisz w konsole bind c +mina)", ile_min)
		}
		case 80..86:
		{
			set_user_armor(id, get_user_armor(id) + 150)
			client_printcolor(id, "!g[Ruletka] !yWylosowales:!t 150 PANCERZA")
		}
		case 87..93:
		{
			daj_pipe(id)
			client_printcolor(id, "!g[Ruletka] !yWylosowales:!t PIPE BOMBE !y(wybierz SMOKE aby uzyc)")
		}
		case 94..100:
		{
			switch(random_num(1,2))
			{
				case 1:
				{
					if(eliminator[id])
					{
						ruletka_human(id)
						return PLUGIN_HANDLED;
					}
					eliminator[id] = 2
					client_printcolor(id, "!g[Ruletka] !yWylosowales:!t OGRANICZNIK ROZRZUTU !y(do konca rundy)")
				}
				case 2:
				{
					if(eliminator[id] == 1)
					{
						ruletka_human(id)
						return PLUGIN_HANDLED;
					}
					eliminator[id] = 1
					client_printcolor(id, "!g[Ruletka] !yWylosowales:!t ELIMINATOR ROZRZUTU !y(do konca rundy)")
				}
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}

public RuletkaCMD(id)
{
/*	if(!(get_user_flags(id) & ADMIN_IMMUNITY))
	{
		client_print(id, print_chat, "Nie jestes upowazniony do korzystania z ruletki (Beta Testy)")
		return PLUGIN_HANDLED;
	}*/
	if(!is_user_alive(id))
	{
		client_printcolor(id, "!g[Ruletka] !yMartwi !gNIE !ymoga korzystac z !gRuletki")
		return PLUGIN_HANDLED;
	}
	new ruletka=menu_create("Menu Ruletki","Ruletka_Handle");
	
	if(zp_ammopacks_get(id) >= 10 && !zp_class_survivor_get(id) && !zp_class_sniper_get(id) && !zp_class_assassin_get(id) && !zp_class_nemesis_get(id))
		menu_additem(ruletka,"Zakrec Ruletka \r10 AP");//item=0
	else
		menu_additem(ruletka,"\dZakrec Ruletka \r10 AP");//item=0
	menu_additem(ruletka,"Zobacz co mozesz wygrac!");//item=1
	
	menu_display(id, ruletka,0);
	return PLUGIN_HANDLED;
}
public Ruletka_Handle(id, menu, item){
	switch(item)
	{
		case 0:
		{
			if(zp_ammopacks_get(id) >= 10 && !zp_class_survivor_get(id) && !zp_class_sniper_get(id) && !zp_class_assassin_get(id) && !zp_class_nemesis_get(id))
			{
				zp_ammopacks_set(id, zp_ammopacks_get(id) - 10)
				if(zp_core_is_zombie(id))
					ruletka_zombi(id)
				else
					ruletka_human(id)
			}
			RuletkaCMD(id)
		}
		case 1:
		{
			new opis[1501], iLen=0, iMax=sizeof(opis) - 1;
			iLen += formatex(opis[iLen], iMax-iLen, "Bonusy jakie mozesz zyskac grajac w ruletke:<br>");
			iLen += formatex(opis[iLen], iMax-iLen, "30%% Pudlo - nic nie dostajesz.<br>");
			iLen += formatex(opis[iLen], iMax-iLen, "15%% EXP.<br>");
			iLen += formatex(opis[iLen], iMax-iLen, "20%% Losowanie AP - mozna na tym stracic lub sie wzbogacic o dodatkowe AP.<br>");
			iLen += formatex(opis[iLen], iMax-iLen, "Extra Itemy (5-10%% na kazdy item):<br>");
			iLen += formatex(opis[iLen], iMax-iLen, "Zombie:<br>");
			iLen += formatex(opis[iLen], iMax-iLen, "- od 2000 do 4000 HP, Antidotum, Zombie Madness, Bomba Infekcyjna.<br>");
			iLen += formatex(opis[iLen], iMax-iLen, "Ludzie:<br>");
			iLen += formatex(opis[iLen], iMax-iLen, "- Miny (od 2 do 5), PipeBombe, 150 Pancerza, Bazooka, Ogranicznik lub Eliminator rozrzutu na jedna runde.<br><br>");
			iLen += formatex(opis[iLen], iMax-iLen, "Jak widac gra jest ryzykowna. Mozna sporo zyskac za niewielka liczbe AP lub tez stracic je nie zyskujac nic w zamian<br>");
			iLen += formatex(opis[iLen], iMax-iLen, "Wszelkie propozycje co do nowych nagrod do wylosowania zglaszajcie na CsFifka.pl -> Dzial ZM EXP<br>");
			
			showpomoc(id,"Bonusy z posiadania goldow",opis)
			
			RuletkaCMD(id)
		}
	}
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public Odrodzenie(id)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return PLUGIN_CONTINUE;
	
	eliminator[id] = 0;
	Anti[id] = 0;
	Madness[id] = 0;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_core_cure_post(id, attacker)
{
	Anti[id] = 0;
	Madness[id] = 0;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_core_infect_post(id, attacker)
{
	Anti[id] = 0;
	Madness[id] = 0;
	
	return PLUGIN_CONTINUE;
}

public CmdStart(id, uc_handle)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED;
	
	if(get_user_button(id) & IN_ATTACK)
	{
		item_rozrzut(id)
	}
	
	return FMRES_IGNORED;
}
		
public item_rozrzut(id)
{
	new Float:punchangle[3];
	if(eliminator[id] == 1)
		entity_set_vector(id, EV_VEC_punchangle, punchangle);
	else if(eliminator[id] == 2)
	{
		entity_get_vector(id, EV_VEC_punchangle, punchangle);
		for(new i=0; i<3;i++) 
		punchangle[i]*=0.9;
		entity_set_vector(id, EV_VEC_punchangle, punchangle);
		return PLUGIN_CONTINUE;
	}
	
	return PLUGIN_CONTINUE;
}

public EmitSound(id, iChannel, sound[], Float:fVol, Float:fAttn, iFlags, iPitch ) 
{
	if(equal(sound, "common/wpn_denyselect.wav"))
	{
		UzyjItemu(id);
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public UzyjItemu(id)
{
/*	if(!(get_user_flags(id) & ADMIN_IMMUNITY))
	{
		client_print(id, print_chat, "Nie jestes upowazniony do korzystania z ruletki (Beta Testy)")
		return PLUGIN_HANDLED;
	}*/
	if(!is_user_alive(id) || !zp_core_is_zombie(id))
	{
		return PLUGIN_HANDLED;
	}
	if(!Anti[id] && !Madness[id])
	{
		return PLUGIN_HANDLED;
	}
	new uzyj=menu_create("Menu Ruletki","UzyjItemu_Handle");
	
	if(Anti[id])
		menu_additem(uzyj,"Uzyj Antidotum");//item=0
	else
		menu_additem(uzyj,"\dUzyj Antidotum");//item=0
	if(Madness[id])
		menu_additem(uzyj,"Uzyj Zombie Madness");//item=0
	else
		menu_additem(uzyj,"\dUzyj Zombie Madness");//item=0
	
	menu_display(id, uzyj,0);
	return PLUGIN_HANDLED;
}

public UzyjItemu_Handle(id, menu, item)
{
	if(!is_user_alive(id) || !zp_core_is_zombie(id))
	{
		return PLUGIN_HANDLED;
	}
	
	switch(item)
	{
		case 0:
		{
			if(Anti[id])
			{
				Anti[id] = 0;
				zp_core_cure(id, 0)
			}
		}
		case 1:
		{
			if(Madness[id])
			{
				daj_madness(id)
				Madness[id] = 0;
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}

stock client_printcolor(const id, const input[], any:...)
{
	new count = 1, players[32]
	static msg[191]
	vformat(msg, 190, input, 3)
	
	replace_all(msg, 190, "!g", "^4") // Green Color
	replace_all(msg, 190, "!y", "^1") // Default Color
	replace_all(msg, 190, "!t", "^3") // Team Color
	
	if (id) players[0] = id; else get_players(players, count, "ch") 
	{
		for ( new i = 0; i < count; i++ )
		{
			if ( is_user_connected(players[i]) )
			{
				message_begin(MSG_ONE_UNRELIABLE, SayText, _, players[i])
				write_byte(players[i]);
				write_string(msg);
				message_end();
			}
		}
	}
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
		format(errormsg,511,"Blad: Folder %s/diablo nie mogł być znaleziony. Prosze skopiowac ten folder z archiwum do folderu amxmodx",amxbasedir)
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

public cmd_dajap(id, level, cid)
{
	if(!cmd_access(id, level, cid, 3))
	return PLUGIN_HANDLED;
	new arg1[33];
	new arg2[10];
	read_argv(1,arg1,32);
	read_argv(2,arg2,9);
	new player = cmd_target(id, arg1, 0);
	remove_quotes(arg2);
	new ap = str_to_num(arg2);
	zp_ammopacks_set(player, zp_ammopacks_get(player) + ap);
	return PLUGIN_HANDLED;
}

