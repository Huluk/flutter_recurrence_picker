import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recurrence_picker/recurrence_picker.dart';
import 'package:recurrence_picker/src/day_of_month_grid.dart';
import 'package:recurrence_picker/src/locale_utils.dart' show WeekdayChoice;

Future<void> pumpPicker(
  WidgetTester tester, {
  MonthlySelection selection = const MonthlySelection(),
  Set<int>? months,
  ValueChanged<MonthlySelection>? onChanged,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: RecurrenceLocalizations.localizationsDelegates,
      supportedLocales: RecurrenceLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: MonthlyPicker(
          selection: selection,
          months: months,
          onChanged: onChanged ?? (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('MonthlyPicker', () {
    group('renders', () {
      testWidgets('mode selector with Date and Weekday segments',
          (tester) async {
        await pumpPicker(tester);

        expect(
          find.byType(SegmentedButton<MonthlyMode>),
          findsOneWidget,
        );
        expect(find.text('Date'), findsOneWidget);
        expect(find.text('Weekday'), findsOneWidget);
      });

      testWidgets('DayOfMonthGrid in date mode', (tester) async {
        await pumpPicker(
          tester,
          selection: const MonthlySelection(mode: MonthlyMode.date),
        );

        expect(find.byType(DayOfMonthGrid), findsOneWidget);
        expect(find.byType(NthWeekdaySelector), findsNothing);
      });

      testWidgets('NthWeekdaySelector in weekday mode', (tester) async {
        await pumpPicker(
          tester,
          selection: const MonthlySelection(mode: MonthlyMode.weekday),
        );

        expect(find.byType(NthWeekdaySelector), findsOneWidget);
        expect(find.byType(DayOfMonthGrid), findsNothing);
      });
    });

    group('mode switching', () {
      testWidgets('tapping Weekday switches to weekday mode', (tester) async {
        MonthlySelection? received;
        await pumpPicker(
          tester,
          selection: const MonthlySelection(mode: MonthlyMode.date),
          onChanged: (v) => received = v,
        );

        await tester.tap(find.text('Weekday'));
        await tester.pumpAndSettle();

        expect(received?.mode, MonthlyMode.weekday);
      });

      testWidgets('tapping Date switches to date mode', (tester) async {
        MonthlySelection? received;
        await pumpPicker(
          tester,
          selection: const MonthlySelection(mode: MonthlyMode.weekday),
          onChanged: (v) => received = v,
        );

        await tester.tap(find.text('Date'));
        await tester.pumpAndSettle();

        expect(received?.mode, MonthlyMode.date);
      });
    });

    group('date mode interaction', () {
      testWidgets('tapping a day reports updated monthDay', (tester) async {
        MonthlySelection? received;
        await pumpPicker(
          tester,
          selection: const MonthlySelection(
            mode: MonthlyMode.date,
            monthDay: 1,
          ),
          onChanged: (v) => received = v,
        );

        await tester.tap(find.text('20'));
        expect(received?.monthDay, 20);
        // Mode stays the same.
        expect(received?.mode, MonthlyMode.date);
      });

      testWidgets('clamps selectedDay to daysInMonth for restricted months',
          (tester) async {
        // February has max 29 days. Day 31 should clamp to 29.
        await pumpPicker(
          tester,
          selection: const MonthlySelection(
            mode: MonthlyMode.date,
            monthDay: 31,
          ),
          months: {2}, // February only.
        );

        // The grid should show 29 days (maxDaysInMonth for Feb).
        final gridInkWells = find.descendant(
          of: find.byType(DayOfMonthGrid),
          matching: find.byType(InkWell),
        );
        expect(gridInkWells, findsNWidgets(29));
      });
    });

    group('weekday mode interaction', () {
      testWidgets('changing ordinal reports updated selection', (tester) async {
        MonthlySelection? received;
        await pumpPicker(
          tester,
          selection: const MonthlySelection(
            mode: MonthlyMode.weekday,
            ordinal: Ordinal.first,
          ),
          onChanged: (v) => received = v,
        );

        // Open ordinal dropdown and select "Last".
        await tester.tap(find.byType(DropdownButton<Ordinal>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Last').last);
        await tester.pumpAndSettle();

        expect(received?.ordinal, Ordinal.last);
        expect(received?.mode, MonthlyMode.weekday);
      });
    });

    group('MonthlySelection', () {
      test('copyWith preserves unspecified fields', () {
        const original = MonthlySelection(
          mode: MonthlyMode.date,
          monthDay: 15,
          ordinal: Ordinal.second,
          nthWeekday: WeekdayChoice.friday,
        );
        final copied = original.copyWith(monthDay: 20);

        expect(copied.mode, MonthlyMode.date);
        expect(copied.monthDay, 20);
        expect(copied.ordinal, Ordinal.second);
        expect(copied.nthWeekday, WeekdayChoice.friday);
      });

      test('equality compares all fields', () {
        const a = MonthlySelection(
          mode: MonthlyMode.date,
          monthDay: 15,
          ordinal: Ordinal.first,
          nthWeekday: WeekdayChoice.monday,
        );
        const b = MonthlySelection(
          mode: MonthlyMode.date,
          monthDay: 15,
          ordinal: Ordinal.first,
          nthWeekday: WeekdayChoice.monday,
        );
        const c = MonthlySelection(
          mode: MonthlyMode.weekday,
          monthDay: 15,
          ordinal: Ordinal.first,
          nthWeekday: WeekdayChoice.monday,
        );

        expect(a, b);
        expect(a, isNot(c));
      });

      test('hashCode is consistent with equality', () {
        const a = MonthlySelection(monthDay: 5);
        const b = MonthlySelection(monthDay: 5);
        expect(a.hashCode, b.hashCode);
      });
    });
  });
}
