import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bite/ui/widgets/week_day_strip.dart';
import 'package:bite/widgets/bite_back_button.dart';

void main() {
  testWidgets('future days do not open and past days do', (tester) async {
    final DateTime today = DateTime.now();
    final DateTime monday = today.subtract(Duration(days: today.weekday - 1));
    DateTime? tapped;
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WeekDayStrip(
            anchor: today,
            selected: today,
            kcalByDay: const <String, int>{},
            daysWithData: const <String>{},
            premium: false,
            onDay: (DateTime day) => tapped = day,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final DateTime future = monday.add(const Duration(days: 6));
    if (future.isAfter(DateTime(today.year, today.month, today.day))) {
      await tester.tap(find.text('${future.day}').last);
      await tester.pump();
      expect(tapped, isNull);
    }

    await tester.tap(find.text('${today.day}'));
    await tester.pump();
    expect(tapped?.day, today.day);
  });

  testWidgets('back button hides on a root page and shows after a push', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: Column(
                children: [
                  const BiteBackButton(),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (BuildContext next) {
                            return const Scaffold(body: BiteBackButton());
                          },
                        ),
                      );
                    },
                    child: const Text('Open'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
