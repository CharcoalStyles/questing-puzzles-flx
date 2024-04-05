package states;

import entities.PlayBoard;
import flixel.FlxG;
import flixel.FlxState;

class PlayState extends FlxState
{
	override public function create()
	{
		super.create();
		FlxG.mouse.visible = true;
		FlxG.camera.antialiasing = true;

		add(new PlayBoard(8, 8)); // var rows = 8;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}
