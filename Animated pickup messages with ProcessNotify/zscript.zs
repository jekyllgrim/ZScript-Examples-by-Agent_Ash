version "4.12.0"

// For this example, the HUD is just a minor modification
// of Doom's HUD, but this can, of course, be done in a
// completely custom HUD as well.
class DoomTestHUD : DoomStatusBar
{
	const PICKUPMSG_SCROLLTIME = 15; //when new messages are added, the list will scroll for this many tics
	HUDFont pickupMsgFont; //font used for the messages
	array<String> pickupMsgStrings; //this will contain every message as it's received
	array<double> pickupMsgAlpha; //this will track the alpha value for each message to fade them out
	double pickupMsgScrollTics; //this timer will be updated as new messages appear

	override void Init()
	{
		Super.Init();
		pickupMsgFont = HUDFont.Create(Font.FindFont('BigUpper'));
	}

	override bool ProcessNotify(EPrintLevel printlevel, String outline)
	{
		// Detect only pickup messages:
		if (printlevel == PRINT_LOW)
		{
			// When a new message appears, push it to our
			// array of strings:
			pickupMsgStrings.Push(outline);
			// We'll also push 2.0 to the alpha value for
			// this new string. We start with 2.0, so that
			// the message is printed opaque first, then
			// gradually starts fading out:
			pickupMsgAlpha.Push(2.0);
			// To be absolutely safe, make sure the two arrays
			// are of the same size:
			pickupMsgAlpha.Resize(pickupMsgStrings.Size());
			// Update the scroll timer:
			pickupMsgScrollTics = PICKUPMSG_SCROLLTIME;
			// Disable default pickup message printing:
			return true;
		}
		return false;
	}

	override void Tick()
	{
		Super.Tick();
		if (pickupMsgStrings.Size() > 0)
		{
			// Update the alpha values of each message.
			bool shouldclear = true;
			for (int i = 0; i < pickupMsgAlpha.Size(); i++)
			{
				pickupMsgAlpha[i] = max(pickupMsgAlpha[i] - 0.025, 0.0);
				if (pickupMsgAlpha[i] > 0)
				{
					// If at least a single message's alpha is
					// above zero, do not clear them.
					shouldclear = false;
				}
			}
			// If ALL messages' alpha is zero, clear arrays:
			if (shouldclear)
			{
				pickupMsgStrings.Clear();
				pickupMsgAlpha.Clear();
			}
			// Otherwise update scroll timer:
			else if (pickupMsgScrollTics > 0)
			{
				pickupMsgScrollTics--;
			}
		}
	}

	override void Draw(int state, double TicFrac)
	{
		Super.Draw(state, TicFrac);
		
		// Draw the messages using our custom function
		// only if the HUD is currently active. This will
		// draw messages in the bottom left area of the
		// HUD:
		if (state != HUD_None)
		{
			DrawCustomPickupMessage((32, -64), DI_SCREEN_LEFT_BOTTOM, 0.25);
		}
	}

	void DrawCustomPickupMessage(Vector2 pos, int flags, double scale = 1.0)
	{
		int msgcount = pickupMsgStrings.Size();
		if (msgcount <= 0) return;
		
		// Get the height of the font (we will use this for vertical
		// spacing):
		double stringHeight = pickupMsgFont.mFont.GetHeight() * scale;
		// If there's more than 1 message in the queue, offset each
		// message to create an effect of them scrolling:
		if (msgcount > 1)
		{
			pos.y += stringheight * (double(pickupMsgScrollTics) / PICKUPMSG_SCROLLTIME);
		}
		// Finally, draw all messages, starting from the newest one:
		for (int i = msgcount - 1; i >= 0; i--)
		{
			DrawString(pickupMsgFont, 
				pickupMsgStrings[i],
				pos,
				flags: flags,
				translation: Font.CR_Green,
				// Pass the alpha value from the alpha values array.
				// Don't forget to clamp it  to 1.0 here, since it
				// starts at 2.0:
				alpha: min(pickupMsgAlpha[i], 1.0),
				scale: (scale, scale));
			// move up for the next message:
			pos.y -= stringheight;
		}
	}
}