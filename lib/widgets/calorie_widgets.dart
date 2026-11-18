import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/format_numbers.dart';
import '../core/widgets/bite_card.dart';
import '../theme/app_theme.dart';

class MacroProgressCard extends StatelessWidget {
  const MacroProgressCard({
    super.key,
    required this.label,
    required this.grams,
    required this.target,
    required this.color,
  });

  final String label;
  final int grams;
  final int target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final double fraction = target <= 0 ? 0 : (grams / target).clamp(0, 1);
    return BiteCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 4),
          Text('${grams}g', style: AppTextStyles.sectionHeading),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fraction.toDouble(),
              minHeight: 6,
              backgroundColor: AppColors.progressTrack,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class CalorieProgressBar extends StatelessWidget {
  const CalorieProgressBar({
    super.key,
    required this.eaten,
    required this.target,
  });

  final int eaten;
  final int target;

  @override
  Widget build(BuildContext context) {
    final double fraction = target <= 0 ? 0 : (eaten / target).clamp(0, 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: AppColors.progressTrack),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: fraction.toDouble(),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(gradient: chiliHaldiGradient),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${formatNumber(eaten)} / ${formatNumber(target)} kcal',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}

class CalorieRing extends StatelessWidget {
  const CalorieRing({super.key, required this.eaten, required this.target});

  final int eaten;
  final int target;

  @override
  Widget build(BuildContext context) {
    final double fraction = target <= 0 ? 0 : (eaten / target).clamp(0, 1);
    return SizedBox(
      width: 116,
      height: 116,
      child: CustomPaint(
        painter: _RingPainter(fraction.toDouble()),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatNumber(eaten),
                style: AppTextStyles.number.copyWith(color: AppColors.card),
              ),
              Text(
                'of ${formatNumber(target)} kcal',
                style: AppTextStyles.caption.copyWith(color: AppColors.card),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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
    final double radius = size.width / 2 - 6;
    final Paint track = Paint()
      ..color = AppColors.card.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    final Paint arc = Paint()
      ..color = AppColors.haldi
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
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
