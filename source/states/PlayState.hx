package states;

import entities.Character;
import entities.Gem.ManaType;
import entities.PlayBoard;
import entities.Sidebar;
import flixel.FlxG;
import flixel.FlxState;

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

	override public function create()
	{
		super.create();
		FlxG.mouse.visible = true;
		FlxG.camera.antialiasing = true;

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

		makePlayer();
		makeAi();

		playerSidebar = new Sidebar(player, true);
		add(playerSidebar);
		aiSidebar = new Sidebar(ai, false);
		add(aiSidebar);
	}

	function makePlayer()
	{
		player = new Character();
		player.name = "Player";
		player.portrait = "";
		player.level = 1;
		player.maxHealth = 20;
		player.health = 20;
		player.maxMana = new Map();
		player.maxMana.set(ManaType.FIRE, 30);
		player.maxMana.set(ManaType.WATER, 25);
		player.maxMana.set(ManaType.EARTH, 20);
		player.maxMana.set(ManaType.AIR, 15);
		player.maxMana.set(ManaType.LIGHT, 25);
		player.maxMana.set(ManaType.DARK, 15);
		player.mana = new Map();
		player.mana.set(ManaType.FIRE, 0);
		player.mana.set(ManaType.WATER, 0);
		player.mana.set(ManaType.EARTH, 0);
		player.mana.set(ManaType.AIR, 0);
		player.mana.set(ManaType.LIGHT, 0);
		player.mana.set(ManaType.DARK, 0);

		player.spells = new Array();
		player.spells.push(new Spell("Fireball", "Deals 5 damage to target enemy", [ManaType.FIRE => 5, ManaType.DARK => 2], (e, s, b) ->
		{
			e.health -= 5;
		}));
		player.spells.push(new Spell("Heal", "Heals 5 health", [ManaType.WATER => 5], (e, s, b) ->
		{
			e.health += 5;
		}));
	}

	function makeAi()
	{
		ai = new Character();
		ai.name = "AI";
		ai.portrait = "";
		ai.level = 1;
		ai.maxHealth = 20;
		ai.health = 20;
		ai.maxMana = new Map();
		ai.maxMana.set(ManaType.FIRE, 30);
		ai.maxMana.set(ManaType.WATER, 25);
		ai.maxMana.set(ManaType.EARTH, 20);
		ai.maxMana.set(ManaType.AIR, 15);
		ai.maxMana.set(ManaType.LIGHT, 25);
		ai.maxMana.set(ManaType.DARK, 15);
		ai.mana = new Map();
		ai.mana.set(ManaType.FIRE, 0);
		ai.mana.set(ManaType.WATER, 0);
		ai.mana.set(ManaType.EARTH, 0);
		ai.mana.set(ManaType.AIR, 0);
		ai.mana.set(ManaType.LIGHT, 0);
		ai.mana.set(ManaType.DARK, 0);

		ai.spells = new Array();
		ai.spells.push(new Spell("Decimate", "Take 1/10th of health, shields and mana", [ManaType.LIGHT => 15, ManaType.DARK => 15], (e, s, b) ->
		{
			e.health -= 5;
		}));
		// ai.spells.push(new Spell("Heal", "Heals 5 health", [ManaType.WATER => 5], (e, s, b) ->
		// {
		// 	e.health += 5;
		// }));
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
