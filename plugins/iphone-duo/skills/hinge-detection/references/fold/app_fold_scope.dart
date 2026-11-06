// Template for iPhone Duo step 7. Place in the UI package under src/fold/.
// This is the ONLY file that imports package:foldable. When Flutter reports
// the hinge natively (flutter/flutter#192515), change this file only.
//
// Written against foldable 1.0.5. Re-check the API if the pinned version
// differs.
import 'dart:ui' show DisplayFeatureType;

import 'package:flutter/widgets.dart';
// foldable exports its own FoldInfo; hide it so ours is the only one.
import 'package:foldable/foldable.dart' hide FoldInfo;

import 'fold_info.dart';

/// Root widget that detects the posture and exposes [FoldInfo] below it.
///
/// Mount it once in `MaterialApp(.router)(builder: ...)`, below the
/// app's own `MediaQuery`, so the bridged display features are not
/// overwritten.
///
/// With [confineModals] (bridge mode `full`) the package also publishes the
/// hinge in `MediaQuery.displayFeatures`, so Flutter confines dialogs,
/// bottom sheets, popup menus and pickers to one half of the inner display.
class AppFoldScope extends StatelessWidget {
  const AppFoldScope({
    required this.child,
    this.confineModals = true,
    @visibleForTesting this.debugFoldInfo,
    super.key,
  });

  final Widget child;

  /// Profile `hinge.modals`: `confine` -> true, `leave` -> false.
  final bool confineModals;

  /// Forces a [FoldInfo] in tests; bypasses the package entirely.
  final FoldInfo? debugFoldInfo;

  @override
  Widget build(BuildContext context) {
    final forced = debugFoldInfo;
    if (forced != null) return _FoldInfoScope(info: forced, child: child);

    return FoldableProvider(
      bridgeMode: confineModals
          ? DisplayFeatureBridgeMode.full
          : DisplayFeatureBridgeMode.none,
      child: Builder(
        builder: (context) =>
            _FoldInfoScope(info: _read(context), child: child),
      ),
    );
  }

  static FoldInfo _read(BuildContext context) {
    final posture = switch (DuoMediaQuery.statusOf(context)) {
      HingeStatus.partiallyOpen => FoldPosture.halfOpened,
      HingeStatus.fullyOpen => FoldPosture.flat,
      HingeStatus.closed || HingeStatus.unknown => FoldPosture.none,
    };
    if (posture != FoldPosture.halfOpened) return FoldInfo(posture: posture);
    return FoldInfo(posture: posture, hingeBounds: _hinge(context));
  }

  /// Prefers MediaQuery (the bridge in `full` mode today, Flutter natively
  /// once #192515 lands), then the package's reserved regions.
  static Rect? _hinge(BuildContext context) {
    for (final feature in MediaQuery.displayFeaturesOf(context)) {
      if (feature.type == DisplayFeatureType.hinge ||
          feature.type == DisplayFeatureType.fold) {
        return feature.bounds;
      }
    }
    for (final region in DuoMediaQuery.regionsOf(context)) {
      if (region.kind == ReservedRegionKind.division &&
          region.wouldSplitLayout) {
        return region.bounds;
      }
    }
    return null;
  }
}

class _FoldInfoScope extends InheritedWidget {
  const _FoldInfoScope({required this.info, required super.child});

  final FoldInfo info;

  @override
  bool updateShouldNotify(_FoldInfoScope oldWidget) => info != oldWidget.info;
}

/// `context.foldInfo`: the current fold state, or [FoldPosture.none] when no
/// [AppFoldScope] is above.
extension FoldInfoContext on BuildContext {
  FoldInfo get foldInfo =>
      dependOnInheritedWidgetOfExactType<_FoldInfoScope>()?.info ??
      const FoldInfo();
}
