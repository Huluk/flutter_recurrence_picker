import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recurrence_picker/recurrence_picker.dart';
import 'package:recurrence_picker/src/month_grid.dart';
import 'package:recurrence_picker/src/number_stepper.dart';
import 'package:rrule/rrule.dart';

Future<void> pumpPicker(
  WidgetTester tester, {
  Frequency initialFrequency = Frequency.weekly,
  int initialInterval = 1,
  DateTime? startDate,
  EndOfMonthBehavior defaultEndOfMonthBehavior = EndOfMonthBehavior.previousDay,
  bool showEndOfMonthSelector = true,
  SpecificDaysMode specificDaysMode = SpecificDaysMode.toggle,
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
            specificDaysMode: specificDaysMode,
            onRecurrenceChanged: onRecurrenceChanged ?? (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapCustomToggle(WidgetTester tester) async {
  await tester.tap(find.byType(Switch));
  await tester.pumpAndSettle();
}

Future<void> selectFrequency(WidgetTester tester, String label) async {
  await tester.tap(find.byType(DropdownButton<Frequency>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  group('RecurrencePicker', () {
    group('initial render', () {
      testWidgets(
          'shows interval stepper, frequency dropdown, and custom toggle',
          (tester) async {
        await pumpPicker(tester);

        expect(find.byType(NumberStepper), findsOneWidget);
        expect(find.byType(DropdownButton<Frequency>), findsOneWidget);
        expect(find.byType(Switch), findsOneWidget);
        expect(find.text('on specific days'), findsOneWidget);
      });

      testWidgets('custom toggle is off by default', (tester) async {
        await pumpPicker(tester);

        expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
      });

      testWidgets('displays initial frequency label', (tester) async {
        await pumpPicker(tester, initialFrequency: Frequency.monthly);
        expect(find.text('months'), findsOneWidget);
      });

      testWidgets('does not show custom-mode content', (tester) async {
        await pumpPicker(tester);

        expect(find.byType(WeekDayPicker), findsNothing);
        expect(find.byType(MonthlyPicker), findsNothing);
        expect(find.byType(MonthGrid), findsNothing);
      });

      testWidgets('custom toggle is disabled when frequency is daily',
          (tester) async {
        await pumpPicker(tester, initialFrequency: Frequency.daily);

        expect(
          tester.widget<Switch>(find.byType(Switch)).onChanged,
          isNull,
        );
      });
    });

    group('frequency change', () {
      testWidgets('changing frequency fires onRecurrenceChanged',
          (tester) async {
        RecurrenceRule? received;
        await pumpPicker(
          tester,
          onRecurrenceChanged: (r) => received = r,
        );

        await selectFrequency(tester, 'months');

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

        await selectFrequency(tester, 'days');

        expect(received!.frequency, Frequency.daily);
      });

      testWidgets('switching to daily while custom is on resets the toggle',
          (tester) async {
        await pumpPicker(tester);

        await tapCustomToggle(tester);
        expect(find.byType(WeekDayPicker), findsOneWidget);

        await selectFrequency(tester, 'days');

        expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
        expect(find.byType(WeekDayPicker), findsNothing);
      });
    });

    group('custom toggle', () {
      testWidgets('toggling on shows custom content', (tester) async {
        await pumpPicker(tester, initialFrequency: Frequency.weekly);

        await tapCustomToggle(tester);

        expect(find.byType(WeekDayPicker), findsOneWidget);
      });

      testWidgets('toggling off hides custom content', (tester) async {
        await pumpPicker(tester);

        await tapCustomToggle(tester);
        expect(find.byType(WeekDayPicker), findsOneWidget);

        await tapCustomToggle(tester);
        expect(find.byType(WeekDayPicker), findsNothing);
      });
    });

    group('custom mode content', () {
      testWidgets('shows MonthlyPicker for monthly frequency', (tester) async {
        await pumpPicker(tester, initialFrequency: Frequency.monthly);

        await tapCustomToggle(tester);

        expect(find.byType(MonthlyPicker), findsOneWidget);
      });

      testWidgets('shows MonthGrid and MonthlyPicker for yearly',
          (tester) async {
        await pumpPicker(tester, initialFrequency: Frequency.yearly);

        await tapCustomToggle(tester);

        expect(find.byType(MonthGrid), findsOneWidget);
        expect(find.byType(MonthlyPicker), findsOneWidget);
      });
    });

    group('end-of-month selector', () {
      testWidgets('appears for monthly with start date > 28', (tester) async {
        await pumpPicker(
          tester,
          initialFrequency: Frequency.monthly,
          startDate: DateTime(2025, 1, 31),
        );

        expect(find.byType(EndOfMonthSelector), findsOneWidget);
      });

      testWidgets('hidden for monthly with start date <= 28', (tester) async {
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

    group('specificDaysMode', () {
      testWidgets('toggleable (default) shows the switch', (tester) async {
        await pumpPicker(tester);

        expect(find.byType(Switch), findsOneWidget);
      });

      testWidgets('disabled hides the switch and custom content',
          (tester) async {
        await pumpPicker(
          tester,
          initialFrequency: Frequency.weekly,
          specificDaysMode: SpecificDaysMode.disabled,
        );

        expect(find.byType(Switch), findsNothing);
        expect(find.byType(WeekDayPicker), findsNothing);
      });

      testWidgets('disabled keeps custom UI hidden across frequency changes',
          (tester) async {
        await pumpPicker(
          tester,
          initialFrequency: Frequency.weekly,
          specificDaysMode: SpecificDaysMode.disabled,
        );

        await selectFrequency(tester, 'months');

        expect(find.byType(Switch), findsNothing);
        expect(find.byType(MonthlyPicker), findsNothing);
      });

      testWidgets('alwaysOn hides the switch and shows custom content',
          (tester) async {
        await pumpPicker(
          tester,
          initialFrequency: Frequency.weekly,
          specificDaysMode: SpecificDaysMode.alwaysOn,
        );

        expect(find.byType(Switch), findsNothing);
        expect(find.byType(WeekDayPicker), findsOneWidget);
      });

      testWidgets('alwaysOn keeps custom UI visible after switching to weekly',
          (tester) async {
        await pumpPicker(
          tester,
          initialFrequency: Frequency.monthly,
          specificDaysMode: SpecificDaysMode.alwaysOn,
        );

        await selectFrequency(tester, 'weeks');

        expect(find.byType(Switch), findsNothing);
        expect(find.byType(WeekDayPicker), findsOneWidget);
      });

      testWidgets('alwaysOn falls back to every mode for daily',
          (tester) async {
        await pumpPicker(
          tester,
          initialFrequency: Frequency.daily,
          specificDaysMode: SpecificDaysMode.alwaysOn,
        );

        expect(find.byType(Switch), findsNothing);
        expect(find.byType(WeekDayPicker), findsNothing);
        expect(find.byType(MonthlyPicker), findsNothing);
      });

      testWidgets('alwaysOn re-enables custom content after leaving daily',
          (tester) async {
        await pumpPicker(
          tester,
          initialFrequency: Frequency.daily,
          specificDaysMode: SpecificDaysMode.alwaysOn,
        );
        expect(find.byType(WeekDayPicker), findsNothing);

        await selectFrequency(tester, 'weeks');

        expect(find.byType(WeekDayPicker), findsOneWidget);
      });
    });
  });
}
