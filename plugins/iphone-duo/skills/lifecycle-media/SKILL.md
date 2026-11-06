---
name: lifecycle-media
description: iPhone Duo step 6/8. Keeps life cycle-driven features and orientation locks working when the iPhone Duo folds/unfolds and in Split View - orientation locks only on compact screens and re-evaluated on display changes, every AppLifecycleState consumer given an explicit Split View policy, and per-feature fixes for camera, video, maps, audio and others. Use as part of iphone-duo:adopt or alone for "camera freezes after fold/unfold", "video pauses in Split View", "map loses its position when unfolding" or "orientation lock on iPhone Duo".
---

# Step 6 — Life cycle, orientation and media

**Why:** two iPhone Duo behaviors break features that react to the life cycle or lock the orientation, whatever the feature is:

1. **Split View:** every app takes part in it, and the app stays **visible while `inactive`**. Anything that stops on `inactive` (camera preview, video, animations, a game loop) stops while the user is still looking at it.
2. **Fold/unfold:** the app moves between displays **in the foreground**. The size changes (outer ≈ phone, inner ≈ 951 × 669 pt) and the app can go through `inactive` → `resumed`. A hard orientation lock makes no sense on the inner display (which ignores it anyway), and anything not rebuilt on `resumed` freezes.

**Reads from the profile:** `media.orientation_lock_screens`, `media.features[]` (each with `kind`, `screens` and its policy), `media.lifecycle_observers`, `layout.orientation_policy`. Profiles written before 0.3.0 have `camera:` instead of `media:`; read it as one `kind: camera` feature (`release_on` and `screens: portrait_lock_screens`) with `orientation_lock_screens: camera.portrait_lock_screens`.

**Template:** `references/compact_portrait_lock.dart` (`CompactPortraitLock`, with `compactOrientations` for landscape locks).

## Feature references

Read only the references for the `kind`s in `media.features`:

| `kind` | Packages (typical) | Reference | Split View default |
|---|---|---|---|
| `camera` | `camera`, `mobile_scanner`, `camerawesome` | `references/camera.md` | Release on `inactive`; off in Split View |
| `video` | `video_player`, `chewie`, `better_player_plus`, `media_kit` | `references/video.md` | Keep playing on `inactive`; pause on `paused` |
| `maps` | `google_maps_flutter`, `apple_maps_flutter`, `flutter_map`, `mapbox_maps_flutter` | `references/maps.md` | Nothing to stop; keep the camera position on resize |
| `audio` | `just_audio`, `audioplayers`, `audio_service`, `record` | `references/audio.md` | Never stop on `inactive` |
| `other` | AR, games, WebView, sensors, custom native views | `references/other.md` | Decide with the developer |

## Scope

In: every `setPreferredOrientations` caller; every `AppLifecycleState` consumer (`WidgetsBindingObserver.didChangeAppLifecycleState`, `AppLifecycleListener`) and its Split View policy; sizing, aspect ratio and overlays of the media screens on the inner display; the per-feature fixes in the references.
Out: upgrading media plugins (separate change if needed); landscape support on standard phones; two-pane media layouts; keeping the hinge clear (step 8); consumers that only log or send analytics.

## Implement

1. **Conditional orientation lock.** For each screen in `media.orientation_lock_screens` (and any other `setPreferredOrientations` caller the developer wants covered): replace the unconditional lock in `initState` with `CompactPortraitLock` from the template (or the same logic in `didChangeDependencies`). Lock only when `MediaQuery.sizeOf(context).shortestSide < 600`, call the platform only when that result changes, and restore the app's global orientations on exit. For a landscape lock (fullscreen video, games) pass `compactOrientations`. Add a widget test: compact → lock call; wide → no lock.
2. **Life cycle audit.** List every `AppLifecycleState` consumer in `lib/` and `packages/`. For each, write down in the PR what it does on `inactive` and on `paused`/`hidden`, then apply the policy from the profile (or the feature reference's default):
   - Stop on `inactive` only what must not run while the user is interacting with another app (exclusive hardware such as the camera, a game that must not keep running unattended).
   - Move to `paused`/`hidden` what the user should keep seeing or hearing in Split View (video, audio, animations, live data).
   - Leave alone what only logs or saves state.
   Put a one-line comment at each changed spot that names Split View as the reason.
3. **Media screens on the inner display.** Size from `MediaQuery.sizeOf` (never a size cached in `initState`). Media keeps its aspect ratio and is centered. Overlays (frames, subtitles, controls, pins) are positioned relative to the **media rect**, not the screen.
4. **Per-feature fixes.** Apply the "Implement" section of each loaded reference.
5. **Fold/unfold and Split View.** On the iPhone Duo simulator, for each media screen: open it, fold and unfold, then enter and leave Split View. Fix anything that freezes, resets or stays at the old size, and add a widget test for `inactive` → `resumed` where re-initialization changed.

## Verify

- [ ] On a standard iPhone and the Duo outer display, locked screens keep their lock.
- [ ] On the inner display they are not locked and adapt to the width.
- [ ] Moving between displays with a locked screen open re-evaluates the lock, and leaving the screen restores the app's global orientations.
- [ ] A widget test covers the conditional `SystemChrome` call and passes.
- [ ] The PR lists every `AppLifecycleState` consumer with its `inactive` and `paused` behavior, and each changed spot has a Split View comment.
- [ ] On the inner display, media keeps its aspect ratio, is centered, and overlays line up with it.
- [ ] Each loaded reference's checklist passes.
- [ ] The PR says which checks ran on the simulator only (camera capture, real GPS, AirPlay, etc.).

## Decisions (defaults)

- One step for every life cycle-driven feature: the Duo behaviors (Split View while `inactive`, foreground display changes) and the fixes (conditional lock, explicit `inactive`/`paused` policy, size from `MediaQuery.sizeOf`) are shared. Only the policy differs per feature, so it lives in a reference.
- Locks apply only when `shortestSide < 600`.
- `compactShortestSide` lives with the feature that locks, so this step doesn't depend on step 5.
- The camera releases on `inactive` (the `camera` plugin's iOS guidance). Video and audio do not stop on `inactive`.

## Risks

| Risk | Mitigation |
|---|---|
| A media plugin misbehaves on display switches | The fold/unfold check above catches it; if app code can't fix it, open a plugin upgrade change. |
| The simulator has no real camera, GPS or audio route changes | Accepted; say so in the PR. |
| `didChangeDependencies` calls `SystemChrome` on every rebuild | Only on a change of the compact result. |
| Moving a pause from `inactive` to `paused` keeps a feature running during calls or Control Center | Acceptable for video and audio (iOS interrupts the audio session itself); keep `inactive` for anything exclusive. |
| Media looks rotated once unlocked on the inner display | Checked on the simulator; fix the orientation in this step. |
