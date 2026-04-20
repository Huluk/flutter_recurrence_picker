import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'l10n/recurrence_localizations.dart';

/// Controls the visual appearance of [NumberStepper].
class NumberStepperStyle {
  /// Shape of the bubble. Defaults to a stadium (pill) shape.
  final ShapeBorder bubbleShape;

  /// Background color of the bubble.
  /// Falls back to [ColorScheme.secondaryContainer] when null.
  final Color? bubbleColor;

  /// Text style for the number inside the field.
  /// Falls back to [TextTheme.titleMedium] when null.
  final TextStyle? numberStyle;

  const NumberStepperStyle({
    this.bubbleShape = const StadiumBorder(),
    this.bubbleColor,
    this.numberStyle,
  });
}

/// Number field with increment/decrement stepper buttons inside a pill bubble.
///
/// [hint] is exposed to accessibility tools (screen-reader hint, tooltip on
/// pointer devices) but has no visual presence.
class NumberStepper extends StatefulWidget {
  final int value;
  final int minValue;
  final int maxValue;
  final ValueChanged<int> onChanged;

  /// Accessible hint describing what is being stepped (e.g. "Repeat interval").
  /// Announced by screen readers and shown as a tooltip on pointer devices.
  /// When null neither is applied.
  final String? hint;

  /// Visual style.
  final NumberStepperStyle style;

  const NumberStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.minValue = 1,
    this.maxValue = 999,
    this.hint,
    this.style = const NumberStepperStyle(),
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
    _controller = TextEditingController(text: widget.value.toString());
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
    final parsed = int.tryParse(_controller.text);
    if (parsed == null || parsed < widget.minValue) {
      _controller.text = widget.minValue.toString();
      if (widget.value != widget.minValue) widget.onChanged(widget.minValue);
    } else if (parsed > widget.maxValue) {
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
    final digits = widget.maxValue.toString().length;
    final fieldWidth = _measureFieldWidth(context, digits);

    Widget field = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _focusNode.requestFocus(),
      child: SizedBox(
        width: math.max(
          2.70 * kMinInteractiveDimension,
          fieldWidth + 1.5 * kMinInteractiveDimension,
        ),
        height: kMinInteractiveDimension,
        child: Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Align(
            child: _numberField(digits),
          ),
        ),
      ),
    );

    if (widget.hint != null) {
      field = Tooltip(
        message: widget.hint!,
        child: Semantics(hint: widget.hint, child: field),
      );
    }

    return Material(
      color: widget.style.bubbleColor ??
          Theme.of(context).colorScheme.secondaryContainer,
      shape: widget.style.bubbleShape,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          field,
          Positioned(
            left: 0,
            child: Semantics(
              label: loc.decrementInterval,
              child: _StepButton(
                icon: Icons.remove,
                onPressed: _stepAction(widget.value - 1),
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: Semantics(
              label: loc.incrementInterval,
              child: _StepButton(
                icon: Icons.add,
                onPressed: _stepAction(widget.value + 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberField(int digits) => TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: (value) {
          final n = int.tryParse(value);
          if (n != null && n >= widget.minValue && n <= widget.maxValue) {
            widget.onChanged(n);
          }
        },
        textAlign: TextAlign.center,
        style:
            widget.style.numberStyle ?? Theme.of(context).textTheme.titleMedium,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(digits),
        ],
      );

  /// Measures the pixel width needed for [digits], with some extra allowance.
  double _measureFieldWidth(BuildContext context, int digits) {
    final resolvedStyle = (widget.style.numberStyle ??
            Theme.of(context).textTheme.titleMedium ??
            const TextStyle())
        .copyWith(inherit: true);
    final painter = TextPainter(
      text: TextSpan(text: '0' * digits, style: resolvedStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.width + 4;
  }

  VoidCallback? _stepAction(int target) {
    if (target < widget.minValue || target > widget.maxValue) return null;
    return () => widget.onChanged(target);
  }
}

/// A transparent IconButton so the parent bubble Material owns all ink.
class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _StepButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20),
      onPressed: onPressed,
      style: IconButton.styleFrom(
        minimumSize:
            const Size(kMinInteractiveDimension, kMinInteractiveDimension),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: Colors.transparent,
        disabledBackgroundColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
    );
  }
}
