// class UIBlackMarket_Buy extends UISimpleCommodityScreen;
class DP_UIIntelMarket_Buy extends DP_UISimpleCommodityScreen;

var localized String IntelAvailableLabel;
var localized String IntelOptionsLabel;
var localized String IntelCostLabel;
var localized String IntelTotalLabel;

// List may not be needed
var UIList List;
var UIText OptionDescText;
var UIText TotalIntelText;

var UILargeButton ExitButton;

var UIItemCard_HackingRewards HackingRewardCard;
var array<MissionIntelOption> SelectedOptions;

//----------------------------------------------------------------------------
// MEMBERS

//Creates the Screen/UI. From original BM_Buy class
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local array<UIPanel> ItemCards;
	local UIPanel Card;
	local object thisObj;
	thisObj=self;
	m_strTitle = ""; //Clear the header out intentionally. 	
	super.InitScreen(InitController, InitMovie, InitName);
	SetBlackMarketLayout();
	ItemCard.PopulateData(" "," "," ","");
	ItemCard.SetAlpha(0.001f);
	ItemCard.SetVisible(false);
	ListContainer.RemoveChild(ItemCard);
	HackingRewardCard=UIItemCard_HackingRewards(Spawn(class'UIItemCard_HackingRewards', ListContainer).InitItemCard('HackingItemCard'));
	HackingRewardCard.SetPosition(635,0);
	HackingRewardCard.Show();
	HackingRewardCard.PopulateIntelItemCard();
	HackingRewardCard.SetAlpha(1);
	HackingRewardCard.PopulateIntelItemCard(self.GetItemTemplate(0));
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
	`XEVENTMGR.RegisterForEvent(thisObj,'SelectedIntelOption',OnSelectedIntelOption, ELD_Immediate);
}
simulated function PopulateData()
{
	GetItems();
	super.PopulateData();
}
simulated function OnStartMissionClicked(UIButton button)
{
	local DP_UIMission_Council MyScreen;
	MyScreen=DP_UIMission_Council(`ScreenStack.GetFirstInstanceOf(class'UIMission'));
	`SCREENSTACK.Pop(self);
	`SCREENSTACK.PopFirstInstanceOfClass(Class'DP_UIIntelMarket');
	//CloseScreen();
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Black_Market_Ambience_Loop_Stop");
	BuyAndSaveIntelOptions();
	if(MyScreen!=none)
	{
		MyScreen.ExposeOLC(button);
	}
	self.OnRemoved();
}
function EventListenerReturn OnSelectedIntelOption(Object EventData, Object EventSource, XComGameState NewGameState, Name InEventID)
{
	local array<string> strSplit;
	local string strSearch;
	local MissionIntelOption NewIntelO;

	NewIntelO=DP_UIInventory_ListItem(EventData).ItemIntel;
	if( CanAffordItem(iSelectedItem) )
	{
		PlaySFX("StrategyUI_Purchase_Item");
		`log("Can Affort Intel: "@GetIntelFriendlyName(NewIntelO),true,'Dragonpunk IntelMarket');
		SelectedOptions.AddItem(NewIntelO);
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
	}
	return ELR_NoInterrupt;
}

simulated function CloseScreen()
{
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Black_Market_Ambience_Loop_Stop");
	super.CloseScreen();
}
simulated function OnRemoved()
{
	super.OnRemoved();
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

//-------------- EVENT HANDLING --------------------------------------------------------

//Manges the original BM_Buy logic for repopulating list
simulated function OnPurchaseClicked(UIList kList, int itemIndex)
{
	if (itemIndex != iSelectedItem)
	{
		iSelectedItem = itemIndex;
	}
	// This line expects type commodity. Replace with intel logic
	if( CanAffordItem(iSelectedItem) )
	{
		PlaySFX("StrategyUI_Purchase_Item");
		// Use all lines of code here except for this one..
//		GetMarket().BuyIntelMarketItem(arrItems[iSelectedItem].RewardRef);
		GetItems();
		// Spawns inventory item for parent class. Replace with intel population for list
		PopulateData();
		
	}
	else
	{
		class'UIUtilities_Sound'.static.PlayNegativeSound();
	}
	XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.UpdateResources();
}

simulated function BuyAndSaveIntelOptions()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_MissionSite MissionState;
	local MissionIntelOption IntelOption;
	local UIMission Screen; 
                            
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
	foreach SelectedOptions(IntelOption)
	{
		XComHQ.TacticalGameplayTags.AddItem(IntelOption.IntelRewardName);
		XComHQ.PayStrategyCost(NewGameState, IntelOption.Cost, XComHQ.MissionOptionScalars);
		MissionState.PurchasedIntelOptions.AddItem(IntelOption);
	}
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	SelectedOptions.Length=0;

}

simulated function SelectedItemChanged(UIList ContainerList, int ItemIndex)
{
	local array<UIPanel> ItemCards;
	local UIPanel Card;
	
	super.SelectedItemChanged(ContainerList,ItemIndex);
	//TitleHeader.SetText(self.GetItemDescString(ItemIndex));
	`log(self.GetItemDescString(ItemIndex),true,'Team Dragonpunk Goblin Bazaar');
	ListContainer.RemoveChild(ItemCard);
	HackingRewardCard.Show();
	HackingRewardCard.PopulateIntelItemCard(self.GetItemTemplate(ItemIndex),,GetIOPSItem(ItemIndex));
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

// Not sure if this gets the bought intel options, or ones available to purchase for the mission
simulated function array<MissionIntelOption> GetMissionIntelOptions()
{
//	return GetMission().IntelOptions;
  	local UIMission Screen,Screen2; 
    local array<MissionIntelOption> IOPS,IOPSOut;                  
    local MissionIntelOption IntelOption,ExcIntelOption;
	local name ExcIntelOptionName;                  
	local bool HasExclusives;                  
	Screen=UIMission(`SCREENSTACK.GetFirstInstanceOf(Class'UIMission'));
	Screen2=UIMission(movie.Stack.GetFirstInstanceOf(Class'UIMission'));
	if(Screen!=none)
		IOPS=Screen.GetMission().IntelOptions;
	else if(Screen2!=none)
	{
		IOPS=Screen2.GetMission().IntelOptions;
		Screen=Screen2;
	}

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
		foreach SelectedOptions(ExcIntelOption)
		{
			foreach GetIntelItemTemplate(ExcIntelOption).MutuallyExclusiveRewards(ExcIntelOptionName)
			{
				if(string(IntelOption.IntelRewardName)~=string(ExcIntelOptionName))
					HasExclusives=true;
			}
		}
		if((Screen.GetMission().PurchasedIntelOptions.Find('IntelRewardName',IntelOption.IntelRewardName) ==-1 && SelectedOptions.Find('IntelRewardName',IntelOption.IntelRewardName) ==-1) &&HasExclusives==false)
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

// Buys the selected rewards. Will need to change to purchase rewards one at a time. Make Global?
simulated function BuyIntelOptions()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_MissionSite MissionState;
	local MissionIntelOption IntelOption;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Buy Mission Intel Options");
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	NewGameState.AddStateObject(XComHQ);

	// Delete this and mirror the single use logic in BM_Buy + repopulation
	foreach SelectedOptions(IntelOption)
	{
		XComHQ.TacticalGameplayTags.AddItem(IntelOption.IntelRewardName);
		XComHQ.PayStrategyCost(NewGameState, IntelOption.Cost, XComHQ.MissionOptionScalars);
	}

	// Save the purchased options
	MissionState = XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(UIMission(Screen).MissionRef.ObjectID));
//	MissionState = GetMission();
//	MissionState = XComGameState_MissionSite(NewGameState.CreateStateObject(class'XComGameState_MissionSite', MissionState.ObjectID));
	MissionState = XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(UIMission(Screen).MissionRef.ObjectID));
	NewGameState.AddStateObject(MissionState);
	MissionState.PurchasedIntelOptions = SelectedOptions;

	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		// Understand this better. Might be worth calling even if no intel is bought.
		History.CleanupPendingGameState(NewGameState);
	}
}

defaultproperties
{
	bConsumeMouseEvents = true;
}
