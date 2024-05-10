package utils;

import entities.Character.Spell;
import entities.Character.SpellEffect;
import entities.Gem.ManaType;
import entities.effects.CsEmitter;
import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import haxe.DynamicAccess;
import openfl.Assets;
import states.PlayState.Play_State;
import utils.CsMath.centreRect;

typedef SpellStruct =
{
	name:String,
	description:String,
	mana:DynamicAccess<Int>,
	effect:String,
	args:Dynamic
}

typedef EffectArgs =
{
	?damageEnemy:Int,
}

class Loader
{
	public static function loadSpell(name:String):Spell
	{
		var spellJson = Assets.getText("assets/data/spells/" + name + ".json");
		var spellData:SpellStruct = haxe.Json.parse(spellJson);
		var spellMana = new Map<ManaType, Int>();

		var manaCount = 0;
		for (mt in spellData.mana.keys())
		{
			switch (mt)
			{
				case "Fire":
					spellMana.set(ManaType.FIRE, spellData.mana.get(mt));
					manaCount++;
					break;
				case "Water":
					spellMana.set(ManaType.WATER, spellData.mana.get(mt));
					manaCount++;
					break;
				case "Earth":
					spellMana.set(ManaType.EARTH, spellData.mana.get(mt));
					manaCount++;
					break;
				case "Air":
					spellMana.set(ManaType.AIR, spellData.mana.get(mt));
					manaCount++;
					break;
				case "Light":
					spellMana.set(ManaType.LIGHT, spellData.mana.get(mt));
					manaCount++;
					break;
				case "Dark":
					spellMana.set(ManaType.DARK, spellData.mana.get(mt));
					manaCount++;
					break;
			}
		}

		if (manaCount == 0)
		{
			throw "No mana found in spell";
		}

		return new Spell(spellData.name, spellData.description, spellMana, loadEffect(spellData.effect, spellData.args));
	}

	public static function loadEffect(name:String, args:Dynamic):SpellEffect
	{
		var script = Assets.getText("assets/data/effects/" + name + ".hxscript");

		return (enemy, self, board) ->
		{
			var globalState = FlxG.plugins.get(GlobalState);

			var parser = new hscript.Parser();
			var program = parser.parseString(script);
			var interp = new hscript.Interp();

			interp.variables.set("Math", Math);

			interp.variables.set("self", self);
			interp.variables.set("enemy", enemy);
			interp.variables.set("board", board);
			interp.variables.set("emitter", globalState.emitter);
			interp.variables.set("tools", {
				getPoint: FlxPoint.get,
				centreRect: centreRect,
				random: FlxG.random,
				burstEmit: CsEmitter.burstEmit,
				stringToColor: FlxColor.fromString
			});
			var effectCallback = (effectArgs:EffectArgs) ->
			{
				if (effectArgs.damageEnemy != null)
				{
					enemy.health -= effectArgs.damageEnemy;
				}
			};
			interp.variables.set("effectCallback", effectCallback);
			interp.variables.set("args", args);

			var ret:
				{
					delay:Float,
					nextState:Int
				} = interp.execute(program);

			return {
				delay: ret.delay,
				nextState: ret.nextState == 0 ? Play_State.Idle : Play_State.BoardMatching
			};
		}
	}
}
