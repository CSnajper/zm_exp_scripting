/*
Multijump addon by twistedeuphoria
Plagued by Dabbi
Classed by B!gBud

CVARS:
	zp_tight_jump 2 (Default)

*/

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <zp50_class_zombie>
#include <zp50_class_nemesis>
#include <zp50_class_assassin>

new jumpznum[33] = 0
new bool:dozjump[33] = false
new cvar_jumps
new g_zclass_tight

// Tight Zombie Atributes
new const zombieclass5_name[] = "Tight"
new const zombieclass5_info[] = "HP- Jump+"
new const zombieclass5_models[][] = { "zombie_source" }
new const zombieclass5_clawmodels[][] = { "models/zombie_plague/v_knife_zombie.mdl" }
const zombieclass5_health = 1400
const Float:zombieclass5_speed = 1.05
const Float:zombieclass5_gravity = 1.2
const Float:zombieclass5_knockback = 1.0

public plugin_init()
{
	cvar_jumps = register_cvar("zp_tight_jump","2")	
}

public plugin_precache()
{
	register_plugin("[ZP] Class: Zombie: Tight", ZP_VERSION_STRING, "Sniper Elite")
	new index
	
	g_zclass_tight = zp_class_zombie_register(zombieclass5_name, zombieclass5_info, zombieclass5_health, zombieclass5_speed, zombieclass5_gravity)
	zp_class_zombie_register_kb(g_zclass_tight, zombieclass5_knockback)
	for (index = 0; index < sizeof zombieclass5_models; index++)
		zp_class_zombie_register_model(g_zclass_tight, zombieclass5_models[index])
	for (index = 0; index < sizeof zombieclass5_clawmodels; index++)
		zp_class_zombie_register_claw(g_zclass_tight, zombieclass5_clawmodels[index])
}

public client_putinserver(id)
{
	jumpznum[id] = 0
	dozjump[id] = false
}

public client_disconnect(id)
{
	jumpznum[id] = 0
	dozjump[id] = false
}

public client_PreThink(id)
{
	if(!is_user_alive(id)) return PLUGIN_CONTINUE
	if(!zp_core_is_zombie(id) || zp_class_zombie_get_current(id) != g_zclass_tight || zp_class_nemesis_get(id) || zp_class_assassin_get(id)) return PLUGIN_CONTINUE
	
	new nzbut = get_user_button(id)
	new ozbut = get_user_oldbutton(id)
	if((nzbut & IN_JUMP) && !(get_entity_flags(id) & FL_ONGROUND) && !(ozbut & IN_JUMP))
	{
		if (jumpznum[id] < get_pcvar_num(cvar_jumps))
		{
			dozjump[id] = true
			jumpznum[id]++
			return PLUGIN_CONTINUE
		}
	}
	if((nzbut & IN_JUMP) && (get_entity_flags(id) & FL_ONGROUND))
	{
		jumpznum[id] = 0
		return PLUGIN_CONTINUE
	}	
	return PLUGIN_CONTINUE
}

public client_PostThink(id)
{
	if(!is_user_alive(id)) return PLUGIN_CONTINUE
	if(!zp_core_is_zombie(id) || zp_class_zombie_get_current(id) != g_zclass_tight) return PLUGIN_CONTINUE
	
	if(dozjump[id] == true)
	{
		new Float:vezlocityz[3]	
		entity_get_vector(id,EV_VEC_velocity,vezlocityz)
		vezlocityz[2] = random_float(265.0,285.0)
		entity_set_vector(id,EV_VEC_velocity,vezlocityz)
		dozjump[id] = false
		return PLUGIN_CONTINUE
	}	
	return PLUGIN_CONTINUE
}	
