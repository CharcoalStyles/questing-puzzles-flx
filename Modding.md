# Content Creation Guide

To aid in development of the game's content, I have taken a data + script approach to content. this has the added benefit of allowing for easy modding of the game.

As development progresses, the structures of the data and scripts will be refined and new features will be added. As it stands, enemies and spells are defined in json files and effect scripts are defined in hxscript files, which are just Haxe scripts to be run by the hscript library in game.

- Enemies are defined in json files in `assets/data/enemies/`.
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

## Enemies

Enemies are defined in json files. The json files are located in `assets/data/enemies/` and should have the name of the enemy and a `.json` extension.

### How to add a new enemy

Create a new json file in `assets/data/enemies/` with the name of the enemy.

Here is an example of an enemy:

```json
{
  "name": "Test Goblin", // The name of the enemy
  "level": 1, // The level of the enemy
  "health": 20, // The  max/starting health of the enemy
  "mana": { // The max/starting mana of the enemy
    "Fire": 30, 
    "Water": 25,
    "Earth": 20,
    "Air": 15,
    "Light": 25,
    "Dark": 15
  },
  "spell:": [ "ThrowRock", "Warcry" ] // The spells that the enemy can cast
}
```

Each spell is a string that is the name of the spell file in `assets/data/spells/`. Usually this will be the same as the spell, without spaces or file extension, but it can be anything.

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
  "effect": [{
    "function": "DamageEnemy", // The name of the effect script to call
    "args": { 
      "damage": 2, // The arguments to pass to the effect script
      "colour": "0x909090" // The colour of the particles
    }
  }] // The effect(s) of the spell
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
  - Other tools are passed in, listed below in the top of the sample script and in the [DamageEnemy](https://github.com/CharcoalStyles/questing-puzzles-flx/blob/main/assets/data/effects/DamageEnemy.hxscript) effect script.
  - The `args` property in the spell object is a dictionary of the arguments to pass to the effect script.

Here is an example of an effect, a simple one that reduces the enemy's health by the `damage` argument and lets the user continue their turn:

```hxscript
///Available Libraries:
// - Math - Haxe Math functions

// Available objects:
// - self:Character The character that cast the spell
// - enemy:Character The character that is being damaged
// - board:PlayBoard The board that the spell is being cast on
// - emitter:CsEmitter The global particle emitter
// - tools: a collection of tools:
//   - random:FlxRandom The global random number generator
//   - getPoint(x, y):FlxPoint Returns a FlxPoint with the given coordinates
//   - centreRect(rect):FlxPoint Returns a FlxPoint with the centre of the given rectangle
//   - burstEmit(colour, lifespan, options):CsEmitter.burstEmit Returns a CsEmitter.burstEmit
//   - stringToColor(str):Int Returns a hexadecimal colour code from a string

// Args callback:
//   - effectCallback:Function(args:EffectArgs):Void

// Args from the spell:
//   Required arguments:
//   - damage:Int The amount of damage to be dealt

// Returns:
//   - delay:Float The amount of time to wait before the next state is triggered, allowing particle effects to be completed
//   - nextState:Int The state to transition to; 0 = Idle, 1 = BoardMatching

effectCallback({
  damageEnemy: args.damage
});

var ret = {
  delay: 1,
  nextState: 0
}

ret;
```

The comments aren't required, but they are useful for remembering what is available to the effect script. This is also a very cutdown version of the [DamageEnemy](https://github.com/CharcoalStyles/questing-puzzles-flx/blob/main/assets/data/effects/DamageEnemy.hxscript) effect script.

### Objects

#### self

The `self` object is the character that cast the spell. It is a [Character](https://github.com/CharcoalStyles/questing-puzzles-flx/blob/main/source/entities/Character.hx) object that is defined in the main Haxe game code.

The main properties that you'll want to access are:
  - `self.health:Int`: The current health of the character
  - `self.mana:Map<ManaType, Int>`: The current mana of the character, uses [ManaType](#mana-types) as the key.
  - `self.spells:Array<Spell>`: The spells that the character can cast.

#### enemy

The `enemy` object is the character that is being damaged. It is a [Character](https://github.com/CharcoalStyles/questing-puzzles-flx/blob/main/source/entities/Character.hx) object that is defined in the main Haxe game code.

The main properties that you'll want to access are:
  - `enemy.health:Int`: The current health of the character
  - `enemy.mana:Map<ManaType, Int>`: The current mana of the character, uses [ManaType](#mana-types) as the key.

#### board

The `board` object is the Game Board, it is a [PlayBoard](https://github.com/CharcoalStyles/questing-puzzles-flx/blob/main/source/entities/PlayBoard.hx) object that is defined in the main Haxe game code.

The main properties that I think you'll want to access are:
  - `board.potentialMoves:Array<ScoredMatch>`: The potential moves on the board, sorted by score in descending order. The score is a basic count of the number of gems in the match.

The main methods that I think you'll want to access are:
  - `board.getRandomGem(manaTypes:Array<ManaType>):Gem`: Returns a random gem on the board that has the specified mana types.
  - `board.doMove(move:ScoredMatch)`: Does the move specified by the `move` object.
  - `board.shuffleBoard()`: Shuffles the board.

These are only the start for now; I'll be adding more methods as I go along.

#### emitter

The `emitter` object is the global particle emitter, it is a [ParticleEmitter](https://github.com/CharcoalStyles/questing-puzzles-flx/blob/main/source/entities/ParticleEmitter.hx) object that is defined in the main Haxe game code.

The main property that you'll want to access are:
  - `emitter.emit(x:Float, y:Float):CsParticle`: Emits a particle at the specified position.
    - and then  you'll mainly want to use the `CsParticle.setEffectStates` method to set the effects on the particle.

#### Tools

The `tools` object is a collection of tools that are available to the effect scripts. The tools are:
  - `random:FlxRandom`: The global random number generator.
  - `getPoint(x, y):FlxPoint`: Returns a FlxPoint with the given coordinates.
  - `centreRect(rect):FlxPoint`: Returns a FlxPoint with the centre of the given rectangle.
  - `burstEmit(colour, lifespan, options):CsEmitter.burstEmit`: Returns a CsEmitter.burstEmit.
  - `stringToColor(str):Int`: Returns a hexadecimal colour code from a string.

These are fairly self explanatory and will grow a lot as I develop the game.

#### efffectCallback

The `effectCallback` is a function that is called from the effect script, it allows the effect script to pass effects to the main game code. It was created because modifying basic objects in the effect script seemed to be ok, but modifying more complex objects (like Characters) was not.

The `effectCallback` is passed an anonymous object with the following optional properties:
  - `damageEnemy:Int`: The amount of damage to be dealt to the enemy. 

Yes, that's the only one (for now). I've been working on this for a few days and I just wanted to get something out there 😅

#### returns

The `returns` object is an anonymous object with the following properties:
  - `delay:Float`: The amount of time in seconds to wait before the next state is triggered, allowing particle effects to be completed.
  - `nextState:Int`: The state to transition to; 0 = Idle, 1 = BoardMatching

### Errata

#### ScoredMatch

The `ScoredMatch` object is defined in the main Haxe game code as:

```haxe
typedef ScoredMatch =
{
	move:CellMove,
	matches:Array<MatchGroup>,
	score:Int
}
```

#### GemGrid

The `GemGrid` object is defined in the main Haxe game code as:

```haxe
typedef GemGrid =
{
	x:Int,
	y:Int,
	gem:Gem
}
```