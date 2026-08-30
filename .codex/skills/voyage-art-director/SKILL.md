---
name: voyage-art-director
description: Turn ideas for the sailboat focus game into coherent art direction, animation briefs, asset layer plans, and product-fit checks grounded in the game's voyage, companionship, and time-trace principles.
metadata:
  short-description: Art direction for the sailboat focus game
---

# Voyage Art Director

Use this skill when working on the sailboat focus game, especially for visual direction, animation details, prompt writing, asset decomposition, feature judgment, or any question about whether an idea fits the product.

The product is not a Pomodoro timer with a sailing skin. It is a small world that moves, grows, remembers time, and makes the player want to begin the next focus voyage.

## Core Product Test

Before proposing or implementing a feature, art change, animation, UI element, reward, or story beat, check it against these questions:

1. Does it make the player look forward to the next focus voyage?
2. Does it create companionship instead of pressure?
3. Does it leave a trace that time has passed?

Prefer people, wishes, voyages, discoveries, world memory, ship aging, map growth, and gentle callbacks. Avoid pressure mechanics such as streak anxiety, missed rewards, daily task quotas, or overt productivity scoring unless the user explicitly asks for them.

## Emotional Direction

The experience should feel quiet, warm, companionable, and meaningful. Focus time should become a visible journey: a voyage completed, a port reached, a crew accompanied, a map filled in, a ship made familiar, or a promise slowly fulfilled.

For first-stage work, prioritize the loop:

`departure -> sailing -> arrival`

Make this one loop comfortable and worth seeing many times before expanding into complex stories or systems.

## Art Direction

Default visual direction:

- 2D hand-painted or painterly game art.
- Portrait 9:16 mobile composition.
- Warm, calm, ocean-voyage atmosphere.
- Gentle motion, readable silhouettes, soft environmental detail.
- A sense of forward travel through parallax, water movement, sail motion, camera drift, and distant landmarks.

Avoid by default:

- Western fantasy, heavy RPG UI, loud reward effects, photorealism, generic 3D, hard sci-fi, aggressive gamification, and cluttered productivity dashboards.

## Animation Briefs

When turning user ideas into animation guidance, describe separate layers and states. For the current ship voyage, prefer these states:

- `departure`: anchored at port, crew prepares, sail begins to rise, ship slowly leaves.
- `sailing_loop`: raised sail, rolling water, hull bobbing, subtle forward feeling, quiet crew activity.
- `pause_idle`: sail lowered or loosened, timer paused, ship drifts gently, water continues moving.
- `resume`: sail rises again, wind catches cloth, forward motion returns.
- `arrival`: port appears, sail lowers, anchor drops, ship eases into harbor.

Always identify which elements should be separate assets when useful: sky, distant island, port, sea surface, wave highlights, ship hull, mast, sail, ropes, crew, foreground water, UI overlay.

## Prompt Writing

When writing prompts for image generation, art outsourcing, Spine animation, or visual references, produce practical briefs rather than decorative adjective lists. Include:

- purpose of the asset or shot;
- composition and camera framing;
- mood and lighting;
- layer requirements;
- motion requirements if animated;
- style constraints;
- negative constraints.

Keep language specific enough for an artist or tool to act on. If the request is vague, make a reasonable first pass and state the key assumption.

## Development Alignment

For Godot implementation, keep art requests compatible with a practical 2D pipeline. Prefer layered PNGs or Spine exports for moving ship, sail, water, and crew elements. A flattened scene can be used for early prototypes, but do not overstate it as real character or object animation.

When a requested visual effect cannot be produced well from a flattened image, say so directly and recommend the minimum asset separation needed.

For the frozen core principles, read `references/core-design-constitution-v1.0.md` when making larger product, story, progression, or visual-direction decisions.
