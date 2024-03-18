/*

    ZSWES_5_Special.zs

    ZScript Windows v0.4.2 Event Handler Special Methods Extension

    Sarah Blackburn
    10-03-2024
    DD-MM-YYYY

    This file extends the event handler class to contain
    any micelaneous methods that are required.

*/

extend class ZEventSystem
{
    /*
		Drops the given class name, in the amount specified,
		at the given MapSpot TID.  If dropFog is true,
		TeleportFog is also spawned.

		It doesn't have to be a MapSpot that is used to
		spawn the objects, it just has to be an actor.

		If using something other than a MapSpot, the DropClass
		property of the ZConversation must be set to the
		name of the actor class doing the item dropping.

		dropAmount works differently than with giving
		items through SetInventory.  For example, with
		SetInventory, if you give the player 20 plasma
		cells, they get 20 rounds.  With dropping, if you
		set the dropAmount to 20, it will attempt to drop 
		20 plasma cell packs, but only one for each valid 
		drop location instance.  So if there are only 5 
		locations, only 5 of the desired 20 packs will spawn.

			Short and Sweet:
			Directly putting items in the player's inventory: the exact amount is added.
			Drop items at locations: up to the desired drop amount will be dropped, if the
			number of drop locations is equal to the drop amount.


	*/
	private void dropItemAtSpot(string dropName, int dropAmount, int spotid, bool dropFog, string dropClass = "MapSpot")
	{
		ActorIterator spotfinder = Level.CreateActorIterator(spotid, dropClass);
		actor a;
		int dropCount = 0;
		while ((a = spotfinder.Next()) && dropCount < dropAmount)
		{
			if (a.tid == spotid)
			{
				a.A_SpawnItemEx(dropName);
				if (dropFog)
					a.A_SpawnItemEx("TeleportFog");
				dropCount++;
			}
		}

		if (dropCount < dropAmount)
			console.Printf(string.Format("ZScript Windows - NOTICE! - Attempted to drop, %d, %s, on drop locations with TID:%d, but could only drop %d!", dropAmount, dropName, spotid, dropCount));
	}

    /* END OF DEFINITION */
}