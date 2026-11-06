# iphone-duo-plugin

A Claude Code plugin that takes any Flutter app to full **iPhone Duo** support.

Built without the iOS 27.1 SDK, a Flutter app runs letterboxed on the iPhone Duo inner display. When the device is half-opened, a hinge crosses the screen, and Flutter can't see it (`MediaQuery.displayFeatures` is empty on iOS, [flutter/flutter#192515](https://github.com/flutter/flutter/issues/192515)). This plugin turns the work into eight small steps. An agent runs them for you one at a time, after asking you the questions only you can answer.

## Install

```text
/plugin marketplace add alvaroarmijos/iphone-duo-plugin
/plugin install iphone-duo@iphone-duo-plugin
```

## Use

From the root of your Flutter app:

```text
/iphone-duo:adopt                    # interview, plan, then step by step
/iphone-duo:adopt --plan-only        # interview and plan, no code changes
/iphone-duo:adopt responsive-layout  # run a single step with the saved profile
/iphone-duo:adopt --reset            # start over
```

Or start a session with the agent as the main thread:

```bash
claude --agent iphone-duo:iphone-duo-adopter
```

### How it works

1. **Discovery.** The agent scans the repo and records what it finds:
   - Flutter version and where it's pinned
   - CI provider and Xcode versions
   - Podfile deployment target
   - a customized `AppDelegate`, and native code that reads the window
   - plugins that touch the app delegate
   - orientation locks, `MediaQuery.of(context).size` usage and camera screens
   - your UI package and candidate screens

   Then it asks only what it can't infer:
   - target Flutter version
   - which SDKs block the whole series if they lack UIScene support
   - max content width
   - orientation and camera policy
   - **which screens must avoid the hinge, and how to split each one**
   - git strategy

   The answers go to `.iphone-duo/profile.md`. Commit that file so the team shares the decisions.
2. **Plan.** It shows which steps apply and which are already done, in `.iphone-duo/progress.md`.
3. **Steps.** For each step it implements the change, runs verification (analyze, tests, iOS build) and shows the diff and the acceptance checklist. Then it asks you to **continue**, **adjust** or **stop**. Progress is saved, so a later run resumes where it left off.

## The eight steps

| # | Skill | What it does |
|---|---|---|
| 1 | `flutter-upgrade` | Upgrades to the latest Flutter 3.41.x, the first version with default UIScene support. Uses your version manager (FVM preferred) and pins the version in CI. |
| 2 | `uiscene-plugin-audit` | Audits the plugins that touch the app delegate or the window, upgrades them one commit at a time, and documents workarounds. Stops if a critical SDK can't do scenes. |
| 3 | `uiscene-migration` | Migrates manually: adds a `SceneDelegate` (`FlutterSceneDelegate`) and moves the `AppDelegate` to `FlutterImplicitEngineDelegate`. Removes every `self.window` / `delegate.window` lookup. |
| 4 | `ios-toolchain` | Sets Xcode 27.1 locally and in CI, raises pods to iOS 15, removes `UIRequiresFullScreen`, and checks the launch screen. Applies the simulator `lipo` workaround if the build needs it. |
| 5 | `responsive-layout` | Switches layouts to `MediaQuery.sizeOf` / `paddingOf` with per-side safe-area insets. Caps page bodies at a max width (600 pt by default) with `AppContentConstraint`. |
| 6 | `lifecycle-camera` | Locks portrait only on compact screens and re-evaluates the lock on display changes. Releases the camera on `inactive` and recovers the preview after fold/unfold. |
| 7 | `hinge-detection` | Adds `FoldPosture`, `FoldInfo`, `AppFoldScope` and `context.foldInfo` to your UI package, wrapping [`foldable`](https://pub.dev/packages/foldable). Dialogs and sheets stay in one half. |
| 8 | `hinge-avoidance` | Adds a `FoldSplitView` that lays the chosen screens out on each side of the hinge, in two columns, one side only, or a split list. Every other posture keeps the normal layout. |

Each skill also works on its own (for example `/iphone-duo:responsive-layout`). It reads the profile if there is one and otherwise asks the minimum.

## Requirements

- Flutter ≥ 3.41 (step 1 gets you there).
- Xcode 27.1 with the iPhone Duo simulator.
- iOS 15 minimum deployment target.

## Limits

- **iOS only.** Android foldables are out of scope.
- **"Avoid the hinge" only.** A full two-pane or master-detail experience is out of scope.
- **The hinge comes from `foldable` for now.** It sits behind your own `FoldInfo` types, so moving to Flutter's native API later (once #192515 lands) changes one directory.
- **Simulator-only validation is the norm.** The agent says so in each step's report.
- **Platform facts move fast.** Xcode versions and the `foldable` API change. The skills tell the agent to re-check them at run time; see [`platform-facts.md`](plugins/iphone-duo/references/platform-facts.md).

## Developing

The Dart templates the skills hand out (`skills/*/references/*.dart`) are compiled and tested against `foldable` 1.0.5:

```bash
tool/verify-templates.sh            # uses `flutter`
tool/verify-templates.sh "fvm flutter"
```

## License

MIT
