import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

// How it works: the logo is drawn, not an image file. A yellow ring
// sits around a white plate, and four dots stand in for food.

class PlateLogo extends StatelessWidget {
  const PlateLogo({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: const _PlatePainter(),
    );
  }
}

class _PlatePainter extends CustomPainter {
  const _PlatePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.width / 2;
    final Paint halo = Paint()..color = AppColors.baingan.withValues(alpha: 0.45);
    canvas.drawCircle(center, radius * 0.92, halo);
    final Paint ring = Paint()
      ..color = AppColors.haldi
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.14;
    canvas.drawCircle(center, radius * 0.62, ring);
    final Paint plate = Paint()..color = AppColors.card;
    canvas.drawCircle(center, radius * 0.48, plate);
    _dot(canvas, center, radius, -0.6, -0.15, 0.12, AppColors.haldiText);
    _dot(canvas, center, radius, 0.35, -0.2, 0.1, AppColors.chili);
    _dot(canvas, center, radius, 0.15, 0.35, 0.11, AppColors.haldi);
    _dot(canvas, center, radius, -0.25, 0.28, 0.07, AppColors.baingan);
  }

  void _dot(
    Canvas canvas,
    Offset center,
    double radius,
    double dx,
    double dy,
    double scale,
    Color color,
  ) {
    canvas.drawCircle(
      center + Offset(dx * radius, dy * radius),
      radius * scale,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Full-width goal row. Selected rows are chili with a tick.
class GoalPill extends StatelessWidget {
  const GoalPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? AppColors.chili : AppColors.card.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(100),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(100),
          child: SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.card,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (selected) const Icon(Icons.check, color: AppColors.card),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
