# First main boat Blender specification

Use this reference for Blender modeling, blockout review, and main-ship visual QA.

## Boat type

The first boat is not:

- a rowboat;
- an open-deck dinghy;
- a large sailing ship;
- a pirate ship;
- a realistic historical ship.

Target:

`small single-mast cruising sailboat with living space`

It should feel like one person could sail away for a long time and live inside it. It can be slightly cute and rounded, but not toy-like.

## Visual keywords

`warm / compact / sturdy / simple / recognizable / lived-in`

Avoid exaggerated cartoon proportions, pirate elements, ornate decoration, royal-ship styling, steampunk, and lots of cargo.

## Proportions

Use hull total length = 1.0 as the relative baseline:

- length: 1.0;
- width: about 0.28-0.34;
- visible hull height: about 0.18-0.23;
- cabin length: about 0.25-0.32 of hull length;
- cabin width: about 70-80% of deck width;
- cabin height: enough to visually believe a person could sit or stand inside;
- mast height: about 0.9-1.15 of hull length;
- main sail visual area: large enough to remain readable in the game camera.

Visual readability on a phone screen beats real-world naval accuracy.

## Hull

Bow:

- slightly pointed;
- may curve upward lightly;
- must not become pirate-ship exaggerated.

Stern:

- slightly wider;
- should feel stable;
- may include a very simple rudder.

Side silhouette:

- warm long curved hull shape;
- no multiple complex deck layers;
- no complex sidewall details;
- no excessive small windows or metal decoration.

## Cabin exterior

The cabin must be readable in the boat silhouette:

- low, slightly rounded cabin block;
- placed near mid-rear hull area;
- not so tall that the boat reads as a tugboat;
- 2-3 windows;
- one entrance indication;
- low roof;
- minimal trim.

From normal camera distance the player should read "there is a small room here." Door handles, screws, tiny frames, and wood seams are not needed.

## Future cabin space

Do not block future cabin gameplay. The first stage does not need a modeled interior, but the cabin volume must plausibly contain:

- table;
- sea chart;
- logbook;
- small ship model;
- weather instruments;
- storage;
- small windows or portholes.

## Sail

Recommended first boat:

- single mast + main sail;
- optional small fore sail only if it helps silhouette.

The main sail must be:

- large;
- simple;
- cream or warm white;
- attractive in silhouette;
- lightly asymmetrical;
- suggestive of wind pressure.

Avoid many sails, complex square rigging, pirate black sails, and large logos.

## Mast and ropes

Keep only necessary structure:

- one main mast;
- one boom or essential spar;
- very limited ropes.

Keep visually meaningful ropes to about 3-6 at normal camera distance. Do not model ropes that disappear in the phone view.

## Deck

Allowed:

- cabin;
- rudder/wheel or simple steering structure;
- 1-2 necessary nautical structures;
- minimal fixed equipment.

Do not add decorative boxes, barrels, bags, nets, many lifestyle props, or complex rope coils. Future collection belongs inside the cabin, not as deck clutter.

## Triangle budget

This is an art constraint, not a hard performance limit:

- total boat: about 8k-15k triangles;
- hull: 2k-4k;
- cabin: 1.5k-3k;
- mast/spars: 500-1k;
- sail: 500-1.5k;
- rudder/structures: 500-1k;
- ropes/other: 500-1.5k;
- remaining budget goes to silhouette refinement.

If the model approaches 30k-50k triangles, first check for meaningless detail.

## Materials

First version should use a small material set:

1. warm wood hull;
2. dark hull accent;
3. warm wood or beige cabin;
4. warm white sail;
5. dark wood mast;
6. small dark gray or metal accents.

The boat should read as a warm color block inside the blue sea and sky.

## Texture rule

First prove the boat works with plain colors. Add only later:

- very light wood indication;
- edge color variation;
- very small wear;
- minimal hand-painted variation.

Avoid realistic photo wood, complex normal maps, heavy roughness variation, and old pirate-ship weathering.

## Windows

Cabin windows are important because they make the player believe there is a personal space inside:

- 2-3 windows;
- round portholes or simple rectangles;
- slightly exaggerated size;
- readable dark marks from far away.

In the future cabin view, these windows connect the cabin to the sea outside.

## Blender production order

Do not start with detail.

1. Blockout 01: hull, cabin, mast, sail; plain colors only; screenshot validation.
2. Blockout 02: adjust length/width, cabin scale, sail area, silhouette; screenshot again.
3. Detail 01: rudder, key ropes, windows, cabin door, necessary deck structure.
4. Material 01: simple materials and very light hand-painted variation.
5. Animation: hull bob/roll/pitch, sail motion, flag, wake.

Never sculpt window frames, wood grain, knots, or ropes before blockout passes.

## Required boat review images

After Blender Blockout 01, provide:

- side view: boat type, cabin, sail, mast proportions;
- 3/4 rear view: most important normal sailing reference;
- game-camera distance: the most important shot because it tests phone-readability.

If the boat looks good close-up but becomes unreadable in the game camera, the model fails.

## Final ship question

Do not ask "does it have enough detail?" Ask:

`If I see it for two seconds, will I remember it?`

If it needs window frames, wood texture, barrels, ropes, and props to be interesting, the direction is wrong.
