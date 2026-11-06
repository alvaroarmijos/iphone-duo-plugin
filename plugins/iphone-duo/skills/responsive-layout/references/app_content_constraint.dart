// Template for iPhone Duo step 5. Place in the UI package
// (e.g. packages/app_ui/lib/src/widgets/app_content_constraint.dart)
// and export it from the package's widgets barrel.
import 'package:flutter/widgets.dart';

/// Maximum width of page content on wide screens such as the
/// iPhone Duo inner display. Value comes from .iphone-duo/profile.md
/// (`layout.content_width.max`).
const double maxContentWidth = 600;

/// Caps [child] at [maxWidth] and centers it horizontally.
///
/// Has no effect when the available width is <= [maxWidth], so standard
/// phones render exactly as before. Wrap a page's `Scaffold.body` with it;
/// leave app bars and navigation at full width.
class AppContentConstraint extends StatelessWidget {
  const AppContentConstraint({
    required this.child,
    this.maxWidth = maxContentWidth,
    super.key,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

// Widget test sketch (adapt to the project's pumpApp helper):
//
// testWidgets('does not constrain when width <= maxWidth', (tester) async {
//   tester.view.physicalSize = const Size(390, 844);
//   tester.view.devicePixelRatio = 1;
//   addTearDown(tester.view.reset);
//   await tester.pumpWidget(const AppContentConstraint(child: SizedBox.expand()));
//   expect(tester.getSize(find.byType(SizedBox)).width, 390);
// });
//
// testWidgets('caps and centers when width > maxWidth', (tester) async {
//   tester.view.physicalSize = const Size(1000, 800);
//   tester.view.devicePixelRatio = 1;
//   addTearDown(tester.view.reset);
//   await tester.pumpWidget(const AppContentConstraint(child: SizedBox.expand()));
//   final rect = tester.getRect(find.byType(SizedBox));
//   expect(rect.width, maxContentWidth);
//   expect(rect.left, (1000 - maxContentWidth) / 2);
// });
