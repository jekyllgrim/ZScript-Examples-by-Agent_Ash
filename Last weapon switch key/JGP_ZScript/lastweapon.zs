class JGP_LastWeaponHandler : EventHandler
{	
	override void PlayerSpawned(playerEvent e)
	{
		int pn = e.PlayerNumber;
			
		if (!PlayerInGame[pn])
			return;
		
		let pmo = players[pn].mo;
		if (!pmo)
			return;
			
		pmo.GiveInventory("JGP_WeaponSwitchControl",1);
	}

	override void NetworkProcess(consoleEvent e)
	{
		if (e.isManual && e.name ~== "selectLastWeapon")
		{
			int pn = e.Player;
			
			if (!PlayerInGame[pn])
				return;
			
			let pmo = players[pn].mo;
			if (!pmo)
				return;
			
			let wsc = JGP_WeaponSwitchControl(pmo.FindInventory("JGP_WeaponSwitchControl"));
			if (wsc)
			{
				wsc.SelectLastWeapon();
			}
		}
	}
}
			

class JGP_WeaponSwitchControl : Inventory
{
	Weapon prevweap;
	Weapon curweap;

	Default
	{
		Inventory.maxamount 1;
		+INVENTORY.UNDROPPABLE
		+INVENTORY.UNTOSSABLE
	}
	
	override void Tick() {}
	
	override void DoEffect()
	{
		super.DoEffect();
		if (!owner || !owner.player)
			return;
			
		let weap = owner.player.readyweapon;
		if (!weap)
			return;
		
		if (weap != curweap || !curweap)
		{
			prevweap = curweap;
			curweap = weap;
		}
		
	}
	
	void SelectLastWeapon()
	{
		if (!prevweap)
			return;
		
		if (!owner || !owner.player || owner.health <= 0)
			return;
		
		owner.player.pendingweapon = prevweap;
	}
}