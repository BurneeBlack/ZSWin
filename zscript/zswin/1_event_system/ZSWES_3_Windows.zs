/*

    ZSWES_3_Windows.zs

    ZScript Windows v0.4.2 Event Handler Window Methods Extension

    Sarah Blackburn
    10-03-2024
    DD-MM-YYYY

    This file extends the event handler class to contain
    relevent methods for manipulating windows.

*/

extend class ZEventSystem
{
/*
		Windows - and only windows - have to call this IN IMPLEMENTATION
		to have the instance added to the window stack.
		
		This has to be done by the windows themselves because ZObjectBase is
		the base of all objects, so this cannot be done in the base.
		
		As demonstrated in the ImpWindow, this is supposed to be called as part
		of the final descendent's Init return.  This method passes it's zobj argument
		back up to its caller.
		
		Just like all things, this cannot be done instantaneously, this has
		to be done on the next UiTick, so incoming windows go to the incomingWindows
		array and will be added in next tick.
		
		This method attempts to protect the window stack by not accepting
		any null references, the reference must be a ZSWindow descendent, and the object
		Name may not be empty (further name restrictions may be put in place if certain
		words require string conversions)
	
	*/

	private void addWindowToStack(string n)
	{
		ThinkerIterator nwdFinder = ThinkerIterator.Create("ZSWindow");
		ZSWindow enwd;
		while (enwd = ZSWindow(nwdFinder.Next()))
		{
			if (enwd.Name ~== n)
				break;
		}
		
		if (enwd)
		{
			if (GlobalNameIsUnique(allZObjects, enwd.Name))
				incomingWindows.Push(enwd);
			else
			{
				int ei = GetStackIndex(enwd);
				if (ei != GetStackSize())
					console.printf(string.format("WARNING! - Duplicate attempt to add window, %s, to stack ignored!", enwd.Name));
				else
				{
					console.printf(string.format("ERROR! - Duplicate window name, %s!  Unique names only!  Duplicate destroyed.", enwd.Name));
					removeOutgoingFromGlobal(enwd);
					enwd.bSelfDestroy = true;
				}
			}
		}
		else
			console.printf(string.Format("ERROR! - ZScript Windows did not find the window, %s!", n));
	}
	
	/*
		Moves incoming windows to the stack
	*/
	private void passIncomingToStack()
	{
		for (int i = 0; i < winStack.Size(); i++)
			winStack[i].Priority += incomingWindows.Size();
		
		// Not sure about append without testing so we'll just use push
		for (int i = 0; i < incomingWindows.Size(); i++)
		{
			if (i < incomingWindows.Size() - 1)
				incomingWindows[i].Priority = (winStack.Size() == 0 ? 1 : winStack.Size()) + i;
			else
				incomingWindows[i].Priority = 0;
			winStack.Push(incomingWindows[i]);
		}
		
		incomingWindows.Clear();
	}
	
	/*
		Finds the ZObject with the give name, and adds
		that object to the incoming objects list.
		
	*/
	private void addObjectToGlobalObjects(string n)
	{
		ThinkerIterator zobjFinder = ThinkerIterator.Create("ZObjectBase");
		ZObjectBase zobj;
		while (zobj = ZObjectBase(zobjFinder.Next()))
		{
			if (zobj.Name ~== n ? GlobalNameIsUnique(allZObjects, zobj.Name) : false)
			{
				incomingZObjects.Push(zobj);
				return;
			}
			else if (zobj.Name ~== n ? !GlobalNameIsUnique(allZObjects, zobj.Name) : false)
			{
				// Destroy object and debug out invalid name
				zobj.bSelfDestroy = true;
				console.printf(string.Format("ZScript Windows enforces unique names for all ZObjects, %s, is taken and object being created has been destroyed.  Sorry.", n));
				return;
			}
		}
		
		console.printf(string.Format("ERROR! - ZScript Windows did not find object named, %s, to be added to global list!", n));
	}
	
	/*
		Adds any objects in the incoming array to the allZObjects array.
	*/
	private void passIncomingToGlobalObjects()
	{
		for (int i = 0; i < incomingZObjects.Size(); i++)
			allZObjects.Push(incomingZObjects[i]);
		incomingZObjects.Clear();
	}
	
	/*
		Calls the ObjectUpdate method on an object at the given
		global index.
	*/
	private void controlUpdateEvent(string controlName)
	{
		let zobj = FindZObject(controlName);
		if (zobj)
			zobj.ObjectUpdate();
	}
	
	/*
		Called by an object to signal that the window at the given
		window stack index needs to be priority 0.
	*/
	private void postPriorityIndex(string n, bool Ignore = false) 
	{
		if (!ignorePostDuplicate)
		{
			priorityStackIndex = GetStackIndex(GetWindowByName(n)); 
			winStack[priorityStackIndex].EventInvalidate();
			ignorePostDuplicate = Ignore;
		}
	}
	
	/*
		Performs the actual priority switch on the window stack.
		This has no impact on a window's controls.
	*/
	private void windowPrioritySwitch()
	{
		if (winStack[priorityStackIndex].Priority > 0)
		{
			array<int> plist;
			for (int i = 0; i < winStack.Size(); i++)
			{
				if (i == priorityStackIndex)
					plist.Push(0);
				else if (winStack[i].Priority < winStack.Size() - 1)
					plist.Push(winStack[i].Priority + 1);
				else
					plist.Push(winStack[i].Priority);
			}
			
			if (plist.Size() == winStack.Size())
			{
				for (int i = 0; i < plist.Size(); i++)
					winStack[i].Priority = plist[i];
			}
		}
		
		priorityStackIndex = -1;
	}
	
	private void letAllPost() { ignorePostDuplicate = false; }

    /*
		This method iterates the window stack and calls the
		window events based on the cursor event.
	*/
	private void windowEventCaller()
	{
		for (int i = 0; i < winStack.Size(); i++)
		{
			// Window must be for the current player, window must be shown, and window must be enabled to be interacted with
			if (winStack[i].PlayerClient == consoleplayer && winStack[i].Show && winStack[i].Enabled)
			{
				switch (cursor.EventType)
				{
					case ZUIEventPacket.EventType_MouseMove:
						winStack[i].OnMouseMove(cursor.EventType);
						break;
					case ZUIEventPacket.EventType_LButtonDown:
						winStack[i].OnLeftMouseDown(cursor.EventType);
						break;
					case ZUIEventPacket.EventType_LButtonUp:
						winStack[i].OnLeftMouseUp(cursor.EventType);
						break;
					case ZUIEventPacket.EventType_LButtonClick:
						winStack[i].OnLeftMouseClick(cursor.EventType);
						break;
					case ZUIEventPacket.EventType_MButtonDown:
						winStack[i].OnMiddleMouseDown(cursor.EventType);
						break;
					case ZUIEventPacket.EventType_MButtonUp:
						winStack[i].OnMiddleMouseUp(cursor.EventType);
						break;
					case ZUIEventPacket.EventType_MButtonClick:
						winStack[i].OnMiddleMouseClick(cursor.EventType);
						break;
					case ZUIEventPacket.EventType_RButtonDown:
						winStack[i].OnRightMouseDown(cursor.EventType);
						break;
					case ZUIEventPacket.EventType_RButtonUp:
						winStack[i].OnRightMouseUp(cursor.EventType);
						break;
					case ZUIEventPacket.EventType_RButtonClick:
						winStack[i].OnRightMouseClick(cursor.EventType);
						break;
					case ZUIEventPacket.EventType_WheelUp:
						winStack[i].OnWheelMouseDown(cursor.EventType);
						break;
					case ZUIEventPacket.EventType_WheelDown:
						winStack[i].OnWheelMouseUp(cursor.EventType);
						break;
					default:
					case ZUIEventPacket.EventType_None:
						winStack[i].WhileMouseIdle(cursor.EventType);
						break;
				}
			}
		}		
	}
	
	/*
		Adds the given window stack index the list of windows to be deleted.
	*/
	private void setWindowForDestruction(string n)
	{
		outgoingWindows.Push(GetStackIndex(GetWindowByName(n)));
	}
	
	/*
		Think this looks bad?  Look at removeOutgoingFromGlobal, which this method calls.
		
		This is the process by which windows and their controls are deleted from the system
		and the level.  This is actually stupid levels of important, not just because of the
		VM crash that will happen if this isn't done right, but because ZScript Windows has
		found a way to circumvent the engine's garbage collection, through basically its own
		memory management.  If a ZObject is not destroyed when it is removed from any part of
		the ZScript Windows code, that object has no references to it of any meaningful value.
		Under the hood the gc should still have the thinker it is reference lists, there may
		be some lingering references in scripts or other actors, but unless something actually
		does something with the ZObject references, they just sit there consuming memory.
		
		This means, at least hypothetically, it should be possible to crash the engine through
		what is essentially a memory leak by creating ZObjects, then removing them from the
		ZEvent System without deleting them from the game.  You would have to do this a really
		ridiculous number to times to cause the crash.  You also could see this take place
		through something as simple as the Windows Task Manager; just watch the memory usage of
		the engine, I used to do that with old Z-Windows when I had memory problems.
		
		But this is solved with the code below.  You delete a window, it and it's controls
		go away, for good.  Turn it off if you want it to persist but not be on the player's screen.
		
		The real problem here is the linear lists used for everything, if I had
		binary trees, especially AVL trees, I could do this with an O(log n) time instead of
		whatever monsterous hell this is - mostly linear, might be capable of exponetial time
		under the right circumstances (deleting every window and control currently in the system).
	*/
	private void deleteOutgoingWindows()
	{
		array<ZObjectBase> newStack;
		// Iterate through the entire stack
		for (int i = 0; i < winStack.Size(); i++)
		{
			// Compare each window to the outgoing list
			bool notOutgoing = true;
			for (int j = 0; j < outgoingWindows.Size(); j++)
			{
				// This window is getting deleted
				if (i == outgoingWindows[j])
				{
					notOutgoing = false;
					// Remove every reference from the global array
					removeOutgoingFromGlobal(winstack[i]);
					
					// Go find every window of lesser priority and decrease it's priority value by 1
					for (int k = winStack[i].Priority + 1; k < winStack.Size(); k++)
						GetWindowByPriority(k).Priority -= 1;
					break;
				}
			}
			
			// Window's not getting deleted.
			if (notOutgoing)
				newStack.Push(winStack[i]);
		}
		
		// Last step before the stack gets anhiliated - tell the windows getting deleted to delete themselves.
		for (int i = 0; i < outgoingWindows.Size(); i++)
			winStack[outgoingWindows[i]].bSelfDestroy = true;
		
		outgoingWindows.Clear();
		winStack.Clear();
		winStack.Move(newStack);
	}
	
	/*
		This is the second half of deletion.
		This method removes ZObjects from the global array
		and any incoming events.
	*/
	private void removeOutgoingFromGlobal(ZObjectBase zobj)
	{
		array<ZObjectBase> newGlobal;
		for (int i = 0; i < allZObjects.Size(); i++)
		{
			bool notOutgoing = true;
			if (allZObjects[i].Name ~== zobj.Name)
				notOutgoing = false;
			else if (zobj is "ZSWindow") // idk how this wouldn't be the case
			{
				for (int j = 0; j < ZSWindow(zobj).GetControlSize(); j++)
				{
					if (ZSWindow(zobj).GetControlByIndex(j) is "ZSWindow")
						removeOutgoingFromGlobal(ZSWindow(zobj).GetControlByIndex(j));
					else if (allZObjects[i].Name ~== ZSWindow(zobj).GetControlByIndex(j).Name)
					{
						notOutgoing = false;
						break;
					}
				}
			}
			
			if (!notOutgoing && incomingEvents.Size() > 0)
			{
				array<bool> deleteIndex;
				deleteIndex.Reserve(incomingEvents.Size());
				for (int j = 0; j < deleteIndex.Size(); j++)
					deleteIndex[j] = false;
				
				for (int j = 0; j < incomingEvents.Size(); j++)
				{
					if (incomingEvents[j].EventName ~== "zswin_ControlUpdate" && incomingEvents[j].FirstArg == i)
						deleteIndex[j] = true;
				}
				
				array<ZEventPacket> newPackets;
				for (int j = 0; j < deleteIndex.Size(); j++)
				{
					if (!deleteIndex[j])
						newPackets.Push(incomingEvents[j]);
				}
				incomingEvents.Clear();
				incomingEvents.Move(newPackets);
			}
			
			if (notOutgoing)
				newGlobal.Push(allZObjects[i]);
		}
		
		allZObjects.Clear();
		allZObjects.Move(newGlobal);
	}

    /* END OF DEFINITION */
}