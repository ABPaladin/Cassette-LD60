# Gameplay rebuild

## Phase 0 — safety and cleanup
- Full file snapshot: `.rebuild_backup/2026-10-18/before-rebuild.zip`, with SHA-256 manifest.
- Safety commit preserves the previous generated prototype and existing PSX addon.
- Removed only the previously generated bedroom scene, controller, screen shader,
  four generated audio clips, test, build helper, preview and prototype notes.
- Removed its main-scene setting. No custom input map existed.
- Preserved Git history, project configuration, all addons (including psx_shader),
  icon, README and files of third-party or uncertain origin.
- Read existing PSX shader documentation: mesh ShaderMaterial plus screen ColorRect;
  supports GL Compatibility. Integration is deferred until gameplay works.

## Phase 1 — tabletop camera
- Saved tabletop scene, minimal environment, rear door and two lights.
- Mouse-edge panning with exposed strength, speed, limits and smoothing.
- Headless scene-load and six camera behavior checks pass; corrected scene numeric
  formatting during validation. Sandbox certificate-store warning is environmental.

## Phases 2–4 — inspection, cassette and pencil
- Four separate primitive object scenes, shared inspection controller, drag rotation,
  hover feedback, zoom, saved return positions, replaceable art slots.
- Configurable cassette transport, contextual analog timeline, play/pause/resume,
  seek, duration, completion, moving reels, marker/region and fragment API foundation.
- Pencil selection inserts a 3D tool into the cassette; circular angular deltas seek
  the actual transport. Clockwise rewinds, counterclockwise advances. Exposed speed,
  sensitivity, inversion, smoothing, dead radius and seek-speed limit.
- Tests pass for all four inspection round trips, transport states, regions, one
  complete 12-second rewind turn, reverse turn across +/-PI, release and cleanup.
- No mystery audio, solution, cassette player or final code has been implemented.

## Phases 5–8 — book, pet, menu and introduction
- Sketchbook remains a 3D model: hinged cover, three page resources, next/previous,
  bounded page index, close-on-return; each page accepts a replacement texture.
- Tamagotchi has three physical raycast buttons, press animation, number/select
  screen states, and an external configurable symbol sequence.
- New 3D cassette menu, shared replaceable font resource, START/QUIT, scene manager,
  fade transitions, exact requested five-line intro, typewriter reveal/advance/skip.
- Behavioral checks pass for page navigation/closing, pet state/sequence wrapping,
  menu startup, introduction advance/reveal, and skip-to-tabletop.
