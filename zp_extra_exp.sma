#include <amxmodx>
#include <colorchat>
#include <zp50_core>
#include <zp50_items>

native set_user_xp(id, exp)
native get_user_xp(id)

new const g_item_name[] = { "Dodatkowy Exp" }
new const g_item_cost = 20

new g_pointer

/*============================================================================*/

// Item IDs
new g_itemid_exp
new cvar_iloscexpa

public plugin_init()
{
	register_plugin("[ZP] Extra: Experience", "1.0", "Sniper Elite");
	
	cvar_iloscexpa = register_cvar("zp_ilosc_expa_sklep", "100");
	g_itemid_exp = zp_items_register(g_item_name, g_item_cost);
	
	set_task(240.0, "info_snajper");
}

public zp_fw_items_select_pre(id, itemid) {
	
	if (itemid == g_itemid_exp) {
	
		new ilosc_graczy = get_playersnum()
		
		g_pointer = get_cvar_pointer( "min_liczba_graczy" );
		new min_graczy = get_pcvar_num(g_pointer)
		
		if(ilosc_graczy < min_graczy)
		{
			return ZP_ITEM_NOT_AVAILABLE;
		}
		
		return ZP_ITEM_AVAILABLE;
	}
	return ZP_ITEM_AVAILABLE;
}

public zp_fw_items_select_post(id, itemid, ignorecost)
{
	if (itemid != g_itemid_exp)
		return;
	
	new xp = get_user_xp(id) + get_pcvar_num(cvar_iloscexpa)
	set_user_xp(id, xp)
	ColorChat(id, GREEN, "[ZM EXP]^x01 Kupiles dodatkowy EXP!");
	
	new name[32]
	get_user_name(id, name, 31);
	log_to_file("sql.log", "%s Kupil dodatkowy exp", name);
}

public info_snajper()
{
	client_print(0, print_chat, "Zapraszamy na forum CsFifka.pl");
	new num = random_num(60,600);
	set_task(float(num), "info_snajper");
}