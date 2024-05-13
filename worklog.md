## 2024-05-13 15:09:56

Added a `Light it up!` spell to the player's spells array. This spell is a simple spell that swaps 5 randoms gems on the board with a random gem of the fire type.

Removed the `Warcry` spell from the player's spells array, I've done my testing.

I've fleshed out the `TODO.md` a bit more, It's great to have a backlog that induces some level of dread.

Also added some more info to the `Modding.md` file, because of things I've added to the modding abilities of the game.

## 2024-05-12 22:23:28

Made the `Warcry `spell and it's associated `AdjustEnemyMana` effect work!

As part of this, I changed up the ManaType enum to be a class. This is because my original idea of Enums was informed by how they are used in C# and the Haxe implantation of them are quite different. I'm not sure if I'll ever make use of the Haxe Enums again, but they seem to be fairly powerful, just not in a way I know how to use.

Also, I added the `Warcry` spell to the Player's spells array, mainly for testing, as the AI doesn't use spells yet. That'l be the next thing after I geth the `Light it up!` spell working.

## 2024-05-12 13:49:04

Added ability to add an ease function to the target effect states from within a script. This was to make the fireball spell work as it did before the transition to the new scripting system.

I also added new optional args to the `DamageEnemy` effect script for the `explosion` and `trailType` arguments. Originally since this effect was only used for the fireball spell, the trail and explosion were hard coded.

Finally, I adjusted the particle effect for the heal spell to spawn a bit closer to the size of the text.

## 2024-05-11 21:34:25

Decided to add a working log to the repo. I'm going to use this to keep track of what I've done and other things I'm thinking about and stuff.

Moved the player's heal spell into the data files and added a nice particle effect for it. As part of this, I added the delay function to the script tools.

Adjusted the effect callback to make it more generic; rather than `damageEnemy`, it's now `adjustEnemyHealth`. Give is a positive value to increase the enemy's health, and a negative value to decrease it 😉. Also added `adjustPlayerHealth` in the same vibe.

I also cleaned up the modding guide a bit. It now holds all the info about the included libraries, objects and tools, instead of the script themselves; though they keep the args for that specific effect.
