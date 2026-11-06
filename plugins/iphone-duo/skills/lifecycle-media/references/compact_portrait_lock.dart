// Template for iPhone Duo step 6. Place next to the feature that locks its
// orientation (camera, fullscreen video, scanner...).
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// shortestSide below which a screen is "compact": a standard phone or
/// the iPhone Duo outer display.
const double compactShortestSide = 600;

/// Locks [child] to [compactOrientations] (portrait by default) only on
/// compact screens, re-evaluates when the app moves between displays
/// (fold/unfold, Split View), and restores [restoreOrientations] when
/// disposed. For fullscreen video pass the landscape orientations.
class CompactPortraitLock extends StatefulWidget {
  const CompactPortraitLock({
    required this.child,
    this.compactOrientations = const [DeviceOrientation.portraitUp],
    this.restoreOrientations = DeviceOrientation.values,
    super.key,
  });

  final Widget child;

  /// Orientations to lock to on compact screens.
  final List<DeviceOrientation> compactOrientations;

  /// Orientations to restore on exit. Use the app's global setting.
  final List<DeviceOrientation> restoreOrientations;

  @override
  State<CompactPortraitLock> createState() => _CompactPortraitLockState();
}

class _CompactPortraitLockState extends State<CompactPortraitLock> {
  bool? _locked;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final compact =
        MediaQuery.sizeOf(context).shortestSide < compactShortestSide;
    // Only call the platform when the result changes, not on every rebuild.
    if (compact == _locked) return;
    _locked = compact;
    SystemChrome.setPreferredOrientations(
      compact ? widget.compactOrientations : widget.restoreOrientations,
    );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(widget.restoreOrientations);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// Widget test sketch: record SystemChrome calls through the platform channel.
//
// final calls = <MethodCall>[];
// TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
//     .setMockMethodCallHandler(SystemChannels.platform, (call) async {
//   if (call.method == 'SystemChrome.setPreferredOrientations') calls.add(call);
//   return null;
// });
// - compact (390x844): first call's arguments == ['DeviceOrientation.portraitUp']
// - wide (1000x800): first call's arguments contain every restore orientation
