import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/meals.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/format_numbers.dart';
import '../../data/bite_repos.dart';
import '../../data/models/food.dart';
import '../../data/models/food_unit.dart';
import '../../data/models/logged_food.dart';
import '../../domain/models.dart';
import '../../domain/progress_calc.dart';
import '../../services/nutrition_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bite_back_button.dart';
import '../../widgets/buttons.dart';
import '../../widgets/food_controls.dart';

// How it works: unit, quantity, and tadka recompute the card immediately.
// Saving stores those whole numbers so the log does not change later.

class FoodDetailScreen extends StatefulWidget {
  const FoodDetailScreen({
    super.key,
    required this.foodId,
    required this.meal,
    this.logId,
    this.date,
  });

  final int foodId;
  final String meal;
  final int? logId;
  final String? date;

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  Food? _food;
  List<FoodUnit> _units = <FoodUnit>[];
  FoodUnit? _unit;
  double _quantity = 1;
  String _tadka = 'Medium';
  late String _meal = widget.meal;
  bool _ready = false;
  bool _asked = false;
  Object? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_asked) {
      return;
    }
    _asked = true;
    _load();
  }

  Future<void> _load() async {
    final BiteRepos? repos = context.read<BiteRepos?>();
    if (repos == null) {
      return;
    }
    try {
      final Food? food = await repos.foods.foodById(widget.foodId);
      final List<FoodUnit> units = await repos.foods.unitsFor(widget.foodId);
      FoodUnit? unit = units.cast<FoodUnit?>().firstWhere(
        (FoodUnit? item) => item!.isDefault,
        orElse: () => units.isEmpty ? null : units.first,
      );
      if (widget.logId != null) {
        final List<LoggedFood> today = await repos.logs.foodsForDate(
          widget.date ?? progressDayKey(DateTime.now()),
        );
        for (final LoggedFood row in today) {
          if (row.id == widget.logId) {
            _quantity = row.quantity;
            _meal = row.meal;
            _tadka = _label(row.tadka);
            unit = units.cast<FoodUnit?>().firstWhere(
              (FoodUnit? item) => item!.id == row.unitId,
              orElse: () => unit,
            );
          }
        }
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _food = food;
        _units = units;
        _unit = unit;
        _ready = true;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _ready = true;
      });
    }
  }

  String _label(String? stored) {
    if (stored == 'light') {
      return 'Light';
    }
    if (stored == 'heavy') {
      return 'Heavy';
    }
    return 'Medium';
  }

  TadkaLevel get _level {
    if (_tadka == 'Light') {
      return TadkaLevel.light;
    }
    if (_tadka == 'Heavy') {
      return TadkaLevel.heavy;
    }
    return TadkaLevel.medium;
  }

  PortionNumbers? get _numbers {
    final Food? food = _food;
    final FoodUnit? unit = _unit;
    if (food == null || unit == null) {
      return null;
    }
    return estimatePortion(
      unitCalories: unit.calories,
      unitProtein: unit.protein,
      unitCarbs: unit.carbs,
      unitFat: unit.fat,
      quantity: _quantity,
      hasTadka: food.hasTadka,
      tadka: _level,
      tadkaLightKcal: food.tadkaLightKcal,
      tadkaLightFat: food.tadkaLightFat,
      tadkaHeavyKcal: food.tadkaHeavyKcal,
      tadkaHeavyFat: food.tadkaHeavyFat,
    );
  }

  Future<void> _save() async {
    final BiteRepos? repos = context.read<BiteRepos?>();
    final Food? food = _food;
    final FoodUnit? unit = _unit;
    if (repos == null || food == null || unit == null) {
      return;
    }
    final String date = progressDayKey(DateTime.now());
    if (widget.logId == null) {
      await repos.logs.addLog(
        date: date,
        meal: _meal,
        food: food,
        unit: unit,
        quantity: _quantity,
        tadka: food.hasTadka ? _level : null,
      );
    } else {
      await repos.logs.updateLog(
        id: widget.logId!,
        meal: _meal,
        food: food,
        unit: unit,
        quantity: _quantity,
        tadka: food.hasTadka ? _level : null,
      );
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added to ${mealLabel(_meal)}')),
    );
    context.pop();
  }

  Future<void> _delete() async {
    final int? id = widget.logId;
    final BiteRepos? repos = context.read<BiteRepos?>();
    if (id == null || repos == null) {
      return;
    }
    final LoggedFood? removed = await repos.logs.deleteLog(id);
    if (!mounted || removed == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Entry deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => repos.logs.restoreLog(removed),
        ),
      ),
    );
    context.pop();
  }

  void _step(int direction) {
    final FoodUnit? unit = _unit;
    if (unit == null) {
      return;
    }
    final double step = quantityStep(unit.label);
    double next = _quantity + (direction * step);
    if (next < 0.5) {
      next = 0.5;
    }
    if (next > 20) {
      next = 20;
    }
    setState(() => _quantity = next);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BiteBackButton(),
              Expanded(child: Center(child: CircularProgressIndicator())),
            ],
          ),
        ),
      );
    }
    if (_error != null || _food == null) {
      return const Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BiteBackButton(),
              Expanded(
                child: Center(child: Text('Could not open this food.')),
              ),
            ],
          ),
        ),
      );
    }
    final Food food = _food!;
    final PortionNumbers? numbers = _numbers;
    final String qty = _quantity == _quantity.roundToDouble()
        ? _quantity.round().toString()
        : _quantity.toStringAsFixed(1);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const BiteBackButton(),
            Text(food.name, style: AppTextStyles.appHeading),
            Text(
              '${food.category} · estimated values',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 16),
            const Text('Serving unit', style: AppTextStyles.caption),
            const SizedBox(height: 8),
            Wrap(
              children: [
                for (final FoodUnit unit in _units)
                  ServingChip(
                    label: unit.label,
                    selected: unit.id == _unit?.id,
                    onTap: () => setState(() => _unit = unit),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text('Quantity', style: AppTextStyles.body),
                ),
                _circle(Icons.remove, AppColors.card, AppColors.text, () => _step(-1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(qty, style: AppTextStyles.sectionHeading),
                ),
                _circle(Icons.add, AppColors.chili, AppColors.card, () => _step(1)),
              ],
            ),
            if (food.hasTadka) ...[
              const SizedBox(height: 16),
              const Text('Tadka / oil', style: AppTextStyles.body),
              const SizedBox(height: 8),
              TadkaSelector(
                selected: _tadka,
                onSelected: (String value) => setState(() => _tadka = value),
              ),
            ],
            const SizedBox(height: 16),
            if (numbers != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: darkCardGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estimated calories',
                      style: AppTextStyles.caption.copyWith(color: AppColors.card),
                    ),
                    Text(
                      '${formatNumber(numbers.calories)} kcal',
                      style: AppTextStyles.numberLarge.copyWith(
                        color: AppColors.haldi,
                      ),
                    ),
                    Text(
                      'Protein ${numbers.protein}g   Carbs ${numbers.carbs}g   Fat ${numbers.fat}g',
                      style: AppTextStyles.body.copyWith(color: AppColors.card),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (final String meal in mealIds)
                  ChoiceChip(
                    label: Text(mealLabel(meal)),
                    selected: _meal == meal,
                    onSelected: (_) => setState(() => _meal = meal),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: widget.logId == null
                  ? 'Add to ${mealLabel(_meal)}'
                  : 'Save changes',
              onPressed: _save,
            ),
            if (widget.logId != null)
              TextButton(
                onPressed: _delete,
                child: const Text(
                  'Delete entry',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _circle(IconData icon, Color fill, Color ink, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      customBorder: const CircleBorder(),
      child: CircleAvatar(
        backgroundColor: fill,
        child: Icon(icon, color: ink),
      ),
    );
  }
}
