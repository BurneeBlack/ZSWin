/*

    ZSWES_1_Debug.zs

    ZScript Windows v0.4.2 Event Handler Debug Extension

    Sarah Blackburn
    10-03-2024
    DD-MM-YYYY

    This file extends the event handler class to contain
    debugging methods.

*/

extend class ZEventSystem
{
    /*
		These are debug messages that can be output from manual net events
	*/
	private void debugStackSizeToConsole() { console.printf(string.Format("ZEvent System Stack Size is currently : %d", winStack.Size())); }
	private void debugStackPriorityToConsole()
	{
		if (winStack.Size() > 0)
		{
			for (int i = 0; i < winStack.Size(); i++)
				console.printf(string.Format("Window : %s, has priority : %d", winStack[i].Name, winStack[i].Priority));
			console.printf(string.format("Priority Stack Index is : %d", priorityStackIndex));
			console.printf(string.format("Ignoring Duplicate Posts: %d", ignorePostDuplicate));
		}
		else
			console.printf("ZEvent System does not contain any windows.");
	}
	/*
		Oooo!  Glad I added this in, I was suspicious that deletion was going to leave
		dangling pointers and sure enough, you can orphan thinkers if controls are not
		set to be deleted as well.
	*/
	private void debugGetGlobalObjectCount()
	{
		int zcount = 0;
		ThinkerIterator zobjfinder = ThinkerIterator.Create("ZObjectBase");
		Thinker t;
		while (t = ZObjectBase(zobjfinder.Next()))
			zcount++;
		console.printf(string.Format("ZEvent System found %d ZObjects in the present level.", zcount));
	}
	
	private void debugGetEventGlobalCount() { console.printf(string.Format("ZEvent System is accounting for %d objects in its global array.", allZObjects.Size())); }
	
	private void debugPrintOutEveryName()
	{
		console.printf(string.Format("ZEvent System Global Objects size is: %d", allZObjects.Size()));
		for (int i = 0; i < allZObjects.Size(); i++)
		{
			if (allZObjects[i] != null)
				console.printf(string.Format("ZEvent System Gobal Objects, index: %d, is named: %s", i, allZObjects[i].Name));
			else
				console.printf(string.Format("ZEvent System Global Objects, index: %d, is null", i));
		}
	}

    /* END OF DEFINITION*/
}