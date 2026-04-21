import 'package:intl/date_symbols.dart';
import 'package:rrule/rrule.dart';

import 'monthly_picker.dart';
import 'recurrence_selection.dart';
import 'rrule_utils.dart';

extension RecurrenceSeletionToRrule on RecurrenceSelection {
  /// Converts a [RecurrenceSelection] into a [RecurrenceRule].
  ///
  /// [startDate] is used only for end-of-month clamping; it is never written
  /// into the rule itself (the `rrule` package keeps DTSTART separate).
  ///
  /// [dateSymbols] is needed to expand weekday categories (work day,
  /// weekend day, any day) in the locale's convention.
  ///
  /// If [stripRedundantAttributes] is true (default), strip information which
  /// is redundant given the start date. This may lead to information loss if
  /// the start date is not preserved!
  /// Example: with startDate 2026-01-01,
  /// FREQ=YEARLY;BYMONTH=1;BYMONTHDAY=1 becomes FREQ=YEARLY.
  RecurrenceRule toRrule({
    DateTime? startDate,
    required DateSymbols dateSymbols,
    bool stripRedundantAttributes = true,
  }) =>
      mode == RecurrenceMode.every
          ? _buildBasicRule(startDate)
          : _buildCustomRule(startDate, dateSymbols,
              stripRedundantAttributes: stripRedundantAttributes);

  /// Builds the rule for "Every" mode, delegating end-of-month clamping to
  /// [RecurrenceRuleClamping.clamp].
  RecurrenceRule _buildBasicRule(DateTime? startDate) {
    final rule = RecurrenceRule(frequency: frequency, interval: interval);
    if (startDate == null) return rule;
    return endOfMonthBehavior == EndOfMonthBehavior.previousDay
        ? rule.clamp(startDate: startDate)
        : rule;
  }

  RecurrenceRule _buildCustomRule(
    DateTime? startDate,
    DateSymbols symbols, {
    required bool stripRedundantAttributes,
  }) =>
      switch (frequency) {
        Frequency.weekly => RecurrenceRule(
            frequency: Frequency.weekly,
            interval: interval,
            byWeekDays: stripRedundantAttributes &&
                    startDate != null &&
                    startDate.weekday == weekdays.singleOrNull
                ? const []
                : [for (final d in weekdays) ByWeekDayEntry(d)],
          ),
        (Frequency.monthly || Frequency.yearly)
            when monthly.mode == MonthlyMode.date =>
          _dateRule(startDate,
              stripRedundantAttributes: stripRedundantAttributes),
        Frequency.monthly || Frequency.yearly => _nthWeekdayRule(symbols),
        _ => throw UnsupportedError(
            'Frequency $frequency cannot be used in rrule'),
      };

  /// Builds an nth-weekday rule.
  ///
  /// Plain weekday (e.g. "2nd Monday") → BYDAY=2MO.
  /// Weekday category (e.g. "2nd work day") → BYDAY=MO,TU,WE,TH,FR; BYSETPOS=2.
  RecurrenceRule _nthWeekdayRule(DateSymbols symbols) {
    final byWeekDays = monthly.nthWeekday
        .days(symbols)
        .map((d) => ByWeekDayEntry(d, monthly.ordinal.value))
        .toList();
    return RecurrenceRule(
      frequency: frequency,
      interval: interval,
      byMonths: _byMonths,
      byWeekDays: byWeekDays,
      bySetPositions: byWeekDays.length > 1
          ? [monthly.ordinal.value.compareTo(0)]
          : <int>[],
    );
  }

  /// Builds a date-based rule (e.g. "day 15 of the month").
  RecurrenceRule _dateRule(
    DateTime? startDate, {
    required bool stripRedundantAttributes,
  }) {
    var rule = RecurrenceRule(
      frequency: frequency,
      interval: interval,
      byMonths: _byMonths,
      byMonthDays: [monthly.monthDay],
    );
    if (endOfMonthBehavior == EndOfMonthBehavior.previousDay) {
      rule = rule.clamp(
        startDate: startDate ?? DateTime(1970, 1, monthly.monthDay),
      );
    }
    if (stripRedundantAttributes &&
        startDate != null &&
        startDate.day == rule.byMonthDays.singleOrNull &&
        (frequency != Frequency.yearly ||
            startDate.month ==
                (rule.byMonths.singleOrNull ?? startDate.month))) {
      rule = rule.copyWith(byMonths: const [], byMonthDays: const []);
    }
    return rule;
  }

  List<int> get _byMonths =>
      frequency == Frequency.yearly ? (months.toList()..sort()) : const [];
}
