---
name: uiscene-plugin-audit
description: iPhone Duo step 2/8. Audits every Flutter plugin that touches the app delegate, the window, notifications, deep links or UI presentation for UIScene compatibility, upgrades the ones that have a compatible version (one commit each) and documents a SceneDelegate workaround for the rest. Stops the series if a critical SDK has no scene support. Use as part of iphone-duo:adopt or alone before a UIScene migration.
---

# Step 2 — Audit and upgrade plugins for UIScene

**Why:** under UIScene, UIKit stops calling the UI-related `UIApplicationDelegate` methods and `UIApplication.delegate.window` is `nil`. Plugins that rely on either (push, deep links, auth, UI presentation) break first. Auditing before step 3 avoids discovering it mid-migration.

**Reads from the profile:** `plugins.uiscene_sensitive`, `plugins.critical_sdks`, `flutter.*`. Without a profile, build the plugin list as in discovery §1 "Plugins" and ask which SDKs are critical.

## Scope

In: third-party plugins from the list; the audit table; upgrades; workaround notes for step 3.
Out: enabling UIScene (step 3); first-party native code (adapted in step 3); plugins with no app delegate/window interaction (`path_provider`, `shared_preferences`, …); forking third-party plugins.

## Implement

1. **Audit.** For each plugin, find the first version with UIScene support and its breaking changes: CHANGELOG on pub.dev, the repo's issues ("UIScene", "scene delegate", "iOS 26/27"), and the native SDK's release notes when the plugin wraps one. Fill the table in `.iphone-duo/uiscene-audit.md`:

   ```markdown
   | Plugin | Current | UIScene-compatible version | Breaking changes | Action |
   | --- | --- | --- | --- | --- |
   | firebase_messaging | ^16.0.0 | 16.1.0 | No | Upgrade |
   ```

   Action values: `Upgrade` (compatible version exists), `No change` (current is compatible), `Workaround step 3` (no compatible version), `Blocking` (only for SDKs in `critical_sdks` without scene support).
   If documentation is silent, test it: on a throwaway branch add the scene manifest (see step 3's template) and exercise the plugin on the simulator; write the result in the table.
2. **Review with the developer.** Show the table. If any row is `Blocking`, stop the series (the `adopt` hard stop) and draft a short message the developer can send to the vendor.
3. **Upgrade**, critical SDKs first, then push/notifications, auth, then the rest. One commit per plugin; after each, `<flutter> analyze`, tests, and an iOS debug build must be green. Adapt Dart breaking changes in the same commit.
4. **Workarounds.** For each `Workaround step 3` row, write in the table what the `SceneDelegate` must forward (for example `scene(_:openURLContexts:)` → the plugin's URL handler, or `connectionOptions` on cold start).

## Verify

- [ ] `.iphone-duo/uiscene-audit.md` has one complete row per audited plugin.
- [ ] Every `Upgrade` row matches the version in its `pubspec.yaml`.
- [ ] No row is `Blocking` (or the step is marked blocked with the vendor escalation written down).
- [ ] Every `Workaround step 3` row says what the SceneDelegate must do.
- [ ] `<flutter> analyze` and tests pass; the iOS build succeeds.
- [ ] On the simulator, the upgraded features work: push (via `xcrun simctl push`), in-app messages, links, share, review prompt, printing, camera — whichever the app uses.

## Decisions (defaults)

- Audit before migrating; the table lives in the repo next to the decisions.
- One commit per plugin, green after each.
- Critical SDKs block the series; others get a workaround. A workaround on the SDK that owns notifications and deep links is too risky.
- Never fork third-party plugins.

## Risks

| Risk | Mitigation |
|---|---|
| A critical SDK has no compatible version | Blocking; escalate to the vendor. |
| The compatible version needs a newer Flutter than the target | Record it; prefer a workaround over a second SDK bump; ask. |
| Major upgrades bring Dart breaking changes | One commit per plugin; run the tests of the packages that use it. |
| The simulator doesn't deliver real pushes | `xcrun simctl push` with `.apns` payloads; note the residual risk. |
