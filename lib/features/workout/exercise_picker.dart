import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/bite_repos.dart';
import '../../data/models/gym_models.dart';
import '../../data/seed/exercise_seeder.dart';
import '../../domain/feature_gate.dart';
import '../../ui/widgets/bite_button.dart';
import '../../ui/widgets/bite_chip.dart';
import '../../ui/widgets/bite_empty_state.dart';
import '../../ui/widgets/emoji_tile.dart';
import '../../ui/widgets/labeled_field.dart';
import '../../ui/widgets/section_header.dart';

// How it works: the list is a SQLite search. Chips come from the groups
// that are actually saved. Walking and Running stay at the top.

class ExercisePicker extends StatefulWidget {
  const ExercisePicker({
    super.key,
    required this.isPremium,
    required this.onPicked,
    required this.onLocked,
  });

  final bool isPremium;
  final ValueChanged<Exercise> onPicked;
  final VoidCallback onLocked;

  @override
  State<ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends State<ExercisePicker> {
  final TextEditingController _query = TextEditingController();
  final TextEditingController _customName = TextEditingController();
  Timer? _debounce;
  List<Exercise> _rows = <Exercise>[];
  List<String> _chips = <String>['All'];
  String _chip = 'All';
  bool _ready = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load(group: null);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    _customName.dispose();
    super.dispose();
  }

  Future<void> _load({required String? group}) async {
    final BiteRepos? repos = context.read<BiteRepos?>();
    if (repos == null) {
      setState(() => _ready = true);
      return;
    }
    try {
      final List<Exercise> rows = await repos.workouts.searchExercises(
        _query.text,
        muscleGroup: group,
        limit: 50,
      );
      final SharedPreferences preferences = await SharedPreferences.getInstance();
      final List<String> groups = await repos.workouts.muscleGroups();
      if (!mounted) {
        return;
      }
      setState(() {
        _rows = rows;
        _chips = exerciseChips(
          groups,
          preferences.getString(ExerciseSeeder.groupOrderKey),
        );
        _ready = true;
        _error = null;
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

  void _type(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      _load(group: _chip == 'All' ? null : _chip);
    });
  }

  void _tap(Exercise exercise) {
    final bool allowed = canLogExercise(
      isPremium: widget.isPremium,
      isFree: exercise.isFree,
      isCustom: exercise.isCustom,
    );
    if (!allowed) {
      widget.onLocked();
      return;
    }
    widget.onPicked(exercise);
  }

  Future<void> _custom() async {
    if (!FeatureGate(isPremium: widget.isPremium).canUse(Feature.customExercises)) {
      widget.onLocked();
      return;
    }
    final BiteRepos? repos = context.read<BiteRepos?>();
    if (repos == null) {
      return;
    }
    final bool? save = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialog) {
        return AlertDialog(
          content: BiteLabeledField(
            controller: _customName,
            label: 'Exercise name',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (save != true || !mounted) {
      return;
    }
    await repos.workouts.createCustomExercise(
      name: _customName.text,
      muscleGroup: 'Full Body',
      isPremium: true,
    );
    _customName.clear();
    await _load(group: _chip == 'All' ? null : _chip);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return BiteEmptyState(
        emoji: '💪',
        message: 'Could not load exercises.',
        actionLabel: 'Try again',
        onAction: () => _load(group: _chip == 'All' ? null : _chip),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(label: 'Exercises'),
        const SizedBox(height: 8),
        TextField(
          controller: _query,
          onChanged: _type,
          decoration: const InputDecoration(
            hintText: 'Search exercises',
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _chips.length,
            separatorBuilder: (BuildContext context, int index) {
              return const SizedBox(width: 8);
            },
            itemBuilder: (BuildContext context, int index) {
              final String label = _chips[index];
              return BiteChip(
                label: label,
                selected: _chip == label,
                onTap: () {
                  setState(() => _chip = label);
                  _load(group: label == 'All' ? null : label);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        if (_rows.isEmpty)
          const BiteEmptyState(emoji: '🔎', message: 'No exercises match.')
        else
          for (final Exercise exercise in _rows) _row(exercise),
        const SizedBox(height: 8),
        BiteButton(
          label: 'Custom exercise',
          filled: false,
          onPressed: _custom,
        ),
      ],
    );
  }

  Widget _row(Exercise exercise) {
    final bool locked = !canLogExercise(
      isPremium: widget.isPremium,
      isFree: exercise.isFree,
      isCustom: exercise.isCustom,
    );
    return InkWell(
      onTap: () => _tap(exercise),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            EmojiTile(emoji: exercise.emoji),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exercise.name, style: AppTextStyles.body),
                  Text(exercise.muscleGroup, style: AppTextStyles.caption),
                ],
              ),
            ),
            if (exercise.isFree && !exercise.isCustom)
              Text(
                'FREE',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.chili,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (locked)
              Text(
                'Locked',
                style: AppTextStyles.caption.copyWith(color: AppColors.muted),
              ),
          ],
        ),
      ),
    );
  }
}
