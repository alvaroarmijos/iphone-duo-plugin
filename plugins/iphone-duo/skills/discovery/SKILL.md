---
name: discovery
description: Scans a Flutter repo for everything iPhone Duo adoption depends on (Flutter pins, CI and Xcode versions, AppDelegate and native window access, UIScene-sensitive plugins, orientation locks, MediaQuery size usage, camera, UI package, screens) and interviews the developer for the decisions only they can make (target Flutter version, critical SDKs, max content width, which screens must avoid the hinge and how). Writes .iphone-duo/profile.md. Used by iphone-duo:adopt; run alone to refresh the profile.
---

# Discovery: scan the repo, then ask

The profile is the contract every step skill reads. Detect what you can, ask only what you can't infer, and record every answer with its reason.

## 1. Automatic scan

Run these checks from the repo root (read-only). Keep the raw findings; they go into the profile's `detected` section.

**Flutter and tooling**
- Version manager: `.fvmrc` / `.fvm/fvm_config.json` (FVM), `.tool-versions` (asdf/mise), `.flutter-version`, otherwise global. Set `flutter.command` (`fvm flutter` or `flutter`).
- Current Flutter version: the pin file, else `flutter --version`.
- Every place that pins a Flutter version: `grep -rnE "flutter(-version|_version|: *['\"]?[0-9]+\.[0-9]+)" .github/ codemagic.yaml bitrise.yml .gitlab-ci.yml ci_scripts/ .vscode/ pubspec.yaml 2>/dev/null`, plus `environment: flutter:` in every `pubspec.yaml`.
- Monorepo packages: `find . -name pubspec.yaml -not -path "*/.dart_tool/*" -not -path "*/build/*" -not -path "*/.fvm/*"`.
- Test runner script (`tool/test.sh`, `melos`, `very_good test`, plain `flutter test`).

**CI and Xcode**
- CI providers present: `.github/workflows/`, `codemagic.yaml`, `bitrise.yml`, `.gitlab-ci.yml`, `ci_scripts/` (Xcode Cloud), `fastlane/`.
- Xcode pins: `grep -rnE "xcode(-version|_version)?:|xcode-select|DEVELOPER_DIR|macos-[0-9]+" <ci files>`.
- Local Xcode: `xcodebuild -version` (if available).

**iOS project**
- `ios/Podfile`: `platform :ios`, and any `IPHONEOS_DEPLOYMENT_TARGET` forced in `post_install`.
- `ios/Runner.xcodeproj/project.pbxproj`: `IPHONEOS_DEPLOYMENT_TARGET`.
- `ios/Runner/Info.plist`: `UIApplicationSceneManifest`, `UIRequiresFullScreen`, `UISupportedInterfaceOrientations*`, `FlutterDeepLinkingEnabled`.
- AppDelegate language and customizations: `ios/Runner/AppDelegate.{swift,m}`; list everything beyond the template (SDK init, push, `self.window`, `rootViewController`, method channels).
- Existing `SceneDelegate`.
- Flavors / schemes: `ios/Runner.xcodeproj/xcshareddata/xcschemes/`, `lib/main_*.dart`.
- Native window access in first-party code: `grep -rnE "delegate\]? ?window|\.delegate\??\.window|keyWindow|UIApplication\.shared\.windows|rootViewController" ios/ packages/*/ios 2>/dev/null` (exclude `Pods/`).

**Plugins** (all `pubspec.yaml` files): list dependencies that typically touch the app delegate, the window or UI presentation — push (`firebase_messaging`, `flutter_local_notifications`, `onesignal_flutter`, `braze_plugin`, `airship_flutter`…), auth/sign-in (`firebase_auth`, `google_sign_in`, `sign_in_with_apple`, `flutter_facebook_auth`…), deep links (`app_links`, `uni_links`, `firebase_dynamic_links`…), presentation (`url_launcher`, `share_plus`, `in_app_review`, `in_app_purchase`, `printing`, `image_picker`, `file_picker`, `camera`, `webview_flutter`…), analytics/marketing SDKs, and any first-party plugin with an `ios/` folder.

**Dart code**
- `grep -rn "MediaQuery.of(context).size" lib packages --include=*.dart` (count and files).
- `grep -rn "setPreferredOrientations" lib packages --include=*.dart`.
- Safe-area-derived symmetric paddings: `grep -rnE "EdgeInsets.symmetric\(horizontal:.*(padding|viewPadding)" lib packages --include=*.dart`.
- Camera usage: `package:camera`, `CameraController`, `AppLifecycleState`.
- UI package: a package named like `*_ui`/`design_system`/`ui_kit` with a widgets barrel; else none.
- App root widget (`MaterialApp`/`MaterialApp.router`/`CupertinoApp`) and its file.
- Candidate screens: classes ending in `Page`/`Screen`/`View` that build a `Scaffold`; group by feature folder and count.
- `displayFeatures`, `foldable`, `dual_screen` already used.

## 2. Interview

Use AskUserQuestion, at most 4 questions per call, recommended option first with "(Recommended)". Put the detected fact in each question so it stands alone. Skip any question whose answer is already certain from the scan. Wait for each block before the next.

**Block A — scope and tooling**
1. Target Flutter version. Recommend the latest stable patch of the minimum version with default UIScene support (see platform facts), not the newest major, to keep the diff small.
2. Version manager: keep the detected one; if none, offer FVM (recommended) or global.
3. Required Xcode / iOS SDK for local and CI. Ask whether CI already offers it.
4. Test devices: iPhone Duo simulator only (typical) or a physical device.

**Block B — risk**
1. Critical SDKs: from the detected plugin list, which SDKs make the whole series **stop** if they have no UIScene support (typically push/marketing SDKs that own notifications and deep links)? The rest get a documented workaround instead.
2. Git strategy: one branch + commit per step (recommended), commits on the current branch, or no commits.
3. Android foldables: out of scope (recommended) or in scope (note: this plugin only covers iOS).

**Block C — layout**
1. Max content width on wide screens. Recommend 600 pt, centered, applied per page `body` so app bars stay full width. Options: 600 pt, 720 pt, other, no cap.
2. Where shared widgets live: the detected UI package (recommended) or `lib/`.
3. Orientation policy: unlock everything and adapt by width (recommended), or keep existing locks only on compact screens (`shortestSide < 600`).

**Block D — camera** (only if the app uses the camera)
1. Split View policy: keep releasing the camera on `inactive` (recommended: the camera plugin's guidance on iOS; the camera is off while in Split View) or release only on `paused`.
2. Camera screens that currently lock to portrait: lock only on compact screens (recommended) or keep the lock.

**Block E — the hinge**
1. Level of hinge support: **avoid the hinge** on chosen screens (recommended for content apps), a full **two-pane** experience (out of this plugin's scope; record and stop at step 8), or **none** (skip steps 7–8).
2. Which screens must avoid the hinge? Show the candidate screens grouped by feature (multiSelect, up to 4 per question; repeat for more features). Recommend the flows users spend the most time in.
3. For each chosen screen, ask how to split it when half-opened: **two columns** (content on each side of the hinge — ask what goes in `start` and what goes in `end`, proposing a split from the widget tree), **one side only** (everything in `start`, `end` empty — good for single documents/PDF/video), or **list split** (alternate items between columns). Ask in blocks; propose a concrete default for each screen.
4. Dialogs and bottom sheets: confine them globally to one half (recommended, via the bridge's full mode) or leave them.

## 3. Write the profile

Create `.iphone-duo/profile.md` (and add `.iphone-duo/` to version control — ask whether to commit it or add it to `.gitignore`; recommend committing it so the team shares the decisions):

```markdown
---
version: 1
created: <date>
flutter:
  current: 3.38.1
  target: 3.41.x
  command: fvm flutter
  manager: fvm
  pins: [".fvmrc", "pubspec.yaml", ".github/workflows/app.yaml:12", "codemagic.yaml:6"]
  packages: 40
  test_command: ./tool/test.sh
xcode:
  required: "27.1"
  ci: [{provider: codemagic, file: codemagic.yaml, lines: [7, 125], current: "26.0"}]
ios:
  deployment_target: "15.0"
  podfile_forced_target: "13"
  app_delegate: {language: swift, custom: true, uses_self_window: true}
  scene_manifest: false
  requires_full_screen: false
  flavors: [development, staging, production]
  native_window_access: ["packages/native_plugin/ios/Classes/NativePlugin.m:58"]
plugins:
  uiscene_sensitive: [braze_plugin ^10.1.0, firebase_messaging ^16.0.0, ...]
  critical_sdks: [braze_plugin]
layout:
  content_width: {enabled: true, max: 600}
  ui_package: packages/app_ui
  orientation_policy: unlock
  mediaquery_size_usages: 23
camera:
  used: true
  release_on: inactive
  portrait_lock_screens: ["lib/camera/view/camera_page.dart"]
hinge:
  support: avoid          # avoid | two-pane | none
  modals: confine         # confine | leave
  screens:
    - {screen: TriviaPage, file: lib/trivia/view/trivia_page.dart, mode: columns, start: "question", end: "answers"}
    - {screen: TicketPage, file: lib/lottery/view/ticket_page.dart, mode: start-only}
    - {screen: LotteryPage, file: lib/lottery/view/lottery_page.dart, mode: list-split}
devices: simulator-only
git:
  strategy: branch-per-step   # branch-per-step | current-branch | none
  branch_prefix: feat/iphone-duo-
  base: main
android_foldables: out
---

## Decisions

- <decision> — <reason given by the developer or the default's rationale>

## Detected

<raw scan findings, grouped as in section 1>

## Open questions

<anything the developer deferred>
```

Show the developer the decisions list and ask them to confirm before handing back to `adopt`.
