/*
	ZSWin_Object_GroupBox.zs
	
	GroupBox Control Base Class Definition

*/

class ZGroupBox : ZControl
{
	// This is the heading
	ZText BoxText;

	// Defines the groupbox shape and line type
	enum BOXSHAPETYPE
	{
		BOXTYPE_box,
		BOXTYPE_thickbox,
		BOXTYPE_roundbox,
		BOXTYPE_roundthickbox,
		BOXTYPE_default,
	};
	BOXSHAPETYPE BoxType;

	int LineColor,
		CornerRadius,
		CornerVertices;

	float LineThickness;

	/* 
		This object handles the control's ability to
		contain an indeterminate number of other controls.
		It is functionally identical to the internal
		control system of the ZWindow.
	*/
	ZControlUtil GroupBoxControls;

	/*
		Returns the length in pixels of the longest line in the heading text.
		This is done regardless of text wrapping.
	*/
	private clearscope static int getHeaderLongestLine(string txt, int wrpwdth, name fnt)
	{
		BrokenLines wrphdr = Font.GetFont(fnt).BreakLines(txt, wrpwdth);
		int lngln = 0;
		for (int i = 0; i < wrphdr.Count(); i++)
		{
			if (Font.GetFont(fnt).StringWidth(wrphdr.StringAt(i)) > lngln)
				lngln = Font.GetFont(fnt).StringWidth(wrphdr.StringAt(i));
		}
		return lngln;
	}

	/*
		Returns either the text's wrapwidth or the width of the groupbox based on wrap enum.
		No text wrapping still returns the groupbox width.
	*/
	private clearscope static int getWrapWidth(TXTWRAP wrap, int wrpwdth, int grpwdth)
	{
		switch (wrap)
		{
			case TXTWRAP_Wrap:
				return wrpwdth;
			default:
			case TXTWRAP_Dynamic:
				return grpwdth;
		}
	}
	
	ZGroupBox Init(ZObjectBase ControlParent, bool Enabled, bool Show, string Name, int PlayerClient, bool UiToggle,
		/* Box specifics */
		BOXSHAPETYPE BoxType = BOXTYPE_default, int LineColor = 4, int CornerRadius = 8, int CornerVertices = 4, float LineThickness = 1,
		/* Universal Dimensionals */
		int Width = 0, int Height = 0, float Box_xLocation = 0, float Box_yLocation = 0, float Box_Alpha = 1,
		/* Clipping and scaling */
		CLIPTYP Box_ClipType = CLIP_Parent, SCALETYP Box_ScaleType = SCALE_NONE, TEXTALIGN Box_TextAlignment = TEXTALIGN_Left,
		/* Heading ZText specifics */
		string Text = "", 
		CLIPTYP Txt_ClipType = CLIP_Parent, SCALETYP Txt_ScaleType = SCALE_NONE, TEXTALIGN Txt_TextAlignment = TEXTALIGN_Left, 
		TXTWRAP TextWrap = TXTWRAP_NONE, int WrapWidth = 0, name TextFont = 'newsmallfont', name TextColor = 'White',
		bool TextLocateBottom = false, float Txt_xLocation = 0, float Txt_yLocation = 0, float Txt_Alpha = 1)
	{
		self.BoxType = BoxType;
		self.LineColor = LineColor;
		self.CornerRadius = CornerRadius;
		self.CornerVertices = CornerVertices;
		self.LineThickness = LineThickness;

		self.Width = Width;
		self.Height = Height;
		self.xLocation = ControlParent.xLocation + Box_xLocation;
		self.yLocation = ControlParent.yLocation + Box_yLocation;
		self.Alpha = Box_Alpha;

		bool spwned;
		actor cntrls, txt;
		[spwned, txt] = A_SpawnItemEx("ZText");
		if (spwned && txt)
		{
			self.BoxText = ZText(txt).Init(self, Enabled, Show, string.Format("%s_GroupBoxHeading", Name), Text, PlayerClient, UiToggle,
				Txt_ClipType, Txt_ScaleType, Txt_TextAlignment,
				TextWrap, WrapWidth, TextFont, TextColor, 
				/* This is the assignment of the header xLocation based on the boxes text alignment */
				Box_TextAlignment == TEXTALIGN_Right ? 
					Width - (Txt_xLocation + getHeaderLongestLine(Text, getWrapWidth(TextWrap, WrapWidth, Width), TextFont)) :
				Box_TextAlignment == TEXTALIGN_Center ? 
					((Width / 2) - (getHeaderLongestLine(Text, getWrapWidth(TextWrap, WrapWidth, Width), TextFont) / 2)) + Txt_xLocation : 
				Txt_xLocation, 
				/* This is the assignment of the header yLocation based on the TextLocateBottom bool */
				TextLocateBottom ? 
					Height + Txt_yLocation - ((Font.GetFont(TextFont).GetHeight()) / 2) :
				Txt_yLocation - ((Font.GetFont(TextFont).GetHeight()) / 2), 
				Txt_Alpha);
			self.BoxText.ClipOffs.Push(new("ClipOffsets").Init("main", self.BoxText.yLocation - self.yLocation));
		}

		[spwned, cntrls] = A_SpawnItemEx("ZControlUtil");
		if (spwned && cntrls)
			GroupBoxControls = ZControlUtil(cntrls).Init(self, Enabled, Show, string.Format("%s_ControlUtil", Name), PlayerClient, UiToggle);

		return ZGroupBox(super.Init(ControlParent, Enabled, Show, Name, PlayerClient, UiToggle, Box_ScaleType, Box_TextAlignment, Box_ClipType));
	}

	override void Tick()
	{
		GroupBoxControls.Tick();

		if (self.bSelfDestroy)
		{
			GroupBoxControls.bSelfDestroy = true;
			BoxText.bSelfDestroy = true;
		}

		super.Tick();
	}

	override bool ZObj_UiProcess(ZUIEventPacket e)
	{
		if (GroupBoxControls.ZObj_UiProcess(e))
			return true;

		return super.ZObj_UiProcess(e);
	}

	override bool ZObj_UiTick()
	{
		if (BoxText.ZObj_UiTick())
			return true;
		if (GroupBoxControls.ZObj_UiTick())
			return true;

		return super.ZObj_UiTick();
	}

	override bool ZObj_NetProcess(ZEventPacket e)
	{
		if (GroupBoxControls.ZObj_NetProcess(e))
			return true;

		return super.ZObj_NetProcess(e);
	}

	override void ZObj_WorldTick()
	{
		GroupBoxControls.ZObj_WorldTick();
	}

	override void ControlEventCaller(int t)
    {
		GroupBoxControls.ControlEventCaller(t);
	}

	/*
		Draws the rounded corners

		Args:
		-----
			sx/sxyloc 	- float, starting location (upper left corner)
			wdth 		- int, width of the box
			hght 		- int, height of the box
			originx/y 	- int, this is the center of the circle
			cx/cystart 	- int this is the starting draw point
			lineColor 	- int, the palette color
			alpha 		- float, transparency, range 0 - 1
			rads 		- int, radius of the circle
			verts 		- int, number of vertices that make up the corner
			[angmult] 	- int, this value rotates the corner by the given number of degrees, default to 0
			[thick] 	- bool, if true draws a thick line, [thickness] pixels thick, defaults to false
			[thickness] - int, pixel thickness of the line if drawing a thick line, defaults to 0
	
	*/
	private ui static void objectDraw_GroupBoxRadius(float sxloc, float syloc, int wdth, int hght,
		int originx, int originy, int cxstart, int cystart, 
		int lineColor, float alpha, int rads, int verts, int angmult = 0,
		bool thick = false, int thickness = 0)
	{
		int ang = 90 / verts;
		for (int i = 0; i < verts; i++)
		{
			int cxend = originx - cos(angmult + ang * i) * rads;
			if ((angmult == 0 || angmult == 180) && i == verts - 1)
				cxend = sxloc + (angmult == 180 ? wdth : 0) + (rads * (angmult == 0 ? 1 : -1));

			int cyend = originy - sin(angmult + ang * i) * rads;
			if ((angmult == 90 || angmult == 270) && i == verts - 1)
				cyend = syloc + (angmult == 270 ? hght : 0) + (rads * (angmult == 90 ? 1 : -1));

			if (thick)
				Screen.DrawThickLine(cxstart,
					cystart,
					cxend,
					cyend,
					thickness,
					Screen.PaletteColor(lineColor),
					int(alpha * 255));
			else
				Screen.DrawLine(cxstart, 
					cystart, 
					cxend, 
					cyend, 
					Screen.PaletteColor(lineColor), 
					int(alpha * 255));
			cxstart = cxend;
			cystart = cyend;
		}
	}

	override void ObjectDraw (ZObjectBase parent)
	{
		ObjectDraw_GroupBox(parent, self);
		BoxText.ObjectDraw(self);
		GroupBoxControls.ObjectDraw(self);
	}

	ui static void ObjectDraw_GroupBox(ZObjectBase parent, ZGroupBox ctl)
	{
		bool bClipped = GetDrawingControls(ctl, ctl.DrawParams);
	
		if (ctl.Show)
		{
			switch (ctl.BoxType)
			{
				//
				// Thin Groupbox
				//
				default:
				case ZGroupBox.BOXTYPE_box:
					// Top split line
					if (!IsEmpty(ctl.BoxText.Text))
					{
						// Left side
						Screen.DrawLine(ctl.DrawParams.sxloc - 1,
										ctl.DrawParams.syloc - 1,
										ctl.DrawParams.sxloc + (ctl.BoxText.DrawParams.sxloc - ctl.DrawParams.sxloc) - 3,
										ctl.DrawParams.syloc - 1,
										Screen.PaletteColor(ctl.LineColor),
										int(GetControlAlpha(ctl.ControlParent, ctl) * 255));
						// Right side
						Screen.DrawLine(ctl.DrawParams.sxloc + (ctl.BoxText.DrawParams.sxloc - ctl.DrawParams.sxloc) + getHeaderLongestLine(ctl.BoxText.Text, getWrapWidth(ctl.BoxText.TextWrap, ctl.BoxText.WrapWidth, ctl.Width), ctl.BoxText.TextFont) + 3,
										ctl.DrawParams.syloc - 1,
										ctl.DrawParams.sxloc + ctl.Width,
										ctl.DrawParams.syloc - 1,
										Screen.PaletteColor(ctl.LineColor),
										int(GetControlAlpha(ctl.ControlParent, ctl) * 255));
					}
					// Normal line if the text isn't found
					else
						Screen.DrawLine(ctl.DrawParams.sxloc - 1,
										ctl.DrawParams.syloc - 1,
										ctl.DrawParams.sxloc + ctl.Width,
										ctl.DrawParams.syloc - 1,
										Screen.PaletteColor(ctl.LineColor),
										int(GetControlAlpha(ctl.ControlParent, ctl) * 255));
					// Bottom
					Screen.DrawLine(ctl.DrawParams.sxloc - 1,
									ctl.DrawParams.syloc + ctl.Height,
									ctl.DrawParams.sxloc + ctl.Width,
									ctl.DrawParams.syloc + ctl.Height,
									Screen.PaletteColor(ctl.LineColor),
									int(GetControlAlpha(ctl.ControlParent, ctl) * 255));
					// Left
					Screen.DrawLine(ctl.DrawParams.sxloc,
									ctl.DrawParams.syloc,
									ctl.DrawParams.sxloc,
									ctl.DrawParams.syloc + ctl.Height,
									Screen.PaletteColor(ctl.LineColor),
									int(GetControlAlpha(ctl.ControlParent, ctl) * 255));
					// Right
					Screen.DrawLine(ctl.DrawParams.sxloc + ctl.Width,
									ctl.DrawParams.syloc,
									ctl.DrawParams.sxloc + ctl.Width,
									ctl.DrawParams.syloc + ctl.Height,
									Screen.PaletteColor(ctl.LineColor),
									int(GetControlAlpha(ctl.ControlParent, ctl) * 255));					
					break;
				//
				// Thick Groupbox
				//
				case ZGroupBox.BOXTYPE_thickbox:
					// Top split line
					if (!IsEmpty(ctl.BoxText.Text))
					{
						// Left side
						Screen.DrawThickLine(ctl.DrawParams.sxloc - ctl.LineThickness,
										ctl.DrawParams.syloc - GetLineThicknessOffset(ctl.LineThickness, true),
										ctl.DrawParams.sxloc + (ctl.BoxText.DrawParams.sxloc - ctl.DrawParams.sxloc) - 3,
										ctl.DrawParams.syloc - GetLineThicknessOffset(ctl.LineThickness, true),
										ctl.LineThickness, 
										Screen.PaletteColor(ctl.LineColor),
										int(GetControlAlpha(ctl.ControlParent, ctl) * 255));
						// Right Side
						Screen.DrawThickLine(ctl.DrawParams.sxloc + (ctl.BoxText.DrawParams.sxloc - ctl.DrawParams.sxloc) + getHeaderLongestLine(ctl.BoxText.Text, getWrapWidth(ctl.BoxText.TextWrap, ctl.BoxText.WrapWidth, ctl.Width), ctl.BoxText.TextFont) + 3,
										ctl.DrawParams.syloc - GetLineThicknessOffset(ctl.LineThickness, true),
										ctl.DrawParams.sxloc + ctl.Width + ctl.LineThickness,
										ctl.DrawParams.syloc - GetLineThicknessOffset(ctl.LineThickness, true),
										ctl.LineThickness, 
										Screen.PaletteColor(ctl.LineColor),
										int(GetControlAlpha(ctl.ControlParent, ctl) * 255));
					}
					// Normal line if the text isn't found
					else
						Screen.DrawThickLine(ctl.DrawParams.sxloc - ctl.LineThickness,
										ctl.DrawParams.syloc - GetLineThicknessOffset(ctl.LineThickness, true),
										ctl.DrawParams.sxloc + ctl.Width + ctl.LineThickness,
										ctl.DrawParams.syloc - GetLineThicknessOffset(ctl.LineThickness, true),
										ctl.LineThickness, 
										Screen.PaletteColor(ctl.LineColor),
										int(GetControlAlpha(ctl.ControlParent, ctl) * 255));
					// Bottom
					Screen.DrawThickLine(ctl.DrawParams.sxloc - ctl.LineThickness,
									ctl.DrawParams.syloc + ctl.Height + GetLineThicknessOffset(ctl.LineThickness),
									ctl.DrawParams.sxloc + ctl.Width + ctl.LineThickness,
									ctl.DrawParams.syloc + ctl.Height + GetLineThicknessOffset(ctl.LineThickness),
									ctl.LineThickness, 
									Screen.PaletteColor(ctl.LineColor),
									int(GetControlAlpha(ctl.ControlParent, ctl) * 255));
					// Left
					Screen.DrawThickLine(ctl.DrawParams.sxloc - GetLineThicknessOffset(ctl.LineThickness),
									ctl.DrawParams.syloc,
									ctl.DrawParams.sxloc - GetLineThicknessOffset(ctl.LineThickness),
									ctl.DrawParams.syloc + ctl.Height,
									ctl.LineThickness, 
									Screen.PaletteColor(ctl.LineColor),
									int(GetControlAlpha(ctl.ControlParent, ctl) * 255));
					// Right
					Screen.DrawThickLine(ctl.DrawParams.sxloc + ctl.Width + GetLineThicknessOffset(ctl.LineThickness, true),
									ctl.DrawParams.syloc,
									ctl.DrawParams.sxloc + ctl.Width + GetLineThicknessOffset(ctl.LineThickness, true),
									ctl.DrawParams.syloc + ctl.Height,
									ctl.LineThickness, 
									Screen.PaletteColor(ctl.LineColor),
									int(GetControlAlpha(ctl.ControlParent, ctl) * 255));
					break;
				//
				// Thin Round Groupbox
				//
				case ZGroupBox.BOXTYPE_roundbox:
					// Top split line
					if (!IsEmpty(ctl.BoxText.Text))
					{
						// Left side
						Screen.DrawLine(ctl.DrawParams.sxloc + ctl.CornerRadius,
										ctl.DrawParams.syloc,
										ctl.DrawParams.sxloc + (ctl.BoxText.DrawParams.sxloc - ctl.DrawParams.sxloc) - 3,
										ctl.DrawParams.syloc,
										Screen.PaletteColor(ctl.LineColor),
										int(GetControlAlpha(ctl.ControlParent, ctl) * 255));
						// Right side
						Screen.DrawLine(ctl.DrawParams.sxloc + (ctl.BoxText.DrawParams.sxloc - ctl.DrawParams.sxloc) + getHeaderLongestLine(ctl.BoxText.Text, getWrapWidth(ctl.BoxText.TextWrap, ctl.BoxText.WrapWidth, ctl.Width), ctl.BoxText.TextFont) + 3,
										ctl.DrawParams.syloc,
										ctl.DrawParams.sxloc + ctl.Width - ctl.CornerRadius,
										ctl.DrawParams.syloc,
										Screen.PaletteColor(ctl.LineColor),
										int(GetControlAlpha(ctl.ControlParent, ctl) * 255));
					}
					// Normal line if the text isn't found
					else
						Screen.DrawLine(ctl.DrawParams.sxloc + ctl.CornerRadius,
										ctl.DrawParams.syloc,
										ctl.DrawParams.sxloc + ctl.Width - ctl.CornerRadius,
										ctl.DrawParams.syloc,
										Screen.PaletteColor(ctl.LineColor),
										int(GetControlAlpha(ctl.ControlParent, ctl) * 255));
					// Bottom
					Screen.DrawLine(ctl.DrawParams.sxloc + ctl.CornerRadius,
									ctl.DrawParams.syloc + ctl.Height,
									ctl.DrawParams.sxloc + ctl.Width - ctl.CornerRadius,
									ctl.DrawParams.syloc + ctl.Height,
									Screen.PaletteColor(ctl.LineColor),
									int(GetControlAlpha(ctl.ControlParent, ctl) * 255));
					// Left
					Screen.DrawLine(ctl.DrawParams.sxloc,
									ctl.DrawParams.syloc + ctl.CornerRadius,
									ctl.DrawParams.sxloc,
									ctl.DrawParams.syloc + ctl.Height - ctl.CornerRadius,
									Screen.PaletteColor(ctl.LineColor),
									int(GetControlAlpha(ctl.ControlParent, ctl) * 255));
					// Right
					Screen.DrawLine(ctl.DrawParams.sxloc + ctl.Width,
									ctl.DrawParams.syloc + ctl.CornerRadius,
									ctl.DrawParams.sxloc + ctl.Width,
									ctl.DrawParams.syloc + ctl.Height - ctl.CornerRadius,
									Screen.PaletteColor(ctl.LineColor),
									int(GetControlAlpha(ctl.ControlParent, ctl) * 255));

					// Upper Left Corner
					objectDraw_GroupBoxRadius(ctl.DrawParams.sxloc, ctl.DrawParams.syloc, ctl.Width, ctl.Height,
						ctl.DrawParams.sxloc + ctl.CornerRadius,
						ctl.DrawParams.syloc + ctl.CornerRadius,
						ctl.DrawParams.sxloc,
						ctl.DrawParams.syloc + ctl.CornerRadius,
						ctl.LineColor,
						GetControlAlpha(ctl.ControlParent, ctl),
						ctl.CornerRadius,
						ctl.CornerVertices);
					
					// Upper Right Corner
					objectDraw_GroupBoxRadius(ctl.DrawParams.sxloc, ctl.DrawParams.syloc, ctl.Width, ctl.Height,
						ctl.DrawParams.sxloc + ctl.Width - ctl.CornerRadius,
						ctl.DrawParams.syloc + ctl.CornerRadius,
						ctl.DrawParams.sxloc + ctl.Width - ctl.CornerRadius,
						ctl.DrawParams.syloc,
						ctl.LineColor,
						GetControlAlpha(ctl.ControlParent, ctl),
						ctl.CornerRadius,
						ctl.CornerVertices,
						90);


					// Lower Left Corner
					objectDraw_GroupBoxRadius(ctl.DrawParams.sxloc, ctl.DrawParams.syloc, ctl.Width, ctl.Height,
						ctl.DrawParams.sxloc + ctl.CornerRadius,
						ctl.DrawParams.syloc + ctl.Height - ctl.CornerRadius,
						ctl.DrawParams.sxloc + ctl.CornerRadius,
						ctl.DrawParams.syloc + ctl.Height,
						ctl.LineColor,
						GetControlAlpha(ctl.ControlParent, ctl),
						ctl.CornerRadius,
						ctl.CornerVertices,
						270);

					// Lower Right Corner
					objectDraw_GroupBoxRadius(ctl.DrawParams.sxloc, ctl.DrawParams.syloc, ctl.Width, ctl.Height,
						ctl.DrawParams.sxloc + ctl.Width - ctl.CornerRadius,
						ctl.DrawParams.syloc + ctl.Height - ctl.CornerRadius,
						ctl.DrawParams.sxloc + ctl.Width,
						ctl.DrawParams.syloc + ctl.Height - ctl.CornerRadius,
						ctl.LineColor,
						GetControlAlpha(ctl.ControlParent, ctl),
						ctl.CornerRadius,
						ctl.CornerVertices,
						180);
					break;
				//
				// Thick Round Groupbox
				//
				case ZGroupBox.BOXTYPE_roundthickbox:
					// Top split line
					if (!IsEmpty(ctl.BoxText.Text))
					{
						// Left side
						Screen.DrawThickLine(ctl.DrawParams.sxloc + ctl.CornerRadius - ctl.LineThickness,
										ctl.DrawParams.syloc - GetLineThicknessOffset(ctl.LineThickness, true),
										ctl.DrawParams.sxloc + (ctl.BoxText.DrawParams.sxloc - ctl.DrawParams.sxloc) - 3,
										ctl.DrawParams.syloc - GetLineThicknessOffset(ctl.LineThickness, true),
										ctl.LineThickness, 
										Screen.PaletteColor(ctl.LineColor),
										int(GetControlAlpha(ctl.ControlParent, ctl) * 255));
						// Right side
						Screen.DrawThickLine(ctl.DrawParams.sxloc + (ctl.BoxText.DrawParams.sxloc - ctl.DrawParams.sxloc) + getHeaderLongestLine(ctl.BoxText.Text, getWrapWidth(ctl.BoxText.TextWrap, ctl.BoxText.WrapWidth, ctl.Width), ctl.BoxText.TextFont) + 3,
										ctl.DrawParams.syloc - GetLineThicknessOffset(ctl.LineThickness, true),
										ctl.DrawParams.sxloc + ctl.Width + ctl.LineThickness - ctl.CornerRadius,
										ctl.DrawParams.syloc - GetLineThicknessOffset(ctl.LineThickness, true),
										ctl.LineThickness, 
										Screen.PaletteColor(ctl.LineColor),
										int(GetControlAlpha(ctl.ControlParent, ctl) * 255));
					}
					// Normal line if the text isn't found
					else
						Screen.DrawThickLine(ctl.DrawParams.sxloc + ctl.CornerRadius - ctl.LineThickness,
										ctl.DrawParams.syloc - GetLineThicknessOffset(ctl.LineThickness, true),
										ctl.DrawParams.sxloc + ctl.Width + ctl.LineThickness - ctl.CornerRadius,
										ctl.DrawParams.syloc - GetLineThicknessOffset(ctl.LineThickness, true),
										ctl.LineThickness, 
										Screen.PaletteColor(ctl.LineColor),
										int(GetControlAlpha(ctl.ControlParent, ctl) * 255));
					// Bottom
					Screen.DrawThickLine(ctl.DrawParams.sxloc + ctl.CornerRadius,
									ctl.DrawParams.syloc + ctl.Height,
									ctl.DrawParams.sxloc + ctl.Width - ctl.CornerRadius,
									ctl.DrawParams.syloc + ctl.Height,
									ctl.LineThickness, 
									Screen.PaletteColor(ctl.LineColor),
									int(GetControlAlpha(ctl.ControlParent, ctl) * 255));
					// Left
					Screen.DrawThickLine(ctl.DrawParams.sxloc,
									ctl.DrawParams.syloc + ctl.CornerRadius,
									ctl.DrawParams.sxloc,
									ctl.DrawParams.syloc + ctl.Height - ctl.CornerRadius,
									ctl.LineThickness, 
									Screen.PaletteColor(ctl.LineColor),
									int(GetControlAlpha(ctl.ControlParent, ctl) * 255));
					// Right
					Screen.DrawThickLine(ctl.DrawParams.sxloc + ctl.Width,
									ctl.DrawParams.syloc + ctl.CornerRadius,
									ctl.DrawParams.sxloc + ctl.Width,
									ctl.DrawParams.syloc + ctl.Height - ctl.CornerRadius,
									ctl.LineThickness, 
									Screen.PaletteColor(ctl.LineColor),
									int(GetControlAlpha(ctl.ControlParent, ctl) * 255));
									
					// Upper Left Corner
					objectDraw_GroupBoxRadius(ctl.DrawParams.sxloc, ctl.DrawParams.syloc, ctl.Width, ctl.Height,
						ctl.DrawParams.sxloc + ctl.CornerRadius,
						ctl.DrawParams.syloc + ctl.CornerRadius,
						ctl.DrawParams.sxloc,
						ctl.DrawParams.syloc + ctl.CornerRadius,
						ctl.LineColor,
						GetControlAlpha(ctl.ControlParent, ctl),
						ctl.CornerRadius,
						ctl.CornerVertices,
						thick:true,
						thickness:ctl.LineThickness);
					
					// Upper Right Corner
					objectDraw_GroupBoxRadius(ctl.DrawParams.sxloc, ctl.DrawParams.syloc, ctl.Width, ctl.Height,
						ctl.DrawParams.sxloc + ctl.Width - ctl.CornerRadius,
						ctl.DrawParams.syloc + ctl.CornerRadius,
						ctl.DrawParams.sxloc + ctl.Width - ctl.CornerRadius,
						ctl.DrawParams.syloc,
						ctl.LineColor,
						GetControlAlpha(ctl.ControlParent, ctl),
						ctl.CornerRadius,
						ctl.CornerVertices,
						90,
						true,
						ctl.LineThickness);

					// Lower Left Corner
					objectDraw_GroupBoxRadius(ctl.DrawParams.sxloc, ctl.DrawParams.syloc, ctl.Width, ctl.Height,
						ctl.DrawParams.sxloc + ctl.CornerRadius,
						ctl.DrawParams.syloc + ctl.Height - ctl.CornerRadius,
						ctl.DrawParams.sxloc + ctl.CornerRadius,
						ctl.DrawParams.syloc + ctl.Height,
						ctl.LineColor,
						GetControlAlpha(ctl.ControlParent, ctl),
						ctl.CornerRadius,
						ctl.CornerVertices,
						270,
						true,
						ctl.LineThickness);

					// Lower Right
					objectDraw_GroupBoxRadius(ctl.DrawParams.sxloc, ctl.DrawParams.syloc, ctl.Width, ctl.Height,
						ctl.DrawParams.sxloc + ctl.Width - ctl.CornerRadius,
						ctl.DrawParams.syloc + ctl.Height - ctl.CornerRadius,
						ctl.DrawParams.sxloc + ctl.Width,
						ctl.DrawParams.syloc + ctl.Height - ctl.CornerRadius,
						ctl.LineColor,
						GetControlAlpha(ctl.ControlParent, ctl),
						ctl.CornerRadius,
						ctl.CornerVertices,
						180,
						true,
						ctl.LineThickness);
					break;
			}
		}
	}

	/* END OF METHODS */
}