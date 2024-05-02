package states.subStates;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.text.FlxText;

class PauseState extends FlxSubState
{
	public function new()
	{
		super(0xff000000);
	}

	public override function create():Void
	{
		super.create();

		var workingY = FlxG.height / 3;

		var text:FlxText = new FlxText(0, workingY, -1, "PAUSED");
		text.setFormat(null, 64, 0xff000000, LEFT, OUTLINE, 0xffffffff);
		text.x = (FlxG.width - text.width) / 2;
		add(text);

    workingY += text.height * 1.75;

    
	}
}
