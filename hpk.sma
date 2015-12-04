#include <amxmodx>
#include <colorchat>

new HIGHPING_MAX_NORMAL = 150 // set maximal acceptable ping
new HIGHPING_MAX_VIP = 200 // set maximal acceptable ping
new HIGHPING_TIME = 6  // set in seconds frequency of ping checking
new HIGHPING_TESTS = 3  // minimal number of checks before doing anything

new iNumTests[33]

public plugin_init() {
	register_plugin("High Ping Kicker","1.2.0","DynAstY")
	if (HIGHPING_TIME < 10) HIGHPING_TIME = 6
	if (HIGHPING_TESTS < 4) HIGHPING_TESTS = 3
	return PLUGIN_CONTINUE
}

public client_disconnect(id) {
	remove_task(id)
	return PLUGIN_CONTINUE
}
	
public client_putinserver(id) {
	iNumTests[id] = 0
	if (!is_user_bot(id)) {
		new param[1]
		param[0] = id
		set_task(30.0, "showWarn", id, param, 1)
	}
	return PLUGIN_CONTINUE
}

kickPlayer(id) {
	new name[32]
	get_user_name(id, name, 31)
	new uID = get_user_userid(id)
	//server_cmd("kick #%d", uID)
	//client_cmd(id, "echo ^"[HPK] Twoj ping jest za duzy!^"; disconnect")
	new kickReason[51]
	if(get_user_flags(id) & ADMIN_LEVEL_H)
		kickReason = "Twoj Ping jest za duzy! Limit: 200 ms"
	else kickReason = "Twoj Ping jest za duzy! Limit: 150 ms"
	server_cmd("kick #%d ^"%s^"",uID,kickReason)
	ColorChat(0, GREEN, "[HPK]^x01 Gracz^x04 %s^x01 zostal rozlaczony z powodu duzego ping'u!", name)
	return PLUGIN_CONTINUE
} 

public checkPing(param[]) {
	new id = param[0]
	if ((get_user_flags(id) & ADMIN_IMMUNITY)) {
		remove_task(id)
		ColorChat(0, GREEN, "[HPK]^x01 Ping nie obowiazuje graczy z immunitetem...")
		return PLUGIN_CONTINUE
	}
	new p, l
	get_user_ping(id, p, l)
	if(get_user_flags(id) & ADMIN_LEVEL_H)
	{
		if (p > HIGHPING_MAX_VIP)
			++iNumTests[id]
		else
			if (iNumTests[id] > 0) --iNumTests[id]
		if (iNumTests[id] > HIGHPING_TESTS)
			kickPlayer(id)
	}
	else
	{
		if (p > HIGHPING_MAX_NORMAL)
			++iNumTests[id]
		else
			if (iNumTests[id] > 0) --iNumTests[id]
		if (iNumTests[id] > HIGHPING_TESTS)
			kickPlayer(id)
	}
	return PLUGIN_CONTINUE
}

public showWarn(param[]) {
	ColorChat(param[0], GREEN, "[HPK]^x01 Gracze z pingiem wiekszym niz^x04 %d^x01 beda wyrzucani!", HIGHPING_MAX_NORMAL)
	set_task(float(HIGHPING_TIME), "checkPing", param[0], param, 1, "b")
	return PLUGIN_CONTINUE
}

