import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/format_numbers.dart';
import '../../data/bite_repos.dart';
import '../../data/models/gym_models.dart';
import '../../domain/feature_gate.dart';
import '../../domain/progress_calc.dart';
import '../../ui/widgets/bite_button.dart';
import '../../ui/widgets/bite_card.dart';
import '../../ui/widgets/bite_empty_state.dart';
import '../../ui/widgets/section_header.dart';
import '../../ui/widgets/week_day_strip.dart';
import '../../widgets/list_row_card.dart';
import '../day/open_day.dart';
import '../onboarding/profile_provider.dart';
import 'exercise_picker.dart';

// How it works: the next card is the plan that has gone longest without a
// finish. Week dots mark days that already have a finished session.

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  List<WorkoutTemplate> _plans = <WorkoutTemplate>[];
  WorkoutTemplate? _next;
  List<WorkoutSummary> _history = <WorkoutSummary>[];
  WorkoutSummary? _open;
  Set<String> _doneDays = <String>{};
  bool _ready = false;
  bool _started = false;
  Object? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    if (context.read<BiteRepos?>() == null) {
      _ready = true;
      return;
    }
    _load();
  }

  Future<void> _load() async {
    final BiteRepos? repos = context.read<BiteRepos?>();
    if (repos == null) {
      return;
    }
    try {
      final List<WorkoutTemplate> plans = await repos.workouts.templates();
      final WorkoutTemplate? next = await repos.workouts.nextTemplate(plans);
      final List<WorkoutSummary> history = await repos.workouts.recentSessions();
      final WorkoutSummary? open = await repos.workouts.openSession();
      final DateTime monday = mondayOf(DateTime.now());
      final Set<String> done = <String>{};
      for (int offset = 0; offset < 7; offset++) {
        final DateTime day = monday.add(Duration(days: offset));
        final int count = await repos.workouts.sessionsOnDate(progressDayKey(day));
        if (count > 0) {
          done.add(progressDayKey(day));
        }
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _plans = plans;
        _next = next;
        _history = history;
        _open = open;
        _doneDays = done;
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

  bool get _premium {
    return context.read<ProfileProvider>().profile?.isPremium ?? false;
  }

  Future<void> _start(WorkoutTemplate plan) async {
    final BiteRepos? repos = context.read<BiteRepos?>();
    if (repos == null) {
      return;
    }
    for (final exercise in plan.exercises) {
      final bool allowed = canLogExercise(
        isPremium: _premium,
        isFree: exercise.isFree,
        isCustom: exercise.isCustom,
      );
      if (!allowed) {
        if (mounted) {
          context.push('/premium');
        }
        return;
      }
    }
    final int id = await repos.workouts.startSession(
      name: plan.name,
      templateId: plan.id,
      exercises: plan.exercises,
      isPremium: _premium,
    );
    if (!mounted) {
      return;
    }
    await context.push('/workout/session/$id');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: TextButton(onPressed: _load, child: const Text('Try again')),
      );
    }
    final DateTime monday = mondayOf(DateTime.now());
    final bool premium = context.watch<ProfileProvider>().profile?.isPremium ?? false;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const Text('Workout', style: AppTextStyles.appHeading),
        const SizedBox(height: 12),
        if (_open != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: BiteButton(
              label: 'Resume ${_open!.name}',
              onPressed: () async {
                await context.push('/workout/session/${_open!.id}');
                _load();
              },
            ),
          ),
        ExercisePicker(
          isPremium: premium,
          onLocked: () => context.push('/premium'),
          onPicked: (exercise) async {
            final BiteRepos? repos = context.read<BiteRepos?>();
            if (repos == null) {
              return;
            }
            final int id = await repos.workouts.startSession(
              name: exercise.name,
              exercises: <Exercise>[exercise],
              isPremium: premium,
            );
            if (!context.mounted) {
              return;
            }
            await context.push('/workout/session/$id');
            if (!context.mounted) {
              return;
            }
            _load();
          },
        ),
        const SizedBox(height: 16),
        if (_next != null)
          BiteSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(label: 'Next session'),
                const SizedBox(height: 8),
                Text(_next!.name, style: AppTextStyles.appHeading),
                Text(
                  '${_next!.exercises.length} exercises · ${_lastDone(_next!)}',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 12),
                BiteButton(
                  label: 'Start workout',
                  onPressed: () => _start(_next!),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(
              child: Text('This week', style: AppTextStyles.sectionHeading),
            ),
            Text(
              '${_doneDays.length} / 5',
              style: AppTextStyles.sectionHeading.copyWith(color: AppColors.chili),
            ),
          ],
        ),
        const SizedBox(height: 8),
        WeekDayStrip(
          anchor: monday,
          selected: dateOnly(DateTime.now()),
          kcalByDay: const <String, int>{},
          daysWithData: _doneDays,
          premium: premium,
          onDay: (DateTime day) {
            handleDayTap(context, day, workoutsFirst: true);
          },
        ),
        const SizedBox(height: 16),
        const SectionHeader(label: 'History'),
        if (_history.isEmpty)
          const BiteEmptyState(emoji: '💪', message: 'No finished workouts yet.')
        else
          for (final WorkoutSummary session in _history)
            ListRowCard(
              letter: session.name.isEmpty ? 'W' : session.name[0],
              seed: session.id,
              title: session.name,
              subtitle: '${formatDay(dateFromKey(session.date) ?? DateTime.now()).substring(0, 3)} · ${session.totalSets} sets',
              value: '${session.durationMin} min',
              onTap: () {
                final DateTime? day = dateFromKey(session.date);
                if (day != null) {
                  handleDayTap(context, day, workoutsFirst: true);
                }
              },
            ),
        if (_plans.isEmpty && context.read<BiteRepos?>() == null)
          const SizedBox.shrink(),
      ],
    );
  }

  String _lastDone(WorkoutTemplate plan) {
    for (final WorkoutSummary session in _history) {
      if (session.name == plan.name) {
        return 'last done ${formatShort(dateFromKey(session.date) ?? DateTime.now())}';
      }
    }
    return 'not done yet';
  }

}
