import 'package:flutter/material.dart';

// How it works: every animation uses one of these three speeds.
// Entrances ease out. Moves between screens ease in and out.

class BiteMotion {
  BiteMotion._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration entrance = Duration(milliseconds: 350);
  static const Duration press = Duration(milliseconds: 100);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve move = Curves.easeInOut;
}
