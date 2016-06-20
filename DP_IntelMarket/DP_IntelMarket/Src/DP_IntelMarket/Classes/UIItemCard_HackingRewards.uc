// This is an Unreal Script
                           
class UIItemCard_HackingRewards extends UIItemCard;


simulated function PopulateIntelItemCard(optional X2HackRewardTemplate ItemTemplate, optional StateObjectReference ItemRef,optional MissionIntelOption IntelOption)
{
	local string strDesc, strRequirement, strTitle;

	if( ItemTemplate == None )
	{
		Hide();
		return;
	}

	bWaitingForImageUpdate = false;

	strTitle = class'UIUtilities_Text'.static.GetColoredText(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(ItemTemplate.GetFriendlyName()), eUIState_Header, 24);
	strDesc = class'UIUtilities_Text'.static.GetColoredText(ItemTemplate.GetDescription(none), eUIState_Normal, 24);//Description and requirements strings are reversed for item cards, desc appears at the very bottom of the card so not needed here
	strRequirement = class'UIUtilities_Text'.static.GetColoredText(ItemTemplate.GetDescription(none), eUIState_Normal, 24);//Description and requirements strings are reversed for item cards, desc appears at the very bottom of the card so not needed here
	if(	ItemTemplate==none)
	{
		strTitle="Welcome to the Goblin Bazaar";
		strDesc="Welcome to the Goblin Bazaar";
		strRequirement="Welcome to the Goblin Bazaar";
	}
	PopulateData(strTitle,"", strDesc, "");

	SetIntelItemImages(ItemTemplate, ItemRef);
	SetIntelItemCost(ItemTemplate, ItemRef,IntelOption);
}

simulated function SetIntelItemImages(optional X2HackRewardTemplate ItemTemplate, optional StateObjectReference ItemRef)
{
	MC.BeginFunctionOp("SetImageStack");
	MC.QueueString(ItemTemplate.RewardImagePath);
	MC.EndOp();
}
simulated function SetIntelItemCost(optional X2HackRewardTemplate ItemTemplate, optional StateObjectReference ItemRef,optional MissionIntelOption IntelOption)
{
	local string StrCost;
	StrCost= string(class'UIUtilities_Strategy'.static.GetCostQuantity(IntelOption.Cost, 'Intel')); //ItemTemplate.MinIntelCost @"-" @ItemTemplate.MaxIntelCost;
	MC.BeginFunctionOp("PopulateCostData");
	MC.QueueString(m_strCostLabel);
	MC.QueueString(StrCost);
	MC.QueueString("");
	MC.QueueString("");
	MC.EndOp();
}