/*
    ZSWin_Control_Graphic.zs

    Graphic Drawing Class Definition

*/

class ZGraphic : ZControl
{
    bool bStretched, bAnimated;
    TextureId Texture;

    enum BORDERTYP
    {
		BORDERTYP_Game,
		BORDERTYP_Line,
		BORDERTYP_ThickLine,
		BORDERTYP_NONE,
    };
    BORDERTYP BorderType;
    int BorderColor;
    float BorderThickness,
        BorderAlpha;


    /*
        This control will behave differently based on the various settings.

        If bStretched is true, Width and Height must be non-zero.
        If bStretched is false, the graphic will be drawn once if Width and Height are 0,
        otherwise the graphic will be tiled.
    
    */
    ZGraphic Init(ZObjectBase ControlParent, bool Enabled, bool Show, string Name, int PlayerClient, bool UiToggle,
        int Width = 0, int Height = 0, float xLocation = 0, float yLocation = 0, float Alpha = 1,
        CLIPTYP ClipType = CLIP_Parent, SCALETYP ScaleType = SCALE_NONE, TEXTALIGN Alignment = TEXTALIGN_Left,
        bool bStretched = false, bool bAnimated = false, string TextureName = "", 
        BORDERTYP BorderType = BORDERTYP_NONE, int BorderColor = 4, float BorderThickness = 1, float BorderAlpha = 1)
    {
		self.Width = Width;
		self.Height = Height;
		self.xLocation = ControlParent.xLocation + xLocation;
		self.yLocation = ControlParent.yLocation + yLocation;
		self.Alpha = Alpha;

        self.bStretched = bStretched;
        self.bAnimated = bAnimated;
        self.Texture = TexMan.CheckForTexture(TextureName, TexMan.TYPE_ANY);
        self.BorderType = BorderType;
        self.BorderColor = BorderColor;
        self.BorderThickness = BorderThickness;
        self.BorderAlpha = BorderAlpha;

        return ZGraphic(super.Init(ControlParent, Enabled, Show, Name, PlayerClient, UiToggle, ScaleType, Alignment, ClipType));
    }

    override void ObjectDraw (ZObjectBase parent)
    {
        ObjectDraw_Graphic(parent, self);
    }

    ui static void ObjectDraw_Graphic(ZObjectBase parent, ZGraphic ctl)
    {
		bool bClipped = GetDrawingControls(ctl, ctl.DrawParams);
	
		if (ctl.Show)
		{
			TextureId txid;
			if (ctl.Texture.IsValid())
				txid = ctl.Texture;
			else
				txid = TexMan.CheckForTexture("-noflat-", TexMan.TYPE_ANY);

			int tx, ty;
			Vector2 txy = TexMan.GetScaledSize(txid);
			tx = txy.x;
			ty = txy.y;

			int twdth = ctl.Width, 
				thght = ctl.Height;
			if (twdth == 0)
				twdth = tx;
			if (thght == 0)
				thght = ty;

			if (txid.IsValid())
			{
				// Stretch texture
				if (ctl.bStretched)
					Screen.DrawTexture(txid, ctl.bAnimated,
						ctl.DrawParams.sxloc, ctl.DrawParams.syloc,
						DTA_Alpha, GetControlAlpha(ctl.ControlParent, ctl),
						DTA_DestWidth, ctl.Width,
						DTA_DestHeight, ctl.Height);
				// Tile texture
				else
				{					
					// Set the clipping boundary - for the draw cycle
					Screen.SetClipRect(ctl.DrawParams.sxloc, ctl.DrawParams.syloc, twdth, thght);
					int w = 0;
					do
					{
						int h = 0;
						do
						{
							Screen.DrawTexture (txid, ctl.bAnimated,
								ctl.DrawParams.sxloc + (tx * w),
								ctl.DrawParams.syloc + (ty * h),
								DTA_Alpha, GetControlAlpha(ctl.ControlParent, ctl),
								DTA_DestWidth, tx,
								DTA_DestHeight, ty);
							h++;
						} while ((((h - 1) * ty) + ty)  < thght);
						w++;
					} while ((((w - 1) * tx) + tx) <= twdth);
					Screen.ClearClipRect();
				}
			}
			else
				console.Printf(string.Format("ZScript Windows - ERROR! - ZGraphic, %s, was unable to find a valid texture!", ctl.Name));

			// Border
			switch (ctl.BorderType)
			{
				case BORDERTYP_Game:
					Screen.DrawFrame(ctl.DrawParams.sxloc, ctl.DrawParams.syloc, twdth, thght);
					break;
				case BORDERTYP_Line:
				// Top
				Screen.DrawLine(ctl.DrawParams.sxloc, 
					ctl.DrawParams.syloc, 
					ctl.DrawParams.sxloc + twdth, 
					ctl.DrawParams.syloc, 
					Screen.PaletteColor(ctl.BorderColor), 
					int(GetControlAlpha(ctl.ControlParent, ctl) * 255));
				// Bottom
				Screen.DrawLine(ctl.DrawParams.sxloc, 
					ctl.DrawParams.syloc + thght, 
					ctl.DrawParams.sxloc + twdth, 
					ctl.DrawParams.syloc + thght, 
					Screen.PaletteColor(ctl.BorderColor), 
					int(GetControlAlpha(ctl.ControlParent, ctl) * 255));
				// Left
				Screen.DrawLine(ctl.DrawParams.sxloc, 
					ctl.DrawParams.syloc, 
					ctl.DrawParams.sxloc, 
					ctl.DrawParams.syloc + thght, 
					Screen.PaletteColor(ctl.BorderColor), 
					int(GetControlAlpha(ctl.ControlParent, ctl) * 255));
				// Right
				Screen.DrawLine(ctl.DrawParams.sxloc + twdth, 
					ctl.DrawParams.syloc, 
					ctl.DrawParams.sxloc + twdth, 
					ctl.DrawParams.syloc + thght, 
					Screen.PaletteColor(ctl.BorderColor), 
					int(GetControlAlpha(ctl.ControlParent, ctl) * 255));
				break;
			case BORDERTYP_ThickLine:
				// Top
				Screen.DrawThickLine(ctl.DrawParams.sxloc - ctl.BorderThickness, 
									ctl.DrawParams.syloc - GetLineThicknessOffset(ctl.BorderThickness, true), 
									ctl.DrawParams.sxloc + twdth + ctl.BorderThickness, 
									ctl.DrawParams.syloc - GetLineThicknessOffset(ctl.BorderThickness, true), 
									ctl.BorderThickness, 
									Screen.PaletteColor(ctl.BorderColor), 
									int(GetControlAlpha(ctl.ControlParent, ctl) * 255));
				// Bottom
				Screen.DrawThickLine(ctl.DrawParams.sxloc - ctl.BorderThickness, 
									ctl.DrawParams.syloc + thght + GetLineThicknessOffset(ctl.BorderThickness), 
									ctl.DrawParams.sxloc + twdth + ctl.BorderThickness, 
									ctl.DrawParams.syloc + thght + GetLineThicknessOffset(ctl.BorderThickness), 
									ctl.BorderThickness, 
									Screen.PaletteColor(ctl.BorderColor), 
									int(GetControlAlpha(ctl.ControlParent, ctl) * 255));
				// Left
				Screen.DrawThickLine(ctl.DrawParams.sxloc - GetLineThicknessOffset(ctl.BorderThickness), 
									ctl.DrawParams.syloc, 
									ctl.DrawParams.sxloc - GetLineThicknessOffset(ctl.BorderThickness), 
									ctl.DrawParams.syloc + thght, 
									ctl.BorderThickness, 
									Screen.PaletteColor(ctl.BorderColor), 
									int(GetControlAlpha(ctl.ControlParent, ctl) * 255));
				// Right
				Screen.DrawThickLine(ctl.DrawParams.sxloc + twdth + GetLineThicknessOffset(ctl.BorderThickness, true), 
									ctl.DrawParams.syloc, 
									ctl.DrawParams.sxloc + twdth + GetLineThicknessOffset(ctl.BorderThickness, true), 
									ctl.DrawParams.syloc + thght, 
									ctl.BorderThickness, 
									Screen.PaletteColor(ctl.BorderColor), 
									int(GetControlAlpha(ctl.ControlParent, ctl) * 255));
					break;
			}
        }
    }

    /* END OF METHODS */
}