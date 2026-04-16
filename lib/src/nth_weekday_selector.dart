import 'package:flutter/material.dart';

import 'l10n/recurrence_localizations.dart';
import 'locale_utils.dart';

/// Ordinal position of a weekday within a month (e.g. "2nd Monday").
enum Ordinal {
  first(1),
  second(2),
  third(3),
  fourth(4),
  secondToLast(-2),
  last(-1);

  /// The integer value used in RFC 5545 BYDAY
  final int value;

  const Ordinal(this.value);

  /// Returns the [Ordinal] with the matching [value].
  static Ordinal fromValue(int value) =>
      values.firstWhere((o) => o.value == value);
}

/// Dropdown pair for selecting an ordinal weekday occurrence
/// (e.g. "2nd Monday", "last work day").
class NthWeekdaySelector extends StatelessWidget {
  final Ordinal ordinal;
  final ValueChanged<Ordinal> onOrdinalChanged;
  final WeekdayChoice selected;
  final ValueChanged<WeekdayChoice> onWeekdayChanged;

  const NthWeekdaySelector({
    super.key,
    required this.ordinal,
    required this.onOrdinalChanged,
    required this.selected,
    required this.onWeekdayChanged,
  });

  @override
  Widget build(BuildContext context) {
    final loc = RecurrenceLocalizations.of(context)!;
    final style = Theme.of(context).textTheme.titleMedium;

    return Row(
      children: [
        DropdownButton<Ordinal>(
          value: ordinal,
          underline: const SizedBox.shrink(),
          style: style,
          items: [
            for (final o in Ordinal.values)
              DropdownMenuItem(value: o, child: Text(_ordinalLabel(loc, o))),
          ],
          onChanged: (value) {
            if (value != null) onOrdinalChanged(value);
          },
        ),
        const SizedBox(width: 8),
        DropdownButton<WeekdayChoice>(
          value: selected,
          underline: const SizedBox.shrink(),
          style: style,
          items: [
            for (final day in WeekdayChoice.weekdayValues)
              DropdownMenuItem(value: day, child: Text(day.label(loc))),
            const DropdownMenuItem(enabled: false, child: Divider(height: 1)),
            for (final special in WeekdayChoice.collectionValues)
              DropdownMenuItem(value: special, child: Text(special.label(loc))),
          ],
          onChanged: (value) {
            if (value != null) onWeekdayChanged(value);
          },
        ),
      ],
    );
  }

  /// Returns the localized label for [ordinal].
  static String _ordinalLabel(RecurrenceLocalizations loc, Ordinal ordinal) =>
      switch (ordinal) {
        Ordinal.first => loc.ordinalFirst,
        Ordinal.second => loc.ordinalSecond,
        Ordinal.third => loc.ordinalThird,
        Ordinal.fourth => loc.ordinalFourth,
        Ordinal.secondToLast => loc.ordinalSecondToLast,
        Ordinal.last => loc.ordinalLast,
      };
}
