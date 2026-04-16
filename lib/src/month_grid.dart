import 'package:flutter/material.dart';
import 'package:intl/date_symbols.dart';

import 'locale_utils.dart';
import 'selectable_grid.dart';

/// 4×3 grid of toggle cells for multi-selecting months,
/// displayed as a single cohesive block with shared borders.
class MonthGrid extends StatelessWidget {
  /// Selected months (1 = January … 12 = December).
  final Set<int> selectedMonths;
  final ValueChanged<Set<int>> onChanged;

  const MonthGrid({
    super.key,
    required this.selectedMonths,
    required this.onChanged,
  });

  static const _cols = 3;

  @override
  Widget build(BuildContext context) {
    final DateSymbols symbols = dateSymbolsOf(context);
    final colorScheme = Theme.of(context).colorScheme;

    return SelectableGrid(
      columns: _cols,
      items: [
        for (int month = 1; month <= 12; month++)
          SelectableGridItem(
            label: Text(
              monthName(symbols, month),
              style: TextStyle(
                color: selectedMonths.contains(month)
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
              ),
            ),
            selected: selectedMonths.contains(month),
            onTap: () => _toggle(month),
          ),
      ],
    );
  }

  void _toggle(int month) {
    final updated = Set<int>.of(selectedMonths);
    if (selectedMonths.contains(month)) {
      if (updated.length > 1) updated.remove(month);
    } else {
      updated.add(month);
    }
    onChanged(updated);
  }
}
