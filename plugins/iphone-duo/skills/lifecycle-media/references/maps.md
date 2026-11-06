# Maps (`kind: maps`)

Packages: `google_maps_flutter`, `apple_maps_flutter`, `flutter_map`, `mapbox_maps_flutter`.

**Profile:** `screens`; optional `track_location_in_split_view` (default `true`).

## Implement

1. **Life cycle.** Maps rarely need a life cycle policy. Only location streams (`geolocator`, `location`) matter: keep them on `inactive` (the map stays visible in Split View) and stop them on `paused` unless the app has background location. Add a Split View comment where you change it.
2. **Keep the map on resize.** On fold/unfold the native map view is laid out again; it must not be recreated. Keep the map widget and its controller stable across the size change (no `key` that depends on size, no `LayoutBuilder` branch that swaps map widgets). If the visible region should stay the same, store the last camera position (`onCameraMove`) and re-apply it after the size change only if the map jumped.
3. **Controls and overlays.** Floating buttons, search bars, bottom sheets and info cards are positioned relative to the map, with a max width on the inner display (step 5's content width does not apply to full-bleed maps). If the screen avoids the hinge (step 8), keep controls off the hinge.
4. **Gestures.** Check that pan and zoom still work after unfolding (platform view gesture recognizers survive the re-layout).

## Verify

- [ ] After fold/unfold the map shows the same area, without a reload or a reset to the initial position.
- [ ] Controls and cards stay reachable and are not stretched across the inner display.
- [ ] Location updates continue in Split View and stop in the background (unless background location is a feature).
- [ ] Pan and zoom work after unfolding.

## Decisions

- No orientation lock on map screens: maps adapt to any size.
- Location stops on `paused`, not `inactive`: the map stays visible in Split View.
