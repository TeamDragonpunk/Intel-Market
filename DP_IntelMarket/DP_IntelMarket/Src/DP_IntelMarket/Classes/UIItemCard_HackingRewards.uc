// This is an Unreal Script
                           
class UIItemCard_HackingRewards extends UIItemCard;
`include(DP_IntelMarket/Src/ModConfigMenuAPI/MCM_API_CfgHelpers.uci)


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
	MC.QueueString(ItemTemplate.RewardImagePath);
	MC.EndOp();
}
simulated function SetIntelItemCost(optional X2HackRewardTemplate ItemTemplate, optional StateObjectReference ItemRef,optional MissionIntelOption IntelOption)
{
	local string StrCost;
	local int Cost;
	Cost=Round(class'UIUtilities_Strategy'.static.GetCostQuantity(IntelOption.Cost, 'Intel')*GetIntelCostMultiplier()*GetRampingIntelCosts()); //Get the cost of the intel item.
	StrCost= string((Cost));
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
	MC.QueueString(""); //Prints the placeholder image
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
	MC.QueueString("");
	MC.EndOp();
	MC.BeginFunctionOp("PopulateCostData");
	MC.QueueString("");	//Should print "Cost" donst need to if null
	MC.QueueString(""); //Should print the cost, empty for null
	MC.QueueString(""); //Should print "requirements", leave empty for this
	MC.QueueString(""); //Should print the actual requirements, leave empty for this
	MC.EndOp();
}

`MCM_CH_VersionChecker(class'DP_IntelOptions_Defaults'.default.VERSION,class'UIListener_MCM_Options'.default.CONFIG_VERSION)

function bool GetIsRampingIntelCosts() 
{
	local XComGameState_CampaignSettings CampaignSettingsStateObject;
	local XComGameState_DPIO_Options DPIO_StateObject;

	CampaignSettingsStateObject=XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
    if(CampaignSettingsStateObject!=none)
	{
		DPIO_StateObject=XComGameState_DPIO_Options(CampaignSettingsStateObject.FindComponentObject(class'XComGameState_DPIO_Options', false));
		if(DPIO_StateObject != none)
		{
			return DPIO_StateObject.RampingIntelCosts;
		}
	}	
	return `MCM_CH_GetValue(class'DP_IntelOptions_Defaults'.default.Default_RampingIntelCosts ,class'UIListener_MCM_Options'.default.RampingIntelCosts);
}
function float GetRampingIntelCosts(Optional bool PrintLog=false)  
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
		`log("Total Multiplier:"@(GetIntelCostMultiplier()*(1+Ramplevel))@"Base Cost Multiplier:"@GetIntelCostMultiplier() @"Final Ramp Level:"@1+RampLevel @"Force"@Force @"Force-StartingForce"@Force-StartingForce @"StartingForce"@StartingForce @"MaxForce"@MaxForce @"Ramping:"@GetIsRampingIntelCosts(),true,'Team Dragonpunk Intel Options');
	
	return 1.0f+RampLevel;

}
function float GetIntelCostMultiplier() 
{
	local XComGameState_CampaignSettings CampaignSettingsStateObject;
	local XComGameState_DPIO_Options DPIO_StateObject;

	CampaignSettingsStateObject=XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
    if(CampaignSettingsStateObject!=none)
	{
		DPIO_StateObject=XComGameState_DPIO_Options(CampaignSettingsStateObject.FindComponentObject(class'XComGameState_DPIO_Options', false));
		if(DPIO_StateObject != none)
		{
			return DPIO_StateObject.IntelCostMultiplier;
		}
	}	
	return `MCM_CH_GetValue(class'DP_IntelOptions_Defaults'.default.Default_IntelCostMultiplier,class'UIListener_MCM_Options'.default.IntelCostMultiplier);
}