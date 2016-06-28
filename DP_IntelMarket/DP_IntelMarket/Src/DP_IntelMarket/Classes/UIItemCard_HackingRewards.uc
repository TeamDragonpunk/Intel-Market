// This is an Unreal Script
                           
class UIItemCard_HackingRewards extends UIItemCard;


simulated function PopulateIntelItemCard(optional X2HackRewardTemplate ItemTemplate, optional StateObjectReference ItemRef,optional MissionIntelOption IntelOption) //Populating the card with the right into, mostly copy pasted from parent.
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
	PopulateData(strTitle,"", strDesc, ""); //populate the title(name) and description of the intel option, a function in the parent class.

	SetIntelItemImages(ItemTemplate, ItemRef); //Set the image
	SetIntelItemCost(ItemTemplate, ItemRef,IntelOption); //Set the cost
}

simulated function SetIntelItemImages(optional X2HackRewardTemplate ItemTemplate, optional StateObjectReference ItemRef)
{
	MC.BeginFunctionOp("SetImageStack");
	if(ItemTemplate.RewardImagePath!="") //if we have an image on the template get the path to it, if not put a placeholder.
		MC.QueueString(ItemTemplate.RewardImagePath);
	else
		MC.QueueString("img:///DP_PlaceholderPOI.POI_GoblinBazaar");
	MC.EndOp();
}
simulated function SetIntelItemCost(optional X2HackRewardTemplate ItemTemplate, optional StateObjectReference ItemRef,optional MissionIntelOption IntelOption)
{
	local string StrCost;
	local float Cost;
	Cost=Round(class'UIUtilities_Strategy'.static.GetCostQuantity(IntelOption.Cost, 'Intel')*class'DP_UIIntelMarket_Buy'.static.GetIntelCostMultiplier()*class'DP_UIIntelMarket_Buy'.static.GetRampingIntelCosts()); //Get the cost of the intel item.
	StrCost= string(int(Cost));
	MC.BeginFunctionOp("PopulateCostData");
	MC.QueueString(m_strCostLabel); //Prints "Cost"
	MC.QueueString(StrCost); //Prints the actual cost
	MC.QueueString("");	//Should print "requirements", leave empty for this
	MC.QueueString(""); //Should print the actual requirements, leave empty for this
	MC.EndOp();
}

simulated function SetInitialParameters() //Easy Setting of initial parameters,should called when first creating the card.
{
	PopulateData("Welcome","", "", ""); //Prints a "Welcome" title on the card.
	MC.BeginFunctionOp("SetImageStack");
	MC.QueueString("img:///DP_PlaceholderPOI.POI_GoblinBazaar"); //Prints the placeholder image
	MC.EndOp();
	MC.BeginFunctionOp("PopulateCostData");
	MC.QueueString(""); //Should print "Cost"  isn't needed here
	MC.QueueString("The Goblins Welcome You To Their Bazzar"); //Should print the cost, prints that string here
	MC.QueueString(""); //Should print "requirements", leave empty for this
	MC.QueueString(""); //Should print the actual requirements, leave empty for this
	MC.EndOp();

}

simulated function SetNullParameters() //Easy setting of parameters for null items.
{
	PopulateData("","", "", "");
	MC.BeginFunctionOp("SetImageStack");
	MC.QueueString("img:///DP_PlaceholderPOI.POI_GoblinBazaar");
	MC.EndOp();
	MC.BeginFunctionOp("PopulateCostData");
	MC.QueueString("");	//Should print "Cost" donst need to if null
	MC.QueueString(""); //Should print the cost, empty for null
	MC.QueueString(""); //Should print "requirements", leave empty for this
	MC.QueueString(""); //Should print the actual requirements, leave empty for this
	MC.EndOp();
}