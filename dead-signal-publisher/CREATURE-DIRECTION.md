# Dead Signal Stalker Direction

The final stalker should NOT be a Huggy clone and should not directly reuse a copyrighted character.

## Core silhouette
- Very tall, narrow torso.
- Limbs slightly too long for the body.
- Flexible spine and shoulders, allowing it to fold through industrial passages.
- Hands large enough to read clearly in darkness, but not oversized cartoon gloves.
- Head small relative to height, giving the creature a wrong/unbalanced silhouette.
- Movement alternates between almost motionless observation and sudden low, fast pursuit.

## Visual language
Working name: **Threadbare**.

Concept:
A maintenance mascot/prototype made from soft industrial fabric stretched over an internal cable-and-joint frame. Old wiring is visible through torn seams. Small indicator lamps in the face/neck pulse with nearby electrical systems.

This ties the creature to Dead Signal's wire/power mechanic instead of copying Poppy Playtime.

## Gameplay behaviors
- Observe from door frames, mezzanines and glass.
- Move only after specific power events in early chapter sections.
- Investigate loud electrical failures.
- Temporarily disappear when the player cuts power to a zone.
- During chase, use service corridors and alternate shortcuts rather than simply following the same path as the player.
- Can trigger environmental events without always entering a full chase.

## Animation needs
- Idle breathing with tiny cable tension movements.
- Long still observation pose.
- Slow upright walk.
- Low fast chase.
- Corner peek.
- Ceiling/upper-frame silhouette pose.
- Search animation.
- Doorway squeeze.
- Stagger/recoil from sudden power discharge.

The existing StalkerService state machine is already designed for these behaviors.
