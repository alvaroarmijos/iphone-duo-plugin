import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:duo_tpl/duo_tpl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _sized(Size size, Widget child, {TextDirection dir = TextDirection.ltr}) =>
    MediaQuery(
      data: MediaQueryData(size: size),
      child: Directionality(textDirection: dir, child: child),
    );

void main() {
  group('AppContentConstraint', () {
    testWidgets('no cap when narrow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const Directionality(
          textDirection: TextDirection.ltr,
          child: AppContentConstraint(child: SizedBox.expand(key: Key('c')))));
      expect(tester.getSize(find.byKey(const Key('c'))).width, 390);
    });
    testWidgets('caps and centers when wide', (tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const Directionality(
          textDirection: TextDirection.ltr,
          child: AppContentConstraint(child: SizedBox.expand(key: Key('c')))));
      final r = tester.getRect(find.byKey(const Key('c')));
      expect(r.width, maxContentWidth);
      expect(r.left, 200);
      expect(r.height, 800);
    });
  });

  group('CompactPortraitLock', () {
    late List<MethodCall> calls;
    setUp(() {
      calls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'SystemChrome.setPreferredOrientations') calls.add(call);
        return null;
      });
    });
    testWidgets('locks portrait when compact, unlocks when wide', (tester) async {
      await tester.pumpWidget(_sized(const Size(390, 844), const CompactPortraitLock(child: SizedBox())));
      expect(calls.single.arguments, ['DeviceOrientation.portraitUp']);
      await tester.pumpWidget(_sized(const Size(390, 845), const CompactPortraitLock(child: SizedBox())));
      expect(calls, hasLength(1), reason: 'no call when result unchanged');
      await tester.pumpWidget(_sized(const Size(951, 669), const CompactPortraitLock(child: SizedBox())));
      expect(calls, hasLength(2));
      expect((calls.last.arguments as List).length, 4);
      await tester.pumpWidget(const SizedBox());
      expect(calls, hasLength(3), reason: 'restores on dispose');
    });
  });

  group('FoldInfo / AppFoldScope', () {
    test('isSeparating and equality', () {
      const a = FoldInfo(posture: FoldPosture.halfOpened, hingeBounds: Rect.fromLTWH(455, 0, 40, 669));
      expect(a.isSeparating, isTrue);
      expect(a.isVerticalHinge, isTrue);
      expect(a, const FoldInfo(posture: FoldPosture.halfOpened, hingeBounds: Rect.fromLTWH(455, 0, 40, 669)));
      expect(const FoldInfo(posture: FoldPosture.halfOpened).isSeparating, isFalse);
    });
    testWidgets('no scope -> none', (tester) async {
      late FoldInfo info;
      await tester.pumpWidget(Builder(builder: (c) { info = c.foldInfo; return const SizedBox(); }));
      expect(info.posture, FoldPosture.none);
    });
    testWidgets('debugFoldInfo is exposed', (tester) async {
      late FoldInfo info;
      const forced = FoldInfo(posture: FoldPosture.flat);
      await tester.pumpWidget(AppFoldScope(debugFoldInfo: forced,
          child: Builder(builder: (c) { info = c.foldInfo; return const SizedBox(); })));
      expect(info, forced);
    });
    testWidgets('real scope on a non-foldable reports none', (tester) async {
      late FoldInfo info;
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => AppFoldScope(child: child!),
        home: Builder(builder: (c) { info = c.foldInfo; return const SizedBox(); }),
      ));
      await tester.pump();
      expect(info.posture, FoldPosture.none);
    });
  });

  group('FoldSplitView', () {
    Widget split(FoldInfo fold, {TextDirection dir = TextDirection.ltr, Size size = const Size(951, 669)}) =>
        AppFoldScope(
          debugFoldInfo: fold,
          child: _sized(size, const FoldSplitView(
            start: SizedBox.expand(key: Key('s')),
            end: SizedBox.expand(key: Key('e')),
            child: SizedBox.expand(key: Key('c')),
          ), dir: dir),
        );
    setUp(() {
      final view = TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!;
      view.physicalSize = const Size(951, 669);
      view.devicePixelRatio = 1;
    });
    tearDown(() => TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!.reset());
    const vertical = FoldInfo(posture: FoldPosture.halfOpened, hingeBounds: Rect.fromLTWH(455, 0, 40, 669));

    testWidgets('flat shows child', (tester) async {
      await tester.pumpWidget(split(const FoldInfo(posture: FoldPosture.flat)));
      expect(find.byKey(const Key('c')), findsOneWidget);
      expect(find.byKey(const Key('s')), findsNothing);
    });
    testWidgets('vertical hinge LTR', (tester) async {
      await tester.pumpWidget(split(vertical));
      await tester.pump();
      expect(tester.getRect(find.byKey(const Key('s'))), const Rect.fromLTWH(0, 0, 455, 669));
      expect(tester.getRect(find.byKey(const Key('e'))), const Rect.fromLTWH(495, 0, 456, 669));
    });
    testWidgets('vertical hinge RTL mirrors', (tester) async {
      await tester.pumpWidget(split(vertical, dir: TextDirection.rtl));
      await tester.pump();
      expect(tester.getRect(find.byKey(const Key('e'))).left, 0);
      expect(tester.getRect(find.byKey(const Key('s'))).left, 495);
    });
    testWidgets('horizontal hinge', (tester) async {
      await tester.pumpWidget(split(const FoldInfo(posture: FoldPosture.halfOpened,
          hingeBounds: Rect.fromLTWH(0, 300, 951, 40))));
      await tester.pump();
      expect(tester.getRect(find.byKey(const Key('s'))), const Rect.fromLTWH(0, 0, 951, 300));
      expect(tester.getRect(find.byKey(const Key('e'))).top, 340);
    });
    testWidgets('offset widget shifts hinge to local coordinates', (tester) async {
      await tester.pumpWidget(AppFoldScope(
        debugFoldInfo: vertical,
        child: _sized(const Size(951, 669), const Padding(
          padding: EdgeInsets.only(left: 100),
          child: FoldSplitView(
            start: SizedBox.expand(key: Key('s')),
            end: SizedBox.expand(key: Key('e')),
            child: SizedBox.expand(key: Key('c')),
          ),
        )),
      ));
      await tester.pump();
      expect(tester.getRect(find.byKey(const Key('s'))).right, 455);
      expect(tester.getRect(find.byKey(const Key('e'))).left, 495);
    });
  });

  test('display feature type is reachable', () {
    const f = DisplayFeature(bounds: Rect.zero, type: DisplayFeatureType.hinge, state: DisplayFeatureState.postureHalfOpened);
    expect(f.type, DisplayFeatureType.hinge);
  });
}
