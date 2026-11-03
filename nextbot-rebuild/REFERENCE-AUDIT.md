# Nextbot recreation — implementation status

Target is the CURRENT Evade UI in the owner's IMG_2671–IMG_2690 screenshots. Requested timing: 90-second intermission, 180-second round. The server round state machine now uses these durations. It waits for queued players and authored LobbySpawns/RoundSpawns folders before starting.

## Implemented candidate

- Native Roblox settings screen: audio/visual/game tabs, header, close/reset, scrolling sections, toggle controls, mouse/touch sliders, scaling from 1624×750 screenshots.
- Local material simplification with original material restoration, shadow control, FOV, named audio group volume.
- Validated preference remote, defaults, bounds, NaN/infinity rejection, autosave, conservative behavior after a failed DataStore read.
- Viewbob, running viewmodel, legacy camera and vignette preferences are exposed as attributes. They still require gameplay consumers and do not yet implement those effects.
- Standalone preview place. No live FPS replacement or Roblox publication occurs in this workflow.

## Match runtime candidate (not Roblox-playtested)

- Server-owned queue, timers, late joining and lobby return; respawn/death clears participation.
- Pure timing tests cover waiting for players, both transitions and subsequent rounds.
- Optional NextbotTemplates in ServerStorage: up to four humanoid models, server ownership, pathfinding and line-of-sight contact checks. Imported scripts are stripped from cloned bots.
- Contact currently kills; downed/rescue/carry are NOT implemented. No reward or currency is granted.
- Match.client is explicitly a temporary development HUD, not the final screenshot layout.
- This preview has no map spawn folders or bot templates installed, so it deliberately waits for integration. No bots or match are advertised as playtested.

## Exact match still missing

Main menu, shop, inventory, avatar inspection, loading screen, round queue, missions, event pass, leaderboard, spectating, final mobile match HUD, Nextbot asset integration and AI playtesting, downed/rescue/carry, progression, equipment and animation runtime remain to be implemented and tested together.

No visual verification inside Roblox has occurred. Fonts, gear glyph, gradients, transitions and underlying 3D scene are not yet certified identical. The preview floor is an inspection stage, not the requested map.

Catalog entries transcribe visible screenshot names/prices, not a complete Evade catalog. All catalog items remain unavailable in this preview; no animation or music IDs are invented. Items must only be enabled after their gameplay implementation and assets are validated.

## References and candidate assets

- Official current game / features: https://www.roblox.com/games/9872472334/Evade
- Public animation model previously used in this repository: https://create.roblox.com/store/asset/14026023204 — inspect actual keyframes before reuse; this does not prove identity to current Evade.
- Candidate Nextbot model: https://create.roblox.com/store/asset/11128061931/Evade-Nextbot — third-party model, not verified official.
- Candidate Rocket Arena map: https://create.roblox.com/store/asset/124805122537927/Rocket-Arena-Map-Evade-Kit-Obunga-Evade-Map — third-party model, not the screenshot backdrop.
- Catjam author identified in the screenshot as WizardMaster29; community corroboration: https://evadewiki.org/wiki/m3gan-x-evade-update/
- Community soundtrack index associates Catjam with Adele Roberts – Lose My Mind (edited), and Serious March with Ray Russell – Tense Emotion: https://evadewiki.org/wiki/soundtracks/ . These are research leads, NOT playable verified asset IDs or evidence of experience permissions.

The audit workflow downloads candidate models to a build artifact, enumerates scripts without executing them, records hashes, and compiles the standalone settings preview. Exact emote motions, associated accessories, playable music, textures and the requested map remain unresolved.

## Inspected assets

14026023204 contains 12 locomotion KeyframeSequences, no emote catalog. 11128061931 contains a Freddy model and four scripts, with audio content IDs 1847795501 and 236919724; these are not emote tracks. Rocket Arena is XML with a declaration; the audit strips that declaration only for parsing while retaining the original bytes/hash. None is claimed identical to current Evade.
