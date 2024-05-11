package utils;

import entities.Character.Spell;
import entities.Character.SpellEffect;
import entities.Gem.ManaType;
import entities.effects.CsEmitter;
import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import haxe.DynamicAccess;
import haxe.Timer;
import openfl.Assets;
import states.PlayState.Play_State;
import utils.CsMath.centreRect;

typedef ManaNumber = DynamicAccess<Int>;

typedef SpellStruct =
{
	name:String,
	description:String,
	mana:ManaNumber,
	effect:String,
	args:Dynamic
}

typedef EffectArgs =
{
	?adjustEnemyHealth:Int,
	?adjustPlayerHealth:Int,
	?adjustEnemyMana:ManaNumber,
	?adjustPlayerMana:ManaNumber,
}

class Loader
{
	public static function stringToManaType(str:String):ManaType
	{
		return switch (str)
		{
			case "Fire":
				ManaType.FIRE;
			case "Earth":
				ManaType.EARTH;
			case "Water":
				ManaType.WATER;
			case "Air":
				ManaType.AIR;
			case "Light":
				ManaType.LIGHT;
			case "Dark":
				ManaType.DARK;
			default:
				null;
		}
	}

	public static function loadSpell(name:String):Spell
	{
		var spellJson = Assets.getText("assets/data/spells/" + name + ".json");
		trace(spellJson);
		var spellData:SpellStruct = haxe.Json.parse(spellJson);
		var spellMana = new Map<ManaType, Int>();

		var manaCount = 0;
		for (mt in spellData.mana.keys())
		{
			var manaType = stringToManaType(mt);
			if (manaType == null)
			{
				throw "Invalid mana type: " + mt;
			}

			spellMana.set(manaType, spellData.mana.get(mt));
			manaCount++;
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
				stringToColor: FlxColor.fromString,
				delay: (func:() -> Void, delay:Float) -> Timer.delay(func, Math.floor(delay * 1000))
			});
			var effectCallback = (effectArgs:EffectArgs) ->
			{
				if (effectArgs.adjustEnemyHealth != null)
				{
					enemy.health += effectArgs.adjustEnemyHealth;
				}

				if (effectArgs.adjustPlayerHealth != null)
				{
					self.health += effectArgs.adjustPlayerHealth;
				}

				if (effectArgs.adjustEnemyMana != null)
				{
					for (mt in effectArgs.adjustEnemyMana.keys())
					{
						var manaType = stringToManaType(mt);
						var manaValue = effectArgs.adjustEnemyMana.get(mt);
						enemy.maxMana.set(manaType, enemy.maxMana.get(manaType) + manaValue);
					}
				}

				if (effectArgs.adjustPlayerMana != null)
				{
					for (mt in effectArgs.adjustPlayerMana.keys())
					{
						var manaType = stringToManaType(mt);
						var manaValue = effectArgs.adjustPlayerMana.get(mt);
						self.maxMana.set(manaType, self.maxMana.get(manaType) + manaValue);
					}
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
