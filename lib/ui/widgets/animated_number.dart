import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bite_motion.dart';

// How it works: the number counts from 0 to the value.
// Reduced motion shows the final number at once. Figures stay tabular.

class AnimatedNumber extends StatelessWidget {
  const AnimatedNumber({
    super.key,
    required this.value,
    this.style,
    this.suffix = '',
  });

  final num value;
  final TextStyle? style;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final TextStyle text = style ?? AppTextStyles.number;
    final bool still = MediaQuery.disableAnimationsOf(context);
    if (still) {
      return Text(_label(value.toDouble()), style: text);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: BiteMotion.base,
      curve: BiteMotion.enter,
      builder: (BuildContext context, double current, Widget? child) {
        return Text(_label(current), style: text);
      },
    );
  }

  String _label(double current) {
    final String digits = value is int
        ? current.round().toString()
        : current.toStringAsFixed(0);
    if (suffix.isEmpty) {
      return digits;
    }
    return '$digits$suffix';
  }
}
