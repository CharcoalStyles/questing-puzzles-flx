package states.subStates;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.util.FlxColor;
import utils.GlobalState;
import utils.Loader;
import utils.SplitText;

class SelectEnemy extends FlxSubState
{
	public function new()
	{
		super(0x80000000);
	}

	public override function create():Void
	{
		super.create();

		var globalState = FlxG.plugins.get(GlobalState);

		var characters = Loader.loadCharacters();
		// var names = enemies.map(function(c) return c.name);

		var nameText = characters.map((char) ->
		{
			return generateText(char.name, FlxColor.GRAY, (text) ->
			{
				var c = Loader.loadCharacter(char);
				globalState.ai = c;
				FlxG.switchState(new PlayState());
			});
		});

		nameText.insert(0, generateText("Select Enemy", FlxColor.WHITE, null, false));
		nameText.push(generateText("BACK", FlxColor.WHITE, closeSub));

		var padding = 48;

		var optionsHeight = nameText.length * (nameText[0].height + padding) + (padding);
		var winWidth = Std.int(FlxG.width * 0.66);
		var winHeight = Std.int(optionsHeight);
		add(new FlxSprite(Std.int((FlxG.width - winWidth) / 2), Std.int((FlxG.height - winHeight) / 2),).makeGraphic(winWidth, winHeight, FlxColor.WHITE));

		var innerWindow = new FlxSprite(Std.int((FlxG.width - winWidth) / 2) + 1,
			Std.int((FlxG.height - winHeight) / 2) + 1).makeGraphic(winWidth - 2, winHeight - 2, FlxColor.BLACK);
		add(innerWindow);

		for (i in 0...nameText.length)
		{
			add(nameText[i]);
			nameText[i].x = innerWindow.x + (innerWindow.width - nameText[i].width) / 2;
			nameText[i].y = innerWindow.y + padding + (i * (nameText[i].height + padding));
		}
	}

	private function closeSub(?x:Any):Void
	{
		closeCallback();
	}

	function generateText(text:String, targetColour:FlxColor, onClick:Null<(text:SplitText) -> Void>, hasBorder:Bool = true)
	{
		var text = new SplitText(0, 0, text, {
			size: 32,
			perCharBuffer: 3,
		});
		text.color = hasBorder ? 0xff000000 : targetColour;
		if (hasBorder)
		{
			text.borderColor = 0xffffffff;
			text.borderQuality = 4;
			text.borderSize = 4;
			text.borderStyle = OUTLINE;
		}
		if (onClick != null)
		{
			text.onMouseIn = () ->
			{
				text.animateWave(28, 0.06, 0.45, true);
				text.animateColour(targetColour, 0.06, 0.45);
			}
			text.onMouseOut = () ->
			{
				text.stopAnimation();
			}
			text.onClick = () ->
			{
				onClick(text);
			};
		}

		return text;
	}
}
