//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIInventory_ListItem.uc
//  AUTHOR:  Samuel Batista
//  PURPOSE: UIPanel representing a list entry on UIInventory_Manufacture screen.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class DP_UIInventory_ListItem extends UIListItemString;

var int Quantity;
var X2ItemTemplate ItemTemplate;
var MissionIntelOption ItemIntel;
var StateObjectReference ItemRef;
var X2EncyclopediaTemplate XComDatabaseEntry;

//Taken from the parent, switched the type so it would take in an intel option.
simulated function InitInventoryListCommodity(MissionIntelOption initIntel, 
											  optional StateObjectReference InitItemRef, 
											  optional string Confirm, 
											  optional EUIConfirmButtonStyle InitConfirmButtonStyle = eUIConfirmButtonStyle_Default,
											  optional int InitRightCol,
											  optional int InitHeight)
{
	// Set data before calling super, so that it's available in the initialization. 
	ItemIntel = initIntel;
	Quantity = 0;
	ItemRef = InitItemRef;
	ConfirmButtonStyle = InitConfirmButtonStyle;

	InitListItem();

	SetConfirmButtonStyle(ConfirmButtonStyle, Confirm, InitRightCol, InitHeight,OnClickConfirmButton, OnDoubleclickConfirmButton);

	//Create all of the children before realizing, to be sure they can receive info. 
	RealizeDisabledState();
	RealizeBadState();
	RealizeAttentionState();
	RealizeGoodState();
}

simulated function OnInit()
{
	super.OnInit();	
	PopulateData();
}
simulated function UIListItemString SetText2D(string NewText)
{
	Text = NewText;
	SetHtmlText(class'UIUtilities_Text'.static.AddFontInfo(Text, false));
	return self;
}
// Set bDisabled variable
simulated function RealizeDisabledState()
{
	local bool bIsDisabled;
	local DP_UISimpleCommodityScreen CommScreen;
	local int CommodityIndex;

	if(ClassIsChildOf(Screen.Class, class'DP_UISimpleCommodityScreen'))
	{
		CommScreen = DP_UISimpleCommodityScreen(Screen);
		CommodityIndex = CommScreen.GetItemIndex(ItemIntel);
		bIsDisabled = !CommScreen.MeetsItemReqs(CommodityIndex) || CommScreen.IsItemPurchased(CommodityIndex);
	}

	SetDisabled(bIsDisabled);
}

simulated function RealizeGoodState()
{
	local DP_UISimpleCommodityScreen CommScreen;
	local int CommodityIndex;

	if( ClassIsChildOf(Screen.Class, class'DP_UISimpleCommodityScreen') )
	{
		CommScreen = DP_UISimpleCommodityScreen(Screen);
		CommodityIndex = CommScreen.GetItemIndex(ItemIntel);
		ShouldShowGoodState(CommScreen.ShouldShowGoodState(CommodityIndex));
	}
}

// Set bBad variable
simulated function RealizeBadState()
{
	local bool bBad;
	local DP_UISimpleCommodityScreen CommScreen;
	local int CommodityIndex;

	switch( Screen.Class )
	{
	case class'UIInventory_BuildItems':
		bBad = !UIInventory_BuildItems(Screen).CanBuildItem(ItemTemplate);
		break;
	case class'UIInventory_Implants':
		bBad = !UIInventory_Implants(Screen).CanEquipImplant(ItemRef);
		break;
	}

	if( ClassIsChildOf(Screen.Class, class'DP_UISimpleCommodityScreen') )
	{
		CommScreen = DP_UISimpleCommodityScreen(Screen);
		CommodityIndex = CommScreen.GetItemIndex(ItemIntel);
		bBad = !CommScreen.CanAffordItem(CommodityIndex);
	}

	SetBad(bBad);
}

simulated function RealizeAttentionState()
{
	local DP_UISimpleCommodityScreen CommScreen;
	local int CommodityIndex;

	if( ClassIsChildOf(Screen.Class, class'DP_UISimpleCommodityScreen') )
	{
		CommScreen = DP_UISimpleCommodityScreen(Screen);
		CommodityIndex = CommScreen.GetItemIndex(ItemIntel);
		NeedsAttention( CommScreen.NeedsAttention(CommodityIndex), UseObjectiveIcon() );
	}
}

simulated function bool UseObjectiveIcon()
{
	if( ClassIsChildOf(Screen.Class, class'UIChooseResearch') )
		return true;

	return false;
}

simulated function NeedsAttention( bool bNeedsAttention , optional bool bIsObjective = false )
{
	super.NeedsAttention(bNeedsAttention, bIsObjective);
	if( AttentionIcon != none )
		AttentionIcon.SetPosition(4,4);
}

simulated function UIListItemString SetBad(bool isBad, optional string TooltipText)
{
	ButtonBG.SetBad(bIsBad, TooltipText);
	super.SetBad(isBad, TooltipText);
	return self;
}

simulated function UpdateQuantity(int NewQuantity)
{
	Quantity = NewQuantity;
}

simulated function PopulateData(optional bool bRealizeDisabled)
{
	local string ItemQuantity; 
	local X2HackRewardTemplateManager HackRewardTemplateManager;
	local X2HackRewardTemplate OptionTemplate;

	HackRewardTemplateManager = class'X2HackRewardTemplateManager'.static.GetHackRewardTemplateManager();
	
	if(Quantity > 0)
		ItemQuantity = GetColoredText(string(Quantity));
	else
		ItemQuantity = GetColoredText("-");

	MC.BeginFunctionOp("populateData");
	if(Screen.Class == class'UIInventory_BuildItems' && ItemTemplate.bPriority)
	{
		MC.QueueString(GetColoredText(ItemTemplate.GetItemFriendlyName(ItemRef.ObjectID) $ class'UIUtilities_Text'.default.m_strPriority));
	}
	else if( Screen.Class == class'UIInventory_XComDatabase' )
	{
		MC.QueueString(XComDatabaseEntry.GetListTitle());
		ItemQuantity = "";
	}
	else if(!ClassIsChildOf(Screen.Class, class'DP_UISimpleCommodityScreen'))
	{
		MC.QueueString(GetColoredText(ItemTemplate.GetItemFriendlyName(ItemRef.ObjectID)));
	}
	else // Only change here- if you are a child of a DP_UISimpleCommodityScreen screen (like the buy screen) populate the list item correctly
	{
		OptionTemplate = HackRewardTemplateManager.FindHackRewardTemplate(ItemIntel.IntelRewardName);
		if(OptionTemplate!=none)
			MC.QueueString(GetColoredText(OptionTemplate.GetFriendlyName())); //Print the name on the list item.
		else
			MC.QueueString(GetColoredText(""));
		ItemQuantity = GetColoredText("");
	}

	MC.QueueString(ItemQuantity);
	MC.EndOp();

	//---------------

	if(bRealizeDisabled)
		RealizeDisabledState();

	RealizeBadState();

	//Button.SetDisabled(bIsDisabled);
	//ConfirmButton.SetDisabled(bIsDisabled);
}
simulated function string GetIntelFriendlyName()
{
	local X2HackRewardTemplateManager HackRewardTemplateManager;
	local X2HackRewardTemplate OptionTemplate;

	HackRewardTemplateManager = class'X2HackRewardTemplateManager'.static.GetHackRewardTemplateManager();
	OptionTemplate = HackRewardTemplateManager.FindHackRewardTemplate(ItemIntel.IntelRewardName);
	return OptionTemplate.GetFriendlyName();
}
simulated function X2HackRewardTemplate GetIntelTemplate()
{
	local X2HackRewardTemplateManager HackRewardTemplateManager;
	local X2HackRewardTemplate OptionTemplate;

	HackRewardTemplateManager = class'X2HackRewardTemplateManager'.static.GetHackRewardTemplateManager();
	OptionTemplate = HackRewardTemplateManager.FindHackRewardTemplate(ItemIntel.IntelRewardName);
	return OptionTemplate;
}
simulated function string GetColoredText(string Txt, optional int FontSize = 24)
{
	local int uiState;
	
	uiState = eUIState_Normal;

	/*if (bDisabled)
	{
		if (ClassIsChildOf(Screen.Class, class'DP_UISimpleCommodityScreen'))
			uiState = eUIState_Bad;
		else if (Screen.Class == class'UIInventory_Implants')
			uiState = eUIState_Disabled;
	}
	else */if(Screen.Class == class'UIInventory_BuildItems' && ItemTemplate.bPriority)
		uiState = eUIState_Warning;

	if( uiState == eUIState_Normal )
		return class'UIUtilities_Text'.static.GetSizedText(Txt, FontSize);
	else
		return class'UIUtilities_Text'.static.GetColoredText(Txt, uiState, FontSize);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	switch(cmd)
	{
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		OnClickedConfirmButton(ConfirmButton);
		return true;
	}

	return super.OnUnrealCommand(cmd, arg);
}

simulated function OnDoubleclickConfirmButton(UIButton Button)
{
	// do nothing
}
simulated function OnClickConfirmButton(UIButton Button) //When clicked call the purchasing option on the IntelMarket_buy screen. (the first one in the stack will always be the one containing this item)
{
	DP_UIIntelMarket_Buy(`ScreenStack.GetFirstInstanceOf(class'DP_UIIntelMarket_Buy')).OnPurchasedAnIOPS(ItemIntel);
}

defaultproperties
{
	width = 700;
	LibID = "InventoryItem";
	bDisabled = false;
	bCascadeFocus = false;
	ConfirmButtonStyle = eUIConfirmButtonStyle_Default;
}
