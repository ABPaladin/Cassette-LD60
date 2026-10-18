# Cassette — rebuilt mechanical foundation

Open `project.godot` with Godot **4.7.2** and press **F5**. The main scene is
`scenes/game.tscn`. This starts the new cassette menu, introduction, and tabletop.

## Play

- START begins Gloria's introduction. Click/Space reveals or advances a line;
  Escape or SKIP bypasses it.
- Move the cursor toward a screen edge to explore that part of the table. The
  camera is elevated and bounded; there is no walking or mouse capture.
- Click an object to lift and inspect it. Drag to rotate, wheel to zoom, Escape,
  right-click or RETURN to put it back and restore the previous tabletop view.
- Cassette: PLAY/PAUSE and a read-only tape-position strip. Use circular pencil
  movement to rewind or advance; there are no time-jump or scrub controls.
  The current recording is deliberately **silent simulated timing,
  03:00**, with no final mystery audio.
- Pencil: inspect it and choose **USE ON CASSETTE**. The pencil enters the left
  reel. Hold left mouse and move in circles around that reel: clockwise rewinds,
  counterclockwise advances. One turn is 12 seconds by default. Release to stop.
  The timeline remains live. Return exits and restores the pencil to the table.
- Sketchbook: OPEN/CLOSE and page arrows operate the 3D cover and page surface.
- Tamagotchi: click its three actual buttons. Left goes backward, middle selects
  the shown symbol, right goes forward. This is a temporary sequence, not a code.
- **F9 / DEBUG: ENDING** runs the technical ending. It stops tape playback, plays
  a rear cue, turns to the opening door, plays an original synthetic shot, flashes
  red, falls, muffles audio, distresses the picture, and fades to an ending panel.
  RETURN TO MENU starts a fresh loop. No investigation solution triggers it yet.

## Scene responsibilities

| Scene / script | Responsibility |
|---|---|
| `game.tscn`, `game_manager.gd` | Menu → intro → table → ending/menu transitions |
| `main_menu.tscn` | Single primitive 3D cassette, START and QUIT |
| `intro_sequence.gd` | Five supplied lines, reveal speed, advance and skip |
| `tabletop.tscn`, `tabletop.gd` | Environment, object instances, contextual controls |
| `tabletop_camera.gd` | Edge pan, bounds, smoothing, inspection zoom and return |
| `inspect_controller.gd`, `interactable.gd` | Shared picking, hover, lift, drag, return |
| `cassette.gd`, `tape_audio_controller.gd` | Reels, playback, seek, markers and audio bus |
| `pencil_rewind.gd` | Wrapped angular gesture → real transport displacement |
| `sketchbook.gd`, `book_page.gd` | Hinged cover and replaceable page resources |
| `tamagotchi.gd`, `pet_sequence.gd` | Physical buttons and configurable symbols |
| `ending_sequence.gd` | Ordered debug cinematic with replaceable sound cues |
| `retro_presentation.gd` | Integration of the existing PSX addon, below readable UI |

## Replacing the placeholders

All four objects are separate scenes in `scenes/objects/`. Replace the children of
**Visual/Model**, or set `replacement_model` on the object root. Keep the root
interaction script and Collision separate; adjust the collision size for new art.
Do not add a separate cassette player.

Keep these functional anchors when integrating models: cassette `Visual/ReelLeft`,
`ReelRight`, and `ReelLeft/PencilSocket`; book `Visual/CoverPivot` and `PageSurface`;
pet `Visual/Screen` and `Button0`–`Button2`. Replace their primitive meshes as needed.
These anchors do not depend on mesh vertices or imported mesh names. The default
mechanism placeholders can be replaced by artist components under the same anchors.

Page resources live in `resources/pages/`. Set `artwork` on each page to replace
the text/doodles with an artist texture. Page order is the book's exported `pages`.
The number/symbol list is `resources/pet_sequence.tres`.

`resources/interface_font.tres` is the single font reference for menu, intro,
controls and pages. Vintage Typist was not present; a system monospaced font with
fallback is used. Replace that resource with the supplied licensed font later.

## Tuning and future puzzle work

Camera home focus, table offset, speed, strength, edge margin, limits, smoothing,
inspection offset and zoom are exported on TabletopCamera. The close, steep view
starts on the cassette; existing object placements are unchanged. Rewind
sensitivity, seconds per turn, inversion,
smoothing, dead radius and maximum seek speed are exported in `pencil_rewind.gd`.

`resources/test_tape.tres` accepts a real `recording` or `recording_path`, fallback
duration, pitch, distortion, reverb, timestamp events and regions. Real stream
duration overrides simulated duration. The tape owns an isolated audio bus and
removes it on exit. Seeking updates position and region state; forward playback
emits crossed timestamp events, including frame skips. The fragment collection
and ordering API validates ownership but contains **no puzzle solution**.

The ending exposes noise and gunshot AudioStream properties and timing scale.
Current cues are generated original noise/tone bursts, not music or recordings.

## Existing PSX addon

`addons/psx_shader/` is preserved unchanged. Its README documents Godot 4.x GL
Compatibility support; the real 4.7.2 OpenGL renderer successfully compiled it.
The integration uses its existing mesh and screen shaders directly. No new PSX
shader, duplicate screen effect or downloaded asset was introduced.

- Native viewport: 960×540, scaled with nearest filtering; console pixels: 2×2.
- Mild vertex snapping/jitter. Final 5-bit color reduction and restrained dithering
  occur only in the screen shader. The UI draws afterward and remains crisp.
- Standard materials retain albedo textures/tints; transparent, additive and
  double-sided materials use the corresponding existing addon variants. Existing
  custom ShaderMaterials are left intact. For art added after startup, call
  `RetroPresentation.apply_to_model(model)` explicitly.
- The addon intentionally uses vertex lighting without dynamic shadows; the table
  has subdivisions so its lighting works with that limitation. Existing addon
  source is never rewritten to add unsupported effects.

## Safety and development tools

The pre-rebuild snapshot is `.rebuild_backup/2026-10-18/before-rebuild.zip` with a
SHA-256 manifest; safety commit **873e069** also preserves the previous prototype.
Git history, addons, third-party resources and unknown-origin files were preserved.
Godot's already tracked `.godot` cache changes are not included in gameplay commits.

`tools/build_scenes.py` generates only the new authored scenes, by named phase.
It is a development helper, not runtime architecture. Do not run it over later
artist scene edits without updating the generator or backing those edits up.

## Checks

```text
godot --headless --path . --script tests/rebuild_test.gd --quit-after 1500
godot --path . --script tests/visual_review.gd --quit-after 3000
```

The first loads real scenes and checks camera framing/bounds, all inspections,
raycasts, transport, manual circles including angle wrap, rate limit/inversion,
pages, physical pet button input, menu/intro/ending flow and native audio streams.
The second captures actual rendered views under `artifacts/` (ignored by Git).
Final graphical runs and MCP validation are recorded in `CHANGELOG.md`.
