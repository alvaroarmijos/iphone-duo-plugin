---
name: hinge-avoidance
description: iPhone Duo step 8/8. Keeps the screens the developer chose clear of the iPhone Duo hinge when half-opened - a reusable FoldSplitView lays content out on each side of the hinge (two columns, one side only, or a list split) and falls back to the normal layout in every other posture. Use as part of iphone-duo:adopt or alone to "keep content off the hinge" on specific screens.
---

# Step 8 — Keep chosen screens clear of the hinge

**Why:** when the iPhone Duo is half-opened, the hinge splits the inner display in two and anything drawn over it is folded and hard to read or tap. Dialogs and sheets are already handled globally by step 7; this step adapts the screens the developer chose.

**Reads from the profile:** `hinge.support` (must be `avoid`; `two-pane` is out of scope — stop and say so; `none` skips), `hinge.screens` (screen, file, mode, start/end contents), `layout.ui_package`. Needs step 7's `context.foldInfo` and step 5's layout. Template: `references/fold_split_view.dart`.

## Scope

In: the `FoldSplitView` widget; adapting each screen in `hinge.screens`; widget tests per screen in half-opened and flat postures.
Out: other screens; a real two-pane / master-detail experience; modal changes (step 7); the fully open layout (step 5).

## Split modes

| Mode | Half-opened layout | Good for |
|---|---|---|
| `columns` | Meaningful split: `start` = one part (e.g. the question, header, banner + summary), `end` = the other (answers, rankings, terms + action) | Screens with two natural regions |
| `start-only` | Everything in `start`, `end` empty | A single document, PDF, video, form, welcome/result views |
| `list-split` | Items alternate between columns (even indexes `start`, odd `end`), each column scrolls on its own | Card lists and feeds |

Horizontal hinge: `start` goes on top, `end` below.

## Implement

1. **Widget.** Copy `references/fold_split_view.dart` into the UI package next to the fold types, fix the import, export it. Tests: no hinge → `child`; vertical hinge → `start`/`end` left/right without overlapping the hinge (and mirrored in RTL); horizontal hinge → top/bottom.
2. **Confirm each screen's split.** For each `hinge.screens` entry without `start`/`end` details, read the screen's widget tree, propose a concrete split (which widgets go in each side), and ask the developer to confirm. Record it in the profile.
3. **Adapt one screen at a time** (one commit each):
   - Keep blocs/providers, listeners, loading overlays and app/tab bars **outside** `FoldSplitView` so changing posture never recreates state and overlays keep full width.
   - Pass the current layout as `child` unchanged; build `start`/`end` from the same widgets (extract private widgets rather than duplicating code).
   - `list-split`: two `ListView`s over the even/odd items, same item builder.
   - Widget test with `AppFoldScope(debugFoldInfo: …)` in `halfOpened` (assert each part lands on its side and nothing overlaps `hingeBounds`) and in `flat` (normal layout).
4. **End to end.** On the iPhone Duo simulator, half-opened, complete each screen's main flow (answer, buy, submit…) and switch posture mid-flow: the state must survive.

## Verify

- [ ] `FoldSplitView` has tests for no hinge, vertical hinge (LTR and RTL) and horizontal hinge.
- [ ] Half-opened on the Duo simulator, no text, button or image on the chosen screens overlaps the hinge.
- [ ] Each chosen screen splits as recorded in the profile (show the table: screen, start, end).
- [ ] Fully open, the chosen screens show step 5's layout (one centered column).
- [ ] On a standard iPhone, the chosen screens are unchanged.
- [ ] Every chosen screen has half-opened and flat widget tests, and they pass.
- [ ] Each screen's main flow works end to end half-opened, and survives a posture change.

## Decisions (defaults)

- Support level "avoid the hinge", not a two-pane experience: content apps gain little from real two-pane layouts for a lot of maintenance.
- Only the screens the developer chose, plus modals globally (step 7).
- Two columns on each side of the hinge, not "move everything to one half" and not one column with a hinge-wide gap (cuts cards in two).
- `start-only` for screens with no natural split (single documents, welcome/result views).
- `list-split` by index for card lists: simple, no master-detail.

## Risks

| Risk | Mitigation |
|---|---|
| Splitting a big screen mixes layout with listeners and state | Only presentation widgets move; listeners, overlays and providers stay outside `FoldSplitView`. |
| Two independently scrolling columns disorient on long lists | Accepted for `list-split`; revisit in QA (a single-scroll grid is a future option). |
| A posture change loses scroll position or progress | Providers above `FoldSplitView`; end-to-end check switches posture mid-flow. |
| The widget isn't at the screen origin | `FoldSplitView` measures its global origin and shifts the hinge into local coordinates. |
