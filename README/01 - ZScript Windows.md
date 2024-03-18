# ZScript Windows v0.4

![](https://github.com/Saican/ZSWin/blob/master/README/ZSWin_Logo.png)

## A Generic NPC & GUI API for (G)ZDoom

**Written in ZScript!**

ZScript Windows is a generic NPC & GUI API aimed at enabling unique implementations that are flexible and dynamic, specific to the needs of the user, fast, powerful, and simple to use. The entire ZScript Windows API is written in (G)ZDoom's native ZScript, allowing users to design NPCs using standard DECORATE syntax as well as their associated GUI systems rendered at the game's framerate **with multiplayer compatibility**.

Unlike its predecessor, *Z-Windows*, ZScript Windows is actually fairly straightforward to use for developers who are familiar with C++, if not familiar with ZScript.  Getting ZScript Windows up and working is even easier than Z-Windows, requiring no extra compilers or batch files.  ZScript Windows functions just like any other (G)ZDoom mod; literally load your inherting classes after a ZScript Windows source package and start spawning actors!

##### A Bit of History and the Concept of ZScript Windows:
I started delving into GUI design several years ago when I wanted mouse-driven menus for a long dead project called *[all] Alone*.  At the time the only way to do this was through ACS methods.  This pretty much immediately made my GUI systems incompatible with multiplayer games.  My project was singleplayer so it that did not matter.  The project went through three iterations before finally being shelved, and the GUI system went through two distinct iterations as well, one being a full rewrite.  Both systems included the HUD.  This ACS GUI system, while functional, was not expandable.  Then I did an experiment.

I wanted to see if I could create any sort of tiling method for a background image in preparation to create a text-box system.  My method was unreasonable, but it gave me another idea: use one image for a background and clip it off based on a specific width and height.  *Z-Windows* was born.  Over the course of development, Z-Windows was quickly ported to GDCC, and this laid the foundation for the concept of a *ZWindow*.

ZScript Windows, and obviously Z-Windows, gets its name not from Microsoft Windows, but from the X Window System (also ZDoom), which provides the basic GUI functionality for many UNIX-like operating systems. Just like X, ZScript Windows provides just the basic GUI framework without mandating what the actual interface is supposed to look like. The term windows is both a GUI organizational concept and a programming concept the interpretations of which can vary dramatically. ZScript Windows does deviate from X in that the functionality of ZScript Windows is geared toward complete GUI management in a video game architecture and as such can mimic the appearance of an actual operating system but is not actually an operating system.  However, implementation does not restrict what the user intends to do with a window, thus only the limits of ZScript actually restrict the user.

###### The Z-Windows Concept
A ZWindow is an object, programatically.  In Z-Windows, every object was a structure, and being written in C, relied heavily on manual memory management, which I failed at.  The code reached a point where it was too complex to keep plugging memory leaks.  Obviously, being written in ZScript, ZScript Windows objects are primarily classes and memory management is handled more by the game than ZScript Windows; ZScript Windows just helps and trys not to crash the VM.  And for a final leap, ZScript Windows *"ZObjects"* are actors, which means they are simply spawned into the game level.

ZObjects are hybrids of both ZScript contexts, the playsism and the UI-ism.  These contexts, or *"isms"*, are kept separate and are handled by the ZScript Windows Event System, the brains, or ZScript Event Handler.  These two things, ZObjects and the Event System, comprise the entirety of ZScript Windows.  What's more, all ZObjects are essentially the same object, be it a Window or a Button. Finally the API attempts to emulate syntax similar C# and .NET Windows Forms.

[Back to Project Main](https://github.com/Saican/ZSWin "Back to Project Main")