import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/meals.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/logged_food.dart';
import '../../ui/widgets/bite_card.dart';
import '../../ui/widgets/bite_empty_state.dart';
import '../../ui/widgets/emoji_tile.dart';
import '../onboarding/profile_provider.dart';
import 'day_board.dart';

// How it works: macros are three thin bars. Meals group today's rows
// and put an emoji tile on the left of each food.

class HomeMacros extends StatelessWidget {
  const HomeMacros({super.key, required this.board, required this.provider});

  final DayBoard board;
  final ProfileProvider provider;

  @override
  Widget build(BuildContext context) {
    final targets = provider.targets;
    return BiteSurface(
      child: Column(
        children: [
          _bar('Protein', board.eaten.protein.round(), targets?.proteinGrams ?? 0, AppColors.protein),
          const SizedBox(height: 12),
          _bar('Carbs', board.eaten.carbs.round(), targets?.carbGrams ?? 0, AppColors.carbs),
          const SizedBox(height: 12),
          _bar('Fat', board.eaten.fat.round(), targets?.fatGrams ?? 0, AppColors.fat),
        ],
      ),
    );
  }

  Widget _bar(String label, int grams, int target, Color color) {
    final double fraction = target <= 0 ? 0 : (grams / target).clamp(0, 1);
    return Column(
      children: [
        Row(
          children: [
            Text(label, style: AppTextStyles.body),
            const Spacer(),
            Text('${grams}g', style: AppTextStyles.caption),
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

class HomeMeals extends StatelessWidget {
  const HomeMeals({super.key, required this.foods});

  final List<LoggedFood> foods;

  @override
  Widget build(BuildContext context) {
    if (foods.isEmpty) {
      return const BiteEmptyState(
        emoji: '🍽️',
        message: 'Nothing logged yet.',
      );
    }
    final List<Widget> cards = <Widget>[];
    for (final String meal in mealIds) {
      final List<LoggedFood> rows = foods
          .where((LoggedFood food) => food.meal == meal)
          .toList();
      if (rows.isEmpty) {
        continue;
      }
      cards.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: BiteSurface(
            child: Column(
              children: [
                for (final LoggedFood row in rows) _row(context, meal, row),
              ],
            ),
          ),
        ),
      );
    }
    return Column(children: cards);
  }

  Widget _row(BuildContext context, String meal, LoggedFood row) {
    return InkWell(
      onTap: () => context.push('/log'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            EmojiTile(emoji: _emoji(meal)),
            const SizedBox(width: 12),
            Expanded(child: Text(row.foodName, style: AppTextStyles.body)),
            Text('${row.calories} kcal', style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  String _emoji(String meal) {
    switch (meal) {
      case 'breakfast':
        return '🍳';
      case 'lunch':
        return '🍛';
      case 'snacks':
        return '🥟';
      default:
        return '🍽️';
    }
  }
}
