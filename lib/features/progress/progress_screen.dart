import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_text_styles.dart';
import '../../data/bite_repos.dart';
import '../../domain/feature_gate.dart';
import '../../ui/widgets/bite_button.dart';
import '../../ui/widgets/bite_card.dart';
import '../../ui/widgets/bite_empty_state.dart';
import '../../ui/widgets/labeled_field.dart';
import '../onboarding/profile_provider.dart';
import '../day/open_day.dart';
import 'progress_board.dart';
import 'progress_view.dart';
import 'sample_progress_data.dart';

// How it works: the board reloads after a meal or a workout.
// A slow load shows a skeleton. No rows at all shows the empty state.

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  ProgressBoard? _board;
  bool _started = false;
  bool _skeleton = false;
  Timer? _slow;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    final BiteRepos? repos = context.read<BiteRepos?>();
    if (repos == null) {
      return;
    }
    _board = ProgressBoard(repos);
    _board!.addListener(_onBoard);
    _slow = Timer(const Duration(milliseconds: 150), () {
      if (mounted && _board != null && !_board!.ready) {
        setState(() => _skeleton = true);
      }
    });
    _reload();
  }

  void _onBoard() {
    if (!mounted) {
      return;
    }
    setState(() => _skeleton = false);
  }

  Future<void> _reload() async {
    final ProgressBoard? board = _board;
    if (board == null) {
      return;
    }
    final targets = context.read<ProfileProvider>().targets;
    await board.reload(
      calorieTarget: targets?.calorieTarget ?? 0,
      proteinTarget: (targets?.proteinGrams ?? 0).toDouble(),
    );
  }

  void _range(int days) {
    final ProgressBoard? board = _board;
    if (board == null) {
      return;
    }
    final targets = context.read<ProfileProvider>().targets;
    board.reload(
      days: days,
      calorieTarget: targets?.calorieTarget ?? 0,
      proteinTarget: (targets?.proteinGrams ?? 0).toDouble(),
    );
  }

  Future<void> _addWeight() async {
    final ProgressBoard? board = _board;
    if (board == null) {
      return;
    }
    // The sheet keeps the text controller until it has left the screen.
    // Disposing it here used to crash the field while the sheet was closing.
    final double? kg = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheet) => const _WeightEntrySheet(),
    );
    if (!mounted || kg == null) {
      return;
    }
    await board.repository.addWeight(kg);
    await _reload();
  }

  Future<void> _sample(bool generate) async {
    final ProgressBoard? board = _board;
    if (board == null) {
      return;
    }
    final SampleProgressData sample = SampleProgressData(board.repos.database);
    if (generate) {
      await sample.generate();
    } else {
      await sample.clear();
    }
    board.repos.logs.notifyChanged();
    await _reload();
  }

  @override
  void dispose() {
    _slow?.cancel();
    _board?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BiteRepos? repos = context.watch<BiteRepos?>();
    final bool premium = context.watch<ProfileProvider>().profile?.isPremium ?? false;
    final bool fullHistory = FeatureGate(isPremium: premium).canUse(Feature.fullHistory);
    final ProgressBoard? board = _board;
    if (repos == null || board == null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          BiteEmptyState(
            emoji: '📈',
            message:
                'Nothing to show yet. Log your first meal and your progress will appear here.',
            actionLabel: 'Log food',
            onAction: () => context.go('/food'),
          ),
        ],
      );
    }
    if (board.error != null) {
      return Center(
        child: BiteButton(label: 'Try again', onPressed: _reload),
      );
    }
    if (!board.ready) {
      if (!_skeleton) {
        return const SizedBox.shrink();
      }
      return const _Skeleton();
    }
    final int range = fullHistory ? board.dayCount : freeHistoryDays;
    if (!fullHistory && board.dayCount != freeHistoryDays) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _range(freeHistoryDays);
        }
      });
    }
    final targets = context.watch<ProfileProvider>().targets;
    return ProgressView(
      report: board.report,
      premium: fullHistory,
      range: range,
      calorieTarget: targets?.calorieTarget ?? 0,
      proteinTarget: targets?.proteinGrams ?? 0,
      carbTarget: targets?.carbGrams ?? 0,
      fatTarget: targets?.fatGrams ?? 0,
      onRange: _range,
      onLockedRange: () => context.push('/premium'),
      onLogFood: () => context.go('/food'),
      onAddWeight: _addWeight,
      onPremium: () => context.push('/premium'),
      onOpenDay: (DateTime day) => handleDayTap(context, day),
      onOpenWorkoutDay: (DateTime day) {
        handleDayTap(context, day, workoutsFirst: true);
      },
      onGenerateSample: kDebugMode ? () => _sample(true) : null,
      onClearSample: kDebugMode ? () => _sample(false) : null,
    );
  }
}

class _WeightEntrySheet extends StatefulWidget {
  const _WeightEntrySheet();

  @override
  State<_WeightEntrySheet> createState() => _WeightEntrySheetState();
}

class _WeightEntrySheetState extends State<_WeightEntrySheet> {
  final TextEditingController _kilos = TextEditingController();

  @override
  void dispose() {
    final TextEditingController kilos = _kilos;
    super.dispose();
    // The closing frame still draws the field. Drop the controller after that.
    WidgetsBinding.instance.addPostFrameCallback((_) => kilos.dispose());
  }

  void _save() {
    final double? kg = double.tryParse(_kilos.text.trim());
    if (kg == null || kg <= 0) {
      return;
    }
    Navigator.pop(context, kg);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BiteLabeledField(
            controller: _kilos,
            label: 'Weight',
            suffix: 'kg',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          BiteButton(
            label: 'Save weight',
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Text('YOUR PROGRESS', style: AppTextStyles.eyebrow),
        const SizedBox(height: 24),
        for (int index = 0; index < 3; index++)
          const Padding(
            padding: EdgeInsets.only(bottom: 24),
            child: BiteSurface(
              child: SizedBox(height: 72),
            ),
          ),
      ],
    );
  }
}
