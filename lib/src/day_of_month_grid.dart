import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'selectable_grid.dart';

/// Grid of numbered buttons for selecting a day-of-month.
/// Displayed as a single cohesive block with shared borders.
class DayOfMonthGrid extends StatelessWidget {
  /// Currently selected day (1–31).
  final int selectedDay;

  final int daysInMonth;

  final ValueChanged<int> onChanged;

  /// Number of columns per row. Defaults to 7.
  final int maxColumns;
  int get columns => min(daysInMonth, maxColumns);

  static final _format = DateFormat.d();

  const DayOfMonthGrid({
    super.key,
    required this.daysInMonth,
    required this.selectedDay,
    required this.onChanged,
    this.maxColumns = 7,
  }) : assert(maxColumns >= 1);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SelectableGrid(
      columns: columns,
      items: [
        for (int day = 1; day <= daysInMonth; day++)
          SelectableGridItem(
            label: Text(
              _format.format(DateTime(1970, 1, day)),
              style: TextStyle(
                color: day == selectedDay
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
              ),
            ),
            selected: day == selectedDay,
            onTap: () => onChanged(day),
          ),
      ],
    );
  }
}
