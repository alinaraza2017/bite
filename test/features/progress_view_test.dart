import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:bite/domain/feature_gate.dart';
import 'package:bite/domain/progress_report.dart';
import 'package:bite/features/progress/progress_view.dart';

void main() {
  ProgressReport foodOnly() {
    return buildProgressReport(
      today: DateTime(2026, 10, 28),
      dayCount: 7,
      logged: <String, DayTotals>{
        '2026-10-28': const DayTotals(
          eatenKcal: 2100,
          protein: 120,
          carbs: 200,
          fat: 60,
          loggedFood: true,
        ),
      },
      allFoodDates: <String>{'2026-10-28'},
      weights: <WeightPoint>[
        WeightPoint(day: DateTime(2026, 10, 28), kg: 70),
      ],
      calorieTarget: 2100,
      proteinTarget: 120,
      hasAnyFood: true,
      hasAnyWorkout: false,
    );
  }

  ProgressReport full() {
    return buildProgressReport(
      today: DateTime(2026, 10, 28),
      dayCount: 30,
      logged: <String, DayTotals>{
        for (int ago = 0; ago < 30; ago++)
          '2026-${_month(DateTime(2026, 10, 28).subtract(Duration(days: ago)))}':
              DayTotals(
            eatenKcal: ago == 0 ? 2400 : 1900,
            protein: 100,
            carbs: 180,
            fat: 50,
            burnedKcal: 100,
            workouts: ago % 3 == 0 ? 1 : 0,
            minutes: ago % 3 == 0 ? 40 : 0,
            loggedFood: true,
          ),
      },
      allFoodDates: <String>{
        for (int ago = 0; ago < 30; ago++)
          '2026-${_month(DateTime(2026, 10, 28).subtract(Duration(days: ago)))}',
      },
      weights: <WeightPoint>[
        WeightPoint(day: DateTime(2026, 10, 1), kg: 72),
        WeightPoint(day: DateTime(2026, 10, 28), kg: 71.2),
      ],
      calorieTarget: 2100,
      proteinTarget: 120,
      hasAnyFood: true,
      hasAnyWorkout: true,
    );
  }

  Future<void> pump(
    WidgetTester tester,
    ProgressView view,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(MaterialApp(home: view));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    tester.view.physicalSize = const Size(360, 2400);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets('new user sees the empty state', (tester) async {
    await pump(
      tester,
      ProgressView(
        report: ProgressReport.empty,
        premium: false,
        range: 7,
        calorieTarget: 2100,
        proteinTarget: 120,
        carbTarget: 200,
        fatTarget: 60,
        onRange: (_) {},
        onLockedRange: () {},
        onLogFood: () {},
        onAddWeight: () {},
        onPremium: () {},
      ),
    );
    expect(
      find.text(
        'Nothing to show yet. Log your first meal and your progress will appear here.',
      ),
      findsOneWidget,
    );
    expect(find.text('Log food'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('food only still shows the weight nudge', (tester) async {
    await pump(
      tester,
      ProgressView(
        report: foodOnly(),
        premium: false,
        range: 7,
        calorieTarget: 2100,
        proteinTarget: 120,
        carbTarget: 200,
        fatTarget: 60,
        onRange: (_) {},
        onLockedRange: () {},
        onLogFood: () {},
        onAddWeight: () {},
        onPremium: () {},
      ),
    );
    expect(find.text('Add your weight to start your trend.'), findsOneWidget);
    expect(find.text('Average of days you logged.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('full progress fits a small phone at 1.3 text', (tester) async {
    await pump(
      tester,
      ProgressView(
        report: full(),
        premium: true,
        range: 30,
        calorieTarget: 2100,
        proteinTarget: 120,
        carbTarget: 200,
        fatTarget: 60,
        onRange: (_) {},
        onLockedRange: () {},
        onLogFood: () {},
        onAddWeight: () {},
        onPremium: () {},
      ),
    );
    expect(find.text('Last 30 days'), findsOneWidget);
    expect(find.textContaining('sessions'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('free users cannot open 30 days and premium updates at once', (
    tester,
  ) async {
    final _Premium flag = _Premium();
    int? chosen;
    var locked = false;
    tester.view.physicalSize = const Size(360, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      ChangeNotifierProvider<_Premium>.value(
        value: flag,
        child: MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              final bool allowed = FeatureGate(
                isPremium: context.watch<_Premium>().on,
              ).canUse(Feature.fullHistory);
              return ProgressView(
                report: foodOnly(),
                premium: allowed,
                range: allowed ? 30 : 7,
                calorieTarget: 2100,
                proteinTarget: 120,
                carbTarget: 200,
                fatTarget: 60,
                onRange: (int days) => chosen = days,
                onLockedRange: () => locked = true,
                onLogFood: () {},
                onAddWeight: () {},
                onPremium: () {},
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.text('Full history and advanced insights'), findsOneWidget);
    await tester.tap(find.text('30 days'));
    await tester.pump();
    expect(locked, isTrue);
    expect(chosen, isNull);

    flag.set(true);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.lock_outline), findsNothing);
    expect(find.text('Full history and advanced insights'), findsNothing);
    await tester.tap(find.text('30 days'));
    await tester.pump();
    expect(chosen, 30);
  });
}

String _month(DateTime day) {
  final String month = day.month.toString().padLeft(2, '0');
  final String date = day.day.toString().padLeft(2, '0');
  return '$month-$date';
}

class _Premium extends ChangeNotifier {
  bool on = false;

  void set(bool value) {
    on = value;
    notifyListeners();
  }
}
