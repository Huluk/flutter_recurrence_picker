import 'package:flutter_test/flutter_test.dart';
import 'package:recurrence_picker/recurrence_picker.dart';
import 'package:rrule/rrule.dart';

void main() {
  group('RecurrenceRuleClamping.clamp', () {
    group('monthly', () {
      test('adjusts day 29 with previousDay behavior', () {
        final rule = RecurrenceRule(frequency: Frequency.monthly, interval: 1);
        final adjusted = rule.clamp(startDate: DateTime(2025, 1, 29));

        expect(adjusted.byMonthDays, [28, 29]);
        expect(adjusted.bySetPositions, [-1]);
        expect(adjusted.frequency, Frequency.monthly);
        expect(adjusted.interval, 1);
      });

      test('adjusts day 30 with previousDay behavior', () {
        final rule = RecurrenceRule(frequency: Frequency.monthly, interval: 2);
        final adjusted = rule.clamp(startDate: DateTime(2025, 4, 30));

        expect(adjusted.byMonthDays, [28, 29, 30]);
        expect(adjusted.bySetPositions, [-1]);
        expect(adjusted.interval, 2);
      });

      test('adjusts day 31 with BYMONTHDAY=-1', () {
        final rule = RecurrenceRule(frequency: Frequency.monthly, interval: 1);
        final adjusted = rule.clamp(startDate: DateTime(2025, 1, 31));

        expect(adjusted.byMonthDays, [-1]);
        expect(adjusted.bySetPositions, isEmpty);
      });

      test('does not adjust day <= 28', () {
        final rule = RecurrenceRule(frequency: Frequency.monthly, interval: 1);
        final adjusted = rule.clamp(startDate: DateTime(2025, 1, 28));

        expect(adjusted.byMonthDays, isEmpty);
        expect(adjusted.bySetPositions, isEmpty);
        expect(identical(adjusted, rule), isTrue);
      });

      test('does not adjust daily frequency', () {
        final rule = RecurrenceRule(frequency: Frequency.daily, interval: 1);
        final adjusted = rule.clamp(startDate: DateTime(2025, 1, 31));

        expect(identical(adjusted, rule), isTrue);
      });

      test('does not adjust weekly frequency', () {
        final rule = RecurrenceRule(frequency: Frequency.weekly, interval: 1);
        final adjusted = rule.clamp(startDate: DateTime(2025, 1, 31));

        expect(identical(adjusted, rule), isTrue);
      });

      test('passes through already-adjusted rules', () {
        final rule = RecurrenceRule(
          frequency: Frequency.monthly,
          interval: 1,
          byMonthDays: const [28, 29, 30, 31],
          bySetPositions: const [-1],
        );
        final adjusted = rule.clamp(startDate: DateTime(2025, 1, 31));

        expect(identical(adjusted, rule), isTrue);
      });

      test('passes through BYMONTHDAY=-1 rules', () {
        final rule = RecurrenceRule(
          frequency: Frequency.monthly,
          interval: 1,
          byMonthDays: const [-1],
        );
        final adjusted = rule.clamp(startDate: DateTime(2025, 1, 31));

        expect(identical(adjusted, rule), isTrue);
      });
    });

    group('yearly', () {
      test('adjusts Feb 29 with previousDay behavior', () {
        final rule = RecurrenceRule(frequency: Frequency.yearly, interval: 1);
        final adjusted = rule.clamp(startDate: DateTime(2024, 2, 29));

        expect(adjusted.byMonths, [2]);
        expect(adjusted.byMonthDays, [-1]);
      });

      test('does not adjust non-Feb-29 yearly rules', () {
        final rule = RecurrenceRule(frequency: Frequency.yearly, interval: 1);
        final adjusted = rule.clamp(startDate: DateTime(2025, 3, 15));

        expect(identical(adjusted, rule), isTrue);
      });

      test('does not adjust yearly on Feb 28', () {
        final rule = RecurrenceRule(frequency: Frequency.yearly, interval: 1);
        final adjusted = rule.clamp(startDate: DateTime(2025, 2, 28));

        expect(identical(adjusted, rule), isTrue);
      });
    });

    group('with pre-set byMonthDays', () {
      test('adjusts monthly day 30 from byMonthDays', () {
        final rule = RecurrenceRule(
          frequency: Frequency.monthly,
          byMonthDays: [30],
        );
        final adjusted = rule.clamp(startDate: DateTime(2000));

        expect(adjusted.byMonthDays, [28, 29, 30]);
        expect(adjusted.bySetPositions, [-1]);
      });

      test('adjusts monthly day 31 from byMonthDays to -1', () {
        final rule = RecurrenceRule(
          frequency: Frequency.monthly,
          byMonthDays: [31],
        );
        final adjusted = rule.clamp(startDate: DateTime(2000));

        expect(adjusted.byMonthDays, [-1]);
        expect(adjusted.bySetPositions, isEmpty);
      });

      test('does not adjust monthly day 15 from byMonthDays', () {
        final rule = RecurrenceRule(
          frequency: Frequency.monthly,
          byMonthDays: [15],
        );
        final adjusted = rule.clamp(startDate: DateTime(2000));

        expect(identical(adjusted, rule), isTrue);
      });

      test('adjusts yearly Feb 29', () {
        final rule = RecurrenceRule(
          frequency: Frequency.yearly,
          byMonths: [2],
          byMonthDays: [29],
        );
        final adjusted = rule.clamp(startDate: DateTime(2000));

        expect(adjusted.byMonths, [2]);
        expect(adjusted.byMonthDays, [-1]);
        expect(adjusted.bySetPositions, isEmpty);
      });

      test('adjusts yearly day 31 in April from byMonths', () {
        final rule = RecurrenceRule(
          frequency: Frequency.yearly,
          byMonths: [4],
          byMonthDays: [31],
        );
        final adjusted = rule.clamp(startDate: DateTime(2000));

        expect(adjusted.byMonthDays.singleOrNull, isIn({31, -1}));
        expect(adjusted.bySetPositions, isEmpty);
      });
    });
  });

  group('RecurrenceRuleClamping.hasEndOfMonthClamping', () {
    test('detects monthly day-31 clamping', () {
      final rule = RecurrenceRule(
        frequency: Frequency.monthly,
        byMonthDays: const [28, 29, 30, 31],
        bySetPositions: const [-1],
      );
      expect(rule.hasEndOfMonthClamping, isTrue);
    });

    test('detects monthly day-29 clamping', () {
      final rule = RecurrenceRule(
        frequency: Frequency.monthly,
        byMonthDays: const [28, 29],
        bySetPositions: const [-1],
      );
      expect(rule.hasEndOfMonthClamping, isTrue);
    });

    test('rejects wrong bySetPositions', () {
      final rule = RecurrenceRule(
        frequency: Frequency.monthly,
        byMonthDays: const [28, 29, 30, 31],
        bySetPositions: const [1],
      );
      expect(rule.hasEndOfMonthClamping, isFalse);
    });

    test('rejects missing bySetPositions', () {
      final rule = RecurrenceRule(
        frequency: Frequency.monthly,
        byMonthDays: const [28, 29, 30, 31],
      );
      expect(rule.hasEndOfMonthClamping, isFalse);
    });

    test('rejects simple byMonthDays', () {
      final rule = RecurrenceRule(
        frequency: Frequency.monthly,
        byMonthDays: const [15],
      );
      expect(rule.hasEndOfMonthClamping, isFalse);
    });

    test('rejects rule with no by-parts', () {
      final rule = RecurrenceRule(frequency: Frequency.monthly);
      expect(rule.hasEndOfMonthClamping, isFalse);
    });

    test('does not match BYMONTHDAY=-1 (clean encoding)', () {
      final rule = RecurrenceRule(
        frequency: Frequency.monthly,
        byMonthDays: const [-1],
      );
      expect(rule.hasEndOfMonthClamping, isFalse);
    });
  });
}
