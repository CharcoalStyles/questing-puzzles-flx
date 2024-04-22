package states;

import entities.Character;
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
				case State.SwappingRevert:
					isPlayerTurnNext = true;
				case State.PostMatch:
					postMatchUpdateOnce();
				default:
			}
			timer = 0;
		}

		playerSidebar = new Sidebar(globalState.player, true);
		add(playerSidebar);
		aiSidebar = new Sidebar(globalState.ai, false);
		add(aiSidebar);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

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
				board.handleclick(FlxG.mouse.x, FlxG.mouse.y);
				isPlayerTurnNext = false;
				timer = 0;
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
