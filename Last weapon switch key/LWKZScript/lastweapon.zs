class LWK_LastWeaponHandler : EventHandler
{
	// Arrays that store current and previous
	// weapon for each player:
	Weapon lwk_lastWeap[MAXPLAYERS];
	Weapon lwk_curWeap[MAXPLAYERS];

	// Continuously keep track of the current
	// and last weapons, updating the arrays above:
	override void WorldTick()
	{
		for(int i = 0; i < MAXPLAYERS; i++)
		{
			if (!PlayerInGame[i]) continue;

			PlayerInfo player = players[i];

			let weap = player.readyweapon;
			if (!weap) continue;

			// No cached current weapon, or actual current weapon
			// is different - update current and last:
			if (weap != lwk_curWeap[i] || lwk_curWeap[i] == null)
			{
				lwk_lastWeap[i] = lwk_curWeap[i];
				lwk_curWeap[i] = weap;
			}
		}
	}

	override void NetworkProcess(consoleEvent e)
	{
		// This is invoked with a keybind or console command
		// that calls "netevent selectLastWeapon" (see KEYCONF):
		if (e.isManual && e.name ~== "selectLastWeapon")
		{
			if (!PlayerInGame[e.Player]) return;

			PlayerInfo player = players[e.Player];

			if (player.health > 0)
			{
				player.pendingweapon = lwk_lastWeap[e.Player];
			}
		}
	}
}