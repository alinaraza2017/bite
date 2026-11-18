import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/bite_repos.dart';
import '../../data/models/gym_models.dart';
import '../../theme/app_theme.dart';
import '../../ui/widgets/animated_number.dart';
import '../../widgets/bite_back_button.dart';
import '../../widgets/buttons.dart';

// How it works: finish already stored the MET estimate. This screen reads it.

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  WorkoutSummary? _session;
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
    if (!mounted) {
      return;
    }
    setState(() => _session = session);
  }

  @override
  Widget build(BuildContext context) {
    final WorkoutSummary? session = _session;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: darkScreenGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: session == null
                ? const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BiteBackButton(light: true),
                      Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BiteBackButton(
                        light: true,
                        onPressed: () => context.go('/workout'),
                      ),
                      const Text(
                        'Session done',
                        style: TextStyle(
                          color: AppColors.card,
                          fontFamily: 'Poppins',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        session.name,
                        style: AppTextStyles.appHeading.copyWith(color: AppColors.haldi),
                      ),
                      const Spacer(),
                      AnimatedNumber(
                        value: session.burnedKcal.round(),
                        suffix: ' kcal',
                        style: AppTextStyles.numberLarge.copyWith(color: AppColors.card),
                      ),
                      Text(
                        '${session.durationMin} min · ${session.totalSets} sets',
                        style: AppTextStyles.body.copyWith(color: AppColors.card),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Estimate based on MET values.',
                        style: AppTextStyles.caption.copyWith(color: AppColors.card),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: 'Done',
                        onPressed: () => context.go('/workout'),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
