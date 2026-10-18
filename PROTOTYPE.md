# Cassette — bedroom prototype

Open `project.godot` in Godot 4.7.2 and press **F5**. The saved main scene is
`scenes/bedroom_prototype.tscn`. All placeholder meshes, lights, collisions and
HUD elements are saved as editable nodes. Existing addons and assets are retained.

## Controls

- Mouse: look around from the fixed seat.
- E or left click: interact with the object beneath the centre dot.
- Escape: release the mouse and suspend room animation/audio; click or Escape resumes.
- R: restart the prototype.

Pick up the cassette, insert it into the deck, then press play. Pick up the pencil
to add three stages to the sketchbook drawing; a fourth interaction starts a fresh
page. Wake/feed the Tamagotchi and toggle the desk lamp. This is a repeatable room
sandbox, with no story progression or save system yet.

The scene renders at 640×360, scaled to a 1280×720 window with the aspect ratio
preserved. Low-poly primitives, muted colours, grain, colour quantization and a
vignette provide the initial PS1-inspired treatment. Original generated audio
provides room hum, tape hiss, clicks and a pet chirp.

## Development

- `scripts/bedroom.gd`: input, raycast targeting, inventory and prop state.
- `shaders/analog.gdshader`: restrained screen treatment, underneath the HUD.
- `tests/prototype_smoke.gd`: loads the real scene and checks raycast reach, input,
  pickups, playback, drawing, pet state, lighting, camera bounds and restart.
- `tools/build_prototype.py`: one-time geometry/audio construction helper. It
  deliberately refuses to overwrite a populated scene or existing audio.

Run the behavioral check with your Godot executable:

```text
godot --headless --path . --script tests/prototype_smoke.gd
```

For a rendered preview, omit `--headless` and append `-- --capture`.
