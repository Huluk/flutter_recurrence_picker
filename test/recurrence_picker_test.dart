import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recurrence_picker/recurrence_picker.dart';
import 'package:recurrence_picker/src/month_grid.dart';
import 'package:recurrence_picker/src/monthly_picker.dart';
import 'package:recurrence_picker/src/number_stepper.dart';
import 'package:recurrence_picker/src/weekly_day_picker.dart';
import 'package:rrule/rrule.dart';

Future<void> pumpPicker(
  WidgetTester tester, {
  Frequency initialFrequency = Frequency.weekly,
  int initialInterval = 1,
  DateTime? startDate,
  EndOfMonthBehavior defaultEndOfMonthBehavior = EndOfMonthBehavior.previousDay,
  bool showEndOfMonthSelector = true,
  ValueChanged<RecurrenceRule>? onRecurrenceChanged,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: RecurrenceLocalizations.localizationsDelegates,
      supportedLocales: RecurrenceLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: SingleChildScrollView(
          child: RecurrencePicker(
            initialFrequency: initialFrequency,
            initialInterval: initialInterval,
            startDate: startDate,
            defaultEndOfMonthBehavior: defaultEndOfMonthBehavior,
            showEndOfMonthSelector: showEndOfMonthSelector,
            onRecurrenceChanged: onRecurrenceChanged ?? (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('RecurrencePicker', () {
    group('initial render (Every mode)', () {
      testWidgets('shows mode dropdown, interval stepper, frequency dropdown',
          (tester) async {
        await pumpPicker(tester);

        expect(
          find.byType(DropdownButton<RecurrenceMode>),
          findsOneWidget,
        );
        expect(find.byType(NumberStepper), findsOneWidget);
        expect(
          find.byType(DropdownButton<Frequency>),
          findsOneWidget,
        );
      });

      testWidgets('displays initial frequency label', (tester) async {
        await pumpPicker(tester, initialFrequency: Frequency.monthly);
        expect(find.text('months'), findsOneWidget);
      });

      testWidgets('does not show custom-mode content', (tester) async {
        await pumpPicker(tester);

        expect(find.byType(WeeklyDayPicker), findsNothing);
        expect(find.byType(MonthlyPicker), findsNothing);
        expect(find.byType(MonthGrid), findsNothing);
      });
    });

    group('Every mode – frequency change', () {
      testWidgets('changing frequency fires onRecurrenceChanged',
          (tester) async {
        RecurrenceRule? received;
        await pumpPicker(
          tester,
          initialFrequency: Frequency.weekly,
          onRecurrenceChanged: (r) => received = r,
        );

        // Open frequency dropdown and select "months".
        await tester.tap(find.byType(DropdownButton<Frequency>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('months').last);
        await tester.pumpAndSettle();

        expect(received, isNotNull);
        expect(received!.frequency, Frequency.monthly);
        expect(received!.interval, 1);
      });

      testWidgets('switching to daily fires rule with daily frequency',
          (tester) async {
        RecurrenceRule? received;
        await pumpPicker(
          tester,
          onRecurrenceChanged: (r) => received = r,
        );

        await tester.tap(find.byType(DropdownButton<Frequency>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('days').last);
        await tester.pumpAndSettle();

        expect(received!.frequency, Frequency.daily);
      });
    });

    group('mode switching', () {
      testWidgets('switching to Custom mode shows custom content',
          (tester) async {
        RecurrenceRule? received;
        await pumpPicker(
          tester,
          initialFrequency: Frequency.weekly,
          onRecurrenceChanged: (r) => received = r,
        );

        // Open mode dropdown and select "Custom".
        await tester.tap(find.byType(DropdownButton<RecurrenceMode>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Custom').last);
        await tester.pumpAndSettle();

        // Custom weekly mode shows a WeeklyDayPicker.
        expect(find.byType(WeeklyDayPicker), findsOneWidget);

        // The rule should include byWeekDays.
        expect(received, isNotNull);
        expect(received!.frequency, Frequency.weekly);
        expect(received!.byWeekDays, isNotEmpty);
      });

      testWidgets('switching back to Every hides custom content',
          (tester) async {
        await pumpPicker(tester);

        // Switch to Custom.
        await tester.tap(find.byType(DropdownButton<RecurrenceMode>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Custom').last);
        await tester.pumpAndSettle();
        expect(find.byType(WeeklyDayPicker), findsOneWidget);

        // Switch back to Every.
        await tester.tap(find.byType(DropdownButton<RecurrenceMode>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Every').last);
        await tester.pumpAndSettle();
        expect(find.byType(WeeklyDayPicker), findsNothing);
      });
    });

    group('Custom mode – weekly', () {
      testWidgets('rule includes selected weekdays', (tester) async {
        RecurrenceRule? received;
        await pumpPicker(
          tester,
          initialFrequency: Frequency.weekly,
          onRecurrenceChanged: (r) => received = r,
        );

        // Switch to Custom.
        await tester.tap(find.byType(DropdownButton<RecurrenceMode>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Custom').last);
        await tester.pumpAndSettle();

        // Default selection is Monday (from _selectedWeekdays init).
        expect(
          received!.byWeekDays.map((e) => e.day),
          contains(DateTime.monday),
        );
      });
    });

    group('Custom mode – monthly', () {
      testWidgets('shows MonthlyPicker for monthly frequency', (tester) async {
        await pumpPicker(
          tester,
          initialFrequency: Frequency.monthly,
        );

        // Switch to Custom.
        await tester.tap(find.byType(DropdownButton<RecurrenceMode>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Custom').last);
        await tester.pumpAndSettle();

        expect(find.byType(MonthlyPicker), findsOneWidget);
      });
    });

    group('Custom mode – yearly', () {
      testWidgets('shows MonthGrid and MonthlyPicker for yearly',
          (tester) async {
        await pumpPicker(
          tester,
          initialFrequency: Frequency.yearly,
        );

        // Switch to Custom.
        await tester.tap(find.byType(DropdownButton<RecurrenceMode>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Custom').last);
        await tester.pumpAndSettle();

        expect(find.byType(MonthGrid), findsOneWidget);
        expect(find.byType(MonthlyPicker), findsOneWidget);
      });
    });

    group('end-of-month selector', () {
      testWidgets('appears for monthly with start date > 28',
          (tester) async {
        await pumpPicker(
          tester,
          initialFrequency: Frequency.monthly,
          startDate: DateTime(2025, 1, 31),
        );

        expect(find.byType(EndOfMonthSelector), findsOneWidget);
      });

      testWidgets('hidden for monthly with start date <= 28',
          (tester) async {
        await pumpPicker(
          tester,
          initialFrequency: Frequency.monthly,
          startDate: DateTime(2025, 1, 15),
        );

        expect(find.byType(EndOfMonthSelector), findsNothing);
      });

      testWidgets('hidden when showEndOfMonthSelector is false',
          (tester) async {
        await pumpPicker(
          tester,
          initialFrequency: Frequency.monthly,
          startDate: DateTime(2025, 1, 31),
          showEndOfMonthSelector: false,
        );

        expect(find.byType(EndOfMonthSelector), findsNothing);
      });

      testWidgets('hidden for daily/weekly frequencies', (tester) async {
        await pumpPicker(
          tester,
          initialFrequency: Frequency.weekly,
          startDate: DateTime(2025, 1, 31),
        );

        expect(find.byType(EndOfMonthSelector), findsNothing);
      });
    });

    group('startDate defaults', () {
      testWidgets('uses startDate weekday for custom weekly selection',
          (tester) async {
        // 2025-01-15 is a Wednesday.
        RecurrenceRule? received;
        await pumpPicker(
          tester,
          initialFrequency: Frequency.weekly,
          startDate: DateTime(2025, 1, 15),
          onRecurrenceChanged: (r) => received = r,
        );

        // Switch to Custom.
        await tester.tap(find.byType(DropdownButton<RecurrenceMode>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Custom').last);
        await tester.pumpAndSettle();

        expect(
          received!.byWeekDays.map((e) => e.day),
          contains(DateTime.wednesday),
        );
      });
    });
  });
}
