#include <amxmodx>
#include <amxmisc>

public plugin_init() {
	register_plugin("Blokada zmiany nicku","1.0","grankee")
	register_message(get_user_msgid("SayText"), "message")
}
public message()
{
	new arg[32]
	get_msg_arg_string(2, arg, 31)
	if(containi(arg,"name")!=-1)
	{
		return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}
public client_infochanged(id)
{
	new newname[32],oldname[32]
	get_user_info(id, "name", newname,31)
	get_user_name(id,oldname,31)
	new userid2 = get_user_userid(id);
	if(!is_user_connected(id) || is_user_bot(id)) return PLUGIN_CONTINUE
	if(!equal(newname, oldname))
	{
		set_user_info(id,"name",oldname)
		client_print(id , print_chat , "[AMXX] Zakaz zmiany nicka! Kick!")
		server_cmd("kick #%d ^"Zakaz zmiany nicku!^"",userid2)
		return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}