package utils;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.text.FlxText.FlxTextAlign;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.util.FlxColor;

typedef AnimOptions =
{
	unselectedColour:FlxColor,
	?selectedColour:FlxColor,
	?borderColour:FlxColor,
}

typedef MenuItem =
{
	selectable:Bool,
	?callback:Void->Void,
	?options:AnimOptions,
}

class CsMenu extends FlxTypedGroup<SplitText>
{
	var menuItems = new Array<MenuItem>();
	var selected:Int = 0;
	var alignment:FlxTextAlign;
	var startX:Float;
	var startY:Float;
	var workingY:Float;
	var minX:Float;
	var maxX:Float;

	public var rect(get, never):FlxRect;

	function get_rect():FlxRect
	{
		return FlxRect.get(minX, startY, maxX - minX, workingY - startY);
	}

	public function new(X:Float, Y:Float, align:FlxTextAlign)
	{
		super();
		alignment = align;
		menuItems = [];
		startX = minX = maxX = X;
		startY = workingY = Y;
	}

	public function addItem(label:String, ?callback:Void->Void, ?options:AnimOptions)
	{
		var opt = options != null ? options : {unselectedColour: 0xFF303030, selectedColour: 0xFF909090, borderColour: 0xFFFFFFFF};

		if (opt.selectedColour == null)
		{
			opt.selectedColour = opt.unselectedColour;
		}

		menuItems.push({selectable: callback != null, callback: callback, options: opt});

		var text = new SplitText(startX, workingY, label);
		switch (alignment)
		{
			case FlxTextAlign.CENTER:
				text.x = startX - text.width / 2;
				minX = Math.min(minX, text.x);
				maxX = Math.max(maxX, text.x + text.width);
			case FlxTextAlign.RIGHT:
				text.x = startX - text.width;
				minX = Math.min(minX, startX - text.width);
				maxX = Math.max(maxX, startX);
			default:
				text.x = startX;
				minX = Math.min(minX, startX);
				maxX = Math.max(maxX, startX + text.width);
		}
		add(text);

		var i = menuItems.filter(function(item) return item.selectable).length;
		if (i == 1)
		{
			text.color = opt.selectedColour;
			selected = menuItems.length - 1;
		}
		else
		{
			text.color = opt.unselectedColour;
		}

		if (opt.borderColour != null)
		{
			text.borderStyle = FlxTextBorderStyle.OUTLINE;
			text.borderColor = opt.borderColour;
			text.borderSize = 2;
		}

		workingY += text.height + 16;
	}

	function onSelectedAnim(index:Int)
	{
		var selection = members[index];
		var item = menuItems[index];
		selection.animateWave(12, 0.01, 0.2, true);
		selection.animateColour(item.options.selectedColour, 0.01, 0.2, item.options.unselectedColour, true);
	}

	function onDeselectedAnim(index:Int)
	{
		var selection = members[index];
		var item = menuItems[index];
		selection.animateColour(item.options.unselectedColour, 0.01, 0.2, item.options.selectedColour, true);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.UP)
		{
			var prevSelected = selected;
			var nextSelected = selected;

			var found = false;
			do
			{
				nextSelected = FlxMath.wrap(nextSelected - 1, 0, menuItems.length - 1);
				if (menuItems[nextSelected].selectable)
				{
					found = true;
				}
			}
			while (!found);

			if (nextSelected != prevSelected)
			{
				selected = nextSelected;
				onDeselectedAnim(prevSelected);
				onSelectedAnim(selected);
			}
		}
		else if (FlxG.keys.justPressed.DOWN)
		{
			var prevSelected = selected;
			var nextSelected = selected;

			var found = false;
			do
			{
				nextSelected = FlxMath.wrap(nextSelected + 1, 0, menuItems.length - 1);
				if (menuItems[nextSelected].selectable)
				{
					found = true;
				}
			}
			while (!found);

			if (nextSelected != prevSelected)
			{
				selected = nextSelected;
				onDeselectedAnim(prevSelected);
				onSelectedAnim(selected);
			}
		}
		else if (FlxG.keys.justPressed.ENTER)
		{
			menuItems[selected].callback();
		}

		for (txtId in 0...members.length)
		{
			if (members[txtId].rect.containsPoint(FlxG.mouse.getPosition()))
			{
				if (txtId != selected && menuItems[txtId].selectable)
				{
					onDeselectedAnim(selected);
					selected = txtId;
					onSelectedAnim(selected);
				}

				if (FlxG.mouse.justPressed && menuItems[txtId].selectable)
				{
					menuItems[selected].callback();
				}
			}
		}
	}
}
