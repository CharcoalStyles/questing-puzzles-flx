## 2024-05-11 21:34:25

Decided to add a working log to the repo. I'm going to use this to keep track of what I've done and other things I'm thinking about and stuff.

Moved the player's heal spell into the data files and added a nice particle effect for it. As part of this, I added the delay function to the script tools.

Adjusted the effect callback to make it more generic; rather than `damageEnemy`, it's now `adjustEnemyHealth`. Give is a positive value to increase the enemy's health, and a negative value to decrease it 😉. Also added `adjustPlayerHealth` in the same vibe.

I also cleaned up the modding guide a bit. It now holds all the info about the included libraries, objects and tools, instead of the script themselves; though they keep the args for that specific effect.
