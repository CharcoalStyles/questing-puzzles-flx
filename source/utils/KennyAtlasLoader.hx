package utils;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets;

class KennyAtlasLoader
{
	public static function fromTexturePackerXml(source:FlxGraphicAsset, xml:FlxXmlAsset):FlxAtlasFrames
	{
		final graphic:FlxGraphic = FlxG.bitmap.add(source);
		if (graphic == null)
			return null;

		// No need to parse data again
		var frames = FlxAtlasFrames.findFrame(graphic);
		if (frames != null)
		{
			FlxG.log.add("Found cached frames");
			return frames;
		}

		if (graphic == null || xml == null)
			return null;

		frames = new FlxAtlasFrames(graphic);

		final data = xml.getXml();

		for (sprite in data.firstElement().elements())
		{
			var name = sprite.get("name");
			var rect = FlxRect.get(Std.parseInt(sprite.get("x")), Std.parseInt(sprite.get("y")), Std.parseInt(sprite.get("width")),
				Std.parseInt(sprite.get("height")));
			var sourceSize = FlxPoint.get(rect.width, rect.height);

			frames.addAtlasFrame(rect, sourceSize, FlxPoint.get(), name);
		}

		return frames;
	}
}
