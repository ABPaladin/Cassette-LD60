# Cassette release handoff — 18 October 2026

The playable placeholder release is packaged. Final voice/song recordings and team
illustrations are still missing. Browser validation was stopped at the user's
request; this is not a claim of a fully verified browser release.

## Delivered gameplay

- Four configurable listened fragments at 00:24, 00:51, 01:19 and 01:44. Seeking
  alone awards nothing. Playback within a two-second tolerance earns the fragment
  after one second of listening. These values are editable in the resource.
- Pencil circles remain the tape-navigation mechanic. There are no five-second
  jump buttons and the timeline cannot be scrubbed. Remove the pencil to listen.
- Notebook clues, Tamagotchi sequence 2, 4, 1, 3, four reconstruction slots,
  fragment replay, retryable incorrect answers and a single-shot solved signal.
- Correct reconstruction displays DON'T TRUST HIM. CHECK THE DOOR., waits, then
  starts the existing ending. Interactions and tape stop; ambience falls silent
  before the shot. The existing camera and ending choreography were preserved.
- Quiet original lamp hum, room tone and tape hiss, playback ducking, and separate
  Master / Ambience / Cassette / SFX controls. Ending cues are prerecorded for Web.
- Replaceable 3D sketchbook artwork with aspect-preserving fitting and captions.
- Optional visual replacement slots for props, mechanism parts, table and door.
  Existing placeholder meshes stay in use until the slots are assigned.

## Validation actually completed

Desktop Godot 4.7.2 GL Compatibility: investigation regression and full mechanical
regression both finished with zero failures. They cover playback/discovery,
wrong/right answers, duplicate-solve prevention, ambience, illustration fitting,
fixed camera, inspection, circular seeking, pages, pet buttons, menu/intro,
ending completion and menu return. The editor MCP error list was empty at its
last check. Replacement slots have not been exercised with final artist models.

Chromium over local HTTP, inside a 948 x 533 opaque-origin sandboxed iframe:
menu, START audio unlock, intro, fixed camera position/FOV, book clues, physical
pet buttons, cassette play/pause, pencil insertion, real circular mouse seeking
in both directions, and all four discoveries through playback passed. Seeking
alone did not discover fragments. Existing PSX shaders rendered in WebGL 2.

The run was stopped before the browser reconstruction/ending/restart checks
finished. Firefox was installed but its gameplay run was not completed. The
production exports were packaged after that stop and were not playtested.
Small-window resizing and the actual Ludum Dare host remain unverified.

Export issues found and fixed: missing dynamically loaded PSX shader includes,
missing default audio buses, and a solution sequence lost during resource export.
The solution now uses an exported typed string array, which retained its values
in the bundled pack and passed the Chromium pet-sequence check.

## Missing content and known limitations

- No original Emily portrait or other teammate illustration textures were found
  in the project. Import `assets/sketchbook/gloria.png`; the drawing page is ready
  to load it. Additional pages accept `artwork` or `artwork_path`. No replacement
  drawings were generated. See `assets/sketchbook/README.md`.
- The three-minute recording uses original generated tones/hiss and explicitly
  marked transcript captions. It is not a voiced performance or the final song.
  Replace the recording in `resources/test_tape.tres` and fragment clips/times,
  captions, order and reveal timing in `resources/investigation.tres`.
- Final models and Vintage Typist font were not supplied. Placeholder models and
  bundled OFL-licensed Courier Prime remain. The current teammate layout crops the top of the
  pet; its visible portion remains selectable. Camera/layout were not redesigned.
- Browser audio start was instrumented, not judged for intelligibility of future
  speech. Final sound mix and 10–15 minute pacing need the final content.

## Deliverables and rebuilding

- Upload `build/web-cassette.zip` (approximately 10.7 MiB), containing `index.html`
  at its root. Its unpacked production files are in `build/web/`.
- Windows fallback: `build/windows/Cassette.exe` (embedded pack).
- Model workflow: `assets/models/INTEGRATION.md`.
- QA files and screenshots are under `artifacts/`, excluded from export and Git.

The Web preset uses Compatibility/WebGL 2 and a single thread. PWA is disabled;
packaging disables persistent paths and service-worker probes. Assets are local;
no external audio or runtime streaming is required. Debug ending controls and the
QA telemetry feature are disabled in the production release configuration.
Editor integration, backups, tests and source-only documentation are excluded.

After the reported editor **Run in Browser** failure, presets were changed to
export all game resources with development-folder exclusions instead of a
manually enumerated resource list. Only the production Web preset is runnable;
Web QA is export-only. The shared SystemFont was replaced with a bundled FontFile
because system fonts fall back to Godot's default on Web. If the already-open
editor still uses its old export preset, save your work and reopen the project
before using Run in Browser again. Close the previous browser tab to avoid an
old running instance. These packaging/font changes did not restart the full tests.

Run `python tools/prepare_exports.py`, export the **Web** release preset from Godot,
then run `python tools/package_web.py build/web`. Wait for Godot to finish exporting
before packaging. Export the **Windows** release preset for the desktop fallback.
For a local preview, run `python tools/serve_web.py` and open
`http://127.0.0.1:8765/web/index.html` (never a file URL).

Recheck the [Ludum Dare embedding guide](https://ludumdare.com/resources/guides/embedding/)
when uploading. This packaging follows its root-index, 256 MB and sandbox rules.
Godot's [Web export documentation](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_web.html)
describes WebGL 2 and sample-audio limitations; effects here use bundled audio
instead of relying on unsupported realtime sample effects.
