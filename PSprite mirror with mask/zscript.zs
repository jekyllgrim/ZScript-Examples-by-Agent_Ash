version "4.10"

class MirrorWeapon : Shotgun
{
	ReflectionCamera cam;
	
	Default 
	{
		Weapon.SlotNumber 3;
	}

	override void DoEffect()
	{
		super.DoEffect();
		if (!owner || !owner.player)
			return;
		
		if (!cam)
		{
			cam = ReflectionCamera(Spawn("ReflectionCamera", owner.pos));
			cam.ppawn = PlayerPawn(owner);
			TexMan.SetCameraToTexture(cam, "Weapon.camtex", 120);
		}
	}

	states
	{
	Ready:
		SHGG A 1 A_WeaponReady(WRF_NOFIRE);
		loop;
	}
}

class CameraHandler : Eventhandler
{
	ui TextureID mirrortex;
	
	override void RenderOverlay(renderEvent e) 
	{
		if (!PlayerInGame[consoleplayer])
			return;
		
		PlayerInfo plr = players[consoleplayer];
		if (plr && plr.readyweapon)
		{	
			if (!mirrortex)
				mirrortex = TexMan.CheckForTexture("Weapon.camtex", TexMan.Type_Any);
			if (mirrortex.IsValid()) {
				Screen.DrawTexture(mirrortex, false, 0.0, 0.0, DTA_Alpha, 0.0);
			}
		}
	}
}

class ReflectionCamera : Actor 
{
	PlayerPawn ppawn;

	Default	
	{
		+NOINTERACTION
		+NOTIMEFREEZE
		radius 1;
		height 1;
	}
	
	override void Tick() 
	{
		if (!ppawn) 
		{
			Destroy();
			return;
		}
		
		Warp(
			ppawn, 
			xofs: -ppawn.radius, 
			yofs: 0,
			zofs: ppawn.player.viewheight - 8
		);
		
		A_SetRoll(ppawn.roll, SPF_INTERPOLATE);
		A_SetAngle(ppawn.angle + 180, SPF_INTERPOLATE);
		A_SetPitch(-ppawn.pitch, SPF_INTERPOLATE);
	}
}