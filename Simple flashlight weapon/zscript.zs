version "4.12"

// Simple weapon that acts as a flashlight
class VerySimpleFlashlight : Weapon
{
	Spotlight beam; //pointer to the spawned spotlight

	// Simple wrapper for A_WeaponReady. This makes sure
	// that Fire state cannot be called repeatedbly by
	// holding the attack button, so we don't cycle the
	// flashlight on/off too quickly:
	action void A_FlashlightReady()
	{
		int fflags = 0;
		// Check if player was holding fire button during last tic;
		// if so, disable the ability to fire:
		if (player.oldbuttons & BT_ATTACK)
		{
			fflags |= WRF_NOPRIMARY;
		}
		A_WeaponReady(fflags);
	}

	// Dedicated function that spawns/despawns the light:
	action void A_ToggleFlashlight()
	{
		// If light already exists, destroy it:
		if (invoker.beam)
		{
			A_StartSound("switches/normbutn", CHAN_WEAPON); //switch sound; replace with custom
			invoker.beam.Destroy();
		}
		// Otherwise spawn it:
		else
		{
			A_StartSound("switches/normbutn", CHAN_WEAPON); //switch sound; replace with custom
			// Spawn the light and pass values to it:
			invoker.beam = Spotlight(Spawn('Spotlight', (pos.xy, player.viewz - 10)));
			invoker.beam.args[0] = 255; //red color in 0-255 range
			invoker.beam.args[1] = 255; //green color in 0-255 range
			invoker.beam.args[2] = 255; //blue color in 0-255 range
			invoker.beam.args[3] = 320; //length of the spotllight
			invoker.beam.SpotInnerAngle = 10; //inner angle (brightest area)
			invoker.beam.SpotOuterAngle = 30; //outerangle (dimmer area)
			invoker.beam.bATTENUATE = true; //make it attenuated (skip this if you want a brighter light, but it won't interact with material shaders)
		}
	}

	override void DoEffect()
	{
		Super.DoEffect();
		// If there's no valid owner, or the owner switchd to a different weapon,
		// manually remove the light:
		if (!owner || !owner.player || !owner.player.readyweapon || owner.player.readyweapon != self)
		{
			if (beam)
			{
				beam.Destroy();
			}
			return;
		}

		// Otherwise keep adjusting the light's angle, pitch and position
		// so it's right below the player's view:
		if (beam)
		{
			beam.SetOrigin((owner.pos.xy, owner.player.viewz - 10), true);
			beam.A_SetAngle(owner.angle, SPF_INTERPOLATE);
			beam.A_SetPitch(owner.pitch, SPF_INTERPOLATE);
		}
	}

	// This uses Fist sprites for simplicity:
	States {
	Ready:
		PUNG A 1 A_FlashlightReady();
		loop;
	Fire:
		PUNG A 10 A_ToggleFlashlight();
		goto Ready;
	Select:
		PUNG A 1 A_Raise;
		loop;
	Deselect:
		PUNG A 1 A_Lower;
		loop;
	}
}