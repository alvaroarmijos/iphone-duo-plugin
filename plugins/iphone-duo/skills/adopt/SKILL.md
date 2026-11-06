---
name: adopt
description: Orchestrates iPhone Duo adoption in a Flutter app. Runs discovery (scan + interview), shows which of the eight steps apply, then runs each step skill in order with verification and an approval gate, tracking progress in .iphone-duo/progress.md so it can resume. Use when the user asks to "add iPhone Duo support", "support foldable iPhone", "adopt iPhone Duo", or runs /iphone-duo:adopt.
argument-hint: "[step-name] [--plan-only] [--reset]"
---

# Adopt iPhone Duo support

You take a Flutter app from "letterboxed on the iPhone Duo inner display" to "fills the display and keeps chosen screens clear of the hinge". You work in eight steps. Each step is its own skill, leaves the app building and green, and is approved by the developer before the next one starts.

Read `${CLAUDE_PLUGIN_ROOT}/references/platform-facts.md` once at the start. It holds the platform facts every step relies on and tells you which ones to re-check online.

## The steps

| # | Skill | Depends on | Skip when (detected or answered in the profile) |
|---|---|---|---|
| 1 | `iphone-duo:flutter-upgrade` | — | Flutter is already ≥ the target version everywhere it is pinned |
| 2 | `iphone-duo:uiscene-plugin-audit` | 1 | The app already runs with `UIApplicationSceneManifest` and no UIScene warnings |
| 3 | `iphone-duo:uiscene-migration` | 1, 2 | `Info.plist` already has `UIApplicationSceneManifest` and a `FlutterSceneDelegate` subclass |
| 4 | `iphone-duo:ios-toolchain` | 3 | Local and CI already build with the required Xcode, pods target ≥ iOS 15, no `UIRequiresFullScreen` |
| 5 | `iphone-duo:responsive-layout` | 4 | Developer opts out (`content_width.enabled: false`) |
| 6 | `iphone-duo:lifecycle-camera` | 4 | No camera and no orientation lock in the app |
| 7 | `iphone-duo:hinge-detection` | 4 | `hinge_support` is `none` |
| 8 | `iphone-duo:hinge-avoidance` | 5, 7 | `hinge_screens` is empty |

Steps 5, 6 and 7 are independent of each other once step 4 is done; keep the numeric order unless the developer asks otherwise.

## Flow

### 1. Load or build the profile

- `--reset`: confirm with the developer, delete `.iphone-duo/`, continue.
- If `.iphone-duo/profile.md` exists, read it and show a one-paragraph summary. Ask whether anything changed since it was written; update it if so.
- Otherwise invoke `iphone-duo:discovery`. It scans the repo, interviews the developer and writes `.iphone-duo/profile.md`.

### 2. Show the step plan

From the profile and a fresh check of each "skip when" condition, write `.iphone-duo/progress.md`:

```markdown
# iPhone Duo adoption progress

Profile: .iphone-duo/profile.md · Started: <date>

| # | Step | Status | Branch / commit | Notes |
|---|---|---|---|---|
| 1 | flutter-upgrade | pending | | |
| 2 | uiscene-plugin-audit | skipped | | already on UIScene |
...
```

Status values: `pending`, `in-progress`, `done`, `skipped`, `blocked`.

Show the table to the developer, with one line per step saying what it will change in this project. Ask for approval of the plan. With `--plan-only`, stop here.

If `.iphone-duo/progress.md` already exists, resume: re-check the first non-`done` step and continue from it.

### 3. Run each step

For the next `pending` step:

1. Set it to `in-progress`. If the profile's `git.strategy` is `branch-per-step`, create the branch `<git.branch_prefix><step-name>` from the base branch first (ask if the working tree is dirty).
2. Invoke the step's skill. It reads the profile, detects the current state, implements, and runs its own verification. Let it ask the developer anything the profile does not answer, and write new answers back to the profile.
3. When the skill finishes, report to the developer:
   - what changed (files, with a short `git diff --stat`),
   - the step's acceptance checklist with each item checked, failed, or "manual — needs the iPhone Duo simulator",
   - anything left for the developer (manual checks, CI runs you cannot trigger).
4. Ask: **continue to the next step**, **adjust this step**, or **stop here**.
   - Adjust: apply the changes, re-run the verification, ask again.
   - Continue: if `git.strategy` is not `none`, commit the step (message `feat(ios): <step summary> (iPhone Duo <n>/8)`), set the step to `done` with the commit hash, and go to the next step.
   - Stop: leave the step `in-progress` (or `done` if approved), summarize where things stand and how to resume (`/iphone-duo:adopt`).

### Hard stops

Set the step to `blocked`, write the reason in Notes, and stop the run when:

- step 2 finds that an SDK listed in `critical_sdks` has no UIScene-compatible version;
- a build or test failure can't be fixed within the step's scope after one honest attempt (report the error output verbatim);
- the developer's environment lacks something the step needs and only they can install it (Xcode version, FVM, simulator runtime). Tell them the exact command.

### 4. Finish

When every step is `done` or `skipped`, show the final table, the manual checks still open, and suggest a beta (TestFlight) build before release. Do not push or open pull requests unless asked.

## Rules

- One step at a time. Never batch two steps into one approval.
- The developer decides scope. If they reject a default (for example the 600 pt content width), record the new value in the profile and use it.
- Keep diffs minimal: no unrelated refactors, no dependency upgrades a step does not need.
- Validation on real hardware is usually impossible; say "verified on the simulator only" when that is the case.
- Running `<flutter>`: use the command in the profile's `flutter.command` (`fvm flutter`, `flutter`, …) everywhere.
