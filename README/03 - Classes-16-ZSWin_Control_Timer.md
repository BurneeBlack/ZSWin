# ZScript Windows v0.4.1

![](https://github.com/Saican/ZSWin/blob/master/README/ZSWin_Logo.png)

## Class ZTimer : ZControl abstract
### Timer Event Control

------------
This control executes an event after a specific period of time has passed; in game ticks (1/35th of a second).  The control is switched on and off by user code using the control's *Enabled* member.  It may be ticked early by simply setting the *Enabled* member to **false**.  If the control's countdown completes, the tick event will be executed.  Users can control for if the timer should reset its countdown or disable itself.

------------

#### Public Members: 
 - **Ticks**, int, specifies how many ticks must pass before the timer event will be executed.

------------
#### Methods:
- *Remember!* - ZScript has a method argument skipping mechanic called "named arguments", which is utilized by ZScript Windows.  Do not be overwhelmed by the constructor argument list, the majority is defaulted allowing you to set what you need and skip the rest.
- Note that defaulted arguments are named in braces [ ].

1. **int GetCurrentTick** - returns how many ticks remain in the countdown.
2. **ZTimer Init** - ZTimer constructor.  This control does not have a visual presence, thus the Show member is omitted from the argument list.
	- **ControlParent**, ZObjectBase, reference to the ZObject containing this control.
	- **Enabled**, bool, if true the control will immediately begin counting down.
	- **Name**, string, name of this object.  Names must be unique!
	- **PlayerClient**, int, the consoleplayer this control corresponds to.
	- **UiToggle**, bool, if true the creation of this object causes UI Mode to be activated for the consoleplayer this control's parent window corresponds to.
	- **[Ticks]**, int, specifies how many ticks must pass before the timer event will execute.  Defaults to 0.
	- **[CountOnce]**, bool, defaults to true, if set to false the timer will repeat its countdown until the *Enabled* member is set to **false**.
3. **virtual void TimerEvent** - the event that will be called upon completion of the countdown.  This method has no arguments and must be overridden by the user in order to define the code to execute when the event is called.

------------
#### Usage Example:

```cpp

```


------------


[Back to Class Detail Links](https://github.com/Saican/ZSWin/blob/master/README/03%20-%20Classes.md)

------------


[Back to Project Main](https://github.com/Saican/ZSWin "Back to Project Main")
