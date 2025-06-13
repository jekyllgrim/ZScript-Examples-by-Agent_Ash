version "4.8.0"

class ProjectileHitbox : Actor
{
	// This will store a pointer to the projectile
	// the  hitbox is attached to:
	Actor attachedProjectile;

	Default
	{
		// The SHOOTABLE flag is needed so it can actually
		// be hit by attacks. The NOBLOOD flag is optional,
		// although most projectiles don't bleed:
		+SHOOTABLE
		+NOBLOOD
		// Set up radius and height as desired. Usually it's
		// recommended to make them bigger than the projectile's:
		Radius 64;
		Height 32;
		// Don't forget to set the desired number of health:
		Health 100;
	}

	// For convenience, we'll make a dedicated static function
	// to spawn and attach a hitbox (this is not required though):
	static Actor SpawnHitbox(Actor attached)
	{
		let h = ProjectileHitbox(Actor.Spawn('ProjectileHitbox', attached.pos));
		if (h)
		{
			h.attachedProjectile = attached;
		}
		return h;
	}

	// When the hitbox is destroyed, it'll cause
	// the projectile it's attached to to explode:
	override void Die(Actor source, Actor inflictor, int dmgflags, Name MeansOfDeath)
	{
		if (attachedProjectile)
		{
			attachedProjectile.ExplodeMissile();
		}
		super.Die(source, inflictor, dmgflags, MeansOfDeath);
	}

	// Continuously warp to the projectile:
	override void Tick()
	{
		Super.Tick();
		if (attachedProjectile)
		{
			// We're offsetting the hitbox so that it's vertically
			// centered at the projectile's middle:
			SetOrigin(attachedProjectile.pos + (0,0, attachedProjectile.height*0.5), true);
		}
		// If the projectile doesn't exist anymore, immediately
		// destroy this actor:
		else
		{
			Destroy();
		}
	}

	// This actor doesn't need any states, unless
	// you specifically want to make it visible.
}

// Example projectile. For simplicity, it's based on Doom's Rocket,
// but you can design any kind of projectile however you like.
class RocketWithHitbox : Rocket
{
	// This will store a pointer to the projectile's hitbox:
	Actor hitbox;

	// This spawns the hitbox actor as soon as the projectile
	// has spawned:
	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		hitbox = ProjectileHitbox.SpawnHitbox(self);
	}

	// This is an important bit: we need to make sure the projectile
	// can't hit its own hitbox, so we pass MHIT_PASS if it crosses it:
	override int SpecialMissileHit(Actor victim)
	{
		if (victim && hitbox && victim == hitbox)
		{
			return MHIT_PASS;
		}
		return MHIT_DEFAULT;
	}

	// You can add any other Default properties/flags and states
	// as usual.
}