// class UIBlackMarket_Buy extends UISimpleCommodityScreen;
class DP_UIIntelMarket_Buy extends DP_UISimpleCommodityScreen;

var localized String IntelAvailableLabel;
var localized String IntelOptionsLabel;
var localized String IntelCostLabel;
var localized String IntelTotalLabel;

var UIX2ResourceHeader			ResourceContainer;

// List may not be needed
var UIList List;
//var UIText OptionDescText;

var UILargeButton ExitButton;
var array<MissionIntelOption> SelectedIntelOptions;

var UIItemCard_HackingRewards HackingRewardCard;

//----------------------------------------------------------------------------
// MEMBERS

//Creates the Screen/UI. From original BM_Buy class
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
	ResourceContainer = Spawn(class'UIX2ResourceHeader', self).InitResourceHeader('ResourceContainer');
	ResourceContainer.AnchorTopRight();
	UpdateIntel();
	HackingRewardCard=UIItemCard_HackingRewards(Spawn(class'UIItemCard_HackingRewards', ListContainer).InitItemCard('HackingItemCard'));
	HackingRewardCard.SetPosition(635,0);
	HackingRewardCard.Show();
	HackingRewardCard.PopulateIntelItemCard();
	HackingRewardCard.SetAlpha(1);
	HackingRewardCard.PopulateIntelItemCard(self.GetItemTemplate(0));
	HackingRewardCard.SetInitialParameters();
	HackingRewardCard.Show();
	ExitButton = Spawn(class'UILargeButton', self);
	ExitButton.bAnimateOnInit = false;
	ExitButton.InitLargeButton('ExitButton',"SQUAD" , "SELECT", OnStartMissionClicked);
	ExitButton.AnchorBottomRight();
	MC.BeginFunctionOp("SetGreeble");
	MC.QueueString(class'UIAlert'.default.m_strBlackMarketFooterLeft);
	MC.QueueString(class'UIAlert'.default.m_strBlackMarketFooterRight);
//	MC.QueueString(class'UIAlert'.default.m_strBlackMarketLogoString);
	MC.QueueString("GOBLIN BAZAAR");
	MC.EndOp();
	GetItems();
	SelectedIntelOptions=GetMissionPurchasedOptions();
	
}
simulated function PopulateData()
{
	GetItems();
	ResourceContainer.Show();
	m_arrRefs.length=0;
	PopulateDataWithRefund(SelectedIntelOptions);
}
simulated function OnStartMissionClicked(UIButton button)
{
	local DP_UIMission_Council MyScreen;
	local DP_UIIntelMarket MyDPScreen;
	//MyScreen=DP_UIMission_Council(`ScreenStack.GetFirstInstanceOf(class'UIMission'));
	MyDPScreen=DP_UIIntelMarket(`ScreenStack.GetFirstInstanceOf(class'DP_UIIntelMarket'));
	`SCREENSTACK.Pop(self);
	`SCREENSTACK.PopFirstInstanceOfClass(Class'DP_UIIntelMarket');
	BuyAndSaveIntelOptions();
	CloseScreen();
	//MyDPScreen.CloseScreen();
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Black_Market_Ambience_Loop_Stop");
	if(MyDPScreen!=none)
	{
		MyDPScreen.ExposeOLC(button);
	}
}
function OnPurchasedAnIOPS(MissionIntelOption NewIntelO)
{
	local array<string> strSplit;
	local string strSearch;

	if( CanAffordIntelOptionsAll(NewIntelO,true) )
	{
		PlaySFX("StrategyUI_Purchase_Item");
		if(SelectedIntelOptions.Find('IntelRewardName',NewIntelO.IntelRewardName)==-1)
		{
			`log("Can Affort Intel: "@GetIntelFriendlyName(NewIntelO),true,'Dragonpunk IntelMarket');
			SelectedIntelOptions.AddItem(NewIntelO);
		}
		else
		{
			`log("Refunding Intel: "@GetIntelFriendlyName(NewIntelO),true,'Dragonpunk IntelMarket');
			SelectedIntelOptions.RemoveItem(NewIntelO);
		}	
		/*strSplit=SplitString(GetIntelFriendlyName(NewIntelO)," ");
		foreach strSplit(strSearch)
		{
			if("squad"~=strSearch||"squadwide"~=strSearch)
			{
				arrIntelItems.RemoveItem(NewIntelO);
				break;
			}	
		}*/
		
		PopulateData();
		XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.UpdateResources();
		UpdateIntel();
	}
}
simulated function bool CanAffordIntelOptionsAll(MissionIntelOption IntelOption,optional bool Show=false)
{
	local MissionIntelOption tempIntelOption;
	local int TotalCostRightNow,i;
//	return (GetTotalIntelCost() <= GetAvailableIntel());
  	TotalCostRightNow=0;    
	if(SelectedIntelOptions.Find('IntelRewardName',IntelOption.IntelRewardName)!=-1)   
		return true;
                                     
	for(i=0;i<SelectedIntelOptions.length;i++)
	{
		tempIntelOption=SelectedIntelOptions[i];
		TotalCostRightNow=TotalCostRightNow+GetIntelCost(tempIntelOption);
	}
	if(show)
		`log("Current Intel Cost:"@GetIntelCost(IntelOption) @"Intel Options Cost:"@TotalCostRightNow @"Total Intel Cost:"@(TotalCostRightNow+GetIntelCost(IntelOption)),true,'Team Dragonpunk IntelMarket');
	
	return ((TotalCostRightNow+GetIntelCost(IntelOption)) <= GetAvailableIntel());
}
simulated function CloseScreen()
{
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Black_Market_Ambience_Loop_Stop");
	super.CloseScreen();
}

//Iterator uses to populate the UI (where is this iterated?)
// We want to get almost all rewards for Intel Market
// TODO: Perhaps filter out some rewards based on mission type or being too OP
//simulated function SelectIntelItem(UIList ContainerList, int ItemIndex)
//{
//	local MissionIntelOption SelectedOption;
//	local X2HackRewardTemplateManager HackRewardTemplateManager;
//	local X2HackRewardTemplate OptionTemplate;
	
//	HackRewardTemplateManager = class'X2HackRewardTemplateManager'.static.GetHackRewardTemplateManager();
//	SelectedOption = GetMission().IntelOptions[ItemIndex];
//	OptionTemplate = HackRewardTemplateManager.FindHackRewardTemplate(SelectedOption.IntelRewardName);

//	OptionDescText.SetText(OptionTemplate.GetDescription(none));
//}

simulated function UpdateIntel()
{
	local int iIntel;
	local MissionIntelOption tempIntelOption;
	local int TotalCostRightNow,i;
//	return (GetTotalIntelCost() <= GetAvailableIntel());
  	TotalCostRightNow=0;                                                   
	for(i=0;i<SelectedIntelOptions.length;i++)
	{
		tempIntelOption=SelectedIntelOptions[i];
		TotalCostRightNow=TotalCostRightNow+GetIntelCost(tempIntelOption);
	}
	

	ResourceContainer.ClearResources();
	UpdateMonthlySupplies();
	UpdateSupplies();
	iIntel = class'UIUtilities_Strategy'.static.GetResource('Intel') -TotalCostRightNow;
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
simulated function OnPurchaseClicked(UIList kList, int itemIndex)
{
	local MissionIntelOption ThisSelectedIOP;
	ThisSelectedIOP=(DP_UIInventory_ListItem(kList.ItemContainer.GetChildAt(ItemIndex)).ItemIntel);
	if(MissionActive.Find('IntelRewardName',ThisSelectedIOP.IntelRewardName)==-1)
		OnPurchasedAnIOPS(ThisSelectedIOP);
}

simulated function BuyAndSaveIntelOptions()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_MissionSite MissionState;
	local MissionIntelOption IntelOption;
	local UIMission Screen; 
	local bool StartingConcealed;
    local int i,k;                       
	Screen=UIMission(`SCREENSTACK.GetFirstInstanceOf(Class'UIMission'));
	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Buy and Save Selected Mission Intel Options");
	
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	NewGameState.AddStateObject(XComHQ);
	
	MissionState = Screen.GetMission();
	MissionState = XComGameState_MissionSite(NewGameState.CreateStateObject(class'XComGameState_MissionSite', MissionState.ObjectID));
	NewGameState.AddStateObject(MissionState);

	// Save and buy the intel options, and add their tactical tags
	for(i=0;i<MissionState.PurchasedIntelOptions.length;i++)
	{
		IntelOption=MissionState.PurchasedIntelOptions[i];
		XComHQ.TacticalGameplayTags.AddItem(IntelOption.IntelRewardName);
	}
	for(i=0;i<SelectedIntelOptions.length;i++)
	{
		IntelOption=SelectedIntelOptions[i];
		XComHQ.TacticalGameplayTags.AddItem(IntelOption.IntelRewardName);
		XComHQ.PayStrategyCost(NewGameState, IntelOption.Cost, XComHQ.MissionOptionScalars);
		MissionState.PurchasedIntelOptions.AddItem(IntelOption);
	}
	if(SelectedIntelOptions.Length>0 ||MissionState.PurchasedIntelOptions.length>0)
		`XCOMHISTORY.AddGameStateToHistory(NewGameState);
	else
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
	SelectedIntelOptions.Length=0;
	XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.UpdateResources();
}
simulated function array<MissionIntelOption> GetMissionPurchasedOptions()
{
	local XComGameState_MissionSite MissionState;
	local UIMission Screen;

	Screen=UIMission(`SCREENSTACK.GetFirstInstanceOf(Class'UIMission'));
	MissionState = Screen.GetMission();
	return MissionState.PurchasedIntelOptions;	
}
simulated function SelectedItemChanged(UIList ContainerList, int ItemIndex)
{
	local array<UIPanel> ItemCards;
	local UIPanel Card;
	local MissionIntelOption SelectedIOP;
	local int i;
	SelectedIOP=DP_UIInventory_ListItem(ContainerList.ItemContainer.GetChildAt(ItemIndex)).ItemIntel;
	super.SelectedItemChanged(ContainerList,ItemIndex);
	`log(GetIntelItemTemplate(SelectedIOP).GetDescription(none),true,'Team Dragonpunk Goblin Bazaar');
	ListContainer.RemoveChild(ItemCard);
	HackingRewardCard.Show();
	if(SelectedIOP.IntelRewardName!='')
		HackingRewardCard.PopulateIntelItemCard(GetIntelItemTemplate(SelectedIOP),,SelectedIOP);
	else
		HackingRewardCard.SetNullParameters();
	for(i=0;i<ContainerList.ItemContainer.NumChildren();i++)
	{
		SelectedIOP=DP_UIInventory_ListItem(ContainerList.ItemContainer.GetChildAt(i)).ItemIntel;
		if((arrIntelItems.Find('IntelRewardName',SelectedIOP.IntelRewardName)!=-1))
		{
			if(!CanAffordIntelOptionsAll(SelectedIOP)&&((DP_UIInventory_ListItem(ContainerList.ItemContainer.GetChildAt(i)).bDisabled==false)||(DP_UIInventory_ListItem(ContainerList.ItemContainer.GetChildAt(i)).bIsBad==false)))
			{
				DP_UIInventory_ListItem(ContainerList.ItemContainer.GetChildAt(i)).SetBad(true,"Cant Afford This Purchase");
				DP_UIInventory_ListItem(ContainerList.ItemContainer.GetChildAt(i)).SetDisabled(true,"Cant Afford This Purchase");
			}
			else if(CanAffordIntelOptionsAll(SelectedIOP)&&((DP_UIInventory_ListItem(ContainerList.ItemContainer.GetChildAt(i)).bDisabled==true)||(DP_UIInventory_ListItem(ContainerList.ItemContainer.GetChildAt(i)).bIsBad==true)))
			{
				DP_UIInventory_ListItem(ContainerList.ItemContainer.GetChildAt(i)).SetBad(false,"");
				DP_UIInventory_ListItem(ContainerList.ItemContainer.GetChildAt(i)).SetDisabled(false);
			}
		}
		else if(SelectedIntelOptions.Find('IntelRewardName',SelectedIOP.IntelRewardName)!=-1)
			DP_UIInventory_ListItem(ContainerList.ItemContainer.GetChildAt(i)).SetBad(false,"");

	}
}
//-------------- GAME DATA HOOKUP --------------------------------------------------------

//Repurpose this to get Hacker reward template and state
//simulated function XComGameState_IntelMarket GetMarket()
//{
//	return class'UIUtilities_Strategy'.static.GetIntelMarket();
//}

// Override from parent class. Called during list population.
// All our buttons should say "buy" or "buy for mission"
simulated function String GetButtonString(int ItemIndex)
{

//		return m_strBuy;
		return "BUY";
}
simulated function PickIntelOptions(XComGameState_MissionSite MissionState)
{
	local XComGameState NewGameState;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Buy and Save Selected Mission Intel Options");
	NewGameState.AddStateObject(MissionState);
	MissionState.PickIntelOptions();
	`XCOMHISTORY.AddGameStateToHistory(NewGameState);
}
// Not sure if this gets the bought intel options, or ones available to purchase for the mission
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
	for(k=0;k<MissionState.GeneratedMission.Mission.MissionSchedules.Length;k++)
	{
		MissionMgr.GetMissionSchedule(MissionState.GeneratedMission.Mission.MissionSchedules[k],Schedule);
		`log("Schedule"@k @"name:"@(string(Schedule.ScheduleID)));
		if(Schedule.XComSquadStartsConcealed==false &&string(Schedule.ScheduleID)!="None" && string(Schedule.ScheduleID)!="")
			StartingConcealed=false;
	}
	if(Screen!=none)
	{
		if(Screen.GetMission().IntelOptions.Length==0)
			PickIntelOptions(Screen.GetMission());
		IOPS=Screen.GetMission().IntelOptions;
	}
	else if(Screen2!=none)
	{
		if(Screen2.GetMission().IntelOptions.Length==0)
			PickIntelOptions(Screen2.GetMission());
		IOPS=Screen2.GetMission().IntelOptions;
		Screen=Screen2;
	}
	`XCOMHISTORY.CleanupPendingGameState(NewGameState);
	foreach IOPS(IntelOption)
	{
		HasExclusives=false;
		foreach Screen.GetMission().PurchasedIntelOptions(ExcIntelOption)
		{
			foreach GetIntelItemTemplate(ExcIntelOption).MutuallyExclusiveRewards(ExcIntelOptionName)
			{
				if(string(IntelOption.IntelRewardName)~=string(ExcIntelOptionName))
					HasExclusives=true;
			}
		}
		for(i=0;i<SelectedIntelOptions.length;i++)
		{
			ExcIntelOption=SelectedIntelOptions[i];
			foreach GetIntelItemTemplate(ExcIntelOption).MutuallyExclusiveRewards(ExcIntelOptionName)
			{
				if(string(IntelOption.IntelRewardName)~=string(ExcIntelOptionName))
					HasExclusives=true;
			}
		}
		if(StartingConcealed&&(string(IntelOption.IntelRewardName)~="SquadConceal_Intel"||string(IntelOption.IntelRewardName)~="IndividualConceal_Intel"))
			StartingConcealed=true;
		else
			StartingConcealed=false;
		if(XComHQ.SoldierUnlockTemplates.Find('SquadSizeIIUnlock') != INDEX_NONE&&(string(IntelOption.IntelRewardName)~="ExtraSoldier_Intel"))
			HasMaxSlots=true;
		if(HasMaxSlots==false&&StartingConcealed==false&&(Screen.GetMission().PurchasedIntelOptions.Find('IntelRewardName',IntelOption.IntelRewardName) ==-1 && SelectedIntelOptions.Find('IntelRewardName',IntelOption.IntelRewardName) ==-1) &&HasExclusives==false)
			IOPSOut.AddItem(IntelOption);
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
//Sends the bought items to game to make changes. Will be replaced by IntelOptions mission code
simulated function GetItems()
{
//	local XComGameState NewGameState;
//	local XComGameState_IntelMarket IntelMarketState;

//	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update Tech Rushes");
//	IntelMarketState = XComGameState_IntelMarket(NewGameState.CreateStateObject(class'XComGameState_IntelMarket', GetMarket().ObjectID));
//	NewGameState.AddStateObject(IntelMarketState);
//	IntelMarketState.UpdateTechRushItems(NewGameState);
//	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

//	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// Repopulates Items from available list. Need to rewrite logic for Intel...
	// Checkbox system doesn't remove already bought intel items...
	// TODO: This is where we need to populate the list with unpurchased hacker rewards
//	arrItems = GetMarket().GetForSaleList();
	arrIntelItems = GetMissionIntelOptions();
}

simulated function AddResource(string label, string data)
{
	ResourceContainer.AddResource(label, data);
}

simulated function UpdateMonthlySupplies()
{
	local int iMonthly;
	local string Monthly, Prefix;

	iMonthly = class'UIUtilities_Strategy'.static.GetResistanceHQ().GetSuppliesReward();
	Prefix = (iMonthly < 0) ? "-" : "+";
	Monthly = class'UIUtilities_Text'.static.GetColoredText("(" $Prefix $ class'UIUtilities_Strategy'.default.m_strCreditsPrefix $ String(int(Abs(iMonthly))) $")", (iMonthly > 0) ? eUIState_Cash : eUIState_Bad);

	AddResource(XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.MonthlyLabel, Monthly);
}

simulated function UpdateSupplies()
{
	local int iSupplies; 
	local string Supplies, Prefix; 
	
	iSupplies = class'UIUtilities_Strategy'.static.GetResource('Supplies');
	Prefix = (iSupplies < 0) ? "-" : ""; 
	Supplies = class'UIUtilities_Text'.static.GetColoredText(Prefix $ class'UIUtilities_Strategy'.default.m_strCreditsPrefix $ String(iSupplies), (iSupplies > 0) ? eUIState_Cash : eUIState_Bad);

	AddResource(Caps(class'UIUtilities_Strategy'.static.GetResourceDisplayName('Supplies', iSupplies)), Supplies);
}

simulated function UpdateEleriumCrystals()
{
	local int iEleriumCrystals;

	iEleriumCrystals = class'UIUtilities_Strategy'.static.GetResource('EleriumDust');
	AddResource(XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.EleriumLabel, class'UIUtilities_Text'.static.GetColoredText(String(iEleriumCrystals), (iEleriumCrystals > 0) ? eUIState_Normal : eUIState_Bad));
}

simulated function UpdateAlienAlloys()
{
	local int iAlloys;

	iAlloys = class'UIUtilities_Strategy'.static.GetResource('AlienAlloy');
	AddResource(XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.AlloysLabel, class'UIUtilities_Text'.static.GetColoredText(String(iAlloys), (iAlloys > 0) ? eUIState_Normal : eUIState_Bad));
}

simulated function UpdateScientistScore()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local bool bBonusActive;
	local int NumSci;
	
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	NumSci = XComHQ.GetNumberOfScientists();
	bBonusActive = (NumSci > XComHQ.GetNumberOfScientists());
	AddResource(XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.SciLabel, class'UIUtilities_Text'.static.GetColoredText(string(NumSci), bBonusActive ? eUIState_Good : eUIState_Normal));
}
simulated function UpdateEngineerScore()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local bool bBonusActive;
	local int NumEng;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	NumEng = XComHQ.GetNumberOfEngineers();
	bBonusActive = (NumEng > XComHQ.GetNumberOfEngineers());
	AddResource(XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.EngLabel, class'UIUtilities_Text'.static.GetColoredText(string(NumEng), bBonusActive ? eUIState_Good : eUIState_Normal));
}

simulated function UpdateResContacts()
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
