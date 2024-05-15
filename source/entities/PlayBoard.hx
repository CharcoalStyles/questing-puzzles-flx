package entities;

import entities.Gem.GemType;
import entities.Gem.ManaType;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.tweens.FlxEase;
import flixel.util.FlxPool;
import states.MainMenuState;
import utils.KennyAtlasLoader;
import utils.UiFlxGroup;

typedef CellIndex =
{
	x:Int,
	y:Int
}

typedef CellMove =
{
	x:Int,
	y:Int,
	direction:MoveDirection
}

typedef ScoredMatch =
{
	move:CellMove,
	matches:Array<MatchGroup>,
	score:Int
}

typedef GemGrid =
{
	x:Int,
	y:Int,
	gem:Gem
}

typedef MatchTypePosition =
{
	manaType:ManaType,
	pos:FlxPoint
}

typedef UpdatedGem =
{
	original:CellIndex,
	updated:CellIndex,
	targetPosition:FlxPoint
};

enum BoardState
{
	Idle;
	Swapping;
	SwappingRevert;
	Matching;
	Matching_Spell;
	PostMatch;
	EndTurn;
	Shuffle;
}

enum MoveDirection
{
	Up;
	Down;
	Left;
	Right;
}

typedef MatchGroup = Array<CellIndex>;

class PlayBoard extends UiFlxGroup
{
	var gemFrames:FlxAtlasFrames;
	var gemPool:FlxPool<Gem>;

	var grid:Array<Array<Gem>>;

	var boardX:Int;
	var boardY:Int;
	var boardWidth:Int;
	var boardHeight:Int;

	var cellSize:Int;

	var state = BoardState.Idle;
	var previousState = BoardState.Idle;

	var moveTimer:Float = 0.0;

	var boardState = new Array<Array<Int>>();
	var bsToGt = [
		GemType.RED,
		GemType.GREEN,
		GemType.BLUE,
		GemType.YELLOW,
		GemType.PURPLE,
		GemType.ORANGE
	];

	var bkgrndTiles:FlxGroup;
	var gems:FlxGroup;

	public var activeMatches:Array<MatchTypePosition> = null;
	public var potentialMoves:Array<ScoredMatch> = null;
	public var onStateChange:BoardState->Void;

	public function new(rows:Int, cols:Int)
	{
		super();
		FlxG.watch.add(this, "state");
		FlxG.watch.add(this, "gemMoves");

		FlxG.mouse.visible = true;

		boardWidth = cols;
		boardHeight = rows;

		gemFrames = KennyAtlasLoader.fromTexturePackerXml("assets/images/spritesheet_tilesGrey.png", "assets/data/spritesheet_tilesGrey.xml");

		gemPool = new FlxPool<Gem>(PoolFactory.fromFunction(() -> new Gem()));
		gemPool.preAllocate(rows * cols);

		cellSize = Math.floor(Math.min(FlxG.height, FlxG.width) / Math.max(rows, cols));
		var margin = Math.floor(cellSize * 0.4);

		boardX = Math.floor((FlxG.width - (cellSize * cols)) / 2);
		boardY = Math.floor((FlxG.height - (cellSize * rows)) / 2);

		setScreenArea(new FlxRect(boardX, boardY, cellSize * cols, cellSize * rows));

		grid = new Array();
		bkgrndTiles = new FlxGroup();
		gems = new FlxGroup();

		for (x in 0...cols)
		{
			grid[x] = new Array();
			for (y in 0...rows)
			{
				var bkgrndTile = new FlxSprite(boardX + (x) * cellSize, boardY + (y) * cellSize, "assets/images/BackTile_16.png");
				bkgrndTile.scale.set(cellSize / bkgrndTile.width, cellSize / bkgrndTile.height);
				bkgrndTile.updateHitbox();
				bkgrndTile.color = 0x00303030;
				bkgrndTiles.add(bkgrndTile);

				var gt = GemType.random();

				var g = gemPool.get();
				g.init(boardX + x * cellSize, boardY + y * cellSize, FlxPoint.get(cellSize, cellSize), FlxPoint.get(margin, margin), gemFrames, gt);
				gems.add(g);
				grid[x][y] = g;
			}
		}

		var matches = findAllMatches(this.grid);
		var count = 0;

		while (matches.length > 0 && count < 1000)
		{
			deMatchBoard(grid, matches);
			matches = findAllMatches(this.grid);
			count += 1;
		}

		add(bkgrndTiles);
		add(gems);

		potentialMoves = findPotentialMoves();

		traceBoard(grid, false);
	}

	function traceBoard(board:Array<Array<Gem>>, isId:Bool)
	{
		var deb = "[";
		for (x in 0...board.length)
		{
			deb += "[";
			for (y in 0...board[0].length)
			{
				var g = board[x][y];
				if (board[x][y] != null)
					deb += (isId ? Std.string(g.id) : g.manaType.name) + ", ";
				else
					deb += "-, ";
			}
			deb += "],";
		}
		deb += "]";
		trace("Board");
		trace(deb);
	}

	var selected:GemGrid = null;

	var userSwap:Array<GemGrid> = null;

	var gemMoves:Array<Bool> = null;

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		switch (state)
		{
			case BoardState.Idle:
				updateIdle(elapsed);
			case BoardState.Swapping:
				onGemMovedFinished(() ->
				{
					state = BoardState.Matching;
				});
			case SwappingRevert:
				onGemMovedFinished(() ->
				{
					state = BoardState.Idle;
				});
			default:
			case BoardState.Matching:
				updateMatching(true);
			case Matching_Spell:
				updateMatching(false);
			case BoardState.PostMatch:
				onGemMovedFinished(() ->
				{
					var matches = findAllMatches(this.grid);
					if (matches.length > 0)
						state = BoardState.Matching;
					else
					{
						state = BoardState.EndTurn;
					}
				});
			case EndTurn:
				resetToIdle();
			case BoardState.Shuffle:
				onGemMovedFinished(resetToIdle);
		}

		if (state != previousState)
		{
			onStateChange(state);
			previousState = state;
		}
	}

	public function setState(state:BoardState)
	{
		this.state = state;
	}

	public function handleclick(position:FlxPoint)
	{
		var cell = getCellAtScreenPosition(position);
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

						state = BoardState.Swapping;
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

	function resetToIdle()
	{
		state = BoardState.Idle;
		moveTimer = 0.0;
		shownMatch = false;
		potentialMoves = findPotentialMoves();

		if (potentialMoves.length == 0)
		{
			shuffleBoard();
		}

		if (suggestedGem != null)
		{
			suggestedGem.highlighted = false;
			suggestedGem = null;
		}
	}

	function onGemMovedFinished(callback:() -> Void)
	{
		if (gemMoves.contains(false))
		{
			return;
		}
		else
		{
			callback();
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

	function updateMatching(spellSwap:Bool)
	{
		var matches = findAllMatches(this.grid);

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
			activeMatches = flatMatches.map((m) ->
			{
				return {
					manaType: m.gem.manaType,
					pos: FlxPoint.get(m.gem.x, m.gem.y)
				};
			});

			byColMatches = byColMatches.filter((c) -> c.length > 0);
			byColMatches = byColMatches.map((c) ->
			{
				var temp:Array<GemGrid> = [];

				for (m in c)
				{
					if (temp.filter((t) -> t.y == m.y).length == 0)
						temp.push(m);
				}

				temp.sort((a, b) -> a.y - b.y);
				return temp;
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
							targetPosition: FlxPoint.get(grid[column][0].x, grid[column][uY].y)
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

			var ecByCols = new Array<Array<UpdatedGem>>();
			for (ec in emptyCells)
			{
				if (ecByCols[ec.updated.x] == null)
					ecByCols[ec.updated.x] = [];

				ecByCols[ec.updated.x].push(ec);
			}

			var colFall = new Array<Float>();
			for (i in 0...boardWidth)
			{
				colFall.push(FlxG.random.float(0.32, 0.38) * (1 + (ecByCols[i] != null ? ecByCols[i].length * 0.25 : 0)));
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

			for (col in ecByCols.filter((c) -> c != null))
			{
				col.sort((a, b) -> b.updated.y - a.updated.y);
				var lowestPixY = col[0].targetPosition.y;
				for (ec in col)
				{
					var emptyGem = grid[ec.updated.x][ec.updated.y];

					emptyGem.respawn(ec.targetPosition.x, 0 - lowestPixY, GemType.random());

					grid[ec.updated.x][ec.updated.y] = emptyGem;

					var index = gemMoves.push(false);
					emptyGem.move(ec.targetPosition.x, ec.targetPosition.y, colFall[ec.updated.x], (t) ->
					{
						gemMoves[index - 1] = true;
					}, FlxEase.bounceOut);
				}
			}

			state = BoardState.PostMatch;
		}
		else
		{
			if (spellSwap)
			{
				state = BoardState.EndTurn;
			}
			else
			{
				swapCells(userSwap[0], userSwap[1]);
				userSwap = null;
				state = BoardState.SwappingRevert;
			}
		}
	}

	var shownMatch = false;
	var suggestedGem:Gem = null;

	function updateIdle(elapsed:Float)
	{
		moveTimer += elapsed;

		if (moveTimer > 10 && !shownMatch)
		{
			shownMatch = true;
			var move = potentialMoves[0].move;

			suggestedGem = grid[move.x][move.y];
			suggestedGem.highlighted = true;
		}
	}

	function getCellAtScreenPosition(position:FlxPoint):CellIndex
	{
		var x = position.x - boardX;
		var y = position.y - boardY;

		if (x < 0 || y < 0 || x >= boardWidth * cellSize || y >= boardHeight * cellSize)
		{
			return null;
		}

		return {x: Math.floor(x / cellSize), y: Math.floor(y / cellSize)};
	}

	function findAllMatches(workingGrid:Array<Array<Gem>>):Array<MatchGroup>
	{
		var matches = new Array<MatchGroup>();

		var colMatches = new Array<MatchGroup>();
		var rowMatches = new Array<MatchGroup>();

		for (y in 0...workingGrid[0].length)
		{
			for (m in findMatchesInRow(y))
			{
				rowMatches.push(m);
			}
		}

		for (x in 0...workingGrid.length)
		{
			for (m in findMatchesInColumn(x))
			{
				colMatches.push(m);
			}
		}

		// find overlapping matches

		var rowSubMatches = new Array<MatchGroup>();
		var colSubMatches = new Array<MatchGroup>();

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

					rowSubMatches.push(rowMatch);
					colSubMatches.push(colMatch);
				}
			}
		}

		// remove the submatches
		for (rowMatch in rowSubMatches)
		{
			rowMatches.remove(rowMatch);
		}

		for (colMatch in colSubMatches)
		{
			colMatches.remove(colMatch);
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
		var lastManaType:ManaType = null;
		var matches = new Array<MatchGroup>();
		var workingMatch = new MatchGroup();

		for (x in 0...grid.length)
		{
			var gem = grid[x][y];
			if (gem.manaType == lastManaType)
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
				lastManaType = gem.manaType;
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
		var lastManaType:ManaType = null;
		var matches = new Array<MatchGroup>();
		var workingMatch = new MatchGroup();

		for (y in 0...grid[0].length)
		{
			var gem = grid[x][y];
			if (gem.manaType == lastManaType)
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
				lastManaType = gem.manaType;
			}
		}

		if (workingMatch.length >= 3)
		{
			matches.push(workingMatch);
		}

		return matches;
	}

	function findPotentialMoves(?inGrid:Array<Array<Gem>>):Array<ScoredMatch>
	{
		var moves = new Array<ScoredMatch>();
		var workingGrid = (inGrid == null ? grid : inGrid).copy();

		for (x in 0...workingGrid.length)
		{
			for (y in 0...workingGrid[0].length)
			{
				var possibleMoves:Array<MoveDirection> = getMoves(x, y);
				for (move in possibleMoves)
				{
					var targetX = x;
					var targetY = y;

					switch (move)
					{
						case MoveDirection.Up:
							targetY -= 1;
						case MoveDirection.Down:
							targetY += 1;
						case MoveDirection.Left:
							targetX -= 1;
						case MoveDirection.Right:
							targetX += 1;
					}

					var temp = workingGrid[x][y];
					workingGrid[x][y] = workingGrid[targetX][targetY];
					workingGrid[targetX][targetY] = temp;

					var matches = findAllMatches(workingGrid);
					if (matches.length > 0)
					{
						var isKeyGem = matches.map((match) ->
						{
							var matchGemType = workingGrid[match[0].x][match[0].y].manaType;
							return temp.manaType == matchGemType;
						}).contains(true);

						if (isKeyGem)
						{
							var score = 0;
							for (match in matches)
							{
								score += match.length;
							}

							moves.push({move: {x: x, y: y, direction: move}, matches: matches, score: score});
						}
					}

					temp = workingGrid[x][y];
					workingGrid[x][y] = workingGrid[targetX][targetY];
					workingGrid[targetX][targetY] = temp;
				}
			}
		}

		var collatedMatches = new Array<
			{
				matches:Array<ScoredMatch>,
				score:Int
			}>();

		for (m in moves)
		{
			var mcmGroup = collatedMatches.filter((cm) -> cm.score == m.score);

			if (mcmGroup.length == 0)
			{
				collatedMatches.push({matches: [m], score: m.score});
			}
			else
			{
				mcmGroup[0].matches.push(m);
			}
		}
		collatedMatches.sort((a, b) -> b.score - a.score);

		var sortedMatches = new Array<ScoredMatch>();

		for (cm in collatedMatches)
		{
			FlxG.random.shuffle(cm.matches);
			sortedMatches = sortedMatches.concat(cm.matches);
		}

		return sortedMatches;
	}

	function getMoves(x:Int, y:Int):Array<MoveDirection>
	{
		var possibleMoves = new Array<MoveDirection>();

		if (x > 0)
		{
			possibleMoves.push(MoveDirection.Left);
		}

		if (x < grid.length - 1)
		{
			possibleMoves.push(MoveDirection.Right);
		}

		if (y > 0)
		{
			possibleMoves.push(MoveDirection.Up);
		}

		if (y < grid[0].length - 1)
		{
			possibleMoves.push(MoveDirection.Down);
		}

		return possibleMoves;
	}

	function deMatchBoard(board:Array<Array<Gem>>, matches:Array<MatchGroup>)
	{
		for (m in matches)
		{
			var g = m[Math.floor(m.length / 2)];
			var oId = board[g.x][g.y].manaType;
			board[g.x][g.y].setType(GemType.random([oId]));
		}
	}

	function shuffleBoard()
	{
		var targetGrid = grid.copy();

		var gridSpaces = new Array<CellIndex>();
		var gems = new Array<GemGrid>();

		for (x in 0...targetGrid.length)
		{
			for (y in 0...targetGrid[0].length)
			{
				gridSpaces.push({x: x, y: y});
				gems.push({x: x, y: y, gem: targetGrid[x][y]});
			}
		}

		var potentialMoves = findPotentialMoves();
		var updates = new Array<UpdatedGem>();
		while (potentialMoves.length == 0)
		{
			var workingGems = gems.copy();
			FlxG.random.shuffle(workingGems);

			while (workingGems.length > 0)
			{
				var gem1 = workingGems.pop();
				var gem2 = workingGems.pop();

				var temp = targetGrid[gem1.x][gem1.y];
				targetGrid[gem1.x][gem1.y] = targetGrid[gem2.x][gem2.y];
				targetGrid[gem2.x][gem2.y] = temp;

				updates.push({
					original: {x: gem1.x, y: gem1.y},
					updated: {x: gem2.x, y: gem2.y},
					targetPosition: FlxPoint.get(targetGrid[gem2.x][gem2.y].x, targetGrid[gem2.x][gem2.y].y)
				});

				updates.push({
					original: {x: gem2.x, y: gem2.y},
					updated: {x: gem1.x, y: gem1.y},
					targetPosition: FlxPoint.get(targetGrid[gem1.x][gem1.y].x, targetGrid[gem1.x][gem1.y].y)
				});
			}

			deMatchBoard(targetGrid, findAllMatches(targetGrid));
			potentialMoves = findPotentialMoves(targetGrid);
		}

		for (u in updates)
		{
			var gem = targetGrid[u.original.x][u.original.y];

			var index = gemMoves.push(false);
			gem.move(u.targetPosition.x, u.targetPosition.y, 0.3, (t) ->
			{
				gemMoves[index - 1] = true;
			});
		}

		grid = targetGrid;
		state = BoardState.Shuffle;
	}

	public function doMove(move:ScoredMatch)
	{
		var targetX = move.move.x;
		var targetY = move.move.y;

		var direction = move.move.direction;

		var targetX2 = targetX;
		var targetY2 = targetY;

		switch (direction)
		{
			case MoveDirection.Up:
				targetY2 -= 1;
			case MoveDirection.Down:
				targetY2 += 1;
			case MoveDirection.Left:
				targetX2 -= 1;
			case MoveDirection.Right:
				targetX2 += 1;
		}

		swapCells({x: targetX, y: targetY, gem: grid[targetX][targetY]}, {x: targetX2, y: targetY2, gem: grid[targetX2][targetY2]});

		state = BoardState.Swapping;
	}

	public function getRandomGem(notTypes:Array<ManaType>):Gem
	{
		var flatGrid:Array<Gem> = [];
		for (x in 0...grid.length)
		{
			for (y in 0...grid[0].length)
			{
				flatGrid.push(grid[x][y]);
			}
		}

		var workingGrid = flatGrid.filter((g) -> !notTypes.contains(g.manaType));
		FlxG.random.shuffle(workingGrid);

		return workingGrid[0];
	}
}
