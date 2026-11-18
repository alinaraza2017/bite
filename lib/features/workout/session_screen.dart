import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/bite_repos.dart';
import '../../data/models/gym_models.dart';
import '../../domain/feature_gate.dart';
import '../../ui/widgets/bite_button.dart';
import '../../ui/widgets/bite_card.dart';
import '../../ui/widgets/emoji_tile.dart';
import '../../widgets/bite_back_button.dart';
import '../onboarding/profile_provider.dart';

// How it works: each exercise opens its own set list. Finish writes
// 210 kcal and opens the summary.

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  WorkoutSummary? _session;
  List<SessionSet> _sets = <SessionSet>[];
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
    final WorkoutSummary? session = await repos.workouts.sessionById(widget.sessionId);
    final List<SessionSet> sets = await repos.workouts.setsForSession(widget.sessionId);
    if (!mounted) {
      return;
    }
    setState(() {
      _session = session;
      _sets = sets;
      _ready = true;
    });
  }

  List<int> get _exerciseIds {
    final List<int> ids = <int>[];
    for (final SessionSet set in _sets) {
      if (!ids.contains(set.exerciseId)) {
        ids.add(set.exerciseId);
      }
    }
    return ids;
  }

  Future<void> _add() async {
    final BiteRepos? repos = context.read<BiteRepos?>();
    if (repos == null) {
      return;
    }
    final List<Exercise> found = await repos.workouts.searchExercises('');
    if (!mounted) {
      return;
    }
    final bool premium = context.read<ProfileProvider>().profile?.isPremium ?? false;
    final Exercise? picked = await showModalBottomSheet<Exercise>(
      context: context,
      builder: (BuildContext sheet) {
        return ListView(
          children: [
            for (final Exercise exercise in found)
              ListTile(
                leading: EmojiTile(emoji: exercise.emoji),
                title: Text(exercise.name),
                subtitle: Text(exercise.isFree ? 'FREE' : exercise.muscleGroup),
                onTap: () {
                  final bool allowed = canLogExercise(
                    isPremium: premium,
                    isFree: exercise.isFree,
                    isCustom: exercise.isCustom,
                  );
                  if (!allowed) {
                    Navigator.pop(sheet);
                    context.push('/premium');
                    return;
                  }
                  Navigator.pop(sheet, exercise);
                },
              ),
          ],
        );
      },
    );
    if (picked == null || !mounted) {
      return;
    }
    try {
      await repos.workouts.addExercise(
        widget.sessionId,
        picked.id,
        isPremium: premium,
      );
    } on PremiumRequired {
      if (mounted) {
        context.push('/premium');
      }
      return;
    }
    await _load();
  }

  Future<void> _finish() async {
    final BiteRepos? repos = context.read<BiteRepos?>();
    if (repos == null) {
      return;
    }
    final double? profileKg = context.read<ProfileProvider>().profile?.weightKg;
    final double? logged = await repos.workouts.latestLoggedWeightKg();
    await repos.workouts.finishSession(
      widget.sessionId,
      logWeightKg: logged,
      profileWeightKg: profileKg,
    );
    if (!mounted) {
      return;
    }
    context.pushReplacement('/workout/summary/${widget.sessionId}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: !_ready
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  const BiteBackButton(),
                  Text(
                    _session?.name ?? 'Session',
                    style: AppTextStyles.appHeading,
                  ),
                  const SizedBox(height: 12),
                  for (final int id in _exerciseIds)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: BiteSurface(
                        child: InkWell(
                          onTap: () async {
                            await context.push(
                              '/workout/exercise/$id?session=${widget.sessionId}',
                            );
                            _load();
                          },
                          child: Row(
                            children: [
                              EmojiTile(emoji: _emoji(id)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_name(id), style: AppTextStyles.body),
                                    Text(_detail(id), style: AppTextStyles.caption),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  TextButton(onPressed: _add, child: const Text('+ Add exercise')),
                  const SizedBox(height: 12),
                  BiteButton(label: 'Finish workout', onPressed: _finish),
                ],
              ),
      ),
    );
  }

  String _name(int id) {
    for (final SessionSet set in _sets) {
      if (set.exerciseId == id) {
        return set.exerciseName;
      }
    }
    return 'Exercise';
  }

  String _emoji(int id) {
    for (final SessionSet set in _sets) {
      if (set.exerciseId == id && set.emoji.isNotEmpty) {
        return set.emoji;
      }
    }
    return '💪';
  }

  String _detail(int id) {
    int count = 0;
    int minutes = 0;
    for (final SessionSet set in _sets) {
      if (set.exerciseId != id || !set.completed) {
        continue;
      }
      count += 1;
      minutes += set.minutes;
    }
    if (minutes > 0) {
      return '$minutes min';
    }
    return '$count sets';
  }

}
