/*

    ZSWin_Control_ControlUtil.zs

    This control is an internal control
    of windows and controls that are
    capable of containing an indeterminate
    number of other controls of various
    types, i.e. control lists like a window.

    This control provides that functionality
    to these ZObjects and is itself a ZControl.



    This control requires the following Event Overrides:
    - Tick
    - ZObj_UiProcess
    - ZObj_UiTick
    - ZObj_NetProcess
    - ObjectDraw
    - ControlEventCaller

*/

class ZControlUtil : ZControl
{
    private array<ZObjectBase> Controls;
	
	private int focusStackIndex;
	private bool ignoreFocusPostDuplicate;
	void PostControlFocusIndex(ZObjectBase control, bool Ignore = false) 
	{
		if (!ignoreFocusPostDuplicate)
		{
			focusStackIndex = GetControlIndex(control); 
			Controls[focusStackIndex].EventInvalidate();
			ignoreFocusPostDuplicate = Ignore;
		}
	}
	private void controlFocusSwitch()
	{
		for (int i = 0; i < Controls.Size(); i++)
		{
			if (Controls[i] is "ZControl")
				ZControl(Controls[i]).HasFocus = (focusStackIndex == i);
		}
		focusStackIndex = -1;
	}
	
	private int priorityStackIndex;
	private bool ignorePriorityPostDuplicate;
	void PostControlPriorityIndex(ZObjectBase control, bool Ignore = false)
	{
		if (!ignorePriorityPostDuplicate)
		{
			priorityStackIndex = GetControlIndex(control);
			Controls[priorityStackIndex].EventInvalidate();
			ignorePriorityPostDuplicate = Ignore;			
		}
	}
	private void controlPrioritySwitch()
	{
		if (Controls[priorityStackIndex].Priority > 0)
		{
			array<int> plist;
			for (int i = 0; i < Controls.Size(); i++)
			{
				if (i == priorityStackIndex)
					plist.Push(0);
				else if (Controls[i].Priority < Controls.Size() - 1)
					plist.Push(Controls[i].Priority + 1);
				else
					plist.Push(Controls[i].Priority);
			}
			
			if (plist.Size() == Controls.Size())
			{
				for (int i = 0; i < plist.Size(); i++)
					Controls[i].Priority = plist[i];
			}
		}
		
		priorityStackIndex = -1;
	}
	
	clearscope int GetControlSize() { return Controls.Size(); }
	clearscope int GetControlIndex(ZObjectBase zobj) { return Controls.Find(zobj); }
	clearscope ZObjectBase GetControlByIndex(int i) { return Controls[i]; }
	clearscope ZObjectBase GetControlByPriority(int p)
	{
		for (int i = 0; i < Controls.Size(); i++)
		{
			if (Controls[i].Priority == p)
				return Controls[i];
		}
		return null;
	}
	clearscope ZObjectBase GetControlByName(string n)
	{
		for (int i = 0; i < Controls.Size(); i++)
		{
			if (Controls[i].Name ~== n)
				return Controls[i];
		}		
		return null;
	}
	
	clearscope bool ControlNameIsUnique(string n)
	{
		for (int i = 0; i < Controls.Size(); i++)
		{
			if (Controls[i].Name ~== n)
				return false;
		}
		return true;
	}

	/*
		Creates a new control of the given class name.
		
		This is basically a wrapper for A_SpawnItemEx, therefore the entirety of
		that method's default args are supported.  Set UseParentLoc to false to
		specify custom offsets/velocities, etc.
		
		Note that flags and failchance do not transfer from the parent object.
		
		Keep in mind, these things effect the playism side of a ZObject, not the UI.
	
	*/
	bool, Actor AddControl (string controlName, bool useParentLoc = true, double xofs = 0, double yofs = 0, double zofs = 0, double xvel = 0, double yvel = 0, double zvel = 0, double angle = 0, int flags = 0, int failchance = 0, int tid = 0)
	{
		if (ZSHandlerUtil.ClassNameIsAClass(controlName))
		{
			bool spwned;
			actor control;
			[spwned, control] = A_SpawnItemEx(controlName,
								(self.pos.x * useParentLoc) + (xofs * !useParentLoc),
								(self.pos.y * useParentLoc) + (yofs * !useParentLoc),
								(self.pos.z * useParentLoc) + (zofs * !useParentLoc),
								(self.vel.x * useParentLoc) + (xvel * !useParentLoc),
								(self.vel.y * useParentLoc) + (yvel * !useParentLoc),
								(self.vel.z * useParentLoc) + (zvel * !useParentLoc),
								(self.angle * useParentLoc) + (angle * !useParentLoc),
								flags,
								failchance,
								(self.tid * useParentLoc) + (tid * !useParentLoc));
			if (spwned && control && control is "ZObjectBase")
			{
				if (ZObjectBase(control).Priority == 0)
					ZObjectBase(control).Priority = Controls.Size();
				Controls.Push(ZObjectBase(control));
				return spwned, control;
			}
			else
				return false, null;
		}
		else
			return false, null;
	}

	int AddExternalControl (ZObjectBase control)
	{
		if (control.Priority == 0)
			control.Priority = Controls.Size();
		Controls.Push(control);
		return control.Priority;
	}

    ZControlUtil Init(ZObjectBase ControlParent, bool Enabled, bool Show, string Name, int PlayerClient, bool UiToggle)
    {
		self.xLocation = ControlParent.xLocation;
		self.yLocation = ControlParent.yLocation;
		self.Width = ControlParent.Width;
		self.Height = ControlParent.Height;
		self.Alpha = ControlParent.Alpha;
		focusStackIndex = priorityStackIndex = -1;
        return ZControlUtil(super.Init(ControlParent, Enabled, Show, Name, PlayerClient, UiToggle));
    }

    override void Tick()
	{
		if (self.bSelfDestroy)
		{
			for (int i = 0; i < Controls.Size(); i++)
				Controls[i].bSelfDestroy = true;
		}
		
		super.Tick();
	}

    override bool ZObj_UiProcess(ZUIEventPacket e)
    {
        for (int i = 0; i < Controls.Size(); i++)
		{
			if (Controls[i].ZObj_UiProcess(e))
				return true;
		}

        return super.ZObj_UiProcess(e); 
    }

    override bool ZObj_UiTick()
    {
		// Control focusing
		if (focusStackIndex > -1)
			ZNetCommand(string.Format("ctrl_ControlToSetFocus,%s", self.Name), self.PlayerClient);
		// Priority switching
		if (priorityStackIndex > -1)
			ZNetCommand(string.Format("ctrl_ControlPrioritySwitch,%s", self.Name), self.PlayerClient);

        for (int i = 0; i < Controls.Size(); i++)
		{
			if (Controls[i].ZObj_UiTick())
				return true;
		}
        return super.ZObj_UiTick();
    }

    enum ZCTRLCMD
	{
		ZCTRLCMD_ControlFocus,
		ZCTRLCMD_ControlPrioritySwitch,
		ZCTRLCMD_TryString,
	};
	
	private ZCTRLCMD stringToControlUtilCommand(string e)
	{
		if (e ~== "ctrl_ControlToSetFocus")
			return ZCTRLCMD_ControlFocus;
		if (e ~== "ctrl_ControlPrioritySwitch")
			return ZCTRLCMD_ControlPrioritySwitch;
		else
			return ZCTRLCMD_TryString;
	}
	
	override bool ZObj_NetProcess(ZEventPacket e)
	{
		Array<string> cmdPlyr;
		e.EventName.Split(cmdPlyr, "?");
		if (cmdPlyr.Size() == 2 ? (cmdPlyr[1].ToInt() == self.PlayerClient) : false)
		{
			if (!e.Manual)
			{
				Array<string> cmdc;
				cmdPlyr[0].Split(cmdc, ":");
				for (int i = 0; i < cmdc.Size(); i++)
				{
					if (cmdc[i] != "")
					{
						Array<string> cmd;
						cmdc[i].Split(cmd, ",");
						if (cmd.Size() > 1 ? (cmd[1] ~== self.Name) : false)
						{
							switch(stringToControlUtilCommand(cmd[0]))
							{
								case ZCTRLCMD_ControlFocus:
									controlFocusSwitch();
									break;
								case ZCTRLCMD_ControlPrioritySwitch:
									controlPrioritySwitch();
									break;
								default:
								case ZCTRLCMD_TryString:
									break;
							}
						}
					}
				}
			}
		}
		
		for (int i = 0; i < Controls.Size(); i++)
		{
			if (Controls[i].ZObj_NetProcess(e))
				return true;
		}
		return super.ZObj_NetProcess(e);
	}

	override void ZObj_WorldTick()
	{
		for (int i = 0; i < Controls.Size(); i++)
			Controls[i].ZObj_WorldTick();
	}

	override void ZObj_WorldLinePreActivated(ZWorldEventPacket e)
	{
		for (int i = 0; i < Controls.Size(); i++)
			Controls[i].ZObj_WorldLinePreActivated(e);
	}

	override void ZObj_WorldLineActivated(ZWorldEventPacket e)
	{
		for (int i = 0; i < Controls.Size(); i++)
			Controls[i].ZObj_WorldLineActivated(e);
	}

    override void ObjectDraw(ZObjectBase parent)
    {
        for (int i = Controls.Size() - 1; i >= 0; i--)
        {
            let control = GetControlByPriority(i);
            if (control && control.PlayerClient == consoleplayer && control.Show)
                control.ObjectDraw(parent);
        }       
    }

    override void ControlEventCaller(int t)
    {
        for (int i = 0; i < Controls.Size(); i++)
		{
			Controls[i].ControlEventCaller(t);

			switch (t)
			{
				default:
				case ZUIEventPacket.EventType_None:
					Controls[i].WhileMouseIdle(t);
					break;
				case ZUIEventPacket.EventType_MouseMove:
					Controls[i].OnMouseMove(t);
					break;
				case ZUIEventPacket.EventType_LButtonDown:
					Controls[i].OnLeftMouseDown(t);
					break;
				case ZUIEventPacket.EventType_LButtonUp:
					Controls[i].OnLeftMouseUp(t);
					break;
				case ZUIEventPacket.EventType_LButtonClick:
					Controls[i].OnLeftMouseClick(t);
					break;
				case ZUIEventPacket.EventType_MButtonDown:
					Controls[i].OnMiddleMouseDown(t);
					break;
				case ZUIEventPacket.EventType_MButtonUp:
					Controls[i].OnMiddleMouseUp(t);
					break;
				case ZUIEventPacket.EventType_MButtonClick:
					Controls[i].OnMiddleMouseClick(t);
					break;
				case ZUIEventPacket.EventType_RButtonDown:
					Controls[i].OnRightMouseDown(t);
					break;
				case ZUIEventPacket.EventType_RButtonUp:
					Controls[i].OnRightMouseUp(t);
					break;
				case ZUIEventPacket.EventType_RButtonClick:
					Controls[i].OnRightMouseClick(t);
					break;
				case ZUIEventPacket.EventType_WheelUp:
					Controls[i].OnWheelMouseDown(t);
					break;
				case ZUIEventPacket.EventType_WheelDown:
					Controls[i].OnWheelMouseUp(t);
					break;
			}
		}
    }

    /* - END OF METHODS - */
}