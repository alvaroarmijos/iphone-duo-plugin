---
name: lifecycle-camera
description: iPhone Duo step 6/8. Keeps camera screens and orientation locks working when the iPhone Duo folds/unfolds and in Split View - portrait lock only on compact screens, re-evaluated on display changes, camera released on inactive and re-initialized on resume. Use as part of iphone-duo:adopt or alone for "camera freezes after fold/unfold" or "orientation lock on iPhone Duo".
---

# Step 6 — Life cycle, orientation locks and the camera

**Why:** on the iPhone Duo every app takes part in Split View (visible while `inactive`), and folding/unfolding moves the app between displays in the foreground. A hard portrait lock makes no sense on the inner display (which ignores it anyway), and a camera controller that isn't rebuilt on `resumed` leaves a frozen preview.

**Reads from the profile:** `camera.used`, `camera.release_on` (default `inactive`), `camera.portrait_lock_screens`, `layout.orientation_policy`. Template: `references/compact_portrait_lock.dart`.

## Scope

In: screens that call `setPreferredOrientations`; camera screens' sizing (`MediaQuery.sizeOf`), preview aspect ratio and overlay alignment on the inner display; camera release/re-init across `inactive`/`resumed`.
Out: keeping the camera live in Split View (unless the profile says so); upgrading the `camera` plugin (separate change if needed); landscape support on standard phones; other life cycle consumers with nothing to pause.

## Implement

1. **Conditional lock.** For each screen in `camera.portrait_lock_screens` (and any other `setPreferredOrientations` caller the developer wants covered): replace the unconditional lock in `initState` with `CompactPortraitLock` from the template (or the same logic in `didChangeDependencies`): portrait only when `MediaQuery.sizeOf(context).shortestSide < 600`, called only when that result changes, restoring the app's global orientations on exit. Use `MediaQuery.sizeOf` in the screen. Add a widget test: compact → portrait call; wide → no portrait lock.
2. **Preview and overlays.** On the inner display the preview must keep its aspect ratio, be centered, and overlays (frames, stickers, guides) must be positioned relative to the **preview rect**, not the screen. Fix layouts that use the screen size for overlay positions.
3. **Release policy.** Keep the controller's release on the profile's `camera.release_on` (default `inactive`, as the `camera` plugin recommends on iOS) and add a comment at that spot explaining that in Split View the camera is intentionally off.
4. **Fold/unfold.** On the iPhone Duo simulator, open the camera screen, fold and unfold. If the preview stays frozen after `resumed`, fix re-initialization (dispose the old controller, create a new one, rebuild with a new key) and add a widget test for `inactive` → `resumed` with a fake controller.

## Verify

- [ ] On a standard iPhone and the Duo outer display, the camera screen is locked to portrait.
- [ ] On the inner display it is not locked and adapts to the width.
- [ ] Moving between displays with the screen open re-evaluates the lock.
- [ ] Leaving the screen restores the app's global orientations.
- [ ] A widget test covers the conditional `SystemChrome` call and passes.
- [ ] On the inner display the preview keeps its aspect ratio, is centered, and overlays line up with it.
- [ ] After fold/unfold the preview shows images again within 2 s without leaving the screen.
- [ ] The release spot has a comment about Split View.
- [ ] If re-initialization changed, an `inactive` → `resumed` test exists and passes.
- [ ] The ticket/PR says the camera was validated on the simulator only (if so).

## Decisions (defaults)

- Keep releasing on `inactive`: the plugin's iOS guidance; the camera in Split View is an edge case.
- Not on `paused` only: would keep the camera on in Split View at the cost of odd behavior with Control Center and calls.
- Portrait lock only when `shortestSide < 600`.
- `compactShortestSide` lives with the camera feature, so this step doesn't depend on step 5.

## Risks

| Risk | Mitigation |
|---|---|
| The `camera` plugin version misbehaves on display switches | Step 4 above tests it; if not fixable in app code, open a plugin upgrade change. |
| The simulator has no real camera | Accepted; say so in the PR. |
| `didChangeDependencies` calls `SystemChrome` on every rebuild | Only on a change of the compact result. |
| The preview looks rotated once unlocked on the inner display | Checked on the simulator; fix preview orientation in this step. |
