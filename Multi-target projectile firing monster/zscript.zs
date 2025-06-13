class DoomImptest : DoomImp
{
	array < Actor> extraTargets;

	bool IsValidVictim(Actor thing)
	{
		return (thing && thing != target && (thing.bISMONSTER || thing.player) && thing.bSHOOTABLE && thing.health > 0 && thing.IsHostile(self) && CheckSight(thing));
	}

	void A_FindExtraTargets(double dist = 1024, vector2 validAngles = (60, 90), int maxTargets = 3)
	{
		extraTargets.clear();
		array < double> distances;

		let itr = BlockThingsIterator.Create(self, dist);
		while (itr.Next())
		{
			let victim = itr.thing;
			if (!IsValidVictim(victim)) //check for bSHOOTABLE, health, friendliness, etc.
				continue;
			
			// check distance:
			double distTo = Distance3D(victim);
			if (distTo > dist)
				continue;
			
			// check it's within allowed FOV:
			vector3 angles = Level.SphericalCoords(self.pos + (0,0,self.height * 0.5), victim.pos+(0,0,victim.height*0.5), (self.angle, self.pitch));
			//console.printf("Found %s | dist: %d | angles: %.1f, %1.f", victim.GetClassName(), distTo, angles.x, angles.y);
			if (angles.x > validAngles.x || angles.y > validAngles.y)
				continue;
			
			// if this is the first victim, push it to array directly:
			int arrSize = extraTargets.Size();
			if (arrSize == 0)
			{
				extraTargets.Push(victim);
				continue;
			}

			// otherwise sort array elements by distance:
			for (int i = 0; i < arrSize; i++)
			{
				int ni = i + 1; // this will be next index:
				// If distance is smaller than the distance to the victim
				// in the current index, put this victim before it:
				if (distTo <= extraTargets[i].Distance3D(self))
				{
					extraTargets.Insert(i, victim);
					break;
				}
				// If distance is higher but there are no more victims,
				// push this one on top:
				else if (ni >= arrSize)
				{
					extraTargets.Push(victim);
					break;
				}
				// If there IS a next victim in the array, and the distance
				// to it is smaller than the distance to this one, put
				// this one right before the next one:
				else if (distTo <= extraTargets[ni].Distance3D(self))
				{
					extraTargets.Insert(ni, victim);
					break;
				}
			}
		}

		// Debug: prints list of victims:
		if (extraTargets.Size() > maxTargets)
		{
			extraTargets.Resize(maxTargets);
		}

		string victimdata = "Victims: ";
		for (int i = 0; i < extraTargets.Size(); i ++)
		{
			let thing = extraTargets[i];
			if (thing)
			{
				victimdata.AppendFormat(String.Format("\n%s, distance %d", thing.GetTag(), thing.Distance3D(self)));
			}
		}
		console.printf(victimdata);
	}

	void A_SpawnMultipleProjectiles(class<Actor> missile = 'DoomImpBall')
	{
		A_SpawnProjectile(missile);
		for (int i = 0; i < extraTargets.Size(); i++)
		{
			let trg = extraTargets[i];
			if (trg)
			{
				A_SpawnProjectile(missile, angle: DeltaAngle(angle, AngleTo(trg)), flags: CMF_AIMDIRECTION, pitch: PitchTo(trg, height * 0.5, trg.height * 0.5));
			}
		}
	}

	void A_SpawnMultipleProjectilesAlt(class<Actor> missile = 'DoomImpBall', missiles = 4)
	{
		A_SpawnProjectile(missile);
		int id = 0;
		for (int i = 0; i < missiles; i++)
		{
			actor trg = target;
			if (id < extraTargets.Size())
			{
				trg = extraTargets[id];
			}
			double spawnheight = (i == 0 || i == 3) ? 44 : 28;
			double spawnofs_xy = i < 2 ? 14 : -14;
			if (trg)
			{			
				A_SpawnProjectile(missile, spawnheight: spawnheight, spawnofs_xy: spawnofs_xy, angle: DeltaAngle(angle, AngleTo(trg)), flags: CMF_AIMDIRECTION, pitch: PitchTo(trg, height * 0.5, trg.height * 0.5));
			}
			else
			{			
				A_SpawnProjectile(missile, spawnheight: spawnheight, spawnofs_xy: spawnofs_xy);
			}
		}
	}

	States {
	Missile:
		TROO EF 8 A_FaceTarget;
		TNT1 A 0 A_FindExtraTargets;
		TROO G 6 A_SpawnMultipleProjectiles;
		Goto See;
	Melee:
		stop;
	}
}