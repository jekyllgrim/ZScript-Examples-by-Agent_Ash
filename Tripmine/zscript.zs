version "4.13.0"

class TripMineWeapon : Weapon
{
	Default
	{
		Weapon.AmmoType1 "TripMineAmmo";
		Weapon.AmmoUse1 1;
		Weapon.AmmoGive1 1;
		Weapon.SlotNumber 8;
		+Weapon.NOAUTOFIRE
	}

	// Tries to place a mine
	// mineClass allows specifying a custom Tripmine-based class
	// successState is where to go upon successful placement
	// otherwise goes to cancelState
	action State A_PlaceTripMine(class<Tripmine> mineClass, StateLabel successState, StateLabel cancelState)
	{
		let mineDef = GetDefaultByType(mineClass);
		Vector3 spawnPos = (0, 0, 0);
		double mineAngle;
		Vector2 mineDir;

		// Trace from player's eyes:
		FlineTraceData t;
		LineTrace(angle, radius + 16, pitch,
			flags: TRF_SOLIDACTORS,
			offsetz: player.viewz - pos.z,
			offsetforward: radius,
			data: t);

		// Hit a wall and also had enough ammo:
		if (t.hittype == TRACE_HITWALL && t.HitLine && invoker.DepleteAmmo(invoker.bAltFire))
		{
			Line l = t.hitLine;
			// Get wall's normal vector:
			Vector2 lNormal = (-l.delta.y, l.delta.x).Unit();
			if (t.LineSide == Line.front)
			{
				lNormal *= -1;
			}

			// Offset along normal to move the mine out of wall:
			spawnPos.xy = level.Vec2Offset(t.HitLocation.xy, lNormal * mineDef.radius);
			spawnPos.z = t.HitLocation.z;
			// Calculate mine's facing angle:
			mineAngle = atan2(l.delta.y, l.delta.x) - 90;
			mineDir = lNormal;
		}

		if (t.hittype == TRACE_HITACTOR && t.HitActor)
		{
			let a = t.HitActor;
			if (a && a.bSolid && !a.bIsMonster && !a.player && a.vel == (0,0,0))
			{
				spawnPos.xy = level.Vec2Offset(t.HitLocation.xy, t.HitDir.xy * -(a.radius + mineDef.radius));
				spawnPos.z = t.HitLocation.z;
				mineAngle = angle + 180;
				mineDir = -t.HitDir.xy;
			}
		}

		if (spawnPos != (0, 0, 0))
		{
			// Spawn mine on the desired position:
			Tripmine mine = Tripmine(Actor.Spawn(mineClass, spawnPos));
			mine.angle = mineAngle;
			mine.target = self;
			mine.attachDirection = mineDir;
			return ResolveState(successState);
		}

			
		return ResolveState(cancelState);
	}

	States {
	Select:
		MINW A 1 A_Raise;
		loop;
	Deselect:
		MINW A 1 A_Lower;
		loop;
	Ready:
		MINW A 1 A_WeaponReady;
		loop;
	Fire:
		#### # 0 A_OverlayPivot(OverlayID(), 0.5, 0.0);
		MINW AAAA 1
		{
			A_WeaponOffset(0, -2, WOF_ADD);
			A_OverlayScale(OverlayID(), -0.05, -0.05, WOF_ADD);
		}
		// Go to FireEnd if placed successfully, otherwise continue this state:
		#### # 0 A_PlaceTripMine('Tripmine', "FireEnd", null);
		MINW AAAA 1
		{
			A_WeaponOffset(0, 2, WOF_ADD);
			A_OverlayScale(OverlayID(), 0.05, 0.05, WOF_ADD);
		}
		goto Ready;
	FireEnd:
		TNT1 A 0 
		{
			A_WeaponOffset(0, WEAPONBOTTOM);
			A_OverlayScale(OverlayID(), 1, 1);
		}
		TNT1 A 0 A_CheckReload;
		goto Select;
	}
}

class Tripmine : Actor
{
	Vector2 attachDirection;

	Default
	{
		+MISSILE
		+NOGRAVITY
		+WALLSPRITE
		ActiveSound "tripmine/active";
		SeeSound "tripmine/beep";
		DeathSound "tripmine/explode";
		MaxTargetRange 1024;
		Radius 4;
		Height 12;
	}

	// Draw a simple particle beam between the two points:
	void SpawnMineBeam(Vector3 from, Vector3 to, double size = 4)
	{
		FSpawnParticleParams p;
		p.color1 = 0xff0000;
		p.size = size;
		p.flags = SPF_FULLBRIGHT;
		p.style = STYLE_Add;
		p.startalpha = 1.0;
		p.lifetime = 1;
		double dist = size;
		Vector3 path = level.Vec3Diff(from, to);
		Vector3 dir = path.Unit() * dist;
		Vector3 curPos = from;
		for (double d = 0; d < path.Length(); d += dist)
		{
			p.pos = curPos;
			level.SpawnParticle(p);
			curPos = level.Vec3Offset(curPos, dir);
		}
	}

	States {
	Spawn:
		TMIN A 35; 
		#### # 0
		{
			A_StartSound(ActiveSound, CHAN_VOICE);
			A_AttachLight('minelight', DynamicLight.PulseLight,
				0xff0000,
				32,
				24,
				DynamicLight.LF_ATTENUATE,
				(0, 0, height*0.75),
				2.0);
		}
	Idle:
		TMIN B 1
		{
			FlineTraceData t;
			LineTrace(angle, maxTargetRange, pitch, data: t);
			SpawnMineBeam(self.pos + (0,0,self.height*0.75), t.HitLocation);
			if (t.HitType == TRACE_HitActor)
			{
				let a = t.HitActor;
				if (a && a.bShootable && a.health > 0 && !a.bNoClip && !a.bNoInteraction)
				{
					return ResolveState("Explode");
				}
			}
			return ResolveState(null);
		}
		loop;
	Explode:
		TMIN BABA 4
		{
			A_StarTSound(SeeSound, CHAN_AUTO, attenuation: 2);
			A_AttachLight('minelight', DynamicLight.PointLight,
				0xff0000,
				random(20, 50),
				0,
				DynamicLight.LF_ATTENUATE,
				(0, 0, height*0.75));
		}
		TNT1 A 0
		{
			// Explode and give a little momentum to move out of wall:
			bFlatSprite = bWallSprite = false;
			vel.xy = attachDirection * 2;
			A_RemoveLight('minelight');
			A_SetRenderStyle(1.0, STYLE_Add);
			A_Quake(2, 24, 0, 256, "");
			A_StartSound(DeathSound);
			A_Explode(128, 256);
		}
		MISL BCD 8 bright;
		stop;
	}
}

class TripMineAmmo : Ammo
{
	Default
	{
		Inventory.Amount 1;
		Inventory.MaxAmount 50;
		Scale 0.75;
	}

	States {
	Spawn:
		TMIN A -1;
		stop;
	}
}