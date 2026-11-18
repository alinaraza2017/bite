import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/meals.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/format_numbers.dart';
import '../../data/bite_repos.dart';
import '../../data/models/day_detail.dart';
import '../../data/models/gym_models.dart';
import '../../data/models/logged_food.dart';
import '../../data/repositories/progress_repository.dart';
import '../../domain/progress_calc.dart';
import '../../ui/widgets/animated_number.dart';
import '../../ui/widgets/bite_button.dart';
import '../../ui/widgets/bite_empty_state.dart';
import '../../ui/widgets/emoji_tile.dart';
import '../../ui/widgets/section_header.dart';
import '../../widgets/bite_back_button.dart';
import '../onboarding/profile_provider.dart';

// How it works: the sheet reads one day, then listens for saves.
// A swipe on a meal uses the same delete and undo as the daily log.

const List<String> _sheetMeals = <String>[
  'breakfast',
  'lunch',
  'dinner',
  'snacks',
];

Future<void> showDayDetail(
  BuildContext context,
  DateTime date, {
  bool workoutsFirst = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (BuildContext sheet) {
      return DayDetailSheet(date: dateOnly(date), workoutsFirst: workoutsFirst);
    },
  );
}

class DayDetailSheet extends StatefulWidget {
  const DayDetailSheet({
    super.key,
    required this.date,
    required this.workoutsFirst,
  });

  final DateTime date;
  final bool workoutsFirst;

  @override
  State<DayDetailSheet> createState() => _DayDetailSheetState();
}

class _DayDetailSheetState extends State<DayDetailSheet> {
  DayDetail? _detail;
  bool _started = false;
  bool _scrolled = false;
  final GlobalKey _workoutsKey = GlobalKey();
  BiteRepos? _repos;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    _repos = context.read<BiteRepos?>();
    _repos?.logs.addOnChanged(_reload);
    _repos?.workouts.addOnChanged(_reload);
    _reload();
  }

  @override
  void dispose() {
    _repos?.logs.removeOnChanged(_reload);
    _repos?.workouts.removeOnChanged(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    final BiteRepos? repos = _repos;
    if (repos == null) {
      if (mounted) {
        setState(() => _detail = DayDetail.empty(widget.date));
      }
      return;
    }
    final DayDetail detail = await ProgressRepository(repos.database).getDayDetail(widget.date);
    if (!mounted) {
      return;
    }
    setState(() => _detail = detail);
    if (widget.workoutsFirst && !_scrolled) {
      _scrolled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final BuildContext? target = _workoutsKey.currentContext;
        if (target != null) {
          Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 250));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final DayDetail? detail = _detail;
    final int target = context.watch<ProfileProvider>().targets?.calorieTarget ?? 0;
    final double height = MediaQuery.sizeOf(context).height * 0.86;
    return SafeArea(
      child: SizedBox(
        height: height,
        child: detail == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Center(
                    child: SizedBox(
                      width: 36,
                      height: 4,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.hairline,
                          borderRadius: const BorderRadius.all(Radius.circular(100)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _heading(detail.day)),
                      BiteBackButton(close: true, onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (detail.isEmpty)
                    BiteEmptyState(
                      emoji: '🍽️',
                      message: 'Nothing logged on ${formatDay(detail.day)}',
                      actionLabel: 'Log food for this day',
                      onAction: () => _logFood(detail.day),
                    )
                  else ...[
                    _summary(detail, target),
                    const SizedBox(height: 20),
                    _foods(detail),
                    const SizedBox(height: 16),
                    _workouts(detail),
                    if (detail.weightKg != null) ...[
                      const SizedBox(height: 16),
                      SectionHeader(label: 'Weight'),
                      Text(
                        '${detail.weightKg!.toStringAsFixed(1)} kg',
                        style: AppTextStyles.sectionHeading,
                      ),
                    ],
                    const SizedBox(height: 16),
                    BiteButton(
                      label: 'Log food for this day',
                      onPressed: () => _logFood(detail.day),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _heading(DateTime day) {
    final bool today = sameDay(day, DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(weekdayNames[day.weekday - 1].toUpperCase(), style: AppTextStyles.eyebrow),
        const SizedBox(height: 4),
        Row(
          children: [
            Flexible(
              child: Text(
                formatDay(day),
                style: AppTextStyles.appHeading,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (today) ...[
              const SizedBox(width: 8),
              const Text('Today', style: AppTextStyles.caption),
            ],
          ],
        ),
      ],
    );
  }

  Widget _summary(DayDetail detail, int target) {
    return Row(
      children: [
        _stat('Eaten', detail.eatenKcal),
        _line(),
        _stat('Target', target),
        _line(),
        _stat('Burned', detail.burnedKcal),
        _line(),
        _stat('Net', detail.netKcal),
      ],
    );
  }

  Widget _line() {
    return Container(width: 1, height: 36, color: AppColors.hairline);
  }

  Widget _stat(String label, int value) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: AppTextStyles.caption),
          AnimatedNumber(value: value, style: AppTextStyles.sectionHeading),
        ],
      ),
    );
  }

  Widget _foods(DayDetail detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final String meal in _sheetMeals) _meal(meal, detail.foods),
      ],
    );
  }

  Widget _meal(String meal, List<LoggedFood> foods) {
    final List<LoggedFood> rows = foods.where((LoggedFood row) => row.meal == meal).toList();
    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }
    final int total = rows.fold(0, (int sum, LoggedFood row) => sum + row.calories);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: SectionHeader(label: mealLabel(meal))),
              Text('$total kcal', style: AppTextStyles.caption),
            ],
          ),
          for (final LoggedFood row in rows) _foodRow(row),
        ],
      ),
    );
  }

  Widget _foodRow(LoggedFood row) {
    return Dismissible(
      key: ValueKey<int>(row.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: AppColors.chiliAt(0.15),
        child: const Text('Delete'),
      ),
      confirmDismiss: (DismissDirection direction) async {
        await _delete(row);
        return false;
      },
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: EmojiTile(emoji: row.emoji),
        title: Text(row.foodName, style: AppTextStyles.body),
        subtitle: Text(_portion(row), style: AppTextStyles.caption),
        trailing: Text('${row.calories}', style: AppTextStyles.body),
        onTap: () {
          final String date = progressDayKey(widget.date);
          context.push('/food/${row.foodId}?meal=${row.meal}&logId=${row.id}&date=$date');
        },
      ),
    );
  }

  String _portion(LoggedFood row) {
    final String qty = row.quantity == row.quantity.roundToDouble()
        ? '${row.quantity.round()}'
        : row.quantity.toStringAsFixed(1);
    final String? tadka = row.tadka;
    final String oil = tadka == null || tadka.isEmpty
        ? ''
        : ' · ${tadka[0].toUpperCase()}${tadka.substring(1)} oil';
    return '1 ${row.unitLabel} x $qty$oil';
  }

  Future<void> _delete(LoggedFood row) async {
    final BiteRepos? repos = _repos;
    if (repos == null) {
      return;
    }
    final LoggedFood? removed = await repos.logs.deleteLog(row.id);
    if (!mounted || removed == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted ${removed.foodName}'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await repos.logs.restoreLog(removed);
          },
        ),
      ),
    );
  }

  Widget _workouts(DayDetail detail) {
    return Column(
      key: _workoutsKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(label: 'Workouts'),
        if (detail.workouts.isEmpty)
          const Text('No workout this day.', style: AppTextStyles.caption)
        else
          for (final DayWorkoutDetail workout in detail.workouts) _workout(workout),
      ],
    );
  }

  Widget _workout(DayWorkoutDetail workout) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(workout.session.name, style: AppTextStyles.body),
      subtitle: Text(_sets(workout.sets), style: AppTextStyles.caption),
      trailing: Text(
        '${workout.session.burnedKcal.round()} kcal',
        style: AppTextStyles.caption,
      ),
      onTap: () => context.push('/workout/summary/${workout.session.id}'),
    );
  }

  String _sets(List<SessionSet> sets) {
    if (sets.isEmpty) {
      return 'No sets';
    }
    final SessionSet first = sets.first;
    if (first.minutes > 0) {
      return '${sets.length} x ${first.minutes} min';
    }
    return '${sets.length} sets · ${first.weightKg.round()} kg x ${first.reps}';
  }

  void _logFood(DateTime day) {
    final String key = progressDayKey(day);
    final GoRouter router = GoRouter.of(context);
    Navigator.pop(context);
    router.go('/food?date=$key');
  }
}
