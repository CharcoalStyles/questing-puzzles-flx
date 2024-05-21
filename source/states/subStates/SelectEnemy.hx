package states.subStates;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText.FlxTextAlign;
import flixel.util.FlxColor;
import utils.CsMenu;
import utils.GlobalState;
import utils.Loader;
import utils.SplitText;

class SelectEnemy extends FlxSubState
{
	public function new()
	{
		super(0x50000000);
	}

	public override function create():Void
	{
		super.create();

		var globalState = FlxG.plugins.get(GlobalState);

		var characters = Loader.loadCharacters();
		// var names = enemies.map(function(c) return c.name);

		var menu = new CsMenu(FlxG.width / 2, FlxG.height / 2, FlxTextAlign.CENTER);
		menu.addItem("Select Enemy", null, {
			unselectedColour: FlxColor.WHITE,
		});

		for (char in characters)
		{
			menu.addItem(char.name, () ->
			{
				var c = Loader.loadCharacter(char);
				globalState.ai = c;
				FlxG.switchState(new PlayState());
			});
		}

		menu.addItem("BACK", closeSub);

		var menuRect = menu.rect;
		var borderSize = 8;
		var menuPadding = 64;

		var windowBorder = new FlxSprite(menuRect.x - (borderSize + menuPadding) / 2, menuRect.y - (borderSize + menuPadding) / 2);
		windowBorder.makeGraphic(Math.floor(menuRect.width + borderSize + menuPadding), Math.floor(menuRect.height + borderSize + menuPadding), FlxColor.WHITE);
		add(windowBorder);

		var window = new FlxSprite(menuRect.x - menuPadding / 2, menuRect.y - menuPadding / 2);
		window.makeGraphic(Math.floor(menuRect.width + menuPadding), Math.floor(menuRect.height + menuPadding), FlxColor.BLACK);
		add(window);

		add(menu);
	}

	private function closeSub():Void
	{
		closeCallback();
	}
}
