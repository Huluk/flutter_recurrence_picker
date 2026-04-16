import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recurrence_picker/recurrence_picker.dart';
import 'package:recurrence_picker/src/month_grid.dart';

Future<void> pumpGrid(
  WidgetTester tester, {
  Set<int> selectedMonths = const {1},
  ValueChanged<Set<int>>? onChanged,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: RecurrenceLocalizations.localizationsDelegates,
      supportedLocales: RecurrenceLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: MonthGrid(
          selectedMonths: selectedMonths,
          onChanged: onChanged ?? (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('MonthGrid', () {
    group('renders', () {
      testWidgets('all 12 month abbreviations', (tester) async {
        await pumpGrid(tester);

        for (final name in [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
        ]) {
          expect(find.text(name), findsOneWidget, reason: '$name not found');
        }
      });

      testWidgets('12 tappable InkWell cells', (tester) async {
        await pumpGrid(tester);
        expect(find.byType(InkWell), findsNWidgets(12));
      });
    });

    group('selection', () {
      testWidgets('highlights selected months with primaryContainer',
          (tester) async {
        await pumpGrid(tester, selectedMonths: {3, 7});

        final theme = Theme.of(tester.element(find.byType(MonthGrid)));
        final highlighted = tester
            .widgetList<Material>(find.byType(Material))
            .where((m) => m.color == theme.colorScheme.primaryContainer);

        expect(highlighted, hasLength(2));
      });
    });

    group('toggle', () {
      testWidgets('tapping unselected month adds it to the set',
          (tester) async {
        Set<int>? received;
        await pumpGrid(
          tester,
          selectedMonths: {1},
          onChanged: (v) => received = v,
        );

        await tester.tap(find.text('Feb'));
        expect(received, unorderedEquals({1, 2}));
      });

      testWidgets('tapping selected month removes it when multiple selected',
          (tester) async {
        Set<int>? received;
        await pumpGrid(
          tester,
          selectedMonths: {1, 6},
          onChanged: (v) => received = v,
        );

        await tester.tap(find.text('Jan'));
        expect(received, unorderedEquals({6}));
      });

      testWidgets('cannot deselect the only remaining month',
          (tester) async {
        Set<int>? received;
        await pumpGrid(
          tester,
          selectedMonths: {4},
          onChanged: (v) => received = v,
        );

        await tester.tap(find.text('Apr'));
        // Callback fires, but set is unchanged.
        expect(received, unorderedEquals({4}));
      });

      testWidgets('can select multiple months in sequence', (tester) async {
        final received = <Set<int>>[];
        await pumpGrid(
          tester,
          selectedMonths: {1},
          onChanged: received.add,
        );

        await tester.tap(find.text('Mar'));
        await tester.tap(find.text('Dec'));

        expect(received, hasLength(2));
        expect(received[0], unorderedEquals({1, 3}));
        // Note: the widget is stateless; each tap sees the original
        // selectedMonths {1} since we don't rebuild.
        expect(received[1], unorderedEquals({1, 12}));
      });
    });
  });
}
