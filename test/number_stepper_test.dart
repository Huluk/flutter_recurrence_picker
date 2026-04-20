import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recurrence_picker/recurrence_picker.dart';
import 'package:recurrence_picker/src/number_stepper.dart';

Future<void> pumpStepper(
  WidgetTester tester, {
  int value = 1,
  int minValue = 1,
  int maxValue = 999,
  ValueChanged<int>? onChanged,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: RecurrenceLocalizations.localizationsDelegates,
      supportedLocales: RecurrenceLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: NumberStepper(
          value: value,
          minValue: minValue,
          maxValue: maxValue,
          onChanged: onChanged ?? (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('NumberStepper', () {
    group('renders', () {
      testWidgets('displays the current value in the text field',
          (tester) async {
        await pumpStepper(tester, value: 42);

        final field = tester.widget<TextFormField>(find.byType(TextFormField));
        expect(field.controller!.text, '42');
      });

      testWidgets('decrement and increment icons', (tester) async {
        await pumpStepper(tester);

        expect(find.byIcon(Icons.remove), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);
      });

      testWidgets('semantic labels for accessibility', (tester) async {
        await pumpStepper(tester);

        expect(
          find.bySemanticsLabel('Decrement recurrence interval'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('Increment recurrence interval'),
          findsOneWidget,
        );
      });
    });

    group('increment', () {
      testWidgets('calls onChanged with value + 1', (tester) async {
        int? received;
        await pumpStepper(
          tester,
          value: 5,
          onChanged: (v) => received = v,
        );

        await tester.tap(find.byIcon(Icons.add));
        expect(received, 6);
      });

      testWidgets('is disabled at maxValue', (tester) async {
        int? received;
        await pumpStepper(
          tester,
          value: 10,
          maxValue: 10,
          onChanged: (v) => received = v,
        );

        await tester.tap(find.byIcon(Icons.add));
        expect(received, isNull);
      });
    });

    group('decrement', () {
      testWidgets('calls onChanged with value - 1', (tester) async {
        int? received;
        await pumpStepper(
          tester,
          value: 5,
          onChanged: (v) => received = v,
        );

        await tester.tap(find.byIcon(Icons.remove));
        expect(received, 4);
      });

      testWidgets('is disabled at minValue', (tester) async {
        int? received;
        await pumpStepper(
          tester,
          value: 1,
          minValue: 1,
          onChanged: (v) => received = v,
        );

        await tester.tap(find.byIcon(Icons.remove));
        expect(received, isNull);
      });
    });

    group('text input', () {
      testWidgets('calls onChanged with parsed integer', (tester) async {
        int? received;
        await pumpStepper(
          tester,
          value: 1,
          onChanged: (v) => received = v,
        );

        await tester.enterText(find.byType(TextFormField), '7');
        expect(received, 7);
      });

      testWidgets('rejects value below minValue', (tester) async {
        int? received;
        await pumpStepper(
          tester,
          value: 5,
          minValue: 3,
          onChanged: (v) => received = v,
        );

        await tester.enterText(find.byType(TextFormField), '2');
        expect(received, isNull);
      });

      testWidgets('rejects value above maxValue', (tester) async {
        int? received;
        await pumpStepper(
          tester,
          value: 5,
          maxValue: 10,
          onChanged: (v) => received = v,
        );

        await tester.enterText(find.byType(TextFormField), '99');
        expect(received, isNull);
      });
    });

    testWidgets(
        'controller update during didUpdateWidget does not trigger '
        'setState during build when inside a Form', (tester) async {
      // Regression test: setting _controller.text in didUpdateWidget fires
      // TextEditingController notifications, which caused Form ancestors to
      // call setState() during the build phase.
      int value = 3;
      late StateSetter setState;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates:
              RecurrenceLocalizations.localizationsDelegates,
          supportedLocales: RecurrenceLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Form(
              child: StatefulBuilder(
                builder: (context, setStateFn) {
                  setState = setStateFn;
                  return NumberStepper(
                    value: value,
                    onChanged: (v) => setStateFn(() => value = v),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Changing value externally triggers didUpdateWidget which must not
      // synchronously set _controller.text (that would fire a change
      // notification during build, causing the Form to call setState()).
      setState(() => value = 8);
      await tester.pumpAndSettle();

      final field =
          tester.widget<TextFormField>(find.byType(TextFormField));
      expect(field.controller!.text, '8');
    });

    testWidgets('updates text field when value changes externally',
        (tester) async {
      int value = 3;
      late StateSetter setState;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates:
              RecurrenceLocalizations.localizationsDelegates,
          supportedLocales: RecurrenceLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setStateFn) {
                setState = setStateFn;
                return NumberStepper(
                  value: value,
                  onChanged: (v) => setStateFn(() => value = v),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final fieldBefore =
          tester.widget<TextFormField>(find.byType(TextFormField));
      expect(fieldBefore.controller!.text, '3');

      setState(() => value = 8);
      await tester.pumpAndSettle();

      final fieldAfter =
          tester.widget<TextFormField>(find.byType(TextFormField));
      expect(fieldAfter.controller!.text, '8');
    });
  });
}
