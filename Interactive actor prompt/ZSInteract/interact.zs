class PromptDisplay : EventHandler
{
	ui HUDFont promptFont;

	// This is where you'll need to insert your own
	// custom conditions to check if actor 'thing'
	// should be considered interactable or not.
	clearscope bool isActorInteractable(Actor thing)
	{
		// Right now it simply returns true provided the
		// thing pointer is not null.
		if (thing)
		{
			return true;
		}
		return false;
	}

	// This draws the interaction prompt:
	override void RenderOverlay(RenderEvent e)
	{
		// Do nothing if we're not in a level,
		// or the player has the HUD disabled:
		if (gamestate != GS_Level) return;
		if (screenblocks >= 12) return;

		// Get pointers to consoleplayer's PlayerInfo
		// and PlayerPawn.
		let player = players[consoleplayer];
		let mo = player.mo;
		// Do nothing if this player is a voodoo doll,
		// or is dead:
		if (!mo || mo.health <= 0 || !mo.player || !mo.player.mo || mo.player.mo != mo) return;

		// Fire a Linetracer that will find an actor:
		let tracer = new('PromptDetector');
		if (!tracer) return;
		// Fire from player's screen center:
		Vector3 start = (mo.pos.xy, player.viewz);
		Vector3 dir = (Actor.AngleToVector(mo.angle, cos(mo.pitch)), -sin(mo.pitch));
		tracer.Trace(start, mo.cursector, dir, mo.radius + mo.userange, traceflags: 0, wallmask: 0, ignore: mo);

		// Check if it hit an actor:
		Actor hitactor = tracer.results.HitActor;
		// And check that the actor is interactable:
		if (tracer.results.HitType == TRACE_HitActor && tracer.results.HitActor && isActorInteractable(hitactor))
		{
			// Initiate a font:
			if (!promptFont)
			{
				promptFont = HUDFont.Create(Font.FindFont('NewConsoleFont'));
			}
			// Get the name for the first and second keys
			// that the +use command is bound to:
			let [useKey1, useKey2] = bindings.GetKeysForCommand("+use");
			String keynames = bindings.NameKeys(useKey1, useKey2);
			// Construct the string to print. This will contain
			// the name of the actor, and then a text string
			// mentioning the +use butotn names:
			String prompt = String.Format("\cd%s\c-: Press [%s] to interact", hitactor.GetTag(), keynames); //I would recommend using a proper LANGUAGE string instead, so it can be localized
			
			// Draw it using HUD methods:
			statusbar.BeginHUD();
			// Draws the string slightly below the crosshair:
			statusbar.DrawString(promptFont, prompt, (0, 16), statusbar.DI_SCREEN_CENTER|statusbar.DI_TEXT_ALIGN_CENTER, scale: (0.5, 0.5));
		}
	}
}

// Very simple custom linetracer that detects when it hits an actor:
class PromptDetector : LineTracer
{
	override ETraceStatus TraceCallback()
	{
		switch (results.HitType)
		{
			case TRACE_HitActor:
			case TRACE_HitFloor:
			case TRACE_HitCeiling:
			case TRACE_HitWall:
				return TRACE_Stop;
				break;
		}
		return TRACE_Skip;
	}
}