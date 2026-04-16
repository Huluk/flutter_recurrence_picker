import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recurrence_picker/recurrence_picker.dart';

Future<void> pumpSelector(
  WidgetTester tester, {
  EndOfMonthBehavior behavior = EndOfMonthBehavior.previousDay,
  ValueChanged<EndOfMonthBehavior>? onChanged,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: RecurrenceLocalizations.localizationsDelegates,
      supportedLocales: RecurrenceLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: EndOfMonthSelector(
          behavior: behavior,
          onChanged: onChanged ?? (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('EndOfMonthSelector', () {
    group('renders', () {
      testWidgets('hint text explaining end-of-month ambiguity',
          (tester) async {
        await pumpSelector(tester);

        expect(
          find.text("This day doesn't exist in every month."),
          findsOneWidget,
        );
      });

      testWidgets('info icon', (tester) async {
        await pumpSelector(tester);
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
      });

      testWidgets('both behavior segment labels', (tester) async {
        await pumpSelector(tester);

        expect(find.text('Or previous day'), findsOneWidget);
        expect(find.text('Skip'), findsOneWidget);
      });

      testWidgets('SegmentedButton with two segments', (tester) async {
        await pumpSelector(tester);

        expect(
          find.byType(SegmentedButton<EndOfMonthBehavior>),
          findsOneWidget,
        );
      });
    });

    group('interaction', () {
      testWidgets(
          'tapping Skip calls onChanged with EndOfMonthBehavior.skip',
          (tester) async {
        EndOfMonthBehavior? received;
        await pumpSelector(
          tester,
          behavior: EndOfMonthBehavior.previousDay,
          onChanged: (v) => received = v,
        );

        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();

        expect(received, EndOfMonthBehavior.skip);
      });

      testWidgets(
          'tapping Or previous day calls onChanged with previousDay',
          (tester) async {
        EndOfMonthBehavior? received;
        await pumpSelector(
          tester,
          behavior: EndOfMonthBehavior.skip,
          onChanged: (v) => received = v,
        );

        await tester.tap(find.text('Or previous day'));
        await tester.pumpAndSettle();

        expect(received, EndOfMonthBehavior.previousDay);
      });
    });
  });
}
