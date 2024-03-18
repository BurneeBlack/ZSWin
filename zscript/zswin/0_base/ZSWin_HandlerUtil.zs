/*
	ZSWin_HandlerUtil.zs
	
	Base class for EventSystem

*/

class ZSHandlerUtil : EventHandler
{
	// This is the ZScript Windows Version
	const ZVERSION = "0.4.2";

	override void OnRegister()
	{
		nukaBlasts.Push("Author: Uncredited\n     _.-^^---....,,--\n _--                  --_\n<                        >)\n|                         |\n \._                   _./\n    ```--. . , ; .--'''\n          | |   |\n       .-=||  | |=-.\n       `-=#$%%&%%$#=-'\n          | ;  :|\n _____.,-#%%&$@%%#&#~,._____\n\nASCII Art from: https://www.asciiart.eu/weapons/explosives\n\n");
		nukaBlasts.Push("Author: Bill March\n                             ____\n                     __,-~~/~    `---.\n                   _/_,---(      ,    )\n               __ /        <    /   )  \___\n- ------===;;;'====------------------===;;;===----- -  -\n                  \/  ~\"~\"~\"~\"~\"~\~\"~)~\"/\n                  (_ (   \  (     >    \)\n                   \_( _ <         >_>'\n                      ~ `-i' ::>|--\"\n                          I;|.|.|\n                         <|i::|i|`.\n                        (` ^'\"`-' \")\n\nASCII Art from: https://www.asciiart.eu/weapons/explosives\n\n");
		nukaBlasts.Push("Author: Uncredited\n              _______\n         ____/ (  )   \\___\n        /( (  )  _ )  )  )\\\n      ((    (  )( ) )  (  ) )\n    ((/  ( _  ) (  _ ) ( ()   )\n   ( (  ( _) (( (  ) .((_ ).  )_\n  ( (  ) (    ( )  )   ) .) (   )\n (  (  ( ( ) (_ ( _) ). ) .) ) ( )\n ( (  ( ) ( )  ( ))  ) _)(  )  )  )\n( (  ( \\ )( (_  ( ) ) ) ) )  )) ( )\n (  (  ( ( (_ () (_   ) ) ( )  )   )\n( (  ( ( ( ) (_  ) ) ) _)  ) _( ( )\n ((  (  )(  (   _  ) _) _(_ (  (_ )\n  (_((__(_(_((((|) )))_))__))_)___)\n  ((__)    \\\\||ll|l||///      \\_))\n          ( /(/() ))\\  )\n         (  ( ( (||)))\\  )\n        ( /(| /() ) )))\n       (   ((((((|)_)))   )\n        (  ||\\(|(|)/||  )\n      (     |(||(|)||      )\n         (  //|/l)|\\ \\   )\n      (/ /// /|//|\\\\ \\ \\ \\ _)\n\nASCII Art from: https://www.asciiart.eu/weapons/explosives\n\n");

		super.OnRegister();
	}

	/*
		Returns a value equal to the lowest possible
		Event Handler Order not used by another handler.
		
		What?  It automates the call to SetOrder and works
		like getting a unique TID.  The number returned is
		not used by any other event handler.
		
		Per the wiki, for inputs, a higher number receives the event first,
		for render events, a higher number receives the event last.
		
		What's not known is what happens if two event handlers share the same order.
		This method is an attempt to give the ZScript Windows handlers unique order
		numbers should other event handlers be present and set order numbers to
		avoid any potential conflicts.
	
	*/
	static int GetLowestPossibleOrder()
	{
		int highestOrder = 0;
		array<string> handlerNames;
		for (int i = 0; i < AllClasses.Size(); i++)
		{
			if (AllClasses[i] is "StaticEventHandler")
				handlerNames.Push(AllClasses[i].GetClassName());
		}
		
		for (int i = 0; i < handlerNames.Size(); i++)
		{
			let handler = EventHandler.Find(handlerNames[i]);
			if (handler && handler.Order > highestOrder)
				highestOrder = handler.Order;
		}
		
		return highestOrder + 1;
	}
	
	/*
		Just for fun, crash scenarios that can't be
		escaped can call this method for a fun VM abort message.
		
		The message argument can be formatted to whatever output you can get.
	
	*/

	array<string> nukaBlasts;

	clearscope static void HaltAndCatchFire(EventHandler e, string message)
	{
		console.printf(string.Format("\n\cgZScript Windows - ABORT! - Error message received: \cf%s\n\n", message));
		ThrowAbortException("\n - - WAR, WAR NEVER CHANGES - -\n\n%s%s%s",
			ZSHandlerUtil(e).nukaBlasts[random(0, ZSHandlerUtil(e).nukaBlasts.Size() - 1)],
			" - - YES YOU DID THAT!  YOU!  IDK WHAT YOU DID BUT IT'S ALL YOUR FAULT!\n\n",
			" - - FULL NUCLEAR ARSENAL UNLEASHED - GOODBYE VM!");
	}
	
	/*
		This method is a very bad way to check that a given
		name corresponds to a known class.  It's bad because
		of the time complexity, even though it's linear, the
		size of the array it searches may be quite large.
		What this means is that use of this method when loaded
		with large mods will be less efficient than with the
		base games.
		
	*/
	clearscope static bool ClassNameIsAClass(string classname)
	{
		for (int i = 0; i < AllClasses.Size(); i++)  // The vm gods have to hate me
		{
			if (AllClasses[i].GetClassName() == classname)
				return true;
		}
		// This search is bad enough that while I'm not going to VM crash for failure, I'm still going to send a console message.
		console.Printf(string.Format(" - - ZScript Windows, ClassNameIsAClass usage failed looking for a class named, %s.\n - - Please note that this method is costly on processing time and should not be used in conditions where failure is likely.", classname));
		return false;
	}
	
	/* - END OF METHODS - */
}