import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recurrence_picker/recurrence_picker.dart';
import 'package:recurrence_picker/src/locale_utils.dart';

/// Pumps a [NthWeekdaySelector] inside a [MaterialApp] with all required
/// localizations.
Future<void> pumpSelector(
  WidgetTester tester, {
  Ordinal ordinal = Ordinal.first,
  ValueChanged<Ordinal>? onOrdinalChanged,
  WeekdayChoice selectedWeekday = WeekdayChoice.monday,
  ValueChanged<WeekdayChoice>? onWeekdayChanged,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: RecurrenceLocalizations.localizationsDelegates,
      supportedLocales: RecurrenceLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: NthWeekdaySelector(
          ordinal: ordinal,
          onOrdinalChanged: onOrdinalChanged ?? (_) {},
          selected: selectedWeekday,
          onWeekdayChanged: onWeekdayChanged ?? (_) {},
        ),
      ),
    ),
  );
  // Allow async localizations to resolve.
  await tester.pumpAndSettle();
}

void main() {
  group('NthWeekdaySelector', () {
    group('renders', () {
      testWidgets('both dropdowns', (tester) async {
        await pumpSelector(tester);

        // Two DropdownButtons: one for ordinal, one for weekday.
        final dropdowns = find.byType(DropdownButton<Ordinal>);
        expect(dropdowns, findsOneWidget);
        final weekdayDropdown = find.byType(DropdownButton<WeekdayChoice>);
        expect(weekdayDropdown, findsOneWidget);
      });

      testWidgets('selected ordinal label', (tester) async {
        await pumpSelector(tester, ordinal: Ordinal.third);
        expect(find.text('3rd'), findsOneWidget);
      });

      testWidgets('selected weekday label', (tester) async {
        await pumpSelector(tester, selectedWeekday: WeekdayChoice.wednesday);
        // Short weekday name for Wednesday (en locale).
        expect(find.text('Wed'), findsOneWidget);
      });

      testWidgets('selected special weekday label', (tester) async {
        await pumpSelector(tester, selectedWeekday: WeekdayChoice.anyDay);
        expect(find.text('Day'), findsOneWidget);
      });

      testWidgets('selected work day label', (tester) async {
        await pumpSelector(tester, selectedWeekday: WeekdayChoice.workDay);
        expect(find.text('Work day'), findsOneWidget);
      });

      testWidgets('selected weekend day label', (tester) async {
        await pumpSelector(tester, selectedWeekday: WeekdayChoice.weekendDay);
        expect(find.text('Weekend day'), findsOneWidget);
      });
    });

    group('ordinal dropdown', () {
      testWidgets('shows all ordinal options', (tester) async {
        await pumpSelector(tester, ordinal: Ordinal.first);

        // Open the ordinal dropdown.
        await tester.tap(find.byType(DropdownButton<Ordinal>));
        await tester.pumpAndSettle();

        // All six ordinals should appear in the menu.
        // The selected value appears twice (button + menu item),
        // so use findsWidgets for '1st'.
        expect(find.text('1st'), findsWidgets);
        expect(find.text('2nd'), findsOneWidget);
        expect(find.text('3rd'), findsOneWidget);
        expect(find.text('4th'), findsOneWidget);
        expect(find.text('2nd to last'), findsOneWidget);
        expect(find.text('Last'), findsOneWidget);
      });

      testWidgets('calls onOrdinalChanged when selecting an ordinal',
          (tester) async {
        Ordinal? received;
        await pumpSelector(
          tester,
          ordinal: Ordinal.first,
          onOrdinalChanged: (v) => received = v,
        );

        // Open dropdown.
        await tester.tap(find.byType(DropdownButton<Ordinal>));
        await tester.pumpAndSettle();

        // Select "Last".
        await tester.tap(find.text('Last').last);
        await tester.pumpAndSettle();

        expect(received, Ordinal.last);
      });

      testWidgets('calls onOrdinalChanged with secondToLast', (tester) async {
        Ordinal? received;
        await pumpSelector(
          tester,
          ordinal: Ordinal.first,
          onOrdinalChanged: (v) => received = v,
        );

        await tester.tap(find.byType(DropdownButton<Ordinal>));
        await tester.pumpAndSettle();

        await tester.tap(find.text('2nd to last').last);
        await tester.pumpAndSettle();

        expect(received, Ordinal.secondToLast);
      });
    });

    group('weekday dropdown', () {
      testWidgets('shows standard weekdays', (tester) async {
        await pumpSelector(tester);

        // Open the weekday dropdown.
        await tester.tap(find.byType(DropdownButton<WeekdayChoice>));
        await tester.pumpAndSettle();

        // All 7 short weekday names should be present.
        for (final name in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']) {
          expect(find.text(name), findsWidgets);
        }
      });

      testWidgets('shows special weekday categories', (tester) async {
        await pumpSelector(tester);

        await tester.tap(find.byType(DropdownButton<WeekdayChoice>));
        await tester.pumpAndSettle();

        expect(find.text('Day'), findsOneWidget);
        expect(find.text('Work day'), findsOneWidget);
        expect(find.text('Weekend day'), findsOneWidget);
      });

      testWidgets('calls onWeekdayChanged when selecting a weekday',
          (tester) async {
        WeekdayChoice? received;
        await pumpSelector(
          tester,
          selectedWeekday: WeekdayChoice.monday,
          onWeekdayChanged: (v) => received = v,
        );

        await tester.tap(find.byType(DropdownButton<WeekdayChoice>));
        await tester.pumpAndSettle();

        // Select Friday.
        await tester.tap(find.text('Fri').last);
        await tester.pumpAndSettle();

        expect(received, WeekdayChoice.friday);
      });

      testWidgets('calls onWeekdayChanged with special category',
          (tester) async {
        WeekdayChoice? received;
        await pumpSelector(
          tester,
          selectedWeekday: WeekdayChoice.monday,
          onWeekdayChanged: (v) => received = v,
        );

        await tester.tap(find.byType(DropdownButton<WeekdayChoice>));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Work day').last);
        await tester.pumpAndSettle();

        expect(received, WeekdayChoice.workDay);
      });
    });

    group('Ordinal enum', () {
      test('fromValue returns correct ordinal for each value', () {
        expect(Ordinal.fromValue(1), Ordinal.first);
        expect(Ordinal.fromValue(2), Ordinal.second);
        expect(Ordinal.fromValue(3), Ordinal.third);
        expect(Ordinal.fromValue(4), Ordinal.fourth);
        expect(Ordinal.fromValue(-2), Ordinal.secondToLast);
        expect(Ordinal.fromValue(-1), Ordinal.last);
      });

      test('fromValue throws for invalid value', () {
        expect(() => Ordinal.fromValue(0), throwsStateError);
        expect(() => Ordinal.fromValue(5), throwsStateError);
        expect(() => Ordinal.fromValue(-3), throwsStateError);
      });

      test('all ordinals have distinct values', () {
        final values = Ordinal.values.map((o) => o.value).toSet();
        expect(values.length, Ordinal.values.length);
      });
    });
  });
}
