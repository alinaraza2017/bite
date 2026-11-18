import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/utils/format_numbers.dart';
import '../../domain/feature_gate.dart';
import '../home/day_board.dart';
import '../onboarding/profile_provider.dart';
import 'day_detail_sheet.dart';

// How it works: free accounts open the last 7 days. Older days open
// the paywall. Future days are ignored. Premium uses the existing flag.

Future<void> handleDayTap(
  BuildContext context,
  DateTime day, {
  bool workoutsFirst = false,
  bool selectOnly = false,
}) async {
  final DateTime today = dateOnly(DateTime.now());
  final DateTime target = dateOnly(day);
  if (target.isAfter(today)) {
    return;
  }
  final bool premium = context.read<ProfileProvider>().profile?.isPremium ?? false;
  final bool allowed = FeatureGate(isPremium: premium).canUse(Feature.fullHistory) ||
      isWithinLastDays(target, today, freeHistoryDays);
  if (!allowed) {
    await context.push('/premium');
    return;
  }
  if (selectOnly) {
    await context.read<DayBoard>().showDay(target);
    return;
  }
  await showDayDetail(context, target, workoutsFirst: workoutsFirst);
}
