package utils;

import flixel.math.FlxPoint;
import flixel.math.FlxRect;

class CsMath
{
	public static function centreRect(rect:FlxRect):FlxPoint
	{
		return FlxPoint.get(rect.x + rect.width / 2, rect.y + rect.height / 2);
	}
}
