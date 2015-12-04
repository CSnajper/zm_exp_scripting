/*================================================================================
	
	-------------------------------------------------
	-*- [ZP] Extra Item: Anti-Infection Armor 1.0 -*-
	-------------------------------------------------
	
	~~~~~~~~~~~~~~~
	- Description -
	~~~~~~~~~~~~~~~
	
	This item gives humans some armor that offers protection
	against zombie injuries.
	
================================================================================*/

#include <amxmodx>
#include <fakemeta>
#include <fun>
#include <zp50_core>
//#include <zombieplague>
#include <engine>
#include <hamsandwich>
#include <zp50_class_survivor>
#include <zp50_items>
#include <zp50_class_nemesis>
#include <zp50_gamemodes>
#include <zp50_class_survivor>
#include <zp50_class_sniper>

/*================================================================================
 [Plugin Customization]
=================================================================================*/

#define MINE_COST 5 // koszt min

native sprawdz_misje(id)
native dodaj_ile_juz(id, ile)
native get_user_xp(id)
native set_user_xp(id, amount)

/*============================================================================*/

// Item IDs
new g_itemid_miny2
new miny[33] = 0
new cvar_minedamage
new sprite_blast
new gmsgDeathMsg
new gmsgScoreInfo
new g_pointer_exp

public plugin_precache()
{
	precache_model("models/mine.mdl");
	sprite_blast = precache_model("sprites/dexplo.spr");
}

public plugin_init()
{
	register_plugin("[ZP] Extra: Mines", "1.0", "Sniper Elite");
	
	cvar_minedamage = register_cvar("zp_mine_damage", "500");
	
	gmsgDeathMsg = get_user_msgid("DeathMsg")
	gmsgScoreInfo = get_user_msgid("ScoreInfo")
	
//	g_itemid_miny2 = zp_register_extra_item(g_item_name, MINE_COST, ZP_TEAM_HUMAN);
	g_itemid_miny2 = zp_items_register("3 Miny", MINE_COST)
	register_touch("Mine", "player",  "DotykMiny");
	register_event("HLTV", "NowaRunda", "a", "1=0", "2=0");
	register_clcmd("+mina", "PostawMine");
//	set_task(30.0, "info_snajper");
}

public plugin_natives()
{
					// Player natives //
	register_native("daj_miny", "native_daj_miny", 1);
}

public native_daj_miny(id, ile)
{
	miny[id] += ile
	client_cmd(id, "bind ^"c^" ^"+mina^"")
}

/*// Human buys our upgrade, give him some armor
public zp_extra_item_selected(player, itemid)
{
	if (itemid == g_itemid_miny2)
	{
		miny[player] += 3
		client_cmd(player, "bind c +mina")
		client_print(player, print_chat, "Masz %i miny, ktore zadaja %i obrazen kazda. Uzycie klawisz C lub 'bind klawisz +mina'", miny[player], get_pcvar_num(cvar_minedamage));
//		client_print(player, print_chat, "Mozesz sam zbindowac miny. Komenda: bind klawisz +mina");
	}
}*/

public zp_fw_items_select_pre(id, itemid) {
	
	if (itemid == g_itemid_miny2) {
		if (zp_core_is_zombie(id) || zp_class_sniper_get(id) || zp_class_survivor_get(id))
			return ZP_ITEM_DONT_SHOW;
			
		if(zp_gamemodes_get_current() == ZP_NO_GAME_MODE || zp_gamemodes_get_current() == zp_gamemodes_get_id("Assassin Mode"))
			return ZP_ITEM_NOT_AVAILABLE;
		
		return ZP_ITEM_AVAILABLE;
	}
	return ZP_ITEM_AVAILABLE;
}

public zp_fw_items_select_post(id, itemid, ignorecost) {

	if (itemid != g_itemid_miny2 || zp_core_is_zombie(id) || zp_class_sniper_get(id) || zp_class_survivor_get(id))
		return;
		
	if (itemid == g_itemid_miny2)
	{
		miny[id] += 3
		client_cmd(id, "bind c +mina")
		client_print(id, print_center, "Masz %i miny, ktore zadaja %i obrazen kazda. Uzycie klawisz C lub 'bind klawisz +mina'", miny[id], get_pcvar_num(cvar_minedamage));
//		client_print(player, print_chat, "Mozesz sam zbindowac miny. Komenda: bind klawisz +mina");
	}
}  

public DotykMiny(ent, id)
{
	new attacker = entity_get_edict(ent, EV_ENT_owner);
	if (zp_core_is_zombie(id) && id != attacker)
	{
		new Float:fOrigin[3], iOrigin[3];
		entity_get_vector( ent, EV_VEC_origin, fOrigin);
		iOrigin[0] = floatround(fOrigin[0]);
		iOrigin[1] = floatround(fOrigin[1]);
		iOrigin[2] = floatround(fOrigin[2]);
		
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY, iOrigin);
		write_byte(TE_EXPLOSION);
		write_coord(iOrigin[0]);
		write_coord(iOrigin[1]);
		write_coord(iOrigin[2]);
		write_short(sprite_blast);
		write_byte(32); // scale
		write_byte(20); // framerate
		write_byte(0);// flags
		message_end();
		new entlist[33];
		new numfound = find_sphere_class(ent,"player", 40.0 ,entlist, 32);
		
		for (new i=0; i < numfound; i++)
		{		
			new pid = entlist[i];
			
			if (!is_user_alive(pid) || !zp_core_is_zombie(pid) || id == attacker)
				continue;
				
//			new Float:dam = get_pcvar_float(cvar_minedamage)
//			ExecuteHam(Ham_TakeDamage, pid, ent, attacker, dam , 1);
			
			new dam = get_pcvar_num(cvar_minedamage)
		
			change_health(pid,-dam,attacker,"")
			
			if(is_user_connected(pid) && is_user_connected(attacker) && !is_user_alive(pid)){
				if(sprawdz_misje(attacker) == 38)
				{
					dodaj_ile_juz(attacker, 1)
				}
			}
		}
		remove_entity(ent);
	}
}

public PostawMine(id)
{
	if (!miny[id])
	{
		return PLUGIN_CONTINUE;
	}
	
	if (!is_user_alive(id) || zp_core_is_zombie(id) || zp_class_nemesis_get(id) || zp_class_survivor_get(id))
		return PLUGIN_CONTINUE;
	
	miny[id]--;
	client_print(id, print_center, "Pozostala ilosc min: %i", miny[id]);
	
	new Float:origin[3];
	entity_get_vector(id, EV_VEC_origin, origin);
		
	new ent = create_entity("info_target");
	entity_set_string(ent ,EV_SZ_classname, "Mine");
	entity_set_edict(ent ,EV_ENT_owner, id);
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_TOSS);
	entity_set_origin(ent, origin);
	entity_set_int(ent, EV_INT_solid, SOLID_TRIGGER);
	
	entity_set_model(ent, "models/mine.mdl");
	entity_set_size(ent,Float:{-16.0,-16.0,0.0},Float:{16.0,16.0,2.0});
	
	drop_to_floor(ent);

	entity_set_float(ent,EV_FL_nextthink,halflife_time() + 0.01) ;
	
	set_rendering(ent,kRenderFxNone, 0,0,0, kRenderTransTexture,65)	;
	
	
	return PLUGIN_CONTINUE;
}

public NowaRunda()
{
	new iEnt = find_ent_by_class(-1, "Mine");
	while(iEnt > 0) 
	{
		remove_entity(iEnt);
		iEnt = find_ent_by_class(iEnt, "Mine");	
	}
}

public zp_user_infected_post(id)
{
	miny[id] = 0;
}

public info_snajper()
{
	client_print(0, print_chat, "Zapraszamy na forum CsFifka.pl");
	
//	new num = random_num(60,600);
//	set_task(float(num), "info_snajper");
}

//£atwiejsza zmiana HP gracza
public change_health(id,hp,attacker,weapon[])
{
	if(is_user_alive(id) && is_user_connected(id))
	{
		if(hp>0)
		{
			set_user_health(id,get_user_health(id)+hp)
		}
		else
		{
			if(get_user_health(id)+hp<1)
			{
				UTIL_Kill(attacker,id,weapon)
			}
			else set_user_health(id,get_user_health(id)+hp)
		}
	}
}
public UTIL_Kill(attacker,id,weapon[])
{
	if( is_user_alive(id)){
		new bPlayerAttack = is_user_connected(attacker);
		
		if(get_user_team(attacker)!=get_user_team(id) && bPlayerAttack)
			set_user_frags(attacker,get_user_frags(attacker) +1);
		
		if(get_user_team(attacker)==get_user_team(id))
			set_user_frags(attacker,get_user_frags(attacker) -1);
		
//		cs_set_user_deaths(id, cs_get_user_deaths(id)+1)
		user_silentkill(id)
		
		if(bPlayerAttack && attacker!=id)
		{
			award_kill(attacker)
//			if(is_user_alive(attacker)) award_item(attacker,0)
		}
		
		message_begin( MSG_ALL, gmsgDeathMsg,{0,0,0},0)
		write_byte(attacker) 
		write_byte(id) 
		write_byte(0) 
		write_string(weapon) 
		message_end() 
		
		if(bPlayerAttack){
			message_begin(MSG_ALL,gmsgScoreInfo) 
			write_byte(attacker) 
			write_short(get_user_frags(attacker)) 
			write_short(get_user_deaths(attacker)) 
			write_short(0) 
			write_short(get_user_team(attacker)) 
			message_end() 
		}
		
		message_begin(MSG_ALL,gmsgScoreInfo) 
		write_byte(id) 
		write_short(get_user_frags(id)) 
		write_short(get_user_deaths(id)) 
		write_short(0) 
		write_short(get_user_team(id)) 
		message_end()
		
	}
}

public award_kill(attacker)
{
	new g_exp;
	g_pointer_exp = get_cvar_pointer( "gxm_xp" );
	g_exp = get_pcvar_num(g_pointer_exp)
	
	set_user_xp(attacker, get_user_xp(attacker) + g_exp)
}	