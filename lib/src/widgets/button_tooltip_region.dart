import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:smooth_corner/smooth_corner.dart';

import 'my_button_theme.dart';

/// Internal desktop tooltip shared by the button families.
class ButtonTooltipRegion extends StatefulWidget {
  const ButtonTooltipRegion({
    required this.message,
    required this.child,
    super.key,
  });

  final String? message;
  final Widget child;

  @override
  State<ButtonTooltipRegion> createState() => _ButtonTooltipRegionState();
}

class _ButtonTooltipRegionState extends State<ButtonTooltipRegion> {
  static const _delay = Duration(milliseconds: 500);

  final LayerLink _link = LayerLink();
  Timer? _timer;
  OverlayEntry? _entry;

  bool get _hasMessage => widget.message?.isNotEmpty ?? false;

  @override
  void didUpdateWidget(covariant ButtonTooltipRegion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hasMessage) _hide();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _entry?.remove();
    super.dispose();
  }

  void _showLater() {
    if (!_hasMessage) return;
    _timer?.cancel();
    _timer = Timer(_delay, () {
      if (!mounted || _entry != null) return;
      final entry = OverlayEntry(
        builder: (context) => CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomRight,
          followerAnchor: Alignment.topRight,
          offset: const Offset(0, 8),
          child: Align(
            alignment: Alignment.topLeft,
            widthFactor: 1,
            heightFactor: 1,
            child: IgnorePointer(child: _ButtonTooltip(widget.message!)),
          ),
        ),
      );
      _entry = entry;
      Overlay.of(context, rootOverlay: true).insert(entry);
    });
  }

  void _hide() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }

  @override
  Widget build(BuildContext context) {
    // The tree shape never depends on whether a message is set: callers toggle
    // [message] to suppress the tooltip while a button is busy or expanded, and
    // swapping the wrapper in and out would re-inflate the whole child subtree —
    // discarding its element state, including any OverlayPortal it holds. The
    // wrappers are layout-transparent, so carrying them unconditionally costs
    // nothing; [_showLater] already declines to open without a message.
    return CompositedTransformTarget(
      link: _link,
      child: MouseRegion(
        onEnter: (_) => _showLater(),
        onExit: (_) => _hide(),
        child: Listener(onPointerDown: (_) => _hide(), child: widget.child),
      ),
    );
  }
}

class _ButtonTooltip extends StatelessWidget {
  const _ButtonTooltip(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: ShapeDecoration(
        color: MyButtonColors.textPrimary,
        shape: SmoothRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          smoothness: MyButtonMetrics.smoothness,
        ),
      ),
      child: Text(
        message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: MyButtonColors.foreground,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
