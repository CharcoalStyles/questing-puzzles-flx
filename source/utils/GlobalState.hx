package utils;

import entities.Character;
import entities.Gem.GemType;
import entities.Gem.ManaType;
import flixel.FlxBasic;
import flixel.FlxG;
import utils.Observer.FloatObservable;
import utils.Observer.IntObservable;

class GlobalState extends FlxBasic
{
	public var isUsingController:Bool = false;
	public var controllerId:Int = 0;
	public var player:Character;
	public var ai:Character;

	public function new()
	{
		super();
		makePlayer();
		makeAi();
	}

	function makePlayer()
	{
		player = new Character();
		player.name = "Player";
		player.portrait = "";
		player.level = 1;
		player.maxHealth = 20;
		player.health = new IntObservable(15);
		player.maxMana = new Map();
		player.maxMana.set(ManaType.FIRE, 30);
		player.maxMana.set(ManaType.WATER, 25);
		player.maxMana.set(ManaType.EARTH, 20);
		player.maxMana.set(ManaType.AIR, 15);
		player.maxMana.set(ManaType.LIGHT, 25);
		player.maxMana.set(ManaType.DARK, 15);
		player.mana = new Map();
		player.mana.set(ManaType.FIRE, new FloatObservable(0));
		player.mana.set(ManaType.WATER, new FloatObservable(5));
		player.mana.set(ManaType.EARTH, new FloatObservable(0));
		player.mana.set(ManaType.AIR, new FloatObservable(0));
		player.mana.set(ManaType.LIGHT, new FloatObservable(0));
		player.mana.set(ManaType.DARK, new FloatObservable(0));

		player.spells = new Array();
		player.spells.push(new Spell("Fireball", "Deals 5 damage to target enemy", [ManaType.FIRE => 5, ManaType.DARK => 2], (e, s, b) ->
		{
			e.health -= 5;
		}));
		player.spells.push(new Spell("Heal", "Heals 5 health", [ManaType.WATER => 5], (e, s, b) ->
		{
			s.health.set((s.health + 5) > s.maxHealth ? s.maxHealth : s.health + 5);
		}));
		player.spells.push(new Spell("Light 'em up!", "Randomly sets 7 gems to Fire", [ManaType.LIGHT => 5, ManaType.DARK => 5], (e, s, b) ->
		{
			for (i in 0...7)
			{
				var gem = b.getRandomGem([FIRE]);
				gem.setType(GemType.RED);
			}
		}));
	}

	function makeAi()
	{
		ai = new Character();
		ai.name = "Goblin";
		ai.portrait = "";
		ai.level = 1;
		ai.maxHealth = 20;
		ai.health = new IntObservable(20);
		ai.maxMana = new Map();
		ai.maxMana.set(ManaType.FIRE, 30);
		ai.maxMana.set(ManaType.WATER, 25);
		ai.maxMana.set(ManaType.EARTH, 20);
		ai.maxMana.set(ManaType.AIR, 15);
		ai.maxMana.set(ManaType.LIGHT, 25);
		ai.maxMana.set(ManaType.DARK, 15);
		ai.mana = new Map();
		ai.mana.set(ManaType.FIRE, new FloatObservable(0));
		ai.mana.set(ManaType.WATER, new FloatObservable(0));
		ai.mana.set(ManaType.EARTH, new FloatObservable(0));
		ai.mana.set(ManaType.AIR, new FloatObservable(0));
		ai.mana.set(ManaType.LIGHT, new FloatObservable(0));
		ai.mana.set(ManaType.DARK, new FloatObservable(0));

		ai.spells = new Array();
		ai.spells.push(new Spell("Throw Rock", "It's a little pointy. Deals 2 damage.", [ManaType.FIRE => 2, ManaType.DARK => 2], (e, s, b) ->
		{
			e.health -= 2;
		}));
		ai.spells.push(new Spell("Warcry", "The noise isn't scary, but it's breath is. Removes 2 from all mana.",
			[ManaType.FIRE => 2, ManaType.LIGHT => 2, ManaType.WATER => 2], (e, s, b) ->
			{
				for (m in e.mana.keys())
				{
					if (e.mana.get(m).get() > 2)
						e.mana.get(m).sub(2);
					else
						e.mana.get(m).set(0);
				}
			}));
	}
}
