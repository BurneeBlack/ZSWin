/*
	ZSWin_ControlBase.zs
	
	This base class contains members and methods universal to controls

*/

struct DrawingParams
{
	float pclipX, pclipY,
		sxloc, syloc;
	int pclipWdth, pclipHght;
	bool bClipped;
}

class ClipOffsets
{
	string Name;
	int Top, Bottom, Left, Right;

	ClipOffsets Init(string Name, int Top = 0, int Bottom = 0, int Left = 0, int Right = 0)
	{
		self.Name = Name;
		self.Top = Top;
		self.Bottom = Bottom;
		self.Left = Left;
		self.Right = Right;
		return self;
	}
}

class ZControl : ZObjectBase abstract
{
	SCALETYP ScaleType;
	bool HasFocus;

	/* 
		This struct contains clipping and postioning data for the control.
		It should be used in tandem with the method GetDrawingControls during ObjectDraw
		to draw the control.
	*/
	DrawingParams DrawParams;

	/*
		This class contains offsets for each side of the clipping boundaries of the control.
		Since there are likely multiple boundaries, this is an array and instances are identified
		by a name.  Utility methods are provided.
	*/
	array<ClipOffsets> ClipOffs;
	clearscope static ClipOffsets GetClipOffset(ZControl ctl, string n)
	{
		for (int i = 0; i < ctl.ClipOffs.Size(); i++)
		{
			if (ctl.ClipOffs[i].Name == n)
				return ctl.ClipOffs[i];
		}

		return null;
	}
	clearscope static int GetTopClipOff(ZControl ctl, string n) { return GetClipOffset(ctl, n) == null ? 0 : GetClipOffset(ctl, n).Top; }
	clearscope static int GetBottomClipOff(ZControl ctl, string n) { return GetClipOffset(ctl, n) == null ? 0 : GetClipOffset(ctl, n).Bottom; }
	clearscope static int GetLeftClipOff(ZControl ctl, string n) { return GetClipOffset(ctl, n) == null ? 0 : GetClipOffset(ctl, n).Left; }
	clearscope static int GetRightClipOff(ZControl ctl, string n) { return GetClipOffset(ctl, n) == null ? 0 : GetClipOffset(ctl, n).Right; }
	
	enum TEXTALIGN
	{
		TEXTALIGN_Left,
		TEXTALIGN_Right,
		TEXTALIGN_Center,
	};
	TEXTALIGN TextAlignment;
	
	enum TXTWRAP
	{
		TXTWRAP_Wrap,
		TXTWRAP_Dynamic,
		TXTWRAP_NONE,
	};
	TXTWRAP TextWrap;

	ZControl Init(ZObjectBase ControlParent, bool Enabled, bool Show, string Name, int PlayerClient, bool UiToggle, SCALETYP ScaleType = SCALE_NONE, TEXTALIGN TextAlignment = TEXTALIGN_Left, CLIPTYP ClipType = CLIP_Parent)
	{
		self.ScaleType = ScaleType;
		self.TextAlignment = TextAlignment;
		self.HasFocus = false;
		self.DrawParams.bClipped = true;	// This is usually the case and needs to be true for controls to be clipped, but now users can control clipping
		if (ControlParent)
			return ZControl(super.Init(ControlParent, Enabled, Show, Name, PlayerClient, UiToggle, ClipType));
		else
			HCF(" - - CONTROLS REQUIRE VALID A PARENT REFERENCE!");
		return null;
	}
	
	/*
		Wrapper to trigger a focus change
	
	*/
	void SetFocus(bool fullKeyboard = false)
	{
		GetParentWindow(self.ControlParent).PostControlFocusIndex(self);
		if (fullKeyboard)
			ZNetCommand("zevsys_ControlFullInput", self.PlayerClient, true);
	}
	
	void LoseFocus(bool fullKeyboard = false)
	{
		HasFocus = false;
		if (fullKeyboard)
			ZNetCommand("zevsys_ControlFullInput", self.PlayerClient);
	}

	/*
		This is a universal alpha calculation
		method for drawing control graphics or text
		(they both use floats for the alpha value).

		The method checks that the parent window's
		alpha is nonzero, otherwise it returns zero
	
	*/
	ui static float GetControlAlpha(ZObjectBase parent, ZControl ctrl) 
	{ 
		return GetParentWindow(parent).GetFloatAlpha(GetParentWindow(parent)) == 0 ? 
			(ctrl.Enabled ? 
				ctrl.Alpha : 
				GetParentWindow(parent).DISABLEDALPHA) : 
			GetParentWindow(parent).GetFloatAlpha(GetParentWindow(parent)); }
	
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

	/*
		Returns a ZSWindow with the given name

	*/
	clearscope ZSWindow GetWindowByName(string n)
	{
		ThinkerIterator nwdFinder = ThinkerIterator.Create("ZSWindow");
		ZSWindow enwd;
		while (enwd = ZSWindow(nwdFinder.Next()))
		{
			if (enwd.Name ~== n)
				return enwd;
		}

		return null;
	}
	
	/*
		Recursively searches for the first encountered window and returns it.
		
		Set searchToFirstWindow to false to seach all the way to the end of the ControlParent chain
	
	*/
	clearscope static ZSWindow GetParentWindow(ZObjectBase zobj, bool searchToFirstWindow = true)
	{
		if (!zobj.ControlParent || (zobj is "ZSWindow" && searchToFirstWindow))
			return ZSWindow(zobj);
		else
			return GetParentWindow(zobj.ControlParent, searchToFirstWindow);	
	}
	
	/*
		Recursively looks up the chain of Control Parents for the first ZSWindow it encounters,
		and returns the result of the window's RealWindowLocation method.
	
	*/
	clearscope static float, float GetParentWindowLocation(ZObjectBase zobj, bool searchToFirstWindow = true)
	{
		float retx, rety;
		if (!zobj.ControlParent || (zobj is "ZSWindow" && searchToFirstWindow))
			[retx, rety] = ZSWindow(zobj).RealWindowLocation(ZSWindow(zobj));
		else
			[retx, rety] = GetParentWindowLocation(zobj.ControlParent, searchToFirstWindow);
		return retx, rety;
	}

	/*
		Recursively looks up the chain of Control Parents for the first ZSWindow it encounters,
		and returns the result of the window's RealWindowScale method.
	
	*/	
	clearscope static int, int GetParentWindowScale(ZObjectBase zobj, bool searchToFirstWindow = true)
	{
		float retx, rety;
		if (!zobj.ControlParent || (zobj is "ZSWindow" && searchToFirstWindow))
			[retx, rety] = ZSWindow(zobj).RealWindowScale(ZSWindow(zobj));
		else
			[retx, rety] = GetParentWindowScale(zobj.ControlParent, searchToFirstWindow);
		return retx, rety;
	}

	/*
		Returns the clipping location and boundaries
		for a ZControl, as well as the absolute location
		of the object.
	
	*/
	clearscope static bool GetDrawingControls(ZControl ctl, out DrawingParams DrawParams)
	{
		let nwd = GetParentWindow(ctl.ControlParent);
		switch (ctl.ClipType)
		{
			case CLIP_Window:
				[DrawParams.pclipX, DrawParams.pclipY] = GetParentWindowLocation(ctl.ControlParent);
				[DrawParams.pclipWdth, DrawParams.pclipHght] = GetParentWindowScale(ctl.ControlParent);
				break;
			case CLIP_Parent:
				float mx, my;
				[mx, my] = nwd.MoveDifference();
				DrawParams.pclipX = ctl.ControlParent.xLocation + nwd.moveAccumulateX + mx;
				DrawParams.pclipY = ctl.ControlParent.yLocation + nwd.moveAccumulateY + my;
				int sx, sy;
				[sx, sy] = nwd.ScaleDifference();
				if (ctl.ControlParent is "ZControl")
				{
					switch (ZControl(ctl.ControlParent).ScaleType)
					{
						case SCALE_Horizontal:
							DrawParams.pclipWdth = ctl.ControlParent.Width + nwd.scaleAccumulateX + sx;
							DrawParams.pclipHght = ctl.ControlParent.Height;
							break;
						case SCALE_Vertical:
							DrawParams.pclipWdth = ctl.ControlParent.Width;
							DrawParams.pclipHght = ctl.ControlParent.Height + nwd.scaleAccumulateY + sy;
							break;
						case SCALE_Both:
							DrawParams.pclipWdth = ctl.ControlParent.Width + nwd.scaleAccumulateX + sx;
							DrawParams.pclipHght = ctl.ControlParent.Height + nwd.scaleAccumulateY + sy;
							break;
						default:
							DrawParams.pclipWdth = ctl.ControlParent.Width;
							DrawParams.pclipHght = ctl.ControlParent.Height;
							break;
					}
				}
				else
				{
					DrawParams.pclipWdth = ctl.ControlParent.Width + nwd.scaleAccumulateX + sx;
					DrawParams.pclipHght = ctl.ControlParent.Height + nwd.scaleAccumulateY + sy;
				}
				break;
			default:
				DrawParams.bClipped = false;
				break;
		}

		[DrawParams.sxloc, DrawParams.syloc] = nwd.MoveDifference();
		DrawParams.sxloc += ctl.xLocation + nwd.moveAccumulateX;
		DrawParams.syloc += ctl.yLocation + nwd.moveAccumulateY;
		int nsclx, nscly;
		[nsclx, nscly] = nwd.ScaleDifference();
		switch (ctl.ScaleType)
		{
			case SCALE_Horizontal:
				DrawParams.sxloc += nwd.scaleAccumulateX + nsclx;
				break;
			case SCALE_Vertical:
				DrawParams.syloc += nwd.scaleAccumulateY + nscly;
				break;
			case SCALE_Both:
				DrawParams.sxloc += nwd.scaleAccumulateX + nsclx;
				DrawParams.syloc += nwd.scaleAccumulateY + nscly;
				break;
			// don't need a default here, variables are already set
		}

		return DrawParams.bClipped;		
	}
	

	/*
		The CONTROLTYPE enum and WhatIsMyParent method
		are here more for information purposes than anything.
		I don't think ZScript Windows uses this anywhere;
		I must have had a use at one point but have long since
		implemented something else for a solution.

		This might be useful in circumstances where a control
		may be spawned to a parent on the fly, however most
		of the useful access points are going to be here in
		the ZControl itself - so yeah, this might be useless.
	
	*/
	enum CONTROLTYPE
	{
		CTLTYP_Window,
		CTLTYP_Button,
		CTLTYP_Dialog,
		CTLTYP_GroupBox,
		CTLTYP_Text,	// what? how? ZText has no way of being a parent
		CTLTYP_TextBox,
		CTLTYP_UNKNOWN,
	};
	
	clearscope CONTROLTYPE WhatIsMyParent(ZObjectBase parent)
	{
		if (parent is "ZSWindow")
			return CTLTYP_Window;
		if (parent is "ZButton")
			return CTLTYP_Button;
		if (parent is "ZConversation")
			return CTLTYP_Dialog;
		if (parent is "ZGroupBox")
			return CTLTYP_GroupBox;
		if (parent is "ZText")
			return CTLTYP_Text;
		if (parent is "ZTextBox")
			return CTLTYP_TextBox;
		else
			return CTLTYP_UNKNOWN;
	}
	
	/* - END OF METHODS - */
}