#if defined _zp50_weapon_minigun_included
  #endinput
#endif
#define _zp50_weapon_minigun_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib zp50_weapon_minigun
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib zp50_weapon_minigun
	#endif
#else
	#pragma library zp50_weapon_minigun
#endif


/**
 * Returns whether a player has a minigun.
 *
 * @param id		Player index.
 * @return			True if it is, false otherwise.
 */
native zp_minigun_get(id)