/*
	ZSWin_Object_Window.zs
	
	Window Base Class Definition
	
	This is the container for all other objects

*/

class ZSWindow : ZObjectBase abstract
{
	/*
		These are just some defaults
	*/
	const DEFLOC_X = 100;
	const DEFLOC_Y = 50;
	const DISABLEDALPHA = 0.5;
	
	/*
		Cursor
	*/
	int CursorX, CursorY;
	
	/*
		Movement
	*/
	private int lockedMoveCursorX, lockedMoveCursorY;
	bool IsMoveLocked() { return (lockedMoveCursorX > -1 && lockedMoveCursorY > -1); }
	void LockMoveCursorOrigin() 
	{
		lockedMoveCursorX = CursorX;
		lockedMoveCursorY = CursorY; 
	}
	void MoveAccumulate()
	{
		int diffx, diffy;
		[diffx, diffy] = MoveDifference();
		moveAccumulateX += diffx;
		moveAccumulateY += diffy;
		lockedMoveCursorX = lockedMoveCursorY = -1;
	}
	int moveAccumulateX, moveAccumulateY;
	clearscope int, int MoveDifference()
	{
		if (lockedMoveCursorX > -1 && lockedMoveCursorY > -1)
			return CursorX - lockedMoveCursorX, CursorY - lockedMoveCursorY;
		else
			return 0, 0;
	}
	
	/*
		Scaling
	*/
	private int lockedScaleCursorX, lockedScaleCursorY;
	bool IsScaleLocked() { return (lockedScaleCursorX > -1 && lockedScaleCursorY > -1); }
	void LockScaleCursorOrigin() 
	{ 
		lockedScaleCursorX = CursorX;
		lockedScaleCursorY = CursorY; 
	}
	void ScaleAccumulate()
	{
		int diffx, diffy;
		[diffx, diffy] = ScaleDifference();
		scaleAccumulateX += diffx;
		scaleAccumulateY += diffy;
		lockedScaleCursorX = lockedScaleCursorY = -1;
	}
	int scaleAccumulateX, scaleAccumulateY;
	clearscope int, int ScaleDifference()
	{
		if (lockedScaleCursorX > -1 && lockedScaleCursorY > -1)
			return CursorX - lockedScaleCursorX, CursorY - lockedScaleCursorY;
		else
			return 0, 0;
	}
	
	/*
		Backgrounds and borders work a lot like Tooltips.  Based on the game, the system
		can select which background and border to use, or use custom options defined by the
		window.
	
	*/
	// Background
	enum BACKTYP
	{
		BACKTYP_GameTex1,
		BACKTYP_GameTex2,
		BACKTYP_GameTex3,
		BACKTYP_ZWin,
		BACKTYP_Custom,
		BACKTYP_NONE,
	};
	BACKTYP BackgroundType;
	float BackgroundAlpha;
	bool BackgroundStretch, AnimateBackground;
	TextureId BackgroundTexture;
	
	// Border
	enum BORDERTYP
	{
		BORDERTYP_Game,
		BORDERTYP_Line,
		BORDERTYP_ThickLine,
		BORDERTYP_ZWin,
		BORDERTYP_NONE,
	};
	BORDERTYP BorderType;
	color BorderColor;
	float BorderThickness,
		BorderAlpha;		
	ZBorder BorderGraphics;
	
	//
	// Controls
	//
	private array<ZObjectBase> windowControls;
	
	private int focusStackIndex;
	private bool ignoreFocusPostDuplicate;
	void PostControlFocusIndex(ZObjectBase control, bool Ignore = false) 
	{
		if (!ignoreFocusPostDuplicate)
		{
			focusStackIndex = GetControlIndex(control); 
			windowControls[focusStackIndex].EventInvalidate();
			ignoreFocusPostDuplicate = Ignore;
		}
	}
	private void controlFocusSwitch()
	{
		for (int i = 0; i < windowControls.Size(); i++)
		{
			if (windowControls[i] is "ZControl")
				ZControl(windowControls[i]).HasFocus = (focusStackIndex == i);
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
			windowControls[priorityStackIndex].EventInvalidate();
			ignorePriorityPostDuplicate = Ignore;			
		}
	}
	private void controlPrioritySwitch()
	{
		if (windowControls[priorityStackIndex].Priority > 0)
		{
			array<int> plist;
			for (int i = 0; i < windowControls.Size(); i++)
			{
				if (i == priorityStackIndex)
					plist.Push(0);
				else if (windowControls[i].Priority < windowControls.Size() - 1)
					plist.Push(windowControls[i].Priority + 1);
				else
					plist.Push(windowControls[i].Priority);
			}
			
			if (plist.Size() == windowControls.Size())
			{
				for (int i = 0; i < plist.Size(); i++)
					windowControls[i].Priority = plist[i];
			}
		}
		
		priorityStackIndex = -1;
	}
	
	clearscope int GetControlSize() { return windowControls.Size(); }
	clearscope int GetControlIndex(ZObjectBase zobj) { return windowControls.Find(zobj); }
	clearscope ZObjectBase GetControlByIndex(int i) { return windowControls[i]; }
	clearscope ZObjectBase GetControlByPriority(int p)
	{
		for (int i = 0; i < windowControls.Size(); i++)
		{
			if (windowControls[i].Priority == p)
				return windowControls[i];
		}
		return null;
	}
	clearscope ZObjectBase GetControlByName(string n)
	{
		for (int i = 0; i < windowControls.Size(); i++)
		{
			if (windowControls[i].Name ~== n)
				return windowControls[i];
		}		
		return null;
	}
	
	clearscope bool ControlNameIsUnique(string n)
	{
		for (int i = 0; i < windowControls.Size(); i++)
		{
			if (windowControls[i].Name ~== n)
				return false;
		}
		return true;
	}
	
	private bool block_bSelfDestroy;

	void Close(bool closeParent = true)
	{
		if (!bSelfDestroy && !block_bSelfDestroy)
		{
			if (closeParent)
			{
				if (self.ControlParent)
				{
					ZObjectBase zobj = self.ControlParent;
					while (zobj.ControlParent)
						zobj = zobj.ControlParent;

					EventHandler.SendNetworkEvent(string.Format("zevsys_SetWindowForDestruction,%s", zobj.Name));
					block_bSelfDestroy = true;
				}
				else
				{
					EventHandler.SendNetworkEvent(string.Format("zevsys_SetWindowForDestruction,%s", self.Name));
					block_bSelfDestroy = true;
				}
			}
			else
			{
				EventHandler.SendNetworkEvent(string.Format("zevsys_SetWindowForDestruction,%s", self.Name));
				block_bSelfDestroy = true;
			}
		}
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
					ZObjectBase(control).Priority = windowControls.Size();
				windowControls.Push(ZObjectBase(control));
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
			control.Priority = windowControls.Size();
		windowControls.Push(control);
		return control.Priority;
	}
	
	/*
		Takes the width and heigh of the window and returns
		an X/Y location that will center the window on the screen.
	
	*/
	float, float WindowLocation_ScreenCenter()
	{
		return float((Screen.GetWidth() - Width) / 2), float((Screen.GetHeight() - Height) / 2);
	}
	
	/*
		Returns the default X/Y locations
	
	*/
	float, float WindowLocation_Default()
	{
		return DEFLOC_X, DEFLOC_Y;
	}
	
	/*
		Takes the width (or height) of a control and returns
		an X (or Y) location that will center the control in
		the window.
	
	*/
	float WindowControlLocation_Center(float controlLocation, bool iswidth = true)
	{
		if (iswidth)
			return (Width / 2) - (controlLocation / 2);
		else
			return (Height / 2) - (controlLocation / 2);
	}
	
	/*
		Returns a ZSWindow with the given priority
	
	*/
	clearscope ZSWindow GetWindowByPriority(int p)
	{
		ThinkerIterator nwdFinder = ThinkerIterator.Create("ZSWindow");
		ZSWindow enwd;
		while (enwd = ZSWindow(nwdFinder.Next()))
		{
			if (enwd.Priority == p)
				return enwd;
		}
		
		return null;
	}
	
	void PostPrioritySwitch(bool Ignore = false)
	{
		let wd = GetRootWindow();
		string n;
		if (wd != null)
			n = wd.Name;
		else
			n = self.Name;
		ZNetCommand(string.Format("zevsys_PostPriorityIndex,%s", n), self.PlayerClient, Ignore);
	}
	
	private ZSWindow addWindowToStack(ZObjectBase zobj)
	{
		EventHandler.SendNetworkEvent(string.Format("zevsys_AddWindowToStack,%s", zobj.Name));
		return ZSWindow(zobj);
	}
	
	/*
		The ZObjectBase Init method is not virtual, so inheriting objects can virtualize their own constructors
		with their own argument lists, and finalize construction by returning the super.Init() (cast to the right type).
		
		The super only initilizes what is sent, finds the event handler, and destroys the window if that fails.
		
		All other initialization must be done here.
		
	*/
	ZSWindow Init(ZObjectBase ControlParent, bool Enabled, bool Show, string Name, int PlayerClient, bool UiToggle,
		CLIPTYP ClipType = CLIP_NONE, float xLocation = 0, float yLocation = 0, float Alpha = 1, bool SkipStackAdd = false)
	{
		block_bSelfDestroy = false;
		focusStackIndex = priorityStackIndex = -1;
		lockedMoveCursorX = lockedMoveCursorY = -1;
		moveAccumulateX = moveAccumulateY = 0;
		lockedScaleCursorX = lockedScaleCursorX = -1;
		scaleAccumulateX = scaleAccumulateY = 0;
		backgroundInit();
		if (BorderType == BORDERTYP_ZWin)
			borderInit();
		if (!SkipStackAdd)
			return addWindowToStack(super.Init(ControlParent, Enabled, Show, Name, PlayerClient, UiToggle, ClipType));
		else
			return ZSWindow(super.Init(ControlParent, Enabled, Show, Name, PlayerClient, UiToggle, ClipType));
	}
		
	override void Tick()
	{
		if (self.bSelfDestroy)
		{
			for (int i = 0; i < windowControls.Size(); i++)
				windowControls[i].bSelfDestroy = true;
		}
		
		super.Tick();
	}
	
	override bool ZObj_UiProcess(ZUIEventPacket e)
	{
		if (e.MouseX != CursorX || e.MouseY != CursorY)
			ZNetCommand(string.Format("nwd_updateCursorLocation,%s", self.Name), self.PlayerClient, e.MouseX, e.MouseY);
		
		for (int i = 0; i < windowControls.Size(); i++)
		{
			if (windowControls[i].ZObj_UiProcess(e))
				return true;
		}
		
		return super.ZObj_UiProcess(e);
	}
	
	override bool ZObj_UiTick()
	{
		// Control focusing
		if (focusStackIndex > -1)
			ZNetCommand(string.Format("nwd_WindowControlsToSetFocus,%s", self.Name), self.PlayerClient);
		// Priority switching
		if (priorityStackIndex > -1)
			ZNetCommand(string.Format("nwd_ControlPrioritySwitch,%s", self.Name), self.PlayerClient);
		
		// Control UiTicking
		for (int i = 0; i < windowControls.Size(); i++)
		{
			if (windowControls[i].ZObj_UiTick())
				return true;
		}

		return super.ZObj_UiTick();
	}
	
	enum ZWINNETCMD
	{
		ZWINCMD_WindowControlFocus,
		ZWINCMD_ControlPrioritySwitch,
		ZWINCMD_UpdateCursor,
		ZWINCMD_TryString,
	};
	
	private ZWINNETCMD stringToWindowCommand(string e)
	{
		if (e ~== "nwd_WindowControlsToSetFocus")
			return ZWINCMD_WindowControlFocus;
		if (e ~== "nwd_ControlPrioritySwitch")
			return ZWINCMD_ControlPrioritySwitch;
		if (e ~== "nwd_updateCursorLocation")
			return ZWINCMD_UpdateCursor;
		else
			return ZWINCMD_TryString;
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
							switch(stringToWindowCommand(cmd[0]))
							{
								case ZWINCMD_WindowControlFocus:
									controlFocusSwitch();
									break;
								case ZWINCMD_ControlPrioritySwitch:
									controlPrioritySwitch();
									break;
								case ZWINCMD_UpdateCursor:
									CursorX = e.FirstArg;
									CursorY = e.SecondArg;
									break;
								default:
								case ZWINCMD_TryString:
									break;
							}
						}
					}
				}
			}
		}
		
		for (int i = 0; i < windowControls.Size(); i++)
		{
			if (windowControls[i].ZObj_NetProcess(e))
				return true;
		}

		return super.ZObj_NetProcess(e);
	}

	override void ZObj_WorldTick()
	{
		for (int i = 0; i < windowControls.Size(); i++)
			windowControls[i].ZObj_WorldTick();
	}

	override void ZObj_WorldLinePreActivated(ZWorldEventPacket e)
	{
		for (int i = 0; i < windowControls.Size(); i++)
			windowControls[i].ZObj_WorldLinePreActivated(e);
	}

	override void ZObj_WorldLineActivated(ZWorldEventPacket e)
	{
		for (int i = 0; i < windowControls.Size(); i++)
			windowControls[i].ZObj_WorldLineActivated(e);
	}
	
	/*
		Sets up internal background options
		Custom backgrounds need to handle this manually
		
	*/
	private void backgroundInit()
	{
		if (BackgroundType == BACKTYP_ZWin)
			BackgroundTexture = TexMan.CheckForTexture("TGRAY", TexMan.TYPE_ANY);
		// Game options
		else if (Backgroundtype != BACKTYP_Custom && Backgroundtype != BACKTYP_NONE)
		{
			switch (gameinfo.gametype)
			{
				case GAME_Doom:
					switch (BackgroundType)
					{
						case BACKTYP_GameTex1:
							BackgroundTexture = TexMan.CheckForTexture("FWATER1", TexMan.TYPE_ANY);
							break;
						case BACKTYP_GameTex2:
							BackgroundTexture = TexMan.CheckForTexture("ROCK2", TexMan.TYPE_ANY);
							break;
						case BACKTYP_GameTex3:
							BackgroundTexture = TexMan.CheckForTexture("GSTONE1", TexMan.TYPE_ANY);
							break;
					}
					break;
				case GAME_Heretic:
				case GAME_Hexen:
					switch (BackgroundType)
					{
						case BACKTYP_GameTex1:
							BackgroundTexture = TexMan.CheckForTexture("GRNBLOK1", TexMan.TYPE_ANY);
							break;
						case BACKTYP_GameTex2:
							BackgroundTexture = TexMan.CheckForTexture("GRSTNPB", TexMan.TYPE_ANY);
							break;
						case BACKTYP_GameTex3:
							BackgroundTexture = TexMan.CheckForTexture("WOODWL", TexMan.TYPE_ANY);
							break;
					}
					break;
				case GAME_Strife:
					switch (BackgroundType)
					{
						case BACKTYP_GameTex1:
							BackgroundTexture = TexMan.CheckForTexture("PIPWAL11", TexMan.TYPE_ANY);
							break;
						case BACKTYP_GameTex2:
							BackgroundTexture = TexMan.CheckForTexture("BRKGRY01", TexMan.TYPE_ANY);
							break;
						case BACKTYP_GameTex3:
							BackgroundTexture = TexMan.CheckForTexture("WINDW04", TexMan.TYPE_ANY);
							break;
					}
					break;
				case GAME_Chex:
					switch (BackgroundType)
					{
						case BACKTYP_GameTex1:
							BackgroundTexture = TexMan.CheckForTexture("BIGDOOR4", TexMan.TYPE_ANY);
							break;
						case BACKTYP_GameTex2:
							BackgroundTexture = TexMan.CheckForTexture("STONE", TexMan.TYPE_ANY);
							break;
						case BACKTYP_GameTex3:
							BackgroundTexture = TexMan.CheckForTexture("COMP2", TexMan.TYPE_ANY);
							break;
					}
					break;
			}
		}		
	}
	
	/*
		Initializes the "Classic Z-Windows" Border
		
	*/
	private void borderInit()
	{
		let newBorder = new("ZBorder");
		if (newBorder)
		{
			newBorder.Corner_TopLeft = TexMan.CheckForTexture("CRNR_TL", TexMan.TYPE_ANY);
			newBorder.Corner_TopRight = TexMan.CheckForTexture("CRNR_TR", TexMan.TYPE_ANY);
			newBorder.Corner_BottomLeft = TexMan.CheckForTexture("CRNR_BL", TexMan.TYPE_ANY);
			newBorder.Corner_BottomRight = TexMan.CheckForTexture("CRNR_BR", TexMan.TYPE_ANY);
			newBorder.Side_Top = TexMan.CheckForTexture("SIDE_T", TexMan.TYPE_ANY);
			newBorder.Side_Bottom = TexMan.CheckForTexture("SIDE_B", TexMan.TYPE_ANY);
			newBorder.Side_Left = TexMan.CheckForTexture("SIDE_L", TexMan.TYPE_ANY);
			newBorder.Side_Right = TexMan.CheckForTexture("SIDE_R", TexMan.TYPE_ANY);
			
			if (newBorder.Corner_TopLeft.IsValid() && newBorder.Corner_TopRight.IsValid() && newBorder.Corner_BottomLeft.IsValid() && newBorder.Corner_BottomRight.IsValid() &&
				newBorder.Side_Top.IsValid() && newBorder.Side_Bottom.IsValid() && newBorder.Side_Left.IsValid() && newBorder.Side_Right.IsValid())
			{
				Vector2 txy = TexMan.GetScaledSize(newBorder.Corner_TopLeft);
				newBorder.BorderWidth = txy.x;
				newBorder.BorderHeight = txy.y;
				newBorder.Animate = false;
				BorderGraphics = newBorder;
			}
			else
			{
				//DebugOut("ZWinBorderError", "ERROR! Window failed to find all of the textures required for the Classic Z-Window's Border.  Defaulting to Line type.");
				BorderType = BORDERTYP_Line;
			}
		}
	}
	
	/*
		Calculates and returns the real window location;
	
	*/
	clearscope static float, float RealWindowLocation(ZSWindow nwd)
	{
		int diffx, diffy;
		[diffx, diffy] = nwd.MoveDifference();
		return nwd.xLocation + nwd.moveAccumulateX + diffx,
				nwd.yLocation + nwd.moveAccumulateY + diffy;
	}
	
	/*
		Calculates and returns the real width/height of the window
	
	*/
	clearscope static  int, int RealWindowScale(ZSWindow nwd)
	{
		int diffx, diffy;
		[diffx, diffy] =  nwd.ScaleDifference();
		return  nwd.Width +  nwd.scaleAccumulateX + diffx,
			 nwd.Height +  nwd.scaleAccumulateY + diffy;
	}
	
	/*
		Calculates and returns the control's scaled location
		
		You add this to a control's location - if the control reacts to scaling
	
	*/
	clearscope static  float, float RealControlScaledLocation(ZSWindow nwd)
	{
		float scalediffx, scalediffy,
			movediffx, movediffy;
		[scalediffx, scalediffy] = nwd.ScaleDifference();
		[movediffx, movediffy] = nwd.MoveDifference();
		return nwd.moveAccumulateX + movediffx + nwd.scaleAccumulateX + scalediffx,
			nwd.moveAccumulateY + movediffy + nwd.scaleAccumulateY + scalediffy;
	}
	
	clearscope static int GetIntAlpha(ZSWindow nwd)
	{
		return int(255 * (nwd.Enabled ? nwd.Alpha : nwd.DISABLEDALPHA));
	}
	
	clearscope static float GetFloatAlpha(ZSWindow nwd)
	{
		return nwd.Enabled ? nwd.Alpha : nwd.DISABLEDALPHA;
	}

	/*
		Objects Contain their own draw methods,
		the base of which overrides ObjectDraw from the base object
	
	*/
	override void ObjectDraw(ZObjectBase parent)
	{	
		if (Show)
		{
			ObjectDraw_Background(self);
			ObjectDraw_Border(self);
			
			for (int i = windowControls.Size() - 1; i >= 0; i--)
			{
				let control = GetControlByPriority(i);
				if (control && control.PlayerClient == consoleplayer && control.Show)
					control.ObjectDraw(self);
			}
		}
	}
	
	/*
		Draws the window background
	
	*/
	ui static void ObjectDraw_Background(ZSWindow nwd)
	{
		TextureId txid;
		if (nwd.BackgroundTexture.IsValid())
			txid = nwd.BackgroundTexture;
		else
			txid = TexMan.CheckForTexture("-noflat-", TexMan.TYPE_ANY);

		float nwdX, nwdY;
		[nwdX, nwdY] = RealWindowLocation(nwd);
		
		int realWidth, realHeight;
		[realWidth, realHeight] = RealWindowScale(nwd);
		
		if (txid.IsValid())
		{
			// Stretch texture
			if (nwd.BackgroundStretch)
				Screen.DrawTexture(txid, nwd.AnimateBackground,
					nwdX, nwdY,
					DTA_Alpha, nwd.GetFloatAlpha(nwd) == 0 ? nwd.BackgroundAlpha : nwd.GetFloatAlpha(nwd),
					DTA_DestWidth, realWidth,
					DTA_DestHeight, realHeight);
			// Tile texture
			else
			{
				// Set the clipping boundary to the window
				Screen.SetClipRect(nwdX, nwdY, realWidth, realHeight);
				int tx, ty, w = 0;
				Vector2 txy = TexMan.GetScaledSize(txid);
				tx = txy.x;
				ty = txy.y;
				do
				{
					int h = 0;
					do
					{
						Screen.DrawTexture (txid, nwd.AnimateBackground,
							nwdX + (tx * w),
							nwdY + (ty * h),
							DTA_Alpha, nwd.GetFloatAlpha(nwd) == 0 ? nwd.BackgroundAlpha : nwd.GetFloatAlpha(nwd),
							DTA_DestWidth, tx,
							DTA_DestHeight, ty);
						h++;
					} while ((((h - 1) * ty) + ty)  < realHeight);
					w++;
				} while ((((w -1) * tx) + tx) <= realWidth);
				Screen.ClearClipRect();
			}
		}
		else
			console.Printf(string.Format("ZScript Windows - ERROR! - ZSWindow, %s, was unable to find a valid background texture!", nwd.Name));
	}
	
	/*
		Window Border Drawer
	
	*/
	ui static void ObjectDraw_Border(ZSWindow nwd)
	{
		float nwdX, nwdY;
		[nwdX, nwdY] = RealWindowLocation(nwd);
		
		int realWidth, realHeight;
		[realWidth, realHeight] = RealWindowScale(nwd);
		
		switch (nwd.BorderType)
		{
			case BORDERTYP_Game:
				Screen.DrawFrame(nwdX, nwdY, realWidth, realHeight);
				break;
			case BORDERTYP_Line:
				// Top
				Screen.DrawLine(nwdX, 
					nwdY, 
					nwdX + realWidth, 
					nwdY, 
					nwd.BorderColor, 
					nwd.GetIntAlpha(nwd) == 0 ? nwd.BorderAlpha : nwd.GetIntAlpha(nwd));
				// Bottom
				Screen.DrawLine(nwdX, 
					nwdY + realHeight, 
					nwdX + realWidth, 
					nwdY + realHeight, 
					nwd.BorderColor, 
					nwd.GetIntAlpha(nwd) == 0 ? nwd.BorderAlpha : nwd.GetIntAlpha(nwd));
				// Left
				Screen.DrawLine(nwdX, 
					nwdY, 
					nwdX, 
					nwdY + realHeight, 
					nwd.BorderColor, 
					nwd.GetIntAlpha(nwd) == 0 ? nwd.BorderAlpha : nwd.GetIntAlpha(nwd));
				// Right
				Screen.DrawLine(nwdX + realWidth, 
					nwdY, 
					nwdX + realWidth, 
					nwdY + realHeight, 
					nwd.BorderColor, 
					nwd.GetIntAlpha(nwd) == 0 ? nwd.BorderAlpha : nwd.GetIntAlpha(nwd));
				break;
			case BORDERTYP_ThickLine:
				// Top
				Screen.DrawThickLine(nwdX - nwd.BorderThickness, 
					nwdY - GetLineThicknessOffset(nwd.BorderThickness, true), 
					nwdX + realWidth + nwd.BorderThickness, 
					nwdY - GetLineThicknessOffset(nwd.BorderThickness, true), 
					nwd.BorderThickness, 
					nwd.BorderColor, 
					nwd.GetIntAlpha(nwd) == 0 ? nwd.BorderAlpha : nwd.GetIntAlpha(nwd));
				// Bottom
				Screen.DrawThickLine(nwdX - nwd.BorderThickness, 
					nwdY + realHeight + GetLineThicknessOffset(nwd.BorderThickness), 
					nwdX + realWidth + nwd.BorderThickness, 
					nwdY + realHeight + GetLineThicknessOffset(nwd.BorderThickness), 
					nwd.BorderThickness, 
					nwd.BorderColor, 
					nwd.GetIntAlpha(nwd) == 0 ? nwd.BorderAlpha : nwd.GetIntAlpha(nwd));
				// Left
				Screen.DrawThickLine(nwdX - GetLineThicknessOffset(nwd.BorderThickness), 
					nwdY, 
					nwdX - GetLineThicknessOffset(nwd.BorderThickness), 
					nwdY + realHeight, 
					nwd.BorderThickness, 
					nwd.BorderColor, 
					nwd.GetIntAlpha(nwd) == 0 ? nwd.BorderAlpha : nwd.GetIntAlpha(nwd));
				// Right
				Screen.DrawThickLine(nwdX + realWidth + GetLineThicknessOffset(nwd.BorderThickness, true), 
					nwdY, 
					nwdX + realWidth + GetLineThicknessOffset(nwd.BorderThickness, true), 
					nwdY + realHeight, 
					nwd.BorderThickness, 
					nwd.BorderColor, 
					nwd.GetIntAlpha(nwd) == 0 ? nwd.BorderAlpha : nwd.GetIntAlpha(nwd));
				break;
			case BORDERTYP_ZWin:
				// Top Left Corner
				Screen.DrawTexture(nwd.BorderGraphics.Corner_TopLeft, nwd.BorderGraphics.Animate,
					nwdX - nwd.BorderGraphics.BorderWidth, 
					nwdY - nwd.BorderGraphics.BorderHeight,
					DTA_Alpha, nwd.GetFloatAlpha(nwd) == 0 ? nwd.BorderAlpha : nwd.GetFloatAlpha(nwd),
					DTA_DestWidth, nwd.BorderGraphics.BorderWidth,
					DTA_DestHeight, nwd.BorderGraphics.BorderHeight);
				// Top Right Corner	
				Screen.DrawTexture(nwd.BorderGraphics.Corner_TopRight, nwd.BorderGraphics.Animate,
					nwdX + realWidth, 
					nwdY - nwd.BorderGraphics.BorderHeight,
					DTA_Alpha, nwd.GetFloatAlpha(nwd) == 0 ? nwd.BorderAlpha : nwd.GetFloatAlpha(nwd),
					DTA_DestWidth, nwd.BorderGraphics.BorderWidth,
					DTA_DestHeight, nwd.BorderGraphics.BorderHeight);
				// Bottom Left Corner
				Screen.DrawTexture(nwd.BorderGraphics.Corner_BottomLeft, nwd.BorderGraphics.Animate,
					nwdX - nwd.BorderGraphics.BorderWidth, 
					nwdY + realHeight,
					DTA_Alpha, nwd.GetFloatAlpha(nwd) == 0 ? nwd.BorderAlpha : nwd.GetFloatAlpha(nwd),
					DTA_DestWidth, nwd.BorderGraphics.BorderWidth,
					DTA_DestHeight, nwd.BorderGraphics.BorderHeight);
				// Bottom Right Corner	
				Screen.DrawTexture(nwd.BorderGraphics.Corner_BottomRight, nwd.BorderGraphics.Animate,
					nwdX + realWidth, 
					nwdY + realHeight,
					DTA_Alpha, nwd.GetFloatAlpha(nwd) == 0 ? nwd.BorderAlpha : nwd.GetFloatAlpha(nwd),
					DTA_DestWidth, nwd.BorderGraphics.BorderWidth,
					DTA_DestHeight, nwd.BorderGraphics.BorderHeight);
				
				Screen.SetClipRect(nwdX,
								nwdY - nwd.BorderGraphics.BorderHeight,
								realWidth,
								realHeight + (nwd.BorderGraphics.BorderHeight * 2));				
				int w = 0;
				do
				{
					Screen.DrawTexture(nwd.BorderGraphics.Side_Top, nwd.BorderGraphics.Animate,
									nwdX + (nwd.BorderGraphics.BorderWidth * w),
									nwdY - nwd.BorderGraphics.BorderHeight,
									DTA_Alpha, nwd.GetFloatAlpha(nwd) == 0 ? nwd.BorderAlpha : nwd.GetFloatAlpha(nwd),
									DTA_DestWidth, nwd.BorderGraphics.BorderWidth,
									DTA_DestHeight, nwd.BorderGraphics.BorderHeight);
					Screen.DrawTexture(nwd.BorderGraphics.Side_Bottom, nwd.BorderGraphics.Animate,
									nwdX + (nwd.BorderGraphics.BorderWidth * w),
									nwdY + realHeight,
									DTA_Alpha, nwd.GetFloatAlpha(nwd) == 0 ? nwd.BorderAlpha : nwd.GetFloatAlpha(nwd),
									DTA_DestWidth, nwd.BorderGraphics.BorderWidth,
									DTA_DestHeight, nwd.BorderGraphics.BorderHeight);
					w++;
				} while (((w - 1) * nwd.BorderGraphics.BorderWidth) + nwd.BorderGraphics.BorderWidth <= realWidth);
				Screen.ClearClipRect();
				
				Screen.SetClipRect(nwdX - nwd.BorderGraphics.BorderWidth,
								nwdY,
								realWidth + (nwd.BorderGraphics.BorderWidth * 2),
								realHeight);
				int h = 0;
				do
				{
					Screen.DrawTexture(nwd.BorderGraphics.Side_Left, nwd.BorderGraphics.Animate,
									nwdX - nwd.BorderGraphics.BorderWidth,
									nwdY + (nwd.BorderGraphics.BorderHeight * h),
									DTA_Alpha, nwd.GetFloatAlpha(nwd) == 0 ? nwd.BorderAlpha : nwd.GetFloatAlpha(nwd),
									DTA_DestWidth, nwd.BorderGraphics.BorderWidth,
									DTA_DestHeight, nwd.BorderGraphics.BorderHeight);
					Screen.DrawTexture(nwd.BorderGraphics.Side_Right, nwd.BorderGraphics.Animate,
									nwdX + realWidth,
									nwdY + (nwd.BorderGraphics.BorderHeight * h),
									DTA_Alpha, nwd.GetFloatAlpha(nwd) == 0 ? nwd.BorderAlpha : nwd.GetFloatAlpha(nwd),
									DTA_DestWidth, nwd.BorderGraphics.BorderWidth,
									DTA_DestHeight, nwd.BorderGraphics.BorderHeight);
					h++;
				} while (((h - 1) * nwd.BorderGraphics.BorderHeight) + nwd.BorderGraphics.BorderHeight <= realHeight);
				Screen.ClearClipRect();
				break;
			default:
				//EventHandler.SendNetworkEvent(string.Format("zswin_debugOut:%s:%s", "badBorderProcess", string.Format("ERROR! - Window, %s, uses invalid border type, %d.  Valid type range: %d - %d", nwd.WindowName, nwd.BorderType, nwd.Game, nwd.noBorder)));
				// intentional fall-through here
			case BORDERTYP_NONE:
				break;
		}	
	}
	
	clearscope ZSWindow GetRootWindow()
	{
		ZObjectBase pwd;
		if (self.ControlParent)
		{
			pwd = self.ControlParent;
			while (pwd.ControlParent != null)
				pwd = pwd.ControlParent;
			
			if (pwd is "ZSWindow")
				return ZSWindow(pwd);
			else
				return null;
		}
		else
			return self;
	}
	
	/*
		This method is how an event determines if it should do its action.
		This is specfic to the object - this version looks to see if any window is above this one.
		
		If "otherPriority" is not -1, it is assummed that this value is the priority of the parent window.
		The priority of a window that is part of another window's controls does not correspond to the root system.
	
	*/
	override bool ValidateCursorLocation()
	{
		int searchPriority;
		
		// check if this window is a control of another window
		ZObjectBase pwd = GetRootWindow();
		if (pwd)
			searchPriority = pwd.Priority;
		else
			searchPriority = self.Priority;
	
		if (searchPriority > 0)
		{
			//console.printf(string.format("%s, checking other priority : %d", otherPriority));
			// Look for higher priority windows
			for (int i = 0; i < searchPriority; i++)
			{
				let enwd = GetWindowByPriority(i);
				if (enwd)
				{
					float enwdX, enwdY;
					[enwdX, enwdY] = RealWindowLocation(enwd);
					int enwdW, enwdH;
					[enwdW, enwdH] = RealWindowScale(enwd);
					if (enwdX < CursorX && CursorX < enwdX + enwdW &&
						enwdY < CursorY && CursorY < enwdY + enwdH)
						return false;
				}
			}
			
			// Check this window
			float sx, sy;
			[sx, sy] = RealWindowLocation(self);
			int sw, sh;
			[sw, sh] = RealWindowScale(self);
			if (sx < CursorX && CursorX < sx + sw &&
				sy < CursorY && CursorY < sy + sh)
				return super.ValidateCursorLocation();
		}

		return false;
	}
	
	/*
		Windows call their control events from their own events.
		So windows that override their events MUST call their super, 
		except in specific circumstances.
		
	*/
	override void WhileMouseIdle(int t) { ControlEventCaller(t); }
	override void OnMouseMove(int t) { ControlEventCaller(t); }
	
	override void OnLeftMouseDown(int t) { ControlEventCaller(t); }	
	override void OnLeftMouseUp(int t) { ControlEventCaller(t); }	
	override void OnLeftMouseClick(int t) { ControlEventCaller(t); }
	
	override void OnMiddleMouseDown(int t) { ControlEventCaller(t); }
	override void OnMiddleMouseUp(int t) { ControlEventCaller(t); }
	override void OnMiddleMouseClick(int t) { ControlEventCaller(t); }
	
	override void OnRightMouseDown(int t) { ControlEventCaller(t); }
	override void OnRightMouseUp(int t) { ControlEventCaller(t); }
	override void OnRightMouseClick(int t) { ControlEventCaller(t); }
	
	override void OnWheelMouseDown(int t) { ControlEventCaller(t); }
	override void OnWheelMouseUp(int t) { ControlEventCaller(t); }
	
	override void ControlEventCaller(int t)
	{
		for (int i = 0; i < windowControls.Size(); i++)
		{
			windowControls[i].ControlEventCaller(t);

			switch (t)
			{
				default:
				case ZUIEventPacket.EventType_None:
					windowControls[i].WhileMouseIdle(t);
					break;
				case ZUIEventPacket.EventType_MouseMove:
					windowControls[i].OnMouseMove(t);
					break;
				case ZUIEventPacket.EventType_LButtonDown:
					windowControls[i].OnLeftMouseDown(t);
					break;
				case ZUIEventPacket.EventType_LButtonUp:
					windowControls[i].OnLeftMouseUp(t);
					break;
				case ZUIEventPacket.EventType_LButtonClick:
					windowControls[i].OnLeftMouseClick(t);
					break;
				case ZUIEventPacket.EventType_MButtonDown:
					windowControls[i].OnMiddleMouseDown(t);
					break;
				case ZUIEventPacket.EventType_MButtonUp:
					windowControls[i].OnMiddleMouseUp(t);
					break;
				case ZUIEventPacket.EventType_MButtonClick:
					windowControls[i].OnMiddleMouseClick(t);
					break;
				case ZUIEventPacket.EventType_RButtonDown:
					windowControls[i].OnRightMouseDown(t);
					break;
				case ZUIEventPacket.EventType_RButtonUp:
					windowControls[i].OnRightMouseUp(t);
					break;
				case ZUIEventPacket.EventType_RButtonClick:
					windowControls[i].OnRightMouseClick(t);
					break;
				case ZUIEventPacket.EventType_WheelUp:
					windowControls[i].OnWheelMouseDown(t);
					break;
				case ZUIEventPacket.EventType_WheelDown:
					windowControls[i].OnWheelMouseUp(t);
					break;
			}
		}
	}

	/* - END OF METHODS - */
}