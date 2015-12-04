/*================================================================================
	
	-------------------------------------------------
	-*- [ZP] Extra Item: Anti-Infection Armor 1.5 -*-
	-------------------------------------------------
	
	~~~~~~~~~~~~~~~
	- Description -
	~~~~~~~~~~~~~~~
	
	Humans can buy extra item that protects them
	from getting infected
	NEW : BUYABLE BY CONSOLE COMMAND :) (bind)
	
=================================================================================*/



/*================================================================================
 [Modules Required]
=================================================================================*/
#include <amxmodx>
#include <fakemeta>
#include <zombieplague>
#include <zp50_items>
#include <zp50_ammopacks>
#include <zp50_core>
#include <zp50_class_survivor>
#include <zp50_class_sniper>
/*===============================================================================*/



/*================================================================================
 [Plugin Settings]
 (default : cost=5, amount=50, max=100)
=================================================================================*/
//Name of extra item
new const g_item_name[] = { "Anti-Infection Armor" }
//Armor price
const g_item_cost = 5
//Sound played when buyed armor
new const g_sound_buyarmor[] = { "items/tr_kevlar.wav" }
//Amount of armor will you get when you buy it
const g_armor_amount = 100
//Maximum of armor that is possible to have
const g_armor_limit = 250
/*===============================================================================*/



new g_itemid_humanarmor

public plugin_precache()
{
	precache_sound(g_sound_buyarmor)
}

public plugin_init()
{
	register_plugin("[ZP] Extra: Anti-Infection Armor", "1.5", "Lama0")
	
	g_itemid_humanarmor = zp_items_register(g_item_name, g_item_cost)
	
	
	
/*================================================================================
 [Console command Settings] - what to bind (or type into console) to buy armor
 (default : "vest" and "vesthelm")
=================================================================================*/
	register_clcmd("vest","buy_armor");
	register_clcmd("vesthelm","buy_armor");
/*===============================================================================*/



}

public zp_fw_items_select_pre(id, itemid)
{
	if (itemid == g_itemid_humanarmor)
	{
		if (zp_core_is_zombie(id) || zp_class_survivor_get(id) || zp_class_sniper_get(id))
			return ZP_ITEM_DONT_SHOW;
	}
	return ZP_ITEM_AVAILABLE;
}

public zp_fw_items_select_post(id, itemid, ignorecost)
{
	if (itemid == g_itemid_humanarmor)
	{
		set_pev(id, pev_armorvalue, float(min(pev(id, pev_armorvalue)+g_armor_amount, g_armor_limit)))
		engfunc(EngFunc_EmitSound, id, CHAN_BODY, g_sound_buyarmor, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
	return PLUGIN_CONTINUE;
}

public buy_armor(player)
{
	if (!zp_core_is_zombie(player))
	{
		new packs = zp_ammopacks_get(player)
		new cost = g_item_cost
	
		if ( packs < cost )
		{
			client_print(player, print_chat, "[ZP] You need more ammo packs to buy armor.")
			return PLUGIN_CONTINUE
		}
		if ( get_user_armor(player) == g_armor_limit )
		{
			client_print(player, print_chat, "[ZP] You have full armor.")
			return PLUGIN_CONTINUE
		}
		zp_ammopacks_set(player, packs - cost)
		set_pev(player, pev_armorvalue, float(min(pev(player, pev_armorvalue)+g_armor_amount, g_armor_limit)))
		engfunc(EngFunc_EmitSound, player, CHAN_BODY, g_sound_buyarmor, 1.0, ATTN_NORM, 0, PITCH_NORM)
		return PLUGIN_CONTINUE
	}
	return PLUGIN_CONTINUE
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
