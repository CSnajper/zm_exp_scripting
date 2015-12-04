#include <amxmodx>

// Plugin Version
new const VERSION[] = "1.4"

// Max sprites
const MAX_SPRITES = 3

// Customization(You do not need to add "sprites/")
new const DEATH_SPRITE[][] =
{
	"93skull1" // zp_death_sprite_play 1
}

// PCVars and caching of CVars
new Toggle, Brightness, Message, Delay, PlayWhich
new Toggle_Cached, Brightness_Cached, Float:Delay_Cached, PlayWhich_Cached

// Sprite
new DeathSprite[MAX_SPRITES]

new g_bitConnectedPlayers

#define MarkUserConnected(%0)   g_bitConnectedPlayers |= (1 << (%0 & 31))
#define ClearUserConnected(%0)  g_bitConnectedPlayers &= ~(1 << (%0 & 31))
#define IsUserConnected(%0)	g_bitConnectedPlayers & (1 << (%0 & 31))

public plugin_init()
{
	register_plugin("[ZP] Addon: Death Sprite", VERSION, "eXcalibur.007")
	
	// New Round
	register_event("HLTV", "event_new_round", "a", "1=0", "2=0")
	
	// Death Message event
	register_event("DeathMsg", "event_DeathMsg", "a")
	
	// PCVars
	Toggle = register_cvar("zp_death_sprite", "1")
	Brightness = register_cvar("zp_death_sprite_brightness", "255")
	Message = register_cvar("zp_death_sprite_message", "[R]est.[I]n.[P]eace. - Grim Reaper")
	Delay = register_cvar("zp_death_sprite_delay", "1.0")
	PlayWhich = register_cvar("zp_death_sprite_play", "0")
}

public plugin_precache()
{
	// Format the directory so we do not need to add "sprites/"
	static buffer[100], i
	
	for(i = 0; i < sizeof DEATH_SPRITE; i++)
	{
		formatex(buffer, 99, "sprites/%s.spr", DEATH_SPRITE[i])
		DeathSprite[i] = precache_model(buffer)
	}
}

public plugin_cfg()
{
	// Cache CVars
	set_task(0.5, "event_new_round")
	
	// Get configs directory
	static cfgdir[64]
	get_localinfo("amxx_configsdir", cfgdir, 63)
	
	// Execute custom config file
	server_cmd("exec %s/DeathSprite.cfg", cfgdir)
	server_exec()
}

public client_putinserver(id)
{
	// Set variables
	MarkUserConnected(id)
}

public client_disconnect(id)
{
	// Set variables
	ClearUserConnected(id)
}

public event_new_round()
{
	// CVars caching
	Toggle_Cached = get_pcvar_num(Toggle)
	Brightness_Cached = get_pcvar_num(Brightness)
	Delay_Cached = get_pcvar_float(Delay)
	PlayWhich_Cached = get_pcvar_num(PlayWhich)
}

public event_DeathMsg()
{
	// If CVar "zp_death_sprite" is 0
	if(!Toggle_Cached)
		return PLUGIN_CONTINUE
	
	// Victim's index
	static victim; victim = read_data(2)
	
	// Valid victim & connected
	if(victim && IsUserConnected(victim))
	{
		static string[192]
		get_pcvar_string(Message, string, 191)
		
		// Empty spaces = Disables print
		if(string[0])
			client_print(victim, print_chat, "%s", string)
		
		// Invalid CVar value
		if(PlayWhich_Cached > MAX_SPRITES || PlayWhich_Cached < 0)
		{
			server_print("Please check zp_death_sprite_play and MAX_SPRITES constant. It must not be more than %i and not less than 0.", MAX_SPRITES)
			return PLUGIN_CONTINUE
		}
		
		set_task(Delay_Cached, "show_sprite", victim)
	}
	return PLUGIN_CONTINUE
}

public show_sprite(id)
{
	if(IsUserConnected(id))
	{
		static sprite
		
		// Valid CVar value
		if(PlayWhich_Cached == 0)
			sprite = random_num(0, sizeof DEATH_SPRITE - 1)
		else
			sprite = PlayWhich_Cached - 1
		
		// Get user's origin
		static origin[3]
		get_user_origin(id, origin)
		
		message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
		write_byte(TE_SPRITE)
		write_coord(origin[0])
		write_coord(origin[1])
		write_coord(origin[2])
		write_short(DeathSprite[sprite])
		write_byte(15)
		write_byte(Brightness_Cached)
		message_end()
	}
	return PLUGIN_CONTINUE
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang18441\\ f0\\ fs16 \n\\ par }
*/
