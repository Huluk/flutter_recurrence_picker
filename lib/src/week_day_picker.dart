import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Multi-select day-of-week picker.
class WeekDayPicker extends StatelessWidget {
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  // Random monday, 1st of January, used for date formatting.
  static final DateTime _referenceMonday = DateTime.utc(2001, 1, 1);

  const WeekDayPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final DateFormat longDateFormat = DateFormat.EEEE();
    final DateFormat shortDateFormat = DateFormat.E();
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    return Wrap(
      spacing: 2,
      runSpacing: 8,
      children: [
        for (var day = _referenceMonday;
            day.day <= 7;
            day = day.add(const Duration(days: 1)))
          FilterChip(
            key: Key('wday-${day.weekday}'),
            label: Container(
                constraints: BoxConstraints.tight(const Size(
                    kMinInteractiveDimension, kMinInteractiveDimension)),
                alignment: AlignmentGeometry.center,
                child: Text(shortDateFormat.format(day),
                    style: textTheme.titleLarge!.copyWith(
                        color: selected.contains(day.weekday)
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface))),
            tooltip: longDateFormat.format(day),
            shape: const CircleBorder(side: BorderSide.none),
            selectedColor: colorScheme.primaryContainer,
            showCheckmark: false,
            selected: selected.contains(day.weekday),
            onSelected: (selected) {
              final updated = Set.of(this.selected);
              if (selected) {
                updated.add(day.weekday);
              } else {
                updated.remove(day.weekday);
              }
              onChanged(updated);
            },
          ),
      ],
    );
  }
}
