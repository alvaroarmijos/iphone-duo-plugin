# Changelog

## Unreleased

- New `stacked` git strategy, now the recommended default. Each step's branch is created from the previous step's branch, and its pull request targets that branch, so every PR shows only its own step. The `adopt` skill documents how to open the stack, rebase it after review changes, and retarget PRs as lower ones merge. `branch-per-step` still creates every branch from the base branch.
- `uiscene-migration` now follows Flutter's official UIScene guide (https://docs.flutter.dev/release/breaking-changes/uiscenedelegate):
  - The automatic path is a plain `flutter build ios` / `flutter run` on 3.41+, not `flutter config`.
  - The `SceneDelegate` is optional, and the manifest defaults to `FlutterSceneDelegate`.
  - The `Info.plist` manifest now uses the guide's keys (`UISceneClassName`, `UISceneConfigurationName = flutter`).
  - New steps cover the UI life cycle callbacks that UIKit no longer calls, bespoke `FlutterViewController` use, and APIs that must stay in `didFinishLaunching`.
  - First-party plugins use the `registrar.viewController` pattern.
  - Rollback is documented through `_UIApplicationSceneManifest`.
- New `references/AppDelegate.md` with the guide's Swift and Objective-C AppDelegate and SceneDelegate code.

## 0.1.0 — 2026-11-06

- First release.
- `iphone-duo-adopter` agent and `/iphone-duo:adopt` command. They run discovery (repo scan plus an interview), show the step plan, and run the eight steps with approval gates. Progress is saved in `.iphone-duo/`.
- `discovery` skill. Writes `.iphone-duo/profile.md`, which records the target Flutter version, critical SDKs, content width, orientation and camera policy, the screens that must avoid the hinge with their split, and the git strategy.
- Step skills, one per step:
  - `flutter-upgrade`
  - `uiscene-plugin-audit`
  - `uiscene-migration`
  - `ios-toolchain`
  - `responsive-layout`
  - `lifecycle-camera`
  - `hinge-detection`
  - `hinge-avoidance`
- Dart templates for `AppContentConstraint`, `CompactPortraitLock`, `FoldInfo`/`AppFoldScope` (built on `foldable` 1.0.5) and `FoldSplitView`. They come with tests and `tool/verify-templates.sh`.
- Native templates: a `SceneDelegate`, the `Info.plist` scene manifest, and window lookup under UIScene.
