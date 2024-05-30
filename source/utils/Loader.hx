package utils;

import entities.Character.Spell;
import entities.Character.SpellEffect;
import entities.Character;
import entities.Gem.GemType;
import entities.Gem.ManaType;
import entities.effects.CsEmitter;
import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.math.FlxRandom;
import flixel.util.FlxColor;
import haxe.DynamicAccess;
import haxe.Timer;
import openfl.Assets;
import states.PlayState.Play_State;
import utils.CsMath.centreRect;
import utils.Observer.FloatObservable;
import utils.Observer.IntObservable;

typedef CharacterStruct =
{
	name:String,
	level:Int,
	health:Int,
	mana:ManaNumber,
	spells:Array<String>,
	effects:Array<String>
}

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
	public static function loadCharacters():Array<{fileName:String, data:CharacterStruct}>
	{
		var characterFileName = Assets.list(TEXT);
		var characterFileName = characterFileName.filter(function(f) return f.indexOf("/characters/") != -1);
		var characters = [];
		for (f in characterFileName)
		{
			var characterJson = Assets.getText(f);
			var characterData:CharacterStruct = haxe.Json.parse(characterJson);
			characters.push({fileName: f.split("/").pop(), data: characterData});
		}
		return characters;
	}

	public static function loadCharacterFromFile(characterFileName:String):CharacterStruct
	{
		var characterJson = Assets.getText("assets/data/characters/" + characterFileName);
		var characterData:CharacterStruct = haxe.Json.parse(characterJson);
		return characterData;
	}

	public static function loadSpell(name:String):Spell
	{
		var spellJson = Assets.getText("assets/data/spells/" + name + ".json");
		var spellData:SpellStruct = haxe.Json.parse(spellJson);
		var spellMana = new Map<ManaType, Int>();

		var manaCount = 0;
		for (mt in spellData.mana.keys())
		{
			var manaType = ManaType.fromString(mt);
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
			interp.variables.set("GemType", GemType);
			interp.variables.set("self", self);
			interp.variables.set("enemy", enemy);
			interp.variables.set("board", board);
			interp.variables.set("emitter", globalState.emitter);
			interp.variables.set("tools", {
				getPoint: FlxPoint.get,
				centreRect: centreRect,
				random: new FlxRandom(),
				shuffle: (array:Array<Dynamic>) ->
				{
					var maxValidIndex = array.length - 1;
					for (i in 0...maxValidIndex)
					{
						var j = FlxG.random.int(i, maxValidIndex);
						var tmp = array[i];
						array[i] = array[j];
						array[j] = tmp;
					}
				},
				burstEmit: CsEmitter.burstEmit,
				stringToColor: FlxColor.fromString,
				stringToManaType: ManaType.fromString,
				delay: (func:() -> Void, delay:Float) -> Timer.delay(func, Math.floor(delay * 1000))
			});
			var effectCallback = (effectArgs:EffectArgs) ->
			{
				if (effectArgs.adjustEnemyHealth != null)
				{
					if (enemy.health + effectArgs.adjustEnemyHealth >= enemy.maxHealth)
					{
						enemy.health.set(enemy.maxHealth);
					}
					else if (enemy.health + effectArgs.adjustEnemyHealth <= 0)
					{
						enemy.health.set(0);
					}
					else
					{
						enemy.health += effectArgs.adjustEnemyHealth;
					}
				}

				if (effectArgs.adjustPlayerHealth != null)
				{
					if (self.health + effectArgs.adjustPlayerHealth >= self.maxHealth)
					{
						self.health.set(self.maxHealth);
					}
					else if (self.health + effectArgs.adjustPlayerHealth <= 0)
					{
						self.health.set(0);
					}
					else
					{
						self.health += effectArgs.adjustPlayerHealth;
					}
				}

				if (effectArgs.adjustEnemyMana != null)
				{
					for (mt in effectArgs.adjustEnemyMana.keys())
					{
						var manaType = ManaType.fromString(mt);
						var manaValue = effectArgs.adjustEnemyMana.get(mt);

						var currentMana = enemy.mana.get(manaType).get();

						if (currentMana + manaValue >= enemy.maxMana.get(manaType))
						{
							enemy.mana.get(manaType).set(enemy.maxMana.get(manaType));
						}
						else if (currentMana + manaValue <= 0)
						{
							enemy.mana.get(manaType).set(0);
						}
						else
						{
							enemy.mana.get(manaType).set(currentMana + manaValue);
						}
					}
				}

				if (effectArgs.adjustPlayerMana != null)
				{
					for (mt in effectArgs.adjustPlayerMana.keys())
					{
						var manaType = ManaType.fromString(mt);
						var manaValue = effectArgs.adjustPlayerMana.get(mt);

						var currentMana = self.mana.get(manaType).get();

						if (currentMana + manaValue >= self.maxMana.get(manaType))
						{
							self.mana.get(manaType).set(self.maxMana.get(manaType));
						}
						else if (currentMana + manaValue <= 0)
						{
							self.mana.get(manaType).set(0);
						}
						else
						{
							self.mana.get(manaType).set(currentMana + manaValue);
						}
					}
				}
			};
			interp.variables.set("effectCallback", effectCallback);
			interp.variables.set("args", args);

			var x = [];

			var ret:
				{
					delay:Float,
					nextState:Int
				} = interp.execute(program);

			return {
				delay: ret.delay,
				nextState: ret.nextState == 0 ? Play_State.Idle : Play_State.BoardMatching,
				endTurn: args.endTurn == null ? false : args.endTurn
			};
		}
	}
}
