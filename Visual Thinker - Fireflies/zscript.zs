class LampTest : TechLamp
{
	override void PostbeginPlay()
	{
		Super.PostBeginPlay();
		for (int i = 0; i < 3; i++)
		{
			SmallFly.SpawnFly(self, "BAL1A0", 64, 24, 12, true, (0.2,0.2));
		}
	}
}

class FlySpawner : Actor
{
	int renderDistance;
	bool canRender;

	Default
	{
		//$Title "Fly spawner"
		//$Arg0 "No. of flies"
		//$Arg0Type 11

		//$Arg1 "Horizontal flight area"
		//$Arg1Type 23
		//$Arg1Default 24
		
		//$Arg2 "Vertical flight area"
		//$Arg2Type 24
		//$Arg2Default 8

		//$Arg3 "Fully bright flies"
		//$arg3Type 11
		//$arg3Enum { 0 = "Disabled"; 1 = "Enabled"; }

		//$Arg4 "Max render distance"
		//$arg4Type 11
		//$Arg4Default 2048

		+NOINTERACTION
		+NOBLOCKMAP
		+MOVEWITHSECTOR
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		renderDistance = args[4];
		for (int i = args[0]; i > 0; i--)
		{
			let fly = SmallFly.SpawnFly(self, "LAMPFLY", args[2]*0.5, args[1], args[2], args[3]);
		}
	}

	bool IsVisible()
	{
		for (int i = 0; i < MAXPLAYERS; i++)
		{
			if (!PlayerInGame[i]) continue;
			let pmo = players[i].mo;
			if (!pmo) continue;
			if (Distance3DSquared(pmo) <= renderDistance**2)
			{
				return true;
			}
		}
		return false;
	}

	override void Tick()
	{
		Super.Tick();
		if (GetAge() % 10 == 0)
		{
			bDORMANT = !IsVisible();
		}
	}
}

class SmallFly : VisualThinker
{
	Actor source;
	double offsetX;
	double offsetY;
	Vector3 sourcepos;
	Vector3 goal;
	int flyTime;
	bool frozen;

	static SmallFly SpawnFly(Actor attach, string texture, double offsetz, double offsetX, double offsetY, bool fullbright = true, vector2 scale = (1,1))
	{
		Vector3 spos = attach.pos + (0,0,offsetz);
		TextureID tex = TexMan.CheckForTexture(texture);
		if (!tex.IsValid())
		{
			Console.Printf("\cgFly spawn error:\c- Could not find texture named \cd%s\c-", texture);
			return null;
		}
		let fly = SmallFly(VisualThinker.Spawn('SmallFly', tex, spos, (0,0,0), scale:scale));
		fly.source = attach;
		fly.offsetX = offsetX;
		fly.offsetY = offsetY;
		fly.sourcepos = spos;
		fly.flags |= SPF_LOCAL_ANIM;
		if (fullbright)
		{
			fly.flags |= SPF_FULLBRIGHT;
		}
		return fly;
	}

	override void Tick()
	{
		Super.Tick();
		if (!source)
		{
			Destroy();
			return;
		}
		if (source.isFrozen() || source.bDORMANT)
		{
			vel = (0,0,0);
			flytime = 0;
			return;
		}
		
		if (flyTime > 0)
		{
			flyTime--;
			vel *= 0.95;
		}
		else
		{
			goal.xy = sourcepos.xy + Actor.RotateVector((offsetX, 0), frandom[fly](0,360));
			goal.z = sourcepos.z + frandompick[fly](-offsetY, offsetY) * frandom[fly](0.5, 1);
			flyTime = random[fly](5, 12);
			let diff = Level.Vec3Diff(pos, goal);
			let dir = diff.Unit();
			let dist = diff.Length();
			vel = dir * (dist / flyTime);
		}
	}
}
