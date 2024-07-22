package entities;

import csHxUtils.Observer.FloatObservable;
import csHxUtils.Observer.IntObservable;
import entities.Gem.ManaType;
import states.PlayState.Play_State;
import utils.Loader.CharacterStruct;
import utils.Loader;

class Character
{
	public var name:String;
	public var portrait:String;
	public var level:Int;
	public var maxHealth:Int;
	public var health:IntObservable = new IntObservable(0);
	public var maxMana:Map<ManaType, Int>;
	public var mana:Map<ManaType, FloatObservable>;
	public var spells:Array<Spell>;

	public var sidebar:Sidebar;

	public function new(?characterData:CharacterStruct)
	{
		if (characterData == null)
		{
			return;
		}

		name = characterData.name;
		// char.portrait = characterData.portrait;
		level = characterData.level;
		maxHealth = characterData.health;
		health = new IntObservable(characterData.health);
		maxMana = new Map();
		mana = new Map();
		for (mt in characterData.mana.keys())
		{
			var manaType = ManaType.fromString(mt);
			if (manaType == null)
			{
				throw "Invalid mana type: " + mt;
			}

			maxMana.set(manaType, characterData.mana.get(mt));
			mana.set(manaType, new FloatObservable(0));
		}

		spells = characterData.spells.map((name) -> Loader.loadSpell(name));
	}

	public function reset()
	{
		health.set(maxHealth);
		for (manaType in mana.keys())
		{
			mana[manaType].set(0);
		}
	}

	public function clearObservers():Void
	{
		health.clearObservers();
		for (manaType in mana.keys())
		{
			mana[manaType].clearObservers();
		}
	}
}

typedef SpellEffect = (enemy:Character, self:Character, board:PlayBoard) -> {
	delay: Float,
	nextState: Play_State,
	endTurn: Bool
};

class Spell
{
	public var name:String;
	public var description:String;
	public var manaCosts:Map<ManaType, FloatObservable>;

	private var effect:SpellEffect;

	public function new(n:String, d:String, mc:Map<ManaType, Int>, e:SpellEffect)
	{
		name = n;
		description = d;
		manaCosts = [];
		for (manaType in mc.keys())
		{
			manaCosts[manaType] = new FloatObservable(mc[manaType]);
		}
		effect = e;
	}

	public function run(enemy:Character, self:Character, board:PlayBoard):
		{
			delay:Float,
			nextState:Play_State,
			endTurn:Bool
		}
	{
		var valid = true;
		for (manaType in manaCosts.keys())
		{
			var manaRequired:Float = manaCosts[manaType] == null ? -1 : manaCosts[manaType].get();
			var manaAvailable:Float = self.mana[manaType] == null ? -1 : self.mana[manaType].get();

			if (manaAvailable != -1 && manaRequired != -1)
			{
				if (manaAvailable < manaRequired)
				{
					valid = false;
					break;
				}
			}
		}

		if (!valid)
		{
			return {
				delay: 0,
				nextState: Play_State.Idle,
				endTurn: false
			};
		}

		for (manaType in manaCosts.keys())
		{
			var manaRequired:Float = manaCosts[manaType] == null ? -1 : manaCosts[manaType].get();
			var thisMana:FloatObservable = self.mana[manaType];
			if (manaRequired != -1)
			{
				thisMana -= manaRequired;
			}
		}

		return effect(enemy, self, board);
	}
}
