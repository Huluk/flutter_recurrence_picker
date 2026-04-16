import 'package:collection/collection.dart';
import 'package:rrule/rrule.dart';

/// How the recurrence should behave when the target day doesn't
/// exist in a given month (e.g. day 31 in a 30-day month).
enum EndOfMonthBehavior {
  /// Use the last available day of the month (e.g. 31 → 30).
  previousDay,

  /// Skip months that don't have the target day.
  skip,
}

/// Number of days in each month across all years.
/// Month 0 represents "any month".
const kAnyMonth = 0;
const maxDaysInMonth = [31, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
const minDaysInMonth = [28, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

int maxDaysInMonths([Iterable<int> months = const [0]]) =>
    months.map((m) => maxDaysInMonth[m]).maxOrNull ?? maxDaysInMonth[kAnyMonth];

int minDaysInMonths([Iterable<int> months = const [0]]) =>
    months.map((m) => minDaysInMonth[m]).minOrNull ?? minDaysInMonth[kAnyMonth];

/// Extension on [RecurrenceRule] providing end-of-month clamping utilities.
extension RecurrenceRuleClamping on RecurrenceRule {
  /// Returns `true` if this rule uses the range-based end-of-month clamping
  /// convention (byMonthDays is a consecutive range starting from 28, with
  /// bySetPositions == [-1]).
  ///
  /// Does **not** match the simpler `BYMONTHDAY=-1` encoding (day 31),
  /// which is self-descriptive and needs no annotation in
  /// [RecurrenceRuleDescription.describe].
  bool get hasEndOfMonthClamping =>
      bySetPositions.contains(-1) && byMonthDays.any((d) => d > 28);

  /// Returns a clamped version of this rule for [startDate] so that rules on
  /// days that don't exist in all months clamp to the last day of the month
  /// instead of skipping it (RFC 5545 default).
  RecurrenceRule clamp({DateTime? startDate}) {
    if (byMonthDays.length > 1 || byMonthDays.contains(-1)) {
      // Either already in clamped form, or else too complicated to handle.
      return this;
    }

    // Derive the target from the rule if set, otherwise from the date.
    // Note that these values may not make sense for all frequency settings.
    final day = byMonthDays.firstOrNull ?? startDate?.day ?? 0;
    final months = byMonths.isNotEmpty
        ? byMonths
        : [if (startDate != null) startDate.month];

    return switch (frequency) {
      Frequency.monthly when day >= 31 =>
        copyWith(byMonthDays: [-1], bySetPositions: []),
      Frequency.monthly when day > 28 => copyWith(
          byMonthDays: [for (int d = 28; d <= day; d++) d],
          bySetPositions: [-1]),
      Frequency.yearly when day >= maxDaysInMonths(months) =>
        copyWith(byMonths: months, byMonthDays: [-1], bySetPositions: []),
      Frequency.yearly when day > minDaysInMonths(months) => copyWith(
          byMonths: months,
          byMonthDays: [for (int d = minDaysInMonths(months); d <= day; d++) d],
          bySetPositions: [-1],
        ),
      _ => this,
    };
  }
}
