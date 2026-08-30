# Project reset and current design basis

Use this reference when deciding product scope, player identity, UI direction, or whether an idea belongs in the current phase.

## Current product

This is a mobile sailing game with focus timing at its core. It is not a traditional adventure game, RPG, open-world exploration game, port-management game, or productivity dashboard.

The core experience is:

`depart -> sail -> see the distance -> arrive or return -> organize voyage results in the boat cabin -> sail again`

The focus period should feel quiet, companionable, in motion, and remembered by the world. It should create expectation for the next voyage without pressure mechanics.

## Current hard boundaries

Do not implement unless the user explicitly changes scope:

- land free-walking;
- third-person island exploration;
- town roaming;
- land quest systems;
- combat;
- RPG maps or character progression;
- open-world character movement;
- port management;
- house building;
- traditional mobile HUD;
- complex currency systems;
- daily tasks or streak-pressure mechanics;
- large NPC systems;
- cat-as-protagonist systems.

The player's main movement is at sea. Islands are destinations, distant landmarks, route nodes, and memory anchors, not first-stage explorable land maps.

## Player identity

The player is the captain, but the captain does not need to appear on screen. The player is not watching a character operate the boat; the boat itself is the player's presence and body in the world.

## Cat sailor / mate

A cat may be added later, but it must not replace the player as captain. Its role is sailor, mate, crew member, or companion. It can work, watch the sea, sleep, observe weather, and occasionally comment, but it is not an MVP priority and should not force a dialogue-heavy system.

## Visual direction

The current target is Graphic Stylized 3D:

- a real 3D world;
- a final image that feels close to a moving flat illustration;
- compressed visual information;
- strong silhouette and big color-block readability.

Do not use these as primary references:

- traditional Japanese animation background;
- Ghibli-like complex scenes;
- high-detail cartoon 3D;
- realistic PBR;
- richly textured fairy-tale ports;
- ordinary low-poly asset packs.

## Cargo-style lesson

Do not reduce the direction to "low polygon count." The real lesson is visual information compression:

`big color blocks > silhouette > depth layers > composition > light/shadow > detail`

Large empty sea and sky areas are intentional. Empty space is not missing content when it strengthens quiet sailing.

## Diegetic UI

The default sailing screen should be close to zero traditional HUD. Avoid always-visible timers, progress bars, coins, levels, task lists, minimaps, home/settings buttons, glowing routes, and skill buttons.

Information should live in the world when possible:

- direction through wind, sail, flag, birds, clouds, light, waves, and distant landmarks;
- destination approach through silhouettes, birds, coast sounds, bells, light, wave state, and ship motion;
- time through sail state, light, sun position, shadows, voyage phase, and subtle environmental change.

Precise time may be available through a deliberate interaction, temporary overlay, or world object, but it should not be permanently displayed by default.

## Boat and cabin relationship

The boat is both vehicle and home. The previous "return to a separate house" idea is replaced by "return to the player's own cabin."

The cabin is not a conventional menu. It is a real 3D private space where objects carry functions:

- logbook for voyage history;
- sea chart for navigation and map traces;
- small boat model for ship upgrade and appearance;
- weather instruments for weather/sea-state systems;
- storage containers for collected voyage objects.

These functions are not first-stage gameplay, but the main boat must be designed so this future cabin relationship remains plausible.
