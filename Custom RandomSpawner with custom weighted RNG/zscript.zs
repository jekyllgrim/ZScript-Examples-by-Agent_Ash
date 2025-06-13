version "4.13"

// Custom randomspawner, base class. This doesn't rely on DropItem, 
// and instead uses arrays. Inherit from this and override the
// BuildActorList function to fill in the arrays.
class CustomWeightedSpawner : RandomSpawner abstract
{
	array<Name> actorsToSpawn;
	array<int> spawnChances;

	// Custom virtual that defines a list of actors,
	// and their chances. The chances can be defined
	// manually, or be added from an integer cvar.
	// CVars MUST be defined as 'server int'!
	// The sizes of arrays at the end MUST be the same!

	// Since this is a virtual, you can create more versions
	// of this spawner and override it to modify what gets 
	// pushed. See CustomZombiemanSpawner below
	virtual void BuildActorList()
	{}

	override void BeginPlay()
	{
		BuildActorList();
		// Prevent the spawner from proceeding if the arrays
		// couldn't be built:
		if (actorsToSpawn.Size() != spawnChances.Size() || min(actorsToSpawn.Size(), spawnChances.Size() == 0))
		{
			Console.Printf("\cgCustomWeightedSpawner error:\c- invalid array sizes (actors array: \cd%d\c-, chances array: \cd%d\c-). Array sizes must be equal and larger than 0. Destroying spawner.", actorsToSpawn.Size(), spawnChances.Size());
			Destroy();
			return;
		}
		Super.BeginPlay();
	}

	override Name ChooseSpawn()
	{
		// Time for weighted randomization.

		// First, calculate total weight of all entries:
		int totalweight;
		foreach (weight : spawnChances)
		{
			totalweight += clamp(weight, 0, 255);
		}

		// Don't continue if chances for everything are 0.
		if (totalweight <= 0)
		{
			return 'none';
		}

		// Roll value:
		int roll = random[add](0, totalweight);
		Name toSpawn;
		// Iterate over the array until a specific actor's
		// spawn chance weight is higher than the roll:
		for (int i = 0; i < actorsToSpawn.Size(); i++)
		{
			// This actor's spawn chance weight:
			int weight = clamp(spawnchances[i], 0, 255);
			Console.Printf("Calculating chance for \cd%s\c- | Roll: \cd%d\c- | Weight: \cd%d\c- | %s", actorsToSpawn[i], roll, weight, roll <= weight? "\cdSUCCESS" : "\cgFAIL");
			// Success:
			if (roll < weight)
			{
				toSpawn = actorsToSpawn[i];
				break;
			}
			// Fail. Reduce roll value for next attempt:
			roll -= weight;
		}
		return toSpawn;
	}
}

// Example of a spawner based on the above class:
class CustomZombiemanSpawner : CustomWeightedSpawner
{
	override void BuildActorList()
	{
		// Example actor name, example CVar name:
		actorsToSpawn.Push('Zombieman');
		spawnChances.Push(255);

		// Example actor name, example CVar name:
		actorsToSpawn.Push('ChaingunGuy');
		spawnChances.Push(64);

		// Example actor name, example CVar name:
		actorsToSpawn.Push('DoomImp');
		spawnChances.Push(64);

		// Example actor name, example CVar name:
		actorsToSpawn.Push('BaronOfHell');
		spawnChances.Push(64);
	}
}