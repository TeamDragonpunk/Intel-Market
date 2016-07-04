class DP_UISimpleCommodityScreen extends UIInventory;

// From GPIntelOptions
var array<MissionIntelOption> arrIntelItems,MissionActive;
// var array<Commodity>		arrItems;
var int						iSelectedItem;
var array<StateObjectReference> m_arrRefs;

var bool		m_bShowButton;
var bool		m_bInfoOnly;
var EUIState	m_eMainColor;
var EUIConfirmButtonStyle m_eStyle;
var int ConfirmButtonX;
var int ConfirmButtonY;

//var UIText OptionDescText;

var public localized String m_strBuy;
var public localized String m_strRefund;

simulated function OnPurchaseClicked(UIList kList, int itemIndex)
{
	// Implement in subclasses
}

simulated function GetItems()
{
	// Implement in subclasses
}

//-------------- UI LAYOUT --------------------------------------------------------
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local array<MissionIntelOption> templist;
	super.InitScreen(InitController, InitMovie, InitName);
	
	// Move and resize list to accommodate label
	List.OnItemDoubleClicked = OnPurchaseClicked;

	SetBuiltLabel("");

	GetItems();

	// May need to remove this...
	SetChooseResearchLayout();
	PopulateData();
	PopulateDataWithRefund(templist);
}

// This may be where we replace the items with the hacker rewards
// Where do we add intel description
// ArrItems is populated in child class in getItems method
simulated function PopulateData()
{
//	local Commodity Template;
	local MissionIntelOption Template;
	// Using this from Elad's suggestion...
	local UIMechaListItem MyItem;
	local int i;
	local UIMission Screen; 
                            
	Screen=UIMission(`SCREENSTACK.GetFirstInstanceOf(Class'UIMission'));

	List.ClearItems();

	
	for(i = 0; i < arrIntelItems.Length; i++)
	{
		MyItem = none; 
		Template = arrIntelItems[i];
		Spawn(class'DP_UIInventory_ListItem', List.itemContainer).InitInventoryListCommodity(Template,Screen.MissionRef, GetButtonString(i), m_eStyle, ConfirmButtonX, ConfirmButtonY);
	}

	if(List.ItemCount == 0 && m_strEmptyListTitle != "")
	{
		TitleHeader.SetText(m_strTitle, m_strEmptyListTitle);
		SetCategory("");
	}
}
simulated function PopulateDataWithRefund(array<MissionIntelOption> SelectedOptions) //Populating the list with correct colors and types.
{
	local MissionIntelOption Template,ExtraTemplate;
	local int i;
	local UIMission Screen; 
    local DP_UIInventory_ListItem TempListItem;                      
	Screen=UIMission(`SCREENSTACK.GetFirstInstanceOf(Class'UIMission'));

	List.ClearItems();
	MissionActive.Length=0;

  	MissionActive=Screen.GetMission().PurchasedIntelOptions; //get all the purchased options that already are on the following mission

	if(MissionActive.Length>0) //Creating the "Active Items:" Label item for the list
	{
		ExtraTemplate.IntelRewardName='';
		Spawn(class'DP_UIInventory_ListItem', List.itemContainer).InitInventoryListCommodity(ExtraTemplate,Screen.MissionRef, "", m_eStyle, ConfirmButtonX, ConfirmButtonY); //Spawning the item
		TempListItem=DP_UIInventory_ListItem(List.itemContainer.GetChildAt(List.itemContainer.NumChildren()-1));
		TempListItem.MC.BeginFunctionOp("populateData");
		TempListItem.MC.QueueString(TempListItem.GetColoredText("Active Items:"));
		TempListItem.MC.QueueString(TempListItem.GetColoredText(""));
		TempListItem.MC.EndOp();
		TempListItem.SetText("Active Items:");
		TempListItem.SetBad(True,""); //Graying out the list item and making it unavailable for clicking

	}
	for(i = 0; i < MissionActive.Length; i++)
	{
		Template = MissionActive[i];
		Spawn(class'DP_UIInventory_ListItem', List.itemContainer).InitInventoryListCommodity(Template,Screen.MissionRef, "", m_eStyle, ConfirmButtonX, ConfirmButtonY); //Spawning the item
		TempListItem=DP_UIInventory_ListItem(List.itemContainer.GetChildAt(List.itemContainer.NumChildren()-1));
		DP_UIInventory_ListItem(List.itemContainer.GetChildAt(List.itemContainer.NumChildren()-1)).SetBad(True,"Already active, Can't refund"); //Graying out the list item and making it unavailable for clicking
		DP_UIInventory_ListItem(List.itemContainer.GetChildAt(List.itemContainer.NumChildren()-1)).SetDisabled(True,"Already active, Can't refund"); //Redding out the list item and making it unavailable for clicking-will only be red if NOT grayed out
		DP_UIInventory_ListItem(List.itemContainer.GetChildAt(List.itemContainer.NumChildren()-1)).MC.FunctionVoid("onReceiveFocus");
		DP_UIInventory_ListItem(List.itemContainer.GetChildAt(List.itemContainer.NumChildren()-1)).OnReceiveFocus();	
		DP_UIInventory_ListItem(List.itemContainer.GetChildAt(List.itemContainer.NumChildren()-1)).MC.FunctionVoid("onLoseFocus");
		DP_UIInventory_ListItem(List.itemContainer.GetChildAt(List.itemContainer.NumChildren()-1)).OnLoseFocus();	
	}
	if(SelectedOptions.Length>0)
	{
		ExtraTemplate.IntelRewardName='';
		Spawn(class'DP_UIInventory_ListItem', List.itemContainer).InitInventoryListCommodity(ExtraTemplate,Screen.MissionRef, "", m_eStyle, ConfirmButtonX, ConfirmButtonY); //Spawning the item
		TempListItem=DP_UIInventory_ListItem(List.itemContainer.GetChildAt(List.itemContainer.NumChildren()-1));
		TempListItem.SetBad(True,"");
		TempListItem.MC.BeginFunctionOp("populateData");
		TempListItem.MC.QueueString(TempListItem.GetColoredText("Purchased Items:"));
		TempListItem.MC.QueueString(TempListItem.GetColoredText(""));
		TempListItem.MC.EndOp();
		TempListItem.SetText("Purchased Items:");
		TempListItem.SetBad(True,""); //Graying out the list item and making it unavailable for clicking
	}
	for(i = 0; i < SelectedOptions.Length; i++)
	{
		Template = SelectedOptions[i];
		Spawn(class'DP_UIInventory_ListItem', List.itemContainer).InitInventoryListCommodity(Template,Screen.MissionRef, "REFUND", m_eStyle, ConfirmButtonX, ConfirmButtonY); //Spawning the item
		DP_UIInventory_ListItem(List.itemContainer.GetChildAt(List.itemContainer.NumChildren()-1)).SetBad(False,""); //Making sure it's capabale of being clicked on
		DP_UIInventory_ListItem(List.itemContainer.GetChildAt(List.itemContainer.NumChildren()-1)).SetDisabled(False,""); //Making it red.
	}
	if(arrIntelItems.Length>0)
	{
		ExtraTemplate.IntelRewardName='';
		Spawn(class'DP_UIInventory_ListItem', List.itemContainer).InitInventoryListCommodity(ExtraTemplate,Screen.MissionRef, "", m_eStyle, ConfirmButtonX, ConfirmButtonY); //Spawning the item
		TempListItem=DP_UIInventory_ListItem(List.itemContainer.GetChildAt(List.itemContainer.NumChildren()-1));
		TempListItem.SetBad(True,"");
		TempListItem.MC.BeginFunctionOp("populateData");
		TempListItem.MC.QueueString(TempListItem.GetColoredText("Available Items:"));
		TempListItem.MC.QueueString(TempListItem.GetColoredText(""));
		TempListItem.MC.EndOp();
		TempListItem.SetText("Available Items:");
		TempListItem.SetBad(True,""); //Graying out the list item and making it unavailable for clicking
	}
	for(i = 0; i < arrIntelItems.Length; i++)
	{
		Template = arrIntelItems[i];
		Spawn(class'DP_UIInventory_ListItem', List.itemContainer).InitInventoryListCommodity(Template,Screen.MissionRef,GetButtonString(i) , m_eStyle, ConfirmButtonX, ConfirmButtonY); //Spawning the item
	}
	
	if(List.ItemCount == 0 && m_strEmptyListTitle != "")
	{
		TitleHeader.SetText(m_strTitle, m_strEmptyListTitle);
		SetCategory("");
	}
	`log("1: Number of active:"@MissionActive.Length @"Number of Purchased:" @SelectedOptions.Length @"Number of Available"@arrIntelItems.Length,true,'Team Dragonpunk');
	`log("2: Number of active:"@Screen.GetMission().PurchasedIntelOptions.Length @"Number of Purchased:" @SelectedOptions.Length @"Number of Available"@Screen.GetMission().IntelOptions.Length,true,'Team Dragonpunk');
	
}
// Use this to create initial list population above and then delete!
simulated function SelectIntelItem(UIList ContainerList, int ItemIndex)
{
	local MissionIntelOption SelectedOption;
	local X2HackRewardTemplateManager HackRewardTemplateManager;
	local X2HackRewardTemplate OptionTemplate;
	local XComGameState_MissionSite MissionState;
	
	HackRewardTemplateManager = class'X2HackRewardTemplateManager'.static.GetHackRewardTemplateManager();

}


simulated function int GetItemIndex(MissionIntelOption Item)
{
	local int i;

	for(i = 0; i < arrIntelItems.Length; i++)
	{
		if(arrIntelItems[i] == Item)
		{
			return i;
		}
	}

	return -1;
}

//-------------- GAME DATA HOOKUP --------------------------------------------------------

simulated function MissionIntelOption GetIOPSItem(int ItemIndex)
{
	return 	arrIntelItems[ItemIndex];
}

simulated function X2HackRewardTemplate GetItemTemplate(int ItemIndex)
{
	local X2HackRewardTemplateManager HackRewardTemplateManager;
	local X2HackRewardTemplate OptionTemplate;
	
	HackRewardTemplateManager = class'X2HackRewardTemplateManager'.static.GetHackRewardTemplateManager();
	OptionTemplate = HackRewardTemplateManager.FindHackRewardTemplate(arrIntelItems[ItemIndex].IntelRewardName);
	return OptionTemplate;
}
simulated function String GetItemImage(int ItemIndex)
{
	local X2HackRewardTemplateManager HackRewardTemplateManager;
	local X2HackRewardTemplate OptionTemplate;
	
	HackRewardTemplateManager = class'X2HackRewardTemplateManager'.static.GetHackRewardTemplateManager();
	OptionTemplate = HackRewardTemplateManager.FindHackRewardTemplate(arrIntelItems[ItemIndex].IntelRewardName);

	if( ItemIndex > -1 && ItemIndex < arrIntelItems.Length )
	{
		return OptionTemplate.RewardImagePath;
	}
	else
	{
		return "";
	}
}

simulated function String GetItemCostString(int ItemIndex)
{
	local X2HackRewardTemplateManager HackRewardTemplateManager;
	local X2HackRewardTemplate OptionTemplate;
	
	HackRewardTemplateManager = class'X2HackRewardTemplateManager'.static.GetHackRewardTemplateManager();
	OptionTemplate = HackRewardTemplateManager.FindHackRewardTemplate(arrIntelItems[ItemIndex].IntelRewardName);
	if( ItemIndex > -1 && ItemIndex < arrIntelItems.Length )
	{
		return ""$int(((OptionTemplate.MaxIntelCost+OptionTemplate.MinHackSuccess)/2.0f)) ;
	}
	else
	{
		return "";
	}
}



simulated function String GetItemDescString(int ItemIndex)
{
	local X2HackRewardTemplateManager HackRewardTemplateManager;
	local X2HackRewardTemplate OptionTemplate;
	
	HackRewardTemplateManager = class'X2HackRewardTemplateManager'.static.GetHackRewardTemplateManager();
	OptionTemplate = HackRewardTemplateManager.FindHackRewardTemplate(arrIntelItems[ItemIndex].IntelRewardName);

	if( ItemIndex > -1 && ItemIndex < arrIntelItems.Length )
	{
		return OptionTemplate.GetDescription(none);
	}
	else
	{
		return "";
	}
}

simulated function bool NeedsAttention(int ItemIndex)
{
	// Implement in subclasses
	return false;
}
simulated function bool ShouldShowGoodState(int ItemIndex)
{
	// Implement in subclasses
	return false;
}

// TODO: Use null check for list, but replace with intel check
simulated function bool CanAffordItem(int ItemIndex)
{
	if( ItemIndex > -1 && ItemIndex < arrIntelItems.Length )
	{
		return CanAffordIntelOptions(arrIntelItems[ItemIndex]);
	}
	else
	{
		return false;
	}
}

// Original logic that assumes player purchases all intel options at once.
simulated function bool CanAffordIntelOptions(MissionIntelOption IntelOption)
{
//	return (GetTotalIntelCost() <= GetAvailableIntel());
	
	return (GetIntelCost(IntelOption) <= GetAvailableIntel());
}

// Gets the player's intel amount
simulated function int GetAvailableIntel()
{
	return class'UIUtilities_Strategy'.static.GetXComHQ().GetResourceAmount('Intel');
}

// gets the until cost of the reward. Not sure if one reward at a time.
simulated function int GetIntelCost(MissionIntelOption IntelOption)
{
	return class'UIUtilities_Strategy'.static.GetCostQuantity(IntelOption.Cost, 'Intel');
}
simulated function bool MeetsItemReqs(int ItemIndex)
{
	if( ItemIndex > -1 && ItemIndex < arrIntelItems.Length )
	{

		return true;
	}
	else
	{
		return false;
	}
}

simulated function bool IsItemPurchased(int ItemIndex)
{
	// Implement in subclasses
	return false;
}
simulated function String GetButtonString(int ItemIndex)
{
	return m_strBuy;
}


defaultproperties
{
	m_bShowButton = true
	m_bInfoOnly = false
	m_eMainColor = eUIState_Normal
	m_eStyle = eUIConfirmButtonStyle_Default //word button
	ConfirmButtonX = 2
	ConfirmButtonY = 0
}