import 'package:flutter/material.dart';

/// Palette from the mockups. Feature screens use these names, not raw hex.
class AppColors {
  AppColors._();

  static const Color chili = Color(0xFFFF4D2E);
  static const Color haldi = Color(0xFFFFB703);
  static const Color baingan = Color(0xFF2A1B3D);
  static const Color violet = Color(0xFF7C5CFC);
  static const Color background = Color(0xFFFFF7F0);
  static const Color card = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF22172F);
  static const Color muted = Color(0xFF7A6F86);
  static const Color success = Color(0xFF12B76A);
  static const Color warning = Color(0xFFF79009);
  static const Color error = Color(0xFFE5383B);

  /// Dark card ends at this purple. Dark screens fade through mid into plum.
  static const Color cardGradientEnd = Color(0xFF4E2A63);
  static const Color screenGradientMid = Color(0xFF4A2A6A);
  static const Color screenGradientEnd = Color(0xFF7A2F5C);
  static const Color workoutGradientEnd = Color(0xFFFF8A1F);

  /// Kept so older theme code still compiles.
  static const Color heroEnd = cardGradientEnd;
  static const Color splashEnd = screenGradientEnd;
  static const Color chiliGradientEnd = workoutGradientEnd;

  /// Protein, carbs, and fat. The word is still shown next to the colour.
  static const Color protein = chili;
  static const Color carbs = haldi;
  static const Color fat = violet;

  /// Carbs tag text. Darker than the haldi bar so it stays readable.
  static const Color haldiText = Color(0xFF9A6700);

  static const Color chiliTint = Color(0xFFFFE8E2);
  static const Color haldiTint = Color(0xFFFFF3D6);
  static const Color violetTint = Color(0xFFEEEAFB);
  static const Color progressTrack = Color(0xFFF1E9E1);
  static const Color line = Color(0x1A2A1B3D);
  static const Color track = progressTrack;
  static const Color scrim = Color(0x992A1B3D);

  /// No hue. Stops Material from painting a tint of its own.
  static const Color clear = Color(0x00000000);

  /// Ink and chili at a chosen strength. Same hues, only more transparent.
  static Color inkAt(double opacity) => text.withValues(alpha: opacity);

  static Color chiliAt(double opacity) => chili.withValues(alpha: opacity);

  /// Cream pulled 4% toward ink. Still the cream hue.
  static Color get creamDeep =>
      Color.alphaBlend(text.withValues(alpha: 0.04), background);

  /// Hairline. A little stronger than [line], still the ink hue.
  static Color get hairline => text.withValues(alpha: 0.12);

  static Color get inkMuted => text.withValues(alpha: 0.60);

  static List<BoxShadow> get ambientShadow => <BoxShadow>[
        BoxShadow(
          color: text.withValues(alpha: 0.05),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
}
