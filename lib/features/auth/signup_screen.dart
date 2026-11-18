import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../ui/widgets/bite_button.dart';
import '../../ui/widgets/labeled_field.dart';
import '../../ui/widgets/staggered_entrance.dart';
import '../../widgets/bite_back_button.dart';

// How it works: a new row is added to accounts. The password is hashed
// first. Setup continues on the About you screen for this account only.

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _again = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _again.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_password.text != _again.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final AuthResult result = await context.read<AuthRepository>().signUp(
      name: _name.text,
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
    final ProfileRepository profiles = context.read<ProfileRepository>();
    profiles.accountId = result.accountId;
    context.read<SessionController>().setAccount(result.accountId);
    context.go('/onboarding');
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
            BiteBackButton(light: true, onPressed: () => context.pop()),
            const SizedBox(height: 16),
            StaggeredEntrance(
              index: 0,
              child: Text(
                'Create account',
                style: AppTextStyles.number.copyWith(color: AppColors.card),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'SAVED ON THIS PHONE ONLY',
              style: AppTextStyles.eyebrow.copyWith(color: AppColors.haldi),
            ),
            const SizedBox(height: 24),
            StaggeredEntrance(
              index: 1,
              child: BiteLabeledField(
                controller: _name,
                label: 'Username',
                hint: 'Ayesha',
                onInk: true,
              ),
            ),
            BiteLabeledField(
              controller: _email,
              label: 'Email',
              hint: 'you@email.com',
              keyboardType: TextInputType.emailAddress,
              onInk: true,
            ),
            BiteLabeledField(
              controller: _password,
              label: 'Password',
              hint: 'At least 6 characters',
              obscure: true,
              onInk: true,
            ),
            BiteLabeledField(
              controller: _again,
              label: 'Confirm password',
              obscure: true,
              onInk: true,
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 8),
            BiteButton(
              label: _busy ? 'Please wait' : 'Sign up',
              onPressed: _busy ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
