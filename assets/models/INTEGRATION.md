# Final model integration

Import team-made models in subfolders here: `cassette/`, `pencil/`, `pet/`,
`sketchbook/`, `table/`, `door/`. Prefer glTF 2.0 `.glb`; use Godot wrapper `.tscn`
scenes for alignment/material overrides so reimporting art does not erase setup.
Keep DCC originals outside the shipping export. One Godot unit = one metre.
Y is up; table objects lie in XZ with their readable top toward +Y, back edge -Z.
Match the existing object dimensions; do not move the gameplay root or camera.

## Interactables

Keep the current StaticBody3D, script, `Collision`, `Visual` and all named mechanism
anchors. Assign a wrapper scene to the root's `replacement_model`: this hides only
`Visual/Model`, keeping interaction, hover, inspection and collision intact.
Adjust `Collision.shape.size` to fit the final silhouette, leaving layers unchanged.
Use convex/simple collision, never imported detailed triangle collision for props.

Origin: object centre at its current tabletop height. Cassette shell ~0.95 x 0.12 x
0.62; book ~1.0 x 0.16 x 1.2; pet ~0.62 x 0.18 x 0.75. Pencil is special: author its
shaft along local Y, centred at origin, point toward -Y, length ~1.0. `Visual`
already rotates it onto the table and the rewind interaction duplicates that
visual and stands it in the socket. Do not bake the table rotation into pencil art.

For moving details, assign `replacement_parts` entries on the same object root.
Each key points to an existing MeshInstance3D under `Visual`; each value is a
wrapper scene at local origin. This clears only that mesh and adds the supplied
visual below it, keeping the named animation/button target. Examples:

| Object | Mesh slots and required anchors |
|---|---|
| Cassette | `Visual/ReelLeft/ReelMesh`, `Visual/ReelRight/ReelMesh`; keep both Reel nodes and `ReelLeft/PencilSocket`. Reels spin around local Y. Replace/hide the Hole/Spoke meshes in the wrapper scene as needed; keep socket transforms. |
| Pencil | `replacement_model` supplies the whole shaft. It must remain under Visual so inserted-pencil duplication includes it. |
| Sketchbook | `Visual/CoverPivot/Cover` for the moving cover; keep CoverPivot (hinge rotation Z), PageSurface, its Sprite3D/Label3D content and the page resources. |
| Tamagotchi | `Visual/Button0/Cap`, `Button1/Cap`, `Button2/Cap`; preserve Button bodies, metadata and Collision children. Keep `Visual/Screen` and LCD location. Buttons press along local Y. |

Do not put a second full set of reels/buttons/cover into the static body model.
Match artwork to the existing mechanism anchors first; move anchors and simple
collisions together only when the final model proportions require it.

## Table and door

The tabletop scene has an `EnvironmentModels` node with empty `tabletop_model`
and `door_model` scene slots. Assign wrappers centred at the existing Tabletop
mesh origin or Door mesh origin. The door stays beneath the original DoorPivot;
its existing cinematic hinge animation remains unchanged. Tabletop dimensions
are whatever the current scene's BoxMesh specifies (preserve teammate edits).
No environment model is replaced until a slot is assigned.

## Materials, budgets and verification

Use StandardMaterial3D with small shared albedo atlases (typically 256–512 px,
1024 px maximum where needed), opaque materials and low mesh counts. The existing
PSX integration converts those materials after objects are instantiated. Custom
ShaderMaterials are preserved; verify them in WebGL 2 before shipping. Avoid
unnecessary transparent layers. Artwork pages intentionally keep their own filter.

After every replacement: run desktop regression, inspect/rotate/return each prop,
circle the pencil both ways, press all three pet buttons, turn the book pages,
and trigger the ending. Then re-export and run the HTTP browser test. Update export
presets with `python tools/prepare_exports.py`; assigned scenes/resources are bundled
as dependencies. Never run `tools/build_scenes.py` over artist-edited scenes.
