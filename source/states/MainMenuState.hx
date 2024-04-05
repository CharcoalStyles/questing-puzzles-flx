package states;

import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import utils.GlobalState;

class MainMenuState extends FlxState
{
	override public function create()
	{
		super.create();
		var globalState = new GlobalState();
		FlxG.plugins.addPlugin(globalState);

		var text = new FlxText(0, 0, FlxG.width, "Questing Puzzles");
		text.size = 64;
		text.alignment = "center";
		add(text);

		text = new FlxText(0, FlxG.height - 96, FlxG.width, "Press SPACE to start");
		text.size = 32;
		text.alignment = "center";
		add(text);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.anyJustPressed([SPACE]))
		{
			FlxG.switchState(new PlayState());
		}
	}
}
