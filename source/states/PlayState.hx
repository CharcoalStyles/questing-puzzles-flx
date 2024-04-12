package states;

import entities.PlayBoard.State;
import entities.PlayBoard;
import flixel.FlxG;
import flixel.FlxState;

class PlayState extends FlxState
{
	var board:PlayBoard;

	var isPlayerTurn:Bool = false;

	override public function create()
	{
		super.create();
		FlxG.mouse.visible = true;
		FlxG.camera.antialiasing = true;

		board = new PlayBoard(8, 8); // var rows = 8;
		add(board);

		board.onStateChange = (state) ->
		{
			FlxG.log.add("State changed to: " + state);
			switch (state)
			{
				case State.Idle:
					var match = board.potentialMoves[0];
					if (match != null)
					{
						board.doMove(match);
					}
				default:
					isPlayerTurn = false;
			}
		}
	}

	override public function update(elapsed:Float)
	{
		if (FlxG.mouse.justPressed)
		{
			board.handleclick(FlxG.mouse.x, FlxG.mouse.y);
		}
		super.update(elapsed);
	}
}
