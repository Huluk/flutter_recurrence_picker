import 'package:flutter/material.dart';

import 'l10n/recurrence_localizations.dart';
import 'rrule_utils.dart';

/// Shows a hint explaining that the selected day doesn't exist in
/// every month, and lets the user choose the desired behavior.
class EndOfMonthSelector extends StatelessWidget {
  final EndOfMonthBehavior behavior;
  final ValueChanged<EndOfMonthBehavior> onChanged;

  const EndOfMonthSelector({
    super.key,
    required this.behavior,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final loc = RecurrenceLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.info_outline,
                size: 16, color: theme.colorScheme.secondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                loc.endOfMonthHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SegmentedButton<EndOfMonthBehavior>(
          segments: [
            ButtonSegment(
              value: EndOfMonthBehavior.previousDay,
              label: Text(loc.endOfMonthPreviousDay),
            ),
            ButtonSegment(
              value: EndOfMonthBehavior.skip,
              label: Text(loc.endOfMonthSkip),
            ),
          ],
          selected: {behavior},
          onSelectionChanged: (selection) =>
              onChanged(selection.first),
        ),
      ],
    );
  }
}
