/*
	ZSWin_Control_Dialog.zs
	
	A conversation control.
	This control and its sub components
	function similarly to USDF.

*/

/*
	This is the base class that is put into the window.
	It is analogous to the Conversation block; the "actor"
	property, which is set to the ConversationID, does not
	exist here.  This class still follows ZScript Windows
	control conventions and should be treated as such.
	
	This control, while existing in the game world, does
	not have an actual appearance in it, or onscreen would
	be the right way to say it.  This is a container
	control, similar to a Windows Forms Timer control, or
	the Open/Save File Dialogs.  You don't see the control
	itself, but what it does has an impact on how the
	windows functions.

*/
class ZConversation : ZControl
{
	const NUMCHOICES = 5;

	/*
		If bTransferToActor is true,
		cost exchanges will transfer
		the currency to the root actor's
		inventory.
	*/
	bool bTransferToActor;

	/*
		bDropAtSpot allows the control
		to spawn objects at a particular
		location in the game level.

		bDropSpotFog will allow TeleportFog
		to be spawn as well.

		DropSpotId is the TID of the actor
		to spawn items from.

		DropClass is the class name of the
		object to drop at.  This will be
		used to search for the right object.
	*/
	bool bDropAtSpot, bDropSpotFog;
	int DropSpotId;
	string DropClass;

	/*
		Set to true if the NPC is dead.
			- Need to see what resurrection does.
	*/
	private bool bDead;

	/*
		This is how long the control will wait
		before changing pages when a choice is made.
		This is to allow the Yes Message to display.
	*/
	int WaitMessageTicks;
	bool WaitForMessage;
	
	// What actually displays the NPC name string
	ZText NPCName,
	// What actually displays the NPC dialog string
		NPCDialog;

	// What actually displays the NPC portrait
	ZGraphic NPCPortrait;
	
	ZButton PlayerChoices[NUMCHOICES];
	private array<ZDialogPage> dialogPages;
	void AddDialogPage(ZDialogPage newPage) 
	{ 
		if (newPage != null)
			dialogPages.Push(newPage); 
		else
			console.Printf(string.Format("ZScript Windows - WARNING - attempt to push NULL Dialog Page to ZConversation, %s, blocked!", self.Name));
	}
	// Lets you find a dialog page index by the name
	int FindDialogPageNumber(string pn)
	{
		for (int i = 0; i < dialogPages.Size(); i++)
		{
			if (dialogPages[i].PageName == pn)
				return i;
		}

		return -1;
	}
	// Lets you access a dialog page by name
	ZDialogPage GetDialogPageByName(string pn)
	{
		for (int i = 0; i < dialogPages.Size(); i++)
		{
			if (dialogPages[i].PageName == pn)
				return dialogPages[i];
		}

		return null;
	}
	// Lets you access a dialog page by index
	// Get the current page by calling GetDialogPageByIndex(GetPageNumber())
	ZDialogPage GetDialogPageByIndex(int i) { return i >= 0 && i < dialogPages.Size() ? dialogPages[i] : null; }

	// Adds a text string to the given dialog page's, dialog list.  You can add a skill enum as well.
	void AddDialogToPage(string dialog, string page, int skill = -1)
	{
		if (GetDialogPageByName(page))
			GetDialogPageByName(page).DialogList.Push(new("ZDialog").Init(dialog, skill));
		else
			console.Printf(string.Format("ZScript Windows - WARNING! - ZConversation, %s, tried to add dialog to non-existent dialog page, %d!", self.Name, page));
	}

	// this is the index of the page currently loaded in dialogPages
	// this is private so it can be readonly
	private int pageNumber;
	private int nextPageNumber;
	int GetPageNumber() { return pageNumber; }
	
	ZConversation Init(ZObjectBase ControlParent, bool Enabled, bool Show, string Name, int PlayerClient, bool UiToggle,
		bool bTransferToActor = false, bool bDropAtSpot = false, bool bDropSpotFog = false, int DropSpotId = 0, string DropClass = "",
		bool bDefault_NPCName = false, bool bDefault_NPCDialog = false, bool bDefault_NPCPortrait = false, bool bDefault_Buttons = false)
	{
		self.bTransferToActor = bTransferToActor;

		self.bDropAtSpot = bDropAtSpot;
		self.bDropSpotFog = bDropSpotFog;
		self.DropSpotId = DropSpotId;
		self.DropClass = DropClass;

		self.bDead = false;

		// Sub controls will inherit their locations from their parent, if defaulted
		// therfore the convo needs to inherit too.
		self.xLocation = ControlParent.xLocation;
		self.yLocation = ControlParent.yLocation;
		// These need to be non-zero for anything to be drawn!
		self.Width = ControlParent.Width;
		self.Height = ControlParent.Height;

		pageNumber = nextPageNumber = -1;

		WaitMessageTicks = 0;
		WaitForMessage = false;

		/*
			NPC Name ZText
			
		*/
		if (bDefault_NPCName)
		{
			bool spwned;
			actor txt_npcNme;
			[spwned, txt_npcNme] = CreateSubControl("ZText");
			if (spwned && txt_npcNme)
				self.NPCName = ZText(txt_npcNme).Init(self, Enabled, Show, string.Format("ZConvo-%s-NPCName", Name), "Hello! My name is, Sarah", PlayerClient, UiToggle);
		}
		else
			self.NPCName = null;
		
		/*
			NPC Dialog ZText
		
		*/
		if (bDefault_NPCDialog)
		{
			bool spwned;
			actor txt_npcDialog;
			[spwned, txt_npcDialog] = CreateSubControl("ZText");
			if (spwned && txt_npcDialog)
				self.NPCDialog = ZText(txt_npcDialog).Init(self, Enabled, Show, string.Format("ZConvo-%s-NPCDialog", Name), "I only talk to sailors", PlayerClient, UiToggle);
		}
		else
			self.NPCDialog = null;

		/*
			NPC Portrait ZGraphic
		
		*/
		if (bDefault_NPCPortrait)
		{
			bool spwned;
			actor gfx_npcPortrait;
			[spwned, gfx_npcPortrait] = CreateSubControl("ZGraphic");
			if (spwned && gfx_npcPortrait)
				self.NPCPortrait = ZGraphic(gfx_npcPortrait).Init(self, Enabled, Show, string.Format("ZConvo-%s-NPCPortrait", Name), PlayerClient, UiToggle);
		}
		else
			self.NPCPortrait = null;
		
		/*
			Buttons
		
		*/
		if (bDefault_Buttons)
		{
			bool spwned;
			actor btn_ChoiceA, btn_ChoiceB, btn_ChoiceC, btn_ChoiceD, btn_ChoiceE;
			// Button A
			[spwned, btn_ChoiceA] = CreateSubControl("ZDialogButton");
			if (spwned && btn_ChoiceA)
				PlayerChoices[0] = ZDialogButton(btn_ChoiceA).Init(self, Enabled, Show, string.Format("ZConvo-%s-PlayerChoiceButton_A", Name), PlayerClient, UiToggle,
																	Type:ZButton.BTN_ZButton, Width:(self.Width - 20), Btn_xLocation:((self.Width - (self.Width - 20)) / 2), Btn_yLocation:(self.Height - ((25 * 6) + 40)),
																	ButtonScaleType:ZControl.SCALE_Both, Text:"Choice Button A", FontName:'newsmallfont', TextAlignment:ZControl.TEXTALIGN_Center, TextWrap:ZControl.TXTWRAP_Wrap,
																	Txt_yLocation:10);
			// Button B
			[spwned, btn_ChoiceB] = CreateSubControl("ZDialogButton");
			if (spwned && btn_ChoiceB)
				PlayerChoices[1] = ZDialogButton(btn_ChoiceB).Init(self, Enabled, Show, string.Format("ZConvo-%s-PlayerChoiceButton_B", Name), PlayerClient, UiToggle,
																	Type:ZButton.BTN_ZButton, Width:(self.Width - 20), Btn_xLocation:((self.Width - (self.Width - 20)) / 2), Btn_yLocation:(self.Height - ((25 * 5) + 30)),
																	ButtonScaleType:ZControl.SCALE_Both, Text:"Choice Button B", FontName:'newsmallfont', TextAlignment:ZControl.TEXTALIGN_Center, TextWrap:ZControl.TXTWRAP_Wrap,
																	Txt_yLocation:10);
			// Button C
			[spwned, btn_ChoiceC] = CreateSubControl("ZDialogButton");
			if (spwned && btn_ChoiceC)
				PlayerChoices[2] = ZDialogButton(btn_ChoiceC).Init(self, Enabled, Show, string.Format("ZConvo-%s-PlayerChoiceButton_C", Name), PlayerClient, UiToggle,
																	Type:ZButton.BTN_ZButton, Width:(self.Width - 20), Btn_xLocation:((self.Width - (self.Width - 20)) / 2), Btn_yLocation:(self.Height - ((25 * 4) + 20)),
																	ButtonScaleType:ZControl.SCALE_Both, Text:"Choice Button C", FontName:'newsmallfont', TextAlignment:ZControl.TEXTALIGN_Center, TextWrap:ZControl.TXTWRAP_Wrap,
																	Txt_yLocation:10);
			// Button D
			[spwned, btn_ChoiceD] = CreateSubControl("ZDialogButton");
			if (spwned && btn_ChoiceD)
				PlayerChoices[3] = ZDialogButton(btn_ChoiceD).Init(self, Enabled, Show, string.Format("ZConvo-%s-PlayerChoiceButton_D", Name), PlayerClient, UiToggle,
																	Type:ZButton.BTN_ZButton, Width:(self.Width - 20), Btn_xLocation:((self.Width - (self.Width - 20)) / 2), Btn_yLocation:(self.Height - ((25 * 3) + 10)),
																	ButtonScaleType:ZControl.SCALE_Both, Text:"Choice Button D", FontName:'newsmallfont', TextAlignment:ZControl.TEXTALIGN_Center, TextWrap:ZControl.TXTWRAP_Wrap,
																	Txt_yLocation:10);
			// Button E
			[spwned, btn_ChoiceE] = CreateSubControl("ZDialogButton");
			if (spwned && btn_ChoiceE)
				PlayerChoices[4] = ZDialogButton(btn_ChoiceE).Init(self, Enabled, Show, string.Format("ZConvo-%s-PlayerChoiceButton_E", Name), PlayerClient, UiToggle,
																	Type:ZButton.BTN_ZButton, Width:(self.Width - 20), Btn_xLocation:((self.Width - (self.Width - 20)) / 2), Btn_yLocation:(self.Height - (25 * 2)),
																	ButtonScaleType:ZControl.SCALE_Both, Text:"Choice Button E", FontName:'newsmallfont', TextAlignment:ZControl.TEXTALIGN_Center, TextWrap:ZControl.TXTWRAP_Wrap,
																	Txt_yLocation:10);
		}
		else
		{
			for (int i = 0; i < NUMCHOICES; i++)
				PlayerChoices[i] = null;
		}

		return ZConversation(super.Init(ControlParent, Enabled, Show, Name, PlayerClient, UiToggle));
	}
	
	/*
		Buttons handle creating their corresponding ZText objects
		through regular ACVI (Actor Create Verify and Initialize)
		but the ZConversation has a lot of attached parts, so this
		method handles the heavy lifting.
	
	*/
	bool, Actor CreateSubControl(string controlName)
	{
		if (ZSHandlerUtil.ClassNameIsAClass(controlName))
		{
			bool spwned;
			actor control;
			[spwned, control] = A_SpawnItemEx(controlName);
			if (spwned && control && control is "ZObjectBase")
				return spwned, control;
			else
				return false, null;
		}
		else
			return false, null;
	}

	/*
		This method pulls the first (index 0) dialog page
		into the system.

	*/
	void Start()
	{
		displayNextPage(0, true);
	}

	/*
		While called Display Next Page,
		this method sets the contents of
		a Dialog Page to the screen.

		The ZIfItem is checked here as well.

	*/
	private void displayNextPage(int dindex, bool UICmd = false)
	{
		if (dialogPages.Size() > 0)
		{
			pageNumber = dindex;

			// Check the Dialog Page for IfItems - pageNumber will change if conditions are satisfied
			if (dialogPages[pageNumber].GetIfItemListSize() > 0)
			{
				// This tracks how many of the ifitems qualified
				int inums = 0;
				// Now iterate through the ifitem list
				for (int i = 0; i < dialogPages[pageNumber].GetIfItemListSize(); i++)
				{
					// Kinda dense, but iterate inums if the given player has the specified number of items of a particular class in their inventory.
					// I know like holy shit, the first bit of actual ZDoom ZScript in ages!  And it's buried under my mountain of class member access :P.
					if((dialogPages[pageNumber].GetIfItemByIndex(i).OnceIf ? (!dialogPages[pageNumber].GetIfItemByIndex(i).WasChecked() ? !dialogPages[pageNumber].GetIfItemByIndex(i).GetChecked() : false) : true) && 
						players[PlayerClient].mo.CountInv(dialogPages[pageNumber].GetIfItemByIndex(i).ClassName) >= dialogPages[pageNumber].GetIfItemByIndex(i).ItemCount)
						inums++;
				}

				// inums should equal the number of ifitems if the player has everything.
				// fail too if the PageLink in the dialog page is empty
				if (inums == dialogPages[pageNumber].GetIfItemListSize() && !IsEmpty(dialogPages[pageNumber].PageLink))
					pageNumber = FindDialogPageNumber(dialogPages[pageNumber].PageLink);
			}

			// Set the Conversation to the Dialog Page at pageNumber
			NPCName.Text = dialogPages[pageNumber].NPCName;
			NPCDialog.Text = dialogPages[pageNumber].GetDialog(true);
			NPCPortrait.Texture = TexMan.CheckForTexture(dialogPages[pageNumber].NPCPortrait, TexMan.TYPE_ANY);

			// This loop sets up the choice buttons.
			for (int i = 0; i < NUMCHOICES; i++)
			{
				if (PlayerChoices[i] != null ? PlayerChoices[i].ButtonText != null : false)
				{
					if (dialogPages[pageNumber].GetChoiceByIndex(i) != null)
					{
						// Display the cost - sooo much string formatting
						if (dialogPages[pageNumber].GetChoiceByIndex(i).DisplayCost && dialogPages[pageNumber].GetChoiceByIndex(i).GetCostListSize() > 0)
						{
							string costlst = string.Format("%s%s", dialogPages[pageNumber].GetChoiceByIndex(i).Text, " - [");
							for (int j = 0; j < dialogPages[pageNumber].GetChoiceByIndex(i).GetCostListSize(); j++)
								costlst = string.Format("%s%s%s(%d)%s", 
											costlst, 
											j > 0 ? " " : "",
											dialogPages[pageNumber].GetChoiceByIndex(i).GetCostByIndex(j).ClassName, 
											dialogPages[pageNumber].GetChoiceByIndex(i).GetCostByIndex(j).Amount,
											j < dialogPages[pageNumber].GetChoiceByIndex(i).GetCostListSize() - 1 ? "," : "");

							costlst = string.Format("%s%s", costlst, "]");
							PlayerChoices[i].ButtonText.Text = costlst;
						}
						// No costs or was flagged not to show them
						else
							PlayerChoices[i].ButtonText.Text = dialogPages[pageNumber].GetChoiceByIndex(i).Text;

						PlayerChoices[i].Show = true;
						PlayerChoices[i].Enabled = true;
						PlayerChoices[i].ButtonText.Show = true;
						PlayerChoices[i].ButtonText.Enabled = true;
					}
					else
					{
						PlayerChoices[i].Show = false;
						PlayerChoices[i].Enabled = false;
						PlayerChoices[i].ButtonText.Show = false;
						PlayerChoices[i].ButtonText.Enabled = false;
					}
				}
			}
			
			/*
				The dialog page itself can have nowhere to go,
				so this is another option users have to use
				a page as a transition page.
			
			*/
			if (dialogPages[pageNumber].GetChoiceListSize() == 0 && dialogPages[pageNumber].WaitForMessage)
			{
				nextPageNumber = FindDialogPageNumber(dialogPages[pageNumber].PageLink);
				if (nextPageNumber == -1)
					nextPageNumber = 0;
				ZNetCommand(string.Format("%szconvo_waitForPageTime,%s", UICmd ? "zevsys_AddToUITicker," : "", self.Name), PlayerClient, dialogPages[pageNumber].WaitMessageTicks);
			}
		}
	}

	/*
		This will be called as a result of the
		zconvo_executeChoice command being sent
		by one of the choice buttons.

		Unlike where a button would do whatever
		action it's designed to do, here they
		all need to do the same thing so that
		the dialog system can respond.

		The cindex argument is the index of the
		ZChoice defined in the current ZDialogPage.
		The ZChoice is stored in a dynamic array
		that is private and accessed through specific
		methods.
	
	*/
	private void executeChoice(int cindex)
	{
		if (pageNumber < dialogPages.Size())
		{
			ZDialogPage currentPage = dialogPages[pageNumber];
			if (currentPage)
			{
				bool bSuccess = false;

				// Do whatever the choice mode is to the buttons
				setChoiceButtonState(currentPage.ChoiceMode, false);

				// Are we giving the player anything?
				if (!IsEmpty(currentPage.GetChoiceByIndex(cindex).GiveClassName))
				{	// We are so we'll determine message choice that way
					// Do we have costs?
					int cnums = 0;
					if (currentPage.GetChoiceByIndex(cindex).GetCostListSize() > 0)
					{	// We do, so check if the player can afford the thing
						for (int i = 0; i < currentPage.GetChoiceByIndex(cindex).GetCostListSize(); i++)
						{
							if (players[PlayerClient].mo.CountInv(currentPage.GetChoiceByIndex(cindex).GetCostByIndex(i).ClassName) >= currentPage.GetChoiceByIndex(cindex).GetCostByIndex(i).Amount)
								cnums++;
						}
					}

					// The player has everything needed to buy the thing
					// This will also pass if there are no costs - so there is the ability for things to be free
					if (cnums == currentPage.GetChoiceByIndex(cindex).GetCostListSize())
					{
						// This takes the currency items from the player's inventory
						// It also handles transfering that currency to the base actor
						// The EVS uses SetInventory so exact amounts are sent.
						for (int i = 0; i < currentPage.GetChoiceByIndex(cindex).GetCostListSize(); i++)
							EventHandler.SendNetworkEvent(string.Format("zevsys_TakePlayerInventory,%s,%s",
									currentPage.GetChoiceByIndex(cindex).GetCostByIndex(i).ClassName,
									GetParentWindow(self.ControlParent, true).Name),
								PlayerClient,
								players[PlayerClient].mo.CountInv(currentPage.GetChoiceByIndex(cindex).GetCostByIndex(i).ClassName) - currentPage.GetChoiceByIndex(cindex).GetCostByIndex(i).Amount,
								bTransferToActor ? GetParentWindow(self.ControlParent, true).CountInv(currentPage.GetChoiceByIndex(cindex).GetCostByIndex(i).ClassName) + currentPage.GetChoiceByIndex(cindex).GetCostByIndex(i).Amount : false);

						// If this convo should drop items at a location object (MapSpot)
						if (bDropAtspot)
							EventHandler.SendNetworkEvent(string.Format("zevsys_DropInventoryAtSpot,%s%s",
									currentPage.GetChoiceByIndex(cindex).GiveClassName,
									IsEmpty(DropClass) ? "" : string.Format(",%s", DropClass)),
								currentPage.GetChoiceByIndex(cindex).GiveItemCount,
								DropSpotId,
								bDropSpotFog);
						// Otherwise give items to the the player normally (SetInventory abuse)
						else
							EventHandler.SendNetworkEvent(string.Format("zevsys_GivePlayerInventory,%s",
									currentPage.GetChoiceByIndex(cindex).GiveClassName),
								PlayerClient,
								players[PlayerClient].mo.CountInv(currentPage.GetChoiceByIndex(cindex).GiveClassName) + currentPage.GetChoiceByIndex(cindex).GiveItemCount);

						NPCDialog.Text = currentPage.GetChoiceByIndex(cindex).YesMessage;
						bSuccess = true;
					}
					// The player doesn't have everything to buy the thing
					else
						NPCDialog.Text = currentPage.GetChoiceByIndex(cindex).NoMessage;
				}
				// We are not - so do we have a yes message?
				else if (!IsEmpty(currentPage.GetChoiceByIndex(cindex).YesMessage))
				{
					NPCDialog.Text = currentPage.GetChoiceByIndex(cindex).YesMessage;
					bSuccess = true;
				}
				// We do not have a yes message?  Um ok, failsafe then
				else
					NPCDialog.Text = "Uh, ok.";

				// Is there a next page?  If we aren't waiting for the yes message, change pages
				if (bSuccess && !currentPage.GetChoiceByIndex(cindex).WaitForMessage && !IsEmpty(currentPage.GetChoiceByIndex(cindex).NextPage))
					displayNextPage(FindDialogPageNumber(currentPage.GetChoiceByIndex(cindex).NextPage));
				// We are waiting for the yes message - give the ticker a tick time
				else if (currentPage.GetChoiceByIndex(cindex).WaitForMessage) // Does not check tick time - if that is 0 the system will just dump to the next page anyway
				{
					// PageNumber can be set here - this may not work long term
					// It did not - introducing nextPageNumber - an index to be used by this mechanic
					nextPageNumber = FindDialogPageNumber(currentPage.GetChoiceByIndex(cindex).NextPage);
					// Got nothing for a page number so reset to the current number.
					if (nextPageNumber == -1)
						nextPageNumber = pageNumber;
					ZNetCommand(string.Format("zconvo_waitForPageTime,%s", self.Name), PlayerClient, currentPage.GetChoiceByIndex(cindex).WaitMessageTicks);
				}
				else if (currentPage.GetChoiceByIndex(cindex).CloseDialog)
				{ /* this needs to close the window but not cause the npc to be deleted */ }
			}
		}
	}

	private void setChoiceButtonState(int ChoiceMode, bool state)
	{
		for (int i = 0; i < NUMCHOICES; i++)
		{
			switch(ChoiceMode)
			{
				case ZDialogPage.CHMODE_Disable:
					PlayerChoices[i].Enabled = state;
					PlayerChoices[i].ButtonText.Enabled = state;
					break;
				case ZDialogPage.CHMODE_Hide:
					PlayerChoices[i].Show = state;
					PlayerChoices[i].Enabled = state;
					PlayerChoices[i].ButtonText.Show = state;
					PlayerChoices[i].ButtonText.Enabled = state;
					break;
			}
		}
	}

	/*
		A NPC must override it's Die event and call this
		method for the WorldThingDied event to process correctly.

	*/
	void SendDeathEventPacket()
	{
		/*
			Parent death and DropItem
			There can be some creative spawn positioning later,
			just get it dropping items when NPCs die.

		*/
		if (self.ControlParent ? (GetParentWindow(self.ControlParent, false) != null ? (GetParentWindow(self.ControlParent, false).health <= 0 && !bDead && !IsEmpty(dialogPages[pageNumber].DropClassName)) : false) : false)
		{
			bDead = true;
			/*
				This is a VERY special use of a direct command to the Event System.
				Due to the order to events, if this were sent via net command, the
				packet that needs created would be created after the death events
				are executed.  Directly creating the packet in the death events
				ensures the data is available at the right time.

				This command creates an EventDataPacket for processing by the WorldThingDied
				event, which will treat the data as what to tell the NPC to drop and how much.

			*/
			ZEventSystem(EventHandler.Find("ZEventSystem")).PushEventDataPacket(string.Format("%s|string,%d|int", dialogPages[pageNumber].DropClassName, dialogPages[pageNumber].DropAmount), EventDataPacket.EVTYP_WorldThingDied);
		}
		else
		{
			/*console.Printf(string.Format("Parent, %s, health is, %d, bDead is %d, and the drop item is: %s, in amount: %d",
				GetParentWindow(self.ControlParent, false).Name,
				GetParentWindow(self.ControlParent, false).health,
				bDead,
				dialogPages[pageNUmber].DropClassName,
				dialogPages[pageNumber].DropAmount));*/
		}
	}

	/*

			* ZSCRIPT OVERRIDES! *
	
	*/
	override void Tick()
	{
		/*
			The super handles self-destruction,
			but the control has to destroy its
			sub controls.
		*/
		if (self.bSelfDestroy)
		{
			if (NPCName)
				NPCName.bSelfDestroy = true;
			if (NPCDialog)
				NPCDialog.bSelfDestroy = true;
			for (int i = 0; i < NUMCHOICES; i++)
			{
				if (PlayerChoices[i])
					PlayerChoices[i].bSelfDestroy = true;
			}
			// dialogPages are an internal data class so they should go with the control
		}

		/*
			Action waiting
		
		*/
		if (WaitForMessage)
		{
			if (WaitMessageTicks > 0)
				WaitMessageTicks--;
			else
			{
				ZNetCommand(string.Format("zconvo_changePageTime,%s", self.Name), PlayerClient);
				WaitForMessage = false;
			}
		}
		
		super.Tick();
	}
	
	/*
		Buttons rely on UI Process to update cursor information
		This passes that along
	
	*/
	override bool ZObj_UiProcess(ZUIEventPacket e)
	{
		for (int i = 0; i < NUMCHOICES; i++)
			PlayerChoices[i].ZObj_UiProcess(e);

		return super.ZObj_UiProcess(e);
	}
	
	/*
		Text object use their UI Ticker to determine
		if text wrapping needs updated.
	
	*/
	override bool ZObj_UiTick()
	{
		// UI Tick the ZText objects
		if (NPCName)
			NPCName.ZObj_UiTick();
		if (NPCDialog)
			NPCDialog.ZObj_UiTick();
		// The buttons have to UI Tick their text objects
		for (int i = 0; i < NUMCHOICES; i++)
			PlayerChoices[i].ZObj_UiTick();
		// UI Tick the rest of this object
		return super.ZObj_UiTick();
	}
	
	/*
		Buttons use their Net Process method to do the
		actual updating of the cursor information.

		The ZConversation receives:
			zconvo_executeChoice from its buttons
			buttons send: zconvo_executeChoice with the FirstArg set to the index of the button
	
	*/
	enum ZDLGNETCMD
	{
		ZDLGCMD_WaitPageTime,
		ZDLGCMD_ChangePageTime,
		ZDLGCMD_ExecuteChoice,
		ZDLGCMD_TryString,
	};

	private ZDLGNETCMD stringToZDialogCommand(string e)
	{
		if (e ~== "zconvo_waitForPageTime")
			return ZDLGCMD_WaitPageTime;
		if (e ~== "zconvo_changePageTime")
			return ZDLGCMD_ChangePageTime;
		if (e ~== "zconvo_executeChoice")
			return ZDLGCMD_ExecuteChoice;
		else
			return ZDLGCMD_TryString;
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

						if (cmd.Size() >= 2 ? cmd[1] ~== self.Name : false)
						{
							switch (stringToZDialogCommand(cmd[0]))
							{
								case ZDLGCMD_WaitPageTime:
									WaitForMessage = true;
									WaitMessageTicks = e.FirstArg;
									break;
								case ZDLGCMD_ChangePageTime:
									displayNextPage(nextPageNumber);
									nextPageNumber = -1;
									break;
								case ZDLGCMD_ExecuteChoice:
									executeChoice(e.FirstArg);
									break;
								default:
									break;
							}
						}
					}
				}
			}
			else {}
		}		

		for (int i = 0; i < NUMCHOICES; i++)
		{
			if (PlayerChoices[i].ZObj_NetProcess(e))
				return true;
		}
		return super.ZObj_NetProcess(e);
	}

	override void ZObj_WorldTick()
	{
		for (int i = 0; i < NUMCHOICES; i++)
			PlayerChoices[i].ZObj_WorldTick();

		NPCName.ZObj_WorldTick();
		NPCDialog.ZObj_WorldTick();
		// The NPCPortrait is a ZGraphic and does not use its WorldTick
	}
	
	/*
		You are what you draw.
		Everything.  EVERYTHING. Draws itself,
		but the draw methods must be called by
		someone.
	*/
	override void ObjectDraw(ZObjectBase parent)
	{
		if(NPCName)
			NPCName.ObjectDraw(self);
		if(NPCDialog)
			NPCDialog.ObjectDraw(self);
		if (NPCPortrait)
			NPCPortrait.ObjectDraw(self);
		for (int i = 0; i < NUMCHOICES; i++)
		{
			if (PlayerChoices[i] != null)
				PlayerChoices[i].ObjectDraw(self);

		}
	}

	/*
		Mouse Event Passing
		Buttons require this.
	
	*/
	override void OnMouseMove(int t)
	{
		for (int i = 0; i < NUMCHOICES; i++)
			PlayerChoices[i].OnMouseMove(t);
	}

	override void OnLeftMouseDown(int t)
	{
		for (int i = 0; i < NUMCHOICES; i++)
			PlayerChoices[i].OnLeftMouseDown(t);
	}
	
	override void OnLeftMouseUp(int t)
	{
		for (int i = 0; i < NUMCHOICES; i++)
			PlayerChoices[i].OnLeftMouseUp(t);
	}
}

/*
	This class is analogous to the Page block,
	and has similar functionality.
	
	You may have as many ZDialogPages as you'd like in a
	ZDialogue control.
	
	Like USDF, the ZDialoguePage is indexed in definition order.
	The first index in the array will be considered the first interaction
	between the NPC and the player.  However the "Link" property has been
	changed to a string, so it is a unique identifier for the next page.
	
	Supported USDF Properties:
	--------------------------
	Name, NPCName - name that appears above everything else displayed by the control
	Panel, TBS - lump name for the portrait
	Voice, TBS - lump name for narration; follow USDF rules, lump should be in the voices namespace
	Dialog, DialogList - contents of the page, what the NPC should say
	Drop, DropClassName - NOT the ConversationID, the class name of the object to be dropped if the NPC is killed
	Link, PageLink - page to jump to if all "ifitem" conditions are met
	
	Extended Properties:
	--------------------
	The "Name" property refers to a ZText object, therefore all ZText properties
	are available for control.
	
	The "Panel" property refers to a ZGraphic object, therefore all ZGraphic properties
	are available for control.
	
	Dialog - this is an array of strings that allows for a random dialog string,
		should the DialogChance property be greater than 0.  DialogChance works like a DECORATE
		jump method.
		
	DropAmount - how many of the "Drop" property to drop
	
	Link - this is now a string, unique identifier for the page.

	Extra Properties:
	-----------------
	The WaitForMessage property allows the control to display the dialog page for a set
	amount of time before changing to another page.  IfItems override this as they are
	checked first, and this does not work if there are valid choices.  If the PageLink
	property is empty this will reset the control back to the first page in the list.

	The WaitMessageTicks represents how many game ticks the control will wait before
	changing dialog pages.  The above rules for WaitForMessage still apply.

*/
class ZDialogPage
{
	const NUMIFLIST = 3;
	const NUMCHOICES = 5;
	
		// This is the unique identifier of the instance
	string PageName,
		// This is the NPC Name
		NPCName,
		// The name of the portrait graphic - do not include file extension
		NPCPortrait,
		// This is the name of the next page
		PageLink,
		// This the is the class name of the item to be dropped upon this NPCs death
		DropClassName;
	
 	// This works just like the fail chance of a DECORATE jump function, 
	// 0 always uses the first index of the array, 255 always chooses a random option, if available.
	uint8 DialogChance;
	// Making this a...unsigned short, to save iterations if for some reason there's not a clean way
	// to spawn multiple items - I guess the intention is to spawn a single quest item, or one unit of ammo, etc.
	uint16 DropAmount;

	bool WaitForMessage;
	int WaitMessageTicks;
		
	// Dialog - what the NPC should say to the player
	array<ZDialog> DialogList;
	// The method GetDialog() runs the randomization chance if DialogChance is greater than 0
	// This check is pretty much what A_Jump does to determine jump chance.
	// Use of Random here defaults to Random(0, 255), and Random "should" be inclusive,
	// so usage in the array index needs to subtract 1 from the array size.
	string GetDialog(bool filter = false)
	{
		if (filter)
		{
			array<string> filterList;
			for (int i = 0; i < DialogList.Size(); i++)
			{
				// Note that the OptionSkill member of DialogList is an enumeration
				// which will match the return of ACS/ZScript skill check methods.
				if (G_SkillPropertyInt(SKILLP_ACSReturn) == DialogList[i].OptionSkill || DialogList[i].OptionSkill == ZDialog.OPTSKILL_ALL)
					filterList.Push(DialogList[i].Dialog);
			}
			
			if (filterList.Size() > 1 && (DialogChance >= 255 || Random() < DialogChance))
				return filterList[Random(0, filterList.Size() - 1)];
			else if (filterList.Size() > 0)
				return filterList[0];
			else
				return " - I am Filtered Error - ";
		}
		else
		{
			if (DialogList.Size() > 1 && (DialogChance >= 255 || Random() < DialogChance))
				return DialogList[Random(0, DialogList.Size() - 1)].Dialog;
			else if (DialogList.Size() > 0)
				return DialogList[0].Dialog;
			else
				return " - I am Error - ";
		}
	}
	
	// This array stores up to 3 class names and an item count.
	// If populated, the array is used as a condition of jumping to the next page
	private array<ZIfItem> IfItemList;
	void PushIfItem(ZIfItem ifitem)
	{
		if (IfItemList.Size() < NUMIFLIST && ifItem != null)
			IfItemList.Push(ifitem);
		else if (IfItemList.Size() == NUMIFLIST)
			console.Printf(string.Format("ZScript Windows - WARNING - ZConversation, Dialog Page, %s, attempted to push too many IfItems!  Item named, %s, is discarded!", self.PageName, ifitem.ClassName));
		else
			console.Printf(string.Format("ZScript Windows - WARNING - Attempt to push NULL IfItem to ZConversation, Dialog Page, %s!", self.PageName));
	}
	int GetIfItemListSize() { return IfItemList.Size(); }
	ZIfItem GetIfItemByIndex(int i) { return i >= 0 && i < NUMIFLIST && i < IfItemList.Size() ? IfItemList[i] : null; }
	ZIfItem GetIfItemByClass(string c, int n = 0)
	{	// This looks kind of shitty, and it is, but it does the job
		for (int i = 0; i < NUMIFLIST; i++)
		{	// first check if we have the right item
			if (c == IfItemList[i].ClassName)
			{	// does the item count matter?
				if (n > 0)
				{	// it does, so do we have the right class and number of items?
					if (IfItemList[i].ItemCount == n) // yes
						return IfItemList[i];
					// no else for failure because that means keep looking
				}
				// the count does not but it is the right item
				else
					return IfItemList[i];
			}
		}
		// invalid name or count
		console.Printf(string.Format("ZScript Windows - WARNING - ZConversation, Dialog Page, %s, did not find the IfItem with Class Name, %s, with Count, %d", self.PageName, c, n));
		return null;
	}
	
	// Choices - what the player can say to the NPC - this follows USDF and is limited to 5 choices
	// If FilterChoices is not false, what choices are displayed will be filtered by their skill enum
	// This does not allow you to break the rule of 5.
	bool FilterChoices;
	private array<ZChoice> ChoiceList;
	void PushChoice(ZChoice choice)
	{
		if (ChoiceList.Size() < NUMCHOICES && choice != null)
			ChoiceList.Push(choice);
		else if (ChoiceList.Size() == NUMCHOICES)
			console.Printf(string.Format("ZScript Windows - WARNING - ZConversation, Dialog Page, %s, attempted to push too many Choices!  Choice with text, %s, is discarded!", self.PageName, choice.Text));
		else
			console.Printf(string.Format("ZScript Windows - WARNING - Attempt to push NULL Choice to ZConversation, Dialog Page, %s!", self.PageName));
	}
	int GetChoiceListSize() { return ChoiceList.Size(); }
	ZChoice GetChoiceByIndex(int i) { return i >= 0 && i < NUMCHOICES && i < ChoiceList.Size() ? ChoiceList[i] : null; }

	enum CHOICEMODES
	{
		CHMODE_Disable,
		CHMODE_Hide,
		CHMODE_none,
	};
	CHOICEMODES ChoiceMode;
	
	ZDialogPage Init(string PageName, string NPCName = "", string NPCPortrait = "", string PageLink = "", 
		string Dialog = "", int DialogChance = 0,
		string DropClassName = "", int DropAmount = 1,
		bool WaitForMessage = false, int WaitMessageTicks = 105,
		ZIfItem CheckItem_A = null, ZIfItem CheckItem_B = null, ZIfItem CheckItem_C = null,
		ZChoice PlayerChoice_A = null, ZChoice PlayerChoice_B = null, ZChoice PlayerChoice_C = null, ZChoice PlayerChoice_D = null, ZChoice PlayerChoice_E = null,
		bool FilterChoices = false, CHOICEMODES ChoiceMode = CHMODE_Disable)
	{
		self.PageName = PageName;
		self.NPCName = NPCName;
		self.NPCPortrait = NPCPortrait;
		self.PageLink = PageLink;
		
		if (!ZObjectBase.IsEmpty(Dialog))
			DialogList.Push(new("ZDialog").Init(Dialog));
		self.DialogChance = DialogChance;
		
		self.DropClassName = DropClassName;
		self.DropAmount = DropAmount;

		self.WaitForMessage = WaitForMessage;
		self.WaitMessageTicks = WaitMessageTicks;
		
		// PushIfItem is null protected - but will spew console errors if you do
		if (CheckItem_A)
			PushIfItem(CheckItem_A);
		if (CheckItem_B)
			PushIfItem(CheckItem_B);
		if (CheckItem_C)
			PushIfItem(CheckItem_C);
		
		if (PlayerChoice_A)
			PushChoice(PlayerChoice_A);
		if (PlayerChoice_B)
			PushChoice(PlayerChoice_B);
		if (PlayerChoice_C)
			PushChoice(PlayerChoice_C);
		if (PlayerChoice_D)
			PushChoice(PlayerChoice_D);
		if (PlayerChoice_E)
			PushChoice(PlayerChoice_E);
		
		self.FilterChoices = FilterChoices;

		return self;
	}
}

/*
	Contains information on required item class name,
	and required quantity.

*/
class ZItemBase
{
	string ClassName;
	ZItemBase Init(string ClassName)
	{
		self.ClassName = ClassName;
		return self;
	}
}

class ZIfItem : ZItemBase
{
	int ItemCount;
	bool OnceIf;
	private bool checked;
	bool GetChecked() { return checked == true ? checked : !(checked = true); }
	bool WasChecked() { return checked; }
	
	ZIfItem Init(string ClassName, bool OnceIf, int ItemCount = 0)
	{
		self.ItemCount = ItemCount;
		self.OnceIf = OnceIf;
		checked = false;
		return ZIfItem(super.Init(ClassName));
	}
}

class ZCost : ZItemBase
{
	int Amount;
	ZCost Init(string ClassName, int Amount = 0)
	{
		self.Amount = Amount;
		return ZCost(super.Init(ClassName));
	}
}

/*
	Base class for block components

*/
class ZConvoBlockBase
{
	enum OPTSKILL
	{
		OPTSKILL_VERYEASY,
		OPTSKILL_EASY,
		OPTSKILL_NORMAL,
		OPTSKILL_HARD,
		OPTSKILL_VERYHARD,
		OPTSKILL_OTHER,
		OPTSKILL_ALL = -1	// this replaces a NONE type as a NONE type would represent ALL skills
	};
	OPTSKILL OptionSkill;
	
	ZConvoBlockBase Init(OPTSKILL OptionSkill = OPTSKILL_ALL)
	{
		self.OptionSkill = OptionSkill;
		return self;
	}
}

/*
	What the NPC says to the player

*/
class ZDialog : ZConvoBlockBase
{	
	string Dialog;
	
	ZDialog Init(string Dialog, OPTSKILL OptionSkill = OPTSKILL_ALL)
	{
		self.Dialog = Dialog;
		return ZDialog(super.Init(OptionSkill));
	}
}

/*
	What the player may say to the NPC

*/
class ZChoice : ZConvoBlockBase
{
	const NUMCOST = 3;

	string Text,
		YesMessage,
		NoMessage,
		GiveClassName,
		NextPage;
	int GiveItemCount,
		WaitMessageTicks;
	bool DisplayCost,
		CloseDialog,
		WaitForMessage;
		
	private array<ZCost> CostList;
	void PushCost(ZCost cost)
	{
		if (CostList.Size() < NUMCOST && cost != null)
			CostList.Push(cost);
		else if (CostList.Size() == NUMCOST)
			console.Printf("ZScript Windows - WARNING - Conversation control attempted to push too many Costs to Choice definition!  Max is 3!");
		else
			console.Printf("ZScript Windows - WARNING - Conversation control attempted to push NULL Cost to Choice!");
	}
	int GetCostListSize() { return CostList.Size(); }
	ZCost GetCostByIndex(int i) { return i >= 0 && i < NUMCOST && i < CostList.Size() ? CostList[i] : null; }
	
	ZChoice Init(string Text, OPTSKILL OptionSkill = OPTSKILL_ALL, bool DisplayCost = true, 
		string YesMessage = "Thank you!", string NoMessage = "Not happening.", 
		string GiveClassName = "", int GiveItemCount = 0,
		string NextPage = "", bool CloseDialog = false,
		bool WaitForMessage = true, int WaitMessageTicks = 105,
		ZCost Cost_A = null, ZCost Cost_B = null, ZCost Cost_C = null)
	{
		self.Text = Text;
		self.DisplayCost = DisplayCost;
		self.YesMessage = YesMessage;
		self.NoMessage = NoMessage;
		self.GiveClassName = GiveClassName;
		self.GiveItemCount = GiveItemCount;
		self.NextPage = NextPage;
		self.CloseDialog = CloseDialog;
		self.WaitForMessage = WaitForMessage;
		self.WaitMessageTicks = WaitMessageTicks;
		if (Cost_A)
			PushCost(Cost_A);
		if (Cost_B)
			PushCost(Cost_B);
		if (Cost_C)
			PushCost(Cost_C);
		return ZChoice(super.Init(OptionSkill));
	}
}


/*
	ZDialogButtons include the required code to
	work with the ZConversation object.

	They function exactly like other ZButtons.

*/
class ZDialogButton : ZButton
{
	// Use this for mouse-over
	override void OnMouseMove(int t)
	{
		if (ValidateCursorLocation())
			self.State = BSTATE_Highlight;
		else
			self.State = BSTATE_Idle;
	}

	// Use this to set the button state to active
	override void OnLeftMouseDown(int t)
	{
		if (self.State == BSTATE_Highlight)
			self.State = BSTATE_Active;
	}
	
	// Use this to do the action
	override void OnLeftMouseUp(int t)
	{
		// Got a valid click from OnLeftMouseDown
		if (self.State == BSTATE_Active)
		{
			// This sends a net command to the conversation object, giving it a choice index
			if (self.ControlParent is "ZConversation")
			{
				ZDialogPage currentPage = ZConversation(self.ControlParent).GetDialogPageByIndex(ZConversation(self.ControlParent).GetPageNumber());
				for (int i = 0; i < currentPage.GetChoiceListSize(); i++)
				{
					if (currentPage.GetChoiceByIndex(i).DisplayCost)
					{
						array<string> bts;
						self.ButtonText.Text.Split(bts, " - "); // literally split at the space
						if (bts.Size() > 0 ? currentPage.GetChoiceByIndex(i).Text ~== bts[0] : false)
						{
							ZNetCommand(string.Format("zconvo_executeChoice,%s", self.ControlParent.Name), self.PlayerClient, i);
							break;						
						}
					}
					else if (currentPage.GetChoiceByIndex(i).Text ~== self.ButtonText.Text)
					{
						ZNetCommand(string.Format("zconvo_executeChoice,%s", self.ControlParent.Name), self.PlayerClient, i);
						break;						
					}
				}
			}
			else
				console.printf(string.Format("ZScript Windows - ERROR! - ZDialogButton, %s, is contained inside invalid parent, %s!  Cannot execute choices!", self.Name, self.ControlParent));
			// Reset the button's state to idle, passive GibZoning will reset it to highlight if needed.
			self.State = BSTATE_Idle;
		}
	}
}