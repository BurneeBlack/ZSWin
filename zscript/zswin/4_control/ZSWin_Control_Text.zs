/*
	ZSWin_Object_Text.zs
	
	Text Control Class Definition
	
	This control does not need to be inherited from, 
	it should be initialized directly.

*/

class ZText : ZControl
{
	string Text;
	BrokenLines WrappedText;
	
	int WrapWidth;
	
	name TextFont, TextColor;
	
	ZText Init(ZObjectBase ControlParent, bool Enabled, bool Show, string Name, string Text, int PlayerClient, bool UiToggle,
		CLIPTYP ClipType = CLIP_Parent, SCALETYP ScaleType = SCALE_NONE, TEXTALIGN TextAlignment = TEXTALIGN_Left,
		TXTWRAP TextWrap = TXTWRAP_NONE, int WrapWidth = 0, name TextFont = 'consolefont', name TextColor = 'Black',
		float xLocation = 0, float yLocation = 0, float Alpha = 1)
	{
		self.Text = Text;
		self.TextWrap = TextWrap;
		self.WrapWidth = WrapWidth;
		self.TextFont = TextFont;
		self.TextColor = TextColor;
		self.xLocation = ControlParent.xLocation + xLocation;
		self.yLocation = ControlParent.yLocation + yLocation;
		self.Alpha = Alpha;
		if (self.TextFont)
			return ZText(super.Init(ControlParent, Enabled, Show, Name, PlayerClient, UiToggle, ScaleType, TextAlignment, ClipType));
		else
			return ZText(HCF(" - - TEXT CONTROL DOES NOT HAVE A VALID FONT!"));
	}
	
	override bool ZObj_UiTick()
	{
		// If this control dynamically wraps its text it needs to update its broken lines
		// prior to the next draw.  This is done from sending an AddToUITicker event.
		// This event is actually sending 2 events, AddToUITicker and ControlUpdate.
		// AddToUITicker will put ControlUpdate and everything else into an event packet
		// for processing by the UITicker.
		
		if (TextWrap != TXTWRAP_NONE && !self.bSelfDestroy)
			ZNetCommand(string.Format("zevsys_AddToUITicker,zobj_ControlUpdate,%s", self.Name), self.PlayerClient);
		return super.ZObj_UiTick();
	}

	override void ZObj_WorldTick()
	{
		if (TextWrap != TXTWRAP_NONE && GameState == GS_TITLELEVEL)
			ObjectUpdate();
	}
	
	/*
		Returns the object's text wrap width.
		
		This should not be confused with the actual WrapWidth member,
		which is a direct assignment of the wrapping width for non-dynamic
		text. This method will return the value of the WrapWidth member, should
		text wrapping be static and the WrapWidth member non-zero.
		
		The intent of this method is to provide a method of determining a text
		wrapping width under all circumstances, especially dynamic where the
		object is calculating things on the fly.
		
		A returned value of zero (0), indicates no text wrapping is being
		applied to the object's text.
		
	*/
	clearscope int GetTextWrapWidth()
	{
		int cw;
		switch (TextWrap)
		{
			case TXTWRAP_Wrap:
				if (WrapWidth > 0)
					cw = self.WrapWidth;
				else
					cw = self.ControlParent.Width;
				break;
			case TXTWRAP_Dynamic:
				int ch;
				// How does the text want to be clipped?
				switch (self.ClipType)
				{
					// To the Window
					case CLIP_Window:
						[cw, ch] = GetParentWindowScale(self.ControlParent);
						break;
					// To its parent
					case CLIP_Parent:
						// Go ahead and get the window anyway
						let nwd = GetParentWindow(self.ControlParent);
						// Check that the parent is actually a control
						if (self.ControlParent is "ZControl")
						{
							// Ok, how does it scale?
							switch(ZControl(self.ControlParent).ScaleType)
							{
								// Horizontal or Both we need the xscale stuff
								case SCALE_Horizontal:
								case SCALE_Both:
									int diffx, diffy;
									[diffx, diffy] =  nwd.ScaleDifference();
									cw = self.ControlParent.Width + nwd.scaleAccumulateX + diffx;
									break;
								// Not scaling, so just set to the parent width
								default:
									cw = self.ControlParent.Width;
									break;
							}
						}
						// Parent is a window so get the window scale
						else
							[cw, ch] = nwd.RealWindowScale(nwd);
						break;
					// Dynamic but doesn't specify? Well Screen width then.
					default:
						cw = screen.GetWidth();
						break;
				}
				break;
			default:
				return 0;
		}
		return cw;
	}
	
	override void ObjectUpdate()
	{
		// Hey ZDoom GC - you better like this, old Z-Windows died because of strings and memory mismanagment
		WrappedText = Font.GetFont(self.TextFont).BreakLines(self.Text, GetTextWrapWidth());
	}
	
	override void ObjectDraw(ZObjectBase parent)
	{
		ObjectDraw_Text(parent, self);
	}
	
	clearscope static float GetAlignment (ZText txt, float xLocation, float Width, string line)
	{
		Font fnt = Font.GetFont(txt.TextFont);
		switch (txt.TextAlignment)
		{
			default:
			case TEXTALIGN_Left: 
				return xLocation;
			case TEXTALIGN_Right: 
				return (xLocation + Width) - fnt.StringWidth(line);
			case TEXTALIGN_Center: 
				return xLocation + ((Width - fnt.StringWidth(line)) / 2);
		}
	}
	
	ui static void ObjectDraw_Text(ZObjectBase parent, ZText txt)
	{
		bool bClipped = GetDrawingControls(txt, txt.DrawParams);
		
		if (txt.Show)
		{
			if (bClipped)
				screen.SetClipRect(txt.DrawParams.pclipX + GetLeftClipOff(txt, "main"), 
					txt.DrawParams.pclipY + GetTopClipOff(txt, "main"), 
					txt.DrawParams.pclipWdth + GetRightClipOff(txt, "main"), 
					txt.DrawParams.pclipHght + GetBottomClipOff(txt, "main"));
			switch (txt.TextWrap)
			{
				case TXTWRAP_Wrap:
				case TXTWRAP_Dynamic:
					if (!txt.WrappedText)
						ZNetCommand(string.Format("zevsys_AddToUITicker,zobj_ControlUpdate,%s", txt.Name), txt.PlayerClient);
					else
					{
						for (int i = 0; i < txt.WrappedText.Count(); i++)
							Screen.DrawText(Font.GetFont(txt.TextFont),
											Font.FindFontColor(txt.TextColor),
											GetAlignment(txt, txt.DrawParams.sxloc, txt.DrawParams.pclipWdth, txt.WrappedText.StringAt(i)),
											txt.DrawParams.syloc + (i * Font.GetFont(txt.TextFont).GetHeight()),
											txt.WrappedText.StringAt(i),
											DTA_Alpha, GetControlAlpha(txt.ControlParent, txt));
					}
					break;
				default:
					Screen.DrawText(Font.GetFont(txt.TextFont),
									Font.FindFontColor(txt.TextColor),
									GetAlignment(txt, txt.DrawParams.sxloc, txt.DrawParams.pclipWdth, txt.Text),
									txt.DrawParams.syloc,
									txt.Text,
									DTA_Alpha, GetControlAlpha(txt.ControlParent, txt));
					break;
			}
			if (bClipped)
				Screen.ClearClipRect();
		}
	}
}