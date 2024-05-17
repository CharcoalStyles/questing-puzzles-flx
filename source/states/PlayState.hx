package states;

import entities.Character;
import entities.Gem.GemType;
import entities.PlayBoard;
import entities.Sidebar;
import flixel.FlxG;
import flixel.FlxState;
import flixel.util.FlxTimer;
import utils.GlobalState;
import utils.SplitText;

enum Play_State
{
	Idle;
	BoardMatching;
	SpellEffect;
}

class PlayState extends FlxState
{
	var board:PlayBoard;

	var isPlayerTurn:Bool = true;
	var isPlayerTurnNext:Bool = false;
	var firstTurn:Bool = true;

	var timer:Float = 0;
	var triggerTime:Float = 1.5;

	var currentState:Play_State = Idle;
	var currentBoardState:BoardState = BoardState.Idle;

	var playerSidebar:Sidebar;
	var aiSidebar:Sidebar;

	var player:Character;
	var ai:Character;
	var globalState:GlobalState;

	var extraTurnText:SplitText;
	var extraManaText:SplitText;

	override public function create()
	{
		super.create();
		FlxG.mouse.visible = true;
		FlxG.camera.antialiasing = true;

		globalState = FlxG.plugins.get(GlobalState);

		board = new PlayBoard(8, 8); // var rows = 8;
		add(board);

		board.onStateChange = (state) ->
		{
			currentBoardState = state;
			switch (state)
			{
				case BoardState.Idle:
					if (currentState == SpellEffect)
					{
						// reset the game state after the board has finished matching
						currentState = Idle;
					}
					else
					{
						isPlayerTurn = isPlayerTurnNext;
					}

					if (isPlayerTurn)
					{
						playerSidebar.isActive = true;
						aiSidebar.isActive = false;
					}
					else
					{
						playerSidebar.isActive = false;
						aiSidebar.isActive = true;
					}
				case BoardState.SwappingRevert:
					isPlayerTurnNext = true;
				case BoardState.PostMatch:
					postMatchUpdateOnce();
				case BoardState.EndTurn:
					state = Idle;
				default:
			}
			timer = 0;
		}

		playerSidebar = new Sidebar(globalState.player, true);
		playerSidebar.isActive = true;
		add(playerSidebar);
		globalState.player.sidebar = playerSidebar;

		aiSidebar = new Sidebar(globalState.ai, false);
		add(aiSidebar);
		globalState.ai.sidebar = aiSidebar;

		globalState.createEmitter();
		add(globalState.emitter.activeMembers);

		extraTurnText = new SplitText(0, 0, "Extra Turn!");
		extraTurnText.x = (FlxG.width - extraTurnText.width) / 2;
		extraTurnText.y = FlxG.height / 2 + 128;
		extraTurnText.alpha = 0;
		add(extraTurnText);
		extraManaText = new SplitText(0, 0, "Extra Mana!");
		extraManaText.x = (FlxG.width - extraManaText.width) / 2;
		extraManaText.y = FlxG.height / 2 - 128;
		extraManaText.alpha = 0;
		add(extraManaText);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if (FlxG.keys.justPressed.ESCAPE)
		{
			globalState.player.clearObservers();
			globalState.ai.clearObservers();
			FlxG.switchState(new MainMenuState());
		}

		if (FlxG.keys.justPressed.ONE)
		{
			for (gt in GemType.ALL)
			{
				FlxG.log.add("Player Mana: " + globalState.player.mana.get(gt.manaType).get() + " (" + gt.manaType + ")");
			}
		}

		switch (currentState)
		{
			case Play_State.Idle:
				idleUpdate(elapsed);
			default:
		}
	}

	function idleUpdate(elapsed:Float)
	{
		if (isPlayerTurn)
		{
			if (FlxG.mouse.justPressed)
			{
				var mousePos = FlxG.mouse.getPosition();
				if (board.isPointInside(mousePos))
				{
					board.handleclick(mousePos);
					isPlayerTurnNext = false;
					timer = 0;
				}
				else if (playerSidebar.isPointInside(FlxG.mouse.getPosition()))
				{
					currentState = Play_State.SpellEffect;

					var spell = playerSidebar.handleClick(mousePos);
					if (spell != null)
					{
						var nextState = spell.run(globalState.ai, globalState.player, board);

						FlxTimer.wait(nextState.delay, () ->
						{
							if (nextState.nextState == Play_State.BoardMatching)
							{
								board.setState(BoardState.Matching);
							}
							else
							{
								currentState = nextState.nextState;
							}
						});
					}
					else
					{
						currentState = Play_State.Idle;
					}
				}
				else if (aiSidebar.isPointInside(FlxG.mouse.getPosition())) {}
			}
		}
		else
		{
			timer += elapsed;
			if (timer >= triggerTime)
			{
				var match = board.potentialMoves[0];
				if (match != null)
				{
					board.doMove(match);
					isPlayerTurnNext = true;
					timer = 0;
				}
			}
		}
	}

	function postMatchUpdateOnce()
	{
		var sb = isPlayerTurn ? playerSidebar : aiSidebar;

		var maxLength = 0;
		for (match in board.activeMatches)
		{
			maxLength = Std.int(Math.max(maxLength, match.count));

			var manaBonus = Std.int(Math.max(0, match.count - 4)); // adds an extra mana per gem when a match is longer than 4

			for (gemPos in match.pos)
			{
				sb.addMana(match.manaType, 1 + manaBonus, gemPos);
			}
		}

		if (maxLength >= 4)
		{
			var timeLength = 1.75;
			var perLetter = 0.08;

			isPlayerTurnNext = isPlayerTurn;
			extraTurnText.animateWave(64, perLetter, timeLength, true);
			extraTurnText.animateColour(0xFFFFFFFF, perLetter, timeLength, 0x00ffffff);

			if (maxLength >= 5)
			{
				extraManaText.animateWave(64, perLetter, timeLength, true);
				extraManaText.animateColour(0xFFFFFFFF, perLetter, timeLength, 0x00ffffff);
			}
		}
	}
}
