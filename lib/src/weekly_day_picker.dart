import 'package:flutter/material.dart';

import '../recurrence_picker.dart';
import 'locale_utils.dart';

/// Multi-select day-of-week picker shown as a row of [FilterChip]s.
class WeeklyDayPicker extends StatelessWidget {
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  const WeeklyDayPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final loc = RecurrenceLocalizations.of(context)!;
    final days = WeekdayChoice.weekdayValues;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final day in days)
          FilterChip(
            label: Text(day.label(loc)),
            selected: selected.contains(day.wday!),
            onSelected: (selected) {
              final updated = Set.of(this.selected);
              if (selected) {
                updated.add(day.wday!);
              } else {
                updated.remove(day.wday!);
              }
              onChanged(updated);
            },
          ),
      ],
    );
  }
}
