import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'bite_spacing.dart';
import 'bite_text.dart';

/// Light theme only. Built by hand so Material does not invent extra hues.
class BiteTheme {
  BiteTheme._();

  static ThemeData get light {
    final ColorScheme colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.chili,
      onPrimary: AppColors.background,
      primaryContainer: AppColors.chiliTint,
      onPrimaryContainer: AppColors.text,
      secondary: AppColors.success,
      onSecondary: AppColors.background,
      secondaryContainer: AppColors.haldiTint,
      onSecondaryContainer: AppColors.text,
      // Tertiary is ink so Material has no third accent colour.
      tertiary: AppColors.text,
      onTertiary: AppColors.background,
      tertiaryContainer: AppColors.muted,
      onTertiaryContainer: AppColors.text,
      // Warnings use orange, not red. The spec forbids a fifth hue.
      error: AppColors.chili,
      onError: AppColors.background,
      errorContainer: AppColors.chiliTint,
      onErrorContainer: AppColors.text,
      surface: AppColors.background,
      onSurface: AppColors.text,
      surfaceDim: AppColors.background,
      surfaceBright: AppColors.background,
      surfaceContainerLowest: AppColors.background,
      surfaceContainerLow: AppColors.background,
      surfaceContainer: AppColors.background,
      surfaceContainerHigh: AppColors.background,
      surfaceContainerHighest: AppColors.background,
      onSurfaceVariant: AppColors.text,
      outline: AppColors.line,
      outlineVariant: AppColors.line,
      shadow: AppColors.text,
      scrim: AppColors.scrim,
      inverseSurface: AppColors.text,
      onInverseSurface: AppColors.background,
      inversePrimary: AppColors.chiliTint,
      surfaceTint: AppColors.clear,
    );

    const TextTheme textTheme = TextTheme(
      displaySmall: BiteText.display,
      titleLarge: BiteText.title,
      bodyLarge: BiteText.body,
      bodyMedium: BiteText.body,
      labelLarge: BiteText.label,
      labelMedium: BiteText.label,
      labelSmall: BiteText.label,
    );

    final OutlineInputBorder outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(BiteRadius.card),
      borderSide: BorderSide(color: AppColors.line),
    );
    const BorderSide primarySide = BorderSide(
      color: AppColors.chili,
      width: 2,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      fontFamily: BiteText.family,
      textTheme: textTheme,
      splashColor: AppColors.track,
      highlightColor: AppColors.track,
      dividerColor: AppColors.line,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: AppColors.clear,
        titleTextStyle: BiteText.title,
      ),
      cardTheme: CardThemeData(
        color: AppColors.background,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BiteRadius.card),
          side: BorderSide(color: AppColors.line),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.background,
        elevation: 0,
        indicatorColor: AppColors.chili,
        surfaceTintColor: AppColors.clear,
        iconTheme: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          final bool selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.background : AppColors.text,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((
          Set<WidgetState> states,
        ) {
          final bool selected = states.contains(WidgetState.selected);
          final Color color = selected ? AppColors.chili : AppColors.text;
          return BiteText.label.copyWith(color: color);
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.chili,
          foregroundColor: AppColors.background,
          disabledBackgroundColor: AppColors.chiliTint,
          disabledForegroundColor: AppColors.text,
          minimumSize: const Size(48, 48),
          textStyle: BiteText.label,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BiteRadius.card),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.background,
        selectedColor: AppColors.chiliTint,
        disabledColor: AppColors.background,
        shadowColor: AppColors.text,
        selectedShadowColor: AppColors.text,
        surfaceTintColor: AppColors.clear,
        labelStyle: BiteText.label,
        secondaryLabelStyle: BiteText.label,
        side: BorderSide(color: AppColors.line),
        shape: const StadiumBorder(),
        elevation: 0,
        pressElevation: 0,
        showCheckmark: false,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.text,
        contentTextStyle: BiteText.body.copyWith(color: AppColors.background),
        actionTextColor: AppColors.background,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        floatingLabelBehavior: FloatingLabelBehavior.never,
        labelStyle: BiteText.label,
        hintStyle: BiteText.body,
        enabledBorder: outline,
        focusedBorder: outline.copyWith(borderSide: primarySide),
        errorBorder: outline.copyWith(
          borderSide: const BorderSide(color: AppColors.chili),
        ),
        focusedErrorBorder: outline.copyWith(borderSide: primarySide),
      ),
    );
  }
}
