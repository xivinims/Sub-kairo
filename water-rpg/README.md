# Water Castle RPG — private development build

Source world: the supplied `water castle.rbxl`, including its native terrain, water, geometry and resident outfits. This replaces the BREU runtime. The game remains private.

## Included

- 101,950 static parts from the supplied world and its serialized native terrain.
- 18 residents: the supplied R15 templates with their original shirts, pants, body parts and meshes, plus a guide near the outside arrival. Shops remain stationary, several citizens roam near their authored homes when a player is nearby.
- A glass menu based on the supplied screenshots, with four slanted ribbon entries, camera motion, seven settings, credits, update log, death menu, respawn and return to menu. Its background is the actual castle.
- Player abilities use an integrated controller: automatic swimming, underwater breath and color grading, running stamina, automatic lateral wall run while sprinting in air, toggled wall walking, a belt lantern, bow aiming/shooting and a Boogie Woogie swap. Swaps target players or training targets and do not move the town residents or architecture.
- Three training targets, conversations, a delivery quest, coins, XP and healing tonics.
- A session lease prevents concurrent profile writes. If DataStore is unavailable, that session uses temporary progression and says so in the UI.

## Controls

| Action | Desktop | Touch |
| --- | --- | --- |
| Run | Shift | Run button |
| Swim | Enter water | Automatic |
| Rise / leave wall | Jump | Default jump |
| Wall run | Sprint + jump beside a wall | Run + jump beside a wall |
| Wall walk | B | Walls |
| Lantern | R | Lantern |
| Equip bow | 1 | Bow |
| Aim | Right mouse | Aim toggle |
| Shoot | Left mouse | Shoot |
| Swap | Aim at target + T | Aim at target + Swap |
| Tonic | H | Tonic |
| Talk | E near resident | World prompt |

## Imported packages

The supplied models were inspected before extraction. Original package networking, stock PlayerModule replacements and multiple competing camera/sprint scripts are not installed together. The native visual models, supplied animation references, RPG dialogue skin and the Luminos After Rain settings are reused. The movement, interaction and ability coordination code is local to this project.

The file `18835619908.rbxm` is Asadrith's Dialogue Kit, not a character power. `Luminos.rbxmx` is a lighting tool/preset collection. The wall-run and bow references are R6-oriented; physical controls have R15 fallbacks, but the supplied animations may require the publishing account to own or authorize them. Residents keep their R15 rigs independently of the player.

## Validation limits

Compilation and rules are tested with Luau. The native preflight checks complete world counts, original resident clothing IDs, restored terrain and solid non-water ground at arrival before saving. The saved version is verified again. These checks are not a rendered client playtest. Real touch behavior, animation permission, asset appearance and performance on a phone still need client verification. No exact visual-match or frame-rate claim is made.

Build: reassemble the source chunks, decompress to `water-rpg/water-castle.rbxl`, then run `lune run water-rpg/build.luau`. The workflow does this automatically. `player-assets.rbxm` contains only the selected visual resources, dialogue skin and a safe lighting preset from the supplied packages.
