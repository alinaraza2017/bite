import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/bite_repos.dart';
import '../../data/models/gym_models.dart';
import '../../domain/burn_calc.dart';
import '../../domain/feature_gate.dart';
import '../../domain/pr_calc.dart';
import '../../ui/widgets/animated_number.dart';
import '../../ui/widgets/bite_button.dart';
import '../../ui/widgets/bite_chip.dart';
import '../../ui/widgets/bite_card.dart';
import '../../ui/widgets/emoji_tile.dart';
import '../../ui/widgets/section_header.dart';
import '../../widgets/bite_back_button.dart';
import '../onboarding/profile_provider.dart';

// How it works: the controls follow the exercise type. The number on screen
// is the MET estimate for the current minutes, variant, or sets.

class ExerciseLogScreen extends StatefulWidget {
  const ExerciseLogScreen({
    super.key,
    required this.exerciseId,
    required this.sessionId,
  });

  final int exerciseId;
  final int sessionId;

  @override
  State<ExerciseLogScreen> createState() => _ExerciseLogScreenState();
}

class _ExerciseLogScreenState extends State<ExerciseLogScreen> {
  Exercise? _exercise;
  LastSet? _previous;
  LastSet? _best;
  List<SessionSet> _sets = <SessionSet>[];
  int _minutes = 30;
  int _seconds = 30;
  double _weight = 20;
  int _reps = 8;
  String? _variant;
  bool _ready = false;
  bool _started = false;

  bool get _premium {
    return context.read<ProfileProvider>().profile?.isPremium ?? false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    _load();
  }

  Future<void> _load({bool keepDraft = false}) async {
    final BiteRepos? repos = context.read<BiteRepos?>();
    if (repos == null) {
      return;
    }
    final Exercise? exercise = await repos.workouts.exerciseById(widget.exerciseId);
    if (exercise == null) {
      return;
    }
    if (!canLogExercise(
      isPremium: _premium,
      isFree: exercise.isFree,
      isCustom: exercise.isCustom,
    )) {
      if (mounted) {
        context.push('/premium');
      }
      return;
    }
    final LastSet? previous = await repos.workouts.previousSet(
      widget.exerciseId,
      ignoreSessionId: widget.sessionId,
    );
    final LastSet? best = await repos.workouts.bestEffort(widget.exerciseId);
    final List<SessionSet> all = await repos.workouts.setsForSession(widget.sessionId);
    final List<SessionSet> mine = all
        .where((SessionSet set) => set.exerciseId == widget.exerciseId)
        .toList();
    if (!mounted) {
      return;
    }
    final List<SessionSet> done = mine.where((SessionSet set) => set.completed).toList();
    if (!keepDraft) {
      _applyDraft(exercise, previous, done);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _exercise = exercise;
      _previous = previous;
      _best = best;
      _sets = mine;
      _ready = true;
    });
    if (!keepDraft && exercise.type == 'duration') {
      final int stored = done.fold<int>(0, (int sum, SessionSet set) => sum + set.minutes);
      if (stored != _minutes) {
        await _saveDuration();
      }
    }
  }

  void _applyDraft(Exercise exercise, LastSet? previous, List<SessionSet> done) {
    if (exercise.type == 'duration') {
      final int lastMinutes = done.isEmpty ? 0 : done.last.minutes;
      _minutes = lastMinutes > 0
          ? lastMinutes
          : (previous != null && previous.minutes > 0 ? previous.minutes : 30);
      _variant = done.isEmpty ? previous?.variantLabel : done.last.variantLabel;
      _variant ??= exercise.defaultVariant?.label;
    }
    if (previous != null && previous.weightKg > 0) {
      _weight = previous.weightKg;
      _reps = previous.reps > 0 ? previous.reps : 8;
    }
    if (previous != null && previous.holdSeconds > 0) {
      _seconds = previous.holdSeconds;
    }
  }

  Future<void> _saveDuration() async {
    final Exercise? exercise = _exercise;
    final BiteRepos? repos = context.read<BiteRepos?>();
    if (exercise == null || repos == null) {
      return;
    }
    final SessionSet? row = _sets.isEmpty ? null : _sets.first;
    await repos.workouts.saveSet(
      sessionId: widget.sessionId,
      exerciseId: exercise.id,
      setNumber: 1,
      weightKg: 0,
      reps: 0,
      minutes: _minutes,
      variantLabel: _variant,
      existingId: row?.id,
      isPremium: _premium,
    );
    await _load(keepDraft: true);
  }

  Future<void> _changeSeconds(int next) async {
    setState(() => _seconds = next);
    final Exercise? exercise = _exercise;
    final BiteRepos? repos = context.read<BiteRepos?>();
    if (exercise == null || repos == null) {
      return;
    }
    for (final SessionSet set in _sets) {
      if (!set.completed) {
        continue;
      }
      await repos.workouts.saveSet(
        sessionId: widget.sessionId,
        exerciseId: exercise.id,
        setNumber: set.setNumber,
        weightKg: set.weightKg,
        reps: set.reps,
        holdSeconds: next,
        existingId: set.id,
        isPremium: _premium,
      );
    }
    await _load(keepDraft: true);
  }

  Future<void> _addSet() async {
    final Exercise? exercise = _exercise;
    final BiteRepos? repos = context.read<BiteRepos?>();
    if (exercise == null || repos == null) {
      return;
    }
    final List<SessionSet> open = _sets.where((SessionSet set) => !set.completed).toList();
    final SessionSet? empty = open.isEmpty ? null : open.first;
    final int number = _sets.where((SessionSet set) => set.completed).length + 1;
    await repos.workouts.saveSet(
      sessionId: widget.sessionId,
      exerciseId: exercise.id,
      setNumber: number,
      weightKg: exercise.type == 'bodyweight' ? _weight : _weight,
      reps: _reps,
      holdSeconds: exercise.type == 'timed' ? _seconds : 0,
      existingId: empty?.id,
      isPremium: _premium,
    );
    await _load(keepDraft: true);
  }

  Future<void> _sameAsLast() async {
    final LastSet? previous = _previous;
    if (previous == null) {
      return;
    }
    setState(() {
      _weight = previous.weightKg;
      _reps = previous.reps;
    });
    await _addSet();
  }

  int _burn() {
    final Exercise? exercise = _exercise;
    if (exercise == null) {
      return 0;
    }
    final double weight = resolveBodyWeightKg(
      profileKg: context.read<ProfileProvider>().profile?.weightKg,
    );
    final ExerciseVariant? variant = exercise.variantByLabel(_variant);
    final double met = variant?.met ?? exercise.met;
    if (exercise.type == 'duration') {
      return durationBurn(met: met, weightKg: weight, minutes: _minutes);
    }
    if (exercise.type == 'timed') {
      final int count = _sets.where((SessionSet set) => set.completed).length;
      return timedBurn(
        met: exercise.met,
        weightKg: weight,
        sets: count,
        seconds: _seconds,
      );
    }
    final int count = _sets.where((SessionSet set) => set.completed).length;
    return strengthBurn(met: exercise.met, weightKg: weight, sets: count);
  }

  @override
  Widget build(BuildContext context) {
    final Exercise? exercise = _exercise;
    final bool premium = context.watch<ProfileProvider>().profile?.isPremium ?? false;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: !_ready || exercise == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  const BiteBackButton(),
                  Row(
                    children: [
                      EmojiTile(emoji: exercise.emoji),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(exercise.name, style: AppTextStyles.appHeading),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _burnCard(),
                  const SizedBox(height: 16),
                  if (exercise.type == 'duration') ..._duration(exercise),
                  if (exercise.type == 'timed') ..._timed(),
                  if (exercise.type == 'strength' || exercise.type == 'bodyweight')
                    ..._strength(exercise),
                  const SizedBox(height: 16),
                  _records(exercise, premium),
                ],
              ),
      ),
    );
  }

  Widget _burnCard() {
    final Exercise? exercise = _exercise;
    final double? km = exercise == null || exercise.type != 'duration'
        ? null
        : estimateDistanceKm(
            speedKmh: exercise.variantByLabel(_variant)?.speedKmh,
            minutes: _minutes,
          );
    return BiteSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Burned', style: AppTextStyles.caption),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text('~', style: AppTextStyles.number),
              AnimatedNumber(value: _burn(), style: AppTextStyles.number),
              const Text(' kcal', style: AppTextStyles.body),
            ],
          ),
          if (km != null)
            Text(
              '~${km.toStringAsFixed(1)} km',
              style: AppTextStyles.caption,
            ),
        ],
      ),
    );
  }

  List<Widget> _duration(Exercise exercise) {
    return <Widget>[
      if (exercise.variants.isNotEmpty)
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final ExerciseVariant variant in exercise.variants)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: BiteChip(
                    label: variant.label,
                    selected: _variant == variant.label,
                    onTap: () {
                      setState(() => _variant = variant.label);
                      _saveDuration();
                    },
                  ),
                ),
            ],
          ),
        ),
      const SizedBox(height: 12),
      _step(
        'Minutes',
        '$_minutes',
        () {
          setState(() => _minutes = (_minutes - 5).clamp(0, 300));
          _saveDuration();
        },
        () {
          setState(() => _minutes = (_minutes + 5).clamp(0, 300));
          _saveDuration();
        },
      ),
    ];
  }

  List<Widget> _timed() {
    final int count = _sets.where((SessionSet set) => set.completed).length;
    return <Widget>[
      _step(
        'Seconds',
        '$_seconds',
        () => _changeSeconds((_seconds - 5).clamp(5, 300)),
        () => _changeSeconds((_seconds + 5).clamp(5, 300)),
      ),
      Text('$count sets logged', style: AppTextStyles.caption),
      const SizedBox(height: 8),
      BiteButton(label: 'Add set', onPressed: _addSet),
    ];
  }

  List<Widget> _strength(Exercise exercise) {
    final bool showKg = exercise.type == 'strength' || _weight > 0;
    final String last = _previous == null
        ? 'First time'
        : 'Last: ${_previous!.weightKg} kg x ${_previous!.reps}';
    return <Widget>[
      SectionHeader(
        label: last,
        trailing: TextButton(
          onPressed: _previous == null ? null : _sameAsLast,
          child: const Text('Same as last'),
        ),
      ),
      if (exercise.type == 'strength' || showKg)
        _step(
          exercise.type == 'bodyweight' ? 'Weight (kg, optional)' : 'Weight (kg)',
          _weight.toStringAsFixed(1),
          () => setState(() => _weight = (_weight - 2.5).clamp(0, 400)),
          () => setState(() => _weight = (_weight + 2.5).clamp(0, 400)),
        ),
      _step(
        'Reps',
        '$_reps',
        () => setState(() => _reps = (_reps - 1).clamp(1, 50)),
        () => setState(() => _reps = (_reps + 1).clamp(1, 50)),
      ),
      BiteButton(label: 'Add set', onPressed: _addSet),
      const SizedBox(height: 8),
      for (final SessionSet set in _sets)
        if (set.completed) _setRow(set),
    ];
  }

  Widget _setRow(SessionSet set) {
    double running = _best == null ? 0 : epleyOneRepMax(_best!.weightKg, _best!.reps);
    bool badge = false;
    for (final SessionSet row in _sets.where((SessionSet item) => item.completed)) {
      final bool record = isPersonalRecord(
        weightKg: row.weightKg,
        reps: row.reps,
        bestOneRepMax: running,
      );
      final double one = epleyOneRepMax(row.weightKg, row.reps);
      if (one > running) {
        running = one;
      }
      if (row.id == set.id) {
        badge = record;
        break;
      }
    }
    final bool premium = context.watch<ProfileProvider>().profile?.isPremium ?? false;
    final String detail = set.holdSeconds > 0
        ? '${set.holdSeconds} sec'
        : '${set.weightKg} kg x ${set.reps}';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('Set ${set.setNumber}'),
      subtitle: Text(detail),
      trailing: premium && badge
          ? Text(
              'PR',
              style: AppTextStyles.sectionHeading.copyWith(color: AppColors.chili),
            )
          : null,
    );
  }

  Widget _records(Exercise exercise, bool premium) {
    final bool lifts = exercise.type == 'strength' || exercise.type == 'bodyweight';
    if (!lifts) {
      return const SizedBox.shrink();
    }
    if (!FeatureGate(isPremium: premium).canUse(Feature.prTracking)) {
      return BiteSurface(
        child: InkWell(
          onTap: () => context.push('/premium'),
          child: const Row(
            children: [
              Expanded(
                child: Text(
                  'Personal records',
                  style: AppTextStyles.sectionHeading,
                ),
              ),
              Text('Locked', style: AppTextStyles.caption),
            ],
          ),
        ),
      );
    }
    final LastSet? best = _best;
    final String line = best == null
        ? 'No record yet'
        : 'Best ${best.weightKg} kg x ${best.reps} · 1RM ${epleyOneRepMax(best.weightKg, best.reps).round()} kg';
    return BiteSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(label: 'Personal record'),
          const SizedBox(height: 8),
          Text(line, style: AppTextStyles.body),
        ],
      ),
    );
  }

  Widget _step(String label, String value, VoidCallback down, VoidCallback up) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.body)),
          _round(Icons.remove, down),
          SizedBox(
            width: 72,
            child: Text(value, textAlign: TextAlign.center, style: AppTextStyles.sectionHeading),
          ),
          _round(Icons.add, up),
        ],
      ),
    );
  }

  Widget _round(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Icon(icon),
      ),
    );
  }
}
