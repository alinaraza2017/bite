import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

// How it works: the label is dark text inside the white box, above the number.
// The unit sits on the right of the number. Nothing floats on the page behind it.

class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType,
    this.obscure = false,
    this.onLight = false,
    this.hint,
    this.suffix,
    this.error,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscure;

  /// True on a light page, so the white box gets a border.
  final bool onLight;
  final String? hint;
  final String? suffix;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final bool bad = error != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: bad
                    ? AppColors.error
                    : (onLight ? AppColors.line : AppColors.card),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            inputDecorationTheme: const InputDecorationTheme(
                              filled: false,
                              isDense: true,
                              floatingLabelBehavior: FloatingLabelBehavior.never,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                          ),
                          child: TextField(
                            controller: controller,
                            keyboardType: keyboardType,
                            obscureText: obscure,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                            cursorColor: AppColors.chili,
                            decoration: InputDecoration(
                              isCollapsed: true,
                              isDense: true,
                              filled: false,
                              hintText: hint,
                              hintStyle: const TextStyle(
                                color: AppColors.muted,
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              floatingLabelBehavior: FloatingLabelBehavior.never,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (suffix != null)
                        Text(
                          suffix!,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (bad)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                error!,
                style: const TextStyle(
                  color: AppColors.error,
                  fontFamily: 'Poppins',
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
