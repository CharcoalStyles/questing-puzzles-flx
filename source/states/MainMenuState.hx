package states;

import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import utils.GlobalState;

class MainMenuState extends FlxState
{
	var startText:FlxText;

	var rgb:Array<FlxColor> = [0xffd04040, 0xff40d040, 0xff4040d0];
	var currentColour:Int = 0;

	override public function create()
	{
		super.create();
		var globalState = new GlobalState();
		FlxG.plugins.addPlugin(globalState);

		FlxG.mouse.visible = true;

		var text = new FlxText(0, 0, FlxG.width, "Questing Puzzles");
		text.size = 64;
		text.alignment = "center";
		add(text);

		startText = new FlxText(0, FlxG.height - 96, FlxG.width, "START");
		startText.size = 46;
		startText.alignment = "center";
		startText.setBorderStyle(OUTLINE, 0xffffffff, 4, 4);

		add(startText);
		changeColour(0);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.anyJustPressed([SPACE]))
		{
			FlxG.switchState(new PlayState());
		}

		if (FlxG.mouse.x >= startText.x
			&& FlxG.mouse.x <= startText.x + startText.width
			&& FlxG.mouse.y >= startText.y
			&& FlxG.mouse.y <= startText.y + startText.height)
		{
			if (FlxG.mouse.justPressed)
			{
				FlxG.switchState(new PlayState());
			}
			else
			{
				startText.setBorderStyle(OUTLINE, 0xffffffff, 6, 32);
			}
		}
		else
		{
			startText.setBorderStyle(OUTLINE, 0xffffffff, 4, 4);
		}
	}

	public function changeColour(initColourIndex:Int)
	{
		var nc = initColourIndex + 1;
		var nextColor = nc % rgb.length;
		FlxG.log.add("nc: " + nc + " rgb.lemgth: " + rgb.length + " nextColor: " + nextColor);
		FlxTween.color(startText, 1.5, rgb[initColourIndex], rgb[nextColor], {
			type: FlxTweenType.ONESHOT,
			ease: FlxEase.linear,
			onComplete: (tween) ->
			{
				changeColour(nextColor);
			}
		});
	}
}
