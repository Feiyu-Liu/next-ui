import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:smooth_corner/smooth_corner.dart';

import 'button_tooltip_region.dart';
import 'morphing_menu_button_theme.dart';

/// Builds the expanded card content for a [MorphingMenuButton].
///
/// Call [close] after a selection when that action should collapse the card.
typedef MorphingMenuContentBuilder =
    Widget Function(BuildContext context, VoidCallback close);

/// Horizontal alignment of the expanded card relative to its trigger.
enum MorphingMenuAlignment {
  /// Aligns the card to the directional leading edge of the trigger.
  start,

  /// Centers the card on the trigger.
  center,

  /// Aligns the card to the directional trailing edge of the trigger.
  end,
}

/// Vertical direction the expanded card of a [MorphingMenuButton] grows toward.
enum MorphingMenuDirection {
  /// Grows upward, so the card's bottom edge sits above the trigger.
  ///
  /// The card never flips to the other side: when the space above cannot hold
  /// the requested height, the height is compressed to what fits instead. A
  /// trigger with almost no room above therefore keeps a collapsed-height card
  /// that overlaps it, which is the cost of a direction that never surprises.
  up,

  /// Grows downward, so the card's top edge sits below the trigger.
  ///
  /// Compresses its height rather than flipping, exactly as [up] does.
  down,

  /// Grows sideways over the trigger itself and keeps the trigger's height,
  /// for an inline control such as a search field that opens where it sits.
  ///
  /// [MorphingMenuButton.alignment] picks the edge held in place: `end` keeps
  /// the trailing edge and grows toward the leading side. The requested and
  /// maximum heights are ignored, there is no drag handle, and the content is
  /// never scaled: it is laid out at its final width against the held edge and
  /// revealed as the card widens, so text does not squash or wobble.
  inPlace,

  /// Prefers [up] and falls back to [down]. The default.
  ///
  /// Measures both sides against the target overlay's edges after
  /// `viewportPadding` and stays [up] whenever the requested height fits above
  /// its trigger anchor, so a card only flips below when the space above cannot
  /// show it and the space below is genuinely roomier. Ties keep the card up.
  ///
  /// The choice is latched for as long as the card stays open, so an anchor
  /// that moves mid-animation cannot flip the card across its trigger.
  auto,
}

/// Opens and closes a [MorphingMenuButton] from outside its own trigger.
///
/// Attach one controller to one button at a time. It is most useful next to
/// [MorphingMenuButton.onTriggerPressed], which suppresses the built-in
/// open-on-press: together they let a trigger act directly in some states and
/// still morph into its card in the states that need one.
///
/// ```dart
/// MorphingMenuButton(
///   controller: _menu,
///   icon: LucideIcons.languages,
///   semanticsLabel: 'Translate',
///   onTriggerPressed: () => busy ? cancel() : _menu.open(),
///   contentBuilder: buildConfirmation,
/// )
/// ```
class MorphingMenuButtonController {
  _MorphingMenuButtonState? _state;

  /// Whether this controller currently drives a mounted button.
  bool get isAttached => _state != null;

  /// Whether the attached button's card is logically open.
  ///
  /// Follows intent rather than the morph: it turns true the moment an open
  /// begins and false the moment a close begins, matching what
  /// [MorphingMenuButton.onExpandedChanged] reports. False while nothing is
  /// attached.
  bool get isExpanded => _state?._expanded ?? false;

  /// Opens the card.
  ///
  /// Does nothing when the card is already open or the button is disabled.
  void open() {
    assert(_state != null, 'No MorphingMenuButton is attached.');
    _state?._open();
  }

  /// Closes the card, doing nothing when it is already closed.
  void close() {
    assert(_state != null, 'No MorphingMenuButton is attached.');
    _state?._close();
  }

  /// Closes an open card and opens a closed one.
  void toggle() {
    assert(_state != null, 'No MorphingMenuButton is attached.');
    _state?._toggle();
  }

  void _attach(_MorphingMenuButtonState state) {
    assert(
      _state == null,
      'A MorphingMenuButtonController can drive only one MorphingMenuButton.',
    );
    _state = state;
  }

  void _detach(_MorphingMenuButtonState state) {
    if (identical(_state, state)) _state = null;
  }
}

/// A button that morphs into an anchored card containing caller-defined UI.
///
/// The expanded card lives in the nearest overlay, so opening it never reflows
/// surrounding layout. It grows away from the trigger in the direction chosen
/// by [MorphingMenuButton.direction], and can close through an outside tap,
/// Escape, a drag toward the trigger, or the callback supplied to
/// [contentBuilder].
class MorphingMenuButton extends StatefulWidget {
  /// Creates a morphing menu button.
  const MorphingMenuButton({
    required this.contentBuilder,
    this.icon,
    this.leading,
    this.label,
    this.semanticsLabel,
    this.tooltip,
    this.enabled = true,
    this.enableDragResize = true,
    this.expandedWidth,
    this.expandedHeight,
    this.maxExpandedHeight,
    this.alignment = MorphingMenuAlignment.start,
    this.direction = MorphingMenuDirection.auto,
    this.onExpandedChanged,
    this.onTriggerPressed,
    this.controller,
    this.style,
    super.key,
  }) : assert(
         (icon == null) != (leading == null),
         'Provide exactly one of icon or leading.',
       ),
       assert(label != null || semanticsLabel != null),
       assert(expandedWidth == null || expandedWidth > 0),
       assert(expandedHeight == null || expandedHeight > 0),
       assert(maxExpandedHeight == null || maxExpandedHeight > 0);

  /// Icon shown by the collapsed trigger when [leading] is null.
  final IconData? icon;

  /// Custom leading widget shown instead of [icon].
  final Widget? leading;

  /// Lazily builds the expanded card content.
  final MorphingMenuContentBuilder contentBuilder;

  /// Optional label shown after [icon].
  final String? label;

  /// Accessible name used when [label] is absent or unsuitable.
  final String? semanticsLabel;

  /// Optional desktop hover tooltip.
  final String? tooltip;

  /// Whether the trigger can open its card.
  final bool enabled;

  /// Whether the expanded card exposes its drag-to-resize handle.
  ///
  /// When false, the card keeps its resolved expanded height and can still be
  /// closed through outside taps, Escape, the trigger, or content callbacks.
  final bool enableDragResize;

  /// Expanded width before the component clamps it to the overlay viewport.
  final double? expandedWidth;

  /// Default expanded height before viewport clamping.
  final double? expandedHeight;

  /// Optional height the card can reach by dragging away from the trigger.
  ///
  /// When null, the drag handle still supports dragging toward the trigger to
  /// close.
  final double? maxExpandedHeight;

  /// Horizontal card alignment relative to the trigger.
  final MorphingMenuAlignment alignment;

  /// Vertical direction the card grows toward.
  ///
  /// Defaults to [MorphingMenuDirection.auto], which opens upward unless the
  /// trigger sits too close to the top of the overlay. An explicit
  /// [MorphingMenuDirection.up] or [MorphingMenuDirection.down] never flips.
  final MorphingMenuDirection direction;

  /// Called once whenever the logical expanded state changes.
  final ValueChanged<bool>? onExpandedChanged;

  /// Replaces what pressing the collapsed trigger does.
  ///
  /// When null a press opens the card. When supplied the press is handed to
  /// this callback instead and nothing opens on its own, so a trigger that
  /// doubles as a direct action stays a single tap in the states that need no
  /// card. Open the card from here — or from anywhere else — through
  /// [controller].
  ///
  /// Only a press on the collapsed trigger arrives here. An open card is
  /// dismissed by its own affordances, which this callback never intercepts.
  final VoidCallback? onTriggerPressed;

  /// Opens and closes this button's card from outside its trigger.
  final MorphingMenuButtonController? controller;

  /// Per-widget style that replaces the inherited style.
  final MorphingMenuButtonStyle? style;

  @override
  State<MorphingMenuButton> createState() => _MorphingMenuButtonState();
}

class _MorphingMenuButtonState extends State<MorphingMenuButton>
    with TickerProviderStateMixin {
  static const double _collapseThreshold = 0.58;

  final OverlayPortalController _portalController = OverlayPortalController();
  final FocusNode _triggerFocusNode = FocusNode();
  final FocusScopeNode _panelFocusScope = FocusScopeNode();
  final Object _tapRegionGroup = Object();

  late final AnimationController _controller;
  late final AnimationController _heightController;
  bool _expanded = false;
  bool _portalVisible = false;
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;
  bool _restoreTriggerFocus = false;

  /// Tears the panel down when a muted ticker never completes the morph.
  Timer? _closeFallback;
  bool _triggerActivatedByPointer = false;
  bool _panelActivatedByPointer = false;
  bool _focusFirstPanelControl = false;
  double? _dragHeight;
  double _heightAnimationStart = 0;
  double _heightAnimationEnd = 0;

  /// Morph progress the current run interpolates from.
  ///
  /// Like an implicit animation, every state change retargets from wherever the
  /// card currently sits and plays its curve forward, so reversing mid-morph
  /// stays continuous and the closing curve is never played backwards.
  double _morphBegin = 0;

  /// Morph progress the current run interpolates to.
  double _morphEnd = 0;

  /// The side resolved when the current card opened.
  ///
  /// [MorphingMenuDirection.auto] re-measures the anchor on every frame, so
  /// without this latch an anchor that moves mid-morph — a scroll, a keyboard,
  /// a rotation — could flip the card across its trigger while it animates.
  MorphingMenuDirection? _openDirection;

  MorphingMenuButtonStyle get _inheritedStyle =>
      widget.style ?? MorphingMenuButtonTheme.of(context).style;

  bool get _reduceMotion =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addStatusListener(_handleAnimationStatus);
    _heightController = AnimationController(vsync: this)
      ..addListener(_handleHeightAnimation);
    _triggerFocusNode.addListener(_handleTriggerFocusChanged);
    widget.controller?._attach(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimationDurations();
  }

  @override
  void didUpdateWidget(covariant MorphingMenuButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
    _syncAnimationDurations();
    if (widget.direction != oldWidget.direction) _openDirection = null;
    if (!widget.enableDragResize && oldWidget.enableDragResize) {
      _dragHeight = null;
    }
    if (!widget.enabled && oldWidget.enabled && _expanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !widget.enabled) _close();
      });
    }
  }

  @override
  void dispose() {
    _closeFallback?.cancel();
    widget.controller?._detach(this);
    _triggerFocusNode
      ..removeListener(_handleTriggerFocusChanged)
      ..dispose();
    _panelFocusScope.dispose();
    _heightController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _syncAnimationDurations() {
    _heightController.duration = _inheritedStyle.heightSnapDuration;
  }

  /// Morph progress at this instant, including any curve overshoot.
  double get _morphProgress {
    if (!_portalVisible) return _morphEnd;
    final style = _inheritedStyle;
    final curve = _morphEnd >= _morphBegin ? style.openCurve : style.closeCurve;
    return lerpDouble(
      _morphBegin,
      _morphEnd,
      curve.transform(_controller.value),
    )!;
  }

  void _handleTriggerFocusChanged() {
    final bool focused = _triggerFocusNode.hasFocus;
    if (_focused == focused || !mounted) return;
    setState(() => _focused = focused);
  }

  void _handleHeightAnimation() {
    if (!mounted || !_expanded) return;
    final progress = Curves.easeOutCubic.transform(_heightController.value);
    setState(() {
      _dragHeight = lerpDouble(
        _heightAnimationStart,
        _heightAnimationEnd,
        progress,
      );
    });
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (!mounted || status != AnimationStatus.completed) return;
    if (_expanded) {
      if (!_focusFirstPanelControl) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_expanded) return;
        if (_panelFocusScope.context == null) return;
        final firstFocus = FocusTraversalGroup.of(
          _panelFocusScope.context!,
        ).findFirstFocus(_panelFocusScope, ignoreCurrentFocus: true);
        firstFocus?.requestFocus();
      });
      return;
    }
    _finishClosing();
  }

  /// Runs what a press on the collapsed trigger means for this caller.
  void _handleTriggerPressed() {
    final override = widget.onTriggerPressed;
    if (override == null) {
      _open();
      return;
    }
    override();
  }

  void _toggle() {
    if (_expanded) {
      _close();
    } else {
      _open();
    }
  }

  /// Reverses an in-flight morph from a pointer tap on the card. Mirrors a
  /// pointer press on the trigger: reopening does not pull focus into the
  /// content, and interrupting an open drops the card without yanking focus
  /// back onto the surface the pointer is already on.
  void _handleInterruptTap() {
    if (_expanded) {
      _close(restoreTriggerFocus: false);
    } else {
      _triggerActivatedByPointer = true;
      _open();
    }
  }

  void _open() {
    if (!widget.enabled || _expanded) return;
    _closeFallback?.cancel();
    _closeFallback = null;
    _focusFirstPanelControl = !_triggerActivatedByPointer;
    _triggerActivatedByPointer = false;
    _panelActivatedByPointer = false;
    _triggerFocusNode.unfocus();
    _restoreTriggerFocus = false;
    _openDirection = null;
    _morphBegin = _morphProgress;
    _morphEnd = 1;
    setState(() {
      _expanded = true;
      _portalVisible = true;
      _dragHeight = null;
    });
    if (!_portalController.isShowing) _portalController.show();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_expanded || _panelFocusScope.context == null) return;
      _panelFocusScope.requestScopeFocus();
    });
    widget.onExpandedChanged?.call(true);
    _runMorph(_inheritedStyle.duration);
  }

  void _close({bool restoreTriggerFocus = true}) {
    if (!_expanded) return;
    _restoreTriggerFocus =
        restoreTriggerFocus &&
        !_panelActivatedByPointer &&
        (_triggerFocusNode.hasFocus || _panelFocusScope.hasFocus);
    _morphBegin = _morphProgress;
    _morphEnd = 0;
    setState(() {
      _expanded = false;
      _pressed = false;
    });
    widget.onExpandedChanged?.call(false);
    final duration = _inheritedStyle.reverseDuration;
    _runMorph(duration);
    if (!_reduceMotion) {
      // The morph's completed status normally tears the portal down. This
      // fallback covers a muted ticker — an offstage or ticker-disabled route
      // never completes the animation, and the panel must not stay up. It is a
      // real timer rather than a fire-and-forget future so that disposing the
      // button cancels it instead of leaving it pending.
      _closeFallback?.cancel();
      _closeFallback = Timer(duration, () {
        if (mounted && !_expanded) _finishClosing();
      });
    }
  }

  /// Plays the retargeted morph forward, mirroring implicit animations.
  void _runMorph(Duration duration) {
    if (_reduceMotion || duration == Duration.zero) {
      _controller
        ..duration = Duration.zero
        ..value = 1
        ..stop();
      if (!_expanded) _finishClosing();
      return;
    }
    _controller
      ..duration = duration
      ..forward(from: 0);
  }

  void _finishClosing() {
    _closeFallback?.cancel();
    _closeFallback = null;
    if (_expanded || !_portalVisible) return;
    if (_portalController.isShowing) _portalController.hide();
    _portalVisible = false;
    _dragHeight = null;
    _openDirection = null;
    _panelActivatedByPointer = false;
    _focusFirstPanelControl = false;
    if (_restoreTriggerFocus) _triggerFocusNode.requestFocus();
    _restoreTriggerFocus = false;
    if (mounted) setState(() {});
  }

  void _setPressed(bool value) {
    if (!widget.enabled || _expanded || _pressed == value) return;
    setState(() => _pressed = value);
  }

  void _handleDragStart(
    DragStartDetails details,
    _MorphingMenuGeometry geometry,
  ) {
    if (!_expanded || !widget.enableDragResize) return;
    _heightController.stop();
    setState(() {
      _dragHeight ??= geometry.expandedRect.height;
    });
  }

  void _handleDragUpdate(
    DragUpdateDetails details,
    _MorphingMenuGeometry geometry,
    double collapsedHeight,
  ) {
    if (!_expanded || !widget.enableDragResize) return;
    // The handle rides the card's free edge, so a downward card grows on the
    // same gesture that shrinks an upward one.
    final double sign = geometry.opensDown ? 1.0 : -1.0;
    setState(() {
      final current = _dragHeight ?? geometry.expandedRect.height;
      _dragHeight = (current + sign * details.delta.dy).clamp(
        collapsedHeight,
        geometry.maxHeight,
      );
    });
  }

  void _handleDragEnd(
    DragEndDetails details,
    _MorphingMenuGeometry geometry,
    double collapsedHeight,
  ) {
    if (!_expanded || !widget.enableDragResize) return;
    // Direction is already folded into `_dragHeight` by the time the gesture
    // ends, so settling is plain height arithmetic.
    final expandedHeight = geometry.expandedRect.height;
    final maxHeight = geometry.maxHeight;
    final current = _dragHeight ?? expandedHeight;
    final span = expandedHeight - collapsedHeight;
    final progress = span <= 0
        ? 1.0
        : ((current - collapsedHeight) / span).clamp(0.0, 1.0);
    if (progress < _collapseThreshold) {
      _close();
      return;
    }
    final canMaximize = maxHeight > expandedHeight;
    final target = canMaximize && current >= (expandedHeight + maxHeight) / 2
        ? maxHeight
        : expandedHeight;
    _heightAnimationStart = current;
    _heightAnimationEnd = target;
    if (_reduceMotion || _inheritedStyle.heightSnapDuration == Duration.zero) {
      setState(() => _dragHeight = target);
    } else {
      _heightController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _resolveDynamicColors(_inheritedStyle, context);

    return TapRegion(
      groupId: _tapRegionGroup,
      onTapOutside: (_) {
        if (_expanded) _close(restoreTriggerFocus: false);
      },
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): _close,
        },
        child: IgnorePointer(
          ignoring: _portalVisible,
          child: ExcludeSemantics(
            excluding: _portalVisible,
            child: ButtonTooltipRegion(
              message: _expanded ? null : widget.tooltip,
              // The collapsed surface has to know the width the caller is
              // forcing on the button. Without it the button shrink-wraps and
              // centers the surface inside a wider slot, stranding the focus
              // ring, the tap target and the morph's starting rect around a
              // pill that is narrower than the box they all belong to.
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) =>
                    _buildTrigger(style, constraints),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrigger(
    MorphingMenuButtonStyle style,
    BoxConstraints constraints,
  ) {
    final Color background = _pressed
        ? style.collapsedPressedColor
        : _hovered
        ? style.collapsedHoverColor
        : style.collapsedBackgroundColor;
    final Color border = _focused
        ? style.focusedBorderColor
        : style.borderColor;

    return Semantics(
      label: widget.semanticsLabel ?? widget.label,
      button: true,
      enabled: widget.enabled,
      expanded: _expanded,
      onTap: widget.enabled ? _handleTriggerPressed : null,
      child: ExcludeSemantics(
        child: MouseRegion(
          cursor: widget.enabled ? SystemMouseCursors.click : MouseCursor.defer,
          onEnter: (_) {
            if (widget.enabled && !_hovered) {
              setState(() => _hovered = true);
            }
          },
          onExit: (_) {
            if (_hovered || _pressed) {
              setState(() {
                _hovered = false;
                _pressed = false;
              });
            }
          },
          child: Listener(
            onPointerDown: (_) {
              _triggerActivatedByPointer = true;
              _setPressed(true);
            },
            onPointerUp: (_) {
              _setPressed(false);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _triggerActivatedByPointer = false;
              });
            },
            onPointerCancel: (_) {
              _triggerActivatedByPointer = false;
              _setPressed(false);
            },
            child: OverlayPortal.overlayChildLayoutBuilder(
              controller: _portalController,
              overlayChildBuilder:
                  (BuildContext overlayContext, OverlayChildLayoutInfo info) =>
                      _buildOverlay(overlayContext, info, style),
              child: CupertinoButton(
                key: const ValueKey<String>('morphing-menu-button-trigger'),
                focusNode: _triggerFocusNode,
                onPressed: widget.enabled ? _handleTriggerPressed : null,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                pressedOpacity: 1,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 120),
                  opacity: widget.enabled ? 1 : style.disabledOpacity,
                  child: Opacity(
                    opacity: _portalVisible ? 0 : 1,
                    child: AnimatedContainer(
                      key: const ValueKey<String>(
                        'morphing-menu-button-trigger-surface',
                      ),
                      duration: const Duration(milliseconds: 90),
                      curve: Curves.easeOutCubic,
                      // A floor, never a ceiling: the surface grows to fill a
                      // slot the caller sized, and shrink-wraps as usual when
                      // nothing is imposed (an unconstrained parent hands down
                      // a minimum of zero).
                      height: math.max(
                        style.buttonHeight,
                        constraints.minHeight,
                      ),
                      constraints: BoxConstraints(
                        minWidth: math.max(
                          style.minButtonWidth,
                          constraints.minWidth,
                        ),
                      ),
                      padding: style.triggerPadding,
                      decoration: ShapeDecoration(
                        color: background,
                        shadows: <BoxShadow>[style.collapsedShadow],
                        shape: SmoothRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            style.collapsedRadius,
                          ),
                          smoothness: style.smoothness,
                          side: BorderSide(
                            color: border,
                            width: _focused
                                ? math.max(1.5, style.borderWidth)
                                : style.borderWidth,
                          ),
                        ),
                      ),
                      child: _TriggerContent(widget: widget, style: style),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay(
    BuildContext context,
    OverlayChildLayoutInfo info,
    MorphingMenuButtonStyle style,
  ) {
    final content = widget.contentBuilder(context, _close);
    final anchorRect = MatrixUtils.transformRect(
      info.childPaintTransform,
      Offset.zero & info.childSize,
    );
    final geometry = _MorphingMenuGeometry.resolve(
      anchorRect: anchorRect,
      overlaySize: info.overlaySize,
      requestedWidth: widget.expandedWidth ?? style.expandedWidth,
      requestedHeight: widget.expandedHeight ?? style.expandedHeight,
      requestedMaxHeight: widget.maxExpandedHeight,
      alignment: widget.alignment,
      direction: _openDirection ?? widget.direction,
      textDirection: Directionality.of(context),
      gap: style.gap,
      viewportPadding: style.viewportPadding,
      collapsedHeight: style.buttonHeight,
    );
    // Memoising a value this build already computed and consumes, so no
    // rebuild is needed — and none may be scheduled from inside build.
    _openDirection ??= geometry.direction;

    // In place the card is exactly the trigger's height as painted, which a
    // scaled ancestor can make shorter than buttonHeight, so it skips the
    // clamp that keeps a resizable card at least one button tall.
    final displayedHeight = geometry.inPlace
        ? geometry.expandedRect.height
        : (_dragHeight ?? geometry.expandedRect.height).clamp(
            style.buttonHeight,
            geometry.maxHeight,
          );

    return SizedBox(
      width: info.overlaySize.width,
      height: info.overlaySize.height,
      child: TapRegion(
        groupId: _tapRegionGroup,
        child: CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(LogicalKeyboardKey.escape): _close,
          },
          child: AnimatedBuilder(
            animation: _controller,
            child: content,
            builder: (BuildContext context, Widget? child) {
              final progress = _morphProgress;
              final paintProgress = progress.clamp(0.0, 1.0);
              final base = geometry.expandedRect;
              // The edge held against the trigger stays put; drag resizing and
              // the elastic overshoot move only the free edge.
              final targetRect = geometry.opensDown
                  ? Rect.fromLTWH(
                      base.left,
                      base.top,
                      base.width,
                      displayedHeight,
                    )
                  : Rect.fromLTWH(
                      base.left,
                      base.bottom - displayedHeight,
                      base.width,
                      displayedHeight,
                    );
              final lerped = Rect.lerp(anchorRect, targetRect, progress)!;
              final rect = Rect.fromLTWH(
                lerped.left,
                lerped.top,
                math.max(0, lerped.width),
                math.max(0, lerped.height),
              );
              return Stack(
                children: <Widget>[
                  Positioned.fromRect(
                    rect: rect,
                    child: Listener(
                      onPointerDown: (_) => _panelActivatedByPointer = true,
                      child: _buildMorphingSurface(
                        style,
                        progress,
                        paintProgress,
                        rect,
                        anchorRect,
                        targetRect,
                        geometry,
                        child!,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMorphingSurface(
    MorphingMenuButtonStyle style,
    double progress,
    double paintProgress,
    Rect rect,
    Rect anchorRect,
    Rect targetRect,
    _MorphingMenuGeometry geometry,
    Widget content,
  ) {
    final radius = math.max(
      0.0,
      lerpDouble(style.collapsedRadius, style.expandedRadius, progress)!,
    );
    final shape = SmoothRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      smoothness: style.smoothness,
      side: BorderSide(
        color: Color.lerp(
          _focused ? style.focusedBorderColor : style.borderColor,
          style.borderColor,
          paintProgress,
        )!,
        width: lerpDouble(
          _focused ? math.max(1.5, style.borderWidth) : style.borderWidth,
          style.borderWidth,
          paintProgress,
        )!,
      ),
    );
    final background = Color.lerp(
      _pressed
          ? style.collapsedPressedColor
          : _hovered
          ? style.collapsedHoverColor
          : style.collapsedBackgroundColor,
      style.expandedBackgroundColor,
      paintProgress,
    )!;
    final shadow = BoxShadow.lerp(
      style.collapsedShadow,
      style.expandedShadow,
      paintProgress,
    )!;
    final revealSpan = style.contentRevealEnd - style.contentRevealStart;
    final contentProgress = revealSpan == 0
        ? (paintProgress >= style.contentRevealEnd ? 1.0 : 0.0)
        : ((paintProgress - style.contentRevealStart) / revealSpan).clamp(
            0.0,
            1.0,
          );
    final triggerOpacity = (1 - paintProgress).clamp(0.0, 1.0);

    // The handle rides the card's free edge, and the room it needs follows it,
    // so `panelPadding` stays purely the caller content's own padding.
    final handleAlignment = geometry.opensDown
        ? Alignment.bottomCenter
        : Alignment.topCenter;
    // A card that grows in place keeps the trigger's height, so it has
    // nothing to resize.
    final dragResizes = widget.enableDragResize && !geometry.inPlace;
    // In place, the trigger glyph and the content both hold to the edge that
    // stays put, so neither drifts while the card widens.
    final AlignmentGeometry heldEdge = switch (widget.alignment) {
      MorphingMenuAlignment.start => AlignmentDirectional.centerStart,
      MorphingMenuAlignment.center => Alignment.center,
      MorphingMenuAlignment.end => AlignmentDirectional.centerEnd,
    };
    final panelPadding = dragResizes
        ? style.panelPadding.add(
            geometry.opensDown
                ? EdgeInsets.only(bottom: style.dragHandleInset)
                : EdgeInsets.only(top: style.dragHandleInset),
          )
        : style.panelPadding;

    return Semantics(
      label: widget.semanticsLabel ?? widget.label,
      container: true,
      expanded: _expanded,
      onTap: _portalVisible ? _toggle : null,
      child: DecoratedBox(
        key: const ValueKey<String>('morphing-menu-button-surface'),
        decoration: ShapeDecoration(
          color: background,
          shadows: <BoxShadow>[shadow],
          shape: shape,
        ),
        child: ClipPath(
          clipper: ShapeBorderClipper(shape: shape),
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: <Widget>[
              // Held at the collapsed size so the elastic undershoot at the end
              // of a close cannot squeeze the icon and label.
              IgnorePointer(
                ignoring: triggerOpacity == 0,
                child: Opacity(
                  key: const ValueKey<String>(
                    'morphing-menu-button-trigger-layer',
                  ),
                  opacity: triggerOpacity,
                  child: OverflowBox(
                    alignment: geometry.inPlace ? heldEdge : Alignment.center,
                    minWidth: anchorRect.width,
                    maxWidth: anchorRect.width,
                    minHeight: anchorRect.height,
                    maxHeight: anchorRect.height,
                    child: Padding(
                      padding: style.triggerPadding,
                      child: _TriggerContent(widget: widget, style: style),
                    ),
                  ),
                ),
              ),
              // Caller content is laid out once at the card's final size. In
              // place it is clipped against the held edge as the card widens;
              // otherwise it is scaled onto the current surface, so it grows
              // with the card the way the reference panel does, without ever
              // being measured against an intermediate, near-trigger-sized
              // box.
              _layoutContent(
                inPlace: geometry.inPlace,
                heldEdge: heldEdge,
                rect: rect,
                targetRect: targetRect,
                content: IgnorePointer(
                  ignoring: !_expanded || contentProgress < 0.999,
                  child: ExcludeSemantics(
                    excluding: contentProgress == 0,
                    child: Opacity(
                      key: const ValueKey<String>(
                        'morphing-menu-button-content',
                      ),
                      opacity: contentProgress,
                      child: FocusScope(
                        node: _panelFocusScope,
                        child: FocusTraversalGroup(
                          child: Padding(padding: panelPadding, child: content),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (dragResizes && paintProgress > 0.3)
                Align(
                  alignment: handleAlignment,
                  child: GestureDetector(
                    key: const ValueKey<String>(
                      'morphing-menu-button-drag-handle',
                    ),
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragStart: (details) =>
                        _handleDragStart(details, geometry),
                    onVerticalDragUpdate: (details) => _handleDragUpdate(
                      details,
                      geometry,
                      style.buttonHeight,
                    ),
                    onVerticalDragEnd: (details) =>
                        _handleDragEnd(details, geometry, style.buttonHeight),
                    child: SizedBox(
                      width: math.max(64, style.dragHandleWidth),
                      // A card compressed onto a cramped side would otherwise
                      // hand most of its surface to the handle's opaque hit
                      // box, swallowing taps meant for the content.
                      height: math.min(
                        style.dragHandleHitHeight,
                        rect.height / 2,
                      ),
                      child: Align(
                        alignment: handleAlignment,
                        child: Container(
                          margin: geometry.opensDown
                              ? const EdgeInsets.only(bottom: 10)
                              : const EdgeInsets.only(top: 10),
                          width: style.dragHandleWidth,
                          height: style.dragHandleHeight,
                          decoration: BoxDecoration(
                            color: style.dragHandleColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // Mid-morph the caller content is inert (it only wakes at
              // contentProgress >= 0.999, and stays asleep the whole way down
              // a close). A tap in that window is the user reaching for the
              // button again to reverse the animation, so it retargets the
              // morph in place instead of falling through to a dead surface.
              // Once the card settles this layer is gone and content plus the
              // drag handle take over again.
              if (_portalVisible && (!_expanded || contentProgress < 0.999))
                Positioned.fill(
                  child: GestureDetector(
                    key: const ValueKey<String>(
                      'morphing-menu-button-interrupt',
                    ),
                    behavior: HitTestBehavior.opaque,
                    onTap: _handleInterruptTap,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _layoutContent({
    required bool inPlace,
    required AlignmentGeometry heldEdge,
    required Rect rect,
    required Rect targetRect,
    required Widget content,
  }) {
    final laidOut = OverflowBox(
      alignment: inPlace ? heldEdge : Alignment.topLeft,
      minWidth: targetRect.width,
      maxWidth: targetRect.width,
      minHeight: targetRect.height,
      maxHeight: targetRect.height,
      child: content,
    );
    if (inPlace) return laidOut;
    return Transform(
      transform: Matrix4.diagonal3Values(
        targetRect.width == 0 ? 1 : rect.width / targetRect.width,
        targetRect.height == 0 ? 1 : rect.height / targetRect.height,
        1,
      ),
      alignment: Alignment.topLeft,
      child: laidOut,
    );
  }
}

class _TriggerContent extends StatelessWidget {
  const _TriggerContent({required this.widget, required this.style});

  final MorphingMenuButton widget;
  final MorphingMenuButtonStyle style;

  @override
  Widget build(BuildContext context) {
    return Align(
      widthFactor: 1,
      heightFactor: 1,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          widget.leading ??
              Icon(
                widget.icon!,
                size: style.iconSize,
                color: style.foregroundColor,
              ),
          if (widget.label != null) ...<Widget>[
            SizedBox(width: style.iconLabelSpacing),
            Flexible(
              child: Text(
                widget.label!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style.textStyle.copyWith(color: style.foregroundColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MorphingMenuGeometry {
  const _MorphingMenuGeometry({
    required this.expandedRect,
    required this.maxHeight,
    required this.direction,
  }) : assert(direction != MorphingMenuDirection.auto);

  /// The card at its default height, on the resolved side of the trigger.
  ///
  /// The edge held against the trigger is [Rect.bottom] when opening up and
  /// [Rect.top] when opening down; the opposite edge is the one drag resizing
  /// and the elastic overshoot move.
  final Rect expandedRect;
  final double maxHeight;

  /// The side the card settled on, or [MorphingMenuDirection.inPlace]. Never
  /// [MorphingMenuDirection.auto].
  final MorphingMenuDirection direction;

  /// Whether the card grows below its trigger.
  bool get opensDown => direction == MorphingMenuDirection.down;

  /// Whether the card grows sideways over its trigger.
  bool get inPlace => direction == MorphingMenuDirection.inPlace;

  static _MorphingMenuGeometry resolve({
    required Rect anchorRect,
    required Size overlaySize,
    required double requestedWidth,
    required double requestedHeight,
    required double? requestedMaxHeight,
    required MorphingMenuAlignment alignment,
    required MorphingMenuDirection direction,
    required TextDirection textDirection,
    required double gap,
    required double viewportPadding,
    required double collapsedHeight,
  }) {
    final maxViewportWidth = math.max(
      collapsedHeight,
      overlaySize.width - viewportPadding * 2,
    );
    final double width = requestedWidth
        .clamp(collapsedHeight, maxViewportWidth)
        .toDouble();

    final desiredBottom = anchorRect.top - gap;
    final desiredTop = anchorRect.bottom + gap;
    final availableAbove = desiredBottom - viewportPadding;
    final availableBelow = (overlaySize.height - viewportPadding) - desiredTop;

    // Explicit directions are honoured as given. `auto` keeps the card up
    // whenever the requested height fits there, and on a tie, so a centered
    // trigger with equal room on both sides never flips.
    final resolvedDirection = switch (direction) {
      MorphingMenuDirection.up => MorphingMenuDirection.up,
      MorphingMenuDirection.down => MorphingMenuDirection.down,
      MorphingMenuDirection.inPlace => MorphingMenuDirection.inPlace,
      MorphingMenuDirection.auto =>
        availableAbove >= requestedHeight || availableAbove >= availableBelow
            ? MorphingMenuDirection.up
            : MorphingMenuDirection.down,
    };
    final bool opensDown = resolvedDirection == MorphingMenuDirection.down;
    final bool inPlace = resolvedDirection == MorphingMenuDirection.inPlace;

    // The requested side is never abandoned: only the height gives way, and
    // never below the collapsed height, which keeps every downstream clamp
    // well ordered.
    final double heightCeiling = math.max(
      collapsedHeight,
      opensDown ? availableBelow : availableAbove,
    );
    // In place the card is the trigger's own height, whatever was requested.
    final double expandedHeight = inPlace
        ? anchorRect.height
        : requestedHeight.clamp(collapsedHeight, heightCeiling).toDouble();
    final requestedMaximum = math.max(
      requestedHeight,
      requestedMaxHeight ?? requestedHeight,
    );
    final double maxHeight = inPlace
        ? expandedHeight
        : requestedMaximum.clamp(expandedHeight, heightCeiling).toDouble();

    final bool startIsLeft = textDirection == TextDirection.ltr;
    final left = switch (alignment) {
      MorphingMenuAlignment.start =>
        startIsLeft ? anchorRect.left : anchorRect.right - width,
      MorphingMenuAlignment.center => anchorRect.center.dx - width / 2,
      MorphingMenuAlignment.end =>
        startIsLeft ? anchorRect.right - width : anchorRect.left,
    };
    final double clampedLeft = left
        .clamp(
          viewportPadding,
          math.max(
            viewportPadding,
            overlaySize.width - viewportPadding - width,
          ),
        )
        .toDouble();

    // Only a side with less than the collapsed height of room reaches this
    // clamp, and then the card is translated into the viewport rather than
    // re-sized or moved to the other side.
    final double idealTop = inPlace
        ? anchorRect.top
        : opensDown
        ? desiredTop
        : desiredBottom - expandedHeight;
    final double maxTop = math.max(
      viewportPadding,
      overlaySize.height - viewportPadding - expandedHeight,
    );
    final double top = idealTop
        .clamp(math.min(viewportPadding, maxTop), maxTop)
        .toDouble();

    return _MorphingMenuGeometry(
      expandedRect: Rect.fromLTWH(clampedLeft, top, width, expandedHeight),
      maxHeight: maxHeight,
      direction: resolvedDirection,
    );
  }
}

MorphingMenuButtonStyle _resolveDynamicColors(
  MorphingMenuButtonStyle style,
  BuildContext context,
) {
  Color resolve(Color color) =>
      CupertinoDynamicColor.maybeResolve(color, context) ?? color;
  return style.copyWith(
    collapsedBackgroundColor: resolve(style.collapsedBackgroundColor),
    collapsedHoverColor: resolve(style.collapsedHoverColor),
    collapsedPressedColor: resolve(style.collapsedPressedColor),
    expandedBackgroundColor: resolve(style.expandedBackgroundColor),
    foregroundColor: resolve(style.foregroundColor),
    borderColor: resolve(style.borderColor),
    focusedBorderColor: resolve(style.focusedBorderColor),
    shadowColor: resolve(style.shadowColor),
    dragHandleColor: resolve(style.dragHandleColor),
    collapsedShadow: style.collapsedShadow.copyWith(
      color: resolve(style.collapsedShadow.color),
    ),
    expandedShadow: style.expandedShadow.copyWith(
      color: resolve(style.expandedShadow.color),
    ),
  );
}
