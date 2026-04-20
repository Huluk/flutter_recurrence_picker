import 'package:flutter/material.dart';

/// A grid of selectable cells displayed as a single cohesive block
/// with shared borders, clipped to a rounded rectangle.
///
/// Items are laid out in rows of [columns] cells each.
/// Cells with `onTap == null` render as empty space (for uneven grids).
class SelectableGrid extends StatelessWidget {
  /// Flat list of items, laid out left-to-right, top-to-bottom.
  final List<SelectableGridItem> items;

  /// Number of columns per row.
  final int columns;

  /// Outer border radius.
  final double borderRadius;

  const SelectableGrid({
    super.key,
    required this.items,
    required this.columns,
    this.borderRadius = 12,
  }) : assert(columns >= 1);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = colorScheme.outlineVariant;
    final borderSide = BorderSide(color: borderColor);
    final rows = (items.length / columns).ceil();

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int row = 0; row < rows; row++)
              IntrinsicHeight(
                child: Row(
                  children: [
                    for (int col = 0; col < columns; col++)
                      _buildCell(
                        row: row,
                        col: col,
                        rows: rows,
                        colorScheme: colorScheme,
                        borderSide: borderSide,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCell({
    required int row,
    required int col,
    required int rows,
    required ColorScheme colorScheme,
    required BorderSide borderSide,
  }) {
    final index = row * columns + col;
    final isLastRow = row == rows - 1;
    final isLastCol = col == columns - 1;

    // Out-of-range items: empty cell with no border on the right.
    if (index >= items.length) {
      return Expanded(
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: !isLastRow ? borderSide : BorderSide.none,
            ),
          ),
          child: const SizedBox.shrink(),
        ),
      );
    }

    final item = items[index];
    final hasTap = item.onTap != null;

    // Don't draw borders between empty cells in the last row.
    final showRight = !isLastCol && (hasTap || !isLastRow);
    final showBottom = !isLastRow;

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: showRight ? borderSide : BorderSide.none,
            bottom: showBottom ? borderSide : BorderSide.none,
          ),
        ),
        child: hasTap ? item : const SizedBox.shrink(),
      ),
    );
  }
}

/// A single cell in a [SelectableGrid].
class SelectableGridItem extends StatelessWidget {
  /// Label widget displayed in the cell.
  final Widget label;

  /// Whether this cell is selected.
  final bool selected;

  /// Callback when the cell is tapped.
  ///
  /// When `null`, the cell renders as empty space (no ink, no tap).
  final VoidCallback? onTap;

  const SelectableGridItem({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: selected
            ? Theme.of(context).colorScheme.primaryContainer
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(child: label),
          ),
        ),
      );
}
