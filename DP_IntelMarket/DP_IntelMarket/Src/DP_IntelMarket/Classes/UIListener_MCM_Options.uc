// This is an Unreal Script
class UIListener_MCM_Options extends UIScreenListener config(DP_IntelOptions_Settings_MCM);

`include(DP_IntelMarket/Src/ModConfigMenuAPI/MCM_API_Includes.uci)
`include(DP_IntelMarket/Src/ModConfigMenuAPI/MCM_API_CfgHelpers.uci)

var config bool RampingIntelCosts;
var config float IntelCostMultiplier;
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
		Page = ConfigAPI.NewSettingsPage("Goblin Bazzar");
		Page.SetPageTitle("Team Dragonpunk Goblin Bazzar");
		Page.SetSaveHandler(SaveButtonClicked);

		Group = Page.AddGroup('Group1', "General Settings");

		Group.AddCheckbox('RampingIntelCosts_CB', "Enable Dynamic Intel Costs", "The cost of intel options will ramp up during your campaign", RampingIntelCosts, CheckboxSaveHandler);
		Group.AddSpinner('IntelCostSpinner_SD', "Intel Cost Multiplier", "A Static cost multiplier to your intel options",IntelRange,TempString, SpinnerSaveHandler);

		Page.ShowSettings();
	}
}

`MCM_CH_VersionChecker(class'DP_IntelOptions_Defaults'.default.VERSION,CONFIG_VERSION)

simulated function SpinnerSaveHandler (MCM_API_Setting _Setting, string _SettingValue)
{
	IntelCostMultiplier=float(_SettingValue);
}

simulated function CheckboxSaveHandler (MCM_API_Setting _Setting, bool _SettingValue)
{
	
	RampingIntelCosts=_SettingValue;
	
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
			RampingIntelCosts=DPIO_StateObject.RampingIntelCosts;
			IntelCostMultiplier=DPIO_StateObject.IntelCostMultiplier;
		}
		else
		{
			NewGameState=class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Adding Options Component");
			DPIO_StateObject = XComGameState_DPIO_Options(NewGameState.CreateStateObject(class'XComGameState_DPIO_Options'));
			
			DPIO_StateObject.RampingIntelCosts=class'DP_IntelOptions_Defaults'.default.Default_RampingIntelCosts;
			DPIO_StateObject.IntelCostMultiplier=class'DP_IntelOptions_Defaults'.default.Default_IntelCostMultiplier;
		
			CampaignSettingsStateObject.AddComponentObject(DPIO_StateObject);
			NewGameState.AddStateObject(DPIO_StateObject);
			//NewGameState.AddStateObject(CampaignSettingsStateObject);
			
			RampingIntelCosts = class'DP_IntelOptions_Defaults'.default.Default_RampingIntelCosts;
			IntelCostMultiplier = class'DP_IntelOptions_Defaults'.default.Default_IntelCostMultiplier;
			
			`XCOMHISTORY.AddGameStateToHistory(NewGameState);
		}
	}
	else
	{
		RampingIntelCosts = class'DP_IntelOptions_Defaults'.default.Default_RampingIntelCosts;
		IntelCostMultiplier = class'DP_IntelOptions_Defaults'.default.Default_IntelCostMultiplier;
	}
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
			if(DPIO_StateObject.RampingIntelCosts!=RampingIntelCosts ||DPIO_StateObject.IntelCostMultiplier!=IntelCostMultiplier)
			{
				DPIO_StateObject.RampingIntelCosts=RampingIntelCosts;
				DPIO_StateObject.IntelCostMultiplier=IntelCostMultiplier;
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

			CampaignSettingsStateObject.AddComponentObject(DPIO_StateObject);
			NewGameState.AddStateObject(DPIO_StateObject);
			//NewGameState.AddStateObject(CampaignSettingsStateObject);
						
			`XCOMHISTORY.AddGameStateToHistory(NewGameState);
		}
	}
    self.CONFIG_VERSION = `MCM_CH_GetCompositeVersion();
    self.SaveConfig();
}

defaultproperties
{
    ScreenClass = none;
}