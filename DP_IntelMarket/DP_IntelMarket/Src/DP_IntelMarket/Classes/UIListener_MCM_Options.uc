// This is an Unreal Script
class UIListener_MCM_Options extends UIScreenListener config(DP_IntelOptions_Settings_MCM);

`include(DP_IntelMarket/Src/ModConfigMenuAPI/MCM_API_Includes.uci)
`include(DP_IntelMarket/Src/ModConfigMenuAPI/MCM_API_CfgHelpers.uci)

var config bool RampingIntelCosts;
var config float IntelCostMultiplier;
var config bool ShowTutorial;
var config int CONFIG_VERSION;

event OnInit(UIScreen Screen)
{
    // Everything out here runs on every UIScreen. Not great but necessary.
    if ( MCM_API(Screen) != none)
    {
        // Everything in here runs only when you need to touch MCM.
        `MCM_API_Register(Screen, ClientModCallback);
    }
	if(Screen.IsA('UIMission'))
		LoadSavedSettings();
}

simulated function ClientModCallback(MCM_API_Instance ConfigAPI, int GameMode)
{
    local MCM_API_SettingsPage Page;
    local MCM_API_SettingsGroup Group;
	local array<string> IntelRange;
	local string TempString;
	local int i,k;
	if (GameMode != eGameMode_MainMenu)
    {
		for(i=1;i<=50;i++)
		{
			TempString= ((i/10)$"."$(i%10));
			IntelRange.AddItem(TempString);
		}
		LoadSavedSettings();
		`log("Loaded Saved Settings:"@IntelCostMultiplier @RampingIntelCosts);
		TempString= ((int(IntelCostMultiplier*10))/10)$"."$((int(IntelCostMultiplier*10)%10));
		Page = ConfigAPI.NewSettingsPage("Goblin bazaar");
		Page.SetPageTitle("Team Dragonpunk Goblin bazaar");
		Page.SetSaveHandler(SaveButtonClicked);

		Group = Page.AddGroup('Group1', "General Settings");

		Group.AddCheckbox('RampingIntelCosts_CB', "Enable Dynamic Intel Costs", "The cost of intel options will ramp up during your campaign", RampingIntelCosts, RampingIntelCostsSaveHandler);
		Group.AddSpinner('IntelCostSpinner_SD', "Intel Cost Multiplier", "A Static cost multiplier to your intel options",IntelRange,TempString, IntelCostMultiplierSaveHandler);
		Group.AddCheckbox('ShowTutorial_CB', "Show Mod Tutorial", "Should the mod show the tutorial when going into the intel buy screen?", ShowTutorial, ShowTutorialSaveHandler);

		Page.ShowSettings();
	}
}

`MCM_CH_VersionChecker(class'DP_IntelOptions_Defaults'.default.VERSION,CONFIG_VERSION)

simulated function IntelCostMultiplierSaveHandler (MCM_API_Setting _Setting, string _SettingValue)
{
	IntelCostMultiplier=float(_SettingValue);
}

simulated function RampingIntelCostsSaveHandler (MCM_API_Setting _Setting, bool _SettingValue)
{
	
	RampingIntelCosts=_SettingValue;
	
}
simulated function ShowTutorialSaveHandler (MCM_API_Setting _Setting, bool _SettingValue)
{
	
	ShowTutorial=_SettingValue;
	
}
simulated function LoadSavedSettings()
{
	local XComGameState_CampaignSettings CampaignSettingsStateObject;
	local XComGameState_DPIO_Options DPIO_StateObject;
	local XComGameState NewGameState;

	CampaignSettingsStateObject=XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
    if(CampaignSettingsStateObject!=none)
	{
		DPIO_StateObject=XComGameState_DPIO_Options(CampaignSettingsStateObject.FindComponentObject(class'XComGameState_DPIO_Options', false));
		if(DPIO_StateObject != none)
		{
			ShowTutorial=DPIO_StateObject.ShowTutorial;
			RampingIntelCosts=DPIO_StateObject.RampingIntelCosts;
			IntelCostMultiplier=DPIO_StateObject.IntelCostMultiplier;
		}
		else
		{
			NewGameState=class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Adding Options Component");
			DPIO_StateObject = XComGameState_DPIO_Options(NewGameState.CreateStateObject(class'XComGameState_DPIO_Options'));
			
			DPIO_StateObject.RampingIntelCosts=`MCM_CH_GetValue(class'DP_IntelOptions_Defaults'.default.Default_RampingIntelCosts,RampingIntelCosts); 
			DPIO_StateObject.IntelCostMultiplier=`MCM_CH_GetValue(class'DP_IntelOptions_Defaults'.default.Default_IntelCostMultiplier,IntelCostMultiplier); 
			DPIO_StateObject.ShowTutorial=`MCM_CH_GetValue(class'DP_IntelOptions_Defaults'.default.Default_ShowTutorial,ShowTutorial); 
			CampaignSettingsStateObject.AddComponentObject(DPIO_StateObject);
			NewGameState.AddStateObject(DPIO_StateObject);
			//NewGameState.AddStateObject(CampaignSettingsStateObject);
			
			RampingIntelCosts = `MCM_CH_GetValue(class'DP_IntelOptions_Defaults'.default.Default_RampingIntelCosts,RampingIntelCosts); 
			IntelCostMultiplier =`MCM_CH_GetValue(class'DP_IntelOptions_Defaults'.default.Default_IntelCostMultiplier,IntelCostMultiplier); 
			ShowTutorial =`MCM_CH_GetValue(class'DP_IntelOptions_Defaults'.default.Default_ShowTutorial,ShowTutorial); 
			
			`XCOMHISTORY.AddGameStateToHistory(NewGameState);
		}
	}
	else
	{
		RampingIntelCosts = `MCM_CH_GetValue(class'DP_IntelOptions_Defaults'.default.Default_RampingIntelCosts,RampingIntelCosts); 
		IntelCostMultiplier =`MCM_CH_GetValue(class'DP_IntelOptions_Defaults'.default.Default_IntelCostMultiplier,IntelCostMultiplier); 
		ShowTutorial =`MCM_CH_GetValue(class'DP_IntelOptions_Defaults'.default.Default_ShowTutorial,ShowTutorial); 
	}
	CampaignSettingsStateObject=XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
	DPIO_StateObject=XComGameState_DPIO_Options(CampaignSettingsStateObject.FindComponentObject(class'XComGameState_DPIO_Options', false));

	`log("Loading:"@DPIO_StateObject.RampingIntelCosts @DPIO_StateObject.IntelCostMultiplier @DPIO_StateObject.ShowTutorial @","@RampingIntelCosts @IntelCostMultiplier @ShowTutorial);

}

simulated function SaveButtonClicked(MCM_API_SettingsPage Page)
{
	local XComGameState_CampaignSettings CampaignSettingsStateObject;
	local XComGameState_DPIO_Options DPIO_StateObject;
	local XComGameState NewGameState;

	CampaignSettingsStateObject=XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
	if(CampaignSettingsStateObject!=none)
	{
		DPIO_StateObject=XComGameState_DPIO_Options(CampaignSettingsStateObject.FindComponentObject(class'XComGameState_DPIO_Options', false));
		if(DPIO_StateObject != none)
		{
			NewGameState=class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Submitting Options Component");
			if(DPIO_StateObject.RampingIntelCosts!=RampingIntelCosts ||DPIO_StateObject.IntelCostMultiplier!=IntelCostMultiplier ||DPIO_StateObject.ShowTutorial!=ShowTutorial)
			{
				DPIO_StateObject.RampingIntelCosts=RampingIntelCosts;
				DPIO_StateObject.IntelCostMultiplier=IntelCostMultiplier;
				DPIO_StateObject.ShowTutorial=ShowTutorial;
				NewGameState.AddStateObject(DPIO_StateObject);
				`XCOMHISTORY.AddGameStateToHistory(NewGameState);
			}
			else
				`XCOMHISTORY.CleanupPendingGameState(NewGameState);
		}
		else
		{
			NewGameState=class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Adding Options Component");
			DPIO_StateObject = XComGameState_DPIO_Options(NewGameState.CreateStateObject(class'XComGameState_DPIO_Options'));
			
			DPIO_StateObject.RampingIntelCosts=RampingIntelCosts;
			DPIO_StateObject.IntelCostMultiplier=IntelCostMultiplier;
			DPIO_StateObject.ShowTutorial=ShowTutorial;

			CampaignSettingsStateObject.AddComponentObject(DPIO_StateObject);
			NewGameState.AddStateObject(DPIO_StateObject);
			//NewGameState.AddStateObject(CampaignSettingsStateObject);
						
			`XCOMHISTORY.AddGameStateToHistory(NewGameState);
		}
	}
    self.CONFIG_VERSION = `MCM_CH_GetCompositeVersion();
    self.SaveConfig();
	CampaignSettingsStateObject=XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
	DPIO_StateObject=XComGameState_DPIO_Options(CampaignSettingsStateObject.FindComponentObject(class'XComGameState_DPIO_Options', false));

	`log("Saving:"@DPIO_StateObject.RampingIntelCosts @DPIO_StateObject.IntelCostMultiplier @DPIO_StateObject.ShowTutorial @","@RampingIntelCosts @IntelCostMultiplier @ShowTutorial);
}

defaultproperties
{
    ScreenClass = none;
}