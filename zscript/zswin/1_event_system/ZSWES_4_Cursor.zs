/*

    ZSWES_4_Cursor.zs

    ZScript Windows v0.4.2 Event Handler Cursor Methods Extension

    Sarah Blackburn
    10-03-2024
    DD-MM-YYYY

    This file extends the event handler class to contain
    relevent methods for controlling the cursor.

*/

extend class ZEventSystem
{
	/*
		Sends the toggle cursor event, if UI processing
		isn't already on.
	
	*/
	void SendUIToggleEvent()
	{
		if (!self.IsUiProcessor)
			zEventCommand("zevsys_UI_cursorToggle", consoleplayer);
	}
	
	/*
		Toggles the system bools required for mouse control
	*/
	private void cursorToggle()
	{
		self.IsUiProcessor = !self.IsUiProcessor;
		self.RequireMouse = !self.RequireMouse;		
	}

    /*
		Wrapper for checking if the given key is the bind for the cursor toggle
	*/
	clearscope private bool keyIsCursorBind(int keyId)
	{
		int key1, key2;
		[key1, key2] = Bindings.GetKeysForCommand("zswin_cmd_cursorToggle");
		return ((key1 && key1 == keyId) || (key2 && key2 == keyId));
	}
	
	/*
		Checks if the given key is any of the supported keys for QuikClose.
		
		Future expansion should hopefully support Esc and tilde (~)
		
		Woohoo!  QuikClose now supports Esc and tilde!
	*/
	private void quickCloseCheck(string keyId, int askey)
	{
		int key1, key2;
		bool quikclose = false;
		
		// Esc key - this is always checked
		if (askey == 27)
			quikclose = true;
		
		// If a control isn't needing full keyboard control - check the tilde key and binds
		if (!bNiceQuikClose)
		{
			// tilde key
			if (askey == 96)
				quikclose = true;
			// The rest are key binds - pretty self explanatory
			[key1, key2] = Bindings.GetKeysForCommand("+forward");
			if(KeyBindings.NameKeys(key1, key2) ~== keyId)
				quikclose = true;
			[key1, key2] = Bindings.GetKeysForCommand("+back");
			if(KeyBindings.NameKeys(key1, key2) ~== keyId)
				quikclose = true;
			[key1, key2] = Bindings.GetKeysForCommand("+moveleft");
			if(KeyBindings.NameKeys(key1, key2) ~== keyId)
				quikclose = true;
			[key1, key2] = Bindings.GetKeysForCommand("+moveright");
			if(KeyBindings.NameKeys(key1, key2) ~== keyId)
				quikclose = true;
			[key1, key2] = Bindings.GetKeysForCommand("+left");
			if(KeyBindings.NameKeys(key1, key2) ~== keyId)
				quikclose = true;
			[key1, key2] = Bindings.GetKeysForCommand("+right");
			if(KeyBindings.NameKeys(key1, key2) ~== keyId)
				quikclose = true;
			[key1, key2] = Bindings.GetKeysForCommand("turn180");
			if(KeyBindings.NameKeys(key1, key2) ~== keyId)
				quikclose = true;
			[key1, key2] = Bindings.GetKeysForCommand("+jump");
			if(KeyBindings.NameKeys(key1, key2) ~== keyId)
				quikclose = true;
			[key1, key2] = Bindings.GetKeysForCommand("+crouch");
			if(KeyBindings.NameKeys(key1, key2) ~== keyId)
				quikclose = true;
			[key1, key2] = Bindings.GetKeysForCommand("crouch");
			if(KeyBindings.NameKeys(key1, key2) ~== keyId)
				quikclose = true;
		}
		
		if (quikclose)
			zEventCommand("zevsys_UI_CursorToggle", consoleplayer);
	}
	
	/*
		Gets the cursor packet from the last tick.
	*/
	private void updateCursorData(int type, int player, string key, int kchar, int mx, int my, bool ishft, bool ialt, bool ictrl)
	{
		cursor.EventType = type;
		cursor.PlayerClient = player;
		cursor.KeyString = key;
		cursor.KeyChar = kchar;
		cursor.MouseX = mx;
		cursor.MouseY = my;
		cursor.IsShift = ishft;
		cursor.IsAlt = ialt;
		cursor.IsCtrl = ictrl;
	}

    /* END OF METHODS */
}