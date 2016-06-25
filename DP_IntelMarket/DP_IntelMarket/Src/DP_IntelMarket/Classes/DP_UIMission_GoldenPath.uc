
class DP_UIMission_GoldenPath extends UIMission_GoldenPath;

simulated public function OnLaunchClicked(UIButton button)
{
	local DP_UIIntelMarket kScreen;
	//isuper.OnLaunchClicked(button);
	kScreen = Screen.Spawn(class'DP_UIIntelMarket', Self); //Pushing the Intel market screen instead of the regular squad select screen
	`ScreenStack.Push(kScreen);
    `log("-------------DOING MY MISSION SCREEN-----------------",true,'Team Dragonpunk Intel Market');

}
simulated public function ExposeOLC(UIButton Button) // Exposing the old OnLaunchClicked function from UIMission class for moving the player to squad select
{
    super.OnLaunchClicked(Button);
}