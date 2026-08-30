# First-stage prototype acceptance checklist

Use this reference before planning, implementing, or judging first-stage visual work.

## Only first-stage goal

Prove that this single vertical mobile sailing image can work:

`sea + sky + one cabin sailboat + simple distant silhouette`

If this image is not quiet, readable, and worth watching, do not add systems to compensate.

## Screen structure

The prototype should satisfy:

- vertical mobile composition;
- default sailing view without traditional HUD;
- first read: sky / sea / boat / distant view;
- sky and sea occupy most of the screen;
- the boat is the visual center, but not a character-display close-up;
- the distant view creates space and destination feeling without stealing attention;
- no decorative overload of islands, buildings, birds, props, or clutter;
- the screenshot remains readable when reduced to phone preview size.

Failure signal: the first read is "many pretty little things" instead of "a boat sailing on a vast sea."

## Graphic Stylized 3D criteria

Must satisfy:

- the world is true 3D;
- the image reads almost like a flat illustration;
- big color blocks come before texture;
- silhouette comes before model detail;
- light and shadow are simple;
- environment color count is restrained;
- no complex material workflow is used to fake quality;
- no complex post-processing is used to hide weak shapes.

Must not drift into:

- Japanese detailed background illustration;
- Ghibli-like complex nature;
- ordinary low-poly asset-pack look;
- realistic PBR;
- fairy-tale port packed with buildings;
- cuteness based on many plants and props.

## Sky

Sky is a core visual asset and must read as a large graphic shape:

- clean blue area;
- restrained atmospheric gradient;
- few clouds;
- cloud outline is more important than interior detail;
- large clouds are allowed if simple, flat, and clearly shaped;
- avoid many small cotton-like cloud clusters;
- avoid heavy volumetric effects;
- keep the horizon clear.

If clouds were reduced to two or three flat color shapes, the image should still work.

## Sea

The sea should express wind, light, distance, and motion, not physical simulation:

- large clear blue color area;
- limited water color-step variation;
- restrained glints;
- clear but simple wake near the boat;
- waves give the boat subtle life;
- sea and sky are clearly separated.

Avoid realistic refraction, complex transparency, dense noise texture, fluid simulation, every-square-meter detail, and expensive underwater systems.

## Distant view

First-stage distant scenery should remain simple:

- extremely distant island;
- mountain silhouette;
- a few rocks;
- no lighthouse unless necessary.

Requirements:

- farthest layer is low-saturation blue-gray;
- one or two clear mid/far layers are enough;
- island is primarily silhouette;
- no village detail;
- no glowing guidance.

Rule: a lighthouse is not allowed to rescue a weak image. If the image is boring without a lighthouse, sea, sky, boat, and camera are not strong enough yet.

## Main boat

The main boat is the first hero asset. It must be:

- a real small sailboat;
- visibly equipped with a cabin;
- cabin volume is readable from outside;
- plausible for future cabin entry;
- not an open-deck small wooden boat;
- not dependent on people or cats;
- not cluttered with decorative boxes;
- readable as hull + cabin + mast + sail at normal camera distance;
- built around a strong warm-color silhouette.

## Animation

Minimum first-stage life:

- hull: very light vertical bob, roll, and pitch;
- sail: not a static flat plane; small wind pressure and motion;
- flag or limited ropes: directional, restrained, not attention-grabbing;
- wake: clearly says forward motion, without glowing or racing effects.

## Camera

The camera should make the player willing to look for 25 minutes:

- boat in lower half of frame;
- enough sky space;
- enough forward-direction space;
- slight following rather than welded to the boat;
- no obvious motion sickness;
- not a third-person action-game camera.

## UI and timer

First-stage normal sailing view defaults to no traditional UI:

- no persistent 25:00;
- no progress bar;
- no coin/level/quest/minimap/home/settings;
- no route arrow or glowing path;
- no skill button;
- no reward popup.

Debug controls may exist in development, but must be off for final visual screenshots.

Timer logic is kept in the background. Timer display is separate from timer function. Do not put a permanent timer back on the screen for convenience.

## First-stage screenshot requirements

Every visual submission needs actual run screenshots from the real game camera:

- Screenshot A: normal sailing.
- Screenshot B: boat closer to camera for main-ship inspection.
- Screenshot C: distant view more visible for depth/layer inspection.

Screenshots must be vertical, with no debug UI, editor gizmos, temporary text, or conventional HUD.

## Final pass standard before cabin phase

Do not move to cabin phase until all are true:

- sea + sky + boat + simple distance alone are appealing;
- Graphic Stylized 3D direction is visible in screenshots;
- no traditional HUD;
- boat has a real cabin structure;
- boat motion is comfortable;
- sea motion is comfortable;
- sail feels alive;
- distant view does not steal attention;
- result does not look like a cheap asset pack;
- result has not returned to detailed Japanese illustration;
- reduced screenshots remain layered and readable;
- the player can watch the boat sail without the screen feeling empty.
