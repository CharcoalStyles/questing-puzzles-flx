package entities;

import entities.Gem.GemType;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxPoint;
import flixel.util.FlxPool;
import states.MainMenuState;
import utils.KennyAtlasLoader;

typedef CellIndex =
{
	x:Int,
	y:Int
};

typedef MatchGroup = Array<CellIndex>;

class PlayBoard extends FlxTypedGroup<FlxSprite>
{
	var gemFrames:FlxAtlasFrames;
	var gemPool:FlxPool<Gem>;

	var grid:Array<Array<Gem>>;

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

		grid = new Array();

		for (x in 0...cols)
		{
			grid[x] = new Array();
			for (y in 0...rows)
			{
				var gt = GemType.random();
				var gbkc = gt.color;
				gbkc.alphaFloat = 0.33;

				var bk = new FlxSprite(gridX + x * cellSize, gridY + y * cellSize);
				bk.makeGraphic(cellSize, cellSize, gbkc);
				add(bk);

				var g = gemPool.get();
				g.init(gridX + x * cellSize, gridY + y * cellSize, FlxPoint.get(cellSize, cellSize), FlxPoint.get(margin, margin), gemFrames, gt);
				add(g);
				grid[x][y] = g;
			}
		}
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.ESCAPE)
		{
			FlxG.switchState(new MainMenuState());
		}

		if (FlxG.keys.justPressed.SPACE)
		{
			for (x in 0...grid.length)
			{
				for (y in 0...grid[0].length)
				{
					grid[x][y].selected = false;
				}
			}
		}

		if (FlxG.keys.justPressed.A)
		{
			var matches = findAllMatches();

			for (match in matches)
			{
				for (cell in match)
				{
					grid[cell.x][cell.y].selected = true;
				}
			}
		}

		if (FlxG.keys.justPressed.X)
		{
			for (y in 0...grid[0].length)
			{
				var matches = findMatchesInRow(y);
				FlxG.log.add(matches);
				for (match in matches)
				{
					for (cell in match)
					{
						grid[cell.x][cell.y].selected = true;
					}
				}
			}
		}

		if (FlxG.keys.justPressed.Y)
		{
			for (x in 0...grid.length)
			{
				var matches = findMatchesInColumn(x);
				FlxG.log.add(matches);
				for (match in matches)
				{
					for (cell in match)
					{
						grid[cell.x][cell.y].selected = true;
					}
				}
			}
		}
	}

	function findAllMatches():Array<MatchGroup>
	{
		var matches = new Array<MatchGroup>();

		var colMatches = new Array<MatchGroup>();
		var rowMatches = new Array<MatchGroup>();

		for (y in 0...grid[0].length)
		{
			for (m in findMatchesInRow(y))
			{
				rowMatches.push(m);
			}
		}

		for (x in 0...grid.length)
		{
			for (m in findMatchesInColumn(x))
			{
				colMatches.push(m);
			}
		}

		// find overlapping matches

		var rowSubMatchIndexs = new Array<Int>();
		var colSubMatchIndexs = new Array<Int>();

		for (rowIndex in 0...rowMatches.length)
		{
			for (colIndex in 0...colMatches.length)
			{
				var rowMatch = rowMatches[rowIndex];
				var colMatch = colMatches[colIndex];

				var isMatched = false;

				for (rm in rowMatch)
				{
					for (cm in colMatch)
					{
						if (rm.x == cm.x && rm.y == cm.y)
						{
							isMatched = true;
							break;
						}
					}
				}

				if (isMatched)
				{
					// join the two matches
					var match = new MatchGroup();

					for (rm in rowMatch)
					{
						match.push(rm);
					}

					for (cm in colMatch)
					{
						match.push(cm);
					}

					matches.push(match);

					rowSubMatchIndexs.push(rowIndex);
					colSubMatchIndexs.push(colIndex);
				}
			}
		}

		// remove the submatches
		for (i in rowSubMatchIndexs)
		{
			rowMatches.remove(rowMatches[i]);
		}

		for (i in colSubMatchIndexs)
		{
			colMatches.remove(colMatches[i]);
		}

		// add the remaining matches
		for (m in rowMatches)
		{
			matches.push(m);
		}

		for (m in colMatches)
		{
			matches.push(m);
		}

		return matches;
	}

	function findMatchesInRow(y:Int):Array<MatchGroup>
	{
		var lastGemTypeID = -1;
		var matches = new Array<MatchGroup>();
		var workingMatch = new MatchGroup();

		for (x in 0...grid.length)
		{
			var gem = grid[x][y];
			if (gem.gemTypeId == lastGemTypeID)
			{
				workingMatch.push({x: x, y: y});
			}
			else
			{
				if (workingMatch.length >= 3)
				{
					matches.push(workingMatch);
				}

				workingMatch = new MatchGroup();
				workingMatch.push({x: x, y: y});
				lastGemTypeID = gem.gemTypeId;
			}
		}

		if (workingMatch.length >= 3)
		{
			matches.push(workingMatch);
		}

		return matches;
	}

	function findMatchesInColumn(x:Int):Array<MatchGroup>
	{
		var lastGemTypeID = -1;
		var matches = new Array<MatchGroup>();
		var workingMatch = new MatchGroup();

		for (y in 0...grid[0].length)
		{
			var gem = grid[x][y];
			if (gem.gemTypeId == lastGemTypeID)
			{
				workingMatch.push({x: x, y: y});
			}
			else
			{
				if (workingMatch.length >= 3)
				{
					matches.push(workingMatch);
				}
				workingMatch = new MatchGroup();
				workingMatch.push({x: x, y: y});
				lastGemTypeID = gem.gemTypeId;
			}
		}

		if (workingMatch.length >= 3)
		{
			matches.push(workingMatch);
		}

		return matches;
	}
}
