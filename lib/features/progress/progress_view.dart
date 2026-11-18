import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/format_numbers.dart';
import '../../domain/progress_calc.dart';
import '../../domain/progress_report.dart';
import '../../ui/widgets/animated_number.dart';
import '../../ui/widgets/bite_button.dart';
import '../../ui/widgets/bite_card.dart';
import '../../ui/widgets/bite_chip.dart';
import '../../ui/widgets/bite_empty_state.dart';
import '../../ui/widgets/section_header.dart';
import '../../ui/widgets/staggered_entrance.dart';
import '../../ui/widgets/week_day_strip.dart';
import 'progress_charts.dart';

// How it works: the screen is a short stack of cards. Empty days stay in
// the chart as zeros, but the average only uses days with a meal.

class ProgressView extends StatelessWidget {
  const ProgressView({
    super.key,
    required this.report,
    required this.premium,
    required this.range,
    required this.calorieTarget,
    required this.proteinTarget,
    required this.carbTarget,
    required this.fatTarget,
    required this.onRange,
    required this.onLockedRange,
    required this.onLogFood,
    required this.onAddWeight,
    required this.onPremium,
    this.onOpenDay,
    this.onOpenWorkoutDay,
    this.onGenerateSample,
    this.onClearSample,
  });

  final ProgressReport report;
  final bool premium;
  final int range;
  final int calorieTarget;
  final int proteinTarget;
  final int carbTarget;
  final int fatTarget;
  final ValueChanged<int> onRange;
  final VoidCallback onLockedRange;
  final VoidCallback onLogFood;
  final VoidCallback onAddWeight;
  final VoidCallback onPremium;
  final ValueChanged<DateTime>? onOpenDay;
  final ValueChanged<DateTime>? onOpenWorkoutDay;
  final VoidCallback? onGenerateSample;
  final VoidCallback? onClearSample;

  @override
  Widget build(BuildContext context) {
    if (report.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          _Header(
            range: range,
            premium: premium,
            onRange: onRange,
            onLocked: onLockedRange,
          ),
          const SizedBox(height: 48),
          BiteEmptyState(
            emoji: '📈',
            message:
                'Nothing to show yet. Log your first meal and your progress will appear here.',
            actionLabel: 'Log food',
            onAction: onLogFood,
          ),
          ..._debugButtons(),
        ],
      );
    }
    final String insight = progressInsight(
      report: report,
      today: DateTime.now(),
      proteinTarget: proteinTarget.toDouble(),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        StaggeredEntrance(
          index: 0,
          child: _Header(
            range: range,
            premium: premium,
            onRange: onRange,
            onLocked: onLockedRange,
          ),
        ),
        const SizedBox(height: 32),
        StaggeredEntrance(index: 1, child: _Summary(report: report)),
        const SizedBox(height: 32),
        StaggeredEntrance(
          index: 2,
          child: _Calories(
            report: report,
            target: calorieTarget,
            onOpenDay: onOpenDay,
          ),
        ),
        const SizedBox(height: 32),
        StaggeredEntrance(
          index: 3,
          child: _Macros(
            report: report,
            proteinTarget: proteinTarget,
            carbTarget: carbTarget,
            fatTarget: fatTarget,
          ),
        ),
        const SizedBox(height: 32),
        StaggeredEntrance(
          index: 4,
          child: _Weight(report: report, onAdd: onAddWeight),
        ),
        const SizedBox(height: 32),
        StaggeredEntrance(
          index: 5,
          child: _Workouts(
            report: report,
            premium: premium,
            onOpenDay: onOpenWorkoutDay ?? onOpenDay,
          ),
        ),
        const SizedBox(height: 32),
        StaggeredEntrance(
          index: 6,
          child: BiteSurface(
            child: Text(insight, style: AppTextStyles.body),
          ),
        ),
        if (!premium) ...[
          const SizedBox(height: 32),
          StaggeredEntrance(
            index: 7,
            child: BiteSurface(
              child: Material(
                color: AppColors.clear,
                child: InkWell(
                  onTap: onPremium,
                  child: const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Full history and advanced insights',
                          style: AppTextStyles.body,
                        ),
                      ),
                      Text('Locked', style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        ..._debugButtons(),
      ],
    );
  }

  List<Widget> _debugButtons() {
    if (!kDebugMode || onGenerateSample == null) {
      return const <Widget>[];
    }
    return <Widget>[
      const SizedBox(height: 32),
      BiteButton(
        label: 'Generate sample data (debug)',
        filled: false,
        onPressed: onGenerateSample,
      ),
      const SizedBox(height: 8),
      BiteButton(
        label: 'Clear sample data',
        filled: false,
        onPressed: onClearSample,
      ),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.range,
    required this.premium,
    required this.onRange,
    required this.onLocked,
  });

  final int range;
  final bool premium;
  final ValueChanged<int> onRange;
  final VoidCallback onLocked;

  @override
  Widget build(BuildContext context) {
    final String title = range == 30 ? 'Last 30 days' : 'Your week';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('YOUR PROGRESS', style: AppTextStyles.eyebrow),
        const SizedBox(height: 8),
        Text(title, style: AppTextStyles.appHeading),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            BiteChip(
              label: '7 days',
              selected: range != 30,
              onTap: () => onRange(7),
            ),
            BiteChip(
              label: '30 days',
              selected: range == 30 && premium,
              onTap: () {
                if (premium) {
                  onRange(30);
                } else {
                  onLocked();
                }
              },
            ),
            if (!premium)
              const Icon(Icons.lock_outline, size: 18, color: AppColors.muted),
          ],
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.report});

  final ProgressReport report;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _stat(
            'Avg / day',
            AnimatedNumber(
              value: report.averageCalories,
              style: AppTextStyles.sectionHeading,
            ),
            'logged days',
          ),
        ),
        Container(width: 1, height: 48, color: AppColors.hairline),
        Expanded(
          child: _stat(
            'On target',
            Text(
              '${report.daysOnTarget} / ${report.days.length}',
              style: AppTextStyles.sectionHeading.copyWith(
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
            'within 10%',
          ),
        ),
        Container(width: 1, height: 48, color: AppColors.hairline),
        Expanded(
          child: _stat(
            'Streak',
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.local_fire_department,
                  color: AppColors.chili,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '${report.streak}',
                    style: AppTextStyles.sectionHeading,
                  ),
                ),
              ],
            ),
            'Best ${report.bestStreak}',
          ),
        ),
      ],
    );
  }

  Widget _stat(String label, Widget value, String note) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          value,
          const SizedBox(height: 4),
          Text(note, style: AppTextStyles.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _Calories extends StatefulWidget {
  const _Calories({
    required this.report,
    required this.target,
    required this.onOpenDay,
  });

  final ProgressReport report;
  final int target;
  final ValueChanged<DateTime>? onOpenDay;

  @override
  State<_Calories> createState() => _CaloriesState();
}

class _CaloriesState extends State<_Calories> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final bool over = widget.report.days.any(
      (ProgressDay day) => widget.target > 0 && day.eatenKcal > widget.target,
    );
    final int? selected = _selected != null && _selected! < widget.report.days.length
        ? _selected
        : null;
    final ProgressDay? picked = selected == null ? null : widget.report.days[selected];
    return BiteSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(child: SectionHeader(label: 'Calories')),
              if (over) ...<Widget>[
                const Tooltip(
                  message: 'Outlined bars are over the target.',
                  child: Icon(Icons.info_outline, size: 18, color: AppColors.muted),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                'Target ${formatNumber(widget.target)}',
                style: AppTextStyles.caption,
                textAlign: TextAlign.right,
                maxLines: 1,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Average skips days with no meal.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 16),
          if (picked != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${formatNumber(picked.eatenKcal)} eaten · ${formatNumber(picked.burnedKcal)} burned · ${formatNumber(picked.netKcal)} net',
                style: AppTextStyles.caption.copyWith(
                  fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
            ),
          CalorieBars(
            days: widget.report.days,
            target: widget.target,
            selected: selected,
            onSelect: (int index) {
              setState(() {
                _selected = selected == index ? null : index;
              });
              final ValueChanged<DateTime>? open = widget.onOpenDay;
              if (open != null) {
                open(dateOnly(widget.report.days[index].day));
              }
            },
          ),
        ],
      ),
    );
  }
}

class _Macros extends StatelessWidget {
  const _Macros({
    required this.report,
    required this.proteinTarget,
    required this.carbTarget,
    required this.fatTarget,
  });

  final ProgressReport report;
  final int proteinTarget;
  final int carbTarget;
  final int fatTarget;

  @override
  Widget build(BuildContext context) {
    return BiteSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(label: 'Macros'),
          const SizedBox(height: 8),
          const Text(
            'Average of days you logged.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 16),
          _bar('Protein', report.averageProtein, proteinTarget, AppColors.success),
          const SizedBox(height: 12),
          _bar('Carbs', report.averageCarbs, carbTarget, AppColors.chiliAt(0.55)),
          const SizedBox(height: 12),
          _bar('Fat', report.averageFat, fatTarget, AppColors.inkAt(0.45)),
        ],
      ),
    );
  }

  Widget _bar(String label, double grams, int target, Color color) {
    final double fraction = target <= 0 ? 0 : (grams / target).clamp(0, 1);
    final String percent = target <= 0 ? '—' : '${(grams / target * 100).round()}%';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: AppTextStyles.body),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '${grams.round()} g · $percent',
                textAlign: TextAlign.right,
                style: AppTextStyles.caption.copyWith(
                  fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: fraction.toDouble(),
            minHeight: 6,
            backgroundColor: AppColors.progressTrack,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _Weight extends StatelessWidget {
  const _Weight({required this.report, required this.onAdd});

  final ProgressReport report;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final List<WeightPoint> points = report.weights;
    return BiteSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(label: 'Weight'),
          const SizedBox(height: 12),
          if (points.length < 2)
            const Text(
              'Add your weight to start your trend.',
              style: AppTextStyles.body,
            )
          else ...[
            Text(
              '${points.last.kg.toStringAsFixed(1)} kg',
              style: AppTextStyles.number.copyWith(
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
            Text(
              _change(points),
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 12),
            WeightLine(points: points),
          ],
          const SizedBox(height: 12),
          BiteButton(label: 'Add weight', onPressed: onAdd),
        ],
      ),
    );
  }

  String _change(List<WeightPoint> points) {
    final double delta = points.last.kg - points.first.kg;
    final String sign = delta > 0 ? '+' : '';
    return '$sign${delta.toStringAsFixed(1)} kg vs the start of this range';
  }
}

class _Workouts extends StatelessWidget {
  const _Workouts({
    required this.report,
    required this.premium,
    required this.onOpenDay,
  });

  final ProgressReport report;
  final bool premium;
  final ValueChanged<DateTime>? onOpenDay;

  @override
  Widget build(BuildContext context) {
    final Set<String> done = <String>{
      for (final ProgressDay row in report.days)
        if (row.workouts > 0) progressDayKey(row.day),
    };
    return BiteSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(label: 'Workouts'),
          const SizedBox(height: 12),
          WeekDayStrip(
            anchor: DateTime.now(),
            selected: dateOnly(DateTime.now()),
            kcalByDay: const <String, int>{},
            daysWithData: done,
            premium: premium,
            onDay: (DateTime day) => onOpenDay?.call(day),
          ),
          const SizedBox(height: 16),
          Text(
            '${report.workoutSessions} sessions · ${report.workoutMinutes} min · ${formatNumber(report.burnedTotal)} kcal',
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}
