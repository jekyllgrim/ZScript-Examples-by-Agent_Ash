version "4.8.0"

class DropAmountController : EventHandler
{
	array <Inventory> droppedItems;
	
	override void WorldThingSpawned(WorldEvent e)
	{
		let item = Inventory(e.thing);
		// It seems reasonable to only have this affect
		// ammo, health and weapon pickups, just in case the
		// monster for some reason drops something important,
		// like a key:
		if (item && item.bTossed && (item is 'Ammo' || item is 'Health' || item is 'Weapon'))
		{
			droppedItems.Push(item);
		}
	}

	override void WorldTick()
	{
		for (int i = droppedItems.Size() - 1; i >= 0; i--)
		{
			let item = droppedItems[i];
			if (!item || item.bNoSector || item.owner)
			{
				droppedItems.Delete(i);
			}
		}
		while (droppedItems.Size() > cl_maxmonsterdrops)
		{
			droppedItems.Delete(0);
		}
	}
}