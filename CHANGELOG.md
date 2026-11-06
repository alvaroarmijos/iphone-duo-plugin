# Changelog

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
