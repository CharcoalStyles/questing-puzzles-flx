package states.subStates;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.text.FlxText;
import utils.CsMenu;
import utils.GlobalState;

class PauseState extends FlxSubState
{
	public function new()
	{
		super(0xff101010);
	}

	public override function create():Void
	{
		super.create();

		var menu = new CsMenu(FlxG.width / 2, FlxG.height / 4, FlxTextAlign.CENTER);
		var mainPage = menu.createPage("Main");
		mainPage.addLabel("PAUSED");
		mainPage.addLabel(" ");
		mainPage.addItem("Toggle Fullscreen", () -> FlxG.fullscreen = !FlxG.fullscreen);
		mainPage.addItem("Quit", () ->
		{
			var globalState = FlxG.plugins.get(GlobalState);
			globalState.player.clearObservers();
			globalState.ai.clearObservers();
			FlxG.switchState(new MainMenuState());
		});
		mainPage.addLabel(" ");
		mainPage.addItem("Back", () -> this.closeCallback());

		mainPage.show(true);

		add(menu);
	}
}
