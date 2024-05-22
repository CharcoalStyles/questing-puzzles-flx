package utils;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.text.FlxText.FlxTextAlign;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.util.FlxColor;

class CsMenu extends FlxTypedGroup<CsMenuPage>
{
	var x:Float;
	var y:Float;
	var menuAlign:FlxTextAlign;
	var pages:Map<String, CsMenuPage>;
	var activePageTag:String;

	public var rect(get, never):FlxRect;

	function get_rect():FlxRect
	{
		return FlxRect.get();
	}

	public function new(X:Float, Y:Float, align:FlxTextAlign)
	{
		super();

		x = X;
		y = Y;
		menuAlign = align;

		pages = new Map<String, CsMenuPage>();
		activePageTag = null;
	}

	public function createPage(tag:String)
	{
		var page = new CsMenuPage(x, y, menuAlign);
		add(page);
		pages.set(tag, page);
		if (activePageTag == null)
		{
			activePageTag = tag;
			page.active = true;
		}
		else
		{
			page.active = false;
		}
		return page;
	}

	public function openPage(tag:String)
	{
		if (activePageTag == tag)
		{
			return;
		}

		pages[activePageTag].hide(() ->
		{
			pages[tag].show();
		});

		activePageTag = tag;
	}
}
