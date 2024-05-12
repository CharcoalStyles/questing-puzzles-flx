package utils;

import entities.Character;
import entities.Gem.GemType;
import entities.Gem.ManaType;
import entities.effects.CsEmitter;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.math.FlxPoint;
import haxe.Timer;
import states.PlayState.Play_State;
import utils.Observer.FloatObservable;
import utils.Observer.IntObservable;

var nextState = [Play_State.Idle, Play_State.BoardMatching];

class GlobalState extends FlxBasic
{
	public var isUsingController:Bool = false;
	public var controllerId:Int = 0;
	public var player:Character;
	public var ai:Character;
	public var emitter:CsEmitter;

	public function new()
	{
		super();
		emitter = new CsEmitter();
		makePlayer();
		makeAi();
	}

	public function createEmitter()
	{
		emitter = new CsEmitter();
	}

	function makePlayer()
	{
		player = new Character();
		player.name = "Player";
		player.portrait = "";
		player.level = 1;
		player.maxHealth = 20;
		player.health = new IntObservable(20);
		player.maxMana = new Map();
		player.maxMana.set(ManaType.FIRE, 30);
		player.maxMana.set(ManaType.WATER, 25);
		player.maxMana.set(ManaType.EARTH, 20);
		player.maxMana.set(ManaType.AIR, 15);
		player.maxMana.set(ManaType.LIGHT, 25);
		player.maxMana.set(ManaType.DARK, 15);
		player.mana = new Map();
		player.mana.set(ManaType.FIRE, new FloatObservable(0));
		player.mana.set(ManaType.WATER, new FloatObservable(0));
		player.mana.set(ManaType.EARTH, new FloatObservable(0));
		player.mana.set(ManaType.AIR, new FloatObservable(0));
		player.mana.set(ManaType.LIGHT, new FloatObservable(0));
		player.mana.set(ManaType.DARK, new FloatObservable(0));

		player.spells = new Array();
		player.spells.push(Loader.loadSpell("Fireball"));
		player.spells.push(Loader.loadSpell("Heal5"));
		player.spells.push(Loader.loadSpell("Warcry"));

		player.spells.push(new Spell("Light 'em up!", "Randomly sets 7 gems to Fire", [ManaType.LIGHT => 5, ManaType.DARK => 5], (e, s, b) ->
		{
			var gems = [for (i in 0...7) b.getRandomGem([ManaType.FIRE])];
			for (i in 0...gems.length)
			{
				Timer.delay(() ->
				{
					var gem = gems[i];
					gem.setType(GemType.RED);
					for (i in 0...50)
					{
						var p = emitter.emit(gem.x + gem.width / 2, gem.y + gem.height / 2);

						var effect = CsEmitter.burstEmit(GemType.RED.colour, 300, {
							scaleExtended: () -> [
								{
									t: 0,
									value: FlxPoint.get(1.2, 1.2),
								},
								{
									t: 1,
									value: FlxPoint.get(0.5, 0.5),
								}
							],
							angularVelocityExtended: () -> [
								{
									t: 0,
									value: FlxG.random.float(45, 90),
								},
								{
									t: 1,
									value: FlxG.random.float(4.5, 9),
								}
							]
						});

						p.setEffectStates([effect]);
					}
				}, i * 250);
			}
			return {
				delay: (gems.length + 1) * 250,
				nextState: Play_State.BoardMatching
			};
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
		ai.mana.set(ManaType.FIRE, new FloatObservable(5));
		ai.mana.set(ManaType.WATER, new FloatObservable(0));
		ai.mana.set(ManaType.EARTH, new FloatObservable(0));
		ai.mana.set(ManaType.AIR, new FloatObservable(0));
		ai.mana.set(ManaType.LIGHT, new FloatObservable(0));
		ai.mana.set(ManaType.DARK, new FloatObservable(0));

		ai.spells = new Array();
		ai.spells.push(Loader.loadSpell("ThrowRock"));
		ai.spells.push(Loader.loadSpell("Warcry"));
	}
}
