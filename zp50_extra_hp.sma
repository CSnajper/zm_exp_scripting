#include <amxmodx>
#include <fun>
#include <zp50_items>
#include <zp50_core>
#include <zp50_class_nemesis>
#include <zp50_class_assassin>

// Oryginalna wersja: T[h]E Dis[as]teR
// Spolszczenie oraz poprawki: Zryty

new item_name[10]
new g_itemid_buyhp
new hpamount, hpcost
new bool:kupil_hp[33]

public plugin_init()
{
		register_plugin("[ZP] Kupno HP", "1.0", "Zryty")

		hpamount = register_cvar("zp_buyhp_amount", "1000") // Ilosc HP
		hpcost = register_cvar("zp_buyhp_cost", "5") // Koszt AP

		formatex(item_name, 39, "%d HP",get_pcvar_num(hpamount))
//		zp_register_extra_item(item_name, get_pcvar_num(hpcost), ZP_TEAM_ZOMBIE)
		g_itemid_buyhp = zp_items_register(item_name, get_pcvar_num(hpcost))
}

public zp_fw_items_select_pre(id, itemid) {
	
	if (itemid == g_itemid_buyhp) {
		if (!zp_core_is_zombie(id) || zp_class_nemesis_get(id) || zp_class_assassin_get(id))
			return ZP_ITEM_DONT_SHOW;
		if(kupil_hp[id])
		{
			return ZP_ITEM_NOT_AVAILABLE;
		}
		return ZP_ITEM_AVAILABLE;
	}
	return ZP_ITEM_AVAILABLE;
}

public zp_fw_items_select_post(id, itemid, ignorecost) {
	
	if(itemid == g_itemid_buyhp)
	{
		kupil_hp[id] = true
		set_user_health(id, get_user_health(id) + get_pcvar_num(hpamount))

		//Nie widzê potrzeby informowania o zakupie, ale nie usuwam, wystarczy odkomentowaæ
		//client_print(id, print_chat,"[ZP] Kupiles dodatkowe HP!");
	}
}

public zp_user_infected_pre(id, infector)
    	kupil_hp[id] = false