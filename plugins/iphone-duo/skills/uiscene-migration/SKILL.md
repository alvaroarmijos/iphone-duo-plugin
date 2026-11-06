---
name: uiscene-migration
description: iPhone Duo step 3/8. Migrates a Flutter iOS app to the UIScene life cycle following Flutter's official guide (AppDelegate adopting FlutterImplicitEngineDelegate, scene manifest with FlutterSceneDelegate or a subclass), by hand when the AppDelegate is customized, so push SDKs, deep links, method channels, self.window and first-party native code keep working. Use as part of iphone-duo:adopt or alone to "migrate to UIScene".
---

# Step 3 — Migrate to the UIScene life cycle

**Source of truth:** Flutter's official guide, https://docs.flutter.dev/release/breaking-changes/uiscenedelegate. Open it before writing code and copy API names, signatures and plist keys from it. The templates in `references/` mirror the guide; if they disagree, the guide wins.

**Why:** apps built with Xcode 27 (iOS 27 SDK) that don't adopt UIScene fail to launch, and UIScene is what lets the app live in resizable windows (Split View, display switches on the iPhone Duo). After migration UIKit stops calling the UI life cycle methods of `UIApplicationDelegate` (`applicationDidBecomeActive`, …), and `self.window` in the AppDelegate / `UIApplication.delegate.window` are `nil`, so anything that reaches the `FlutterViewController` through them breaks.

**Versions:** the migration APIs (`FlutterImplicitEngineDelegate`, `FlutterSceneDelegate`, `registrar.viewController`) exist from Flutter 3.38. From 3.41 UIScene is the default and eligible apps migrate automatically.

**Reads from the profile:** `ios.app_delegate`, `ios.native_window_access`, `ios.flavors`, `plugins.*`, `flutter.target`, and `.iphone-duo/uiscene-audit.md` (workarounds). Templates: this skill's `references/`.

## Choose the path

- **Unmodified template AppDelegate** (only `GeneratedPluginRegistrant` + `super`) on Flutter ≥ 3.41: run `<flutter> build ios` (or `<flutter> run`). Success prints `Finished migration to UIScene lifecycle`; review the diff (AppDelegate + `Info.plist`) and skip to Verify. If the CLI prints manual instructions instead, take the manual path.
- **Anything else** (SDK init, push, `self.window`, `rootViewController`, method channels, UI life cycle methods): manual migration below. This is the usual case.

Never use `enable-uiscene-migration: false` (under `flutter: config:` in `pubspec.yaml`) to get past this step: it only hides the CLI warning, the app still crashes with the iOS 27 SDK.

## Scope

In: `Info.plist` scene manifest; AppDelegate on `FlutterImplicitEngineDelegate`; moving UI life cycle callbacks and `FlutterViewController`-dependent code; an optional `SceneDelegate`; first-party native code that reads the app delegate's window; step 2 workarounds.
Out: real multi-window (`UIApplicationSupportsMultipleScenes = true`, not fully supported by Flutter yet); add-to-app hosts; Xcode upgrade (step 4); Android.

## Implement

Each step leaves the app working; the manifest is switched on last.

1. **AppDelegate.** Adopt `FlutterImplicitEngineDelegate` exactly as the guide shows (`references/AppDelegate.md`, Swift and Objective-C):
   - Move `GeneratedPluginRegistrant.register(...)` into `didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge)`, using `engineBridge.pluginRegistry`.
   - Create method channels and platform-view factories there with `engineBridge.applicationRegistrar.messenger()`, never from `window.rootViewController`.
   - `application(_:didFinishLaunchingWithOptions:)` keeps only work that needs no window or controller, and must keep the APIs Apple requires before launch finishes: `BGTaskScheduler` registration, `UNUserNotificationCenter.current().delegate`, `HKHealthStore` background delivery. Plugin registration now happens later (at scene connect), so a plugin that needs one of those exposes a setup method the AppDelegate calls here.
   - No `FlutterViewController` access in `didFinishLaunching` (`window?.rootViewController as! FlutterViewController` can crash).
   Leave `Info.plist` untouched; the app still runs without scenes.
2. **Bespoke `FlutterViewController` use** (storyboard controller used in `didFinishLaunching` for anything other than channels, e.g. asset helpers, SDK views): either subclass `FlutterViewController` and do it in `awakeFromNib()` (after `super`), or do it in the SceneDelegate's `scene(_:willConnectTo:options:)` after `super`. Code that only needs the messenger goes to the step 1 callback.
3. **UI life cycle callbacks.** List every UI-state method the AppDelegate implements and move its logic to the SceneDelegate equivalent, calling `super` first:

   | AppDelegate (no longer called) | SceneDelegate |
   |---|---|
   | `applicationDidBecomeActive` | `sceneDidBecomeActive` |
   | `applicationWillResignActive` | `sceneWillResignActive` |
   | `applicationWillEnterForeground` | `sceneWillEnterForeground` |
   | `applicationDidEnterBackground` | `sceneDidEnterBackground` |
   | `application(_:open:options:)` | `scene(_:openURLContexts:)` |
   | `application(_:continue:restorationHandler:)` | `scene(_:continue:)` |
   | `application(_:performActionFor:completionHandler:)` | `windowScene(_:performActionFor:completionHandler:)` |

   On a cold start, URLs, user activities and shortcut items arrive in `connectionOptions` of `scene(_:willConnectTo:options:)`, not in the callbacks above.
4. **SceneDelegate, only if needed.** The guide makes it optional. Create one only when step 2, step 3 or a step 2 workaround (`Workaround step 3` rows in `.iphone-duo/uiscene-audit.md`) gives it work. Swift: `ios/Runner/SceneDelegate.swift` from `references/SceneDelegate.swift` (`class SceneDelegate: FlutterSceneDelegate`). Objective-C: `SceneDelegate.h/.m` from `references/AppDelegate.md`. Add the file to the Runner target in `project.pbxproj` (all flavors/configurations). Every override calls `super` so Flutter and its plugins still receive the event. If nothing needs it, don't create it: the manifest names `FlutterSceneDelegate` directly.
5. **Deep links / URL routing from SDK callbacks** (e.g. a push SDK's "should open URL" delegate that calls `pushRoute` on the controller): resolve the `FlutterViewController` from the active scene **at callback time** (`references/native-window-lookup.md`), not from `self.window` and not cached at launch.
6. **First-party native code.** Replace every `[[UIApplication sharedApplication] delegate] window]`, `UIApplication.shared.delegate?.window`, `UIApplication.shared.keyWindow`, `UIApplication.shared.windows`, `UIScreen.main` using the table in `references/native-window-lookup.md`. First-party plugins use the guide's pattern, `registrar.viewController?.view.window?.windowScene`; app code without a registrar uses the active-scene helper. Grep widely (`window`, `keyWindow`, `rootViewController`, `UIScreen.main`) in `ios/` and every first-party plugin's `ios/`, excluding `Pods/`. `self.view.window` inside a view controller keeps working.
7. **Turn on scenes.** Add `references/Info-scene-manifest.xml` to `ios/Runner/Info.plist` (or use Xcode's Application Scene Manifest editor). `UISceneDelegateClassName` is `FlutterSceneDelegate` with no custom class, `$(PRODUCT_MODULE_NAME).SceneDelegate` for a Swift subclass, `SceneDelegate` for an Objective-C one. Keep `UISceneStoryboardFile` = `Main` if the app uses `Main.storyboard`.
8. **Step 2 workarounds.** Implement each `Workaround step 3` row in the `SceneDelegate` (URL contexts, user activities, `connectionOptions` on cold start), always calling `super`.
9. **Manual check on the simulator** (ask the developer to run what you can't): cold and warm start; foreground/background transitions that ran in the moved life cycle methods; push in foreground, background and terminated (`xcrun simctl push`), tapping each opens the right route; in-app messages / content cards; an SDK deep link; a universal link (`applinks:`); a home-screen quick action if the app has them; every screen backed by first-party native code; the camera.

## Verify

- [ ] `Info.plist` has `UIApplicationSceneManifest` with `UIApplicationSupportsMultipleScenes = false`, `UISceneClassName = UIWindowScene`, `UISceneConfigurationName = flutter`, and `UISceneDelegateClassName` = `FlutterSceneDelegate`, `$(PRODUCT_MODULE_NAME).SceneDelegate` (Swift) or `SceneDelegate` (Objective-C).
- [ ] If a custom `SceneDelegate` exists, it subclasses `FlutterSceneDelegate`, belongs to the Runner target, and every override calls `super`.
- [ ] The AppDelegate adopts `FlutterImplicitEngineDelegate` and registers plugins (and channels) in `didInitializeImplicitFlutterEngine`.
- [ ] `grep -nE "self\.window|rootViewController" ios/Runner/AppDelegate.*` returns nothing.
- [ ] `grep -nE "applicationDidBecomeActive|applicationWillResignActive|applicationWillEnterForeground|applicationDidEnterBackground|openURL|open url|continueUserActivity|continue userActivity|performActionFor" ios/Runner/AppDelegate.*` returns nothing (logic moved to the SceneDelegate).
- [ ] No first-party native file reads the app delegate's window (`grep -rnE "delegate\]? ?window|delegate\??\.window" ios packages/*/ios --exclude-dir=Pods` is empty).
- [ ] Auto path only: the build printed `Finished migration to UIScene lifecycle`.
- [ ] The run log has no UIKit or Flutter CLI warning about missing UIScene adoption.
- [ ] Every item of the manual check passes (or is listed as not verifiable on the simulator).
- [ ] Every step 2 workaround is implemented.

## Decisions (defaults)

- Manual migration whenever the AppDelegate is customized; automatic migration (Flutter ≥ 3.41) only for the unmodified template.
- `SceneDelegate` is optional, as in the guide: create it only when it has work to do, and then subclass `FlutterSceneDelegate`.
- Single scene: one window is enough for Split View and display switches; Flutter doesn't fully support multiple scenes yet.
- Remove every use of the app delegate's window.
- Switch the manifest on last, so every earlier commit is shippable.
- Rollback if a regression shows up after release: rename the key to `_UIApplicationSceneManifest` in `Info.plist` to turn UIScene off temporarily (not possible once the app is built with the iOS 27 SDK).
- Take exact API signatures from the official guide.

## Risks

| Risk | Mitigation |
|---|---|
| A push that launches the app loses its route (it arrives in `scene(_:willConnectTo:options:)`) | Terminated-state check; forward `connectionOptions` to `super`. |
| Logic in `applicationDidBecomeActive` & co. silently stops running | Step 3 inventory and grep in Verify. |
| Pre-launch APIs (`UNUserNotificationCenter.delegate`, `BGTaskScheduler`) moved out of `didFinishLaunching` | Keep them there (step 1); plugin registration is deferred to scene connect. |
| Controller-dependent init runs before the controller exists | Move it to the engine callback, `awakeFromNib` or the scene (step 2); test the screens that use it. |
| A delayed SDK callback targets a stale controller | Resolve from the active scene at callback time. |
| More window lookups than the obvious ones | Wide grep in step 6. |
| Notification regressions only visible in production | Manual checklist covers all three app states; recommend a TestFlight beta. |
