# Camera (`kind: camera`)

Packages: `camera`, `mobile_scanner`, `camerawesome`, or a first-party plugin that opens an `AVCaptureSession`.

**Profile:** `release_on` (`inactive` by default, or `paused`), `screens`.

## Implement

1. **Release policy.** Keep releasing the controller on the profile's `release_on`. The default is `inactive`, as the `camera` plugin recommends on iOS. Add a comment at that spot: in Split View the camera is intentionally off.
2. **Preview and overlays.** On the inner display the preview keeps its aspect ratio and is centered. Frames, stickers, scan windows and guides are positioned relative to the **preview rect**, not the screen. Fix layouts that use the screen size for overlay positions.
3. **Re-initialization.** Open the camera screen on the simulator, fold and unfold. If the preview stays frozen after `resumed`, dispose the old controller, create a new one and rebuild with a new key. Add a widget test for `inactive` → `resumed` with a fake controller.

## Verify

- [ ] After fold/unfold the preview shows images again within 2 s without leaving the screen.
- [ ] The release spot has a comment about Split View.
- [ ] If re-initialization changed, an `inactive` → `resumed` test exists and passes.
- [ ] The PR says the camera was validated on the simulator only (if so).

## Decisions

- Release on `inactive`: the plugin's iOS guidance; a camera in Split View is an edge case.
- Not on `paused` only: that would keep the camera on in Split View, at the cost of odd behavior with Control Center and calls.
