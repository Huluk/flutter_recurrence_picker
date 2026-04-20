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
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value.toString(),
    );
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(NumberStepper old) {
    super.didUpdateWidget(old);
    final text = widget.value.toString();
    if (_controller.text != text) _controller.text = text;
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) return;
    final textValue = int.tryParse(_controller.text);
    if (textValue == null || textValue < widget.minValue) {
      _controller.text = widget.minValue.toString();
      if (widget.value != widget.minValue) widget.onChanged(widget.minValue);
    } else if (textValue > widget.maxValue) {
      _controller.text = widget.maxValue.toString();
      if (widget.value != widget.maxValue) widget.onChanged(widget.maxValue);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
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
            onPressed: _stepAction(widget.value - 1),
          ),
        ),
        SizedBox(
          width: 48,
          child: TextFormField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: (value) {
              final n = int.tryParse(value);
              if (n != null && n >= widget.minValue && n <= widget.maxValue) {
                widget.onChanged(n);
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
            onPressed: _stepAction(widget.value + 1),
          ),
        ),
      ],
    );
  }

  VoidCallback? _stepAction(int targetValue) {
    if (targetValue < widget.minValue || targetValue > widget.maxValue) {
      return null;
    }
    return () => widget.onChanged(targetValue);
  }
}

int _log10(int value) => value.toString().length;
