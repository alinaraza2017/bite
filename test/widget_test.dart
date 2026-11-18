import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bite/app.dart';
import 'package:bite/data/repositories/auth_repository.dart';
import 'package:bite/data/repositories/profile_repository.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      AuthRepository.accountKey: 1,
      '${ProfileRepository.onboardingDoneKey}_1': true,
    });
  });

  testWidgets('bottom bar stays low when the system inset is huge', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 400);
    tester.view.viewPadding = const FakeViewPadding(bottom: 400);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(const BiteApp());
    await tester.pumpAndSettle();

    final RenderBox progress =
        tester.renderObject(find.text('Progress')) as RenderBox;
    final double labelBottom =
        progress.localToGlobal(Offset.zero).dy + progress.size.height;
    expect(labelBottom, greaterThan(700));
    expect(tester.takeException(), isNull);
  });

  testWidgets('app starts on Home and opens Workout', (tester) async {
    await tester.pumpWidget(const BiteApp());
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsNWidgets(2));
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Workout'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);

    await tester.tap(find.text('Workout'));
    await tester.pumpAndSettle();

    expect(find.text('Workout'), findsNWidgets(2));
  });

  testWidgets('small phone at 1.3 text scale does not overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const BiteApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Workout'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('onboarding at 1.3 text scale does not overflow', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const BiteApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    expect(find.text('Log in'), findsWidgets);
  });
}
