package entities;

import entities.Gem.GemType;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.util.FlxPool;
import utils.KennyAtlasLoader;

class PlayBoard extends FlxTypedGroup<FlxSprite>
{
	var gemFrames:FlxAtlasFrames;
	var gemPool:FlxPool<Gem>;

	public function new(rows:Int, cols:Int)
	{
		super();
		gemFrames = KennyAtlasLoader.fromTexturePackerXml("assets/images/spritesheet_tilesGrey.png", "assets/data/spritesheet_tilesGrey.xml");

		gemPool = new FlxPool<Gem>(PoolFactory.fromFunction(() -> new Gem()));
		gemPool.preAllocate(72);

		var cellSize = Math.floor(Math.min(FlxG.height, FlxG.width) / Math.max(rows, cols));
		var margin = Math.floor(cellSize * 0.4);

		var gridX = Math.floor((FlxG.width - (cellSize * cols)) / 2);
		var gridY = Math.floor((FlxG.height - (cellSize * rows)) / 2);

		for (y in 0...rows)
		{
			for (x in 0...cols)
			{
				var gt = GemType.random();
				var gbkc = gt.color;
				gbkc.alphaFloat = 0.33;

				var bk = new FlxSprite(gridX + x * cellSize, gridY + y * cellSize);
				bk.makeGraphic(cellSize, cellSize, gbkc);
				add(bk);

				var g = gemPool.get();
				add(g);
				g.init(gridX + x * cellSize, gridY + y * cellSize, FlxPoint.get(cellSize, cellSize), FlxPoint.get(margin, margin), gemFrames, gt);
			}
		}
	}
}
