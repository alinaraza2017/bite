import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/bite_motion.dart';
import '../../core/utils/greeting.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/body_rules.dart';
import '../../domain/models.dart';
import '../../ui/widgets/animated_number.dart';
import '../../ui/widgets/bite_button.dart';
import '../../ui/widgets/staggered_entrance.dart';
import '../../widgets/bite_back_button.dart';
import 'body_form.dart';
import 'profile_provider.dart';

// How it works: three pages on an ink background. The body form is checked,
// then the target counts up. The maths stays in domain/targets_calc.dart.

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pages = PageController();
  int _step = 0;
  bool _nameLoaded = false;
  final TextEditingController _name = TextEditingController();
  Goal _goal = Goal.maintain;
  Sex _sex = Sex.female;
  final TextEditingController _age = TextEditingController(text: '25');
  final TextEditingController _height = TextEditingController(text: '160');
  final TextEditingController _weight = TextEditingController(text: '60');
  ActivityLevel _activity = ActivityLevel.moderate;
  String? _ageError;
  String? _heightError;
  String? _weightError;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_nameLoaded) {
      return;
    }
    _nameLoaded = true;
    final String? quick = firstName(context.read<AuthRepository>().welcomeName());
    if (quick != null) {
      _name.text = quick;
    }
    _loadName();
  }

  Future<void> _loadName() async {
    final String? saved = await context.read<AuthRepository>().accountDisplayName();
    if (!mounted || saved == null || saved.isEmpty) {
      return;
    }
    setState(() => _name.text = saved);
  }

  void _go(int step) {
    setState(() => _step = step);
    _pages.animateToPage(
      step,
      duration: const Duration(milliseconds: 250),
      curve: BiteMotion.move,
    );
  }

  Future<void> _back() async {
    if (_step > 0) {
      _go(_step - 1);
      return;
    }
    final AuthRepository auth = context.read<AuthRepository>();
    final ProfileRepository profiles = context.read<ProfileRepository>();
    final SessionController session = context.read<SessionController>();
    await auth.logOut();
    if (!mounted) {
      return;
    }
    profiles.accountId = null;
    session.setAccount(null);
    context.go('/login');
  }

  @override
  void dispose() {
    _pages.dispose();
    _name.dispose();
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  void _apply() {
    final String? ageError = validateAge(_age.text);
    final String? heightError = validateHeight(_height.text);
    final String? weightError = validateWeight(_weight.text);
    final String name = _name.text.trim();
    final bool missingName = firstName(name) == null;
    if (missingName || ageError != null || heightError != null || weightError != null) {
      setState(() {
        _ageError = ageError;
        _heightError = heightError;
        _weightError = weightError;
        _error = missingName ? 'Sign up needs a username.' : null;
      });
      return;
    }
    context.read<ProfileProvider>().setProfile(
      UserProfile(
        name: name,
        sex: _sex,
        ageYears: int.parse(_age.text.trim()),
        heightCm: double.parse(_height.text.trim()),
        weightKg: double.parse(_weight.text.trim()),
        activity: _activity,
        goal: _goal,
      ),
    );
    setState(() {
      _ageError = null;
      _heightError = null;
      _weightError = null;
      _error = null;
    });
    _go(2);
  }

  Future<void> _finish() async {
    await context.read<ProfileProvider>().saveAndFinish();
    if (!mounted) {
      return;
    }
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final int kcal = context.watch<ProfileProvider>().targets?.calorieTarget ?? 0;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.baingan,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              children: [
                BiteBackButton(light: true, onPressed: () => _back()),
                _StepPills(step: _step),
                const SizedBox(height: 16),
                Expanded(
                  child: PageView(
                    controller: _pages,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _welcome(),
                      _body(),
                      _result(kcal),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _welcome() {
    return ListView(
      children: [
        const SizedBox(height: 48),
        StaggeredEntrance(
          index: 0,
          child: Text(
            welcomeLine(_name.text),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.eyebrow.copyWith(color: AppColors.haldi),
          ),
        ),
        const SizedBox(height: 12),
        StaggeredEntrance(
          index: 1,
          child: Text(
            'Bite',
            textAlign: TextAlign.center,
            style: AppTextStyles.numberLarge.copyWith(
              color: AppColors.card,
              fontSize: 48,
            ),
          ),
        ),
        const SizedBox(height: 12),
        StaggeredEntrance(
          index: 2,
          child: Text(
            'Track food the way you actually eat.',
            textAlign: TextAlign.center,
            style: AppTextStyles.sectionHeading.copyWith(
              color: AppColors.card,
              fontWeight: FontWeight.w400,
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 48),
        StaggeredEntrance(
          index: 3,
          child: BiteButton(
            label: 'Get started',
            onPressed: () => _go(1),
          ),
        ),
      ],
    );
  }

  Widget _body() {
    return ListView(
      children: [
        Text(
          'About you',
          style: AppTextStyles.number.copyWith(color: AppColors.card),
        ),
        const SizedBox(height: 16),
        BodyDetailsForm(
          age: _age,
          height: _height,
          weight: _weight,
          sex: _sex,
          activity: _activity,
          goal: _goal,
          onDark: true,
          ageError: _ageError,
          heightError: _heightError,
          weightError: _weightError,
          onSex: (Sex value) => setState(() => _sex = value),
          onActivity: (ActivityLevel value) => setState(() => _activity = value),
          onGoal: (Goal value) => setState(() => _goal = value),
        ),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: AppColors.error)),
        const SizedBox(height: 12),
        BiteButton(label: 'See my target', onPressed: _apply),
      ],
    );
  }

  Widget _result(int kcal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        Text(
          'YOUR ESTIMATE',
          style: AppTextStyles.eyebrow.copyWith(color: AppColors.card),
        ),
        const SizedBox(height: 8),
        AnimatedNumber(
          value: kcal,
          suffix: ' kcal',
          style: AppTextStyles.numberLarge.copyWith(color: AppColors.haldi),
        ),
        const SizedBox(height: 8),
        Text(
          'These are estimates, not medical advice.',
          style: AppTextStyles.body.copyWith(color: AppColors.card, height: 1.45),
        ),
        const Spacer(),
        BiteButton(label: 'Start tracking', onPressed: _finish),
      ],
    );
  }
}

class _StepPills extends StatelessWidget {
  const _StepPills({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    return Row(
      children: [
        for (int index = 0; index < 3; index++)
          AnimatedContainer(
            duration: still ? Duration.zero : const Duration(milliseconds: 200),
            curve: BiteMotion.enter,
            margin: const EdgeInsets.only(right: 8),
            height: 6,
            width: step == index ? 28 : 8,
            decoration: BoxDecoration(
              color: step == index
                  ? AppColors.chili
                  : AppColors.card.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
      ],
    );
  }
}
