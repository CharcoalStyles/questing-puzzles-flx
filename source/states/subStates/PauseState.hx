package states.subStates;

import csHxUtils.entities.CsMenu;
import flixel.FlxG;
import flixel.FlxSubState;
import flixel.text.FlxText;
import utils.GlobalState;

class PauseState extends FlxSubState
{
	var controllerId:Int;

	public function new(cId:Int)
	{
		super(0xff101010);
		controllerId = cId;
	}

	public override function create():Void
	{
		super.create();

		var menu = new CsMenu(FlxG.width / 2, FlxG.height / 4, FlxTextAlign.CENTER, {
			keyboard: true,
			mouse: true,
			gamepad: true,
			gamepadId: controllerId
		});
		var mainPage = menu.createPage("Main");
		mainPage.addLabel("PAUSED");
		mainPage.addLabel(" ");
		mainPage.addItem("Toggle Fullscreen", () -> FlxG.fullscreen = !FlxG.fullscreen);
		mainPage.addItem("Quit", () ->
		{
			var globalState = FlxG.plugins.get(GlobalState);
			globalState.player.clearObservers();
			FlxG.switchState(new MainMenuState());
		});
		mainPage.addLabel(" ");
		mainPage.addItem("Back", () -> this.closeCallback());

		mainPage.show(true);

		add(menu);
	}
}
