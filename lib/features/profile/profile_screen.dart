import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/format_numbers.dart';
import '../../core/utils/greeting.dart';
import '../../core/widgets/bite_card.dart';
import '../../ui/widgets/bite_card.dart';
import '../../widgets/bite_back_button.dart';
import '../../widgets/buttons.dart';
import '../../data/bite_repos.dart';
import '../../data/repositories/auth_repository.dart';
import '../progress/sample_progress_data.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/models.dart';
import '../../theme/app_theme.dart';
import '../onboarding/profile_provider.dart';
import 'profile_editor.dart';

// How it works: the rows read the saved profile. Premium stays off
// until a real purchase exists. Reset clears the row and the flag.

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final ProfileProvider provider = context.watch<ProfileProvider>();
    final UserProfile? profile = provider.profile;
    final int target = provider.targets?.calorieTarget ?? 0;
    final String? accountName = context.read<AuthRepository>().welcomeName();
    final String shownName = profile == null
        ? ''
        : greetingName(profile.name, accountName);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const BiteBackButton(),
            if (profile != null) ...[
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: chiliHaldiGradient,
                  ),
                  child: Text(
                    avatarLetter(profile.name, accountName),
                    style: AppTextStyles.number.copyWith(color: AppColors.card),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                shownName,
                textAlign: TextAlign.center,
                style: AppTextStyles.appHeading,
              ),
              Text(
                '${profile.ageYears} y · ${profile.heightCm.round()} cm · ${profile.weightKg.round()} kg',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 16),
            ],
            if (profile == null)
              const Text('Finish setup to see your profile.', style: AppTextStyles.body)
            else if (_editing)
              ProfileEditor(
                profile: profile,
                onClose: () => setState(() => _editing = false),
              )
            else ...[
              _row('Username', shownName),
              _row('Sex', profile.sex.label),
              _row('Age', '${profile.ageYears}'),
              _row('Height', '${profile.heightCm.round()} cm'),
              _row('Weight', '${profile.weightKg.round()} kg'),
              _row('Activity', profile.activity.label),
              _row('Goal', profile.goal.label),
              _row('Daily target', '${formatNumber(target)} kcal'),
              const SizedBox(height: 8),
              PrimaryButton(
                label: 'Edit details',
                onPressed: () => setState(() => _editing = true),
              ),
              const SizedBox(height: 8),
              BiteCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Premium', style: AppTextStyles.sectionHeading),
                    Text(
                      profile.isPremium ? 'Premium is on' : 'Free plan',
                      style: AppTextStyles.caption,
                    ),
                    TextButton(
                      onPressed: () => context.push('/premium'),
                      child: const Text('See Premium'),
                    ),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Premium (demo)',
                            style: AppTextStyles.body,
                          ),
                        ),
                        Switch(
                          value: profile.isPremium,
                          onChanged: (bool value) {
                            provider.setPremium(value);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              BiteSurface(
                child: InkWell(
                  onTap: () => context.push('/premium'),
                  child: const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Recipe builder',
                          style: AppTextStyles.body,
                        ),
                      ),
                      Text('Coming soon', style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              BiteSurface(
                child: InkWell(
                  onTap: () => context.push('/premium'),
                  child: const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Adaptive targets',
                          style: AppTextStyles.body,
                        ),
                      ),
                      Text('Coming soon', style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ),
              if (kDebugMode) ...[
                TextButton(
                  onPressed: () => _sample(context, true),
                  child: const Text('Generate sample data (debug)'),
                ),
                TextButton(
                  onPressed: () => _sample(context, false),
                  child: const Text('Clear sample data'),
                ),
              ],
              TextButton(
                onPressed: () async {
                  await provider.clearProfile();
                  if (context.mounted) {
                    context.go('/onboarding');
                  }
                },
                child: const Text(
                  'Reset profile',
                  style: TextStyle(color: AppColors.chili),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await context.read<AuthRepository>().logOut();
                  if (!context.mounted) {
                    return;
                  }
                  context.read<ProfileRepository>().accountId = null;
                  context.read<SessionController>().setAccount(null);
                  context.go('/login');
                },
                child: const Text(
                  'Log out',
                  style: TextStyle(color: AppColors.baingan),
                ),
              ),
              const Text(
                'Targets are estimates, not medical advice.',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _sample(BuildContext context, bool generate) async {
    final BiteRepos? repos = context.read<BiteRepos?>();
    if (repos == null) {
      return;
    }
    final SampleProgressData sample = SampleProgressData(repos.database);
    if (generate) {
      await sample.generate();
    } else {
      await sample.clear();
    }
    repos.logs.notifyChanged();
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BiteCard(
        child: Row(
          children: [
            Text(label, style: AppTextStyles.body),
            const Spacer(),
            Text(value, style: AppTextStyles.sectionHeading),
          ],
        ),
      ),
    );
  }
}
