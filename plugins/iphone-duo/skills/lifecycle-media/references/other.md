# Other features (`kind: other`)

For anything the other references don't cover: AR (`ar_flutter_plugin`, `arkit_plugin`), games (`flame` and custom loops), WebViews with media, sensors (`sensors_plus`), Bluetooth streams, custom native views.

**Profile:** `name`, `screens`, and the answers to the three questions below.

## Ask the developer (during discovery or now)

1. **What does it do on `inactive`?** Should it keep running while the app is visible in Split View?
   - Exclusive hardware (AR uses the camera, so treat it as `camera`) → stop on `inactive`.
   - Something the user watches → keep running, stop on `paused`.
   - Games: pause on `inactive` and show a pause overlay (the user is interacting with the other app), unless the game is meant to be watched.
2. **Does it lock the orientation?** If so, use `CompactPortraitLock` with the right `compactOrientations`.
3. **Does it depend on the screen size?** (a canvas size, a game viewport, a WebView's layout). It must read `MediaQuery.sizeOf` and handle a size change in the foreground: resize the viewport instead of recreating the scene, and keep its state.

## Implement

Apply the answers with the same pattern as the core step: one explicit `inactive`/`paused` policy with a Split View comment, a conditional lock, and size taken from `MediaQuery.sizeOf`. Write down what was decided in the profile's Decisions so the next step and reviewers can see it.

## Verify

- [ ] The feature behaves as decided in Split View and after fold/unfold, without losing its state.
- [ ] The decision and its reason are recorded in the profile.
