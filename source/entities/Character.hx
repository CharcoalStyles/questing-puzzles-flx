package entities;

import entities.Gem.ManaType;

class Character
{
	public var name:String;
	public var portrait:String;
	public var level:Int;
	public var maxHealth:Int;
	public var health:Int;
	public var maxMana:Map<ManaType, Int>;
	public var mana:Map<ManaType, Int>;
	public var spells:Array<Spell>;

	public function new() {}
}

class Spell
{
	public var name:String;
	public var description:String;
	public var manaCosts:Map<ManaType, Int>;
	public var effect:(enemy:Character, self:Character, board:PlayBoard) -> Void;

	public function new(n:String, d:String, mc:Map<ManaType, Int>, e:(enemy:Character, self:Character, board:PlayBoard) -> Void)
	{
		name = n;
		description = d;
		manaCosts = mc;
		effect = e;
	}
}
