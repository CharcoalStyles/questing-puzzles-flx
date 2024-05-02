package states;

import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import utils.GlobalState;
import utils.SplitText;

class MainMenuState extends FlxState
{
	var startText:SplitText;

	var rgb:Array<FlxColor> = [0xffd04040, 0xff40d040, 0xff4040d0];
	var currentColour:Int = 0;
	var globalState:GlobalState;

	override public function create()
	{
		super.create();
		globalState = new GlobalState();
		FlxG.plugins.addPlugin(globalState);

		FlxG.mouse.visible = true;

		var text = new FlxText(0, 0, FlxG.width, "Questing Puzzles");
		text.size = 64;
		text.alignment = "center";
		add(text);

		startText = new SplitText(0, FlxG.height - 96, "START");
		startText.color = 0xff000000;
		startText.borderColor = 0xffffffff;
		startText.borderQuality = 4;
		startText.borderSize = 4;
		startText.borderStyle = OUTLINE;
		startText.onMouseIn = () ->
		{
			startText.animate();
			startText.color = 0xffffffff;
		}
		startText.onMouseOut = () ->
		{
			startText.stopAnimation();
			startText.color = 0xff000000;
		}
		startText.onClick = () ->
		{
			FlxG.switchState(new PlayState());
		}

		startText.x = (FlxG.width - startText.width) / 2;

		add(startText);

		globalState.createEmitter();
		add(globalState.emitter.activeMembers);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.anyJustPressed([SPACE]))
		{
			FlxG.switchState(new PlayState());
		}

		if (FlxG.mouse.justPressed)
		{
			var color = FlxG.random.color(0xa0a0a0, 0xe0e0e0);
			globalState.emitter.burstEmit(FlxG.mouse.x, FlxG.mouse.y, 50, color);
		}
	}
}
