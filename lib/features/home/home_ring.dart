import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bite_motion.dart';
import '../../ui/widgets/animated_number.dart';
import '../../ui/widgets/bite_card.dart';

// How it works: the ring draws how much of the target is eaten.
// The middle number is what is left. It counts up on open.

class TodayRing extends StatelessWidget {
  const TodayRing({
    super.key,
    required this.eaten,
    required this.target,
    required this.left,
    required this.burned,
  });

  final int eaten;
  final int target;
  final int left;
  final int burned;

  @override
  Widget build(BuildContext context) {
    final bool over = left < 0;
    final double fraction = target <= 0 ? 0 : (eaten / target).clamp(0, 1);
    final bool still = MediaQuery.disableAnimationsOf(context);
    return BiteSurface(
      child: Column(
        children: [
          RepaintBoundary(
            child: SizedBox(
              width: 180,
              height: 180,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: fraction.toDouble()),
                duration: still ? Duration.zero : BiteMotion.slow,
                curve: BiteMotion.enter,
                builder: (BuildContext context, double sweep, Widget? child) {
                  return CustomPaint(
                    painter: _RingPainter(sweep),
                    child: child,
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedNumber(
                      value: left.abs(),
                      style: AppTextStyles.numberLarge.copyWith(
                        color: over ? AppColors.warning : AppColors.text,
                      ),
                    ),
                    Text(
                      over ? 'kcal over' : 'kcal left',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Quiet(label: 'Eaten', value: eaten),
              _line(),
              _Quiet(label: 'Burned', value: burned),
              _line(),
              _Quiet(label: 'Left', value: left),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line() {
    return Container(width: 1, height: 36, color: AppColors.hairline);
  }
}

class _Quiet extends StatelessWidget {
  const _Quiet({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('$value', style: AppTextStyles.sectionHeading),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.fraction);

  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.width / 2 - 10;
    final Paint track = Paint()
      ..color = AppColors.inkAt(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    final Paint arc = Paint()
      ..shader = LinearGradient(
        colors: <Color>[AppColors.chili, AppColors.chiliAt(0.55)],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    if (fraction <= 0) {
      return;
    }
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * fraction,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.fraction != fraction;
  }
}
