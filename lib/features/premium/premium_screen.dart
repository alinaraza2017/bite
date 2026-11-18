import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bite_back_button.dart';
import '../../widgets/buttons.dart';

// How it works: the prices are shown only. Subscribe does not charge
// anyone and does not flip the premium flag.

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _yearly = true;

  static const List<String> _perks = <String>[
    'All 150+ workouts',
    'Personal record tracking',
    '30-day trends and full history',
    'Unlimited custom foods and exercises',
    'Recipe builder (Coming soon)',
    'Adaptive targets (Coming soon)',
  ];

  Future<void> _soon() async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialog) {
        return AlertDialog(
          content: const Text('Premium is coming soon'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: darkScreenGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                children: [
                  BiteBackButton(
                    light: true,
                    onPressed: () => context.pop(),
                  ),
                  const Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                      children: [
                        TextSpan(text: 'Bite', style: TextStyle(color: AppColors.card)),
                        TextSpan(text: ' Premium', style: TextStyle(color: AppColors.haldi)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Everything in Free, plus:',
                    style: TextStyle(color: AppColors.card, fontFamily: 'Poppins'),
                  ),
                  const SizedBox(height: 12),
                  for (final String item in _perks)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.haldi,
                            child: Icon(Icons.check, size: 14, color: AppColors.baingan),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            item,
                            style: const TextStyle(
                              color: AppColors.card,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  _plan(
                    'Monthly',
                    r'$2.49',
                    null,
                    !_yearly,
                    () => setState(() => _yearly = false),
                  ),
                  const SizedBox(height: 8),
                  _plan(
                    'Yearly',
                    r'$17.99',
                    '7-day free trial · best value',
                    _yearly,
                    () => setState(() => _yearly = true),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Indicative pricing · cancel anytime in Google Play',
                    style: TextStyle(color: AppColors.card, fontFamily: 'Poppins', fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  PremiumButton(
                    label: _yearly ? 'Start free trial' : 'Subscribe',
                    onPressed: _soon,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _plan(
    String title,
    String price,
    String? note,
    bool selected,
    VoidCallback onTap,
  ) {
    return Material(
      color: selected ? AppColors.haldi : AppColors.card.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppColors.haldi : AppColors.clear,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.sectionHeading.copyWith(
                        color: selected ? AppColors.baingan : AppColors.card,
                      ),
                    ),
                    if (note != null)
                      Text(
                        note,
                        style: AppTextStyles.caption.copyWith(
                          color: selected ? AppColors.baingan : AppColors.haldi,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                price,
                style: AppTextStyles.sectionHeading.copyWith(
                  color: selected ? AppColors.baingan : AppColors.card,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
