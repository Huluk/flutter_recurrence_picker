import 'package:flutter/material.dart';
import 'package:rrule/rrule.dart';

import 'end_of_month_selector.dart';
import 'l10n/recurrence_localizations.dart';
import 'locale_utils.dart';
import 'month_grid.dart';
import 'monthly_picker.dart';
import 'nth_weekday_selector.dart';
import 'number_stepper.dart';
import 'rrule_utils.dart';
import 'week_day_picker.dart';

/// Internal switch between the simple interval rule and the detailed
/// day/date-based rule. Exposed in the UI as the "on specific days" toggle.
enum RecurrenceMode { every, custom }

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

  // Common state.
  RecurrenceMode _mode = RecurrenceMode.every;
  late Frequency _frequency;
  late int _interval;

  // Weekly state.
  Set<int> _selectedWeekdays = {DateTime.monday};

  // Monthly / yearly shared state.
  MonthlySelection _selection = const MonthlySelection();
  late EndOfMonthBehavior _endOfMonthBehavior;

  // Yearly state.
  Set<int> _selectedMonths = {1};

  RecurrenceLocalizations get _loc => RecurrenceLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _frequency = widget.initialFrequency;
    _interval = widget.initialInterval;
    _endOfMonthBehavior = widget.defaultEndOfMonthBehavior;
    _mode = _resolveMode(_mode);
    _applyStartDateDefaults(widget.startDate);
  }

  /// Resolves the effective [RecurrenceMode] given the current frequency and
  /// the configured [RecurrencePicker.specificDaysMode].
  RecurrenceMode _resolveMode(RecurrenceMode current) =>
      switch (widget.specificDaysMode) {
        SpecificDaysMode.disabled => RecurrenceMode.every,
        SpecificDaysMode.alwaysOn =>
          _customAvailable ? RecurrenceMode.custom : RecurrenceMode.every,
        SpecificDaysMode.toggle =>
          _customAvailable ? current : RecurrenceMode.every,
      };

  @override
  void didUpdateWidget(RecurrencePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final startDateChanged = widget.startDate != oldWidget.startDate;
    final specificDaysModeChanged =
        widget.specificDaysMode != oldWidget.specificDaysMode;
    if (startDateChanged) _applyStartDateDefaults(widget.startDate);
    if (specificDaysModeChanged) _mode = _resolveMode(_mode);
    if (startDateChanged || specificDaysModeChanged) {
      // Defer notification — calling _buildRule() during build
      // would trigger the parent's setState() mid-frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _buildRule();
      });
    }
  }

  /// Derives sensible default values for all pickers from [date].
  ///
  /// When [date] is null, falls back to generic defaults.
  void _applyStartDateDefaults(DateTime? date) {
    if (date == null) return;

    _selectedWeekdays = {date.weekday};
    _selectedMonths = {date.month};

    final daysInMonth = DateUtils.getDaysInMonth(date.year, date.month);
    _selection = date.day == daysInMonth
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
  }

  // -----------------------------------------------------------------
  // Recurrence rule construction
  // -----------------------------------------------------------------

  void _buildRule() {
    widget.onRecurrenceChanged(
      _mode == RecurrenceMode.every ? _buildBasicRule() : _buildCustomRule(),
    );
  }

  /// Builds the RecurrenceRule for "Every" mode, delegating end-of-month
  /// clamping to [RecurrenceRuleClamping.clamp].
  RecurrenceRule _buildBasicRule() {
    final rule = RecurrenceRule(frequency: _frequency, interval: _interval);
    final start = widget.startDate;
    if (start == null) return rule;
    return _endOfMonthBehavior == EndOfMonthBehavior.previousDay
        ? rule.clamp(startDate: start)
        : rule;
  }

  RecurrenceRule _buildCustomRule() => switch (_frequency) {
        Frequency.weekly => RecurrenceRule(
            frequency: Frequency.weekly,
            interval: _interval,
            byWeekDays: [
              for (final d in _selectedWeekdays) ByWeekDayEntry(d),
            ],
          ),
        Frequency.monthly when _selection.mode == MonthlyMode.date =>
          _dateRule(Frequency.monthly),
        Frequency.monthly => _nthWeekdayRule(Frequency.monthly),
        Frequency.yearly when _selection.mode == MonthlyMode.date =>
          _dateRule(Frequency.yearly),
        Frequency.yearly => _nthWeekdayRule(Frequency.yearly),
        _ => RecurrenceRule(
            frequency: _frequency,
            interval: _interval,
          ),
      };

  /// Builds an nth-weekday RecurrenceRule.
  ///
  /// For a plain weekday the rule is simple:
  ///   e.g. "2nd Monday" → BYDAY=2MO
  ///
  /// For a special category, nth selects from the expanded set:
  ///   e.g. "2nd work day" → BYDAY=MO,TU,WE,TH,FR; BYSETPOS=2
  RecurrenceRule _nthWeekdayRule(Frequency freq) {
    final symbols = dateSymbolsOf(context);
    final byWeekDays = _selection.nthWeekday
        .days(symbols)
        .map((d) => ByWeekDayEntry(d, _selection.ordinal.value))
        .toList();
    return RecurrenceRule(
      frequency: freq,
      interval: _interval,
      byMonths: freq == Frequency.yearly
          ? (_selectedMonths.toList()..sort())
          : const [],
      byWeekDays: byWeekDays,
      bySetPositions: byWeekDays.isEmpty
          ? <int>[]
          : [_selection.ordinal.value.compareTo(0)],
    );
  }

  /// Builds a date-based RecurrenceRule.
  RecurrenceRule _dateRule(Frequency freq) {
    final rule = RecurrenceRule(
      frequency: freq,
      interval: _interval,
      byMonths: freq == Frequency.yearly
          ? (_selectedMonths.toList()..sort())
          : const [],
      byMonthDays: [_selection.monthDay],
    );
    return _endOfMonthBehavior == EndOfMonthBehavior.previousDay
        ? rule.clamp(
            startDate:
                widget.startDate ?? DateTime(1970, 1, _selection.monthDay))
        : rule;
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
          if (_mode == RecurrenceMode.custom) ...[
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
              value: _interval,
              onChanged: (v) {
                setState(() => _interval = v);
                _buildRule();
              },
              hint: _loc.interval,
            ),
            const SizedBox(width: 4),
            _frequencyDropdown,
          ],
        ),
        if (_mode == RecurrenceMode.every && _showEndOfMonthSelector)
          _endOfMonthSelector,
      ],
    );
  }

  Widget get _frequencyDropdown => DropdownButton<Frequency>(
        value: _frequency,
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
          setState(() {
            _frequency = value;
            _mode = _resolveMode(_mode);
          });
          _buildRule();
        },
      );

  /// Whether the custom-selection toggle is meaningful: "on specific days"
  /// does not apply for daily recurrence.
  bool get _customAvailable => _frequency != Frequency.daily;

  /// Switch + label that toggles [_mode] between every and custom. Disabled
  /// when [_customAvailable] is false. Merged into a single semantic control.
  Widget get _customToggle {
    final theme = Theme.of(context);
    return MergeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: _mode == RecurrenceMode.custom,
            onChanged: _customAvailable ? _setCustomMode : null,
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

  void _setCustomMode(bool value) {
    setState(
      () => _mode = value ? RecurrenceMode.custom : RecurrenceMode.every,
    );
    _buildRule();
  }

  // -----------------------------------------------------------------
  // "Custom" mode content
  // -----------------------------------------------------------------

  Widget get _customContent => switch (_frequency) {
        Frequency.weekly => WeekDayPicker(
            selected: _selectedWeekdays,
            onChanged: (v) {
              setState(() => _selectedWeekdays = v);
              _buildRule();
            },
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
    final clamped = _selection.monthDay > daysInMonth
        ? _selection.copyWith(monthDay: daysInMonth)
        : _selection;
    return MonthlyPicker(
      selection: clamped,
      months: months,
      onChanged: (v) {
        setState(() => _selection = v);
        _buildRule();
      },
    );
  }

  /// Whether the end-of-month selector should be shown.
  bool get _showEndOfMonthSelector {
    if (!widget.showEndOfMonthSelector) return false;
    if (_frequency != Frequency.monthly && _frequency != Frequency.yearly) {
      return false;
    }

    if (_mode == RecurrenceMode.every) {
      final startDate = widget.startDate;
      if (startDate == null) return false;
      return switch (_frequency) {
        Frequency.monthly => startDate.day > minDaysInMonths(),
        Frequency.yearly => startDate.month == 2 && startDate.day == 29,
        _ => false,
      };
    }

    if (_selection.mode != MonthlyMode.date) return false;
    if (_selection.monthDay == maxDaysInMonths(_selectedMonths)) return false;
    if (_frequency == Frequency.yearly &&
        _selectedMonths.contains(2) &&
        _selection.monthDay == 29) {
      return true;
    }
    return minDaysInMonths(_selectedMonths) < _selection.monthDay;
  }

  Widget get _endOfMonthSelector => EndOfMonthSelector(
        behavior: _endOfMonthBehavior,
        onChanged: (v) {
          setState(() => _endOfMonthBehavior = v);
          _buildRule();
        },
      );

  // -----------------------------------------------------------------
  // Yearly: month grid + monthly sub-picker
  // -----------------------------------------------------------------

  Widget get _yearlyContent => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          MonthGrid(
            selectedMonths: _selectedMonths,
            multiSelectionEnabled: false,
            onChanged: (v) {
              final daysInMonth = maxDaysInMonths(v);
              setState(() {
                _selectedMonths = v;
                if (_selection.monthDay > daysInMonth) {
                  _selection = _selection.copyWith(monthDay: daysInMonth);
                }
              });
              _buildRule();
            },
          ),
          const SizedBox(height: 8),
          _monthlyPicker(months: _selectedMonths),
          if (_showEndOfMonthSelector) _endOfMonthSelector,
        ],
      );

  String _frequencyLabel(Frequency frequency) => switch (frequency) {
        Frequency.daily => _loc.frequencyDays,
        Frequency.weekly => _loc.frequencyWeeks,
        Frequency.monthly => _loc.frequencyMonths,
        Frequency.yearly => _loc.frequencyYears,
        _ => throw UnsupportedError('Frequency $frequency is not supported'),
      };
}
