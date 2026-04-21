import 'package:flutter/material.dart' show DateUtils;
import 'package:rrule/rrule.dart';

import 'locale_utils.dart';
import 'monthly_picker.dart';
import 'nth_weekday_selector.dart';
import 'rrule_utils.dart';

/// Internal switch between the simple interval rule and the detailed
/// day/date-based rule. Exposed in the UI as the "on specific days" toggle.
enum RecurrenceMode { every, custom }

/// All user-editable state of a [RecurrencePicker] in one value object.
///
/// The start date of the recurrence is deliberately *not* stored here; it's a
/// runtime parameter passed to [buildRecurrenceRule] to align with conventions
/// of the `rrule` package.
class RecurrenceSelection {
  /// The repeat frequency (daily / weekly / monthly / yearly).
  final Frequency frequency;

  /// The repeat interval ("every N").
  final int interval;

  /// Whether the rule is a plain interval or a specific-days rule.
  final RecurrenceMode mode;

  /// How to handle target days that don't exist in every month.
  final EndOfMonthBehavior endOfMonthBehavior;

  /// Selected weekdays (1–7) for weekly custom mode.
  final Set<int> weekdays;

  /// Sub-selection for monthly / yearly custom mode.
  final MonthlySelection monthly;

  /// Selected months (1–12) for yearly custom mode.
  final Set<int> months;

  const RecurrenceSelection({
    this.frequency = Frequency.weekly,
    this.interval = 1,
    this.mode = RecurrenceMode.every,
    this.endOfMonthBehavior = EndOfMonthBehavior.previousDay,
    this.weekdays = const {DateTime.monday},
    this.monthly = const MonthlySelection(),
    this.months = const {1},
  });

  /// Whether the "on specific days" mode is meaningful at the current
  /// frequency. Daily recurrence has no specific-days refinement.
  bool get customAvailable => frequency != Frequency.daily;

  RecurrenceSelection copyWith({
    Frequency? frequency,
    int? interval,
    RecurrenceMode? mode,
    EndOfMonthBehavior? endOfMonthBehavior,
    Set<int>? weekdays,
    MonthlySelection? monthly,
    Set<int>? months,
  }) =>
      RecurrenceSelection(
        frequency: frequency ?? this.frequency,
        interval: interval ?? this.interval,
        mode: mode ?? this.mode,
        endOfMonthBehavior: endOfMonthBehavior ?? this.endOfMonthBehavior,
        weekdays: weekdays ?? this.weekdays,
        monthly: monthly ?? this.monthly,
        months: months ?? this.months,
      );

  /// Returns a new selection with weekday / month / day defaults derived from
  /// [date]. Common, non-day-specific fields ([frequency], [interval],
  /// [mode], [endOfMonthBehavior]) are preserved.
  RecurrenceSelection withStartDate(DateTime? date) {
    if (date == null) return this;

    final daysInMonth = DateUtils.getDaysInMonth(date.year, date.month);
    final monthlyDefaults = date.day == daysInMonth
        ? MonthlySelection(
            mode: MonthlyMode.weekday,
            monthDay: date.day,
            ordinal: Ordinal.last,
            nthWeekday: WeekdayChoice.anyDay,
          )
        : MonthlySelection(
            mode: MonthlyMode.date,
            monthDay: date.day,
            nthWeekday: WeekdayChoice.fromValue(date.weekday),
            ordinal: date.day + 7 > daysInMonth
                ? Ordinal.last
                : Ordinal.fromValue(1 + (date.day - 1) ~/ 7),
          );

    return copyWith(
      weekdays: {date.weekday},
      months: {date.month},
      monthly: monthlyDefaults,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurrenceSelection &&
          runtimeType == other.runtimeType &&
          frequency == other.frequency &&
          interval == other.interval &&
          mode == other.mode &&
          endOfMonthBehavior == other.endOfMonthBehavior &&
          _setEquals(weekdays, other.weekdays) &&
          monthly == other.monthly &&
          _setEquals(months, other.months);

  @override
  int get hashCode => Object.hash(
        frequency,
        interval,
        mode,
        endOfMonthBehavior,
        Object.hashAllUnordered(weekdays),
        monthly,
        Object.hashAllUnordered(months),
      );
}

bool _setEquals(Set<int> a, Set<int> b) =>
    a.length == b.length && a.containsAll(b);
