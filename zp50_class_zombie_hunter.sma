/*================================================================================
	
	---------------------------------
	-*- [ZP] Class: Zombie: Leech -*-
	---------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fun>
#include <hamsandwich>
#include <fakemeta>
#include <fakemeta_util>
#include <amx_settings_api>
#include <cs_ham_bots_api>
#include <zp50_class_zombie>
#include <zp50_class_nemesis>
#include <engine>
#include <colorchat>

// Leech Zombie Attributes
new const zombieclass5_name[] = "Hunter"
new const zombieclass5_info[] = "HP- Knockback+ Leech++"
new const zombieclass5_models[][] = { "zombie_source" }
new const zombieclass5_clawmodels[][] = { "models/zombie_plague/v_knife_zombie.mdl" }
const zombieclass5_health = 1300
const Float:zombieclass5_speed = 0.75
const Float:zombieclass5_gravity = 1.0
const Float:zombieclass5_knockback = 1.25


//longjump
new g_lastleaptime[33] // time leap was last used

new dzwieki_hunter[] = {"hunter/l4d_hunter_jump.wav", "hunter/l4d_hunter_jump3.wav", "hunter/l4d_hunter_jump4.wav"}

new cvar_leaphuntercooldown, cvar_leaphunterheight
new cvar_leaphunterforce

new g_ZombieClassID

public plugin_precache()
{
	register_plugin("[ZP] Class: Zombie: Leech", ZP_VERSION_STRING, "ZP Dev Team")
	
	cvar_leaphuntercooldown = register_cvar("zp_leap_hunter_cooldown", "8")
	cvar_leaphunterforce = register_cvar("zp_leap_hunter_force", "500")
	cvar_leaphunterheight = register_cvar("zp_leap_hunter_height", "300")
	
	new index
	
	g_ZombieClassID = zp_class_zombie_register(zombieclass5_name, zombieclass5_info, zombieclass5_health, zombieclass5_speed, zombieclass5_gravity)
	zp_class_zombie_register_kb(g_ZombieClassID, zombieclass5_knockback)
	for (index = 0; index < sizeof zombieclass5_models; index++)
		zp_class_zombie_register_model(g_ZombieClassID, zombieclass5_models[index])
	for (index = 0; index < sizeof zombieclass5_clawmodels; index++)
		zp_class_zombie_register_claw(g_ZombieClassID, zombieclass5_clawmodels[index])
		
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	
	precache_sound("hunter/l4d_hunter_jump.wav");
	precache_sound("hunter/l4d_hunter_jump3.wav");
	precache_sound("hunter/l4d_hunter_jump4.wav");

}

// Forward Player PreThink
public fw_PlayerPreThink(id)
{
	if (!zp_core_is_zombie(id) || zp_class_zombie_get_current(id) != g_ZombieClassID || !is_user_alive(id) || zp_class_nemesis_get(id))
		return;
	
	// Not doing a longjump (don't perform check for bots, they leap automatically)
	if (!(pev(id, pev_button) & (IN_JUMP | IN_DUCK) == (IN_JUMP | IN_DUCK)))
		return;
	
	new cooldown
	cooldown = get_pcvar_num(cvar_leaphuntercooldown)
		
	new xd = floatround(halflife_time()-g_lastleaptime[id])
	new czas = cooldown-xd
	if(halflife_time()-g_lastleaptime[id] <= cooldown)
	{
		return;
	}
	
	// Not on ground or not enough speed
	if (!(pev(id, pev_flags) & FL_ONGROUND) || fm_get_speed(id) < 80)
		return;
		
	static Float:velocity[3]
	velocity_by_aim(id, get_pcvar_num(cvar_leaphunterforce), velocity)
	velocity[2] = get_pcvar_float(cvar_leaphunterheight)
	new los = random_num(0,2)
//	emit_sound(id, CHAN_BODY, "dzwieki_hunter[los]", 1.0, ATTN_NORM, 0, PITCH_NORM);
	switch(los)
	{
		case 0:
		{
			emit_sound(id, CHAN_AUTO, "hunter/l4d_hunter_jump.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		}
		case 1:
		{
			emit_sound(id, CHAN_AUTO, "hunter/l4d_hunter_jump3.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		}
		case 2:
		{
			emit_sound(id, CHAN_AUTO, "hunter/l4d_hunter_jump4.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		}
	}
//	emit_sound(id, CHAN_AUTO, dzwieki_hunter[los], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	// Apply the new velocity
	set_pev(id, pev_velocity, velocity)
	
	// Update last leap time
	g_lastleaptime[id] = floatround(halflife_time())
	set_task(get_pcvar_float(cvar_leaphuntercooldown), "skok_already", id)
}

public skok_already(id)
{
	ColorChat(id, GREEN, "[Hunter]^x03 LongJump gotowy do uzycia!");

	return PLUGIN_CONTINUE;
}