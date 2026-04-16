import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recurrence_picker/src/day_of_month_grid.dart';

Future<void> pumpGrid(
  WidgetTester tester, {
  int daysInMonth = 31,
  int selectedDay = 1,
  ValueChanged<int>? onChanged,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DayOfMonthGrid(
          daysInMonth: daysInMonth,
          selectedDay: selectedDay,
          onChanged: onChanged ?? (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('DayOfMonthGrid', () {
    group('renders', () {
      testWidgets('an InkWell for each day in the month', (tester) async {
        await pumpGrid(tester, daysInMonth: 28);
        expect(find.byType(InkWell), findsNWidgets(28));
      });

      testWidgets('31 cells for a 31-day month', (tester) async {
        await pumpGrid(tester, daysInMonth: 31);
        expect(find.byType(InkWell), findsNWidgets(31));
      });

      testWidgets('day numbers as text', (tester) async {
        await pumpGrid(tester, daysInMonth: 31);

        // Spot-check a few day labels.
        expect(find.text('1'), findsOneWidget);
        expect(find.text('15'), findsOneWidget);
        expect(find.text('31'), findsOneWidget);
      });
    });

    group('selection', () {
      testWidgets('highlights selected day with primaryContainer color',
          (tester) async {
        await pumpGrid(tester, daysInMonth: 31, selectedDay: 15);

        // Find all Material widgets that use primaryContainer.
        final theme = Theme.of(tester.element(find.byType(DayOfMonthGrid)));
        final primaryContainer = theme.colorScheme.primaryContainer;

        final materials = tester
            .widgetList<Material>(find.descendant(
              of: find.byType(DayOfMonthGrid),
              matching: find.byType(Material),
            ))
            .where((m) => m.color == primaryContainer);

        // Exactly one cell should be highlighted.
        expect(materials, hasLength(1));
      });
    });

    group('interaction', () {
      testWidgets('tapping a day calls onChanged with that day number',
          (tester) async {
        int? received;
        await pumpGrid(
          tester,
          daysInMonth: 31,
          selectedDay: 1,
          onChanged: (v) => received = v,
        );

        await tester.tap(find.text('15'));
        expect(received, 15);
      });

      testWidgets('tapping day 1 reports 1', (tester) async {
        int? received;
        await pumpGrid(
          tester,
          daysInMonth: 31,
          selectedDay: 10,
          onChanged: (v) => received = v,
        );

        await tester.tap(find.text('1'));
        expect(received, 1);
      });

      testWidgets('tapping the last day reports daysInMonth',
          (tester) async {
        int? received;
        await pumpGrid(
          tester,
          daysInMonth: 28,
          selectedDay: 1,
          onChanged: (v) => received = v,
        );

        await tester.tap(find.text('28'));
        expect(received, 28);
      });
    });
  });
}
