
class DP_UIIntelMarket extends UIScreen;

var public localized String m_strBuy;
var public localized String m_strSell;
var public localized String m_strImage;

var UIPanel LibraryPanel;
var UIButton Button1, Button2, Button3;
var UIImage ImageTarget;

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local XComGameState NewGameState;

	super.InitScreen(InitController, InitMovie, InitName);
	BuildScreen();
	self.SetAlpha(1);
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: On Black Market Open");
	`XEVENTMGR.TriggerEvent('OnBlackMarketOpen', , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

simulated function BuildScreen()
{
	local UIPanel ButtonGroup;

	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Black_Market_Enter");

	LibraryPanel = Spawn(class'UIPanel', self);
	LibraryPanel.bAnimateOnInit = false;
	LibraryPanel.InitPanel('', 'BlackMarketMenu');
		
	ButtonGroup = Spawn(class'UIPanel', LibraryPanel);
	ButtonGroup.InitPanel('ButtonGroup', '');

	Button1 = Spawn(class'UIButton', ButtonGroup);
	Button1.SetResizeToText(false);
	Button1.InitButton('Button0', "BUY");

	Button2 = Spawn(class'UIButton', ButtonGroup);
	Button2.SetResizeToText(false);
	Button2.InitButton('Button1', "LEAVE");
	
	Button3 = Spawn(class'UIButton', ButtonGroup);
	Button3.SetResizeToText(false);
	Button3.InitButton('Button2', "");

	ImageTarget = Spawn(class'UIImage', LibraryPanel).InitImage('MarketMenuImage');
	`log("m_strImage:"@m_strImage,true,'Team Dragonpunk POI Art');
	ImageTarget.LoadImage("img:///DP_PlaceholderPOI.POI_GoblinBazaar");

	//-----------------------------------------------

	LibraryPanel.MC.FunctionString("SetMenuQuote", "The Goblins Welcome You To Their Bazzar!");

	LibraryPanel.MC.BeginFunctionOp("SetMenuInterest");
	LibraryPanel.MC.QueueString(class'UIUtilities_Text'.static.AlignLeft("Guide"));
	LibraryPanel.MC.QueueString(class'UIUtilities_Text'.static.AlignLeft("Purchased Options will last for 1 mission only"));
	LibraryPanel.MC.EndOp();

	Button1.OnClickedDelegate = OnBuyClicked;
	Button2.OnClickedDelegate = OnSellClicked;
	Button3.Hide();

	LibraryPanel.MC.BeginFunctionOp("SetGreeble");
	LibraryPanel.MC.QueueString("Put Something Cool Here");
	LibraryPanel.MC.QueueString(class'UIAlert'.default.m_strBlackMarketFooterRight);
    LibraryPanel.MC.QueueString("GOBLIN BAZAAR");
	LibraryPanel.MC.EndOp();

	LibraryPanel.MC.FunctionVoid("AnimateIn");

	XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.NavHelp.ClearButtonHelp();
	XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.NavHelp.AddBackButton(CloseScreen);
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	
	XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.NavHelp.ClearButtonHelp();
	XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.NavHelp.AddBackButton(CloseScreen);
}


//-------------- EVENT HANDLING --------------------------------------------------------
simulated function OnBuyClicked(UIButton button)
{
	DP_UIIntelMarketBuy();

}
// If you change this title, then you'll need to create a new button delegate
simulated function OnSellClicked(UIButton button)
{
    CloseScreen();
}

//-------------- GAME DATA HOOKUP --------------------------------------------------------
simulated function DP_UIIntelMarketBuy(){	local DP_UIIntelMarket_Buy kScreen;	kScreen = Spawn(class'DP_UIIntelMarket_Buy', self);	`SCREENSTACK.Push(kScreen);	kScreen.SelectedIntelOptions.length=0;	`log("-------------DOING THE BUY SCREEN-----------------",true,'Team Dragonpunk Intel Market');}

simulated function ExposeOLC(UIButton Button) // Triggerring the ExposeOLC functions on the correct UIMission screen that created this screen
{
	local UIScreen MissionScreen;
	MissionScreen=`ScreenStack.GetFirstInstanceOf(class'UIMission');
	UIMission(MissionScreen).OnLaunchClicked(button);
	/*Switch(MissionScreen.class)
	{
		case Class'UIMission_AlienFacility':
			UIMission_AlienFacility(MissionScreen).ExposeOLC(Button);
			break;
		case Class' UIMission_Council':
			 UIMission_Council(MissionScreen).ExposeOLC(Button);
			break;
		case Class' UIMission_GoldenPath':
			 UIMission_GoldenPath(MissionScreen).ExposeOLC(Button);
			break;
		case Class' UIMission_GOps':
			 UIMission_GOps(MissionScreen).ExposeOLC(Button);
			break;
		case Class' UIMission_GPIntelOptions':
			 UIMission_GPIntelOptions(MissionScreen).ExposeOLC(Button);
			break;
		case Class' UIMission_LandedUFO':
			 UIMission_LandedUFO(MissionScreen).ExposeOLC(Button);
			break;
		case Class' UIMission_Retaliation':
			 UIMission_Retaliation(MissionScreen).ExposeOLC(Button);
			break;
		case Class' UIMission_SupplyRaid':
			 UIMission_SupplyRaid(MissionScreen).ExposeOLC(Button);
			break;
		default:
			break;

	}	*/
}

simulated function CloseScreen()
{
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Black_Market_Ambience_Loop_Stop");
	super.CloseScreen();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	// Only pay attention to presses or repeats; ignoring other input types
	// NOTE: Ensure repeats only occur with arrow keys
	if( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	bHandled = true;
	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_B:
	case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
	case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
		CloseScreen();
		break;
	case class'UIUtilities_Input'.const.FXS_BUTTON_START:
		`HQPRES.UIPauseMenu(, true);
		break;
	default:
		bHandled = false;
		break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}


//==============================================================================

defaultproperties
{
	InputState = eInputState_Consume;
	Package = "/ package/gfxBlackMarket/BlackMarket";
	bConsumeMouseEvents = true;
}