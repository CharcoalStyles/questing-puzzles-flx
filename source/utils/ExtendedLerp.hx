package utils;

typedef ExtendedLerpStop =
{
	t:Float,
	value:Float
};

class ExtendedLerp
{
	public static function lerp(stops:Array<ExtendedLerpStop>, t:Float)
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

		return v1 + (v2 - v1) * (t - t1) / (t2 - t1);
	}
}
