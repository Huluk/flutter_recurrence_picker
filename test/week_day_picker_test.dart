import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recurrence_picker/recurrence_picker.dart';

Future<void> pumpPicker(
  WidgetTester tester, {
  Set<int> selected = const {DateTime.monday},
  ValueChanged<Set<int>>? onChanged,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: RecurrenceLocalizations.localizationsDelegates,
      supportedLocales: RecurrenceLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: WeekDayPicker(
          selected: selected,
          onChanged: onChanged ?? (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('WeeklyDayPicker', () {
    group('render', () {
      testWidgets('seven FilterChips', (tester) async {
        await pumpPicker(tester);
        expect(find.byType(FilterChip), findsNWidgets(7));
      });

      testWidgets('short weekday names', (tester) async {
        await pumpPicker(tester);

        for (final name in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']) {
          expect(find.text(name), findsOneWidget, reason: '$name not found');
        }
      });

      testWidgets('marks selected chips', (tester) async {
        await pumpPicker(
          tester,
          selected: {DateTime.wednesday, DateTime.friday},
        );

        final chips = tester.widgetList<FilterChip>(
          find.byType(FilterChip),
        );
        final selectedLabels = chips
            .where((c) => c.selected)
            .map((c) => (c.key as ValueKey<String>).value)
            .toList();

        expect(selectedLabels, unorderedEquals(['wday-3', 'wday-5']));
      });
    });

    group('interaction', () {
      testWidgets('tapping an unselected chip adds it', (tester) async {
        Set<int>? received;
        await pumpPicker(
          tester,
          selected: {DateTime.monday},
          onChanged: (v) => received = v,
        );

        await tester.tap(find.text('Fri'));
        expect(received, unorderedEquals({DateTime.monday, DateTime.friday}));
      });

      testWidgets('tapping a selected chip removes it', (tester) async {
        Set<int>? received;
        await pumpPicker(
          tester,
          selected: {DateTime.monday, DateTime.thursday},
          onChanged: (v) => received = v,
        );

        await tester.tap(find.text('Mon'));
        expect(received, unorderedEquals({DateTime.thursday}));
      });

      testWidgets('can deselect all chips', (tester) async {
        Set<int>? received;
        await pumpPicker(
          tester,
          selected: {DateTime.sunday},
          onChanged: (v) => received = v,
        );

        await tester.tap(find.text('Sun'));
        expect(received, isEmpty);
      });
    });
  });
}
