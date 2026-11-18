import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/bite_spacing.dart';
import '../../core/theme/bite_text.dart';

/// Scroll wheel for age, height, or weight. No keyboard.
class NumberWheel extends StatefulWidget {
  const NumberWheel({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onChanged,
  });

  final List<int> values;
  final int selected;
  final String label;
  final ValueChanged<int> onChanged;

  @override
  State<NumberWheel> createState() => _NumberWheelState();
}

class _NumberWheelState extends State<NumberWheel> {
  late final FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    final int index = widget.values.indexOf(widget.selected);
    _controller = FixedExtentScrollController(
      initialItem: index < 0 ? 0 : index,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(widget.label, style: BiteText.label),
        const SizedBox(height: BiteSpacing.xs),
        Expanded(
          child: ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: 40,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (int index) {
              widget.onChanged(widget.values[index]);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: widget.values.length,
              builder: (BuildContext context, int index) {
                final int value = widget.values[index];
                final bool selected = value == widget.selected;
                return Center(
                  child: Text(
                    '$value',
                    style: BiteText.title.copyWith(
                      color: selected ? AppColors.chili : AppColors.text,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
