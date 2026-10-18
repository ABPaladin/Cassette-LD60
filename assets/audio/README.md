# Replaceable audio

`placeholder/` contains original deterministic synthesis created for this game:
50 Hz lamp hum and harmonics, room noise, tape hiss, short signal tones and the
existing ending cues baked from `scripts/placeholder_sfx.gd`. No commercial songs,
sample libraries, external recordings or voice likenesses are used. These outputs
may be distributed with Cassette-LD60. Generator sources are in `tools/`.

The 180-second recording is explicitly a tone/transcript placeholder, NOT the final
Gloria performance or song. Caption scripts and fragments live in
`resources/investigation.tres`. Assign a final bundled recording in
`resources/test_tape.tres` and per-fragment replay clips in the investigation data.
Keep marker times aligned with the final recording. Pre-render distortion/reverb
into replacement clips for Web Sample playback. Do not overwrite teammate assets
with the placeholder generator.
