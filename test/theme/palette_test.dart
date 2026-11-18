import 'package:flutter_test/flutter_test.dart';

import 'package:bite/core/theme/app_colors.dart';

void main() {
  test('palette matches the mockup colours', () {
    expect(AppColors.chili.toARGB32(), 0xFFFF4D2E);
    expect(AppColors.haldi.toARGB32(), 0xFFFFB703);
    expect(AppColors.baingan.toARGB32(), 0xFF2A1B3D);
    expect(AppColors.violet.toARGB32(), 0xFF7C5CFC);
    expect(AppColors.background.toARGB32(), 0xFFFFF7F0);
    expect(AppColors.card.toARGB32(), 0xFFFFFFFF);
    expect(AppColors.text.toARGB32(), 0xFF22172F);
    expect(AppColors.muted.toARGB32(), 0xFF7A6F86);
    expect(AppColors.success.toARGB32(), 0xFF12B76A);
    expect(AppColors.warning.toARGB32(), 0xFFF79009);
    expect(AppColors.error.toARGB32(), 0xFFE5383B);
  });

  test('tints stay on the same hues', () {
    expect(AppColors.chiliTint.toARGB32(), 0xFFFFE8E2);
    expect(AppColors.haldiTint.toARGB32(), 0xFFFFF3D6);
    expect(AppColors.violetTint.toARGB32(), 0xFFEEEAFB);
    expect(AppColors.track.toARGB32(), 0xFFF1E9E1);
    expect(AppColors.line.a, closeTo(0.10, 0.01));
    expect(AppColors.protein, AppColors.chili);
    expect(AppColors.carbs, AppColors.haldi);
    expect(AppColors.fat, AppColors.violet);
  });
}
