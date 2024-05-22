package utils;

import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.text.FlxText.FlxTextAlign;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import haxe.Timer;

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

class CsMenuPage extends FlxTypedGroup<SplitText>
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

	public function addLabel(label:String, ?colour:FlxColor)
	{
		addEntry(label, null, {unselectedColour: colour == null ? 0xFFe0e0e0 : colour});
	}

	public function addItem(label:String, ?callback:Void->Void, ?options:AnimOptions)
	{
		addEntry(label, callback, options);
	}

	function addEntry(label:String, ?callback:Void->Void, ?options:AnimOptions)
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

		if (active)
		{
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

	function manuallySetSelectedTop()
	{
		var s = -1;
		for (i in 0...menuItems.length)
		{
			if (s == -1 && menuItems[i].selectable)
			{
				members[i].color = menuItems[i].options.selectedColour;
				s = i;
			}
			else
			{
				members[i].color = menuItems[i].options.unselectedColour;
			}
		}
		selected = s;
	}

	public function show(force:Bool = false, ?callback:Void->Void)
	{
		if (force)
		{
			manuallySetSelectedTop();
			active = true;
			for (member in members)
			{
				member.alpha = 1;
			}
			return;
		}

		for (i in 0...members.length)
		{
			manuallySetSelectedTop();
			Timer.delay(function()
			{
				FlxTween.tween(members[i], {alpha: 1}, 0.5, {
					onComplete: (t) ->
					{
						if (i == members.length - 1)
						{
							active = true;
							if (callback != null)
							{
								callback();
							}
						}
					}
				});
			}, 1);
		}
	}

	public function hide(force:Bool = false, ?callback:Void->Void)
	{
		active = false;

		if (force)
		{
			for (member in members)
			{
				member.alpha = 0;
			}
			return;
		}

		for (i in 0...members.length)
		{
			Timer.delay(function()
			{
				FlxTween.tween(members[i], {alpha: 0}, 0.5, {
					onComplete: (t) ->
					{
						if (callback != null && i == members.length - 1)
							callback();
					}
				});
			}, 1);
		}
	}
}
