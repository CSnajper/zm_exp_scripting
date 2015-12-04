/*
	Created by DJ_WEST
	
	Web: http://amx-x.ru
	Русское сообщество по AMX Mod X и SourceMod
	
	Присоединяйтесь к нам. Здесь рождаются новые идеи.
*/


#include <amxmodx>
#include <orpheu>

#define PLUGIN "RCON Defencer"
#define VERSION "1.1"
#define AUTHOR "DJ_WEST"

// Укажите здесь ваш RCON пароль в MD5 формате
#define RCON_PASSWORD "7b879220cac4f6700d9d4ba60b4ec32f"

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	OrpheuRegisterHook(OrpheuGetFunction("SV_Rcon_Validate"), "On_Rcon_Validate_Pre", OrpheuHookPre)
	OrpheuRegisterHook(OrpheuGetFunction("SV_Rcon_Validate"), "On_Rcon_Validate_Post", OrpheuHookPost)
}

public OrpheuHookReturn:On_Rcon_Validate_Pre()
{
	static s_Msg[76], s_Challenge[12], s_Rcon[32], s_Command[32], s_MD5[34]
    
	read_args(s_Msg, charsmax(s_Msg))
	parse(s_Msg, s_Challenge, charsmax(s_Challenge), s_Rcon, charsmax(s_Rcon), s_Command, charsmax(s_Command))
	md5(s_Rcon, s_MD5)
    
	if (equal(s_MD5, RCON_PASSWORD))
		set_cvar_string("rcon_password", s_Rcon)
}

public OrpheuHookReturn:On_Rcon_Validate_Post()
	set_cvar_string("rcon_password", "")
 
