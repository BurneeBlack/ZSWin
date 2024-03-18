/*

    ZSWES_2_Native.zs

    ZScript Windows v0.4.2 Event Handler Native Class Extension

    Sarah Blackburn
    10-03-2024
    DD-MM-YYYY

    This file extends the event handler class to contain
    native method overrides.

*/

extend class ZEventSystem
{
    /*
		First-time setup
		
	*/
	override void OnRegister()
	{
		// Get the lowest unused order value
		SetOrder(GetLowestPossibleOrder());

		// Say hello the game world
		console.printf(string.format("ZScript Windows v%s - Window Event System Registered with Order %d for Player #%d - Welcome!", ZSHandlerUtil.ZVERSION, self.Order, consoleplayer));
		
		// If this isn't -1 stuff thinks there's stuff going on, 0 is a valid stack index
		priorityStackIndex = -1;

		// Interactions from players can (more like will) take more than one tick to complete.
		// This means events will be executed multiple times if there is not a lockout mechanism.
		ignorePostDuplicate = false;

		// This is the switch that makes QuikClose only react to the Esc key
		bNiceQuikClose = false;

		// Information about the cursor is stored in a ZUIEventPacket - this is just and empty default
		cursor = new("ZUIEventPacket").Init(0, 0, "", 0, 0, 0, false, false, false);

		super.OnRegister();
	}
	
	/*
		Window Drawer - Remember! This is called multiple times per tick
		and always after UiTick!
	
	*/
	override void RenderOverlay(RenderEvent e)
	{
		for (int i = winStack.Size() - 1; i >= 0; i--)
		{
			let nwd = GetWindowByPriority(i);
			if (nwd && nwd.PlayerClient == consoleplayer && nwd.Show && !nwd.bSelfDestroy)
				nwd.ObjectDraw(winStack[i]);
		}

		super.RenderOverlay(e);
	}
	
	/*
		Receives input events when the handler is in UI Mode
	
	*/
	override bool UiProcess(UiEvent e)
	{
		// Handler Events - This is anything specific the handler needs to do based on an input.
		switch (e.Type)
		{
			case UiEvent.Type_None:			
				break;
			case UiEvent.Type_KeyDown:
				// This results in a NetworkProcess_String call where the QuikClose check is processed
				// KeyString is used to check various binds, KeyChar is used to check specific keys (Esc and tilde)
				zEventCommand(string.Format("zevsys_QuikCloseCheck,%s", e.KeyString), consoleplayer, e.KeyChar);
				break;
			case UiEvent.Type_KeyRepeat:
				break;
			case UiEvent.Type_KeyUp:
				// Check if the key is the bind for the cursor toggle
				if (!bNiceQuikClose && KeyBindings.NameKeys(Bindings.GetKeysForCommand("zswin_cmd_cursorToggle"), 0) ~== e.KeyString)
					zEventCommand("zevsys_UI_CursorToggle", consoleplayer);
				break;
			case UiEvent.Type_Char:
			case UiEvent.Type_MouseMove:
			case UiEvent.Type_LButtonDown:
			case UiEvent.Type_LButtonUp:
			case UiEvent.Type_LButtonClick:
			case UiEvent.Type_MButtonDown:
			case UiEvent.Type_MButtonUp:
			case UiEvent.Type_MButtonClick:
			case UiEvent.Type_RButtonDown:
			case UiEvent.Type_RButtonUp:
			case UiEvent.Type_RButtonClick:
			case UiEvent.Type_WheelUp:
			case UiEvent.Type_WheelDown:
			default:
				// No error here - just got First/Last Mouse Event - what even are those?
				break;
		}
		
		for (int i = 0; i < winStack.Size(); i++)
		{
			if (winStack[i].PlayerClient == consoleplayer)
			{
				//console.printf(string.format("Event System got key string, %s (%d), shift is, %s", e.KeyString, e.KeyChar, e.IsShift ? "true" : "false"));
				if (winStack[i].ZObj_UiProcess(new("ZUIEventPacket").Init(e.Type, consoleplayer, e.KeyString, e.KeyChar, e.MouseX, e.MouseY, e.IsShift, e.IsAlt, e.IsCtrl)))
					break;
			}
		}
		
		zEventCommand(string.Format("zevsys_UpdateCursorData,%d,%d,%s,%d,%d,%d", e.Type, consoleplayer, e.KeyString, e.KeyChar, e.MouseX, e.MouseY), e.IsShift, e.IsAlt, e.IsCtrl);
		return super.UiProcess(e);
	}
	
	/*
		Window Driver - Remember! This is called only once per game tick,
		always before RenderOverlay, and is how any window maninpulation happens!
	
	*/
	override void UiTick()
	{
		// Call Window Events
		zEventCommand("zevsys_CallWindowEvents", consoleplayer);
		
		// Deletion
		if (outgoingWindows.Size() > 0)
			zEventCommand("zevsys_DeleteOutgoingWindows", consoleplayer);
		// Priority
		if (priorityStackIndex != -1 && incomingWindows.Size() == 0)
			zEventCommand("zevsys_PrioritySwitch", consoleplayer);
		// Incoming
		if (incomingWindows.Size() > 0)
			zEventCommand("zevsys_AddIncomingToStack", consoleplayer);
		// All objects get added to the global arrays
		if (incomingZObjects.Size() > 0)
			zEventCommand("zevsys_AddObjectToGlobalObjects", consoleplayer);
		
		// Incoming events from the last tick - this would be events send from UI scoped methods
		if (incomingEvents.Size() > 0)
		{
			for (int i = 0; i < incomingEvents.Size(); i++)
				zEventCommand(incomingEvents[i].EventName, consoleplayer, incomingEvents[i].FirstArg, incomingEvents[i].SecondArg, incomingEvents[i].ThirdArg);
			zEventCommand("zevsys_ClearIncomingUIEvents", consoleplayer);
		}
		
		// Call the window UiTick - this is done last, all other things should be done so
		// this should be a safe place for windows to do their thing.
		for (int i = 0; i < winStack.Size(); i++)
		{
			if (winStack[i].PlayerClient == consoleplayer)
			{
				if(winStack[i].ZObj_UiTick())
					break;
			}
		}

		super.UiTick();
	}
	
	/*
		Receives input when the handler is not in UI Mode
	
	*/
	override bool InputProcess(InputEvent e)
	{
		if (e.Type == InputEvent.Type_KeyUp && keyIsCursorBind(e.KeyScan))
			zEventCommand("zevsys_CursorToggle", consoleplayer);
		return super.InputProcess(e);
	}
	
	/*
		Communication server - anything going between scopes passes through here
	
	*/
	enum ZNETCMD
	{
		ZNCMD_AddIncoming,
		ZNCMD_PrioritySwitch,
		ZNCMD_UpdateCursorData,
		ZNCMD_ClearUIIncoming,
		ZNCMD_QuickCloseCheck,
		ZNCMD_CursorToggle,
		ZNCMD_CallWindowEvents,
		ZNCMD_DeleteOutgoingWindows,
		ZNCMD_AddObjectToGlobalObjects,
		
		ZNCMD_HandlerIncomingGlobal,		
		ZNCMD_AddToUITicker,
		ZNCMD_SetWindowForDestruction,
		ZNCMD_PostStackIndex,
		ZNCMD_AddWindowToStack,
		ZNCMD_ControlFullInput,
		ZNCMD_CallACS,
		ZNCMD_TakeInventory,
		ZNCMD_GiveInventory,
		ZNCMD_DropInventoryAtSpot,
		ZNCMD_CreateEventDataPacket,
		ZNCMD_TimerTickOutEvent,

		ZNCMD_ControlUpdate,
		ZNCMD_LetAllPost,
		
		ZNCMD_ManualStackSizeOut,
		ZNCMD_ManualStackPriorityOut,
		ZNCMD_ManualGlobalZObjectCount,
		ZNCMD_ManualEventGlobalCount,
		ZNCMD_ManualGlobalNamePrint,

		ZNCMD_ManualHCF,
		
		ZNCMD_TryString,
	};
	
	/*
		Converts a string to a ZNETCMD
	*/
	private ZNETCMD stringToZNetworkCommand(string e)
	{
		// Internal commands - these are sent from within the Event System
		if (e ~== "zevsys_AddIncomingToStack")
			return ZNCMD_AddIncoming;
		if (e ~== "zevsys_PrioritySwitch")
			return ZNCMD_PrioritySwitch;
		if (e ~== "zevsys_UpdateCursorData")
			return ZNCMD_UpdateCursorData;
		if (e ~== "zevsys_ClearIncomingUIEvents")
			return ZNCMD_ClearUIIncoming;
		if (e ~== "zevsys_QuikCloseCheck")
			return ZNCMD_QuickCloseCheck;
		if (e ~== "zevsys_UI_CursorToggle" || e ~== "zevsys_CursorToggle")
			return ZNCMD_CursorToggle;
		if (e ~== "zevsys_CallWindowEvents")
			return ZNCMD_CallWindowEvents;
		if (e ~== "zevsys_DeleteOutgoingWindows")
			return ZNCMD_DeleteOutgoingWindows;
		if (e ~== "zevsys_AddObjectToGlobalObjects")
			return ZNCMD_AddObjectToGlobalObjects;

		// External Commands - these are sent from ZObjects
		if (e ~== "zevsys_AlertHandlersToNewGlobal")
			return ZNCMD_HandlerIncomingGlobal;
		if (e ~== "zevsys_AddToUITicker")
			return ZNCMD_AddToUITicker;
		if (e ~== "zevsys_SetWindowForDestruction")
			return ZNCMD_SetWindowForDestruction;
		if (e ~== "zevsys_PostPriorityIndex")
			return ZNCMD_PostStackIndex;
		if (e ~== "zevsys_AddWindowToStack")
			return ZNCMD_AddWindowToStack;
		if (e ~== "zevsys_ControlFullInput")
			return ZNCMD_ControlFullInput;
		if (e ~== "zevsys_CallACS")
			return ZNCMD_CallACS;
		if (e ~== "zevsys_TakePlayerInventory")
			return ZNCMD_TakeInventory;
		if (e ~== "zevsys_GivePlayerInventory")
			return ZNCMD_GiveInventory;
		if (e ~== "zevsys_DropInventoryAtSpot")
			return ZNCMD_DropInventoryAtSpot;
		if (e ~== "zevsys_CreateEventDataPacket")
			return ZNCMD_CreateEventDataPacket;
		if (e ~== "zevsys_TimerTickOutEvent")
			return ZNCMD_TimerTickOutEvent;
		
		if (e ~== "zobj_ControlUpdate")
			return ZNCMD_ControlUpdate;
		if (e ~== "zobj_LetAllPost")
			return ZNCMD_LetAllPost;
		
		// Manual Commands
		if (e ~== "zswin_stacksizeout")
			return ZNCMD_ManualStackSizeOut;
		if (e ~== "zswin_stackpriorityout")
			return ZNCMD_ManualStackPriorityOut;
		if (e ~== "zswin_globalobjectcount")
			return ZNCMD_ManualGlobalZObjectCount;
		if (e ~== "zswin_eventglobalcount")
			return ZNCMD_ManualEventGlobalCount;
		if (e ~== "zswin_printallnames")
			return ZNCMD_ManualGlobalNamePrint;
		if (e ~== "zswin_hcf")
			return ZNCMD_ManualHCF;
		// All else fails, try to string process the command
		else
			return ZNCMD_TryString;
	}
	
	/*
		EVENT COMMAND FORMATTING
		
		ZScript Windows reserves the following characters for
		formatted command strings:
		
		? : ,
		
		Question Mark Usage
		 - This character is reserved exclusively for internal use.
		 - This character separates the command string from the player client
		 
		Colon Usage
		 - This character separates individual commands
		 
		Comma Usage
		 - This character separates commands and arguments
		 
		Example
		
		zcmd_CommandA,data_argX:zcmd_CommandB,data_argY?playerClient
		
		Command Processing Logic:
		-------------------------
		Step 1 - NetworkProcess
			- Try to split the command string into the command and the player ID
			- If that succeeds and the player ID is the same as the consoleplayer,
			  attempt to figure out what the command is.
			- Simple commands are processed here that don't require further processing.
		Step 2 - NetworkProcess_String
			- If command conversion returns TryString, the entire ConsoleEvent is passed
			  along and the process restarts.
			- Assuming the command is for a valid player, the string processing of the
			  command functions as follows:
					1 - Split the string with a colon (:) as a delimiter.  These strings
					    are treated as individual commands, possibly with arguments.
					2 - Execute each command sequentially.  Attempt to split each command
					    string with a comma (,) as a delimiter.  The first string in the
						array is treated as the command, and all others as arguments.
		Step 3 - ZObject Event Extension
			- Regardless of what occurred in the previous steps, the entire contents of
			  ConsoleEvent data is replicated and passed to valid ZObjects, in this case
			  ZSWindows, through ZEventPackets.
			- Command processing at this stage is at the discretion of the control.
			
			
		Command Specifics:
		------------------
		AddToUITicker - This command will create an event packet to be processed by the UITicker
						event of the Event Systetm, containing a second command and arguments,
						to be executed by the net command system.
					  - Command follows the standard command format.
					  - Example: this command will add "zobj_ControlUpdate" and the ZObject's name to the command queue.
							ZNetCommand(string.Format("zevsys_AddToUITicker,zobj_ControlUpdate,%s", self.Name));
							
	*/
	clearscope private void zEventCommand(string cmd, int plyr_id, int arg_a = 0, int arg_b = 0, int arg_c = 0)
	{
		SendNetworkEvent(string.Format("%s?%d", cmd, plyr_id), arg_a, arg_b, arg_c);
	}
	
	/*
		Main context communication method
	*/
	override void NetworkProcess(ConsoleEvent e)
	{
		//console.printf(string.format("ZEvent System got command string: %s", e.Name));
		Array<string> cmdc;
		e.Name.Split(cmdc, "?");		
		if (cmdc.Size() == 2 ? (cmdc[1].ToInt() == consoleplayer) : false)
		{
			if (!e.IsManual)  // there's no reason any of these events should ever be manually called
			{
				switch (stringToZNetworkCommand(cmdc[0]))
				{
					case ZNCMD_AddIncoming:
						passIncomingToStack();
						break;
					case ZNCMD_PrioritySwitch:
						windowPrioritySwitch();
						break;
					case ZNCMD_ClearUIIncoming:
						clearUIEvents();
						break;
					case ZNCMD_CursorToggle:
						cursorToggle();
						break;
					case ZNCMD_CallWindowEvents:
						windowEventCaller();
						break;
					case ZNCMD_DeleteOutgoingWindows:
						deleteOutgoingWindows();
						break;
					case ZNCMD_AddObjectToGlobalObjects:
						passIncomingToGlobalObjects();
						break;
					case ZNCMD_ControlFullInput:
						quikCloseInputRangeLimit(e.Args[0]);
						break;
					case ZNCMD_LetAllPost:
						letAllPost();
						break;
					// String Processing
					default:
						NetworkProcess_String(e);
						break;
				}
			}
		}
		else if (e.IsManual) // These may be called manualy - mostly debugging stuff
		{
			switch (stringToZNetworkCommand(e.Name))
			{
				case ZNCMD_ManualStackSizeOut:
					debugStackSizeToConsole();
					break;
				case ZNCMD_ManualStackPriorityOut:
					debugStackPriorityToConsole();
					break;
				case ZNCMD_ManualGlobalZObjectCount:
					debugGetGlobalObjectCount();
					break;
				case ZNCMD_ManualEventGlobalCount:
					debugGetEventGlobalCount();
					break;
				case ZNCMD_ManualGlobalNamePrint:
					debugPrintOutEveryName();
					break;
				case ZNCMD_ManualHCF:
					HaltAndCatchFire(self, "Manual VM abort called.  Um...why?  IDK, you called for it.");
					break;
			}
		}
		// These are a select few commands that will be sent normally - i.e. they are global commands.
		else
		{
			if (!e.IsManual)
			{
				Array<string> cmde;
				e.Name.Split(cmde, ":");
				for (int i = 0; i < cmde.Size(); i++)
				{
					if (cmde[i] != "")
					{
						Array<string> cmd;
						cmde[i].Split(cmd, ",");
						if (cmd.Size() > 0)
						{
							switch (stringToZNetworkCommand(cmd[0]))
							{
								case ZNCMD_SetWindowForDestruction:
									if (cmd.Size() == 2)
										setWindowForDestruction(cmd[1]);
									else
										console.printf("Invalid attempt to set window for destruction!");
									break;
								case ZNCMD_AddWindowToStack:
									if (cmd.Size() == 2)
										addWindowToStack(cmd[1]);
									else
										console.printf("Invalid attempt to add window to stack!");
									break;
								case ZNCMD_CallACS:
									if (cmd.Size() == 2)
										players[consoleplayer].mo.ACS_ScriptCall(cmd[1], e.Args[0], e.Args[1], e.Args[2]);
									else
										console.printf("Call to activate script received no script name!");
									break;
								case ZNCMD_TakeInventory:
									if (cmd.Size() == 3)
									{
										players[e.Args[0]].mo.SetInventory(cmd[1], e.Args[1]);
										if (e.Args[2] > 0)
											GetWindowByName(cmd[2]).SetInventory(cmd[1], e.Args[2]);
									}
									else
										console.Printf("Invalid attempt to take from player inventory!");
									break;
								case ZNCMD_GiveInventory:
									if (cmd.Size() == 2)
										players[e.Args[0]].mo.SetInventory(cmd[1], e.Args[1]);
									else
										console.Printf("Can't give the player nothing!");
									break;
								case ZNCMD_DropInventoryAtSpot:
									if (cmd.Size() == 2)
										dropItemAtSpot(cmd[1], e.Args[0], e.Args[1], e.Args[2]);
									else if (cmd.Size() == 3)
										dropItemAtSpot(cmd[1], e.Args[0], e.Args[1], e.Args[2], cmd[2]);
									else
										console.Printf("Can't drop nothing!");
									break;
							}
						}
					}
				}
			}
			else {}
		}
		
		for (int i = 0; i < winStack.Size(); i++)
		{
			if (winStack[i].PlayerClient == consoleplayer)
			{
				//console.printf(string.format("Sending to window command string: %s", e.Name));
				if (winStack[i].ZObj_NetProcess(new("ZEventPacket").Init(e.Name, e.Args[0], e.Args[1], e.Args[2], e.Player, e.IsManual)))
					break;
			}
		}

		super.NetworkProcess(e);
	}
	
	/*
		Processing for more complicated net events that 
		send information through their name
	*/
	private void NetworkProcess_String(ConsoleEvent e)
	{
		Array<string> cmdPlyr;
		e.Name.Split(cmdPlyr, "?");
		if (cmdPlyr.Size() == 2 ? (cmdPlyr[1].ToInt() == consoleplayer) : false)
		{
			Array<string> cmdc;
			cmdPlyr[0].Split(cmdc, ":");
			for (int i = 0; i < cmdc.Size(); i++)
			{
				if (cmdc[i] != "")
				{
					Array<string> cmd;
					cmdc[i].Split(cmd, ",");
					if (cmd.Size() > 0)
					{
						switch (stringToZNetworkCommand(cmd[0]))
						{
						case ZNCMD_UpdateCursorData:
							if (cmd.Size() != 7)
								console.printf(string.format("Update Cursor from Event System received %d args!", cmd.Size()));
							else
								updateCursorData(cmd[1].ToInt(), cmd[2].ToInt(), cmd[3], cmd[4].ToInt(), cmd[5].ToInt(), cmd[6].ToInt(), e.Args[0], e.Args[1], e.Args[2]);
							break;
						case ZNCMD_AddToUITicker:
							// Instead of having some special format for this command
							// this just jams the string back together to create the
							// event name.
							if (cmd.Size() >= 2)
							{
								string addCmd = cmd[1];
								bool addPkt = true;
								int cmdArgs = 0;
								if (cmd.Size() > 2)
								{
									for (cmdArgs = 2; cmdArgs < cmd.Size(); cmdArgs++)
									{
										if (cmd[cmdArgs] != "")
											addCmd.AppendFormat(",%s", cmd[cmdArgs]);
										else
										{
											addPkt = false;
											break;
										}
									}
								}
								if (addPkt)
									AddEventPacket(addCmd, e.Args[0], e.Args[1], e.Args[2]);
								else
									console.printf(string.Format("Add To UI Ticker got an empty argument adding \"%s\" at index, %d", addcmd, cmdArgs));
							}
							break;
						case ZNCMD_QuickCloseCheck:
							if (cmd.Size() == 2)
								quickCloseCheck(cmd[1], e.Args[0]);
							else
								console.printf("Quik Close Check did not get a valid key string!");
							break;
						case ZNCMD_ControlUpdate:
							if (cmd.Size() == 2)
								controlUpdateEvent(cmd[1]);
							else
								console.printf("Control Update did not get a valid control name!");
							break;
						case ZNCMD_PostStackIndex:
							if (cmd.Size() == 2)
								postPriorityIndex(cmd[1], e.Args[0]);
							else
								console.printf("Post Stack Index did not get a valid window name!");
							break;
						case ZNCMD_HandlerIncomingGlobal:
							if (cmd.Size() == 2)
								addObjectToGlobalObjects(cmd[1]);
							else
								console.printf("Invalid attempt to add ZObject to globals!");
							break;
						case ZNCMD_CreateEventDataPacket:
							/*
								command format is: zevsys_CreateEventDataPacket,data|type,...?consoleplayer
								Args[0] = event type
							*/
							if (cmd.Size() > 1) // Is there more than just the command?
							{
								EventDataPacket evdp = new("EventDataPacket").Init(e.Args[0]);
								if (evdp)
								{
									console.printf(string.format("cmd size is %d", cmd.Size()));
									for (int i = 1; i < cmd.Size(); i++)
									{
										array<string> evd;
										cmd[i].Split(evd, "|");
										if (evd.Size() == 2) // Theres data, and a type
											evdp.Nodes.Push(new("DataNode").Init(evd[0], DataNode.stringToDataType(evd[1])));
									}

									eventData.Push(evdp);
								}
							}
							else
								console.printf("No data for event data packet!");
							break;
						case ZNCMD_TimerTickOutEvent:
							if (cmd.Size() == 2)
								ZTimer(FindZObject(cmd[1])).TimerEvent();
							break;
						default:
							/* debug out if it's on, otherwise this net command probably came from something else */
							break;
						}
					}
					else { /* probably smart to hcf here, becuz what now?  there's some fuckery here. just no, you broke it or something. */}
				}
			}
		}
	}

	/*
		This really only exists in order to take as
		much of the work off of the user when using
		the ZConversation.

		When something dies, if it is a ZSWindow (a NPC),
		this event will look for an EventDataPacket flagged
		for this event.  If it finds one, it treats it as
		information about what the NPC should drop and
		how many to drop.

		WHAT ARE EVENT DATA PACKETS?
			A generic packet.  They may be processed by
			any of the Event System methods, for any
			defined purpose.  However it is up to the
			event that processes the packet to ensure
			the contents of the array is maintained.
	*/
	override void WorldThingDied (WorldEvent e)
	{
		if (e.Thing is "ZSWindow" && eventData.Size() > 0)
		{
			for (int i = 0; i < eventData.Size(); i++)
			{
				if (eventData[i].Event == EventDataPacket.EVTYP_WorldThingDied && eventData[i].Nodes.Size() > 0)
				{	// Should be 2 things - what to drop, and how many
					string whatToDrop = "";
					int howMuchToDrop = 0;
					for (int k = 0; k < eventData[i].Nodes.Size(); k++)
					{
						switch(eventData[i].Nodes[k].Type)
						{
							case DataNode.DTYPE_int:
								howMuchToDrop = eventData[i].Nodes[k].Data.ToInt();
								break;
							case DataNode.DTYPE_string:
								whatToDrop = eventData[i].Nodes[k].Data;
								break;
							default:	// invalid type
								console.Printf(string.Format("ZScript Windows - ERROR! - WorldThingDied got invalid node type, %d!  Drop failed!", eventData[i].Nodes[k].Type));
								break;
						}
					}	
					
					if (whatToDrop != "" && howMuchToDrop > 0)
					{
						for (int k = 0; k < howMuchToDrop; k++)
							e.Thing.A_DropItem(whatToDrop, howMuchToDrop);
					}
				}
			}

			/*
				Whatever event processes the given packet
				is responsible for getting rid of it.

				We aren't going to use delete, instead
				we'll copy from array to array and use clear
				like everything else.

			*/
			array<EventDataPacket> curpkts;
			for (int i = 0; i < eventData.Size(); i++)
			{
				if (eventData[i].Event != EventDataPacket.EVTYP_WorldThingDied)
					curpkts.Push(eventData[i]);
			}
			eventData.Clear();
			for (int i = 0; i < curpkts.Size(); i++)
				eventData.Push(curpkts[i]);

			//console.printf(string.Format("Event Data contains %d packets", eventData.Size()));
		}
		super.WorldThingDied(e);
	}

	override void WorldTick()
	{
		for (int i = 0; i < winStack.Size(); i++)
		{
			if (winStack[i].PlayerClient == consoleplayer)
				winStack[i].ZObj_WorldTick();
		}

		super.WorldTick();
	}

	override void WorldLinePreActivated(WorldEvent e)
	{
		for (int i = 0; i < winStack.Size(); i++)
		{
			if (winStack[i].PlayerClient == consoleplayer)
				winStack[i].ZObj_WorldLinePreActivated(new("ZWorldEventPacket").Init(e.Thing, e.ActivatedLine, e.ActivationType, e.ShouldActivate));
		}

		super.WorldLinePreActivated(e);
	}

	override void WorldLineActivated(WorldEvent e)
	{
		for (int i = 0; i < winStack.Size(); i++)
		{
			if (winStack[i].PlayerClient == consoleplayer)
				winStack[i].ZObj_WorldLineActivated(new("ZWorldEventPacket").Init(e.Thing, e.ActivatedLine, e.ActivationType));
		}

		super.WorldLineActivated(e);
	}

    /* END OF DEFINITION */
}