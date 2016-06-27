// This is an Unreal Script
class UIListener_UIMission_Swapper extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	//local UIMission MissionScreen;
	local UIButton ModifiedConfirmButton;
	local float x,y,w,h;
	local string text;
	local bool SetBad,OnConfirm;
	if(Screen.isA('UIMission'))
	{
		if(!UIMission(Screen).ConfirmButton.bIsVisible)
		{
			x=UIMission(Screen).Button1.X;
			y=UIMission(Screen).Button1.y;
			w=UIMission(Screen).Button1.Width;
			h=UIMission(Screen).Button1.Height;	
			text=UIMission(Screen).m_strLaunchMission;	
			SetBad=UIMission(Screen).Button1.IsBad;
			UIMission(Screen).Button1.OnClickedDelegate=OnLaunchClicked_Intel;
			OnConfirm=false;
		}
		else
		{
			x=UIMission(Screen).ConfirmButton.X;
			y=UIMission(Screen).ConfirmButton.y;
			w=UIMission(Screen).ConfirmButton.Width;
			h=UIMission(Screen).ConfirmButton.Height;	
			text=UIMission(Screen).m_strLaunchMission;	
			SetBad=UIMission(Screen).ConfirmButton.IsBad;
			UIMission(Screen).ConfirmButton.OnClickedDelegate=OnLaunchClicked_Intel;
			OnConfirm=true;
		}
		/*
		 `log("Screen class:"$string(Screen.class.name)@"x:"$x@",y:"$y@",w:"$w@",h:"$h@",text:"$text@",SetBad:"$SetBad,true,'Team Dragonpunk Intel Market');
		if(OnConfirm)
		{
			text=class'UIUtilities_Text'.default.m_strGenericConfirm;
			y=205;
			x=5;
			UIMission(Screen).ConfirmButton.Hide();
		}
		ModifiedConfirmButton=Screen.Spawn(class'UIButton',UIMission(Screen).buttonGroup);
		ModifiedConfirmButton.SetResizeToText(false);
		ModifiedConfirmButton.InitButton('ModifiedConfirmButton',text, OnLaunchClicked_Intel);
		ModifiedConfirmButton.SetResizeToText(false);
		ModifiedConfirmButton.SetTextAlign("Center");
		ModifiedConfirmButton.SetBad(SetBad);
		ModifiedConfirmButton.SetPosition(-150+x,y+1);
		ModifiedConfirmButton.SetSize(300,h);
		x=ModifiedConfirmButton.X;
		y=ModifiedConfirmButton.y;
		w=ModifiedConfirmButton.Width;
		h=ModifiedConfirmButton.Height;	
		`log("Screen class:"$string(Screen.class.name)@"x:"$x@",y:"$y@",w:"$w@",h:"$h@",text:"$text@",SetBad:"$SetBad,true,'Team Dragonpunk Intel Market');
		*/
	}
}

event OnReceiveFocus(UIScreen Screen)
{
	OnInit(Screen);
}

simulated public function OnLaunchClicked_Intel(UIButton button)
{
	local DP_UIIntelMarket kScreen;
	kScreen = `SCREENSTACK.GetFirstInstanceOf(Class'UIMission').Spawn(class'DP_UIIntelMarket', `SCREENSTACK.GetFirstInstanceOf(Class'UIMission') ); //Pushing the Intel market screen instead of the regular squad select screen
	`ScreenStack.Push(kScreen);
    `log("-------------DOING MY MISSION SCREEN NO OVERRIDE-----------------",true,'Team Dragonpunk Intel Market');

	/*[Engine.Engine]
	+ModClassOverrides=(BaseGameClass="UIMission_AlienFacility", ModClass="DP_IntelMarket.DP_UIMission_AlienFacility")
	+ModClassOverrides=(BaseGameClass="UIMission_Council", ModClass="DP_IntelMarket.DP_UIMission_Council")
	+ModClassOverrides=(BaseGameClass="UIMission_GoldenPath", ModClass="DP_IntelMarket.DP_UIMission_GoldenPath")
	+ModClassOverrides=(BaseGameClass="UIMission_GOps", ModClass="DP_IntelMarket.DP_UIMission_GOps")
	+ModClassOverrides=(BaseGameClass="UIMission_GPIntelOptions", ModClass="DP_IntelMarket.DP_UIMission_GPIntelOptions")
	+ModClassOverrides=(BaseGameClass="UIMission_LandedUFO", ModClass="DP_IntelMarket.DP_UIMission_LandedUFO")
	+ModClassOverrides=(BaseGameClass="UIMission_Retaliation", ModClass="DP_IntelMarket.DP_UIMission_Retaliation")
	+ModClassOverrides=(BaseGameClass="UIMission_SupplyRaid", ModClass="DP_IntelMarket.DP_UIMission_SupplyRaid")*/

	
}


defaultproperties
{
	// Leaving this assigned to none will cause every screen to trigger its signals on this class
	ScreenClass = none;
}