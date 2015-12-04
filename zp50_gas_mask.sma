/*

	                       [ZP] Anti Infect Bomb 
		                    - other name - 
		                       Gas Mask

	Description: 
	[   Removes bombs that is thrown at zombie        ] 
	[   (it will remove everything in range of 150)   ]

	Credits to : 
	[     AmineKyo     ]
	[    Nick Haldem   ]
	[     Excalibur    ]
	[      micapat     ]
	[       Y060N      ]
	
	Version : 
	[2.2 - Final modifying]
*/

#include < amxmodx >
#include < hamsandwich >
#include < engine >

#include <zp50_core>
#include <zp50_items>
#include <zp50_ammopacks>
#include <zp50_class_survivor>
#include <zp50_class_sniper>

#define _PLUGIN   "[ZP50] Extra item: Gas Mask"
#define _VERSION             "2.2"
#define _AUTHOR           "H.RED.ZONE"

#define _MarkPlayerInMask(%0)   _bitPlayerInMask |= (1 << (%0 & 31))
#define _ClearPlayerInMask(%0)  _bitPlayerInMask &= ~(1 << (%0 & 31))
#define _IsPlayerInMask(%0)     _bitPlayerInMask & (1 << (%0 & 31))

#define _MarkPlayerConnected(%0)  _bitPlayerConnected |= (1 << (%0 & 31))
#define _ClearPlayerConnected(%0) _bitPlayerConnected &= ~(1 << (%0 & 31))
#define _IsPlayerConnected(%0)    _bitPlayerConnected & (1 << (%0 & 31))

#define _MarkPlayerAlive(%0)  _bitPlayerAlive |= (1 << (%0 & 31))
#define _ClearPlayerAlive(%0) _bitPlayerAlive &= ~(1 << (%0 & 31))
#define _IsPlayerAlive(%0)    _bitPlayerAlive & (1 << (%0 & 31))

#define EV_INT_nadetype     EV_INT_flTimeStepSound
#define NADETYPE_INFECTION  1111 

#define COST   20           // Item Cost

new g_itemid_buyremoverh
new g_icon 

new _pcvar_range
	,_pcvar_after_remove
	,_pcvar_prefix
	,_pcvar_limit
	
new _bitPlayerInMask
	,_bitPlayerAlive
	,_bitPlayerConnected

new g_MsgSayText
	,g_MaxPlayers
	,g_Limit
	
new const plr_command[][] = {
	"say /mask",
	"say_team /mask"	
}	
	
public plugin_init() {
	register_plugin( _PLUGIN, _VERSION, _AUTHOR )
	
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn", 1 )
	RegisterHam(Ham_Think, "grenade", "fw_ThinkGrenade", 1)
	
	g_itemid_buyremoverh = zp_items_register("Gas Mask" , COST)
    
	register_event( "HLTV", "NewRound", "a", "1=0", "2=0" )
  
	for ( new Index; Index < sizeof plr_command; Index++)
		register_clcmd(plr_command[Index], "buy_mask")
  
	_pcvar_range = register_cvar( "zp_gas_remover_range", "200" )
	_pcvar_after_remove = register_cvar( "zp_gas_remover_after", "1" )
	_pcvar_prefix = register_cvar("zp_gas_mask_prefix", "ZM EXP")
	_pcvar_limit = register_cvar("zp_gas_mask_limit", "1")
	
	g_MsgSayText = get_user_msgid("SayText");
	g_MaxPlayers = get_maxplayers()
	g_icon = get_user_msgid("StatusIcon") 
}

public zp_fw_items_select_pre(id, itemid) {
	if (itemid == g_itemid_buyremoverh) {
		if (zp_core_is_zombie(id) || zp_class_survivor_get(id) || zp_class_sniper_get(id))
			return ZP_ITEM_DONT_SHOW;
		
		static text[32]
		formatex ( text , charsmax ( text ) , "[%d/%d]" , g_Limit , get_pcvar_num ( _pcvar_limit ) )
		zp_items_menu_text_add ( text )
    
		if ( g_Limit >= get_pcvar_num ( _pcvar_limit ) )
			return ZP_ITEM_NOT_AVAILABLE;
		
		return ZP_ITEM_AVAILABLE;
	}
	return ZP_ITEM_AVAILABLE;
}

public zp_fw_items_select_post(plr, itemid, ignorecost) {
        if (itemid == g_itemid_buyremoverh) {
		_MarkPlayerInMask( plr )
		ProtoChat(plr, "Kupiles MASKE GAZOWA! Chroni ona przed bomba infekcyjna w promieniu %i:", get_pcvar_num( _pcvar_range ))
		Icon_On(plr)
		g_Limit++
        }
}  

public buy_mask(id) {
	new AmmoPacks = zp_ammopacks_get(id)
	
	if( AmmoPacks > COST) {
		_MarkPlayerInMask(id)
		zp_ammopacks_set(id, AmmoPacks - COST);
		g_Limit++
	}
	else {
		ProtoChat(id, "You can't buy^x04 Gas Mask^x01 now.")
	}	
}

public fw_ThinkGrenade( entity ) {
	if( is_valid_ent( entity ) && entity_get_int( entity, EV_INT_nadetype ) == NADETYPE_INFECTION  ) { 
		new _cvar_range = get_pcvar_num( _pcvar_range ) 
		new _cvar_after_remove = get_pcvar_num( _pcvar_after_remove )
        
		for( new id = 1 ; id <= g_MaxPlayers ; id++ ) {
			if( _IsPlayerAlive( id ) && _IsPlayerInMask( id )) {
                			if( get_entity_distance( entity, id ) <= _cvar_range ) {
                    			remove_entity( entity )
                    	
                    			if( _cvar_after_remove ) {
                        				_ClearPlayerInMask( id )
							
                        				Icon_Off(id)	
                        				ProtoChat(id, "Infect nade is removed, you don't have mask anymore.")
                    			}
                			}
            		}
        		}
    	}
	return HAM_IGNORED;
}  

public NewRound() {
	_bitPlayerInMask = 0
	g_Limit = 0
}

public client_connect( plr ) {
	_MarkPlayerConnected( plr )	
}

public client_disconnect( plr ) {
	_ClearPlayerConnected( plr )
	Icon_Off( plr )	
}

public zp_user_infected_post( id ) {
	_ClearPlayerInMask( id )
	Icon_Off( id )	
}

public zp_user_infected_pre( id ) {
	_ClearPlayerInMask( id )
	Icon_Off( id )	
} 

public Icon_On(plr) {
	message_begin( MSG_ONE_UNRELIABLE, g_icon, { 0, 0, 0 }, plr );
	write_byte( 1 );
	write_string( "dmg_gas" );
	write_byte( 0 );
	write_byte( 255 );
	write_byte( 0 );
	message_end( );
}
	
public Icon_Off(plr) {
	message_begin( MSG_ONE_UNRELIABLE, g_icon, { 0, 0, 0 }, plr );
	write_byte( 0 );
	write_string( "dmg_gas" );
	write_byte( 0 );
	write_byte( 255 );
	write_byte( 0 );
	message_end( );
}
	
public fw_PlayerKilled(plr, attacker, shouldgib) {
	if(_IsPlayerConnected(plr)) {
		_ClearPlayerAlive(plr)
		Icon_Off(plr)	
	}
}

public fw_PlayerSpawn(plr) {
	if(_IsPlayerConnected(plr)) {
		_MarkPlayerAlive(plr)
		Icon_Off(plr)
	}
}

ProtoChat (plr, const sFormat[], any:...) {
	static i; i = plr ? plr : get_player();
	if ( !i ) {
		return PLUGIN_HANDLED;
	}
	
	new sPrefix[16];
	get_pcvar_string(_pcvar_prefix, sPrefix, 15);
	
	new sMessage[256];
	new len = formatex(sMessage, 255, "^x01[^x04%s^x01] ", sPrefix);
	vformat(sMessage[len], 255-len, sFormat, 3)
	sMessage[192] = '^0' 
	
	Make_SayText(plr, i, sMessage)
	
	return PLUGIN_CONTINUE;
}

get_player() {
	for ( new plr; plr <= g_MaxPlayers; plr++) {
		if (_IsPlayerConnected(plr)) {
			return plr;
		}
	}
	return PLUGIN_HANDLED
}

Make_SayText(Receiver, Sender, sMessage[]) {
	if (!Sender) {
		return PLUGIN_HANDLED;
	}
	message_begin(Receiver ? MSG_ONE_UNRELIABLE : MSG_ALL, g_MsgSayText, {0,0,0}, Receiver)
	write_byte(Sender)
	write_string(sMessage)
	message_end()
	
	return PLUGIN_CONTINUE;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang10266\\ f0\\ fs16 \n\\ par }
*/
