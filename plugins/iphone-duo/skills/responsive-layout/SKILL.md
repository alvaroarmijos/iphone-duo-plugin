---
name: responsive-layout
description: iPhone Duo step 5/8. Makes every Flutter screen lay out from the real available width and safe area (MediaQuery.sizeOf / paddingOf, per-side insets) and caps page content at a maximum width, centered, on wide screens like the iPhone Duo inner display, with no visual change on standard phones. Use as part of iphone-duo:adopt or alone to "make layouts width-driven / cap content width on wide screens".
---

# Step 5 — Width-driven layouts and a content-width cap

**Why:** the inner display is much wider than a phone, its safe area can be asymmetric, and it ignores supported orientations. Layouts sized from `MediaQuery.of(context).size` or symmetric safe-area paddings stretch cards and buttons across the whole width.

**Reads from the profile:** `layout.content_width` (`enabled`, `max`, default 600), `layout.ui_package`, `camera.portrait_lock_screens` (excluded here, handled in step 6). Template: `references/app_content_constraint.dart`.

## Scope

In: `MediaQuery.of(context).size` → `MediaQuery.sizeOf(context)`; safe-area-derived symmetric horizontal paddings → per-side insets with `MediaQuery.paddingOf`; an `AppContentConstraint` widget; wrapping every page body with it.
Out: hinge logic (steps 7–8); two-pane layouts; camera screens (step 6); a dedicated tablet/iPad redesign; constant design paddings.

## Implement

1. **Widget.** Create `AppContentConstraint` and `maxContentWidth = <profile max>` in the UI package (or `lib/` if none), export it, and add widget tests: width ≤ max is unconstrained; width > max is capped and centered. Follow the project's widget/test conventions (barrel files, `pumpApp` helpers).
2. **sizeOf.** Replace every `MediaQuery.of(context).size` with `MediaQuery.sizeOf(context)` (also `.padding` → `paddingOf`, `.viewInsets` → `viewInsetsOf`, etc.) in `lib/` and packages, except the camera screens left for step 6. Batch by feature folder, one commit each if large.
3. **Asymmetric safe area.** Find horizontal paddings derived from the safe area (`EdgeInsets.symmetric(horizontal: …padding…)`, `padding.horizontal`, `viewPadding.left` used for both sides) and switch to `EdgeInsets.only(left: p.left + x, right: p.right + x)` with `final p = MediaQuery.paddingOf(context)`. Leave constant design values alone.
4. **Wrap pages.** For every page with a `Scaffold`, wrap the `body` with `AppContentConstraint`. App bars, bottom navigation, tab bars and full-bleed media stay full width. Start with the highest-traffic features, then the rest; one commit per feature group. Ask the developer before wrapping screens that are intentionally full-bleed (maps, video, camera, onboarding art).
5. **Look at it.** On the iPhone Duo simulator (inner display, fully open) check the main screens; on a standard iPhone simulator check nothing changed.

## Verify

- [ ] `grep -rn "MediaQuery.of(context).size" lib packages --include=*.dart` returns only the step-6 camera files.
- [ ] No `EdgeInsets.symmetric(horizontal:` takes a value from `MediaQuery` padding.
- [ ] `AppContentConstraint` has tests for ≤ max and > max, and they pass.
- [ ] Every `Scaffold` page wraps its body (except the full-bleed screens the developer excluded, listed in the profile).
- [ ] On the iPhone Duo simulator, inner display, page content is `<max>` pt wide and centered; app bars and navigation are full width.
- [ ] On a standard iPhone simulator, screens look the same as before.
- [ ] Analyze and all tests pass; new files are fully covered.

## Decisions (defaults)

- Lay out by width, not platform or orientation: the inner display ignores orientations.
- Cap at 600 pt, centered: avoids absurdly wide cards and buttons without a redesign.
- Cap per page body: app bars and navigation keep full width.
- Not a global cap in `MaterialApp.builder`: the whole app would look like a centered phone with side bars.
- Only fix safe-area-derived paddings, the ones that break with an asymmetric safe area.

## Risks

| Risk | Mitigation |
|---|---|
| Wrapping a body breaks a layout that expected the full width (e.g. a horizontal carousel) | Visual pass per feature; exclude and record in the profile if intended. |
| Scrollables lose bounded height | `AppContentConstraint` uses `Align`, which passes the parent's max height; check scroll screens. |
| Large diff | Split commits by feature folder. |
