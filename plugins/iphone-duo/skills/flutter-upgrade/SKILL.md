---
name: flutter-upgrade
description: iPhone Duo step 1/8. Upgrades a Flutter app and all its packages to the minimum Flutter version with default UIScene support (3.41.x latest stable patch), through the project's version manager (FVM preferred), and pins the same version in every CI file. Use as part of iphone-duo:adopt, or alone when asked to "upgrade Flutter for UIScene / iPhone Duo".
---

# Step 1 — Upgrade Flutter to 3.41.x

**Why:** the iOS 27 SDK makes the UIScene life cycle mandatory, and Flutter supports it by default (`FlutterSceneDelegate`, `FlutterImplicitEngineDelegate`) from 3.41. This step changes only the SDK; plugins (step 2), UIScene (step 3) and Xcode (step 4) come later.

**Reads from the profile:** `flutter.*`, `xcode.ci`, `git.*`. If there's no profile, detect the version manager and pins (discovery §1 "Flutter and tooling") and ask for the target version.

## Scope

In: version manager pin, IDE SDK path, `environment: flutter:` constraints, every CI pin, minimal dependency bumps that block resolution, analyzer and test fixes caused by the new SDK.
Out: UIScene, plugin upgrades for UIScene, Xcode, lint package upgrades, `pub upgrade --major-versions`.

## Implement

1. **Pick the version.** List stable releases (`fvm releases --channel stable`, or https://docs.flutter.dev/release/archive) and pick the latest patch of the profile's `flutter.target` (default: latest `3.41.x`). Confirm with the developer.
2. **Install and pin locally.**
   - FVM: `fvm install <v>` then `fvm use <v>` (updates `.fvmrc` and the `.fvm/` symlink). Update `.vscode/settings.json` `dart.flutterSdkPath` to `.fvm/versions/<v>` if present.
   - asdf/mise: update `.tool-versions` and install.
   - Global: tell the developer to run `flutter upgrade` / switch channel; don't change their global SDK yourself.
   - Check `<flutter> --version` shows `<v>`.
3. **Constraints.** Update `environment: flutter:` in the app's `pubspec.yaml` (and packages that declare one) to `^<v>` or `>=<v>`. Raise the Dart `sdk:` lower bound only if resolution demands it.
4. **Resolve.** `<flutter> pub get` in the app and every package. If resolution fails, bump only the blocking dependency, one per commit. A major bump with large breaking changes → stop and ask (it may deserve its own ticket).
5. **Analyze.** `<flutter> analyze` across app and packages; fix errors and warnings introduced by the SDK. One commit per package if there are many.
6. **Test.** Run the project's test command with the pinned SDK (if a script calls `flutter` directly, put `.fvm/flutter_sdk/bin` first on `PATH`). Golden changes: regenerate in a separate commit and ask the developer to review them visually.
7. **CI.** Set the exact same version in every pin listed in `flutter.pins` (GitHub Actions `flutter-version`, Codemagic `flutter:`, Bitrise, GitLab, Xcode Cloud `ci_post_clone.sh`). Workflows that don't pin a version: leave them unless they fail.
8. **Smoke test.** Ask the developer to run the app on an iOS simulator and an Android emulator through the main flows; offer to run it yourself if a simulator is available.

## Verify

- [ ] The version manager pin and `<flutter> --version` show the same `3.41.x`.
- [ ] `grep -rn "<old version>"` over pins, pubspecs, CI and `.vscode/` returns nothing.
- [ ] `<flutter> analyze` reports no errors or warnings in the app and every package.
- [ ] All tests pass, coverage not lower than before.
- [ ] CI is green (developer confirms if you can't trigger it).
- [ ] Smoke test passes on iOS and Android.

## Decisions (defaults)

- Latest patch of the minimum UIScene version, not the newest major: smallest diff that unlocks UIScene.
- Pin the version (manager + CI): every developer and CI build the same thing.
- Only bump dependencies that block resolution; no general upgrades.
- Separate step from the toolchain and UIScene: an SDK upgrade has its own blast radius.

## Risks

| Risk | Mitigation |
|---|---|
| A pinned dependency doesn't resolve with the new Dart | Bump only that one; if it's a big major, stop and ask. |
| Rendering changes break goldens | Regenerate in a separate commit, review visually. |
| Scripts use the global `flutter` | Run with the pinned SDK first on `PATH`; CI pins explicitly. |
| Android regression | Smoke test includes Android. |
