import 'package:flutter_test/flutter_test.dart';
import 'package:recurrence_picker/recurrence_picker.dart';
import 'package:recurrence_picker/src/l10n/recurrence_localizations_de.dart';
import 'package:recurrence_picker/src/l10n/recurrence_localizations_en.dart';
import 'package:rrule/rrule.dart';

void main() {
  late RruleL10nEn l10n;
  late RecurrenceLocalizationsEn loc;

  setUpAll(() async {
    l10n = await RruleL10nEn.create();
    loc = RecurrenceLocalizationsEn();
  });

  group('RecurrenceRuleDescription.describe', () {
    group('simple rules', () {
      test('daily', () {
        final rule = RecurrenceRule(frequency: Frequency.daily);
        expect(
          rule.describe(l10n: l10n, loc: loc),
          'Daily',
        );
      });

      test('every other day', () {
        final rule = RecurrenceRule(frequency: Frequency.daily, interval: 2);
        expect(
          rule.describe(l10n: l10n, loc: loc),
          'Every other day',
        );
      });

      test('every 3 days', () {
        final rule = RecurrenceRule(frequency: Frequency.daily, interval: 3);
        expect(
          rule.describe(l10n: l10n, loc: loc),
          'Every 3 days',
        );
      });

      test('weekly', () {
        final rule = RecurrenceRule(frequency: Frequency.weekly);
        expect(
          rule.describe(l10n: l10n, loc: loc),
          'Weekly',
        );
      });

      test('every other week', () {
        final rule = RecurrenceRule(frequency: Frequency.weekly, interval: 2);
        expect(
          rule.describe(l10n: l10n, loc: loc),
          'Every other week',
        );
      });

      test('monthly', () {
        final rule = RecurrenceRule(frequency: Frequency.monthly);
        expect(
          rule.describe(l10n: l10n, loc: loc, startDate: DateTime(2026, 4, 15)),
          'Monthly',
        );
      });

      test('every 3 months', () {
        final rule = RecurrenceRule(frequency: Frequency.monthly, interval: 3);
        expect(
          rule.describe(l10n: l10n, loc: loc, startDate: DateTime(2026, 4, 15)),
          'Every 3 months',
        );
      });

      test('yearly', () {
        final rule = RecurrenceRule(frequency: Frequency.yearly);
        expect(
          rule.describe(l10n: l10n, loc: loc, startDate: DateTime(2026, 4, 15)),
          'Annually',
        );
      });

      test('every 2 years', () {
        final rule = RecurrenceRule(frequency: Frequency.yearly, interval: 2);
        expect(
          rule.describe(l10n: l10n, loc: loc, startDate: DateTime(2026, 4, 15)),
          'Every other year',
        );
      });
    });

    group('weekly with byWeekDays', () {
      test('single weekday', () {
        final rule = RecurrenceRule(
          frequency: Frequency.weekly,
          byWeekDays: [ByWeekDayEntry(DateTime.monday)],
        );
        expect(
          rule.describe(l10n: l10n, loc: loc),
          contains('Monday'),
        );
      });

      test('multiple weekdays', () {
        final rule = RecurrenceRule(
          frequency: Frequency.weekly,
          byWeekDays: [
            ByWeekDayEntry(DateTime.monday),
            ByWeekDayEntry(DateTime.wednesday),
            ByWeekDayEntry(DateTime.friday),
          ],
        );
        final text = rule.describe(l10n: l10n, loc: loc);
        expect(text, contains('Monday'));
        expect(text, contains('Wednesday'));
        expect(text, contains('Friday'));
      });
    });

    group('monthly with byMonthDays', () {
      test('specific day', () {
        final rule = RecurrenceRule(
          frequency: Frequency.monthly,
          byMonthDays: [15],
        );
        final text = rule.describe(l10n: l10n, loc: loc);
        expect(text, contains('15th'));
      });

      test('day 1', () {
        final rule = RecurrenceRule(
          frequency: Frequency.monthly,
          byMonthDays: [1],
        );
        final text = rule.describe(l10n: l10n, loc: loc);
        expect(text, contains('1st'));
      });
    });

    group('monthly with nth weekday', () {
      test('2nd Monday', () {
        final rule = RecurrenceRule(
          frequency: Frequency.monthly,
          byWeekDays: [
            ByWeekDayEntry(DateTime.monday, 2),
          ],
        );
        final text = rule.describe(l10n: l10n, loc: loc);
        expect(text, contains('2nd'));
        expect(text, contains('Monday'));
      });

      test('last Friday', () {
        final rule = RecurrenceRule(
          frequency: Frequency.monthly,
          byWeekDays: [
            ByWeekDayEntry(DateTime.friday, -1),
          ],
        );
        final text = rule.describe(l10n: l10n, loc: loc);
        expect(text, contains('last'));
        expect(text, contains('Friday'));
      });
    });

    group('end-of-month clamping (previousDay)', () {
      test('basic mode appends asterisk for day-31', () {
        final rule = RecurrenceRule(
          frequency: Frequency.monthly,
          byMonthDays: [28, 29, 30, 31],
          bySetPositions: [-1],
        );
        final text = rule.describe(
          l10n: l10n,
          loc: loc,
          verbose: false,
        );
        expect(text, endsWith('*'));
        expect(text, contains('31st'));
      });

      test('basic mode appends asterisk for day-29', () {
        final rule = RecurrenceRule(
          frequency: Frequency.monthly,
          byMonthDays: [28, 29],
          bySetPositions: [-1],
        );
        final text = rule.describe(
          l10n: l10n,
          loc: loc,
          verbose: false,
        );
        expect(text, endsWith('*'));
        expect(text, contains('29th'));
      });

      test('verbose mode appends localized suffix for day-31', () {
        final rule = RecurrenceRule(
          frequency: Frequency.monthly,
          byMonthDays: [28, 29, 30, 31],
          bySetPositions: [-1],
        );
        final text = rule.describe(
          l10n: l10n,
          loc: loc,
          verbose: true,
        );
        expect(text, isNot(endsWith('*')));
        expect(text, contains('(or previous available day)'));
        expect(text, contains('31st'));
      });

      test('verbose mode uses German loc', () {
        final rule = RecurrenceRule(
          frequency: Frequency.monthly,
          byMonthDays: [28, 29, 30, 31],
          bySetPositions: [-1],
        );
        final deLoc = RecurrenceLocalizationsDe();
        final text = rule.describe(
          l10n: l10n,
          loc: deLoc,
          verbose: true,
        );
        expect(text, contains('(oder vorheriger verfügbarer Tag)'));
      });

      test('BYMONTHDAY=-1 has no asterisk (clean encoding)', () {
        final rule = RecurrenceRule(
          frequency: Frequency.monthly,
          byMonthDays: [-1],
        );
        final text = rule.describe(
          l10n: l10n,
          loc: loc,
          verbose: false,
        );
        expect(text, isNot(endsWith('*')));
        expect(text, isNot(contains('previous available')));
      });

      test('no asterisk for non-clamped rule', () {
        final rule = RecurrenceRule(
          frequency: Frequency.monthly,
          byMonthDays: [15],
        );
        final text = rule.describe(
          l10n: l10n,
          loc: loc,
          verbose: false,
        );
        expect(text, isNot(endsWith('*')));
      });

      test('no suffix for non-clamped verbose', () {
        final rule = RecurrenceRule(
          frequency: Frequency.monthly,
          byMonthDays: [15],
        );
        final text = rule.describe(
          l10n: l10n,
          loc: loc,
          verbose: true,
        );
        expect(text, isNot(contains('previous available')));
      });
    });

    group('end-of-month skip (inferred)', () {
      test('basic mode appends asterisk for bare day-31', () {
        final rule = RecurrenceRule(
          frequency: Frequency.monthly,
          byMonthDays: [31],
        );
        final text = rule.describe(l10n: l10n, loc: loc);
        expect(text, endsWith('*'));
      });

      test('basic mode appends asterisk for bare day-29', () {
        final rule = RecurrenceRule(
          frequency: Frequency.monthly,
          byMonthDays: [29],
        );
        final text = rule.describe(l10n: l10n, loc: loc);
        expect(text, endsWith('*'));
      });

      test('verbose mode appends skip suffix for bare day-31', () {
        final rule = RecurrenceRule(
          frequency: Frequency.monthly,
          byMonthDays: [31],
        );
        final text = rule.describe(l10n: l10n, loc: loc, verbose: true);
        expect(text, isNot(endsWith('*')));
        expect(text, contains('(skip when date does not exist)'));
      });

      test('verbose skip uses German loc', () {
        final rule = RecurrenceRule(
          frequency: Frequency.monthly,
          byMonthDays: [31],
        );
        final deLoc = RecurrenceLocalizationsDe();
        final text = rule.describe(l10n: l10n, loc: deLoc, verbose: true);
        expect(text, contains('(übersprungen wenn Datum nicht existiert)'));
      });

      test('no asterisk for day-15', () {
        final rule = RecurrenceRule(
          frequency: Frequency.monthly,
          byMonthDays: [15],
        );
        final text = rule.describe(l10n: l10n, loc: loc);
        expect(text, isNot(endsWith('*')));
      });

      test('no asterisk for day-28', () {
        final rule = RecurrenceRule(
          frequency: Frequency.monthly,
          byMonthDays: [28],
        );
        final text = rule.describe(l10n: l10n, loc: loc);
        expect(text, isNot(endsWith('*')));
      });
    });

    group('yearly', () {
      test('with byMonths', () {
        final rule = RecurrenceRule(
          frequency: Frequency.yearly,
          byMonths: [1, 6],
        );
        final text = rule.describe(l10n: l10n, loc: loc);
        expect(text, contains('January'));
        expect(text, contains('June'));
      });

      test('Feb 29 clamped basic', () {
        final rule = RecurrenceRule(
          frequency: Frequency.yearly,
          byMonths: [2],
          byMonthDays: [28, 29],
          bySetPositions: [-1],
        );
        final text = rule.describe(
          l10n: l10n,
          loc: loc,
          verbose: false,
        );
        expect(text, endsWith('*'));
        expect(text, contains('February'));
      });

      test('Feb 29 clamped verbose', () {
        final rule = RecurrenceRule(
          frequency: Frequency.yearly,
          byMonths: [2],
          byMonthDays: [28, 29],
          bySetPositions: [-1],
        );
        final text = rule.describe(
          l10n: l10n,
          loc: loc,
          verbose: true,
        );
        expect(text, contains('(or previous available day)'));
        expect(text, contains('February'));
      });

      test('Feb 29 bare day skip basic', () {
        final rule = RecurrenceRule(
          frequency: Frequency.yearly,
          byMonths: [2],
          byMonthDays: [29],
        );
        final text = rule.describe(l10n: l10n, loc: loc);
        expect(text, endsWith('*'));
      });

      test('Feb 29 bare day skip verbose', () {
        final rule = RecurrenceRule(
          frequency: Frequency.yearly,
          byMonths: [2],
          byMonthDays: [29],
        );
        final text = rule.describe(l10n: l10n, loc: loc, verbose: true);
        expect(text, contains('(skip when date does not exist)'));
      });

      test('Jan 31 has no asterisk (day exists)', () {
        final rule = RecurrenceRule(
          frequency: Frequency.yearly,
          byMonths: [1],
          byMonthDays: [31],
        );
        final text = rule.describe(l10n: l10n, loc: loc);
        // January always has 31 days.
        expect(text, isNot(endsWith('*')));
      });

      test('Mar 31 has no asterisk (day exists)', () {
        final rule = RecurrenceRule(
          frequency: Frequency.yearly,
          byMonths: [3],
          byMonthDays: [31],
        );
        final text = rule.describe(l10n: l10n, loc: loc);
        expect(text, isNot(endsWith('*')));
      });

      test('Apr 30 has no asterisk (day exists)', () {
        final rule = RecurrenceRule(
          frequency: Frequency.yearly,
          byMonths: [4],
          byMonthDays: [30],
        );
        final text = rule.describe(l10n: l10n, loc: loc);
        expect(text, isNot(endsWith('*')));
      });

      test('Jun+Nov 31 has asterisk (Nov has 30)', () {
        final rule = RecurrenceRule(
          frequency: Frequency.yearly,
          byMonths: [6, 11],
          byMonthDays: [31],
        );
        final text = rule.describe(l10n: l10n, loc: loc);
        // Neither June nor November has 31 days.
        expect(text, endsWith('*'));
      });

      test('day-31 without byMonths infers skip', () {
        final rule = RecurrenceRule(
          frequency: Frequency.yearly,
          byMonthDays: [31],
        );
        // No BYMONTH → conservatively assumes unsupported.
        expect(rule.describe(l10n: l10n, loc: loc), endsWith('*'));
      });

      test('day-31 without byMonths + startDate Jan → no asterisk', () {
        final rule = RecurrenceRule(
          frequency: Frequency.yearly,
          byMonthDays: [31],
        );
        final text = rule.describe(
          l10n: l10n,
          loc: loc,
          startDate: DateTime(2025, 1, 31),
        );
        // January always has 31 days.
        expect(text, isNot(endsWith('*')));
      });

      test('day-31 without byMonths + startDate Feb → asterisk', () {
        final rule = RecurrenceRule(
          frequency: Frequency.yearly,
          byMonthDays: [31],
        );
        final text = rule.describe(
          l10n: l10n,
          loc: loc,
          startDate: DateTime(2025, 2, 28),
        );
        // February never has 31 days.
        expect(text, endsWith('*'));
      });
    });

    group('simple rules have no asterisk', () {
      test('daily has no asterisk', () {
        final rule = RecurrenceRule(frequency: Frequency.daily);
        expect(
          rule.describe(l10n: l10n, loc: loc),
          isNot(contains('*')),
        );
      });

      test('weekly has no asterisk', () {
        final rule = RecurrenceRule(frequency: Frequency.weekly, interval: 2);
        expect(
          rule.describe(l10n: l10n, loc: loc),
          isNot(contains('*')),
        );
      });
    });
  });
}
