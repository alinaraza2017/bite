import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bite_motion.dart';
import '../../core/utils/format_numbers.dart';
import '../../domain/progress_report.dart';

// How it works: bars and the weight line are drawn, not a chart package.
// They grow once. Reduced motion shows the finished shape.

class CalorieBars extends StatelessWidget {
  const CalorieBars({
    super.key,
    required this.days,
    required this.target,
    required this.selected,
    required this.onSelect,
  });

  final List<ProgressDay> days;
  final int target;
  final int? selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    final bool week = days.length <= 7;
    return Column(
      children: [
        SizedBox(
          height: 140,
          width: double.infinity,
          child: RepaintBoundary(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: still ? Duration.zero : BiteMotion.slow,
              curve: BiteMotion.enter,
              builder: (BuildContext context, double t, Widget? child) {
                return CustomPaint(
                  painter: _BarPainter(
                    days: days,
                    target: target,
                    progress: t,
                    selected: selected,
                    today: DateTime.now(),
                  ),
                  child: child,
                );
              },
              child: Row(
                children: [
                  for (int index = 0; index < days.length; index++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onSelect(index),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 22 * MediaQuery.textScalerOf(context).scale(1),
          child: Row(
            children: [
              for (int index = 0; index < days.length; index++)
                Expanded(
                  child: _label(days[index], index, week),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _label(ProgressDay day, int index, bool week) {
    final bool show = week || index == days.length - 1 || index % 5 == 0;
    if (!show) {
      return const SizedBox.shrink();
    }
    final String text = week ? weekdayLetter(day.day) : '${day.day.day}';
    return GestureDetector(
      onTap: () => onSelect(index),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          style: AppTextStyles.caption.copyWith(
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.days,
    required this.target,
    required this.progress,
    required this.selected,
    required this.today,
  });

  final List<ProgressDay> days;
  final int target;
  final double progress;
  final int? selected;
  final DateTime today;

  @override
  void paint(Canvas canvas, Size size) {
    if (days.isEmpty) {
      return;
    }
    double peak = target.toDouble();
    for (final ProgressDay day in days) {
      if (day.eatenKcal > peak) {
        peak = day.eatenKcal.toDouble();
      }
    }
    if (peak < 1) {
      peak = 1;
    }
    final double slot = size.width / days.length;
    final double barWidth = math.min(18, slot * 0.55);
    for (int index = 0; index < days.length; index++) {
      final ProgressDay day = days[index];
      final bool over = target > 0 && day.eatenKcal > target;
      final bool isToday = _sameDay(day.day, today);
      final double height = size.height * (day.eatenKcal / peak) * progress;
      final Rect rect = Rect.fromLTWH(
        index * slot + (slot - barWidth) / 2,
        size.height - height,
        barWidth,
        height,
      );
      final RRect shape = RRect.fromRectAndRadius(rect, const Radius.circular(6));
      final Paint paint = Paint()
        ..color = over
            ? AppColors.clear
            : (isToday ? AppColors.chili : AppColors.chiliAt(0.45))
        ..style = PaintingStyle.fill;
      if (height > 0) {
        canvas.drawRRect(shape, paint);
      }
      if (over && height > 0) {
        canvas.drawRRect(
          shape,
          Paint()
            ..color = AppColors.chili
            ..style = PaintingStyle.stroke
            ..strokeWidth = isToday ? 2.5 : 1.5,
        );
        if (slot >= 16) {
          final double cx = rect.center.dx;
          final double cy = math.max(7.0, rect.top - 8);
          canvas.drawCircle(Offset(cx, cy), 5, Paint()..color = AppColors.card);
          canvas.drawCircle(
            Offset(cx, cy),
            5,
            Paint()
              ..color = AppColors.chili
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1,
          );
          canvas.drawCircle(
            Offset(cx, cy - 1.6),
            0.7,
            Paint()..color = AppColors.chili,
          );
          canvas.drawLine(
            Offset(cx, cy + 0.2),
            Offset(cx, cy + 2.4),
            Paint()
              ..color = AppColors.chili
              ..strokeWidth = 1,
          );
        }
      }
      if (selected == index) {
        canvas.drawRRect(
          shape.inflate(2),
          Paint()
            ..color = AppColors.inkAt(0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }
    if (target > 0) {
      final double y = size.height - size.height * (target / peak) * progress;
      final Paint dash = Paint()
        ..color = AppColors.inkAt(0.45)
        ..strokeWidth = 1;
      for (double x = 0; x < size.width; x += 8) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + 4, size.width), y), dash);
      }
    }
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  bool shouldRepaint(_BarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.selected != selected ||
        oldDelegate.days != days ||
        oldDelegate.target != target;
  }
}

class WeightLine extends StatelessWidget {
  const WeightLine({super.key, required this.points});

  final List<WeightPoint> points;

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      height: 120,
      width: double.infinity,
      child: RepaintBoundary(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: still ? Duration.zero : BiteMotion.slow,
          curve: BiteMotion.enter,
          builder: (BuildContext context, double t, Widget? child) {
            return CustomPaint(
              painter: _LinePainter(points: points, progress: t),
            );
          },
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({required this.points, required this.progress});

  final List<WeightPoint> points;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) {
      return;
    }
    double low = points.first.kg;
    double high = points.first.kg;
    for (final WeightPoint point in points) {
      if (point.kg < low) {
        low = point.kg;
      }
      if (point.kg > high) {
        high = point.kg;
      }
    }
    if (high - low < 0.4) {
      low -= 0.4;
      high += 0.4;
    }
    Offset at(int index) {
      final double x = points.length == 1
          ? size.width / 2
          : size.width * index / (points.length - 1);
      final double y = size.height - ((points[index].kg - low) / (high - low)) * size.height;
      return Offset(x, y.clamp(6, size.height - 6));
    }

    final Path path = Path()..moveTo(at(0).dx, at(0).dy);
    for (int index = 1; index < points.length; index++) {
      path.lineTo(at(index).dx, at(index).dy);
    }
    final Paint line = Paint()
      ..color = AppColors.chili
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final ui.PathMetric metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * progress), line);
    }
    final int last = ((points.length - 1) * progress).round().clamp(0, points.length - 1);
    for (int index = 0; index <= last; index++) {
      final bool end = index == points.length - 1;
      canvas.drawCircle(
        at(index),
        end ? 5 : 3,
        Paint()..color = end ? AppColors.chili : AppColors.chiliAt(0.8),
      );
    }
  }

  @override
  bool shouldRepaint(_LinePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.points != points;
  }
}
