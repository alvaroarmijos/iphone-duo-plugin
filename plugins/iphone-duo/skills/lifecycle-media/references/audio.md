# Audio (`kind: audio`)

Packages: `just_audio`, `audioplayers`, `audio_service`, `assets_audio_player`, `record`, `flutter_sound`.

**Profile:** `background` (`true` when the app declares the `audio` background mode), `screens`.

## Implement

Audio usually needs nothing from this step. Only check:

1. **No pause on `inactive`.** If an app-level observer pauses playback or stops recording on `inactive`, move it to `paused` (or remove it when the app has background audio). Split View, Control Center and notifications all pass through `inactive`. Add a Split View comment.
2. **Audio session.** Interruptions (calls, Siri, other apps taking the session) are iOS audio session events, not life cycle events. Handle them through the session (`audio_session` interruption stream) rather than through `AppLifecycleState`.
3. **Player UI.** Full-screen players (artwork, waveform, lyrics) follow the media-screen rules in the core step: size from `MediaQuery.sizeOf`, artwork keeps its aspect ratio, content width on the inner display.

## Verify

- [ ] Playback (or recording) continues in Split View and while folding/unfolding.
- [ ] Without background audio, playback pauses when the app goes to the background; with it, playback continues.
- [ ] The player screen fits the inner display without stretched artwork.

## Decisions

- Never stop audio on `inactive`: it would cut audio every time the user opens Control Center or Split View.
