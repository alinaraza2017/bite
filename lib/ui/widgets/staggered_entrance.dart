import 'package:flutter/material.dart';

import '../../core/theme/bite_motion.dart';

// How it works: each item fades and rises 12 px, a little after the one before.
// It runs once. Reduced motion shows the item immediately.

class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance> {
  bool _show = false;
  bool _motion = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motion = !MediaQuery.disableAnimationsOf(context);
    if (_show || _started) {
      return;
    }
    _started = true;
    if (!_motion) {
      setState(() => _show = true);
      return;
    }
    final int wait = 50 * widget.index;
    Future<void>.delayed(Duration(milliseconds: wait), () {
      if (mounted) {
        setState(() => _show = true);
      }
    });
  }

  bool _started = false;

  @override
  Widget build(BuildContext context) {
    final Duration time = _motion ? BiteMotion.entrance : Duration.zero;
    return AnimatedSlide(
      offset: _show ? Offset.zero : const Offset(0, 0.06),
      duration: time,
      curve: BiteMotion.enter,
      child: AnimatedOpacity(
        opacity: _show ? 1 : 0,
        duration: time,
        curve: BiteMotion.enter,
        child: widget.child,
      ),
    );
  }
}
