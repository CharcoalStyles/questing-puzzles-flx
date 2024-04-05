package utils;

import entities.Gem;
import flixel.FlxBasic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxPool;

class GlobalState extends FlxBasic
{
	public var isUsingController:Bool = false;
	public var controllerId:Int = 0;

	public function new()
	{
		super();
	}
}
