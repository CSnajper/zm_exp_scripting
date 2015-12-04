#include <amxmodx>
#include <zp50_core>
#include <zp50_class_nemesis>
#include <zp50_class_survivor>
#include <zp50_ammopacks>
#include <zp50_gamemodes>

native get_user_xp(id)
native set_user_xp(id, amount)
forward zp_fw_core_infect(id, attacker)

new reward_enable, reward_of_nemesis, reward_of_zombie, reward_of_survivor, reward_of_lasthuman, reward_of_firstzombie, reward_of_human;
new xp_of_nemesis, xp_of_survivor, xp_of_lasthuman, xp_of_firstzombie;

public plugin_init() {
	register_plugin("[ZP] Kill Reward", "0.2", "camilost")
	register_event("DeathMsg", "Death", "a")
	reward_enable = register_cvar("zp_reward_of_kill", "1")
	
	reward_of_nemesis = register_cvar("zp_reward_of_nemesis", "10")
	xp_of_nemesis = register_cvar("zp_xp_of_nemesis", "50")
	
	reward_of_zombie = register_cvar("zp_reward_of_zombie", "1")
	
	reward_of_human = register_cvar("zp_reward_of_human", "1")
	
	reward_of_survivor = register_cvar("zp_reward_of_survivor", "10")
	xp_of_survivor = register_cvar("zp_xp_of_survivor", "50")
	
	reward_of_lasthuman = register_cvar("zp_reward_of_lasthuman", "5")
	xp_of_lasthuman = register_cvar("zp_xp_of_lasthuman", "20")
	
	reward_of_firstzombie = register_cvar("zp_reward_of_firstzombie", "5")
	xp_of_firstzombie = register_cvar("zp_xp_of_firstzombie", "20")
}

public Death()
{
	new kid = read_data(1);
	new vid = read_data(2);
	
	if(kid != 0 && kid != vid && get_user_team(kid) != get_user_team(vid) && get_pcvar_num(reward_enable))
	{
		new vname[18];
		new kname[18];
		get_user_name(vid, vname, 17)
		get_user_name(kid, kname, 17)
		new ammopacks = zp_ammopacks_get(kid);
		new nemreward = get_pcvar_num(reward_of_nemesis);
		new zomreward = get_pcvar_num(reward_of_zombie);
		new surreward = get_pcvar_num(reward_of_survivor);
		new lasreward = get_pcvar_num(reward_of_lasthuman);
		new firreward = get_pcvar_num(reward_of_firstzombie);
		new humreward = get_pcvar_num(reward_of_human);
		
		new nemxp = get_pcvar_num(xp_of_nemesis);
		new surxp = get_pcvar_num(xp_of_survivor);
		new lasxp = get_pcvar_num(xp_of_lasthuman);
		new firxp = get_pcvar_num(xp_of_firstzombie);
		
		new const Swarm[] = "Swarm Mode" 
		new SwarmID = zp_gamemodes_get_id(Swarm)
		
		if(zp_class_nemesis_get(vid) && nemreward > 0)
		{	// Jesli zabojca to nie zombie, lecz zabity to nemesis
			zp_ammopacks_set(kid,ammopacks + nemreward)
			new exp = get_user_xp(kid) + nemxp
			set_user_xp(kid, exp)
			//client_print(0, print_chat, "[ZP] %s dostal %d AP (zabil nemesis %s)" , kname, nemreward, vname)
			print_chatColor(0, "\g[ZP] %s \ndostal \g%d AP \noraz \g%d EXPA \t(zabil Nemesis- %s)" , kname, nemreward, nemxp, vname)
		}
		if(zp_core_is_zombie(vid) && !zp_core_is_first_zombie(vid) && !zp_core_is_last_human(vid) && !zp_class_nemesis_get(vid) && zomreward > 0)
		{	// Jesli jest zwyklym zombie, a nie nemesis, ostatnim, pierwszym zombie
			zp_ammopacks_set(kid,ammopacks + zomreward)
			//client_print(0, print_chat, "[ZP] %s dostal %d AP (zabil zombie %s)" , kname, zomreward, vname)
			print_chatColor(0, "\g[ZP] %s \ndostal \g%d AP \t(zabil Zombie- %s)" , kname, zomreward, vname)
		}
		if(!zp_core_is_zombie(vid) && !zp_core_is_first_zombie(vid) && !zp_core_is_last_human(vid) && !zp_class_nemesis_get(vid) && zomreward > 0)
		{	// Jesli jest zwyklym zombie, a nie nemesis, ostatnim, pierwszym zombie
			zp_ammopacks_set(kid,ammopacks + zomreward)
			//client_print(0, print_chat, "[ZP] %s dostal %d AP (zabil zombie %s)" , kname, zomreward, vname)
			print_chatColor(0, "\g[ZP] %s \ndostal \g%d AP \t(zabil Zombie- %s)" , kname, zomreward, vname)
		}
		if(zp_core_is_first_zombie(vid) && !zp_class_nemesis_get(vid) && zp_gamemodes_get_current() != SwarmID && firreward > 0)
		{	// Jesli jest matka zombie, a nie nemesis
			zp_ammopacks_set(kid,ammopacks + firreward)
			new exp = get_user_xp(kid) + firxp
			set_user_xp(kid, exp)
			//client_print(0, print_chat, "[ZP] %s dostal %d AP (zabil matke zombie %s)" , kname, firreward, vname)
			print_chatColor(0, "\g[ZP] %s \ndostal \g%d AP \noraz \g%d EXPA \t(zabil Matke Zombie- %s)" , kname, firreward, firxp, vname)
		}
		if(zp_core_is_last_human(vid) && !zp_core_is_first_zombie(vid) && lasreward > 0)
		{	// Jesli jest ostatnim zombie, a nie matka
			zp_ammopacks_set(kid,ammopacks + lasreward)
			new exp = get_user_xp(kid) + lasxp
			set_user_xp(kid, exp)
			//client_print(0, print_chat, "[ZP] %s dostal %d AP (zabil ostatniego zombie %s)" , kname, lasreward, vname)
			print_chatColor(0, "\g[ZP] %s \ndostal \g%d AP \noraz \g%d EXPA \t(zabil ostatniego zywego- %s)" , kname, lasreward, lasxp, vname)
		}
		if(zp_class_survivor_get(vid) && surreward > 0)
		{	// Jesli zabity jest survivor
			zp_ammopacks_set(kid,ammopacks + surreward)
			new exp = get_user_xp(kid) + surxp
			set_user_xp(kid, exp)
			//client_print(0, print_chat, "[ZP] %s dostal %d AP (zabil ocalenca %s)" , kname, surreward, vname)
			print_chatColor(0, "\g[ZP] %s \ndostal \g%d AP \noraz \g%d EXPA \t(zabil Ocalenca- %s)" , kname, surreward, surxp, vname)
		}
	}
}

public zp_fw_core_infect(id, attacker)
{
	new vname[18];
	new kname[18];
	get_user_name(id, vname, 17)
	get_user_name(attacker, kname, 17)
	
	new humreward = get_pcvar_num(reward_of_human);
	new ammopacks = zp_ammopacks_get(attacker);
	
	if(id != 0 && id != attacker && get_user_team(id) != get_user_team(attacker) && get_pcvar_num(reward_enable))
	{	
		if(!zp_class_survivor_get(id) && get_user_team(id) == 2 && humreward > 0)
		{	// Zarazenie/zabicie czlowieka
			zp_ammopacks_set(attacker,ammopacks + humreward)
			//client_print(0, print_chat, "[ZP] %s dostal %d AP (zabil zombie %s)" , kname, humreward, vname)
			print_chatColor(0, "\g[ZP] %s \ndostal \g%d AP \t(zarazil Czlowieka- %s)" , kname, humreward, vname)
		}
	}
	return PLUGIN_CONTINUE;
}

stock print_chatColor(const id, const input[], any:...)
{
    new msg[191], players[32], count = 1;
    vformat(msg,190,input,3);
    replace_all(msg,190,"\g","^4");// zielony
    replace_all(msg,190,"\n","^1");// zwykly kolor z say'u (zolty)
    replace_all(msg,190,"\t","^3");// kolor druzyny
    
    if (id) players[0] = id; else get_players(players,count,"ch");
    for (new i=0;i<count;i++)
        if (is_user_connected(players[i]))
    {
        message_begin(MSG_ONE_UNRELIABLE,get_user_msgid("SayText"),_,players[i]);
        write_byte(players[i]);
        write_string(msg);
        message_end();
    }
}