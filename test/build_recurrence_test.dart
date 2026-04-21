import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/date_symbols.dart';
import 'package:intl/intl.dart';
import 'package:recurrence_picker/recurrence_picker.dart';
import 'package:recurrence_picker/src/locale_utils.dart';
import 'package:rrule/rrule.dart';

void main() {
  late final DateSymbols symbols;

  setUpAll(() async {
    await initializeDateFormatting('en');
    symbols = DateFormat('', 'en').dateSymbols;
  });

  group('every mode', () {
    test('plain daily rule carries frequency and interval', () {
      final rule = const RecurrenceSelection(
        frequency: Frequency.daily,
        interval: 3,
      ).toRrule(dateSymbols: symbols);

      expect(rule.frequency, Frequency.daily);
      expect(rule.interval, 3);
      expect(rule.byMonthDays, isEmpty);
      expect(rule.byWeekDays, isEmpty);
    });

    test('monthly without startDate has no clamping', () {
      final rule = const RecurrenceSelection(
        frequency: Frequency.monthly,
      ).toRrule(dateSymbols: symbols);

      expect(rule.byMonthDays, isEmpty);
      expect(rule.bySetPositions, isEmpty);
    });

    test('monthly previousDay clamps day 31 to BYMONTHDAY=-1', () {
      final rule = const RecurrenceSelection(
        frequency: Frequency.monthly,
      ).toRrule(
        startDate: DateTime(2025, 1, 31),
        dateSymbols: symbols,
      );

      expect(rule.byMonthDays, [-1]);
      expect(rule.bySetPositions, isEmpty);
    });

    test('monthly previousDay clamps day 30 to range+BYSETPOS=-1', () {
      final rule = const RecurrenceSelection(
        frequency: Frequency.monthly,
      ).toRrule(
        startDate: DateTime(2025, 4, 30),
        dateSymbols: symbols,
      );

      expect(rule.byMonthDays, [28, 29, 30]);
      expect(rule.bySetPositions, [-1]);
    });

    test('monthly skip does not clamp day 31', () {
      final rule = const RecurrenceSelection(
        frequency: Frequency.monthly,
        endOfMonthBehavior: EndOfMonthBehavior.skip,
      ).toRrule(
        startDate: DateTime(2025, 1, 31),
        dateSymbols: symbols,
      );

      expect(rule.byMonthDays, isEmpty);
    });

    test('monthly day 15 is not clamped', () {
      final rule = const RecurrenceSelection(
        frequency: Frequency.monthly,
      ).toRrule(
        startDate: DateTime(2025, 1, 15),
        dateSymbols: symbols,
      );

      expect(rule.byMonthDays, isEmpty);
    });

    test('yearly Feb 29 previousDay clamps to last of February', () {
      final rule = const RecurrenceSelection(
        frequency: Frequency.yearly,
      ).toRrule(
        startDate: DateTime(2024, 2, 29),
        dateSymbols: symbols,
      );

      expect(rule.byMonths, [2]);
      expect(rule.byMonthDays, [-1]);
    });
  });

  group('custom weekly', () {
    test('single weekday emits one ByWeekDayEntry', () {
      final rule = const RecurrenceSelection(
        frequency: Frequency.weekly,
        mode: RecurrenceMode.custom,
        weekdays: {DateTime.tuesday},
      ).toRrule(dateSymbols: symbols);

      expect(rule.frequency, Frequency.weekly);
      expect(rule.byWeekDays, [ByWeekDayEntry(DateTime.tuesday)]);
    });

    test('multiple weekdays preserved', () {
      final rule = const RecurrenceSelection(
        frequency: Frequency.weekly,
        mode: RecurrenceMode.custom,
        weekdays: {DateTime.monday, DateTime.friday},
      ).toRrule(dateSymbols: symbols);

      expect(
        rule.byWeekDays,
        unorderedEquals([
          ByWeekDayEntry(DateTime.monday),
          ByWeekDayEntry(DateTime.friday),
        ]),
      );
    });

    test('single weekday matching startDate.weekday is stripped', () {
      // 2025-01-06 is a Monday.
      final rule = const RecurrenceSelection(
        frequency: Frequency.weekly,
        mode: RecurrenceMode.custom,
        weekdays: {DateTime.monday},
      ).toRrule(
        startDate: DateTime(2025, 1, 6),
        dateSymbols: symbols,
      );

      expect(rule.byWeekDays, isEmpty);
    });

    test('stripRedundantAttributes=false keeps byWeekDays', () {
      final rule = const RecurrenceSelection(
        frequency: Frequency.weekly,
        mode: RecurrenceMode.custom,
        weekdays: {DateTime.monday},
      ).toRrule(
        startDate: DateTime(2025, 1, 6),
        dateSymbols: symbols,
        stripRedundantAttributes: false,
      );

      expect(rule.byWeekDays, [ByWeekDayEntry(DateTime.monday)]);
    });

    test('multi-weekday selection is never stripped', () {
      final rule = const RecurrenceSelection(
        frequency: Frequency.weekly,
        mode: RecurrenceMode.custom,
        weekdays: {DateTime.monday, DateTime.tuesday},
      ).toRrule(
        startDate: DateTime(2025, 1, 6),
        dateSymbols: symbols,
      );

      expect(
        rule.byWeekDays,
        unorderedEquals([
          ByWeekDayEntry(DateTime.monday),
          ByWeekDayEntry(DateTime.tuesday),
        ]),
      );
    });
  });

  group('custom monthly (date mode)', () {
    test('emits byMonthDays and no byMonths', () {
      final rule = const RecurrenceSelection(
        frequency: Frequency.monthly,
        mode: RecurrenceMode.custom,
        monthly: MonthlySelection(monthDay: 15),
      ).toRrule(dateSymbols: symbols);

      expect(rule.byMonthDays, [15]);
      expect(rule.byMonths, isEmpty);
    });

    test('previousDay clamps monthDay 31', () {
      final rule = const RecurrenceSelection(
        frequency: Frequency.monthly,
        mode: RecurrenceMode.custom,
        monthly: MonthlySelection(monthDay: 31),
      ).toRrule(dateSymbols: symbols);

      expect(rule.byMonthDays, [-1]);
    });

    test('skip keeps monthDay 31 unclamped', () {
      final rule = const RecurrenceSelection(
        frequency: Frequency.monthly,
        mode: RecurrenceMode.custom,
        endOfMonthBehavior: EndOfMonthBehavior.skip,
        monthly: MonthlySelection(monthDay: 31),
      ).toRrule(dateSymbols: symbols);

      expect(rule.byMonthDays, [31]);
    });

    test('monthDay matching startDate.day is stripped', () {
      final rule = const RecurrenceSelection(
        frequency: Frequency.monthly,
        mode: RecurrenceMode.custom,
        monthly: MonthlySelection(monthDay: 15),
      ).toRrule(
        startDate: DateTime(2025, 3, 15),
        dateSymbols: symbols,
      );

      expect(rule.byMonthDays, isEmpty);
    });
  });

  group('custom monthly (nth weekday)', () {
    test('plain weekday emits BYDAY with ordinal, no BYSETPOS', () {
      final rule = const RecurrenceSelection(
        frequency: Frequency.monthly,
        mode: RecurrenceMode.custom,
        monthly: MonthlySelection(
          mode: MonthlyMode.weekday,
          ordinal: Ordinal.first,
          nthWeekday: WeekdayChoice.monday,
        ),
      ).toRrule(dateSymbols: symbols);

      expect(rule.byWeekDays, [ByWeekDayEntry(DateTime.monday, 1)]);
      expect(rule.bySetPositions, isEmpty);
    });

    test('last Friday encodes ordinal=-1 without BYSETPOS', () {
      final rule = const RecurrenceSelection(
        frequency: Frequency.monthly,
        mode: RecurrenceMode.custom,
        monthly: MonthlySelection(
          mode: MonthlyMode.weekday,
          ordinal: Ordinal.last,
          nthWeekday: WeekdayChoice.friday,
        ),
      ).toRrule(dateSymbols: symbols);

      expect(rule.byWeekDays, [ByWeekDayEntry(DateTime.friday, -1)]);
      expect(rule.bySetPositions, isEmpty);
    });

    test('1st work day expands to weekdays with BYSETPOS=1', () {
      final rule = const RecurrenceSelection(
        frequency: Frequency.monthly,
        mode: RecurrenceMode.custom,
        monthly: MonthlySelection(
          mode: MonthlyMode.weekday,
          ordinal: Ordinal.first,
          nthWeekday: WeekdayChoice.workDay,
        ),
      ).toRrule(dateSymbols: symbols);

      expect(
        rule.byWeekDays.map((e) => e.day).toSet(),
        {
          DateTime.monday,
          DateTime.tuesday,
          DateTime.wednesday,
          DateTime.thursday,
          DateTime.friday,
        },
      );
      expect(rule.bySetPositions, [1]);
    });

    test('last work day uses BYSETPOS=-1', () {
      final rule = const RecurrenceSelection(
        frequency: Frequency.monthly,
        mode: RecurrenceMode.custom,
        monthly: MonthlySelection(
          mode: MonthlyMode.weekday,
          ordinal: Ordinal.last,
          nthWeekday: WeekdayChoice.workDay,
        ),
      ).toRrule(dateSymbols: symbols);

      expect(rule.bySetPositions, [-1]);
    });

    test('any day includes all 7 weekdays', () {
      final rule = const RecurrenceSelection(
        frequency: Frequency.monthly,
        mode: RecurrenceMode.custom,
        monthly: MonthlySelection(
          mode: MonthlyMode.weekday,
          ordinal: Ordinal.first,
          nthWeekday: WeekdayChoice.anyDay,
        ),
      ).toRrule(dateSymbols: symbols);

      expect(
        rule.byWeekDays.map((e) => e.day).toSet(),
        {1, 2, 3, 4, 5, 6, 7},
      );
      expect(rule.bySetPositions, [1]);
    });
  });

  group('custom yearly', () {
    test('emits sorted byMonths with byMonthDays', () {
      final rule = const RecurrenceSelection(
        frequency: Frequency.yearly,
        mode: RecurrenceMode.custom,
        months: {6, 1, 3},
        monthly: MonthlySelection(monthDay: 15),
      ).toRrule(dateSymbols: symbols);

      expect(rule.byMonths, [1, 3, 6]);
      expect(rule.byMonthDays, [15]);
    });

    test('strips byMonths and byMonthDays matching startDate', () {
      final rule = const RecurrenceSelection(
        frequency: Frequency.yearly,
        mode: RecurrenceMode.custom,
        months: {3},
        monthly: MonthlySelection(monthDay: 15),
      ).toRrule(
        startDate: DateTime(2025, 3, 15),
        dateSymbols: symbols,
      );

      expect(rule.byMonths, isEmpty);
      expect(rule.byMonthDays, isEmpty);
    });

    test('nth weekday yearly carries byMonths and ordinal', () {
      final rule = const RecurrenceSelection(
        frequency: Frequency.yearly,
        mode: RecurrenceMode.custom,
        months: {6},
        monthly: MonthlySelection(
          mode: MonthlyMode.weekday,
          ordinal: Ordinal.second,
          nthWeekday: WeekdayChoice.friday,
        ),
      ).toRrule(dateSymbols: symbols);

      expect(rule.byMonths, [6]);
      expect(rule.byWeekDays, [ByWeekDayEntry(DateTime.friday, 2)]);
      expect(rule.bySetPositions, isEmpty);
    });
  });
}
