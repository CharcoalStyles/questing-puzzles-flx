package entities;

import entities.Gem.GemType;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxPoint;
import flixel.util.FlxPool;
import lime.app.Promise;
import states.MainMenuState;
import utils.KennyAtlasLoader;

typedef CellIndex =
{
	x:Int,
	y:Int
}

typedef GemGrid =
{
	x:Int,
	y:Int,
	gem:Gem
}

enum State
{
	Idle;
	Swapping;
	SwappingRevert;
	Matching;
	Falling;
	Refilling;
}

typedef MatchGroup = Array<CellIndex>;

class PlayBoard extends FlxTypedGroup<FlxSprite>
{
	var gemFrames:FlxAtlasFrames;
	var gemPool:FlxPool<Gem>;

	var grid:Array<Array<Gem>>;

	var boardX:Int;
	var boardY:Int;
	var boardWidth:Int;
	var boardHeight:Int;

	var cellSize:Int;

	var state = State.Idle;

	public function new(rows:Int, cols:Int)
	{
		super();
		FlxG.watch.add(this, "state");
		FlxG.watch.add(this, "gemMoves");

		boardWidth = cols;
		boardHeight = rows;

		gemFrames = KennyAtlasLoader.fromTexturePackerXml("assets/images/spritesheet_tilesGrey.png", "assets/data/spritesheet_tilesGrey.xml");

		gemPool = new FlxPool<Gem>(PoolFactory.fromFunction(() -> new Gem()));
		gemPool.preAllocate(72);

		cellSize = Math.floor(Math.min(FlxG.height, FlxG.width) / Math.max(rows, cols));
		var margin = Math.floor(cellSize * 0.4);

		boardX = Math.floor((FlxG.width - (cellSize * cols)) / 2);
		boardY = Math.floor((FlxG.height - (cellSize * rows)) / 2);

		grid = new Array();

		for (x in 0...cols)
		{
			grid[x] = new Array();
			for (y in 0...rows)
			{
				var gt = GemType.random();
				var gbkc = gt.color;
				gbkc.alphaFloat = 0.33;

				var bk = new FlxSprite(boardX + x * cellSize, boardY + y * cellSize);
				bk.makeGraphic(cellSize, cellSize, gbkc);
				add(bk);

				var g = gemPool.get();
				g.init(boardX + x * cellSize, boardY + y * cellSize, FlxPoint.get(cellSize, cellSize), FlxPoint.get(margin, margin), gemFrames, gt);
				add(g);
				grid[x][y] = g;
			}
		}
	}

	var selected:GemGrid = null;

	var swapping:Array<GemGrid> = null;

	var gemMoves = 0;

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.ESCAPE)
		{
			FlxG.switchState(new MainMenuState());
		}

		switch (state)
		{
			case State.Idle:
				updateIdle();
			case State.Swapping:
				updateSwapping();
			case SwappingRevert:
				if (gemMoves >= 2)
				{
					state = State.Idle;
				}
			default:
				// case State.Matching:
				//	updateMatching();
				// case State.Falling:
				//	updateFalling();
				// case State.Refilling:
				//	updateRefilling();
		}
	}

	function swapCells():Void
	{
		if (swapping == null)
		{
			return;
		}

		gemMoves = 0;

		var temp = grid[swapping[0].x][swapping[0].y];
		grid[swapping[0].x][swapping[0].y] = grid[swapping[1].x][swapping[1].y];
		grid[swapping[1].x][swapping[1].y] = temp;

		swapping[0].gem.move(swapping[1].gem.x, swapping[1].gem.y, 0.3, (t) ->
		{
			gemMoves++;
		});
		swapping[1].gem.move(swapping[0].gem.x, swapping[0].gem.y, 0.3, (t) ->
		{
			gemMoves++;
		});
	}

	function updateSwapping()
	{
		if (gemMoves >= 2)
		{
			var matches = findAllMatches();

			for (m in matches)
			{
				var x = "";
				for (c in m)
				{
					x += "(" + c.x + ", " + c.y + ") - ";
				}
				FlxG.log.add("Match: " + x);
			}

			if (matches.length > 0)
			{
				state = State.Matching;
			}
			else
			{
				// swap back
				swapCells();
				state = State.SwappingRevert;
			}
		}
	}

	function updateIdle()
	{
		if (FlxG.mouse.justPressed && state == State.Idle)
		{
			var cell = getCellAtMouse();
			if (cell != null)
			{
				FlxG.log.add("Clicked on cell: " + cell.x + ", " + cell.y);

				var clickedGem = grid[cell.x][cell.y];

				if (selected == null)
				{
					var selectedGem = clickedGem;
					selectedGem.selected = true;
					selected = {x: cell.x, y: cell.y, gem: selectedGem};
				}
				else
				{
					if (selected.x == cell.x && selected.y == cell.y)
					{
						selected.gem.selected = false;
						selected = null;
					}
					else
					{
						var dx = cell.x - selected.x;
						var dy = cell.y - selected.y;

						if (Math.abs(dx) + Math.abs(dy) == 1)
						{
							selected.gem.selected = false;
							swapping = [selected, {x: cell.x, y: cell.y, gem: clickedGem}];
							swapCells();
							selected = null;

							state = State.Swapping;
						}
						else
						{
							selected.gem.selected = false;

							selected = {x: cell.x, y: cell.y, gem: clickedGem};
							selected.gem.selected = true;
						}
					}
				}
			}
		}
	}

	function getCellAtMouse():CellIndex
	{
		var x = FlxG.mouse.x - boardX;
		var y = FlxG.mouse.y - boardY;

		if (x < 0 || y < 0 || x >= boardWidth * cellSize || y >= boardHeight * cellSize)
		{
			return null;
		}

		return {x: Math.floor(x / cellSize), y: Math.floor(y / cellSize)};
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
