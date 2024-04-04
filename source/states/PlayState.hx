package states;

import entities.Gem.GemType;
import flixel.FlxG;
import flixel.FlxState;
import flixel.math.FlxPoint;
import utils.GlobalState;

class PlayState extends FlxState
{
	var globalState:GlobalState;

	override public function create()
	{
		super.create();
		FlxG.mouse.visible = true;
		FlxG.camera.antialiasing = true;
		var gs = FlxG.plugins.get(GlobalState);

		if (gs == null)
		{
			globalState = new GlobalState();
			FlxG.plugins.addPlugin(globalState);
		}
		else
		{
			globalState = gs;
		}

		var rows = 8;
		var cols = 8;
		var margin = 8;

		var cellSize = Math.floor(FlxG.height / rows - margin);
		var gemSize = cellSize - margin;

		var gridX = Math.floor((FlxG.width - (cellSize * cols)) / 2);
		var gridY = Math.floor((FlxG.height - (cellSize * rows)) / 2);

		for (y in 0...rows)
		{
			for (x in 0...cols)
			{
				var g = globalState.gemPool.get();
				var gt = GemType.random();
				g.init(gridX + x * cellSize, gridY + y * cellSize, FlxPoint.get(cellSize, cellSize), FlxPoint.get(margin, margin), gt);
				add(g);
			}
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}
