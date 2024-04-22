package entities;

import entities.Gem.ManaType;
import utils.Observer.FloatObservable;
import utils.Observer.IntObservable;

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

	public function new() {}

	public function clearObservers():Void
	{
		health.clearObservers();
		for (manaType in mana.keys())
		{
			mana[manaType].clearObservers();
		}
	}
}

class Spell
{
	public var name:String;
	public var description:String;
	public var manaCosts:Map<ManaType, FloatObservable>;

	private var effect:(enemy:Character, self:Character, board:PlayBoard) -> Void;

	public function new(n:String, d:String, mc:Map<ManaType, Int>, e:(enemy:Character, self:Character, board:PlayBoard) -> Void)
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

	public function run(enemy:Character, self:Character, board:PlayBoard):Void
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
			return;
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

		effect(enemy, self, board);
	}
}
