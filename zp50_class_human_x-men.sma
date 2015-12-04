#include <amxmodx>
#include <zp50_class_human>

// Classic Human Attributes
new const humanclass1_name[] = "X-MEN"
new const humanclass1_info[] = "=VIP Only="
new const humanclass1_models[][] = { "csfifkaczlo" }
const humanclass1_health = 300
const Float:humanclass1_speed = 1.15
const Float:humanclass1_gravity = 0.8
const humanclass1_armor = 65

new g_HumanClassID

public plugin_precache()
{
	register_plugin("[ZP] Class: Human: Classic", ZP_VERSION_STRING, "ZP Dev Team")
	
	g_HumanClassID = zp_class_human_register(humanclass1_name, humanclass1_info, humanclass1_health, humanclass1_speed, humanclass1_gravity, humanclass1_armor)
	new index
	for (index = 0; index < sizeof humanclass1_models; index++)
		zp_class_human_register_model(g_HumanClassID, humanclass1_models[index])
}

public zp_fw_class_human_select_pre(id, classid)
{
 	if(!(get_user_flags(id) & ADMIN_LEVEL_H) && classid == g_HumanClassID)
	{
		return ZP_CLASS_NOT_AVAILABLE;
	}
	return ZP_CLASS_AVAILABLE;
}

/*public zp_fw_core_spawn_post(id)
{
	if (zp_class_human_get_current(id) == g_HumanClassID)
	{
		if(!(get_user_flags(id) & ADMIN_LEVEL_H)){
			zp_colored_print(id, "You are using^x04Armorer hclass^x01, you now have^x04%s^x01 armor.", get_pcvar_num(cvar_armor))
		
		}
	}
}*/