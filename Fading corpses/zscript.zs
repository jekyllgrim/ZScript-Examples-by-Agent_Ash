version "4.9"

class JGP_CorpseHandler : StaticEventHandler
{
	override void WorldThingDied(worldEvent e)
	{
		let t = e.thing;
		if (t && t.bISMONSTER)
		{
			JGP_CorpseController.Attach(t);
		}
	}
}

class JGP_CorpseController : Thinker
{
	Actor c_corpse;
	State c_dState;
	State c_xdState;
	int c_prevStyle;
	double c_prevAlpha;
	double c_fadeStep;
	int c_fadeDelay;

	static void Attach(Actor thing)
	{
		if (!thing)
			return;
		
		// find final state in Death and XDeath sequences:
		State deathstate = thing.ResolveState("Death");
		while (deathstate && deathstate.nextState)
		{
			deathstate = deathstate.nextstate;
		}
		State xdeathstate = thing.ResolveState("XDeath");
		while (xdeathstate && xdeathstate.nextState)
		{
			xdeathstate = xdeathstate.nextstate;
		}
		// no valid final state or final state is not -1
		// no need to handle, the monster disappears by itself
		if ((!deathstate && !xdeathstate) || (deathstate.tics >= 0 && xdeathstate.tics >= 0))
		{
			return;
		}

		let cc = New('JGP_CorpseController');
		cc.c_corpse = thing;
		cc.c_dState = deathstate;
		cc.c_xdState = xdeathstate;
		cc.c_prevStyle = thing.GetRenderStyle();
		cc.c_prevAlpha = thing.alpha;
		cc.c_fadeStep = thing.alpha / (TICRATE * jgp_corpseFadeTime);
		cc.c_fadeDelay = round(TICRATE * jgp_corpseFadeDelay);
	}

	void Detach()
	{
		if (c_corpse)
		{
			c_corpse.A_SetRenderstyle(c_prevAlpha, c_prevStyle);
		}
		Destroy();
	}

	override void Tick()
	{
		if (!c_corpse)
		{
			Destroy();
			return;
		}
		// got revived before fading out:
		if (c_corpse.health > 0)
		{
			Detach();
			return;
		}
		if (c_corpse.IsFrozen())
		{
			return;
		}
		if (c_fadeDelay > 0)
		{
			c_fadeDelay--;
			return;
		}
		if (c_corpse.curstate != c_dState && c_corpse.curstate != c_xdState)
		{
			return;
		}
		c_corpse.A_FadeOut(c_fadeStep);
	}
}
