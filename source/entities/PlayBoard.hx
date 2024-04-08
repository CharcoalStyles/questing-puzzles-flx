package entities;

import entities.Gem.GemType;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.util.FlxPool;
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

typedef UpdatedGem =
{
	original:CellIndex,
	updated:CellIndex,
	targetPosition:FlxPoint
};

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

	var boardState = new Array<Array<Int>>();
	var bsToGt = [
		GemType.RED,
		GemType.GREEN,
		GemType.BLUE,
		GemType.YELLOW,
		GemType.PURPLE,
		GemType.ORANGE
	];

	public function new(rows:Int, cols:Int)
	{
		super();
		FlxG.watch.add(this, "state");
		FlxG.watch.add(this, "gemMoves");

		FlxG.mouse.visible = true;

		boardWidth = cols;
		boardHeight = rows;

		boardState = [
			[1, 2, 6, 4, 5, 1, 2, 3],
			[2, 6, 4, 5, 1, 2, 3, 4],
			[6, 4, 6, 6, 2, 3, 3, 5],
			[4, 5, 6, 2, 3, 4, 3, 1],
			[5, 1, 2, 3, 4, 5, 1, 2],
			[1, 2, 3, 4, 5, 1, 2, 3],
			[2, 3, 4, 5, 1, 2, 3, 4],
			[3, 4, 5, 1, 2, 3, 4, 5]
		];

		gemFrames = KennyAtlasLoader.fromTexturePackerXml("assets/images/spritesheet_tilesGrey.png", "assets/data/spritesheet_tilesGrey.xml");

		gemPool = new FlxPool<Gem>(PoolFactory.fromFunction(() -> new Gem()));
		gemPool.preAllocate(rows * cols);

		cellSize = Math.floor(Math.min(FlxG.height, FlxG.width) / Math.max(rows, cols));
		var margin = Math.floor(cellSize * 0.4);

		boardX = Math.floor((FlxG.width - (cellSize * cols)) / 2);
		boardY = Math.floor((FlxG.height - (cellSize * rows)) / 2);

		grid = new Array();
	}

	var selected:GemGrid = null;

	var userSwap:Array<GemGrid> = null;

	var gemMoves:Array<Bool> = null;

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.ESCAPE)
		{
			FlxG.switchState(new MainMenuState());
		}

		if (FlxG.keys.justPressed.F)
		{
			for (x in 0...boardWidth)
			{
				var r = "";
				for (y in 0...boardHeight)
				{
					if (grid[x][y] != null)
						r += grid[x][y].gemTypeId + ", ";
					else
						r += "-, ";
				}

				FlxG.log.add(r);
			}
		}

		switch (state)
		{
			case State.Idle:
				updateIdle();
			case State.Swapping:
				updateSwapping();
			case SwappingRevert:
				if (gemMoves.contains(false))
					return;
				else
					state = State.Idle;
			default:
			case State.Matching:
				updateMatching();
			case State.Falling:
				updateFalling();
				// case State.Refilling:
				//	updateRefilling();
		}
	}

	function updateFalling()
	{
		if (gemMoves.contains(false))
		{
			return;
		}
		else
		{
			state = State.Refilling;
		}
	}

	function swapCells(gem1:GemGrid, gem2:GemGrid, ?visual:Bool = true):Void
	{
		var temp = grid[gem1.x][gem1.y];
		grid[gem1.x][gem1.y] = grid[gem2.x][gem2.y];
		grid[gem2.x][gem2.y] = temp;

		if (visual)
		{
			gemMoves = [false, false];
			gem1.gem.move(gem2.gem.x, gem2.gem.y, 0.3, (t) ->
			{
				gemMoves[0] = true;
			});
			gem2.gem.move(gem1.gem.x, gem1.gem.y, 0.3, (t) ->
			{
				gemMoves[1] = true;
			});
		}
	}

	// function swapCells(?gem1:GemGrid, ?gem2:GemGrid, ?noVisual:Bool):Void {}

	function updateMatching()
	{
		var matches = findAllMatches();

		if (matches.length > 0)
		{
			gemMoves = [];
			var flatMatches = new Array<GemGrid>();
			var byColMatches = new Array<Array<GemGrid>>();

			for (y in 0...boardWidth)
			{
				byColMatches.push([]);
			}

			for (m in matches)
			{
				for (c in m)
				{
					flatMatches.push({x: c.x, y: c.y, gem: grid[c.x][c.y]});
					byColMatches[c.x].push({x: c.x, y: c.y, gem: grid[c.x][c.y]});
				}
			}
			flatMatches.sort((a, b) -> a.y - b.y);

			byColMatches = byColMatches.filter((c) -> c.length > 0);
			byColMatches = byColMatches.map((c) ->
			{
				c.sort((a, b) -> a.y - b.y);
				return c;
			});

			var emptyCells = new Array<UpdatedGem>();
			var movedCells = new Array<UpdatedGem>();

			for (colMatches in byColMatches)
			{
				var column = colMatches[0].x;
				var matchedCells = colMatches.map((c) -> c.y);
				matchedCells.sort((a, b) -> a - b);
				var filledCells:Array<UpdatedGem> = [];

				for (y in 0...boardHeight)
				{
					if (matchedCells.contains(y))
					{
						continue;
					}

					filledCells.push({
						original: {x: column, y: y},
						updated: {x: column, y: y},
						targetPosition: FlxPoint.get(grid[column][y].x, grid[column][y].y)
					});
				}

				var totalEmpty = matchedCells.length;
				while (matchedCells.length > 0)
				{
					var empty = matchedCells.pop();
					if (empty != null)
					{
						var uY = totalEmpty - matchedCells.length - 1;
						emptyCells.push({
							original: {x: column, y: empty},
							updated: {x: column, y: uY},
							targetPosition: FlxPoint.get(grid[column][0].x, grid[column][0].y)
						});

						matchedCells = matchedCells.map((c) -> c + 1);
						filledCells = filledCells.map((c) ->
						{
							if (empty < c.updated.y)
								return c;

							c.updated.y += 1;

							var target = grid[column][c.updated.y];

							c.targetPosition.set(target.x, target.y);
							return c;
						});
					}
				}

				var culled = filledCells.filter((c) -> c.original.y != c.updated.y);
				movedCells = movedCells.concat(culled);
			}

			var colFall = new Array<Float>();
			for (i in 0...boardWidth)
			{
				colFall.push(FlxG.random.float(0.32, 0.38));
			}

			movedCells = movedCells.filter((mc) -> mc.original.y != mc.updated.y);
			movedCells.sort((a, b) -> b.updated.y - a.updated.y);

			for (mc in movedCells)
			{
				var originalGem = grid[mc.original.x][mc.original.y];
				var emptyCell = grid[mc.updated.x][mc.updated.y];
				swapCells({x: mc.original.x, y: mc.original.y, gem: originalGem}, {x: mc.updated.x, y: mc.updated.y, gem: emptyCell}, false);

				var index = gemMoves.push(false);
				originalGem.move(mc.targetPosition.x, mc.targetPosition.y, colFall[mc.updated.x], (t) ->
				{
					gemMoves[index - 1] = true;
				}, FlxEase.bounceOut);
			}

			for (ec in emptyCells)
			{
				var emptyGem = grid[ec.updated.x][ec.updated.y];
				emptyGem.kill();
				grid[ec.updated.x][ec.updated.y] = null;
			}

			state = State.Falling;
		}
		else
		{
			swapCells(userSwap[0], userSwap[1]);
			userSwap = null;
			state = State.SwappingRevert;
		}
	}

	function updateSwapping()
	{
		if (gemMoves.contains(false))
			return;
		else
			state = State.Matching;
	}

	function updateIdle()
	{
		if (FlxG.mouse.justPressed && state == State.Idle)
		{
			var cell = getCellAtMouse();
			if (cell != null)
			{
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
							userSwap = [selected, {x: cell.x, y: cell.y, gem: clickedGem}];
							swapCells(userSwap[0], userSwap[1]);
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

				var duplicateCells = [];
				for (rm in rowMatch)
				{
					for (cm in colMatch)
					{
						if (rm.x == cm.x && rm.y == cm.y)
						{
							duplicateCells.push(rm);
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
						if (!duplicateCells.contains(rm))
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
