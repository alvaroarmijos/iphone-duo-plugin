# Video (`kind: video`)

Packages: `video_player`, `chewie`, `better_player_plus`, `media_kit`, `youtube_player_iframe`.

**Profile:** `pause_on` (`paused` by default, or `inactive`), `fullscreen_lock` (`landscape` or `none`), `screens`.

## Implement

1. **Pause policy.** In Split View the user is still watching, so video must **not** pause on `inactive`. Find every app-level observer that pauses on `inactive` (or on "anything but `resumed`") and move the pause to the profile's `pause_on` (default `paused`). Resume on `resumed` only if the video was playing before. Check the player's own life cycle handling too: `video_player` pauses on `paused` by itself; options such as `VideoPlayerOptions(allowBackgroundPlayback: ...)` change that **(re-check for the version in use)**. Add a Split View comment at the changed spot.
2. **Fullscreen lock.** A fullscreen route that forces landscape uses `CompactPortraitLock(compactOrientations: [landscapeLeft, landscapeRight])`. On the inner display, fullscreen fills the display without a lock.
3. **Aspect ratio.** The player uses `AspectRatio(controller.value.aspectRatio)` inside a centered, constrained box, so it is letterboxed, not stretched, on the 951 × 669 pt inner display. Subtitles and controls follow the video rect.
4. **Fold/unfold.** Fold and unfold while playing and while paused. Playback position and state survive, and the texture shows frames right away. If the texture goes black, keep the controller alive above the part of the tree that rebuilds on the size change (do not create the controller in a widget keyed by size or layout).

## Verify

- [ ] In Split View the video keeps playing; it pauses when the app goes to the background.
- [ ] After fold/unfold the video keeps its position and state, with no black frame after 1 s.
- [ ] Fullscreen is landscape-locked on compact screens only.
- [ ] On the inner display the video is letterboxed, centered, with controls and subtitles over it.
- [ ] A widget test covers `inactive` (no pause) and `paused` (pause).

## Decisions

- Pause on `paused`: Split View is a viewing mode; pausing there is the main bug users notice.
- `inactive` stays an option for DRM or licensing rules that forbid playback while another app has focus. Record the reason in the profile.
