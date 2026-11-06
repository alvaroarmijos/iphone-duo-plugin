# iPhone Duo platform facts for Flutter

Facts the step skills rely on, as of November 2026. Items marked **(re-check)** change often: confirm them online (pub.dev, the Flutter docs, the GitHub issue) before you act on them, and tell the developer when a fact has changed.

## The device

- Two displays: an **outer** phone-sized display (closed) and an **inner** wide display (open), almost as wide as an iPad mini.
- Postures: closed (outer display), fully open (inner display, flat), **half-opened** (inner display with a hinge across it).
- When half-opened, the hinge splits the inner display into two halves. Content drawn over the hinge is folded and hard to read or tap.
- Folding or unfolding moves the running app from one display to the other while it stays in the foreground.
- Every app takes part in **Split View**. An app can be visible while its life cycle state is `inactive`.
- The inner display ignores the app's supported interface orientations: layouts must depend on the available **width**, not on the orientation or the platform.

## The SDK and the toolchain

- What the SDK the app is built against gives it on the inner display:

  | Built against | On iPhone Duo inner display |
  |---|---|
  | Before the iOS 27 SDK | Letterboxed: keeps a phone size and aspect ratio, black around it |
  | iOS 27 SDK | Extends left of the status bar area |
  | **iOS 27.1 SDK** (Xcode 27.1) | Full screen to the edges, vertical bars, reserved regions |

  Nothing an app adapts is visible until it builds with the 27.1 SDK. **(re-check the exact Xcode version)**
- With the iOS 27 SDK, the **UIScene life cycle is mandatory**. UIKit stops calling the UI-related `UIApplicationDelegate` methods, and `UIApplication.delegate.window` is `nil`.
- Xcode 27.1 does not accept deployment targets below **iOS 15**, and Flutter's own pods still declare 13.0: force 15.0 in the Podfile `post_install`.
- Xcode 27.1's `lipo` accepts one architecture per call; some Flutter versions pass both simulator slices and the build fails in `debug_unpack_ios` ("does not contain architectures arm64 x86_64"). Workaround: `ARCHS = arm64` in `ios/Flutter/Debug.xcconfig` (breaks Intel/x86_64 simulator debug builds). **(re-check: may be fixed in later Flutter versions)**
- `UIRequiresFullScreen` is deprecated by Apple; with it, the app can't take part in Split View. Remove it.

## Flutter

- The UIScene migration APIs (`FlutterSceneDelegate`, `FlutterImplicitEngineDelegate`, `registrar.viewController`) exist from **3.38**; UIScene is the default from **3.41**. Official guide (source of truth): https://docs.flutter.dev/release/breaking-changes/uiscenedelegate.
- From 3.41, `flutter run` / `flutter build ios` migrates automatically only apps whose `AppDelegate` is the unmodified template, and prints `Finished migration to UIScene lifecycle`. Any customization (SDK init, push, `self.window`, method channels, UI life cycle methods) means a manual migration. `enable-uiscene-migration: false` under `flutter: config:` in `pubspec.yaml` only hides the CLI warning.
- **`MediaQuery.displayFeatures` is empty on iOS**: Flutter does not report the iPhone Duo hinge. Open issue: https://github.com/flutter/flutter/issues/192515 (P2), with an unmerged PR (#193025). **(re-check: if fixed in the target Flutter version, prefer the native API and skip the `foldable` package)**
- Workaround: the **`foldable`** package (https://pub.dev/packages/foldable, `1.0.5`, MIT). It exposes the posture through `DuoMediaQuery.statusOf` (`HingeStatus.closed`, `partiallyOpen`, `fullyOpen`, `unknown`), the hinge angle, reserved regions (`DuoMediaQuery.regionsOf`, `ReservedRegionKind.division` / `occlusion`) and size classes. `FoldableProvider(bridgeMode: DisplayFeatureBridgeMode.full)` also publishes the fold in `MediaQuery.displayFeatures`, which makes Flutter confine dialogs, sheets, popup menus and pickers to one half (~455 pt of the 951 pt inner display); the default `none` publishes nothing. It exports its own `FoldInfo` class: import it with `hide FoldInfo` when the app defines one. If Flutter starts reporting display features on iOS, the bridge stands down automatically. **(re-check version and API)**
- Alternatives considered and not recommended: `duo_display`, `unfold`, `iphone_duo_ui_pro` (less mature or less documented), a hand-written Swift bridge (duplicates work until Flutter fixes the issue).
- Prefer `MediaQuery.sizeOf(context)` and `MediaQuery.paddingOf(context)` over `MediaQuery.of(context).size/padding`: they rebuild only on the aspect that changed and are what width-driven layouts need.

## Camera

- The `camera` plugin recommends releasing the controller on `AppLifecycleState.inactive` on iOS. In Split View, the app can be `inactive` while visible, so the preview stops. That is accepted by default.
- Folding/unfolding with the camera open goes through `inactive` → `resumed`; the controller must re-initialize and the preview must recover.

## Other media

- Split View keeps the app visible while `inactive`, so anything that stops on `inactive` stops in front of the user. Video and audio should stop on `paused`, not `inactive`.
- `video_player` pauses on `AppLifecycleState.paused` by itself; `VideoPlayerOptions(allowBackgroundPlayback: true)` disables that. **(re-check for the version in use)**
- Map plugins on iOS are platform views; a size change lays them out again without recreating them, as long as the widget and its controller stay in the tree.
- Audio interruptions (calls, Siri) come through the iOS audio session, not through `AppLifecycleState`.

## What the simulator can't do

- Real camera capture and real push notifications (use `xcrun simctl push` with `.apns` payloads).
- Hinge angle and some UIKit-only APIs (`ArrangementView`, vertical bars) have no Dart equivalent; out of scope.

## Sources

- Building Flutter apps for the iPhone Duo — https://medium.com/@mohamedyousufdev/building-flutter-apps-for-the-iphone-duo-98f007b2b617
- Flutter UIScene adoption — https://docs.flutter.dev/release/breaking-changes/uiscenedelegate
- flutter/flutter#192515 — https://github.com/flutter/flutter/issues/192515
- foldable — https://pub.dev/packages/foldable
