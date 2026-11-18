import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/meals.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/format_numbers.dart';
import '../../core/widgets/bite_card.dart';
import '../../data/bite_repos.dart';
import '../../data/models/logged_food.dart';
import '../../domain/feature_gate.dart';
import '../../domain/progress_calc.dart';
import '../../widgets/bite_back_button.dart';
import '../day/open_day.dart';
import '../onboarding/profile_provider.dart';

// How it works: the same log table feeds Home. Swipe right to edit,
// swipe left to delete. Undo puts the row back.

class DailyLogScreen extends StatefulWidget {
  const DailyLogScreen({super.key, this.initialDay});

  final DateTime? initialDay;

  @override
  State<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends State<DailyLogScreen> {
  late DateTime _day = dateOnly(widget.initialDay ?? DateTime.now());
  List<LoggedFood> _rows = <LoggedFood>[];
  bool _ready = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final BiteRepos? repos = context.read<BiteRepos?>();
    if (repos == null) {
      return;
    }
    final List<LoggedFood> rows = await repos.logs.foodsForDate(
      progressDayKey(_day),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _rows = rows;
      _ready = true;
    });
  }

  Future<void> _shift(int days) async {
    final DateTime next = _day.add(Duration(days: days));
    final DateTime today = dateOnly(DateTime.now());
    if (next.isAfter(today)) {
      return;
    }
    final bool premium =
        context.read<ProfileProvider>().profile?.isPremium ?? false;
    final bool inFreeWeek = isWithinLastDays(next, today, freeHistoryDays);
    final bool fullHistory = FeatureGate(isPremium: premium).canUse(Feature.fullHistory);
    if (!inFreeWeek && !fullHistory) {
      if (!mounted) {
        return;
      }
      context.push('/premium');
      return;
    }
    setState(() {
      _day = next;
      _ready = false;
    });
    await _load();
  }

  Future<void> _delete(LoggedFood row) async {
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialog) {
        return AlertDialog(
          content: Text('Delete ${row.foodName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Keep'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (yes != true || !mounted) {
      return;
    }
    final BiteRepos repos = context.read<BiteRepos?>()!;
    final LoggedFood? removed = await repos.logs.deleteLog(row.id);
    await _load();
    if (!mounted || removed == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await repos.logs.restoreLog(removed);
            _load();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int eaten = _rows.fold(0, (int sum, LoggedFood row) => sum + row.calories);
    final int target =
        context.watch<ProfileProvider>().targets?.calorieTarget ?? 0;
    final int left = target - eaten;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _ready
            ? ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  const BiteBackButton(),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Today',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.appHeading,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _shift(-1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Flexible(
                        child: GestureDetector(
                          onTap: () => handleDayTap(context, _day),
                          child: Text(
                            formatDay(_day),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _shift(1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  BiteCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _stat('Eaten', formatNumber(eaten)),
                        _stat('Target', formatNumber(target)),
                        _stat(
                          left < 0 ? 'Over' : 'Left',
                          formatNumber(left.abs()),
                          color: left < 0 ? AppColors.warning : AppColors.success,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final String meal in mealIds) _meal(meal),
                  const Text(
                    'Swipe a food to edit or delete',
                    style: AppTextStyles.caption,
                  ),
                ],
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _stat(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.caption),
        Text(
          value,
          style: AppTextStyles.sectionHeading.copyWith(color: color),
        ),
      ],
    );
  }

  Widget _meal(String meal) {
    final List<LoggedFood> rows = _rows
        .where((LoggedFood row) => row.meal == meal)
        .toList();
    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }
    final int total = rows.fold(0, (int sum, LoggedFood row) => sum + row.calories);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BiteCard(
        child: Column(
          children: [
            Row(
              children: [
                Text(mealLabel(meal), style: AppTextStyles.sectionHeading),
                const Spacer(),
                Text(
                  '$total kcal',
                  style: AppTextStyles.sectionHeading.copyWith(
                    color: AppColors.chili,
                  ),
                ),
              ],
            ),
            for (final LoggedFood row in rows)
              Dismissible(
                key: ValueKey<int>(row.id),
                background: Container(
                  color: AppColors.baingan,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 16),
                  child: const Text('Edit', style: TextStyle(color: Colors.white)),
                ),
                secondaryBackground: Container(
                  color: AppColors.error,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Text('Delete', style: TextStyle(color: Colors.white)),
                ),
                confirmDismiss: (DismissDirection direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    final String date = progressDayKey(_day);
                    context.push(
                      '/food/${row.foodId}?meal=${row.meal}&logId=${row.id}&date=$date',
                    );
                    return false;
                  }
                  await _delete(row);
                  return false;
                },
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_line(row), style: AppTextStyles.body),
                  trailing: Text(
                    '${row.calories} kcal',
                    style: AppTextStyles.caption,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _line(LoggedFood row) {
    final String qty = row.quantity == row.quantity.roundToDouble()
        ? row.quantity.round().toString()
        : row.quantity.toStringAsFixed(1);
    final String oil = !row.hasTadka || row.tadka == null || row.tadka == 'medium'
        ? ''
        : ' (${row.tadka![0].toUpperCase()}${row.tadka!.substring(1)})';
    return '${row.foodName}$oil, $qty ${row.unitLabel}';
  }
}
