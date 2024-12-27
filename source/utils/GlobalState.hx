package utils;

import csHxUtils.Observer.FloatObservable;
import csHxUtils.Observer.IntObservable;
import csHxUtils.entities.CsEmitter;
import entities.Character;
import entities.Gem.ManaType;
import flixel.FlxBasic;
import states.PlayState.Play_State;

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
		player.maxMana.set(ManaType.LIGHT, 25);
		player.maxMana.set(ManaType.DARK, 15);
		player.mana = new Map();
		player.mana.set(ManaType.FIRE, new FloatObservable(0));
		player.mana.set(ManaType.WATER, new FloatObservable(0));
		player.mana.set(ManaType.EARTH, new FloatObservable(0));
		player.mana.set(ManaType.LIGHT, new FloatObservable(0));
		player.mana.set(ManaType.DARK, new FloatObservable(0));

		player.spells = new Array();
		player.spells.push(Loader.loadSpell("Fireball"));
		player.spells.push(Loader.loadSpell("Heal_5"));
		player.spells.push(Loader.loadSpell("Light_Em_Up"));
	}
}
