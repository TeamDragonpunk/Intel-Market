// class UIBlackMarket_Buy extends UISimpleCommodityScreen;
class DP_UIIntelMarket_Buy extends DP_UISimpleCommodityScreen config(DP_IntelOptions_Settings);

var localized String IntelAvailableLabel;
var localized String IntelOptionsLabel;
var localized String IntelCostLabel;
var localized String IntelTotalLabel;

var config bool RampingIntelCosts;
var config float IntelCostMultiplier;

var UIX2ResourceHeader			ResourceContainer;

var UILargeButton ExitButton;
var array<MissionIntelOption> SelectedIntelOptions;

var UIItemCard_HackingRewards HackingRewardCard;

//----------------------------------------------------------------------------
// MEMBERS

//Creates the Screen UI. From original BM_Buy class
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local array<UIPanel> ItemCards;
	local UIPanel Card;
	local object thisObj;
	thisObj=self;
	m_strTitle = ""; //Clear the header out intentionally. 	.
	m_arrRefs.length=0;
	super.InitScreen(InitController, InitMovie, InitName);
	SetBlackMarketLayout();
	ItemCard.PopulateData(" "," "," ","");
	ItemCard.SetAlpha(0.001f);
	ItemCard.SetVisible(false);
	ListContainer.RemoveChild(ItemCard);
	ResourceContainer = Spawn(class'UIX2ResourceHeader', self).InitResourceHeader('ResourceContainer'); //Spawning the resource description bar
	ResourceContainer.AnchorTopRight();
	UpdateIntel();
	HackingRewardCard=UIItemCard_HackingRewards(Spawn(class'UIItemCard_HackingRewards', ListContainer).InitItemCard('HackingItemCard')); //Spawning the custom item card with pics and descriptions
	HackingRewardCard.SetPosition(635,0);
	HackingRewardCard.Show();
	HackingRewardCard.PopulateIntelItemCard();
	HackingRewardCard.SetAlpha(1);
	HackingRewardCard.PopulateIntelItemCard(self.GetItemTemplate(0));
	HackingRewardCard.SetInitialParameters();
	HackingRewardCard.Show();
	ExitButton = Spawn(class'UILargeButton', self); //Spawning the button for going to squad select.
	ExitButton.bAnimateOnInit = false;
	ExitButton.InitLargeButton('ExitButton',"SQUAD" , "SELECT", OnStartMissionClicked);
	ExitButton.AnchorBottomRight();
	MC.BeginFunctionOp("SetGreeble");
	MC.QueueString(class'UIAlert'.default.m_strBlackMarketFooterLeft);
	MC.QueueString(class'UIAlert'.default.m_strBlackMarketFooterRight);
	MC.QueueString("GOBLIN BAZAAR");
	MC.EndOp();
	GetItems();
	SelectedIntelOptions.Length=0;
	PopulateData(); //Populating the list 
	UpdateListParameters(self.List);//fixing list colors and layout.
}
simulated function PopulateData()
{
	GetItems();
	ResourceContainer.Show();
	m_arrRefs.length=0;
	PopulateDataWithRefund(SelectedIntelOptions);// Calling the function to populate the list correctly, passing the purchased(red,refundable) options.
}
simulated function OnStartMissionClicked(UIButton button) //When clicking on the button to go to squad select.
{
	local DP_UIIntelMarket MyDPScreen;
	MyDPScreen=DP_UIIntelMarket(`ScreenStack.GetFirstInstanceOf(class'DP_UIIntelMarket'));
	`SCREENSTACK.Pop(self);//popping from Screen Stack so it wont go back to it when backing out of the squad select screen.
	`SCREENSTACK.PopFirstInstanceOfClass(Class'DP_UIIntelMarket');//popping from Screen Stack so it wont go back to it when backing out of the squad select screen.
	BuyAndSaveIntelOptions(); //Submit the actual intel options to the mission to take effect.
	CloseScreen();
	//MyDPScreen.CloseScreen();
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Black_Market_Ambience_Loop_Stop"); //stop the music from the black market so the game would be able to fire up the squad select music
	if(MyDPScreen!=none)
	{
		MyDPScreen.ExposeOLC(button); // Fire up the original functions from the UIMission screens,moving the player to the squad select screen.
	}
}
function OnPurchasedAnIOPS(MissionIntelOption NewIntelO) //Called when clicking the buy or refund button (also activates on a double click on the list item itself)
{
	local array<string> strSplit;
	local string strSearch;

	if( CanAffordIntelOptionsAll(NewIntelO,true) ) //If you cant afford the option do nothing (will always be true on refundable ones), the bool input is for log output
	{
		PlaySFX("StrategyUI_Purchase_Item");
		if(SelectedIntelOptions.Find('IntelRewardName',NewIntelO.IntelRewardName)==-1 &&MissionActive.Find('IntelRewardName',NewIntelO.IntelRewardName)==-1)
		{	 // If it's not purchased already and not active already add it to the purchased options array.
			`log("Can Affort Intel: "@GetIntelFriendlyName(NewIntelO),true,'Dragonpunk IntelMarket');
			SelectedIntelOptions.AddItem(NewIntelO);
		}
		else
		{	// If it's purchased already remove it from the purchased options array.
			`log("Refunding Intel: "@GetIntelFriendlyName(NewIntelO),true,'Dragonpunk IntelMarket');
			SelectedIntelOptions.RemoveItem(NewIntelO);
		}	
		//Populate the data, will update the purchasable items on the function 
		PopulateData();
		XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.UpdateResources();
		//Updates the intel count on Resource bar on the top right corner of the screen.
		UpdateIntel();
	}
}
simulated function bool CanAffordIntelOptionsAll(MissionIntelOption IntelOption,optional bool Show=false) // A check if we can afford all the intel option, Show will determain if it would put out log statements.
{
	local MissionIntelOption tempIntelOption;
	local int TotalCostRightNow,i;
  	TotalCostRightNow=0;    
	if(SelectedIntelOptions.Find('IntelRewardName',IntelOption.IntelRewardName)!=-1)   //If it's an already purchased item we're trying to refund always return true.
		return true;
                                     
	for(i=0;i<SelectedIntelOptions.length;i++) //Calculate the total cost of all the already purchased options and save it.
	{
		tempIntelOption=SelectedIntelOptions[i];
		TotalCostRightNow=TotalCostRightNow+ Round(GetIntelCostMultiplier()*GetRampingIntelCosts()*GetIntelCost(tempIntelOption));
	}
	if(show) //log statement for debugging
		`log("Current Intel Cost:"@ Round(GetIntelCostMultiplier()*GetRampingIntelCosts()*GetIntelCost(tempIntelOption)) @"Intel Options Cost:"@TotalCostRightNow @"Total Intel Cost:"@(TotalCostRightNow+(GetIntelCostMultiplier()*GetRampingIntelCosts()*GetIntelCost(tempIntelOption))),true,'Team Dragonpunk IntelMarket');
	
	return ((TotalCostRightNow+ Round(GetIntelCostMultiplier()*GetRampingIntelCosts()*GetIntelCost(tempIntelOption))) <= GetAvailableIntel()); //if the intel cost of the current option + the rest of the already purchased options is smaller than the total amount of intel return true, if not it will return false. 
}
simulated function CloseScreen()
{
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Black_Market_Ambience_Loop_Stop");
	super.CloseScreen();
}

simulated function UpdateIntel()
{
	local int iIntel;
	local MissionIntelOption tempIntelOption;
	local int TotalCostRightNow,i;

  	TotalCostRightNow=0;                                                   
	for(i=0;i<SelectedIntelOptions.length;i++) //Calculate the total cost of all the already purchased options and save it.
	{
		tempIntelOption=SelectedIntelOptions[i];
		TotalCostRightNow=TotalCostRightNow+ Round(GetIntelCostMultiplier()*GetRampingIntelCosts(true)*GetIntelCost(tempIntelOption));
	}
	

	ResourceContainer.ClearResources();
	UpdateMonthlySupplies();
	UpdateSupplies();
	iIntel = class'UIUtilities_Strategy'.static.GetResource('Intel') -TotalCostRightNow; // Prints out the left over intel if all the current purchased intel options were to be purchased fully and paid.
	ResourceContainer.AddResource(Caps(class'UIUtilities_Strategy'.static.GetResourceDisplayName('Intel', iIntel)), class'UIUtilities_Text'.static.GetColoredText(String(iIntel), (iIntel > 0) ? eUIState_Normal : eUIState_Bad));
	UpdateEleriumCrystals();
	UpdateAlienAlloys();
	UpdateScientistScore();
	UpdateEngineerScore();
	UpdateResContacts();
	ResourceContainer.Show();
}

//-------------- EVENT HANDLING --------------------------------------------------------

//Manges the original BM_Buy logic for repopulating list
simulated function OnPurchaseClicked(UIList kList, int itemIndex) //Activated on double clicked.
{
	local MissionIntelOption ThisSelectedIOP;
	ThisSelectedIOP=(DP_UIInventory_ListItem(kList.ItemContainer.GetChildAt(ItemIndex)).ItemIntel);
	if(MissionActive.Find('IntelRewardName',ThisSelectedIOP.IntelRewardName)==-1)
		OnPurchasedAnIOPS(ThisSelectedIOP);
}

simulated function BuyAndSaveIntelOptions() //Buy and apply the purhcased intel options.
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_MissionSite MissionState;
	local MissionIntelOption IntelOption;
	local UIMission Screen; 
	local bool HasChanged;
	local name HackRewardName;
    local int i,k,X;                       
	local XComGameState_Unit Unit;
	local array<string> AddedNames,AddedNames2;
	local float TotalMultiplier;
	local StrategyCost FixedCost;
	TotalMultiplier=GetIntelCostMultiplier()*GetRampingIntelCosts();

	Screen=UIMission(`SCREENSTACK.GetFirstInstanceOf(Class'UIMission'));
	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Buy and Save Selected Mission Intel Options");
	
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	NewGameState.AddStateObject(XComHQ);
	
	MissionState = Screen.GetMission();
	MissionState = XComGameState_MissionSite(NewGameState.CreateStateObject(class'XComGameState_MissionSite', MissionState.ObjectID));
	NewGameState.AddStateObject(MissionState);
	class'X2CardManager'.static.GetCardManager().GetAllCardsInDeck('GuaranteedIntelPurchasedHackRewards',AddedNames);
	class'X2CardManager'.static.GetCardManager().GetAllCardsInDeck('IntelPurchasedHackRewards',AddedNames2);
	LogError();

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		NewGameState.AddStateObject(Unit);
		for(i=0;i<Unit.CurrentHackRewards.Length;i++)
		{
			X=XComHQ.TacticalGameplayTags.Find(Unit.CurrentHackRewards[i]);
			if(X!=-1)
			{
				XComHQ.TacticalGameplayTags.Removeitem(Unit.CurrentHackRewards[i]);
				XComHQ.TacticalGameplayTags.Removeitem(class'X2HackRewardTemplateManager'.static.GetHackRewardTemplateManager().FindHackRewardTemplate(Unit.CurrentHackRewards[i]).DataName);
			}
		}
		Unit.CurrentHackRewards.Remove(0, Unit.CurrentHackRewards.Length);
		Unit.CurrentHackRewards.Length=0;
		HasChanged=true;
	}

	for(i=0;i<XComHQ.TacticalGameplayTags.Length;i++)
	{
		if(IsValidIntelItemTemplate(`XComHQ.TacticalGameplayTags[i])||AddedNames.Find(string(`XComHQ.TacticalGameplayTags[i]))!=-1||AddedNames2.Find(string(`XComHQ.TacticalGameplayTags[i]))!=-1)
		{
			XComHQ.TacticalGameplayTags.RemoveItem(`XComHQ.TacticalGameplayTags[i]);	
			HasChanged=true;
		}
	}	
	LogError();
	//If you have any applied intel options add their tactical tags- backing out of squad select removes all intel options tactical tags, re-add them so they will be actually applied.
	for(i=0;i<MissionState.PurchasedIntelOptions.length;i++)
	{
		IntelOption=MissionState.PurchasedIntelOptions[i];
		XComHQ.TacticalGameplayTags.AddItem(IntelOption.IntelRewardName);
		HasChanged=true;
	}
	// Save and buy the intel options, and add their tactical tags
	for(i=0;i<SelectedIntelOptions.length;i++)
	{
		FixedCost=IntelOption.Cost;
		FixedCost.ResourceCosts[0].Quantity=FixedCost.ResourceCosts[0].Quantity*TotalMultiplier;
		IntelOption=SelectedIntelOptions[i];
		XComHQ.TacticalGameplayTags.AddItem(IntelOption.IntelRewardName);
		XComHQ.PayStrategyCost(NewGameState, FixedCost , XComHQ.MissionOptionScalars);
		MissionState.PurchasedIntelOptions.AddItem(IntelOption);
		HasChanged=true;
	}
	
	if(HasChanged) //Submit to history if we did something
		`XCOMHISTORY.AddGameStateToHistory(NewGameState);
	else
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
	//`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	SelectedIntelOptions.Length=0;
	LogError();
	XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.UpdateResources();
}

simulated function LogError()
{
	local XComGameState_Unit Unit;
	local int HackRewardIndex;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if(Unit.CurrentHackRewards.Length>0)
			`log("Unit"@Unit.ObjectID @":");

		for( HackRewardIndex = 0; HackRewardIndex < Unit.CurrentHackRewards.Length; ++HackRewardIndex )
		{
			`log(class'X2HackRewardTemplateManager'.static.GetHackRewardTemplateManager().FindHackRewardTemplate(Unit.CurrentHackRewards[HackRewardIndex]).DataName);
			`log(string(Unit.CurrentHackRewards[HackRewardIndex]));
		}
		if(Unit.CurrentHackRewards.Length>0)
			`log("");
	}
	`log("Hack Rewards Active");
	for(HackRewardIndex=0;HackRewardIndex<`XComHQ.TacticalGameplayTags.Length;HackRewardIndex++)
	{
		if(IsValidIntelItemTemplate(`XComHQ.TacticalGameplayTags[HackRewardIndex]))
		{
			`log(string(`XComHQ.TacticalGameplayTags[HackRewardIndex]));
		}
	}
	`log("");
	`log("Hack Rewards Purchased");
	for(HackRewardIndex=0;HackRewardIndex<UIMission(`ScreenStack.GetFirstInstanceOf(class'UIMission')).GetMission().PurchasedIntelOptions.Length;HackRewardIndex++)
	{
		if(IsValidIntelItemTemplate(UIMission(`ScreenStack.GetFirstInstanceOf(class'UIMission')).GetMission().PurchasedIntelOptions[HackRewardIndex].IntelRewardName))
		{
			`log(string(UIMission(`ScreenStack.GetFirstInstanceOf(class'UIMission')).GetMission().PurchasedIntelOptions[HackRewardIndex].IntelRewardName));
		}
	}
	`log("");
}
simulated function array<MissionIntelOption> GetMissionPurchasedOptions() //Getting the active options.
{
	local XComGameState_MissionSite MissionState;
	local UIMission Screen;

	Screen=UIMission(`SCREENSTACK.GetFirstInstanceOf(Class'UIMission'));
	MissionState = Screen.GetMission();
	return MissionState.PurchasedIntelOptions;	
}
simulated function SelectedItemChanged(UIList ContainerList, int ItemIndex) //Activated when mousing over a list item
{
	local array<UIPanel> ItemCards;
	local UIPanel Card;
	local MissionIntelOption SelectedIOP;
	local int i;
	SelectedIOP=DP_UIInventory_ListItem(ContainerList.ItemContainer.GetChildAt(ItemIndex)).ItemIntel; //Getting the intel from the current moused over item.
	super.SelectedItemChanged(ContainerList,ItemIndex);
	`log(GetIntelItemTemplate(SelectedIOP).GetDescription(none),true,'Team Dragonpunk Goblin Bazaar');
	ListContainer.RemoveChild(ItemCard);
	HackingRewardCard.Show();
	if(SelectedIOP.IntelRewardName!='')
		HackingRewardCard.PopulateIntelItemCard(GetIntelItemTemplate(SelectedIOP),,SelectedIOP); //Setting up the item card of the intel option
	else
		HackingRewardCard.SetNullParameters(); //if we have a null intel option (Labels for the types of items) just get the null parameters card- placeholder image.

	UpdateListParameters(ContainerList); // Update the looks of all the items.
}

simulated function UpdateListParameters(UIList ContainerList)
{
	local MissionIntelOption SelectedIOP;
	local int i;

	for(i=0;i<ContainerList.ItemContainer.NumChildren();i++) // Cycle through all the list items
		{
			SelectedIOP=DP_UIInventory_ListItem(ContainerList.ItemContainer.GetChildAt(i)).ItemIntel; //get the intel option for each list item
			if((arrIntelItems.Find('IntelRewardName',SelectedIOP.IntelRewardName)!=-1)) //Deal with stuff that are purchasable
			{
				if(!CanAffordIntelOptionsAll(SelectedIOP)&&((DP_UIInventory_ListItem(ContainerList.ItemContainer.GetChildAt(i)).bDisabled==false)||(DP_UIInventory_ListItem(ContainerList.ItemContainer.GetChildAt(i)).bIsBad==false)))
				{	//if you can afford the intel item AND one of the two looks options arent correct- correct them.
					DP_UIInventory_ListItem(ContainerList.ItemContainer.GetChildAt(i)).SetBad(true,"Cant Afford This Purchase");
					DP_UIInventory_ListItem(ContainerList.ItemContainer.GetChildAt(i)).SetDisabled(true,"Cant Afford This Purchase");
				}
				else if(CanAffordIntelOptionsAll(SelectedIOP)&&((DP_UIInventory_ListItem(ContainerList.ItemContainer.GetChildAt(i)).bDisabled==true)||(DP_UIInventory_ListItem(ContainerList.ItemContainer.GetChildAt(i)).bIsBad==true)))
				{	//if you can't afford the intel item AND one of the two looks options arent correct- correct them.
					DP_UIInventory_ListItem(ContainerList.ItemContainer.GetChildAt(i)).SetBad(false,"");
					DP_UIInventory_ListItem(ContainerList.ItemContainer.GetChildAt(i)).SetDisabled(false);
				}
			}
			else if(SelectedIntelOptions.Find('IntelRewardName',SelectedIOP.IntelRewardName)!=-1) //If it's already purchased make sure we can click it to refund it.
				DP_UIInventory_ListItem(ContainerList.ItemContainer.GetChildAt(i)).SetBad(false,"");

		}	
}
//-------------- GAME DATA HOOKUP --------------------------------------------------------


// All our buttons should say "buy" or "buy for mission"
simulated function String GetButtonString(int ItemIndex)
{

		return "BUY";
}
simulated function PickIntelOptions(XComGameState_MissionSite MissionState) //Just in case a mission has no intel options (or you want to reroll) it will roll the intel options even if the template dosnt allow that in stock.
{
	local XComGameState NewGameState;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Buy and Save Selected Mission Intel Options");
	NewGameState.AddStateObject(MissionState);
	MissionState.PickIntelOptions(); //Roll the intel options
	`XCOMHISTORY.AddGameStateToHistory(NewGameState);//submit to history
}

// Gets all the intel options available to purchase for the mission. filtering mutually exclusive rewards,purchased(red ones you purchase on that screen) ones and active ones(already paid for and active on the mission)
simulated function array<MissionIntelOption> GetMissionIntelOptions()
{
//	return GetMission().IntelOptions;
  	local UIMission Screen,Screen2; 
    local array<MissionIntelOption> IOPS,IOPSOut;                  
    local MissionIntelOption IntelOption,ExcIntelOption;
	local name ExcIntelOptionName;                  
	local bool HasExclusives;     
    local bool StartingConcealed,HasMaxSlots;
    local int i,k;                     
    local XComTacticalMissionManager MissionMgr;    
    local MissionSchedule Schedule;  
	local XComGameState_MissionSite MissionState;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Buy and Save Selected Mission Intel Options");
	MissionMgr=`TACTICALMISSIONMGR;
	Screen=UIMission(`SCREENSTACK.GetFirstInstanceOf(Class'UIMission'));
	Screen2=UIMission(movie.Stack.GetFirstInstanceOf(Class'UIMission'));
	StartingConcealed=true;
	MissionState = Screen.GetMission();
	MissionState = XComGameState_MissionSite(NewGameState.CreateStateObject(class'XComGameState_MissionSite', MissionState.ObjectID));
	//MissionState.GetShadowChamberStrings();
	`log("Schedule name:"@(string(MissionState.SelectedMissionData.SelectedMissionScheduleName)));
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	for(k=0;k<MissionState.GeneratedMission.Mission.MissionSchedules.Length;k++) // Check all mission schedules for seeing if the squad starts concealed on that mission.
	{
		MissionMgr.GetMissionSchedule(MissionState.GeneratedMission.Mission.MissionSchedules[k],Schedule);
		`log("Schedule"@k @"name:"@(string(Schedule.ScheduleID)));
		if(Schedule.XComSquadStartsConcealed==false &&string(Schedule.ScheduleID)!="None" && string(Schedule.ScheduleID)!="")
			StartingConcealed=false;
	}
	if(Screen!=none)
	{
		if(Screen.GetMission().IntelOptions.Length==0) //Set up intel options for missions if they have none
			PickIntelOptions(Screen.GetMission());
		IOPS=Screen.GetMission().IntelOptions;
	}
	else if(Screen2!=none) //Get the movie screen from XCOM HQ Pres. , just in case we cant get the original one from the main screenstack. 
	{
		if(Screen2.GetMission().IntelOptions.Length==0)
			PickIntelOptions(Screen2.GetMission());	//Set up intel options for missions if they have none
		IOPS=Screen2.GetMission().IntelOptions;
		Screen=Screen2;
	}
	`XCOMHISTORY.CleanupPendingGameState(NewGameState);
	foreach IOPS(IntelOption) //Go through all the intel options the mission has in it and check for mutually exclusives.
	{
		HasExclusives=false;
		foreach Screen.GetMission().PurchasedIntelOptions(ExcIntelOption) //if the player has active options that are mutually exclusive flag that option so you wont be able to purchase it.
		{
			foreach GetIntelItemTemplate(ExcIntelOption).MutuallyExclusiveRewards(ExcIntelOptionName)
			{
				if(string(IntelOption.IntelRewardName)~=string(ExcIntelOptionName))
					HasExclusives=true;
			}
		}
		for(i=0;i<SelectedIntelOptions.length;i++) //if the player has purchased(red,refundable) options that are mutually exclusive flag that option so you wont be able to purchase it.
		{
			ExcIntelOption=SelectedIntelOptions[i];
			foreach GetIntelItemTemplate(ExcIntelOption).MutuallyExclusiveRewards(ExcIntelOptionName)
			{
				if(string(IntelOption.IntelRewardName)~=string(ExcIntelOptionName))
					HasExclusives=true;
			}
		}
		if(StartingConcealed&&(string(IntelOption.IntelRewardName)~="SquadConceal_Intel"||string(IntelOption.IntelRewardName)~="IndividualConceal_Intel")) // If we start with a concealed state on the mission and the current option is concealment of any kind- flag it
			StartingConcealed=true;
		else
			StartingConcealed=false;

		if(XComHQ.SoldierUnlockTemplates.Find('SquadSizeIIUnlock') != INDEX_NONE&&(string(IntelOption.IntelRewardName)~="ExtraSoldier_Intel")) // If the campaign has the second squad size upgrade already and the current option is to add a soldier- flag it (tested it on a STOCK campaign, dosnt add to the squad size on that case)
			HasMaxSlots=true;
		else
			HasMaxSlots=false;

		if(HasMaxSlots==false&&StartingConcealed==false&&(Screen.GetMission().PurchasedIntelOptions.Find('IntelRewardName',IntelOption.IntelRewardName) ==-1 && SelectedIntelOptions.Find('IntelRewardName',IntelOption.IntelRewardName) ==-1) &&HasExclusives==false)
			IOPSOut.AddItem(IntelOption); //If the current one is flagged for concealment filtering,extra soldier filtering, mutually exclusive filtering OR is present in the already purchased(red,refundable) intel options or already an active(gray) option dont add it to the available intel options for that mission.
	}
	return IOPSOut;

}
simulated function string GetIntelFriendlyName(MissionIntelOption ItemIntel)
{
	local X2HackRewardTemplateManager HackRewardTemplateManager;
	local X2HackRewardTemplate OptionTemplate;

	HackRewardTemplateManager = class'X2HackRewardTemplateManager'.static.GetHackRewardTemplateManager();
	OptionTemplate = HackRewardTemplateManager.FindHackRewardTemplate(ItemIntel.IntelRewardName);
	return OptionTemplate.GetFriendlyName();
}
simulated function X2HackRewardTemplate GetIntelItemTemplate(MissionIntelOption ItemIntel)
{
	local X2HackRewardTemplateManager HackRewardTemplateManager;
	local X2HackRewardTemplate OptionTemplate;
	
	HackRewardTemplateManager = class'X2HackRewardTemplateManager'.static.GetHackRewardTemplateManager();
	OptionTemplate = HackRewardTemplateManager.FindHackRewardTemplate(ItemIntel.IntelRewardName);
	return OptionTemplate;
}

simulated function bool IsValidIntelItemTemplate(name ItemIntelname)
{
	local X2HackRewardTemplateManager HackRewardTemplateManager;
	local X2HackRewardTemplate OptionTemplate;
	
	HackRewardTemplateManager = class'X2HackRewardTemplateManager'.static.GetHackRewardTemplateManager();
	OptionTemplate = HackRewardTemplateManager.FindHackRewardTemplate(ItemIntelname);
	return (OptionTemplate!=none &&!OptionTemplate.bBadThing);
}

//Sends the bought items to game to make changes. Will be replaced by IntelOptions mission code
simulated function GetItems()
{
	arrIntelItems = GetMissionIntelOptions();
}

static function bool GetIsRampingIntelCosts() 
{
	if ( class'UIListener_MCM_Options'.default.RampingIntelCosts != default.RampingIntelCosts && default.RampingIntelCosts==false ) 
	{
		return class'UIListener_MCM_Options'.default.RampingIntelCosts;
	}
	else 
	{
		return default.RampingIntelCosts;
	}
}
static function float GetRampingIntelCosts(Optional bool PrintLog=false) 
{
	local XComGameState_HeadquartersAlien AlienHQ;
	local float RampLevel;
	local float MaxForce,StartingForce,Force;

	AlienHQ = class'UIUtilities_Strategy'.static.GetAlienHQ(true);
	MaxForce=AlienHQ.default.AlienHeadquarters_MaxForceLevel;
	StartingForce=AlienHQ.default.AlienHeadquarters_StartingForceLevel;
	Force=AlienHQ.ForceLevel;
	RampLevel=(Force-StartingForce)/MaxForce;
	if(!GetIsRampingIntelCosts())
		RampLevel=0;

	if(PrintLog)
		`log("Final Ramp Level:"@1+RampLevel @"Force"@Force @"Force-StartingForce"@Force-StartingForce @"StartingForce"@StartingForce @"MaxForce"@MaxForce @"Ramping:"@GetIsRampingIntelCosts(),true,'Team Dragonpunk Intel Options');
	
	return 1.0f+RampLevel;

}
static function float GetIntelCostMultiplier() 
{
	if ( class'UIListener_MCM_Options'.default.IntelCostMultiplier>0.0f) 
	{
		return class'UIListener_MCM_Options'.default.IntelCostMultiplier;
	}
	else 
	{
		return default.IntelCostMultiplier;
	}
}

simulated function AddResource(string label, string data) //Add resource, copied from the UIAvengerHUD class, handles adding resource description for the resource tab on the top right corner of the screen.
{
	ResourceContainer.AddResource(label, data);
}

simulated function UpdateMonthlySupplies() //copied from the UIAvengerHUD class
{
	local int iMonthly;
	local string Monthly, Prefix;

	iMonthly = class'UIUtilities_Strategy'.static.GetResistanceHQ().GetSuppliesReward();
	Prefix = (iMonthly < 0) ? "-" : "+";
	Monthly = class'UIUtilities_Text'.static.GetColoredText("(" $Prefix $ class'UIUtilities_Strategy'.default.m_strCreditsPrefix $ String(int(Abs(iMonthly))) $")", (iMonthly > 0) ? eUIState_Cash : eUIState_Bad);

	AddResource(XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.MonthlyLabel, Monthly);
}

simulated function UpdateSupplies()//copied from the UIAvengerHUD class
{
	local int iSupplies; 
	local string Supplies, Prefix; 
	
	iSupplies = class'UIUtilities_Strategy'.static.GetResource('Supplies');
	Prefix = (iSupplies < 0) ? "-" : ""; 
	Supplies = class'UIUtilities_Text'.static.GetColoredText(Prefix $ class'UIUtilities_Strategy'.default.m_strCreditsPrefix $ String(iSupplies), (iSupplies > 0) ? eUIState_Cash : eUIState_Bad);

	AddResource(Caps(class'UIUtilities_Strategy'.static.GetResourceDisplayName('Supplies', iSupplies)), Supplies);
}

simulated function UpdateEleriumCrystals()//copied from the UIAvengerHUD class
{
	local int iEleriumCrystals;

	iEleriumCrystals = class'UIUtilities_Strategy'.static.GetResource('EleriumDust');
	AddResource(XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.EleriumLabel, class'UIUtilities_Text'.static.GetColoredText(String(iEleriumCrystals), (iEleriumCrystals > 0) ? eUIState_Normal : eUIState_Bad));
}

simulated function UpdateAlienAlloys()//copied from the UIAvengerHUD class
{
	local int iAlloys;

	iAlloys = class'UIUtilities_Strategy'.static.GetResource('AlienAlloy');
	AddResource(XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.AlloysLabel, class'UIUtilities_Text'.static.GetColoredText(String(iAlloys), (iAlloys > 0) ? eUIState_Normal : eUIState_Bad));
}

simulated function UpdateScientistScore()//copied from the UIAvengerHUD class
{
	local XComGameState_HeadquartersXCom XComHQ;
	local bool bBonusActive;
	local int NumSci;
	
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	NumSci = XComHQ.GetNumberOfScientists();
	bBonusActive = (NumSci > XComHQ.GetNumberOfScientists());
	AddResource(XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.SciLabel, class'UIUtilities_Text'.static.GetColoredText(string(NumSci), bBonusActive ? eUIState_Good : eUIState_Normal));
}
simulated function UpdateEngineerScore()//copied from the UIAvengerHUD class
{
	local XComGameState_HeadquartersXCom XComHQ;
	local bool bBonusActive;
	local int NumEng;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	NumEng = XComHQ.GetNumberOfEngineers();
	bBonusActive = (NumEng > XComHQ.GetNumberOfEngineers());
	AddResource(XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.EngLabel, class'UIUtilities_Text'.static.GetColoredText(string(NumEng), bBonusActive ? eUIState_Good : eUIState_Normal));
}

simulated function UpdateResContacts()//copied from the UIAvengerHUD class
{
	local XComGameState_HeadquartersXCom XComHQ;
	local int iCurrentContacts, iTotalContacts;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	if (XComHQ.IsContactResearched())
	{
		iCurrentContacts = XComHQ.GetCurrentResContacts();
		iTotalContacts = XComHQ.GetPossibleResContacts();

		if (iCurrentContacts >= iTotalContacts)
			AddResource(XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.ContactsLabel, class'UIUtilities_Text'.static.GetColoredText(iCurrentContacts $ "/" $ iTotalContacts, eUIState_Bad));
		else if (iTotalContacts - iCurrentContacts <= 2)
			AddResource(XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.ContactsLabel, class'UIUtilities_Text'.static.GetColoredText(iCurrentContacts $ "/" $ iTotalContacts, eUIState_Warning));
		else
			AddResource(XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.ContactsLabel, class'UIUtilities_Text'.static.GetColoredText(iCurrentContacts $ "/" $ iTotalContacts, eUIState_Cash));
	}
}

defaultproperties
{
	bConsumeMouseEvents = true;
}
