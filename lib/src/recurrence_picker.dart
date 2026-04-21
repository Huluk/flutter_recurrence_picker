import 'package:flutter/material.dart';
import 'package:rrule/rrule.dart';

import 'build_recurrence.dart';
import 'end_of_month_selector.dart';
import 'l10n/recurrence_localizations.dart';
import 'locale_utils.dart';
import 'month_grid.dart';
import 'monthly_picker.dart';
import 'number_stepper.dart';
import 'recurrence_selection.dart';
import 'rrule_utils.dart';
import 'week_day_picker.dart';

/// Controls the visibility and behavior of the "on specific days" toggle.
enum SpecificDaysMode {
  /// Never show the toggle and never enter the specific-days mode.
  /// The picker always emits a simple interval rule.
  disabled,

  /// Show the toggle; the user chooses whether to refine the rule with
  /// specific-day selections. This is the default.
  toggle,

  /// Never show the toggle but always enable the specific-days mode when
  /// the current frequency supports it (everything except daily).
  alwaysOn,
}

/// A compound widget for selecting a [RecurrenceRule].
///
/// The interval and frequency ("every 2 weeks") are always shown. A toggle
/// labelled "on specific days" expands the picker into **Custom** mode, where
/// the user specifies exactly which days, weekdays, or months the recurrence
/// targets.
class RecurrencePicker extends StatefulWidget {
  final Frequency initialFrequency;
  final int initialInterval;
  final ValueChanged<RecurrenceRule> onRecurrenceChanged;

  /// The start date of the recurrence.
  /// In accordance with the `rrule` package and iOS, the start date is **not**
  /// written into the rrule, but only serves as a reference for calculations.
  /// If null, no end-of-month handling is applied in "Every" mode.
  final DateTime? startDate;

  /// Default end-of-month behavior when a critical date (>28) is
  /// selected. Defaults to [EndOfMonthBehavior.previousDay].
  final EndOfMonthBehavior defaultEndOfMonthBehavior;

  /// Whether to show the end-of-month behavior selector when a
  /// critical date is picked. Defaults to `true`.
  final bool showEndOfMonthSelector;

  /// Controls whether the "on specific days" toggle is shown and whether the
  /// specific-days mode may be active. Defaults to [SpecificDaysMode.toggle].
  final SpecificDaysMode specificDaysMode;

  const RecurrencePicker({
    super.key,
    this.initialFrequency = Frequency.weekly,
    this.initialInterval = 1,
    required this.onRecurrenceChanged,
    this.startDate,
    this.defaultEndOfMonthBehavior = EndOfMonthBehavior.previousDay,
    this.showEndOfMonthSelector = true,
    this.specificDaysMode = SpecificDaysMode.toggle,
  });

  @override
  State<RecurrencePicker> createState() => _RecurrencePickerState();
}

class _RecurrencePickerState extends State<RecurrencePicker> {
  static const _frequencies = [
    Frequency.daily,
    Frequency.weekly,
    Frequency.monthly,
    Frequency.yearly,
  ];

  late RecurrenceSelection _selection;

  RecurrenceLocalizations get _loc => RecurrenceLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _selection = RecurrenceSelection(
      frequency: widget.initialFrequency,
      interval: widget.initialInterval,
      endOfMonthBehavior: widget.defaultEndOfMonthBehavior,
    ).withStartDate(widget.startDate);
    _selection = _resolveMode(_selection);
  }

  /// Resolves the effective [RecurrenceMode] given the current selection and
  /// the configured [RecurrencePicker.specificDaysMode].
  RecurrenceSelection _resolveMode(RecurrenceSelection s) {
    final mode = switch (widget.specificDaysMode) {
      SpecificDaysMode.disabled => RecurrenceMode.every,
      SpecificDaysMode.alwaysOn =>
        s.customAvailable ? RecurrenceMode.custom : RecurrenceMode.every,
      SpecificDaysMode.toggle =>
        s.customAvailable ? s.mode : RecurrenceMode.every,
    };
    return s.copyWith(mode: mode);
  }

  @override
  void didUpdateWidget(RecurrencePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final startDateChanged = widget.startDate != oldWidget.startDate;
    final specificDaysModeChanged =
        widget.specificDaysMode != oldWidget.specificDaysMode;
    if (startDateChanged) {
      _selection = _selection.withStartDate(widget.startDate);
    }
    if (specificDaysModeChanged) _selection = _resolveMode(_selection);
    if (startDateChanged || specificDaysModeChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _notify();
      });
    }
  }

  // -----------------------------------------------------------------
  // Notification
  // -----------------------------------------------------------------

  void _notify() {
    widget.onRecurrenceChanged(
      _selection.toRrule(
          startDate: widget.startDate, dateSymbols: dateSymbolsOf(context)),
    );
  }

  void _update(RecurrenceSelection next) {
    setState(() => _selection = next);
    _notify();
  }

  // -----------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _intervalSection,
          if (widget.specificDaysMode == SpecificDaysMode.toggle) _customToggle,
          if (_selection.mode == RecurrenceMode.custom) ...[
            const SizedBox(height: 8),
            _customContent,
          ],
        ],
      );

  /// The always-visible "Every [N] [freq]" row, plus the end-of-month
  /// selector when applicable in "Every" mode (in "Custom" mode the selector
  /// is rendered within [_customContent] instead).
  Widget get _intervalSection {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(_loc.every, style: theme.textTheme.titleMedium),
            const SizedBox(width: 4),
            NumberStepper(
              value: _selection.interval,
              onChanged: (v) => _update(_selection.copyWith(interval: v)),
              hint: _loc.interval,
            ),
            const SizedBox(width: 4),
            _frequencyDropdown,
          ],
        ),
        if (_selection.mode == RecurrenceMode.every && _showEndOfMonthSelector)
          _endOfMonthSelector,
      ],
    );
  }

  Widget get _frequencyDropdown => DropdownButton<Frequency>(
        value: _selection.frequency,
        underline: const SizedBox.shrink(),
        focusColor: Colors.transparent,
        style: Theme.of(context).textTheme.titleMedium,
        items: [
          for (final freq in _frequencies)
            DropdownMenuItem(
              value: freq,
              child: Text(_frequencyLabel(freq)),
            ),
        ],
        onChanged: (value) {
          if (value == null) return;
          _update(_resolveMode(_selection.copyWith(frequency: value)));
        },
      );

  /// Switch + label that toggles the mode between every and custom. Disabled
  /// when [RecurrenceSelection.customAvailable] is false. Merged into a
  /// single semantic control.
  Widget get _customToggle {
    final theme = Theme.of(context);
    return MergeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: _selection.mode == RecurrenceMode.custom,
            onChanged: _selection.customAvailable ? _setCustomMode : null,
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child:
                Text(_loc.onSpecificDays, style: theme.textTheme.titleMedium),
          ),
        ],
      ),
    );
  }

  void _setCustomMode(bool value) => _update(
        _selection.copyWith(
          mode: value ? RecurrenceMode.custom : RecurrenceMode.every,
        ),
      );

  // -----------------------------------------------------------------
  // "Custom" mode content
  // -----------------------------------------------------------------

  Widget get _customContent => switch (_selection.frequency) {
        Frequency.weekly => WeekDayPicker(
            selected: _selection.weekdays,
            onChanged: (v) => _update(_selection.copyWith(weekdays: v)),
          ),
        Frequency.monthly => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _monthlyPicker(),
              if (_showEndOfMonthSelector) _endOfMonthSelector,
            ],
          ),
        Frequency.yearly => _yearlyContent,
        _ => const SizedBox.shrink(),
      };

  // -----------------------------------------------------------------
  // Monthly sub-picker (reused in yearly)
  // -----------------------------------------------------------------

  MonthlyPicker _monthlyPicker({Set<int> months = const {0}}) {
    final daysInMonth = maxDaysInMonths(months);
    final monthly = _selection.monthly;
    final clamped = monthly.monthDay > daysInMonth
        ? monthly.copyWith(monthDay: daysInMonth)
        : monthly;
    return MonthlyPicker(
      selection: clamped,
      months: months,
      onChanged: (v) => _update(_selection.copyWith(monthly: v)),
    );
  }

  /// Whether the end-of-month selector should be shown.
  bool get _showEndOfMonthSelector {
    if (!widget.showEndOfMonthSelector) return false;
    final frequency = _selection.frequency;
    if (frequency != Frequency.monthly && frequency != Frequency.yearly) {
      return false;
    }

    if (_selection.mode == RecurrenceMode.every) {
      final startDate = widget.startDate;
      if (startDate == null) return false;
      return switch (frequency) {
        Frequency.monthly => startDate.day > minDaysInMonths(),
        Frequency.yearly => startDate.month == 2 && startDate.day == 29,
        _ => false,
      };
    }

    final monthly = _selection.monthly;
    final months = _selection.months;
    if (monthly.mode != MonthlyMode.date) return false;
    if (monthly.monthDay == maxDaysInMonths(months)) return false;
    if (frequency == Frequency.yearly &&
        months.contains(2) &&
        monthly.monthDay == 29) {
      return true;
    }
    return minDaysInMonths(months) < monthly.monthDay;
  }

  Widget get _endOfMonthSelector => EndOfMonthSelector(
        behavior: _selection.endOfMonthBehavior,
        onChanged: (v) => _update(_selection.copyWith(endOfMonthBehavior: v)),
      );

  // -----------------------------------------------------------------
  // Yearly: month grid + monthly sub-picker
  // -----------------------------------------------------------------

  Widget get _yearlyContent => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          MonthGrid(
            selectedMonths: _selection.months,
            multiSelectionEnabled: false,
            onChanged: _onYearlyMonthsChanged,
          ),
          const SizedBox(height: 8),
          _monthlyPicker(months: _selection.months),
          if (_showEndOfMonthSelector) _endOfMonthSelector,
        ],
      );

  void _onYearlyMonthsChanged(Set<int> months) {
    final daysInMonth = maxDaysInMonths(months);
    final monthly = _selection.monthly;
    final nextMonthly = monthly.monthDay > daysInMonth
        ? monthly.copyWith(monthDay: daysInMonth)
        : monthly;
    _update(_selection.copyWith(months: months, monthly: nextMonthly));
  }

  String _frequencyLabel(Frequency frequency) => switch (frequency) {
        Frequency.daily => _loc.frequencyDays,
        Frequency.weekly => _loc.frequencyWeeks,
        Frequency.monthly => _loc.frequencyMonths,
        Frequency.yearly => _loc.frequencyYears,
        _ => throw UnsupportedError('Frequency $frequency is not supported'),
      };
}
