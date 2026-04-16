import 'package:flutter/material.dart';

import 'day_of_month_grid.dart';
import 'l10n/recurrence_localizations.dart';
import 'locale_utils.dart';
import 'nth_weekday_selector.dart';
import 'rrule_utils.dart';

/// Whether the monthly recurrence targets a specific date
/// or an nth weekday.
enum MonthlyMode { date, weekday }

/// Bundles the user's monthly recurrence selections: which mode
/// (date vs weekday), and the values for each mode.
class MonthlySelection {
  /// Date vs nth-weekday mode.
  final MonthlyMode mode;

  /// Selected day of month (1–31) for date mode.
  final int monthDay;

  /// Ordinal occurrence for weekday.
  final Ordinal ordinal;

  /// Selected weekday (1–7) or weekday category.
  final WeekdayChoice nthWeekday;

  const MonthlySelection({
    this.mode = MonthlyMode.date,
    this.monthDay = 1,
    this.ordinal = Ordinal.first,
    this.nthWeekday = WeekdayChoice.monday,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthlySelection &&
          runtimeType == other.runtimeType &&
          mode == other.mode &&
          monthDay == other.monthDay &&
          ordinal == other.ordinal &&
          nthWeekday == other.nthWeekday;

  @override
  int get hashCode => Object.hash(mode, monthDay, ordinal, nthWeekday);

  MonthlySelection copyWith({
    MonthlyMode? mode,
    int? monthDay,
    Ordinal? ordinal,
    WeekdayChoice? nthWeekday,
  }) =>
      MonthlySelection(
        mode: mode ?? this.mode,
        monthDay: monthDay ?? this.monthDay,
        ordinal: ordinal ?? this.ordinal,
        nthWeekday: nthWeekday ?? this.nthWeekday,
      );
}

/// Picker for monthly recurrence details: either a specific
/// day-of-month (via inline calendar) or an nth weekday
/// (via dropdowns).
class MonthlyPicker extends StatelessWidget {
  final MonthlySelection selection;

  /// ISO month (1-12) or null for any month.
  final Set<int>? months;
  final ValueChanged<MonthlySelection> onChanged;

  const MonthlyPicker({
    super.key,
    this.months,
    required this.selection,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _modeSelector(context),
        const SizedBox(height: 8),
        if (selection.mode == MonthlyMode.date)
          ..._dateGrid
        else
          NthWeekdaySelector(
            ordinal: selection.ordinal,
            onOrdinalChanged: (v) => onChanged(selection.copyWith(ordinal: v)),
            selected: selection.nthWeekday,
            onWeekdayChanged: (v) =>
                onChanged(selection.copyWith(nthWeekday: v)),
          ),
      ],
    );
  }

  List<Widget> get _dateGrid {
    final daysInMonth = maxDaysInMonths(months ?? const {0});
    final clampedDay =
        selection.monthDay > daysInMonth ? daysInMonth : selection.monthDay;
    return [
      DayOfMonthGrid(
        daysInMonth: daysInMonth,
        selectedDay: clampedDay,
        onChanged: (v) => onChanged(selection.copyWith(monthDay: v)),
      ),
    ];
  }

  Widget _modeSelector(BuildContext context) {
    final loc = RecurrenceLocalizations.of(context)!;
    return SegmentedButton<MonthlyMode>(
      segments: [
        ButtonSegment(
          value: MonthlyMode.date,
          label: Text(loc.monthlyByDate),
        ),
        ButtonSegment(
          value: MonthlyMode.weekday,
          label: Text(loc.monthlyByWeekday),
        ),
      ],
      selected: {selection.mode},
      onSelectionChanged: (s) => onChanged(selection.copyWith(mode: s.first)),
    );
  }
}
