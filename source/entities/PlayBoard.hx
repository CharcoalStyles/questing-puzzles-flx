package entities;

import entities.Gem.GemType;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.util.FlxPool;
import haxe.atomic.AtomicBool;
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

typedef UpdatedGem =
{
	originalX:Int,
	originalY:Int,
	updatedX:Int,
	updatedY:Int,
	targetPostion:FlxPoint,
	gem:Gem,
	isMatch:Bool
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
		GemType.BLUE,
		GemType.GREEN,
		GemType.ORANGE,
		GemType.PURPLE,
		GemType.RED,
		GemType.YELLOW
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
			[1, 2, 3, 4, 5, 1, 2, 3],
			[2, 6, 4, 5, 1, 2, 3, 4],
			[3, 4, 6, 6, 2, 3, 4, 5],
			[4, 5, 6, 2, 3, 4, 5, 1],
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

		for (x in 0...cols)
		{
			grid[x] = new Array();
			for (y in 0...rows)
			{
				var gt = bsToGt[boardState[x][y] - 1]; // GemType.random();
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

	function swapCells():Void
	{
		if (swapping == null)
		{
			return;
		}

		gemMoves = [false, false];

		var temp = grid[swapping[0].x][swapping[0].y];
		grid[swapping[0].x][swapping[0].y] = grid[swapping[1].x][swapping[1].y];
		grid[swapping[1].x][swapping[1].y] = temp;

		swapping[0].gem.move(swapping[1].gem.x, swapping[1].gem.y, 0.3, (t) ->
		{
			gemMoves[0] = true;
		});
		swapping[1].gem.move(swapping[0].gem.x, swapping[0].gem.y, 0.3, (t) ->
		{
			gemMoves[1] = true;
		});
	}

	function updateMatching()
	{
		var matches = findAllMatches();

		if (matches.length > 0)
		{
			gemMoves = [];
			var flatMatches = new Array<GemGrid>();
			for (m in matches)
			{
				for (c in m)
				{
					flatMatches.push({x: c.x, y: c.y, gem: grid[c.x][c.y]});
				}
			}
			flatMatches.sort((a, b) -> a.y - b.y);

			var updatedGems = new Array<UpdatedGem>();

			for (match in flatMatches)
			{
				trace(match.x, match.y);

				var gem = grid[match.x][match.y];
				var updatedMatchedGem:UpdatedGem = {
					originalX: match.x,
					originalY: match.y,
					updatedX: match.x,
					updatedY: match.y,
					targetPostion: FlxPoint.get(gem.x, gem.y),
					gem: gem,
					isMatch: true
				};

				var finished = false;

				var nextY = match.y - 1;
				while (!finished)
				{
					if (nextY < 0)
					{
						finished = true;
						continue;
					}

					var ng = updatedGems.filter((g) -> g.originalX == match.x && g.originalY == nextY && g.isMatch); // Perhaps not do this, bruteforce it to the top?
					if (ng.length > 0)
					{
						finished = true;
					}
					else
					{
						var nextGem = grid[match.x][nextY];
						if (nextGem != null)
						{
							var updatedGem = updatedGems.filter((g) -> g.originalX == match.x && g.originalY == nextY && !g.isMatch);

							if (updatedGem.length > 0)
							{
								updatedMatchedGem.updatedY = nextY + 1;
								updatedMatchedGem.targetPostion = FlxPoint.get(nextGem.x, nextGem.y);
								finished = true;
							}
							else
							{
								updatedGems.push({
									originalX: match.x,
									originalY: nextY,
									updatedX: match.x,
									updatedY: nextY + 1,
									targetPostion: FlxPoint.get(nextGem.x, nextGem.y),
									gem: nextGem,
									isMatch: false
								});
								updatedMatchedGem.updatedY = nextY;
								updatedMatchedGem.targetPostion = FlxPoint.get(nextGem.x, nextGem.y);
								nextY--;
							}
						}
						else
						{
							finished = true;
						}
					}
				}

				updatedGems.push(updatedMatchedGem);
			}

			var colFall = new Array<Float>();
			for (i in 0...boardWidth)
			{
				colFall.push(FlxG.random.float(0.32, 0.38));
			}

			trace(updatedGems);

			for (ug in updatedGems)
			{
				grid[ug.updatedX][ug.updatedY] = ug.gem;
			}

			for (ug in updatedGems.filter((ug) -> !ug.isMatch))
			{
				var index = gemMoves.push(false);
				ug.gem.move(ug.targetPostion.x, ug.targetPostion.y, colFall[ug.updatedY], (t) ->
				{
					gemMoves[index - 1] = true;
				}, FlxEase.bounceOut);
			}

			for (ug in updatedGems.filter((ug) -> ug.isMatch))
			{
				ug.gem.kill();
				grid[ug.updatedX][ug.updatedY] = null;
			}

			state = State.Falling;

			// 	// for each column, find the lowest matched gem
			// 	var lowestMatchedCells = new Array<Int>();

			// 	for (i in 0...boardWidth)
			// 	{
			// 		lowestMatchedCells.push(-1);
			// 	}

			// 	for (cell in flatMatches)
			// 	{
			// 		if (lowestMatchedCells[cell.x] == -1 || cell.y > lowestMatchedCells[cell.x])
			// 		{
			// 			lowestMatchedCells[cell.x] = cell.y;
			// 		}
			// 	}
			// 	for (x in 0...lowestMatchedCells.length)
			// 	{
			// 		var colFall = FlxG.random.float(0.32, 0.38);
			// 		var lmc = lowestMatchedCells[x];
			// 		if (lmc != -1)
			// 		{
			// 			var colDelta = 0;
			// 			for (i in 1...lmc + 1)
			// 			{
			// 				var y = lmc - i;

			// 				var car = flatMatches.filter((c) -> c.x == x && c.y == y);

			// 				if (car.length > 0 && colDelta > 0)
			// 				{
			// 					colDelta += 1;
			// 				}

			// 				if (car.length == 0)
			// 				{
			// 					if (colDelta == 0)
			// 					{
			// 						// this is the first not matched cell, find the cell distance between this and hte lmc
			// 						colDelta = lmc - y;
			// 					}

			// 					var gem = grid[x][y];
			// 					var targetGem = grid[x][y + colDelta];

			// 					var index = gemMoves.push(false);

			// 					gem.move(targetGem.x, targetGem.y, Math.pow(colDelta, colFall) * colFall, (t) ->
			// 					{
			// 						gemMoves[index - 1] = true;
			// 					}, FlxEase.bounceOut);
			// 				}
			// 			}
			// 		}
			// 	}

			// 	for (m in flatMatches)
			// 	{
			// 		m.gem.kill();
			// 		grid[m.x][m.y] = null;
			// 	}

			// 	state = State.Falling;
		}
		else
		{
			swapCells();
			swapping = null;
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
