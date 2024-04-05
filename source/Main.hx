package;

import flixel.FlxGame;
import openfl.display.Sprite;
import states.FlxCstyLogo;
import states.MainMenuState;

class Main extends Sprite
{
	public function new()
	{
		super();
		addChild(new FlxGame(0, 0, () -> new FlxCstyLogo(new MainMenuState())));
	}
}
