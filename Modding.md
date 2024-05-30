# Content Creation Guide

To aid in development of the game's content, I have taken a data + script approach to content. this has the added benefit of allowing for easy modding of the game.

As development progresses, the structures of the data and scripts will be refined and new features will be added. As it stands, enemies and spells are defined in json files and effect scripts are defined in hxscript files, which are just Haxe scripts to be run by the hscript library in game.

- Enemies are defined in json files in `assets/data/characters/`.
  - Each enemy has a name, level, health, and mana.
  - The mana is a dictionary of the mana types and their maximum values.
  - The spells are an array of spell objects.
- Spells are defined in json files in `assets/data/spells/`.
  - Each spell has a name, description, mana cost, and effect.
  - The effect is an array object with the following properties:
    - function: The name of the effect script to call.
    - args: The arguments to pass to the effect script.
- Effects are defined in hxscript files in `assets/data/effects/`.
  - Each effect is a [Haxe](https://haxe.org/) script file that is essentially the body of a function.
- The player will also use the spells and effects defined in the data.
  - How this is done is not yet defined and current spells are hardcoded.

## Characters

Characters are defined in json files. The json files are located in `assets/data/characters/` and should have the name of the character and a `.json` extension.

### How to add a new enemy

Create a new json file in `assets/data/characters/` with the name of the enemy.

Here is an example of an enemy:

```json
{
  "name": "Test Goblin", // The name of the character
  "level": 1, // The level of the character, not that it's used yet
  "health": 20, // The  max/starting health of the character
  "mana": { // The max/starting mana of the character
    "Fire": 30, 
    "Water": 25,
    "Earth": 20,
    "Light": 25,
    "Dark": 15
  },
  "spell:": [ "ThrowRock", "Warcry" ] // The spells that the character can cast
}
```

Each spell is a string that is the name of the spell file in `assets/data/spells/`. Usually this will be the same as the spell, without spaces or file extension, but it **can** be anything.

## Spells

Spells are defined in json files. The json files are located in `assets/data/spells/` and should have the name of the spell.

### How to add a new spell

Create a new json file in `assets/data/spells/` with the name of the spell and a `.json` extension.

Here is an example of a spell:

```json
{
  "name": "Throw Rock", // The name of the spell
  "description": "It's a little pointy. Deals 2 damage.", // The description of the spell
  "manaCost": { // The mana cost of the spell
    "Fire": 2,
    "Dark": 2,
  },
  "effect": "DamageEnemy", // The name of the effect script to call
  "args": { 
    "damage": 2, // The arguments to pass to the effect script
    "colour": "0x909090" // The colour of the particles
  }
}
```

Each effect is an object with the following properties:
  - function: The name of the effect script to call. This is the name of the hxscript file in `assets/data/effects/`. Usually this will be the same as the spell, without spaces or file extension, but it can be anything.
  - args: The arguments to pass to the effect script. This is a dictionary of the arguments to pass to the effect script.

## Effects

Effects are defined in hxscript files. The hxscript files are located in `assets/data/effects/` and should have the name of the effect.

### How to add a new effect

Create a new hxscript file in `assets/data/effects/` with the name of the effect and a `.hxscript` extension. The script is a [Haxe](https://haxe.org/) script file that is essentially the body of a function, with some defined arguments.

Here are some caveats with Haxe scripts:
  - This is a subset of the Haxe language. Here are the specifics [hScript](https://github.com/HaxeFoundation/hscript)
  - Most classes have to be imported in to the scripts from the main Haxe game code. As such, there is currently only one class that is imported: `Math`.
  - Other tools are passed in, more information below.
  - The `args` property in the spell object is a dictionary of the arguments to pass to the effect script.

Here is an example of an effect, a simple one that reduces the enemy's health by the `damage` argument and lets the user continue their turn:

```haxe
// SimpleDamageEnemy.hxscript

// Args from the spell:
//   Required arguments:
//   - damage:Int The amount of damage to be dealt

effectCallback({
  adjustEnemyHealth:  0 -args.damage // adjust enemy health adds the value given, so we make it negative to reduce the health
});

var ret = {
  delay: 1,
  nextState: 0
}

ret;
```

This is a very cutdown version of the [DamageEnemy](https://github.com/CharcoalStyles/questing-puzzles-flx/blob/main/assets/data/effects/DamageEnemy.hxscript) effect script, just to give a simple entry point to learn about the effect script.

### What's available to the effect script?

#### args

The `args` property is a collection of the arguments prodided to the effect script from the spell object. This is different for every effect, allowing swpells to use the same effect script but with different arguments.

Currently, the only effect available is the [DamageEnemy](https://github.com/CharcoalStyles/questing-puzzles-flx/blob/main/assets/data/effects/DamageEnemy.hxscript) effect script, which takes the required argument `damage` and the optional argument `colour`. The `damage` argument is an integer that is the amount of damage to be dealt to the enemy. The `colour` argument is a string (CSS style colour code or hexadecimal colour code) that sets the colour of the particle effects.

#### Math

It is a direct insertion of the [Math](https://api.haxe.org/Math.html) class from the Haxe standard library.

#### GemType

It is a direct insertion of the [GemType](https://github.com/CharcoalStyles/questing-puzzles-flx/blob/main/source/entities/Gem.hx) class from the Haxe game code. This is really only used to get the colour of the gems.

#### self and enemy

`self` and `enemy` are [Character](https://github.com/CharcoalStyles/questing-puzzles-flx/blob/main/source/entities/Character.hx) objects. Self is the character that cast the spell, enemy is the other character in the battle.

The main properties that you'll want to access are:
  - `self.health:Int`: The current health of the character
  - `self.mana:Map<ManaType, Int>`: The current mana of the character, uses ManaType as the key.

Everything in the characters is available, but your milage might vary when modifying anything directly. 

#### board

The `board` object is the Game Board, it is a [PlayBoard](https://github.com/CharcoalStyles/questing-puzzles-flx/blob/main/source/entities/PlayBoard.hx) object that is defined in the main Haxe game code.

The main properties that I think you'll want to access are:
  - `board.potentialMoves:Array<ScoredMatch>`: The potential moves on the board, sorted by score in descending order. The score is a basic count of the number of gems in the match.

The main methods that I think you'll want to access are:
  - `board.getRandomGem(manaTypes:Array<ManaType>):Gem`: Returns a random gem on the board that has the specified mana types.
  - `board.doMove(move:ScoredMatch)`: Does the move specified by the `move` object.
  - `board.shuffleBoard()`: Shuffles the board.

Everything that is publicly available in the PlayBoard class is available to use. Right now that isn't a lot, but this is just the start; I'll be exposing more as I go along. Also, there is no guarantee that changing anything will actually work.

#### emitter

The `emitter` object is the global particle emitter, it is a [CsEmitter](https://github.com/CharcoalStyles/questing-puzzles-flx/blob/main/source/entities/effects/CsEmitter.hx) object that is defined in the main Haxe game code.

The main property that you'll want to access are:
  - `emitter.emit(x:Float, y:Float):CsParticle`: Emits a particle at the specified position.
    - and then you'll  want to use the `CsParticle.setEffectStates` method to set the effects on the particle.

#### Tools

The `tools` object is a collection of tools that are available to the effect scripts. The tools are:
  - `random:FlxRandom`: The global random number generator.
  - `getPoint(x, y):FlxPoint`: Returns a FlxPoint with the given coordinates.
  - `centreRect(rect):FlxPoint`: Returns a FlxPoint with the centre of the given rectangle.
  - `burstEmit(colour, lifespan, options):CsEmitter.burstEmit`: Returns a CsEmitter.burstEmit.
  - `stringToColor(str):Null<FLxColor>`: Returns a FlxColor from a string.
  - `stringToManaType(str):ManaType`: Returns a ManaType from a string.
  - `delay(func:() -> Void, delay:Float):Void`: Delays the execution of the function by the given amount of time in seconds.

These are fairly self explanatory and will grow a lot as I develop the game.

#### effectCallback

The `effectCallback` is a function that is called from the effect script, it allows the effect script to pass effects to the main game code. It was created because modifying basic objects in the effect script seemed to be ok, but modifying more complex objects (like Characters) was not.

The `effectCallback` is passed an anonymous object with the following optional properties:
  - `adjustEnemyHealth:Int`: The value to add to the enemy's health. To reduce the enemy's health, use a negative value.
  - `adjustPlayerHealth:Int`: The value to add to the player's health.
  - `adjustEnemyMana:DynamicAccess<Int>`: A dictionary of the mana types and their values to add to the enemy's mana.
  - `adjustPlayerMana:DynamicAccess<Int>`: A dictionary of the mana types and their values to add to the player's mana.

#### returns

Each script will return an object with the following properties:
  - `delay:Float`: The amount of time in seconds to wait before the next state is triggered, allowing particle effects to be completed.
  - `nextState:Int`: The state to transition to; 0 = Idle, 1 = BoardMatching

The delay should be calculated on how long the particle effect(s) take to complete.
And generally, the next state should be the Idle, unless the effect has changed the board state.
