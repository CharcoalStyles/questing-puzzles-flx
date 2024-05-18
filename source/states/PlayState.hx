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
	GameOver;
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

	var winText:SplitText;
	var loseText:SplitText;

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
						setState(Idle);
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

		winText = new SplitText(0, 0, "You Win!", SplitText.naiieveScaleDefaultOptions(2.2));
		winText.x = (FlxG.width - winText.width) / 2;
		winText.y = FlxG.height / 2;
		winText.alpha = 0;
		add(winText);

		loseText = new SplitText(0, 0, "You Lose!", SplitText.naiieveScaleDefaultOptions(2.2));
		loseText.x = (FlxG.width - loseText.width) / 2;
		loseText.y = FlxG.height / 2;
		loseText.alpha = 0;
		add(loseText);
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

	function setState(state:Play_State)
	{
		var realState = state;
		switch (state)
		{
			case Play_State.Idle:
				if (globalState.ai.health <= 0)
				{
					winText.animateWave(64, 0.3, 2.0, false);
					winText.animateColour(0xff40e090, 0.3, 2.0, 0x00FFFFFF, true);
					realState = Play_State.GameOver;
				}
				if (globalState.player.health <= 0)
				{
					loseText.animateWave(64, 0.3, 2.0, false);
					loseText.animateColour(0xffff6060, 0.3, 2.0, 0x00FFFFFF, true);
					realState = Play_State.GameOver;
				}
			case Play_State.BoardMatching:
			case Play_State.SpellEffect:
			case Play_State.GameOver:
		}

		currentState = realState;
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
					setState(Play_State.SpellEffect);

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
								setState(nextState.nextState);
							}
						});
					}
					else
					{
						setState(Play_State.Idle);
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
				var availableSpells = [];
				for (spellUi in globalState.ai.sidebar.spellUis)
				{
					if (spellUi.isActivated)
					{
						availableSpells.push(spellUi.spell);
					}
				}

				if (availableSpells.length > 0 && FlxG.random.int(0, 9) <= globalState.ai.level + 1)
				{
					setState(Play_State.SpellEffect);
					var spell = availableSpells[FlxG.random.int(0, availableSpells.length - 1)];
					var nextState = spell.run(globalState.player, globalState.ai, board);

					FlxTimer.wait(nextState.delay, () ->
					{
						if (nextState.nextState == Play_State.BoardMatching)
						{
							board.setState(BoardState.Matching);
						}
						else
						{
							setState(nextState.nextState);
						}
					});
					return;
				}

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
