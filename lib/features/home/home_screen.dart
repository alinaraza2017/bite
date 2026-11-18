import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/utils/format_numbers.dart';
import '../../data/bite_repos.dart';
import '../../data/models/day_detail.dart';
import '../../domain/models.dart';
import '../../domain/progress_calc.dart';
import '../../ui/widgets/bite_button.dart';
import '../../ui/widgets/bite_chip.dart';
import '../../ui/widgets/bite_empty_state.dart';
import '../../ui/widgets/section_header.dart';
import '../../ui/widgets/staggered_entrance.dart';
import '../../ui/widgets/week_day_strip.dart';
import '../day/open_day.dart';
import '../onboarding/profile_provider.dart';
import 'day_board.dart';
import 'home_header.dart';
import 'home_meals.dart';
import 'home_ring.dart';

// How it works: DayBoard already loaded today. This screen only draws it.
// kcal left is the target minus what was eaten.

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final BiteRepos? repos = context.watch<BiteRepos?>();
    if (repos == null) {
      return const Center(child: Text('Home', style: AppTextStyles.heading));
    }
    final DayBoard board = context.watch<DayBoard>();
    if (!board.ready) {
      return const Center(child: CircularProgressIndicator());
    }
    if (board.error != null && board.foods.isEmpty) {
      return BiteEmptyState(
        emoji: '🍽️',
        message: 'Could not load today.',
        actionLabel: 'Try again',
        onAction: board.reload,
      );
    }
    final UserProfile? profile = context.watch<ProfileProvider>().profile;
    final int target = context.watch<ProfileProvider>().targets?.calorieTarget ?? 0;
    final int eaten = board.eaten.kcal.round();
    final int left = target - eaten;
    final bool viewingToday = sameDay(board.day, DateTime.now());
    final bool premium = profile?.isPremium ?? false;
    final Map<String, int> kcal = <String, int>{
      for (final MapEntry<String, DayMark> mark in board.marks.entries)
        mark.key: mark.value.eatenKcal,
    };
    return Stack(
      children: [
        GestureDetector(
          onHorizontalDragEnd: (DragEndDetails details) {
            final double speed = details.primaryVelocity ?? 0;
            if (speed > 250) {
              handleDayTap(context, board.day.subtract(const Duration(days: 1)), selectOnly: true);
            } else if (speed < -250) {
              handleDayTap(context, board.day.add(const Duration(days: 1)), selectOnly: true);
            }
          },
          child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
          children: [
            StaggeredEntrance(
              index: 0,
              child: HomeHeader(profileName: profile?.name, day: board.day),
            ),
            const SizedBox(height: 16),
            StaggeredEntrance(
              index: 1,
              child: WeekDayStrip(
                anchor: board.day,
                selected: board.day,
                kcalByDay: kcal,
                daysWithData: board.marks.keys.toSet(),
                premium: premium,
                onDay: (DateTime day) {
                  handleDayTap(context, day, selectOnly: true);
                },
              ),
            ),
            if (!viewingToday) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Viewing ${formatDay(board.day)}', style: AppTextStyles.caption),
                  BiteChip(
                    label: 'Back to today',
                    selected: false,
                    onTap: () => board.showDay(dateOnly(DateTime.now())),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            StaggeredEntrance(
              index: 2,
              child: TodayRing(
                eaten: eaten,
                target: target,
                left: left,
                burned: board.burned.round(),
              ),
            ),
            const SizedBox(height: 16),
            StaggeredEntrance(
              index: 3,
              child: HomeMacros(
                board: board,
                provider: context.watch<ProfileProvider>(),
              ),
            ),
            const SizedBox(height: 24),
            StaggeredEntrance(
              index: 4,
              child: SectionHeader(
                label: viewingToday ? "Today's meals" : formatDay(board.day),
                trailing: TextButton(
                  onPressed: () => context.push(
                    '/log?date=${progressDayKey(board.day)}',
                  ),
                  child: const Text('See log'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            HomeMeals(foods: board.foods),
          ],
        ),
        ),
        Positioned(
          right: 20,
          bottom: 12,
          child: BiteButton(
            label: '+ Log food',
            fullWidth: false,
            onPressed: () => context.go('/food?date=${progressDayKey(board.day)}'),
          ),
        ),
      ],
    );
  }
}
