package states;

import entities.effects.CsEmitter;
import flixel.FlxG;
import flixel.FlxState;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import utils.GlobalState;
import utils.SplitText;

class MainMenuState extends FlxState
{
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
		var startText = generateText("START", FlxColor.GREEN, (t) -> FlxG.switchState(new PlayState()));

		startText.x = (FlxG.width - startText.width) / 2;
		startText.y = FlxG.height / 2 + 96;

		add(startText);

		var fullScreen = generateText("Toggle Fullscreen", FlxColor.ORANGE, (text) ->
		{
			FlxG.fullscreen = !FlxG.fullscreen;
		});

		fullScreen.x = (FlxG.width - fullScreen.width) / 2;
		fullScreen.y = FlxG.height / 2 + 172;

		add(fullScreen);

		globalState.createEmitter();
		add(globalState.emitter.activeMembers);
	}

	function generateText(text:String, targetColour:FlxColor, onClick:(text:SplitText) -> Void)
	{
		var text = new SplitText(0, 0, text);
		text.color = 0xff000000;
		text.borderColor = 0xffffffff;
		text.borderQuality = 4;
		text.borderSize = 4;
		text.borderStyle = OUTLINE;
		text.onMouseIn = () ->
		{
			text.animateWave(36, 0.075, 0.6, true);
			text.animateColour(targetColour, 0.075, 0.6);
		}
		text.onMouseOut = () ->
		{
			text.stopAnimation();
		}
		text.onClick = () ->
		{
			onClick(text);
		};

		return text;
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
			var partScale = FlxPoint.get(0.5, 0.5);
			for (i in 0...50)
			{
				var p = globalState.emitter.emit(FlxG.mouse.x, FlxG.mouse.y);
				var em = CsEmitter.burstEmit(color, null, {
					lifespan: () -> 0.5,
					scaleExtended: () -> [
						{
							t: 0,
							value: partScale
						},
					]
				});
				p.setEffectStates([em]);
			}
		}
	}
}
