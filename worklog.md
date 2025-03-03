# 2024-12-27 21:45:44

And another long break. There has been a few little updates before this, but it's about time to write about stuff.

I'm ignoring everything in the last post as far as how the game works. This was born out of a want to see a new "classic" match-3 RPG game and I'm going to stick with that.

So, I've been working on a tool that will help me make the content for the game. I'm using my day job skills to make a NextJS + Deno based app to create and edit the data. Currently it's just some APIs to create, read and update the data for spells, characters and effects. Next steps will be adding the delete and possibly the individual read routes (currently you can only read everything, which will be **too** much for the final editor.)

After that will be writing up the UI and then pumping out the new content. Another thing I want ot add is an embedded version of the game that can be pushed into the editor to simulate battles based on the current state of the data that is being edited. :D

One thing to note with this is that through the use of Deno, I should be able to build the editor for Windows, Mac and Linux. Modding was (obviously) a big part of what I wanted to make, so releasing the editor on all three platforms should be a nice bonus!

Also, I've done a manual conversion of the file names and references to what the editor should be pushing out. But I haven't tested it, so YOLO.

# 2024-09-01 21:32:09

Ok, that was a bit of a break.

It's been at the back of my mind how I should approach this project. Should I stick as much as possible to the original inspiration or should I add a bit of a spin on it?

Still not 100% sure, so I think I'll have a bit of a crack in a slightly different direction.

Instead of having a single character you play as, you control a team of characters. Each character has a set of skills and spells that they can use. This is heavily inspired by the v3 update of [Slice and Dice](https://tann.itch.io/slice-dice), with a bit of inspiration from Puzzle Kingdoms.

Lots of things to unpack or this change:

- There has to bea a *bunch* of characters; it doesn't mean much more work than the original, as the characters can (and will) be used in enemy groups,too.
- There will be a big re-think of how characters target each other, how spells and abilities are activated, how mana is handled, and how the 'damage' tile is used. So basically all the minute-to-minute mechanics will need a solid overhaul.
- A big UI rethink, too. Not that the current one was that good.

I'm not going to timebox this, considering I have such minimal and erratic time to spend on it. But I'll get it to a level of quality a bit better than the current version.

Also, the only recent fixes in code are getting the Github pages working since I moved a bunch of code out into a new library.

# 2024-05-30 20:45:29

The grey gems now do damage!, 1 damage per gem and a simple effect. Nothing too much more than that.

Added a new enemy character, the Test Rat; it bites and eats cheese. I mainly just wanted another character (and set of spells) to test the loading of new characters.

I also updated the menu text animations, a selected item now waves a little. I also remove the animations when items are switched.

Also did a tiny bit of game balancing. It's not perfect, but it's a start.

# 2024-05-25 23:56:17

More polish (aka procrastination)!

Tweaked Fireball to only use 5 fire mana, but also ends the turn. This is through a "global" (i.e. any spell can have it) arg.

Added tooltips to the spells that show hte description.

Put a menu in the pause state.

Tweaked the visuals of the game over screen and added a "press any key to continue" text. and it goes back to the main menu when nay button is pressed.

# 2024-05-23 07:27:01

Even more procrastination!

Menus have pages now.

# 2024-05-21 22:40:41

More procrastination!

I thought it might be nice to have a menu system that is a little nicer to make. I came across another library, but wasted a few hours to not get it working.

So I've started my own! It currently is accessible though keyboard and mouse (and possibly touch). It has default animations for selection and deselection, as well as unselectable items; commonly known as labels.

Eventually there will be more options; I'm thinking different anims, joystick support (duh), and other menu options, like number scrolling and selectable options from a list/array. You know, usual game menu stuff.

# 2024-05-20 05:47:37

Added ability to set the speed of the main particle effect in the `Damage_Enemy` effect script.

# 2024-05-18 22:44:15

Added both the "win" and "lose"  states to the game and show a text effect for them.

Also added the ability for the AI to use spells. basically there's a level+1 chance in 10 that when the AI has a turn, it will use a spell. It 100% needs tweaking, but it's a start.

# 2024-05-17 21:26:56

This took a little longer than expected, but I've got the x-match system working. I had to re-arrange how some data comes through to the play state and while doing that, I messed up how part of it looked up the gem type.

Now on a 4 length match, the player gets a new turn. 5+ length matches give an extra mana per extra gem matched. if you match 4 gems, you get 4 mana. If you get 5 gems, you get 10 mana. 6 gems gets 18 mana. This is broken.But none of the game is balanced, so it doesn't matter!

Also, both of these get a text effect on the board. I think it's pretty sweet.

# 2024-05-16 16:31:02

Enemies now don't load with full mana. Lucky they couldn't actually use it anyway.

# 2024-05-15 10:50:07

Main menu now has a "New Battle" button, which loads a list of characters to battle. Though currently there is only one: the Test Goblin.

Fixed a bug with the "Light it up!" spell, it would when not producing a match go through the swap reversal. This totally messed up the board. A bit of fiddling with states (and adding a new one) fixed it.

## 2024-05-13 22:11:03

Added a nice little effect to the options on the main menu.

Also added a Fullscreen toggle to the main menu.

## 2024-05-13 15:09:56

Added a `Light it up!` spell to the player's spells array. This spell is a simple spell that swaps 5 randoms gems on the board with a random gem of the fire type.

Removed the `Warcry` spell from the player's spells array, I've done my testing.

I've fleshed out the `TODO.md` a bit more, It's great to have a backlog that induces some level of dread.

Also added some more info to the `Modding.md` file, because of things I've added to the modding abilities of the game.

## 2024-05-12 22:23:28

Made the `Warcry `spell and it's associated `Adjust_Enemy_Mana` effect work!

As part of this, I changed up the ManaType enum to be a class. This is because my original idea of Enums was informed by how they are used in C# and the Haxe implantation of them are quite different. I'm not sure if I'll ever make use of the Haxe Enums again, but they seem to be fairly powerful, just not in a way I know how to use.

Also, I added the `Warcry` spell to the Player's spells array, mainly for testing, as the AI doesn't use spells yet. That'l be the next thing after I geth the `Light it up!` spell working.

## 2024-05-12 13:49:04

Added ability to add an ease function to the target effect states from within a script. This was to make the fireball spell work as it did before the transition to the new scripting system.

I also added new optional args to the `Damage_Enemy` effect script for the `explosion` and `trailType` arguments. Originally since this effect was only used for the fireball spell, the trail and explosion were hard coded.

Finally, I adjusted the particle effect for the heal spell to spawn a bit closer to the size of the text.

## 2024-05-11 21:34:25

Decided to add a working log to the repo. I'm going to use this to keep track of what I've done and other things I'm thinking about and stuff.

Moved the player's heal spell into the data files and added a nice particle effect for it. As part of this, I added the delay function to the script tools.

Adjusted the effect callback to make it more generic; rather than `damageEnemy`, it's now `adjustEnemyHealth`. Give is a positive value to increase the enemy's health, and a negative value to decrease it 😉. Also added `adjustPlayerHealth` in the same vibe.

I also cleaned up the modding guide a bit. It now holds all the info about the included libraries, objects and tools, instead of the script themselves; though they keep the args for that specific effect.
