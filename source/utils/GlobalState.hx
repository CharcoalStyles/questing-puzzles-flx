package utils;

import entities.Gem;
import flixel.FlxBasic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxPool;

class GlobalState extends FlxBasic
{
	public var isUsingController:Bool = false;
	public var controllerId:Int = 0;
	public var gemFrames:FlxAtlasFrames = null;
	public var gemPool:FlxPool<Gem>;

	public function new()
	{
		super();
		gemFrames = KennyAtlasLoader.fromTexturePackerXml("assets/images/spritesheet_tilesGrey.png", "assets/data/spritesheet_tilesGrey.xml");

		gemPool = new FlxPool<Gem>(PoolFactory.fromFunction(() -> new Gem()));
		gemPool.preAllocate(72);
	}
}
