package utils;

import flixel.math.FlxPoint;
import flixel.util.FlxColor;

typedef ExtendedLerpStop<T> =
{
	t:Float,
	value:T
};

class ExtendedLerp
{
	public static function flerp(stops:Array<ExtendedLerpStop<Float>>, t:Float):Float
	{
		if (stops.length == 0)
		{
			throw "No stops provided";
		}
		if (stops.length == 1)
		{
			return stops[0].value;
		}
		if (t <= stops[0].t)
		{
			return stops[0].value;
		}
		if (t >= stops[stops.length - 1].t)
		{
			return stops[stops.length - 1].value;
		}

		var i = 0;
		while (i < stops.length - 1 && t > stops[i + 1].t)
		{
			i++;
		}

		// Perform linear interpolation (LERP)
		var t1 = stops[i].t;
		var t2 = stops[i + 1].t;
		var v1 = stops[i].value;
		var v2 = stops[i + 1].value;

		return lerp(t1, t2, v1, v2, t);
	}

	static function lerp(t1:Float, t2:Float, v1:Float, v2:Float, t:Float):Float
	{
		return v1 + (v2 - v1) * (t - t1) / (t2 - t1);
	}

	public static function fPlerp(stops:Array<ExtendedLerpStop<FlxPoint>>, t:Float, ?point:FlxPoint):FlxPoint
	{
		var p = point != null ? point : FlxPoint.get();

		if (stops.length == 0)
		{
			throw "No stops provided";
		}
		if (stops.length == 1)
		{
			return p.copyFrom(stops[0].value);
		}
		if (t <= stops[0].t)
		{
			return p.copyFrom(stops[0].value);
		}
		if (t >= stops[stops.length - 1].t)
		{
			return p.copyFrom(stops[stops.length - 1].value);
		}

		var i = 0;
		while (i < stops.length - 1 && t > stops[i + 1].t)
		{
			i++;
		}

		var t1 = stops[i].t;
		var t2 = stops[i + 1].t;
		var v1 = stops[i].value;
		var v2 = stops[i + 1].value;

		p.x = lerp(t1, t2, v1.x, v2.x, t);
		p.y = lerp(t1, t2, v1.y, v2.y, t);

		return p;
	}

	public static function ilerp(stops:Array<ExtendedLerpStop<Int>>, t:Float):Int
	{
		return Std.int(flerp(stops.map(function(stop) return {t: stop.t, value: stop.value * 1.0}), t));
	}

	public static function clerp(stops:Array<ExtendedLerpStop<FlxColor>>, t:Float):FlxColor
	{
		if (stops.length == 0)
		{
			throw "No stops provided";
		}
		if (stops.length == 1)
		{
			return stops[0].value;
		}
		if (t <= stops[0].t)
		{
			return stops[0].value;
		}
		if (t >= stops[stops.length - 1].t)
		{
			return stops[stops.length - 1].value;
		}

		var i = 0;
		while (i < stops.length - 1 && t > stops[i + 1].t)
		{
			i++;
		}

		var t1 = stops[i].t;
		var t2 = stops[i + 1].t;
		var v1 = stops[i].value;
		var v2 = stops[i + 1].value;

		var percent = (t - t1) / (t2 - t1);
		return FlxColor.interpolate(v1, v2, percent);
	}
}
