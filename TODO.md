# My todo list

Just want a place to keep track of what I want to do next. Might as well make it public.

- [ ] New particle system
  - [x] Basic Pooling system
  - [x] Extended FlxParticle
  - [x] Extended LERP with steps/stops
    - Original FlxParticle LERP just wasn't working for me
    - I've actually stripped out access to the original FlxParticle LERPs. An array with 2 stops at 0 and 1 do the same thing; though I do miss out on easings (for now...)
  - [x] Emitter function to replace current mana gain effect
  - [ ] Emitter function for health gain
  - [x] Emitter function for damage taken
    - Kind of done, Fireball spell has a particle animation right now, but it isn't a generic "lose health" effect.
    - Both heal/damage might just be specific to the "spell" that does the effect
  - [x] Emitter function for gem change (Also a basic explosion)
    - First pass done and works on main menu on click and the "Light it up!" spell in game
  - [ ] Emitter function for gem match
    - I can't even remember what I meant by this. Right now it seems the same as the mana gain effect.
- [ ] x-match system
  - [ ] New turn on 4+ match
  - [ ] UI and/or text effect for new turn
  - [ ] Do something on 5+ match
  - [ ] Do something on 6+ match?
- [ ] Change Air to damage
  - [ ] Remove from character mana system
  - [ ] deal damage to other character on match
  - [ ] Find appropriate developer art for new gem
- [ ] Particle system Extensions
  - [ ] See if there's some refinements for the particle system generation
    - It's a bit too much to write right now. But also not too bad, I guess.
    - Also, this might solve it's self when I move spells to data files
  - [ ] Add easings to the particle system, somehow, the stops make it weird.
  - [ ] Split out the particle system into a library?