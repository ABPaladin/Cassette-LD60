# Isolated artist meshes ? updated integration

Safety checkpoint: `753dabc755a851a9abace3752645e7e7e18ac363`.

## Source state

- Updated cassette: `../cassette/Cassette .glb` (space before extension).
- Updated pet: `../pet/Tamogotchi.glb`.
- Pencil: `../pencil/Pencil.glb`, unchanged from the previous integration.
- No usable sketchbook mesh: revised files contain only an empty Sketchbook_ROOT
  branch. Keep the working sketchbook and its original artwork.
- All GLBs still include unrelated scene objects. Never instance whole exports.

SOURCE_PARTS.json records the exact named source mesh for each isolated ArrayMesh
and the center subtracted from its vertices. Originals and textures are preserved.
Updating a source GLB does not automatically regenerate these isolated copies.

## Current alignment

The updated cassette and pet meshes already use XZ tabletop orientation, front +Y.
Their old axis-swapping transforms were removed; existing visual nodes now carry
only scaling and source-relative positions. No gameplay script was changed.

Cassette: body fits 0.95 x 0.12 x 0.62. Artist ReelRight is at negative X and is
mapped to the gameplay ReelLeft; artist ReelLeft maps to gameplay ReelRight.
The shell has open holes at those source centers (vertical mesh-ray check).
Reels retain the artist's relative height inside the shell; the old Y=0.07
floating correction was removed. Recentered meshes rotate about the existing
Y-axis anchors. PencilSocket is 0.012 above the left reel center. The complete
visual is lowered 0.048, leaving its bottom 0.002 above the existing tabletop.
The menu instances this same updated cassette scene; its logic is unchanged.

Pet: body fits 0.62 x 0.14 x 0.75. Body, LCD, and buttons use source-relative
positions and preserve separate gameplay anchors. The body is lowered 0.058 to
rest just above the tabletop; its existing collision follows. The live Screen
label is 0.006 above the LCD and retains pixel size 0.0034. Buttons retain their
metadata, hit boxes and local negative-Y press animation. The newly supplied
body texture is preserved; temporary dark caps and green LCD remain where needed.

Pencil: unchanged mesh and local-axis conversion retained. The existing negative-Y
Tip marker still matches the actual pointed mesh end. Visual and collision were
lowered 0.095732413 onto the tabletop. Insertion continues to duplicate Visual and
use the existing Tip/socket calculation; input direction and sensitivity are unchanged.

Artist cassette/reel/pet materials currently contain checker/UV-test textures;
these were preserved rather than replaced or painted over.

## Focused validation

One Godot preview loaded the revised GLBs, regenerated eight isolated resources,
checked expected object mesh counts (3/1/5), reel pivots, pencil tip, LCD/button
paths and collision metadata. Zero integration-check failures.

Contact sheet: `artifacts/updated-models-contact.png` (local, ignored by Git).
Tiles left-to-right, top-to-bottom: menu, tabletop, cassette inspection, inserted
pencil, pet inspection, photograph front, photograph back, existing sketchbook.
Visual inspection confirmed the two photo faces, menu cassette orientation,
recessed reel alignment, inserted pencil, readable LCD and aligned buttons.
No full gameplay, puzzle or browser tests were run. The engine emitted its existing
Windows certificate-store warning; no script/resource errors appeared in this pass.
