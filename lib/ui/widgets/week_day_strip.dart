import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/format_numbers.dart';
import '../../domain/feature_gate.dart';
import '../../domain/progress_calc.dart';
import 'bite_press.dart';

// How it works: the letter comes from the date, so Monday is always
// the first cell. A future day is dim and does not take a tap.

class WeekDayStrip extends StatelessWidget {
  const WeekDayStrip({
    super.key,
    required this.anchor,
    required this.selected,
    required this.kcalByDay,
    required this.daysWithData,
    required this.premium,
    required this.onDay,
  });

  final DateTime anchor;
  final DateTime? selected;
  final Map<String, int> kcalByDay;
  final Set<String> daysWithData;
  final bool premium;
  final ValueChanged<DateTime> onDay;

  @override
  Widget build(BuildContext context) {
    final DateTime today = dateOnly(DateTime.now());
    final DateTime monday = mondayOf(anchor);
    return Row(
      children: [
        for (int index = 0; index < 7; index++)
          Expanded(
            child: _cell(monday.add(Duration(days: index)), today),
          ),
      ],
    );
  }

  Widget _cell(DateTime day, DateTime today) {
    final String key = progressDayKey(day);
    return DayChip(
      day: day,
      today: today,
      selected: selected != null && sameDay(selected!, day),
      kcal: kcalByDay[key] ?? 0,
      hasData: daysWithData.contains(key),
      premium: premium,
      onDay: onDay,
    );
  }
}

class DayChip extends StatelessWidget {
  const DayChip({
    super.key,
    required this.day,
    required this.today,
    required this.selected,
    required this.kcal,
    required this.hasData,
    required this.premium,
    required this.onDay,
  });

  final DateTime day;
  final DateTime today;
  final bool selected;
  final int kcal;
  final bool hasData;
  final bool premium;
  final ValueChanged<DateTime> onDay;

  @override
  Widget build(BuildContext context) {
    final bool future = dateOnly(day).isAfter(today);
    final bool locked = !future &&
        !premium &&
        !isWithinLastDays(day, today, freeHistoryDays);
    final String spoken = _spoken(future, locked);
    final Color numberInk = selected ? AppColors.card : AppColors.text;
    return Semantics(
      button: !future,
      label: spoken,
      child: BitePress(
        scale: future ? 1 : 0.96,
        child: Opacity(
          opacity: future ? 0.35 : 1,
          child: Material(
            color: AppColors.clear,
            child: InkWell(
              onTap: future
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      onDay(dateOnly(day));
                    },
              customBorder: const CircleBorder(),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      weekdayLetter(day),
                      style: AppTextStyles.caption,
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.text : AppColors.clear,
                        shape: BoxShape.circle,
                        border: !selected && sameDay(day, today)
                            ? Border.all(color: AppColors.text)
                            : null,
                      ),
                      child: FittedBox(
                        child: Text(
                          '${day.day}',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: numberInk,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 8,
                      child: locked
                          ? const Icon(Icons.lock_outline, size: 10, color: AppColors.muted)
                          : hasData
                              ? Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    color: AppColors.chili,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _spoken(bool future, bool locked) {
    final String name = weekdayNames[day.weekday - 1];
    final String month = monthNames[day.month - 1];
    if (future) {
      return '$name ${day.day} $month';
    }
    if (locked) {
      return '$name ${day.day} $month, locked';
    }
    if (kcal > 0) {
      return '$name ${day.day} $month, ${formatNumber(kcal)} kcal logged';
    }
    if (hasData) {
      return '$name ${day.day} $month, logged';
    }
    return '$name ${day.day} $month, nothing logged';
  }
}
