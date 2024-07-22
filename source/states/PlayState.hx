package states;

import csHxUtils.CsMath;
import csHxUtils.entities.CsEmitter;
import csHxUtils.entities.SplitText;
import entities.Character;
import entities.Gem.GemType;
import entities.PlayBoard;
import entities.Sidebar;
import flixel.FlxG;
import flixel.FlxState;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import haxe.Timer;
import states.subStates.PauseState;
import utils.GlobalState;
import utils.Loader;

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
	var enemySidebar:Sidebar;

	var player:Character;
	var enemy:Character;
	var globalState:GlobalState;

	var extraTurnText:SplitText;
	var extraManaText:SplitText;

	var winText:SplitText;
	var loseText:SplitText;
	var continueText:FlxText;

	public function new(enemyfileName:String)
	{
		super();
		var enemyData = Loader.loadCharacterFromFile(enemyfileName);
		enemy = new Character(enemyData);
	}

	override public function create()
	{
		super.create();
		FlxG.mouse.visible = true;
		FlxG.camera.antialiasing = true;

		globalState = FlxG.plugins.get(GlobalState);
		globalState.player.reset();

		board = new PlayBoard(8, 8); // var rows = 8;
		add(board);

		board.onStateChange = (state) ->
		{
			currentBoardState = state;
			switch (state)
			{
				case BoardState.Idle:
					setState(Idle);
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

		enemySidebar = new Sidebar(enemy, false);
		add(enemySidebar);
		enemy.sidebar = enemySidebar;

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
		winText.borderColor = 0xff000000;
		winText.borderSize = 2;
		winText.borderStyle = FlxTextBorderStyle.OUTLINE;
		winText.alpha = 0;
		add(winText);

		loseText = new SplitText(0, 0, "You Lose!", SplitText.naiieveScaleDefaultOptions(2.2));
		loseText.x = (FlxG.width - loseText.width) / 2;
		loseText.y = FlxG.height / 2;
		loseText.borderColor = 0xff000000;
		loseText.borderSize = 2;
		loseText.borderStyle = FlxTextBorderStyle.OUTLINE;
		loseText.alpha = 0;
		add(loseText);

		continueText = new FlxText(0, FlxG.height - 32, 0, "Press any key to continue", 32);
		continueText.x = (FlxG.width - continueText.width) / 2;
		continueText.y = FlxG.height - 128;
		continueText.borderColor = 0xff000000;
		continueText.borderSize = 2;
		continueText.borderStyle = FlxTextBorderStyle.OUTLINE;
		continueText.alpha = 0;
		add(continueText);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.ONE)
		{
			for (gt in GemType.ALL)
			{
				FlxG.log.add("Player Mana: " + globalState.player.mana.get(gt.manaType).get() + " (" + gt.manaType + ")");
			}
		}

		var mousePos = FlxG.mouse.getPosition();
		playerSidebar.handleHover(mousePos);
		enemySidebar.handleHover(mousePos);

		switch (currentState)
		{
			case Play_State.Idle:
				idleUpdate(elapsed);
			case Play_State.GameOver:
				if (FlxG.keys.justPressed.ANY || FlxG.mouse.justPressed)
				{
					globalState.player.clearObservers();
					enemy.clearObservers();
					FlxG.switchState(new MainMenuState());
				}
			default:
		}

		if (FlxG.keys.justPressed.ESCAPE)
		{
			this.subState = new PauseState(globalState.controllerId);
			this.subState.create();
			this.subState.closeCallback = () ->
			{
				this.subState = null;
			}
		}
	}

	function setState(state:Play_State)
	{
		var realState = state;
		switch (state)
		{
			case Play_State.Idle:
				isPlayerTurn = isPlayerTurnNext;

				if (isPlayerTurn)
				{
					playerSidebar.isActive = true;
					enemySidebar.isActive = false;
				}
				else
				{
					playerSidebar.isActive = false;
					enemySidebar.isActive = true;
				}

				if (enemy.health <= 0)
				{
					winText.animateWave(64, 0.3, 2.0, false);
					winText.animateColour(0xff36cb4a, 0.3, 2.0, 0x00FFFFFF, true);
					realState = Play_State.GameOver;
					Timer.delay(() ->
					{
						FlxTween.tween(continueText, {alpha: 1}, 0.5);
					}, 1000);
				}
				if (globalState.player.health <= 0)
				{
					loseText.animateWave(64, 0.3, 2.0, false);
					loseText.animateColour(0xffe24f4f, 0.3, 2.0, 0x00FFFFFF, true);
					realState = Play_State.GameOver;
					Timer.delay(() ->
					{
						FlxTween.tween(continueText, {alpha: 1}, 0.5);
					}, 1000);
				}
			case Play_State.BoardMatching:
			case Play_State.SpellEffect:
			case Play_State.GameOver:
		}

		currentState = realState;
	}

	function idleUpdate(elapsed:Float)
	{
		var mousePos = FlxG.mouse.getPosition();

		if (isPlayerTurn)
		{
			if (FlxG.mouse.justPressed)
			{
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
						var nextState = spell.run(enemy, globalState.player, board);

						FlxTimer.wait(nextState.delay, () ->
						{
							if (nextState.endTurn)
							{
								isPlayerTurnNext = false;
							}
							if (nextState.nextState == Play_State.BoardMatching)
							{
								board.setState(BoardState.Matching_Spell);
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
				else if (enemySidebar.isPointInside(FlxG.mouse.getPosition())) {}
			}
		}
		else
		{
			timer += elapsed;
			if (timer >= triggerTime)
			{
				var availableSpells = [];
				for (spellUi in enemy.sidebar.spellUis)
				{
					if (spellUi.isActivated)
					{
						availableSpells.push(spellUi.spell);
					}
				}

				if (availableSpells.length > 0 && FlxG.random.int(0, 9) <= enemy.level + 1)
				{
					setState(Play_State.SpellEffect);
					var spell = availableSpells[FlxG.random.int(0, availableSpells.length - 1)];
					var nextState = spell.run(globalState.player, enemy, board);

					FlxTimer.wait(nextState.delay, () ->
					{
						if (nextState.endTurn)
						{
							isPlayerTurnNext = true;
						}
						if (nextState.nextState == Play_State.BoardMatching)
						{
							board.setState(BoardState.Matching_Spell);
						}
						else
						{
							setState(nextState.nextState);
						}
					});
					return;
				}

				var matchIndex = board.potentialMoves.length == 1 ? 0 : FlxG.random.int(1, Math.floor(Math.min(board.potentialMoves.length - 1, 4)));
				var match = board.potentialMoves[matchIndex];
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
		var sb = isPlayerTurn ? playerSidebar : enemySidebar;

		var maxLength = 0;
		for (match in board.activeMatches)
		{
			maxLength = Std.int(Math.max(maxLength, match.count));

			var manaBonus = Std.int(Math.max(0, match.count - 4)); // adds an extra mana per gem when a match is longer than 4

			for (gemPos in match.pos)
			{
				if (match.manaType == null)
				{
					var enemy = isPlayerTurn ? enemy : globalState.player;

					var healthText = CsMath.centreRect(enemy.sidebar.healthText.getScreenBounds());
					var p = globalState.emitter.emit(gemPos.x, gemPos.y);
					var pSize = FlxPoint.get(1.75, 1.75);
					p.setEffectStates([
						{
							lifespan: () -> FlxG.random.float(0.75, 0.5),
							target: (particle) -> {
								origin: FlxPoint.get(gemPos.x, gemPos.y),
								target: FlxPoint.get(healthText.x, healthText.y),
								easeName: "cubeIn"
							},
							scaleExtended: () -> [
								{t: 0, value: pSize},
								{t: 0.7, value: pSize.scaleNew(0.7)},
								{t: 1, value: pSize.scaleNew(0.1)}
							],
							onComplete: (particle) ->
							{
								if (enemy.health > 0)
								{
									enemy.health.set(enemy.health - 1);
								}
							}
						}
					]);
				}
				else
				{
					sb.addMana(match.manaType, 1 + manaBonus, gemPos);
				}
			}
		}

		if (maxLength >= 4)
		{
			var timeLength = 0.7;
			var perLetter = 0.02;

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
