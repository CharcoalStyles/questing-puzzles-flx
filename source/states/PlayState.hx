package states;

import entities.Character;
import entities.Gem.GemType;
import entities.Gem.ManaType;
import entities.PlayBoard;
import entities.Sidebar;
import flixel.FlxG;
import flixel.FlxState;
import utils.GlobalState;

class PlayState extends FlxState
{
	var board:PlayBoard;

	var isPlayerTurn:Bool = true;
	var isPlayerTurnNext:Bool = false;
	var firstTurn:Bool = true;

	var timer:Float = 0;
	var triggerTime:Float = 1.5;

	var currentState:State = State.Idle;

	var playerSidebar:Sidebar;
	var aiSidebar:Sidebar;

	var player:Character;
	var ai:Character;
	var globalState:GlobalState;

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
			currentState = state;
			switch (state)
			{
				case State.Idle:
					isPlayerTurn = isPlayerTurnNext;
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
				case State.SwappingRevert:
					isPlayerTurnNext = true;
				case State.PostMatch:
					postMatchUpdateOnce();
				default:
			}
			timer = 0;
		}

		playerSidebar = new Sidebar(globalState.player, true);
		playerSidebar.isActive = true;
		add(playerSidebar);
		aiSidebar = new Sidebar(globalState.ai, false);
		add(aiSidebar);

		globalState.createEmitter();
		add(globalState.emitter.activeMembers);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if (FlxG.keys.justPressed.ESCAPE)
		{
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
			case State.Idle:
				idleUpdate(elapsed);
			case State.Matching:
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
					var spell = playerSidebar.handleClick(mousePos);
					if (spell != null)
					{
						spell.run(globalState.ai, globalState.player, board);
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
		var am = board.activeMatches;
		for (g in am)
		{
			sb.addMana(g.manaType, 1, g.pos);
		}
	}
}
