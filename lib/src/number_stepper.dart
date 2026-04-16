import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'l10n/recurrence_localizations.dart';

/// Number field with increment/decrement stepper buttons.
class NumberStepper extends StatefulWidget {
  final int value;
  final int minValue;
  final int maxValue;
  final ValueChanged<int> onChanged;

  const NumberStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.minValue = 1,
    this.maxValue = 999,
  });

  @override
  State<NumberStepper> createState() => _NumberStepperState();
}

class _NumberStepperState extends State<NumberStepper> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value.toString(),
    );
  }

  @override
  void didUpdateWidget(NumberStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = RecurrenceLocalizations.of(context)!;
    final style = Theme.of(context).textTheme.titleMedium;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: loc.decrementInterval,
          child: IconButton(
            icon: const Icon(Icons.remove),
            onPressed: widget.value <= widget.minValue
                ? null
                : () => widget.onChanged(widget.value - 1),
          ),
        ),
        SizedBox(
          width: 48,
          child: TextFormField(
            controller: _controller,
            onChanged: (value) {
              final n = int.tryParse(value);
              if (n == null) return;
              if (n >= widget.minValue && n <= widget.maxValue) {
                widget.onChanged(n);
              } else {
                _controller.text = widget.value.toString();
              }
            },
            textAlign: TextAlign.center,
            style: style,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: loc.interval,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(_log10(widget.maxValue)),
            ],
          ),
        ),
        Semantics(
          label: loc.incrementInterval,
          child: IconButton(
            icon: const Icon(Icons.add),
            onPressed: widget.value >= widget.maxValue
                ? null
                : () => widget.onChanged(widget.value + 1),
          ),
        ),
      ],
    );
  }
}

int _log10(int value) => value.toString().length;
