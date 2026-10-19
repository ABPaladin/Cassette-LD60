# Sketchbook: Blender modeling and Godot integration guide

This guide describes the current button-based sketchbook, inspected on 19 October 2026. Deliver one `sketchbook.glb`. Keep gameplay, collision, text and drawing management in Godot. No Blender animation is required.

Only this document was created. The game was not run or changed for this inspection. Integration steps below are instructions for a future asset import, not completed changes.

## 1. Current Godot implementation

Scene: `res://scenes/objects/sketchbook.tscn`.

```text
Sketchbook (StaticBody3D; scripts/sketchbook.gd)
├── Collision (CollisionShape3D; BoxShape3D)
└── Visual (Node3D; inspection rotates this whole branch)
    ├── Model (Node3D; static placeholder geometry)
    │   ├── Back (MeshInstance3D)
    │   └── Pages (MeshInstance3D)
    ├── CoverPivot (Node3D; animated hinge)
    │   └── Cover (MeshInstance3D)
    └── PageSurface (Node3D; content anchor, NOT a page mesh)
        ├── Label3D [created at runtime]
        └── Sprite3D [created at runtime]
```

The runtime children are held in `page_label` and `page_art`; their generated node names are not a model contract.

| Responsibility | Current implementation |
|---|---|
| OPEN / CLOSE | `scripts/tabletop.gd` calls `sketchbook.gd:set_open()` |
| Cover animation | Tweens `Visual/CoverPivot.rotation.z` from 0 to **2.75 radians (157.6°)** in **0.4 seconds**, cubic ease in/out |
| `< PAGE` / `PAGE >` | Calls `turn_page(-1)` / `turn_page(1)`; requires an open book; clamps at first/last page |
| Page animation | Immediately replaces content, then lifts `PageSurface.position.y` to **0.075** over 0.10 s and returns it to **0.03** over 0.12 s |
| RETURN | Calls inspection controller's `leave()`; the sketchbook closes and returns to its rest transform |
| Picking and inspection | `scripts/inspect_controller.gd` raycasts collision layer 2, selects the root, supports drag rotation, wheel zoom, ESC/right-click return |
| Object movement | `scripts/interactable.gd` lifts the root **0.55 units** over 0.35 s; inspection distance is **1.9**; mouse drag rotates `Visual` |
| Page data | `scripts/book_page.gd` resources in `resources/pages/`; selected by `sketchbook.gd` |

There is no active corner-drag page-turn method in `sketchbook.gd`, no physical turning leaf, and no AnimationPlayer in this scene. The page animation moves text/art, not the static paper block. Do not model a complicated articulated stack expecting the current code to animate it.

### Page content and artwork

The three configured resources are `notes.tres`, `drawings.tres`, and `clues.tres`. Their order is the exported `pages` array. Fields include `title`, `text`, `artwork`, `artwork_path`, `artwork_caption`, and `investigation_clues`.

- Godot creates a horizontal Label3D and Sprite3D under `PageSurface`, each rotated **−90° around X**. Their readable side faces up, +Y.
- Without artwork, the label shows title and text; investigation pages obtain their text from the investigation resource.
- With artwork, Godot changes `Sprite3D.texture` and fits its original aspect ratio inside **0.86 × 0.74 units**. Art is centered at local Z = **−0.16**, with a **0.003-unit** upward offset from `PageSurface`.
- The title and short artwork caption are placed toward the reader at local Z = **+0.39**. Full body text is not displayed alongside artwork by the current code.
- Text and artwork disappear when closed. These are 3D children, not a fullscreen document.
- Artwork uses linear filtering. Preserve its readability; do not bake the portrait or changing clues into a cover atlas.

**Asset status:** `drawings.tres` points to `res://assets/sketchbook/gloria.png`. The directory currently contains only `README.md`; the actual portrait is absent. The filename is a legacy technical path for Emily's portrait. Supply the team's actual artwork at that path, or later update the page resource deliberately. Do not invent a replacement or blindly rename references.

## 2. Recommended Blender Outliner

Use this simple authoring hierarchy. Its names intentionally match the existing Godot geometry and hinge.

```text
Sketchbook_ROOT (Empty; identity transform at book center)
├── Model (Empty; identity transform)
│   ├── Back (Mesh; back cover)
│   ├── Pages (Mesh; stationary paper block)
│   └── Spine (Mesh; optional stationary binding)
└── CoverPivot (Empty; left-edge hinge)
    └── Cover (Mesh; front cover, with inner and outer faces)
```

| Object | Artist instructions |
|---|---|
| `Sketchbook_ROOT` | Export root only. It does not replace the Godot StaticBody3D or receive gameplay scripts. Keep scale 1 and rotation 0. |
| `Model` | Groups stationary geometry. Back, Pages and optional Spine stay here. |
| `Back` | Low-poly back cover. Center its mesh origin on the part; place it using the coordinates below. |
| `Pages` | One thin, closed paper block with a flat blank upper surface. Page-edge stripes may be textured. This block does not animate with page buttons. |
| `Spine` | Optional thin stationary binding at the left edge. Keep it clear of the moving cover. It may be combined with Back. Its precise shape is an artistic choice; there is no existing spine mesh. |
| `CoverPivot` | Independent Empty at the hinge. This is the rotation reference; do not center it on the cover. |
| `Cover` | Separate movable front cover. Its geometry origin is at its center, offset from the parent hinge. Model the inside too, since it becomes visible when opened. |

Back, Pages and Spine may be combined for optimization if their materials remain distinguishable. Keeping them separate initially makes integration simpler. **Never combine Cover with stationary geometry.**

Do not add separate `Page_Left`, `Page_Right`, left/right stacks, bones, or page-turn pivots for the current version. The game displays one logical page at a time. A two-page spread would require new content placement and code; it is not part of this replacement.

## 3. Dimensions, orientation and origins

These measurements come from the current scene, not from a real-world notebook. The game uses a deliberately large prop scale. **Match it rather than shrinking to a typical 20 cm notebook.** Use Blender Metric units, Unit Scale 1.0; one project unit corresponds to one meter.

In Godot: X goes across the page, Y is up, Z runs along the spine. The top of the written page is **−Z**, and its bottom is **+Z**. The hinge is at **−X**.

For Blender's standard glTF +Y-up export: Blender **X → Godot X**, Blender **Z → Godot Y**, and Blender **Y → Godot −Z**. Model flat in Blender's XY plane, front facing +Z, page top toward +Y, spine at −X. Do not add a compensating 90° rotation to the root.

| Part | Godot dimensions X/Y/Z | Blender dimensions X/Y/Z | Godot local position | Blender local position |
|---|---|---|---|---|
| Back | 1.00 / 0.06 / 1.20 | 1.00 / 1.20 / 0.06 | (0, −0.04, 0), under Model | (0, 0, −0.04) |
| Pages | 0.94 / 0.04 / 1.14 | 0.94 / 1.14 / 0.04 | (0, 0, 0), under Model | (0, 0, 0) |
| CoverPivot | Empty | Empty | (−0.50, 0.04, 0), under Visual | (−0.50, 0, 0.04), under Sketchbook_ROOT |
| Cover | 1.00 / 0.045 / 1.20 | 1.00 / 1.20 / 0.045 | (+0.50, 0, 0), relative to hinge | (+0.50, 0, 0), relative to hinge |

The overall closed placeholder spans approximately **1.00 × 1.20 × 0.1325 m** (width × length × thickness). The collision box is **1.00 × 0.16 × 1.20** in Godot X/Y/Z, centered at the root. Keep the existing collision and tabletop placement.

The open cover swings upward, then out to the **left**; it stops short of lying completely flat. In Blender, preview by rotating CoverPivot approximately **−157.6° about local Y**, then return it to zero before export. Godot animates the equivalent **positive local Z** rotation.

Keep the paper top at Godot Y = **0.02**. The existing content anchor sits at Y = **0.03**. Taller paper or an extra face at the content height can obscure text or cause z-fighting. Preserve a blank central area for artwork and a lower area for captions.

Apply **Rotation & Scale** to mesh objects before final parenting; retain deliberate locations and origins. After parenting, check that local transforms match the table, mesh scale is (1,1,1), and the hinge rotation is zero. Do not apply Location indiscriminately: that can bake away the center/hinge offsets needed for replacement.

## 4. UVs, materials and performance

- UV unwrap Back and Cover, including the visible inside cover. Use a separate material slot for paper, e.g. `MAT_Paper`, and a cover material such as `MAT_Cover`.
- Use simple Principled BSDF materials with base-color textures and high roughness. Bake procedural patterns to image textures; do not depend on Blender-only nodes.
- Keep the paper upper face blank and light enough for dark writing. The current drawings are **Sprite3D textures controlled by Godot**, not textures swapped on the imported paper mesh. Paper UVs are for paper grain/edges only.
- Aim for **500–1,500 triangles total**, roughly **2–3 materials**, and one **512²** cover/paper atlas where practical. Up to 1024² is reasonable for a necessary close-up detail. These are suggested budgets, not engine limits.
- Keep teammate drawings separate, preserve aspect ratio, and use up to **1024 px on the longest edge** for the shipping illustration, retaining originals outside the export. Do not pixelate the source artwork destructively.
- Prefer opaque materials and real thin cover thickness. Avoid transparent page stacks, excessive bevel segments, and a mesh for every paper sheet.
- Check normals on both cover sides. No lights, cameras, collision meshes, armatures, or embedded text labels are needed in the GLB.
- The existing retro system converts standard mesh materials to its PSX shader. Do not add another PSX shader to the asset. More elaborate PBR details may not survive that conversion; prioritize silhouette and base color.

## 5. Export from Blender

1. Save the `.blend` source separately. Leave the book **closed**, CoverPivot rotation zero, root rotation zero and scale one.
2. Select Sketchbook_ROOT and every intended descendant, including hinge and grouping Empties.
3. Choose **File → Export → glTF 2.0**, format **glTF Binary (.glb)**.
4. Enable **Selected Objects** and retain hierarchy. Use standard **+Y Up** conversion. Include UVs, normals and materials; bundle image textures in the GLB.
5. Apply necessary geometry modifiers (or use the exporter's Apply Modifiers option). Triangulate deliberately if triangulation changes the silhouette or shading.
6. Disable animation export. Do not export cameras/lights or use Draco compression for this simple asset.
7. Export `sketchbook.glb`. Reimport a copy into a clean Blender scene if desired to check hierarchy and appearance. The Godot integrator must check dimensions and axis conversion after import.

Blender exporter option placement varies by version. Reference: [Blender glTF 2.0 exporter manual](https://docs.blender.org/manual/en/latest/addons/import_export/scene_gltf2.html).

## 6. Godot integration: preserve the gameplay anchors

Suggested new asset location: `res://assets/models/sketchbook/sketchbook.glb`. This is a proposed destination, not an existing asset.

**Recommended approach: replace mesh resources in the existing scene.** Import the GLB, inspect its component meshes, and assign the imported Back, Pages and Cover Mesh resources to the existing MeshInstance3D nodes. Because the specified mesh origins and local transforms match, retain the existing node transforms. Add the optional Spine mesh under Model using its imported local transform. Do not replace the entire Sketchbook scene with the GLB scene.

This yields the following exact gameplay hierarchy:

```text
Sketchbook (existing StaticBody3D; existing sketchbook.gd)
├── Collision (existing CollisionShape3D; unchanged)
└── Visual (existing Node3D; unchanged)
    ├── Model (existing Node3D)
    │   ├── Back (existing MeshInstance3D; imported Back mesh/material)
    │   ├── Pages (existing MeshInstance3D; imported Pages mesh/material)
    │   └── Spine (optional new MeshInstance3D; imported static mesh)
    ├── CoverPivot (existing Node3D; retain position and animation)
    │   └── Cover (existing MeshInstance3D; imported Cover mesh/material)
    └── PageSurface (existing Node3D; unchanged)
        ├── Label3D [existing runtime creation]
        └── Sprite3D [existing runtime creation]
```

Clear the old placeholder `material_override` on each replaced MeshInstance3D so imported materials can show. If materials were assigned as per-instance surface overrides in the imported scene rather than embedded in its Mesh resource, copy those material assignments too. Keep the original GLB imported resource intact; make integration edits in the existing Godot scene, not inside generated import files.

If an imported part contains multiple mesh children, make a small visual-only wrapper scene for that part rather than attaching gameplay logic to artist mesh names. Center a cover wrapper at the cover mesh's center if placing it under the existing `Cover` node; the hinge offset is already supplied by that node and CoverPivot.

### Paths the scripts require

All paths below are relative to the Sketchbook root:

| Path | Why it must remain |
|---|---|
| `Visual` | Whole-object inspection rotation, reset and hover scaling |
| `Visual/Model` | Existing static-model replacement contract |
| `Visual/CoverPivot` | `set_open()` directly animates this exact node |
| `Visual/PageSurface` | Script attaches text/art, controls visibility and applies page-button flutter |

`Visual/CoverPivot/Cover` is the existing movable mesh attachment, although `sketchbook.gd` does not directly look up that child. `Back` and `Pages` are art-only names; keeping them makes replacement straightforward. `Collision` remains a child of the existing StaticBody3D on collision layer 2, mask 0. Do not parent collision under the rotating Visual.

No gameplay script path changes are needed with the recommended mesh-swap approach. Keeping the entire GLB nested under `Visual/Model/Sketchbook_ROOT` would leave its cover outside the animated `Visual/CoverPivot` branch. That alternative would require restructuring or a new animation reference; merely matching the imported hinge's name is insufficient.

### Existing replacement exports: useful limitation

`interactable.gd` also exposes `replacement_model` and `replacement_parts`:

- `replacement_model` hides **only `Visual/Model`** and adds the replacement under Visual. Assigning a complete book GLB there would leave the old animated cover visible and the imported cover unconnected. Do not use a whole-book GLB in that slot unchanged.
- `replacement_parts` can put a visual-only scene under `Visual/CoverPivot/Cover`; when the anchor is a MeshInstance3D it clears its old mesh. The scene must use the center-origin convention above and avoid repeating the existing +0.5 hinge offset.
- Replacing a Node3D anchor through that dictionary does not automatically remove its existing children. Do not assume it clears Model or CoverPivot.

These are optional integration routes, not a reason to alter working scripts. The mesh-resource swap is sufficient for this deliverable.

### Future integration acceptance checks

After importing the final model, the integrator should check once that clicking the unchanged collision selects the book; OPEN/CLOSE moves only the cover; both page buttons still show all three resources; the portrait and captions remain unobscured; drag rotation and RETURN work; and the open cover clears the paper. Preserve `inspect_distance`, root transform, and all UI callbacks. No tests were run as part of writing this guide.

## 7. Common mistakes to avoid

- Modeling a realistic small notebook instead of matching the existing 1 × 1.2-unit footprint.
- Joining the front cover to the paper block or putting the hinge at the cover center.
- Exporting an open pose, negative scale, or an extra root axis correction.
- Replacing the gameplay root, losing collision layer 2, or renaming the three required Visual anchors.
- Importing a whole static book and expecting its internal CoverPivot to be animated automatically.
- Adding left/right page meshes and expecting the current single-page code to populate them.
- Raising the paper into the text/art plane, baking changing clues into textures, or baking Emily's portrait into the cover.
- Leaving placeholder material overrides active and mistaking them for broken GLB materials.
- Supplying Blender keyframes that fight Godot's existing cover tween.
- Assuming the portrait is bundled: its configured file is currently missing and must come from the team.
