/*

    ZSWES_0_Base.zs

    ZScript Windows v0.4.2 Event Handler Base Definition

    Sarah Blackburn
    10-03-2024
    DD-MM-YYYY

    This file defines the base event handler class.

*/

class ZEventSystem : ZSHandlerUtil
{	
    /*
        allZObjects and utility methods 
    */

	//This works like the engine's AllClasses array but is specific to ZObjects
	private array<ZObjectBase> allZObjects;
    // ZObjects are processed through an incoming array queue before being added to allZObjects
	private array<ZObjectBase> incomingZObjects;

    // Returns the size of the allZObjects array
	clearscope int GetSizeAllZObjects() { return allZObjects.Size(); }

    // Returns the index value of the given ZObject in the allZObjects array
	clearscope int GetIndexAllZObjects(ZObjectBase zobj) { return allZObjects.Find(zobj); }

    // Returns the ZObject at the given index in the allZObjects array
	clearscope ZObjectBase GetByIndexAllZObjects(int i) { if (i < allZObjects.Size()) return allZObjects[i]; else return null; }

    // Returns the ZObject with the given name in the allZObjects array
	clearscope ZObjectBase FindZObject(string n)
	{
		for (int i = 0; i < allZObjects.Size(); i++)
		{
			if (allZObjects[i] != null ? allZObjects[i].Name ~== n : false)
				return allZObjects[i];
		}

		return null;
	}

    /*
		Cursor packet - contains the cursor data
	*/
	private ZUIEventPacket cursor;
	
	/*
		Event packets - this is for events that need executed by UITick
	*/
	private array<ZEventPacket> incomingEvents;
	void AddEventPacket(string n, int fa, int sa, int ta) { incomingEvents.Push(new("ZEventPacket").Init(n, fa, sa, ta)); }
	private void clearUIEvents() { if (incomingEvents.Size() > 0) incomingEvents.Clear(); }

	/*
		Event Data Packets
	*/
	private array<EventDataPacket> eventData;
	/*
		This is a direct access method to push an EventDataPacket
		to the array.

		This works similar to the process in NetProcess, but is
		without a net command.

		You only use this if you have to AND this must be a global
		call to all event handlers otherwise you can/will cause desyncs.

	*/
	void PushEventDataPacket(string fmt_Data, int evtyp)
	{
		EventDataPacket evdp = new("EventDataPacket").Init(evtyp);
		array<string> evdl;
		fmt_Data.Split(evdl, ",");
		if (evdp && evdl.Size() > 0)
		{
			for (int i = 0; i < evdl.Size(); i++)
			{
				array<string> evd;
				evdl[i].Split(evd, "|");
				if (evd.Size() == 2)
					evdp.Nodes.Push(new("DataNode").Init(evd[0], DataNode.stringToDataType(evd[1])));
			}

			eventData.Push(evdp);
		}
	}
	
	/*
		Window stack and related components
	*/
	private array<ZObjectBase> incomingWindows;
	private array<ZObjectBase> winStack;
	private int priorityStackIndex;
	private bool ignorePostDuplicate;
	private array<int> outgoingWindows;
	
	/*
		Get methods for accessing the stack
	*/
	clearscope int GetStackSize() { return winStack.Size(); }
	clearscope int GetStackIndex (ZObjectBase zobj) { return winStack.Find(zobj); }
	clearscope ZObjectBase GetWindowByIndex(int i) { return winStack[i]; }
	clearscope ZObjectBase GetWindowByPriority (int p)
	{
		for (int i = 0; i < winStack.Size(); i++)
		{
			if (winStack[i].Priority == p)
				return winStack[i];
		}
		return null;
	}
	clearscope ZObjectBase GetWindowByName(string n)
	{
		for (int i = 0; i < winStack.Size(); i++)
		{
			if (winStack[i].Name ~== n)
				return winStack[i];
		}
		return null;
	}

	/*
		Searches the allZObjects array to check if
		any object has the same name.  Returns false
		if it finds an object with the same name,
		true otherwise.

		Because this method is static, it must be provided with the array to search
	*/
	clearscope static bool GlobalNameIsUnique(array<ZObjectBase> allZObjects, string n)
	{
		for (int i = 0; i < allZObjects.Size(); i++)
		{
			if (allZObjects[i].Name.MakeLower() ~== n.MakeLower())
				return false;
		}
		return true;
	}
	
	/*
		QuikClose Input Nullifier
		
		This is set to true when a control needs MOST of the keyboard for input,
		like text boxes, so only the Esc key will toggle UI mode.
		
		This is set only through a net command.
	*/
	private bool bNiceQuikClose;
	private void quikCloseInputRangeLimit(bool limit) { bNiceQuikClose = limit; }

    /* END OF DEFINITION */
}