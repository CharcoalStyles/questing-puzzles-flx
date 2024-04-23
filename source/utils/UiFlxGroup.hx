package utils;

import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;

class UiFlxGroup extends FlxGroup
{
	private var screenArea:FlxRect;

	public function new()
	{
		super();
	}

	public function setScreenArea(screenArea:FlxRect):Void
	{
		this.screenArea = screenArea;
	}

	public function isPointInside(point:FlxPoint)
	{
		if (screenArea == null)
		{
			return null;
		}

		return screenArea.containsPoint(point);
	}
}
