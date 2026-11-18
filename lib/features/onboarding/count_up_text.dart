import 'package:flutter/material.dart';

/// Counts from 0 up to [end]. The stored target is not rounded here until display.
class CountUpText extends StatelessWidget {
  const CountUpText({
    super.key,
    required this.end,
    required this.style,
    this.suffix = '',
  });

  final int end;
  final TextStyle style;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      // 350 ms is the top of the app's animation range.
      duration: still ? Duration.zero : const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: end.toDouble()),
      builder: (BuildContext context, double value, Widget? child) {
        return Text('${value.round()}$suffix', style: style);
      },
    );
  }
}
