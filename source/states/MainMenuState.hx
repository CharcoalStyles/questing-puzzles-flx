package states;

import entities.effects.CsEmitter;
import flixel.FlxG;
import flixel.FlxState;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import states.subStates.SelectEnemy;
import utils.GlobalState;
import utils.SplitText;

class MainMenuState extends FlxState
{
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
		var startText = generateText("New Battle", FlxColor.GREEN, (t) ->
		{
			setPickEnemySubState();
		});

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

	function setPickEnemySubState()
	{
		this.subState = new SelectEnemy();
		this.subState.create();
		this.subState.closeCallback = () ->
		{
			this.subState = null;
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.anyJustPressed([SPACE]))
		{
			setPickEnemySubState();
		}
	}
}
