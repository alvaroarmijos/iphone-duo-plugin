// Template for iPhone Duo step 7. Place in the UI package under src/fold/.
// Plain Dart types: features depend on these, never on package:foldable.
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Device posture, independent of the package that detects it.
enum FoldPosture {
  /// Not a foldable, or the iPhone Duo closed (outer display).
  none,

  /// Inner display fully open: no active hinge.
  flat,

  /// Inner display half-opened: the hinge splits the screen in two.
  halfOpened,
}

/// Fold information consumed by features through `context.foldInfo`.
@immutable
class FoldInfo {
  const FoldInfo({this.posture = FoldPosture.none, this.hingeBounds});

  final FoldPosture posture;

  /// The hinge in global (screen) coordinates.
  /// Only non-null when [posture] is [FoldPosture.halfOpened].
  final Rect? hingeBounds;

  /// Whether the hinge currently separates the screen into two areas.
  bool get isSeparating =>
      posture == FoldPosture.halfOpened && hingeBounds != null;

  /// Whether the hinge runs top to bottom (content goes left and right).
  bool get isVerticalHinge =>
      hingeBounds != null && hingeBounds!.height >= hingeBounds!.width;

  @override
  bool operator ==(Object other) =>
      other is FoldInfo &&
      other.posture == posture &&
      other.hingeBounds == hingeBounds;

  @override
  int get hashCode => Object.hash(posture, hingeBounds);

  @override
  String toString() => 'FoldInfo($posture, $hingeBounds)';
}
