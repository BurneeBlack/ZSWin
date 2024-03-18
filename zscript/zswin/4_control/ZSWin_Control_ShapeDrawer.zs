/*
    ZSWin_Control_ShapeDrawer.zs

    This control allows for an arbitrary shape to
    be drawn to the screen.

*/

/*
    Ok so to use the Shape2D class, there are a couple steps.

    1. Map texture coodinates
        - This is done using Shape2D.PushCoord()
        - This function takes a Vector2
            - The relevant members of the Vector2 class will likely be the X and Y members
            - These members are doubles

    2. Triangulate the shape
        - This is done using Shape2D.PushTriangle()
        - This functions arguments are the indices of each texture coordinate
          of the triangle.
        - From the example it appears that indices should go counter-clockwise

    3. Establish screen vertices
        - There should be as many vertices as texture coordinates
        - They should also be Vector2
        - Once established they should be pushed to the Shape2D with the Shape2D.PushVertex() function.

    4. If anything needs to change
        - Call the Shape2D.Clear() function.
        - This function takes an enumeration representing which array to clear
        - New information may then be pushed to the cleared array

    5. Drawing the shape
        - Call Screen.DrawShape();

*/

/*
    This is a wrapper class for Vector2's since they can't be used in dynamic arrays

*/
class ShapeVec
{
    Vector2 Coords;

    ShapeVec Init(double x, double y)
    {
        Coords = (x, y);
        return self;
    }

    ShapeVec Init_R(ShapeVec c)
    {
        Coords = (c.Coords.x, c.Coords.y);
        return self;
    }
}

/*
    This is the base class for ZShapes and ShapeBosses

*/
class ZShape_Control_Base : ZControl abstract
{
    enum SHAPE_PROTOTYPE
    {
        SHPROT_Triangle = 3,
        SHPROT_Square,
        SHPROT_Pentagon,
        SHPROT_Hexagon,
        SHPROT_Heptagon,        // This is the fully greek name for a 7-gon
        SHPROT_Septagon = 7,    // This is a valid name for a 7-gon, it just mixes Latin and Greek (it's what I called it initially)
        SHPROT_Octagon,
        SHPROT_Nonagon,
        SHPROT_Decagon,
        SHPROT_Hendecagon,      // I did not know that was an 11-gon
        SHPROT_Dodecagon,
        SHPROT_Circle = 0,
        SHPROT_none = -1,
    }; 

    enum BOSS_ANCHOR
    {
        BANCHOR_Center,
        BANCHOR_UpperLeft,
        BANCHOR_UpperRight,
        BANCHOR_LowerLeft,
        BANCHOR_LowerRight
    }; 

    /*
        Does ZScript seriously have no pow function????
        Ok, I'll do it myself, I'd like to know if there's
        a way to shift bytes somehow that'd made this much
        faster, this may be linear, but iterative length
        is gonna grow at higher powers.
    */
    float pow(float a, float b)
    {
        float n = 1;
        for (int i = 0; i < b; i++)
            n *= a;
        return n;
    } 
}

/*
    This control is not meant to be used directly.  It's a part of
    the ZShape class, which handles ShapeBosses.

    "Boss" here is used as in the engineering definition of the word.
    A boss is a protruding feature on a workpiece commonly used to
    locate one object within a pocket or hole of another object.

    In this case the ShapeBoss is either a simple shape or,
    the result of knitting several shapes together.
    
    There may be several bosses within one ZShape.
    This is governed by the ZShape type - either simple or complex.

    A simple shape will just be the shape data that was supplied
    upon construction.  If several shapes are present in the ZShape,
    they are drawn exactly the same as described in a WYSIWYG configuration.

    A complex shape considers each subsequent shape in the array as the
    interior boundary of the shape.  This is achieved through "knitting"
    both shapes into one shape.  This does not neccessarily erase the
    inner shape as this process can happen repeatedly to achieve
    different results.  This can/will have a target-like appearance.

    Note that VertCount supersedes the prototype - the prototype is just
    an easy way to establish a shape quickly.
*/
class ShapeBoss : ZShape_Control_Base
{
    BOSS_ANCHOR WorkPointSetting;
    float WorkPointX,
        WorkPointY;

    SHAPE_PROTOTYPE Prototype;

    TextureId Texture;
    Shape2D Shape;

    array<ShapeVec> TexVerts;
    array<ShapeVec> ShapeVerts;

    float ShapeScaleX,
        ShapeScaleY,
        AngleOffset,
        TextureRadius;

    int VertCount;

    bool bAnimated,
        bStretched,
        bSquared,
        bVertexListed;

    ShapeBoss Init (ZObjectBase ControlParent, bool Enabled, bool Show, string Name, int PlayerClient, bool UiToggle,
        SHAPE_PROTOTYPE Prototype = SHPROT_Square, BOSS_ANCHOR WorkPointSetting = BANCHOR_Center,
        string ShapeTexture = "", bool bAnimated = false, bool bStretched = true, 
        float ShapeScaleX = 1.0, float ShapeScaleY = 1.0, int VertCount = 4, bool bSquared = true, float AngleOffset = 0.0,
        int Width = 0, int Height = 0, float xLocation = 0, float yLocation = 0, float Alpha = 1, bool bVertexListed = false)
    {
        // Prototype and VertCount - if you want a shape with more verts than the enums can provide, use the VertCount
        // otherwise use the enumeration
        if (VertCount > SHPROT_Dodecagon)
        {
            self.Prototype = SHPROT_none;
            self.VertCount = VertCount;
        }
        else
        {
            self.Prototype = Prototype;
            self.VertCount = Prototype;
        }

        // Set the texture id - default if there isn't one
        if (IsEmpty(ShapeTexture))
            self.Texture = TexMan.CheckForTexture("TGRAY", TexMan.TYPE_Any);
        else
            self.Texture = TexMan.CheckForTexture(ShapeTexture, TexMan.TYPE_Any);
        // Check that there is a valid texture otherwise call up the engine's "noflat", that's a last ditch attempt and should exist.
        if (!self.Texture.IsValid())
            self.Texture = TexMan.CheckForTexture("-noflat-", TexMan.TYPE_Any);

        // Work Points are thought of similar to the Work Coordinates in CNC - this is a 0, 0 location to start things from.
        // These are used in finalizing the Shape Vertices to locate the shape on either a corner or the center.
        Vector2 tsiz = TexMan.GetScaledSize(self.Texture);
        TextureRadius = Sqrt(pow(tsiz.x / 2, 2) + pow(tsiz.y / 2, 2));
        self.WorkPointSetting = WorkPointSetting;
        switch(self.WorkPointSetting)
        {
            case BANCHOR_Center:
                WorkPointX = 0;
                WorkPointY = 0;
                break;
            case BANCHOR_UpperLeft:
                WorkPointX = TextureRadius;
                WorkPointY = TextureRadius;
                break;
            case BANCHOR_UpperRight:
                WorkPointX = TextureRadius * -1;
                WorkPointY = TextureRadius;
                break;
            case BANCHOR_LowerLeft:
                WorkPointX = TextureRadius;
                WorkPointY = TextureRadius * -1;
                break;
            case BANCHOR_LowerRight:
                WorkPointX = TextureRadius * -1;
                WorkPointY = TextureRadius * -1;
                break;
        }

        // If the texture is animated the screen call can account for that.
        self.bAnimated = bAnimated;
        // Generally a texture is stretched across the shape vertices so that it obeys scaling.  It will tile if set to false
        self.bStretched = bStretched;

        self.Shape = new("Shape2D");

        // ShapeScaleN works like the scale values of the TEXTURES lump
        self.ShapeScaleX = ShapeScaleX;
        self.ShapeScaleY = ShapeScaleY;

        // If the number of sides in the shape is a multiple of 4, 
        // this will cause the shape to rotate to square the shape, 
        // defaults to true, set to false to default shape
        self.bSquared = bSquared;
        // This will rotate the shape from it's default angle
        self.AngleOffset = AngleOffset;

        // Width and Height have control over the clipping boundaries of the object
        // So this either defaults to the given texture size or to a given Width and Height
        if (!Width)
            self.Width = tsiz.x;
        else
            self.Width = Width;
        if (!Height)
            self.Height = tsiz.y;
        else
            self.Height = Height;

        // Standard X/Y locations and alpha
        self.xLocation = ControlParent.xLocation + xLocation;
        self.yLocation = ControlParent.yLocation + yLocation;
        self.Alpha = Alpha;

        // Debugging boolean this will cause the drawer to draw numbers corresponding to each vertex of the shape
        self.bVertexListed = bVertexListed;

        // This generates the base shape - should it be complex that is handled by the ZShape
        generateShape();

        console.printf(string.format("Shape boss: x: %f, y:%f", self.xLocation, self.yLocation));

        return ShapeBoss(super.Init(ControlParent, Enabled, Show, Name, PlayerClient, UiToggle, ZControl(ControlParent).ScaleType, ClipType:ControlParent.ClipType));
    }

    override bool ZObj_UiTick()
    {
        return super.ZObj_UiTick();
    }

    override void ObjectDraw(ZObjectBase parent)
    {
        ObjectDraw_Shape(self);
    }

    /*
        Unlike other draw functions, the Shape2D does
        not allow for dynamic drawing.  This means that
        all changes to a shape must happen prior to
        the shape being drawn.

    */
    ui static void ObjectDraw_Shape(ShapeBoss shp)
    {
        bool bClipped = GetDrawingControls(shp, shp.DrawParams);

        if (shp.Show)
        {
            if (bClipped)
                Screen.SetClipRect(shp.DrawParams.pclipX + GetLeftClipOff(shp, "main"),
                    shp.DrawParams.pclipY + GetTopClipOff(shp, "main"),
                    shp.DrawParams.pclipWdth + GetTopClipOff(shp, "main"),
                    shp.DrawParams.pclipHght + GetBottomClipOff(shp, "main"));

            Screen.DrawShape(shp.Texture, shp.bAnimated, shp.Shape,
                DTA_Alpha, GetControlAlpha(shp.ControlParent, shp));

            if (shp.bVertexListed)
            {
                for (int i = 0; i < shp.ShapeVerts.Size(); i++)
                    Screen.DrawText(Font.GetFont('consolefont'), 0, shp.ShapeVerts[i].Coords.x, shp.ShapeVerts[i].Coords.y, string.format("%d", i));
            }

            if (bClipped)
                Screen.ClearClipRect();
        }
    }

    /*
        The angle calculated to "square" a shape
        will always be negative.  This function
        returns 0 if the bSquared member is false,
        or the number of vertices does not make
        it a multiple of 4 - no internal angle is 90
        degrees otherwise.
    */
    private float getSquareAngle(float ca)
    {
        if (bSquared && VertCount % 4 == 0)
            return ca / 2 * - 1;
        return 0;
    }

    /*
        The Coordinate Angle is just how many
        degrees apart each vertex needs to be
        to draw the shape.  These can be effected
        by the Angle Offset and the bSquared members.
        This function takes those into account,
        and clamps the true angle value between 
        0 and 360.
    */
    private float getTrueAngle(int i, float ca)
    {
        if (AngleOffset != 0)
        {
            if ((ca * i) + AngleOffset + getSquareAngle(ca) < 0)
                return 360 + ((ca * i) + AngleOffset + getSquareAngle(ca));
            else if ((ca * i) + AngleOffset + getSquareAngle(ca) > 360)
                return ((ca * i) + AngleOffset + getSquareAngle(ca)) - 360;
            else
                return (ca * i) + AngleOffset + getSquareAngle(ca);
        }
        else
            return (ca * i) + getSquareAngle(ca);

        return 0;
    }

    /*
        This function generates the shape
        from the constructor data.

        At this point the shape could be considered static.
    */
    private void generateShape()
    {
        Vector2 tsiz = TexMan.GetScaledSize(Texture);

        // Calculate the radius and base angle
        float coordang = 360.0 / float(VertCount);

        // Generate Raw Coordinates and Convert to Texture Coordinates
        // - this is done in one shot in the algorithm
        Shape.PushCoord((0.5, 0.5));    // Center of circle
        for (int i = 0; i < VertCount; i++)
            TexVerts.Push(new("ShapeVec").Init(((((TextureRadius * (bStretched ? 1 : ShapeScaleX)) * Cos(getTrueAngle(i, coordang))) / tsiz.x) + 1) / 2,
                ((((TextureRadius * (bStretched ? 1 : ShapeScaleY)) * Sin(getTrueAngle(i, coordang))) / tsiz.y) + 1) / 2));

        // Push the texture coordinates to the shape
        for (int i = 0; i < TexVerts.Size(); i++)
            Shape.PushCoord(TexVerts[i].Coords);

        // Push the triangles
        Shape.PushTriangle(0, 1, VertCount);    // indices for the first triangle don't follow the pattern, all the others do.
        for (int i = VertCount; i > 1; i--)
            Shape.PushTriangle(0, i, i - 1);    // we rotate counter-clockwise, 0 - or the center is always the first index

        // Push Shape Vertices
        // This is the center vertex
        ShapeVerts.Push(new("ShapeVec").Init(xLocation + WorkPointX, yLocation + WorkPointY));
        // Generate the vertices on the circle
        // - NOTE that it is not an error that the texture radius is always multiplied by the ShapeScaleN members.
        // - The shape verts must always be multipied by ShapeScaleN to always scale, the tex coords either stretch or tile depending on bStretched
        for (int i = 0; i < VertCount; i++)
            ShapeVerts.Push(new("ShapeVec").Init((TextureRadius * ShapeScaleX) * Cos(getTrueAngle(i, coordang)) + (xLocation + WorkPointX),
                (TextureRadius * ShapeScaleY) * Sin(getTrueAngle(i, coordang)) + (yLocation + WorkPointY)));
        // Push them to shape
        for (int i = 0; i < ShapeVerts.Size(); i++)
            Shape.PushVertex(ShapeVerts[i].Coords);
    }
}

class ZShape : ZShape_Control_Base
{
    enum SHAPE_TYPE
    {
        SHTYPE_Simple,
        SHTYPE_Complex,
    };

    SHAPE_TYPE Type;

    array<ShapeBoss> Bosses;

    bool bVertexListed;

    /*
        Wrapper for spawning and initializing a ShapeBoss.
        Does not insert the boss into the array.

    */
    bool, ShapeBoss CreateBoss(bool Enabled, bool Show, string Name, int PlayerClient, bool UiToggle,
        SHAPE_PROTOTYPE Prototype = SHPROT_Square, BOSS_ANCHOR WorkPointSetting = BANCHOR_Center,
        string ShapeTexture = "", bool bAnimated = false, bool bStretched = true, 
        float ShapeScaleX = 1.0, float ShapeScaleY = 1.0, int VertCount = 4, bool bSquared = true, float AngleOffset = 0.0,
        int Width = 0, int Height = 0, float xLocation = 0, float yLocation = 0, float Alpha = 1, bool bVertexListed = false)
    {
        bool spwned;
        actor boss;
        [spwned, boss] = A_SpawnItemEx("ShapeBoss", self.pos.x, self.pos.y, self.pos.z, self.vel.x, self.vel.y, self.vel.z, self.angle, 0, 0, self.tid);
        if (spwned && boss)
            return spwned, ShapeBoss(boss).Init(self, Enabled, Show, Name, PlayerClient, UiToggle,
                Prototype, WorkPointSetting,
                ShapeTexture, bAnimated, bStretched,
                ShapeScaleX, ShapeScaleY, VertCount, bSquared, AngleOffset,
                Width, Height, xLocation, yLocation, Alpha, bVertexListed);
        return spwned, null;
    }

    /*
        Wrapper for CreateBoss().
        This function does insert the boss into the array.

    */
    bool InsertBoss(bool Enabled, bool Show, string Name, int PlayerClient, bool UiToggle,
        SHAPE_PROTOTYPE Prototype = SHPROT_Square, BOSS_ANCHOR WorkPointSetting = BANCHOR_Center,
        string ShapeTexture = "", bool bAnimated = false, bool bStretched = true, 
        float ShapeScaleX = 1.0, float ShapeScaleY = 1.0, int VertCount = 4, bool bSquared = true, float AngleOffset = 0.0,
        int Width = 0, int Height = 0, float xLocation = 0, float yLocation = 0, float Alpha = 1, bool bVertexListed = false)
    {
        bool spwned;
        actor boss;
        [spwned, boss] = CreateBoss(Enabled, Show, Name, PlayerClient, UiToggle,
            Prototype, WorkPointSetting,
            ShapeTexture, bAnimated, bStretched,
            ShapeScaleX, ShapeScaleY, VertCount, bSquared, AngleOffset,
            Width, Height, xLocation, yLocation, Alpha, bVertexListed);
        if (spwned && boss)
            Bosses.Push(ShapeBoss(boss));

        return spwned;
    }

    /*
        This function combines the bosses into a complex shape
        and should be called on a ZShape once configuration is complete.

    */
    void Knit()
    {
        // Iterate through the list of bosses
        for (int i = 0; i < Bosses.Size(); i++)
        {
            // Check that there is another boss after the current one
            if (i + 1 < Bosses.Size())
            {
                // Copy the next bosses textures coordinates to the current boss
                // - - generateShape does not store the center point in the TexVerts
                for (int j = 0; j < Bosses[i + 1].TexVerts.Size(); j++)
                    Bosses[i].TexVerts.Push(new("ShapeVec").Init_R(Bosses[i + 1].TexVerts[j]));
                // Clear out the texture coordinates from the current shape - don't need the center point now
                Bosses[i].Shape.Clear(Shape2D.C_Coords);
                // Regenerate the coordinates
                for (int j = 0; j < Bosses[i].TexVerts.Size(); j++)
                    Bosses[i].Shape.PushCoord(Bosses[i].TexVerts[j].Coords);
                
                // Re-triangulate the current shape
                // Clear out the triangle indices
                Bosses[i].Shape.Clear(Shape2D.C_Indices);
                // The knitted vertex count is equal to the vertex counts of both bosses
                int kvc = Bosses[i].VertCount + Bosses[i + 1].VertCount;
                // Now if the first boss (the outer boss) has more vertices than the second (inner),
                // we use it's vertex count for triangulation - or if their equal
                if (Bosses[i].VertCount > Bosses[i + 1].VertCount || Bosses[i].VertCount == Bosses[i + 1].VertCount)
                {
                    
                }
                // Otherwise we use the inner boss
                else
                {

                }
            }
        }
    }

    ZShape Init(ZObjectBase ControlParent, bool Enabled, bool Show, string Name, int PlayerClient, bool UiToggle,
        CLIPTYP ClipType = CLIP_Parent, SCALETYP ScaleType = SCALE_NONE, 
        SHAPE_TYPE Type = SHTYPE_Simple, ShapeBoss SimpleBoss = null, bool bVertexListed = false,
        int Width = 0, int Height = 0, float xLocation = 0, float yLocation = 0, float Alpha = 1)
    {
        // Type is an enumeration to make it more verbose, but it's also a consistency thing.
        self.Type = Type;
        // This is meant for instances of a single shape, which can be pre-initialized and then inserted
        // when creating the actual ZShape.  Creating a complex shape has further initialization akin to the Dialog control.
        if (self.Type == SHTYPE_Simple && SimpleBoss)
            Bosses.Push(SimpleBoss);

        // This is a debugging boolean, if true, the ShapeVerts array is used to draw a number next to each vertex
        self.bVertexListed = bVertexListed;
        if (self.Type == SHTYPE_Simple && Bosses.Size() == 1 && self.bVertexListed)
                Bosses[0].bVertexListed = self.bVertexListed;

        // Width and Height have control over the clipping boundaries of the object
        // So this either defaults to the parent or to a given Width and Height
        if (!Width)
            self.Width = ControlParent.Width;
        else
            self.Width = Width;
        if (!Height)
            self.Height = ControlParent.Height;
        else
            self.Height = Height;

        // Standard X/Y locations and alpha
        self.xLocation = ControlParent.xLocation + xLocation;
        self.yLocation = ControlParent.yLocation + yLocation;
        self.Alpha = Alpha;

        float nwdx, nwdy;
        [nwdx, nwdy] = GetParentWindowLocation(ControlParent);
        console.printf(string.format("Shape : x: %f, y:%f\nWindow: x: %f, y: %f", self.xLocation, self.yLocation, nwdx, nwdy));

        return ZShape(super.Init(ControlParent, Enabled, Show, Name, PlayerClient, UiToggle, ScaleType, ClipType:ClipType));
    }

    override void Tick()
    {
        if (self.bSelfDestroy && Bosses.Size() > 0)
        {
            for (int i = 0; i < Bosses.Size(); i++)
                Bosses[i].bSelfDestroy = true;
        }
        super.Tick();
    }

    override bool ZObj_UiTick()
    {
        for (int i = 0; i < Bosses.Size(); i++)
        {
            if (Bosses[i].ZObj_UiTick())
                return true;
        }
        return super.ZObj_UiTick();
    }

    override void ObjectDraw(ZObjectBase parent)
    {
        for (int i = 0; i < Bosses.Size(); i++)
            Bosses[i].ObjectDraw(self);
    }

    /* END OF METHODS */
}

