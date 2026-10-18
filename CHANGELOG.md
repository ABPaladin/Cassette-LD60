# Gameplay rebuild

## Targeted camera and pencil-navigation adjustment — 2026-10-18
- Tightened tabletop framing to a close, near-overhead view centered on the
  cassette; slowed edge pan, widened the neutral center and capped diagonal speed.
  Camera home focus remains configurable. Existing object placements are unchanged.
- Removed both five-second jump buttons and direct timeline scrubbing. PLAY/PAUSE
  and the position readout remain; circular pencil movement controls tape seeking.
- Preserved the working angular gesture implementation, ending sequence, scene
  geometry, sketchbook resources and PSX addon. The current drawing page resource
  contains placeholder text, not an assigned girl texture; no artwork was edited.
- Graphical Godot 4.7.2 regression: 79 checks passed, including both circular
  directions, angle wrap, center crossing, release, camera bounds and full game loop.
  Rendered tabletop/inspection/pencil/ending views captured and reviewed.
- MCP script validation passed for all changed scripts; all 9 scene references
  passed project validation. Editor error list: 0.
- Initial added test needed an explicit Array type; corrected before the passing
  renderer run. Verbose renderer log includes a nonfatal NVIDIA profile message
  (NVAPI_EXECUTABLE_ALREADY_IN_USE); the capture run completed without errors.

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

## Phases 9–11 — audio foundation, ending and existing PSX integration
- Tape data accepts real streams/paths or simulated duration, pitch, optional
  distortion/reverb, timestamp and region events (including frame skips), and a
  future fragment-collection/order API. No final audio puzzle is authored.
- F9 / clearly labelled DEBUG button runs the rear-noise, door-turn/open, synthetic
  shot, red flash, camera fall, muffling, image distress, fade and menu-return flow.
- Existing addon shaders are referenced directly; mild vertex wobble and nearest
  pixels, one final color/dither pass, UI on a separate later canvas layer.
- Verified all 95 pre-existing addon files against the safety manifest: unchanged.
- Renderer screenshots reviewed for menu, introduction, tabletop, all four objects,
  inserted pencil, door and ending. Corrected pencil clipping, dark cassette body,
  rear-door visibility, and gesture release/continuation over UI controls.

## Phase 12 — full validation
- 22 GDScript files pass MCP validation. All 9 scene references pass validation.
- Graphical 4.7.2 GL Compatibility regression run: 70 checks, zero failures; no
  errors or warnings in the renderer log. Native audio play/seek/pause/resume tested
  with a silent WAV stream as well as the simulated transport.
- Actual pointer raycasts tested for all objects and all three physical pet buttons.
- Editor MCP error list: 0. Backup ZIP integrity verified.
- Sandbox-only headless runs report Windows certificate-store access restrictions;
  one headless audio teardown warned about ObjectDB cleanup. Neither appears in the
  final graphical run outside that sandbox.
- Remaining content is intentional: primitive models, temporary pages/symbols,
  simulated recording, synthetic cinematic cues, font fallback, and debug ending.
  Final recordings, mystery clues, solution, artwork and 10–15 minute pacing are
  not authored in this mechanical foundation.
