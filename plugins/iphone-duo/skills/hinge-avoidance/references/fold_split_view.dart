// Template for iPhone Duo step 8. Place in the UI package next to the fold
// types from step 7 (it reads `context.foldInfo`).
import 'package:flutter/widgets.dart';

import 'fold/fold.dart'; // FoldInfo, context.foldInfo (adjust the import)

/// Splits a page around the hinge when the iPhone Duo is half-opened.
///
/// - Hinge separating the screen: [start] and [end] are laid out on each
///   side of the hinge, nothing is drawn over it. Vertical hinge: [start]
///   is the leading side (left in LTR, right in RTL). Horizontal hinge:
///   [start] is on top.
/// - Any other posture (standard phone, outer display, inner display flat):
///   shows [child], the page's normal layout.
///
/// Place it where the constraints are bounded (e.g. a `Scaffold.body`).
/// Keep blocs/providers ABOVE it so switching posture never recreates state.
/// For an empty side use `const SizedBox.shrink()`.
class FoldSplitView extends StatefulWidget {
  const FoldSplitView({
    required this.child,
    required this.start,
    required this.end,
    super.key,
  });

  final Widget child;
  final Widget start;
  final Widget end;

  @override
  State<FoldSplitView> createState() => _FoldSplitViewState();
}

class _FoldSplitViewState extends State<FoldSplitView> {
  /// Global position of this widget. The hinge comes in screen coordinates,
  /// so it is shifted by this origin to get local coordinates. Measured after
  /// layout; the first half-opened frame assumes the widget's previous origin.
  Offset _origin = Offset.zero;

  void _measure(Duration _) {
    if (!mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final origin = box.localToGlobal(Offset.zero);
    if (origin != _origin) setState(() => _origin = origin);
  }

  @override
  Widget build(BuildContext context) {
    final fold = context.foldInfo;
    if (!fold.isSeparating) return widget.child;

    WidgetsBinding.instance.addPostFrameCallback(_measure);
    final hinge = fold.hingeBounds!.shift(-_origin);
    final rtl = Directionality.of(context) == TextDirection.rtl;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth || !constraints.hasBoundedHeight) {
          assert(false, 'FoldSplitView needs bounded constraints.');
          return widget.child;
        }
        final size = constraints.biggest;

        if (fold.isVerticalHinge) {
          final left = hinge.left.clamp(0.0, size.width);
          final right = (size.width - hinge.right).clamp(0.0, size.width);
          return Row(
            textDirection: TextDirection.ltr, // physical left -> right
            children: [
              SizedBox(width: left, child: rtl ? widget.end : widget.start),
              SizedBox(
                width: (size.width - left - right).clamp(0.0, size.width),
              ),
              SizedBox(width: right, child: rtl ? widget.start : widget.end),
            ],
          );
        }

        final top = hinge.top.clamp(0.0, size.height);
        final bottom = (size.height - hinge.bottom).clamp(0.0, size.height);
        return Column(
          children: [
            SizedBox(height: top, child: widget.start),
            SizedBox(
              height: (size.height - top - bottom).clamp(0.0, size.height),
            ),
            SizedBox(height: bottom, child: widget.end),
          ],
        );
      },
    );
  }
}

// Widget test sketch, using step 7's debug hook:
//
// AppFoldScope(
//   debugFoldInfo: const FoldInfo(
//     posture: FoldPosture.halfOpened,
//     hingeBounds: Rect.fromLTWH(480, 0, 40, 700), // vertical hinge
//   ),
//   child: MediaQuery(data: const MediaQueryData(size: Size(1000, 700)),
//     child: Directionality(textDirection: TextDirection.ltr,
//       child: FoldSplitView(child: Text('single'), start: Text('a'), end: Text('b')))),
// )
// - expect 'a' right edge <= 480 and 'b' left edge >= 520; 'single' absent.
// - FoldPosture.flat -> only 'single'.
// - horizontal hinge Rect.fromLTWH(0, 330, 1000, 40) -> 'a' above, 'b' below.
