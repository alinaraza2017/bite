import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/bite_spacing.dart';
import '../../core/theme/bite_text.dart';

// How it works: the label sits above the box. The border is a hairline
// until the field is focused, then it turns chili. The unit stays on the right.
// On ink pages the caption is cream so it stays readable above the white box.

class BiteLabeledField extends StatefulWidget {
  const BiteLabeledField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.suffix,
    this.error,
    this.keyboardType,
    this.obscure = false,
    this.onInk = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? suffix;
  final String? error;
  final TextInputType? keyboardType;
  final bool obscure;

  /// True on the aubergine pages, so the caption above the box is cream.
  final bool onInk;

  @override
  State<BiteLabeledField> createState() => _BiteLabeledFieldState();
}

class _BiteLabeledFieldState extends State<BiteLabeledField> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool bad = widget.error != null;
    final Color border = bad
        ? AppColors.error
        : (_focus.hasFocus ? AppColors.chili : AppColors.hairline);
    return Padding(
      padding: const EdgeInsets.only(bottom: BiteSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: BiteText.label.copyWith(
              color: widget.onInk ? AppColors.card : AppColors.text,
            ),
          ),
          const SizedBox(height: BiteSpacing.xs),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(BiteRadius.card),
              border: Border.all(color: border),
            ),
            child: Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: const InputDecorationTheme(
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                floatingLabelBehavior: FloatingLabelBehavior.never,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: BiteSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focus,
                      keyboardType: widget.keyboardType,
                      obscureText: widget.obscure,
                      style: BiteText.body,
                      cursorColor: AppColors.chili,
                      decoration: InputDecoration(
                        hintText: widget.hint,
                        isCollapsed: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: BiteSpacing.md,
                        ),
                      ),
                    ),
                  ),
                  if (widget.suffix != null)
                    Text(widget.suffix!, style: BiteText.caption),
                ],
              ),
            ),
          ),
          ),
          if (bad)
            Padding(
              padding: const EdgeInsets.only(top: BiteSpacing.xxs),
              child: Text(
                widget.error!,
                style: BiteText.caption.copyWith(color: AppColors.error),
              ),
            ),
        ],
      ),
    );
  }
}
