import 'package:flutter/material.dart';

import '../../core/theme/bite_motion.dart';

// How it works: a tap shrinks the child a little, then lets it go.
// The button underneath still receives the tap.

class BitePress extends StatefulWidget {
  const BitePress({super.key, required this.child, this.scale = 0.97});

  final Widget child;
  final double scale;

  @override
  State<BitePress> createState() => _BitePressState();
}

class _BitePressState extends State<BitePress> {
  bool _down = false;

  void _setDown(bool next) {
    if (_down == next) {
      return;
    }
    setState(() => _down = next);
  }

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    return Listener(
      onPointerDown: (_) => _setDown(true),
      onPointerUp: (_) => _setDown(false),
      onPointerCancel: (_) => _setDown(false),
      child: AnimatedScale(
        scale: _down && !still ? widget.scale : 1,
        duration: still ? Duration.zero : BiteMotion.press,
        curve: BiteMotion.enter,
        child: widget.child,
      ),
    );
  }
}
