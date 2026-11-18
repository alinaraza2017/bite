import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/meals.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/format_numbers.dart';
import '../../data/bite_repos.dart';
import '../../data/seed/food_seeder.dart';
import '../../data/models/food.dart';
import '../../domain/premium_gate.dart';
import '../../widgets/list_row_card.dart';
import '../log_food/food_search_controller.dart';
import '../onboarding/profile_provider.dart';

// How it works: the box waits 150 ms, then SQLite searches the name and aliases.
// Chips come from the categories in the database, in the order of foods.json.

/// "All" first, then the JSON order, then any extra category from a custom food.
List<String> foodChips(List<String> found, String? savedOrder) {
  final List<String> order = <String>[];
  if (savedOrder != null && savedOrder.isNotEmpty) {
    final Object? decoded = jsonDecode(savedOrder);
    if (decoded is List<dynamic>) {
      for (final dynamic item in decoded) {
        order.add(item.toString());
      }
    }
  }
  final List<String> chips = <String>['All'];
  final Set<String> used = <String>{};
  for (final String name in order) {
    if (found.contains(name) && used.add(name)) {
      chips.add(name);
    }
  }
  final List<String> rest = List<String>.from(found)..sort();
  for (final String name in rest) {
    if (used.add(name)) {
      chips.add(name);
    }
  }
  return chips;
}

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key, this.date});

  /// yyyy-MM-dd when the person came from a chosen day. Null means today.
  final String? date;

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  FoodSearchController? _search;
  String _chip = 'All';
  List<String> _chips = <String>['All'];
  bool _chipsAsked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_search != null) {
      return;
    }
    final BiteRepos? repos = context.read<BiteRepos?>();
    if (repos == null) {
      return;
    }
    _search = FoodSearchController(
      search: (String query, List<String>? categories) {
        final String? category = categories == null || categories.isEmpty
            ? null
            : categories.first;
        return repos.foods.searchFoods(query, category: category, limit: 50);
      },
      recents: () => repos.foods.searchFoods('', limit: 50),
    );
    if (!_chipsAsked) {
      _chipsAsked = true;
      _loadChips(repos);
    }
  }

  Future<void> _loadChips(BiteRepos repos) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final List<String> found = await repos.foods.categories();
    if (!mounted) {
      return;
    }
    setState(() {
      _chips = foodChips(
        found,
        preferences.getString(FoodSeeder.categoryOrderKey),
      );
    });
  }

  @override
  void dispose() {
    _search?.dispose();
    super.dispose();
  }

  Future<void> _custom() async {
    final BiteRepos? repos = context.read<BiteRepos?>();
    if (repos == null) {
      return;
    }
    final int count = await repos.foods.customCount();
    if (!mounted) {
      return;
    }
    final bool premium = context.read<ProfileProvider>().profile?.isPremium ?? false;
    if (!canAddCustomFood(currentCount: count, isPremium: premium)) {
      await showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext sheet) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Free includes $freeCustomFoodLimit custom foods.',
                  style: AppTextStyles.sectionHeading,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pop(sheet);
                    context.push('/premium');
                  },
                  child: const Text('Go Premium'),
                ),
              ],
            ),
          );
        },
      );
      return;
    }
    if (mounted) {
      context.push('/food/custom');
    }
  }

  @override
  Widget build(BuildContext context) {
    final FoodSearchController? search = _search;
    if (search == null) {
      return const Center(child: Text('Food', style: AppTextStyles.heading));
    }
    return ListenableBuilder(
      listenable: search,
      builder: (BuildContext context, Widget? child) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Add food', style: AppTextStyles.appHeading),
                ),
                TextButton(
                  onPressed: () => context.push('/log'),
                  child: const Text("Today's log"),
                ),
              ],
            ),
            TextField(
              textAlign: TextAlign.end,
              decoration: InputDecoration(
                hintText: 'Search',
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100),
                  borderSide: const BorderSide(color: AppColors.chili, width: 1.5),
                ),
              ),
              onChanged: search.setQuery,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final String category in _chips)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: _chip == category,
                        onSelected: (_) {
                          setState(() => _chip = category);
                          search.selectCategories(
                            category == 'All' ? null : <String>[category],
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (!search.ready)
              const Center(child: CircularProgressIndicator())
            else if (search.error != null)
              TextButton(onPressed: search.retry, child: const Text('Try again'))
            else if (search.foods.isEmpty)
              const Text('No foods match.', style: AppTextStyles.body)
            else
              for (final Food food in search.foods)
                ListRowCard(
                  letter: food.name.isEmpty ? '?' : food.name[0],
                  seed: food.id,
                  title: food.name,
                  subtitle: food.defaultUnitLabel,
                  value: '${formatNumber(food.defaultCalories)} kcal',
                  onTap: () {
                    final String meal = mealForTime(DateTime.now());
                    final String? day = widget.date;
                    final String extra = day == null ? '' : '&date=$day';
                    context.push('/food/${food.id}?meal=$meal$extra');
                  },
                ),
            const SizedBox(height: 8),
            Material(
              color: AppColors.haldiTint,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cannot find it?', style: AppTextStyles.caption),
                    TextButton(
                      onPressed: _custom,
                      child: const Text(
                        '+ Add custom food',
                        style: TextStyle(color: AppColors.chili),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
