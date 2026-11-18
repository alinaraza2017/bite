import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/greeting.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../ui/widgets/bite_button.dart';
import '../../ui/widgets/labeled_field.dart';
import '../../ui/widgets/staggered_entrance.dart';
import '../../widgets/bite_back_button.dart';
import '../onboarding/profile_provider.dart';

// How it works: the form checks the email and password against the
// accounts table. A match opens Home, or onboarding if setup is unfinished.

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  String _who = '';
  String? _error;
  bool _busy = false;
  bool _asked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_asked) {
      return;
    }
    _asked = true;
    _who = context.read<AuthRepository>().welcomeName() ?? '';
    _loadName();
  }

  Future<void> _loadName() async {
    // Name comes from the accounts row in SQLite, not a hardcoded fallback.
    final String? name = await context.read<AuthRepository>().accountDisplayName();
    if (!mounted || name == null || name.isEmpty) {
      return;
    }
    setState(() => _who = name);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final AuthResult result = await context.read<AuthRepository>().logIn(
      email: _email.text,
      password: _password.text,
    );
    if (!mounted) {
      return;
    }
    if (!result.ok) {
      setState(() {
        _busy = false;
        _error = result.error;
      });
      return;
    }
    await _enter(result.accountId!);
  }

  Future<void> _enter(int accountId) async {
    final ProfileRepository profiles = context.read<ProfileRepository>();
    profiles.accountId = accountId;
    context.read<SessionController>().setAccount(accountId);
    final saved = await profiles.load();
    if (!mounted) {
      return;
    }
    if (saved != null) {
      context.read<ProfileProvider>().setProfile(saved);
    }
    if (!mounted) {
      return;
    }
    context.go(profiles.isOnboardingDone() ? '/home' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.baingan,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            BiteBackButton(
              light: true,
              onPressed: () => BiteBackButton.leavePage(context),
            ),
            const SizedBox(height: 32),
            StaggeredEntrance(
              index: 0,
              child: Text(
                welcomeLine(_who.isEmpty ? null : _who),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.number.copyWith(color: AppColors.card),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'LOG IN',
              style: AppTextStyles.eyebrow.copyWith(color: AppColors.haldi),
            ),
            const SizedBox(height: 32),
            StaggeredEntrance(
              index: 1,
              child: BiteLabeledField(
                controller: _email,
                label: 'Email',
                hint: 'you@email.com',
                keyboardType: TextInputType.emailAddress,
                onInk: true,
              ),
            ),
            StaggeredEntrance(
              index: 2,
              child: BiteLabeledField(
                controller: _password,
                label: 'Password',
                obscure: true,
                onInk: true,
              ),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 8),
            BiteButton(
              label: _busy ? 'Please wait' : 'Log in',
              onPressed: _busy ? null : _submit,
            ),
            TextButton(
              onPressed: () => context.push('/signup'),
              child: Text(
                'Create account',
                style: AppTextStyles.button.copyWith(color: AppColors.card),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
