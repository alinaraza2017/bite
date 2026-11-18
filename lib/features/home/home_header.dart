import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/format_numbers.dart';
import '../../core/utils/greeting.dart';
import '../../data/repositories/auth_repository.dart';
import '../day/open_day.dart';

// How it works: the eyebrow is the date being viewed. The line under
// it is Welcome plus accounts.name for the logged-in id.

class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key, required this.profileName, required this.day});

  final String? profileName;
  final DateTime day;

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  String? _accountName;
  bool _asked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_asked) {
      return;
    }
    _asked = true;
    _accountName = context.read<AuthRepository>().welcomeName();
    _load();
  }

  Future<void> _load() async {
    // Reads accounts.name for the logged-in id. "Friend" is dropped.
    final String? name = await context.read<AuthRepository>().accountDisplayName();
    if (!mounted) {
      return;
    }
    setState(() => _accountName = name);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => handleDayTap(context, widget.day),
                child: Text(
                  formatDay(widget.day).toUpperCase(),
                  style: AppTextStyles.eyebrow,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                welcomeLine(_accountName),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.appHeading,
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () => context.push('/profile'),
          customBorder: const CircleBorder(),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.chili,
            child: Text(
              avatarLetter(widget.profileName, _accountName),
              style: AppTextStyles.sectionHeading.copyWith(color: AppColors.card),
            ),
          ),
        ),
      ],
    );
  }
}
