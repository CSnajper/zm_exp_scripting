#include <amxmodx>
#include <amxmisc>
//#include <zombieplague>

#define PLUGIN "[ZP] Countdown"
#define VERSION "1.0 fixed"
#define AUTHOR "Mr.Apple"

new countdown
new time_s

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
}

public plugin_precache()
{
   precache_sound( "csfifka/eight.wav" )
   precache_sound( "csfifka/seven.wav" )
   precache_sound( "csfifka/six.wav" )
   precache_sound( "csfifka/five.wav" )
   precache_sound( "csfifka/four.wav" )
   precache_sound( "csfifka/three.wav" )
   precache_sound( "csfifka/two.wav" )
   precache_sound( "csfifka/one.wav" )
}

public event_round_start()
{
	set_task(2.0, "zombie_countdown")
	time_s = 8
	countdown = 7
}

public zombie_countdown(id) 
{  
	new speak[ 8 ][] = { "csfifka/one.wav","csfifka/two.wav","csfifka/three.wav","csfifka/four.wav","csfifka/five.wav","csfifka/six.wav","csfifka/seven.wav","csfifka/eight.wav" } 
     
    emit_sound( 0, CHAN_VOICE, speak[ countdown ], 1.0, ATTN_NORM, 0, PITCH_NORM ) 
    countdown-- 
     
    set_hudmessage(179, 0, 0, -1.0, 0.28, 2, 0.02, 1.0, 0.01, 0.1, 10);  
    show_hudmessage(0, "Infection in %i secondes", time_s);  
    --time_s; 
     
    if(time_s >= 1) 
    { 
        set_task(1.0, "zombie_countdown",0) 
    } 
}