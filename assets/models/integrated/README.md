# Isolated artist meshes

Checkpoint before integration: `c4696b775f7b19740db2ab99b61346c5c0e3c2cd` (pushed to origin/main).

The original Cassette.glb, Pencil.glb and Tamogotchi.glb each contain the whole
Blender scene. Do not instance them directly as gameplay props.
These nine ArrayMesh resources contain only the named parts listed in
SOURCE_PARTS.json. Vertex positions were recentered around their bounds; normals,
UVs, indices and source materials were retained. Original GLBs remain unchanged.
The center values in that file are the offsets subtracted from source vertices.

## Integration locations

- `scenes/objects/cassette.tscn`: Shell, ReelLeft/ReelMesh, ReelRight/ReelMesh.
  Source +X faces upward; +Z maps left, +Y maps toward the top of the cassette.
  Body fits the existing 0.95 x 0.12 x 0.62 footprint. Reels keep separate Y-axis
  anchors, centered over their supplied body locations and raised to Y=0.07.
  PencilSocket stays under ReelLeft. Old label/hole/spoke meshes are cleared;
  their nodes remain for compatibility.
- `scenes/objects/pencil.tscn`: Shaft uses the supplied Pencil mesh, rotated from
  source Z to local Y. Its pointed end is at the existing Tip marker Y=-0.57;
  total length is 1.10. The existing Visual rotation lays it horizontally.
  Lead's old geometry is cleared. Existing temporary pencil material is retained.
- `scenes/objects/tamagotchi.tscn`: Shell, LCD and three independent Cap meshes.
  Body fits 0.62 x 0.14 x 0.75 including its top loop. Button bodies and hit boxes
  follow the imported cap centers. Caps remain at local position zero so the
  existing negative-Y press animation works. Screen is 0.006 above the LCD and
  its pixel size is 0.0034 to fit selected-number brackets. Existing shell,
  button and LCD materials are retained. Layers and button metadata are unchanged.

Artist meshes are scaled/oriented by the existing visual scene nodes; gameplay
roots, scripts, audio, page artwork, camera and PSX effects are unchanged.
Mesh copies are stable across original GLB reimports. If artists update a source,
regenerate the affected isolated mesh explicitly and recheck its anchor offsets.
No imported whole-scene instance is used. No sketchbook GLB was supplied.

## Validation performed

One headless extraction/resource-load pass checked all three imported sources,
all nine isolated resources, scene loading, expected mesh counts (3/1/5), reel
centering, pencil-tip alignment and required button/LCD/collision references.
Zero integration-check failures. The headless engine emitted an unrelated Windows
root-certificate-store warning. Interactive appearance, button clicks, rewind
and browser rendering were not play-tested; no Web export was made.
