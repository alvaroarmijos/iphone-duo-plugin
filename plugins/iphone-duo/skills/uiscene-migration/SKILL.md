---
name: uiscene-migration
description: iPhone Duo step 3/8. Migrates a Flutter iOS app to the UIScene life cycle (SceneDelegate based on FlutterSceneDelegate, AppDelegate adopting FlutterImplicitEngineDelegate) by hand, so customized AppDelegates (push SDKs, deep links, method channels, self.window) and first-party native code keep working. Use as part of iphone-duo:adopt or alone to "migrate to UIScene".
---

# Step 3 — Migrate to the UIScene life cycle

**Why:** UIScene is mandatory with the iOS 27 SDK and is what lets the app live in resizable windows (Split View, display switches on the iPhone Duo). Under UIScene `self.window` in the AppDelegate and `UIApplication.delegate.window` are `nil`, so anything that reaches the `FlutterViewController` through them breaks.

**Reads from the profile:** `ios.app_delegate`, `ios.native_window_access`, `ios.flavors`, `plugins.*`, `flutter.target`, and `.iphone-duo/uiscene-audit.md` (workarounds). Templates: this skill's `references/`.

## Choose the path

- **Unmodified template AppDelegate** (only `GeneratedPluginRegistrant` + `super`): use Flutter's automatic migration (`<flutter> config --enable-uiscene-migration`, then build) and skip to Verify.
- **Anything else** (SDK init, push, `self.window`, `rootViewController`, method channels): manual migration below. This is the usual case.

Before writing code, open the Flutter UIScene migration guide for the pinned version (https://docs.flutter.dev/to/uiscene-migration) and use its exact API names and signatures; the templates show the shape, the guide wins.

## Scope

In: `Info.plist` scene manifest; new `SceneDelegate`; AppDelegate on `FlutterImplicitEngineDelegate`; moving code that needs the `FlutterViewController`; first-party native code that reads the app delegate's window; step 2 workarounds.
Out: real multi-window (`UIApplicationSupportsMultipleScenes = true`); Xcode upgrade (step 4); Android.

## Implement

Each step leaves the app working; the manifest is switched on last.

1. **SceneDelegate.** Create `ios/Runner/SceneDelegate.swift` from `references/SceneDelegate.swift` (a `FlutterSceneDelegate` subclass, no logic yet) and add it to the Runner target in `project.pbxproj` (all flavors/configurations). Objective-C projects: same class in `.h/.m`.
2. **AppDelegate.** Adopt `FlutterImplicitEngineDelegate`; move `GeneratedPluginRegistrant.register(...)` and any method-channel setup into the implicit engine callback (use the engine bridge's registry/messenger, not `window.rootViewController`). Leave `Info.plist` untouched; the app still runs without scenes.
3. **Code that needs the FlutterViewController** (asset or channel helpers initialized with the controller, SDK views): move it to the implicit engine callback if it only needs the engine/messenger, or to the `SceneDelegate` once the scene's window has a root controller.
4. **Deep links / URL routing from SDK callbacks** (e.g. a push SDK's "should open URL" delegate that calls `pushRoute` on the controller): resolve the `FlutterViewController` from the active scene **at callback time** (`references/native-window-lookup.md`), not from `self.window` and not cached at launch.
5. **First-party native code.** Replace every `[[UIApplication sharedApplication] delegate] window]`, `UIApplication.shared.delegate?.window`, `UIApplication.shared.keyWindow`, `UIApplication.shared.windows` with the active scene's key window helper. Grep widely (`window`, `keyWindow`, `rootViewController`) in `ios/` and every first-party plugin's `ios/`, excluding `Pods/`. `self.view.window` inside a view controller keeps working.
6. **Turn on scenes.** Add `references/Info-scene-manifest.xml` to `ios/Runner/Info.plist` (single scene, `$(PRODUCT_MODULE_NAME).SceneDelegate`). Keep `UISceneStoryboardFile` = `Main` if the app uses `Main.storyboard`.
7. **Step 2 workarounds.** Implement each `Workaround step 3` row in the `SceneDelegate` (URL contexts, user activities, `connectionOptions` on cold start), always calling `super`.
8. **Manual check on the simulator** (ask the developer to run what you can't): cold and warm start; push in foreground, background and terminated (`xcrun simctl push`), tapping each opens the right route; in-app messages / content cards; an SDK deep link; a universal link (`applinks:`); every screen backed by first-party native code; the camera.

## Verify

- [ ] `Info.plist` has `UIApplicationSceneManifest` with `UISceneDelegateClassName = $(PRODUCT_MODULE_NAME).SceneDelegate` and `UIApplicationSupportsMultipleScenes = false`.
- [ ] `SceneDelegate` exists and subclasses `FlutterSceneDelegate`.
- [ ] The AppDelegate adopts `FlutterImplicitEngineDelegate` and registers plugins in its callback.
- [ ] `grep -n "self.window" ios/Runner/AppDelegate.*` returns nothing.
- [ ] No first-party native file reads the app delegate's window (`grep -rnE "delegate\]? ?window|delegate\??\.window" ios packages/*/ios --exclude-dir=Pods` is empty).
- [ ] The run log has no UIKit warning about missing UIScene adoption.
- [ ] Every item of the manual check passes (or is listed as not verifiable on the simulator).
- [ ] Every step 2 workaround is implemented.

## Decisions (defaults)

- Manual migration whenever the AppDelegate is customized.
- `SceneDelegate` subclasses `FlutterSceneDelegate`, as the official guide requires.
- Single scene: one window is enough for Split View and display switches; multi-window multiplies test cases for no gain.
- Remove every use of the app delegate's window.
- Switch the manifest on last, so every earlier commit is shippable.
- Take exact API signatures from the guide for the pinned Flutter version.

## Risks

| Risk | Mitigation |
|---|---|
| A push that launches the app loses its route (it arrives in `scene(_:willConnectTo:options:)`) | Terminated-state check; forward `connectionOptions` to `super`. |
| Controller-dependent init runs before the controller exists | Move it to the engine callback or the scene (step 3); test the screens that use it. |
| A delayed SDK callback targets a stale controller | Resolve from the active scene at callback time. |
| More window lookups than the obvious ones | Wide grep in step 5. |
| Notification regressions only visible in production | Manual checklist covers all three app states; recommend a TestFlight beta. |
