import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/bite_repos.dart';
import '../../data/seed/food_seeder.dart';
import '../../data/models/food_unit.dart';
import '../../widgets/bite_back_button.dart';
import '../../widgets/buttons.dart';
import '../../widgets/labeled_field.dart';
import 'food_screen.dart';

// How it works: the numbers are checked before save. A bad field turns
// the error colour. A good save opens the food so it can be logged.

class CustomFoodScreen extends StatefulWidget {
  const CustomFoodScreen({super.key});

  @override
  State<CustomFoodScreen> createState() => _CustomFoodScreenState();
}

class _CustomFoodScreenState extends State<CustomFoodScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _unit = TextEditingController(text: '1 plate');
  final TextEditingController _kcal = TextEditingController();
  final TextEditingController _protein = TextEditingController();
  final TextEditingController _carbs = TextEditingController();
  final TextEditingController _fat = TextEditingController();
  String _category = 'Main meals';
  List<String> _categories = <String>['Main meals'];
  bool _categoriesAsked = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_categoriesAsked) {
      return;
    }
    _categoriesAsked = true;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final BiteRepos? repos = context.read<BiteRepos?>();
    if (repos == null) {
      return;
    }
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final List<String> found = await repos.foods.categories();
    final List<String> chips = foodChips(
      found,
      preferences.getString(FoodSeeder.categoryOrderKey),
    ).where((String name) => name != 'All').toList();
    if (!mounted || chips.isEmpty) {
      return;
    }
    setState(() {
      _categories = chips;
      if (!_categories.contains(_category)) {
        _category = _categories.first;
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _unit.dispose();
    _kcal.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  double? _read(TextEditingController controller, double max) {
    final double? value = double.tryParse(controller.text.trim());
    if (value == null || value < 0 || value > max) {
      return null;
    }
    return value;
  }

  Future<void> _save() async {
    final BiteRepos? repos = context.read<BiteRepos?>();
    final double? kcal = _read(_kcal, 2000);
    final double? protein = _read(_protein, 200);
    final double? carbs = _read(_carbs, 300);
    final double? fat = _read(_fat, 200);
    if (repos == null ||
        _name.text.trim().isEmpty ||
        _unit.text.trim().isEmpty ||
        kcal == null ||
        protein == null ||
        carbs == null ||
        fat == null) {
      setState(() => _error = 'Enter a name, a serving, and numbers that make sense.');
      return;
    }
    final int id = await repos.foods.addCustomFood(
      name: _name.text,
      category: _category,
      unit: FoodUnitInput(
        label: _unit.text.trim(),
        grams: 100,
        calories: kcal,
        protein: protein,
        carbs: carbs,
        fat: fat,
      ),
    );
    if (!mounted) {
      return;
    }
    context.pushReplacement('/food/$id?meal=lunch');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          const BiteBackButton(),
          const Text('Custom food', style: AppTextStyles.appHeading),
          const SizedBox(height: 16),
          LabeledField(controller: _name, label: 'Name', onLight: true),
          const Text(
            'Category',
            style: TextStyle(
              color: AppColors.text,
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _category,
            items: [
              for (final String category in _categories)
                DropdownMenuItem<String>(value: category, child: Text(category)),
            ],
            onChanged: (String? value) {
              if (value != null) {
                setState(() => _category = value);
              }
            },
            decoration: const InputDecoration(
              filled: true,
              fillColor: AppColors.card,
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 12),
          LabeledField(controller: _unit, label: 'Serving unit', onLight: true),
          LabeledField(
            controller: _kcal,
            label: 'Calories',
            keyboardType: TextInputType.number,
            onLight: true,
          ),
          LabeledField(
            controller: _protein,
            label: 'Protein (g)',
            keyboardType: TextInputType.number,
            onLight: true,
          ),
          LabeledField(
            controller: _carbs,
            label: 'Carbs (g)',
            keyboardType: TextInputType.number,
            onLight: true,
          ),
          LabeledField(
            controller: _fat,
            label: 'Fat (g)',
            keyboardType: TextInputType.number,
            onLight: true,
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: AppTextStyles.caption.copyWith(color: AppColors.error),
              ),
            ),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Save', onPressed: _save),
        ],
        ),
      ),
    );
  }
}
