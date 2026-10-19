# Temporary spoken clue recording

These are clearly labelled development recordings, not the final actor or song.
Original draft text comes from resources/investigation.tres. It was synthesized
locally using Windows System.Speech's Microsoft Zira Desktop voice, then mixed
with original generated hiss and encoded as a bundled 180-second OGG Vorbis file.
No celebrity imitation, downloaded performance or commercial song is used.

The four WAV replay clips contain CHECK, DON'T, THE DOOR and TRUST HIM. Their
placement in the tape follows the central fragment times. Narrative lines are
also audio only; gameplay no longer reveals their transcript or clue words.
spool.wav is an original seeded noise texture, looped only during pencil movement.
The old tone-only recording remains untouched in ../placeholder/.

Replace recording and recording_notice in resources/test_tape.tres, and update
clip/time/duration/accepted_answers in resources/investigation.tres for final audio.
The generator is tools/make_temporary_voice.py with bake_temporary_voice.ps1;
do not run it over final artist recordings. It writes only this temporary folder.
