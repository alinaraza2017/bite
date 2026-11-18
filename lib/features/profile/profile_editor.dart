import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/body_rules.dart';
import '../../domain/models.dart';
import '../../ui/widgets/bite_button.dart';
import '../onboarding/body_form.dart';
import '../onboarding/profile_provider.dart';

// How it works: the same body form as setup. Save recalculates the target
// and writes the row for this account. Cancel leaves the old numbers.

class ProfileEditor extends StatefulWidget {
  const ProfileEditor({
    super.key,
    required this.profile,
    required this.onClose,
  });

  final UserProfile profile;
  final VoidCallback onClose;

  @override
  State<ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<ProfileEditor> {
  late final TextEditingController _age;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  late Sex _sex;
  late ActivityLevel _activity;
  late Goal _goal;
  String? _ageError;
  String? _heightError;
  String? _weightError;

  @override
  void initState() {
    super.initState();
    final UserProfile profile = widget.profile;
    _age = TextEditingController(text: '${profile.ageYears}');
    _height = TextEditingController(text: '${profile.heightCm.round()}');
    _weight = TextEditingController(text: '${profile.weightKg.round()}');
    _sex = profile.sex;
    _activity = profile.activity;
    _goal = profile.goal;
  }

  @override
  void dispose() {
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String? ageError = validateAge(_age.text);
    final String? heightError = validateHeight(_height.text);
    final String? weightError = validateWeight(_weight.text);
    if (ageError != null || heightError != null || weightError != null) {
      setState(() {
        _ageError = ageError;
        _heightError = heightError;
        _weightError = weightError;
      });
      return;
    }
    final ProfileProvider provider = context.read<ProfileProvider>();
    provider.setProfile(
      widget.profile.copyWith(
        sex: _sex,
        ageYears: int.parse(_age.text.trim()),
        heightCm: double.parse(_height.text.trim()),
        weightKg: double.parse(_weight.text.trim()),
        activity: _activity,
        goal: _goal,
      ),
    );
    await provider.saveProfile();
    if (!mounted) {
      return;
    }
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Edit details', style: AppTextStyles.appHeading),
        const SizedBox(height: 12),
        BodyDetailsForm(
          age: _age,
          height: _height,
          weight: _weight,
          sex: _sex,
          activity: _activity,
          goal: _goal,
          ageError: _ageError,
          heightError: _heightError,
          weightError: _weightError,
          onSex: (Sex value) => setState(() => _sex = value),
          onActivity: (ActivityLevel value) => setState(() => _activity = value),
          onGoal: (Goal value) => setState(() => _goal = value),
        ),
        const Text(
          'Targets are estimates, not medical advice.',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: 12),
        BiteButton(label: 'Save', onPressed: _save),
        TextButton(
          onPressed: widget.onClose,
          child: Text(
            'Cancel',
            style: AppTextStyles.button.copyWith(color: AppColors.baingan),
          ),
        ),
      ],
    );
  }
}
