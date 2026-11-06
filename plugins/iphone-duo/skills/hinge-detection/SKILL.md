---
name: hinge-detection
description: iPhone Duo step 7/8. Exposes the iPhone Duo posture (none, flat, half-opened) and the hinge rectangle to a Flutter app through its own types (FoldPosture, FoldInfo, AppFoldScope, context.foldInfo) in the UI package, wrapping the foldable package because Flutter's MediaQuery.displayFeatures is empty on iOS. Confines dialogs and bottom sheets to one half. Use as part of iphone-duo:adopt or alone to "detect the hinge on iPhone Duo".
---

# Step 7 — Detect the hinge

**Why:** Flutter doesn't fill `MediaQuery.displayFeatures` on iOS (flutter/flutter#192515), so the app can't see the hinge. The `foldable` package reports the posture and, in `full` bridge mode, publishes the hinge in `displayFeatures` and keeps modals in one half. Wrapping it behind the app's own types means one directory changes when Flutter ships native support.

**Reads from the profile:** `hinge.support` (skip if `none`), `hinge.modals`, `layout.ui_package`. Templates: `references/fold/`. Platform facts: `${CLAUDE_PLUGIN_ROOT}/references/platform-facts.md` — **re-check first** whether the pinned Flutter version already reports the hinge; if it does, implement `AppFoldScope` from `MediaQuery.displayFeatures` + posture without the package and skip the iOS build settings.

## Scope

In: the `foldable` dependency (UI package only) and the iOS build settings its README requires; `FoldPosture`, `FoldInfo`, `AppFoldScope`, `context.foldInfo`; mounting the scope at the app root; global modal confinement (if `hinge.modals: confine`); tests with a forced posture.
Out: adapting specific screens (step 8); hinge angle; UIKit-only APIs (`ArrangementView`, vertical bars); migrating to native support later.

## Implement

1. **Dependency.** Add `foldable` (`^1.0.5` or the latest compatible, check pub.dev) to the UI package's `pubspec.yaml`. The package needs no build settings of its own; the Xcode 27.1 workarounds its README lists (pods at iOS 15, `ARCHS = arm64` for the `lipo` error) belong to step 4. Run `pod install` and build on the iPhone Duo simulator.
2. **Types.** Copy `references/fold/fold_info.dart` to `<ui_package>/lib/src/fold/`. Tests: `isSeparating`, `isVerticalHinge`, `==`/`hashCode`. Implement `==` by hand if the package doesn't use `equatable`.
3. **Scope.** Copy `references/fold/app_fold_scope.dart` (written against `foldable` 1.0.5: it imports the package with `hide FoldInfo`, because the package exports a class with the same name), export `src/fold/` from the package barrel (export only the app's types, never re-export `foldable`). Status mapping: `closed`/`unknown` → `none`, `fullyOpen` → `flat`, `partiallyOpen` → `halfOpened`. `hingeBounds` comes from `MediaQuery.displayFeaturesOf` (`hinge`/`fold`), falling back to the package's `division` reserved region. Pass `confineModals: false` when `hinge.modals` is `leave` (bridge mode `none`).
4. **Scope tests.** With `debugFoldInfo`, and with a `MediaQuery(data: …copyWith(displayFeatures: [...]))` to check the hinge is read correctly; a widget below reads `context.foldInfo`.
5. **Mount it.** Wrap the app once inside `MaterialApp(.router)(builder: (context, child) => AppFoldScope(child: child!))`. It must sit below the app's `MediaQuery`: `WidgetsApp` rebuilds `MediaQuery` from the view and would drop the bridged display features if the scope were above it. On the iPhone Duo simulator, half-opened, open one dialog and one bottom sheet from the app and check each stays in one half.

## Verify

- [ ] `grep -rln "package:foldable" lib packages` lists only files under `<ui_package>/lib/src/fold/`.
- [ ] `pod install` and the simulator build work with the new dependency.
- [ ] Half-opened on the Duo simulator: `context.foldInfo.posture == halfOpened` and `hingeBounds != null` (temporary `debugPrint` or the inspector).
- [ ] Fully open → `flat`; closed → `none`; standard iPhone → `none`.
- [ ] Half-opened: the test dialog and bottom sheet stay in one half (if `confine`).
- [ ] Tests for `FoldInfo` and `AppFoldScope` pass with full coverage of `src/fold/`.

## Decisions (defaults)

- `foldable` behind the app's own types; features never import it.
- Not a hand-written Swift bridge: duplicates work until Flutter fixes #192515.
- Not waiting for Flutter: the issue is open with no date.
- `full` bridge mode: modals land in one half app-wide with no extra code.
- `hingeBounds` read from `MediaQuery.displayFeaturesOf`, aligned with the future native API.
- Posture derived from the package status, not from region state (which can lag).

## Risks

| Risk | Mitigation |
|---|---|
| The package is young, single publisher, may be abandoned | Isolated in one directory; replace in one place. |
| `full` mode shrinks modals to about half of the inner display (~455 pt of 951 pt) | Expected; manual check in step 5; give a modal an `anchorPoint` (or choose `leave`) if one half looks wrong. |
| UIKit APIs change in later iOS releases | Pin the package version; an iOS upgrade triggers a review. |
| Flutter fixes #192515 | The package's bridge stands down automatically so the hinge is never published twice; later, drop the package and keep `AppFoldScope`'s API. |
