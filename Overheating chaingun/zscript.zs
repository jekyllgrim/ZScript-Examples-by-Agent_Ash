version "4.14.0"

class ChaingunOverheat : Chaingun
{
	const HEAT_LAYER	= 50;	// sprite layer index used by the barrel heat layer

	const HEAT_MAX			= 50.0;	// maximum heat value (can't fire when you reach this)
	const HEAT_GAIN			= 1.0;	// how much heat is gained per tic when firing
	const HEAT_DECAY		= 1.0;	// how much heat is lost per tic when not firing
	const HEAT_DECAY_DELAY	= TICRATE * 2;	// how many tics must pass after you've stopped firing before heat begins decaying

	double heat_current;
	uint heat_decayDelayTics;

	Default
	{
		Weapon.SlotNumber 4;
	}

	override void Tick()
	{
		Super.Tick();

		bool shouldGain = false;
		if (owner && owner.player && owner.player.readyweapon == self)
		{
			PSprite psp = owner.player.FindPSprite(PSP_WEAPON);
			shouldGain = psp != null && Actor.InStateSequence(psp, self.GetAtkState());

			if (psp != null && self.heat_current > 0 && !owner.player.FindPSprite(HEAT_LAYER))
			{
				owner.player.SetPSprite(HEAT_LAYER, self.FindState("HeatLayer"));
			}
		}

		if (shouldGain == true)
		{
			self.heat_current += HEAT_GAIN;
		}
		else if (self.heat_current > 0)
		{
			if (self.heat_decayDelayTics > 0)
			{
				self.heat_decayDelayTics--;
			}
			else
			{
				self.heat_current -= min(HEAT_DECAY, self.heat_current);
			}
		}
	}

	States {
	Fire:
		#### # 0
		{
			if (invoker.heat_current >= HEAT_MAX)
			{
				A_ClearRefire();
				return invoker.GetReadyState();
			}
			invoker.heat_decayDelayTics = HEAT_DECAY_DELAY;
			return ResolveState(null);
		}
		CHGG AB 4 A_FireCGun;
		CHGG B 0 A_ReFire;
		Goto Ready;
	
	HeatLayer:
		TNT1 A 0
		{
			A_OverlayFlags(OverlayID(), PSPF_RENDERSTYLE|PSPF_FORCEALPHA, true);
			A_OverlayRenderStyle(OverlayID(), STYLE_Add);
			A_OverlayAlpha(OverlayID(), 1.0);
		}
		CHGH # 1
		{
			if (invoker.heat_current <= 0)
			{
				return ResolveState("Null");
			}
			PSprite pspMain = self.player.FindPSprite(PSP_WEAPON);
			PSPrite pspSelf = self.player.FindPSprite(OverlayID());
			if (pspMain && pspSelf)
			{
				pspSelf.frame = pspMain.frame;
				pspSelf.alpha = clamp(invoker.heat_current / HEAT_MAX, 0.0, 1.0);
			}
			else
			{
				return ResolveState("Null");
			}
			return ResolveState(null);
		}
		wait;
	}
}