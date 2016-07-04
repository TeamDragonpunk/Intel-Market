// This is an Unreal Script
                           
class UITutorialScreen extends UISimpleScreen;

var int PageNumber;
var array<string> TutorialTitleArray;
var array<string> TutorialTextArray;
var array<string> TutorialImageArray;

var UIImage TutorialImage;
var UIText TutorialText;
var array<UIX2PanelHeader> TutorialHeaders;
var UIButton ForwardButton,BackButton;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	Super.InitScreen(InitController,InitMovie,InitName);
	PageNumber=0;
	BuildScreen();
	`HQPRES.m_kAvengerHUD.NavHelp.AddBackButton(CloseScreen);	
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
}
simulated function InitArrays(array<string> TitleA,array<string> TextA,array<string> ImageA)
{
	TutorialTitleArray=TitleA;
	TutorialTextArray=TextA;
	TutorialImageArray=ImageA;	
}
simulated function BuildScreen(optional array<string> TitleA,optional array<string> TextA,optional array<string> ImageA)
{
	local TRect rText,rTitle,rImage;	
	local LinearColor clrControl;
	local int i;
	if(TitleA.Length!=0 && TextA.Length==TitleA.Length &&TitleA.Length==ImageA.Length)
		InitArrays(TitleA,TextA,ImageA);

	TutorialHeaders.Length=0;
	AddFullscreenBG(0.75);
	//AnchorCenter();
	clrControl = MakeLinearColor(0.9, 0.9, 0.2, 0.75);
	rTitle =MakeRect(462, 150, 900,50);
	rImage =MakeRect(455, 150, 910,650);
	rText = MakeRect(462, 650, 900,75);
	//MainBGBox.OriginCenter();
	//MainBGBox.AnchorCenter();
	TutorialImage=AddImage(rImage,TutorialImageArray[0],eUIState_Good,,self);
	TutorialImage.SetSize(900,450);
	TutorialImage.SetPosition(462,200);
	for(i=0;i<TutorialTitleArray.Length;i++)
	{
		TutorialHeaders.AddItem(AddHeader(rTitle,TutorialTitleArray[i],clrControl,,,self));
		if(i!=0)
			TutorialHeaders[i].hide();
	}
	TutorialText=AddUncenteredText(rText,TutorialTextArray[0],,self);
	ForwardButton.SetResizeToText(False);
	BackButton.SetResizeToText(False);
	ForwardButton=AddButton(MakeRect(1140,770,100,35),class'UIUtilities_Text'.static.AlignCenter(m_strContinue),OnForwardClicked,'ForwardButton');
	BackButton=AddButton(MakeRect(480,770,100,35),class'UIUtilities_Text'.static.AlignCenter(m_strBack),OnBackClicked,'BackButton');
	UpdateTutorialScreen();
}
simulated public function UpdateTutorialScreen()
{
	TutorialImage.AnimateOut(0.1f);
	TutorialImage.LoadImage(TutorialImageArray[PageNumber]);
	TutorialImage.AnimateIn(0.1f);
	TutorialText.AnimateOut(0.1f);
	TutorialText.SetText(TutorialTextArray[PageNumber]);
	TutorialText.AnimateIn(0.1f);
	
	//ForwardButton.AnimateOut(0.1f);
	//BackButton.AnimateOut(0.1f);
	if(PageNumber==TutorialTitleArray.Length-1)
	{
		ForwardButton.SetText(class'UIUtilities_Text'.static.AlignCenter("Don't Show Again"));
		BackButton.SetText(class'UIUtilities_Text'.static.AlignCenter("Show Again"));
	}
	else
	{
		ForwardButton.SetText(class'UIUtilities_Text'.static.AlignCenter(m_strContinue));
		BackButton.SetText(class'UIUtilities_Text'.static.AlignCenter(m_strBack));
	}
	//ForwardButton.AnimateIn(0.1f);
	//BackButton.AnimateIn(0.1f);
}

simulated public function OnForwardClicked(UIButton Button)
{
	local XComGameState_CampaignSettings CampaignSettingsStateObject;
	local XComGameState_DPIO_Options DPIO_StateObject;
	local XComGameState NewGameState;

	PageNumber++;
	if(PageNumber<TutorialTitleArray.Length)
	{
		TutorialHeaders[PageNumber-1].hide();
		TutorialHeaders[PageNumber-1].AnimateOut(0.1f);
		TutorialHeaders[PageNumber].show();
		TutorialHeaders[PageNumber].AnimateIn(0.1f);
		UpdateTutorialScreen();
		return;
	}
	else if(PageNumber==TutorialTitleArray.Length)
	{
		SaveDSAState(false);
		PageNumber=0;
		CloseScreen();
		return;
	}
}
simulated public function OnBackClicked(UIButton Button)
{
	
	if(PageNumber==TutorialTitleArray.Length-1)
	{
		SaveDSAState(true);
		PageNumber=0;
		CloseScreen();
		return;
	}
	PageNumber--;
	if(PageNumber>=0 &&PageNumber<TutorialTitleArray.Length )
	{
		TutorialHeaders[PageNumber+1].hide();
		TutorialHeaders[PageNumber+1].AnimateOut(0.1f);
		TutorialHeaders[PageNumber].show();
		TutorialHeaders[PageNumber].AnimateIn(0.1f);
		UpdateTutorialScreen();
	}
	else
	{
		CloseScreen();
		PageNumber=0;
	}
}

simulated public function SaveDSAState(bool DSAState)
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
			if(DPIO_StateObject.Counter==0)
				DPIO_StateObject.Counter++;

			if(DSAState!=DPIO_StateObject.ShowTutorial)
			{
				DPIO_StateObject.ShowTutorial=DSAState;
				NewGameState=class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Changing popup");
				NewGameState.AddStateObject(DPIO_StateObject);
				`XCOMHISTORY.AddGameStateToHistory(NewGameState);
			}
		}
	}
}