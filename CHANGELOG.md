# Gameplay rebuild

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
