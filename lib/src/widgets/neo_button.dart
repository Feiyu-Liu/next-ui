// Adapted from ChunUI (MIT), Copyright (c) 2026 liseami (赵纯想).
// See third_party/CHUNUI_LICENSE and NOTICE.
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:smooth_corner/smooth_corner.dart';

import 'button_tooltip_region.dart';
import 'neo_button_theme.dart';

/// A skeuomorphic command button ported from ChunUI's `CCNeoButton`.
///
/// The texture comes from the edge rather than the shadow: a three stop
/// vertical fill, a white highlight tucked under the top edge, a hairline
/// gradient border that runs from light to dark, and a shadow that never
/// leaves the ground.
///
/// [onPressed] accepts both synchronous and asynchronous callbacks. When the
/// callback returns a future the button shows a spinner in place of its icon
/// and refuses further taps until the future settles; a synchronous callback
/// never flashes a spinner.
///
/// ```dart
/// NeoButton(
///   'Start',
///   variant: NeoButtonVariant.primary,
///   size: NeoButtonSize.large,
///   icon: LucideIcons.sparkles,
///   fullWidth: true,
///   onPressed: () async => start(),
/// )
/// ```
class NeoButton extends StatefulWidget {
  /// Creates a neo button showing [label].
  const NeoButton(
    this.label, {
    required this.onPressed,
    this.icon,
    this.variant = NeoButtonVariant.primary,
    this.size = NeoButtonSize.medium,
    this.fullWidth = false,
    this.disabled = false,
    this.loading,
    this.accent,
    this.brightness,
    this.semanticsLabel,
    this.enableHapticFeedback,
    this.pressStyle,
    this.textStyle,
    this.contentAlignment = MainAxisAlignment.center,
    super.key,
  });

  /// The text shown on the button. Truncated to a single line.
  final String label;

  /// Invoked on tap. A null callback disables the button.
  ///
  /// Returning a future puts the button into its loading state for the
  /// duration of that future.
  final FutureOr<void> Function()? onPressed;

  /// Optional leading glyph, replaced by the spinner while loading.
  final IconData? icon;

  /// The visual role.
  final NeoButtonVariant variant;

  /// The control height.
  final NeoButtonSize size;

  /// Whether the button expands to fill its parent's width.
  ///
  /// Like SwiftUI's `maxWidth: .infinity`, this requires a bounded width; it
  /// will overflow inside a horizontally unbounded parent such as a horizontal
  /// `ListView`.
  final bool fullWidth;

  /// Whether the button rejects taps and dims.
  final bool disabled;

  /// Overrides the automatic loading state when non-null.
  final bool? loading;

  /// Replaces the primary fill color and forces a white label.
  ///
  /// Ignored by every variant other than [NeoButtonVariant.primary].
  final Color? accent;

  /// Forces a brightness, overriding both the theme and the ambient one.
  final Brightness? brightness;

  /// Accessibility label, defaulting to [label].
  final String? semanticsLabel;

  /// Whether the tap emits a light impact. Defaults to the theme value.
  final bool? enableHapticFeedback;

  /// Whether pressing scales the button or darkens it in place. Defaults to
  /// the theme value.
  final NeoButtonPressStyle? pressStyle;

  /// Merged over the resolved label style.
  final TextStyle? textStyle;

  /// Horizontal alignment of the icon and label inside a full-width button.
  final MainAxisAlignment contentAlignment;

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> {
  bool _autoLoading = false;
  Object? _inFlight;

  bool get _loading => widget.loading ?? _autoLoading;
  bool get _disabled => widget.disabled || widget.onPressed == null;
  bool get _interactive => !_disabled && !_loading;

  /// SwiftUI dims only when disabled, never while a task is running.
  bool get _dimmed => _disabled && !_loading;

  void _handleTap() {
    unawaited(_run().catchError(_reportActionError));
  }

  /// Routes a failed action through [FlutterError] rather than dropping it, so
  /// it surfaces the same way any other widget level async failure does.
  void _reportActionError(Object error, StackTrace stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'my_ui',
        context: ErrorDescription(
          'while running the NeoButton action for "${widget.label}"',
        ),
      ),
    );
  }

  Future<void> _run() async {
    final FutureOr<void> Function()? action = widget.onPressed;
    if (action == null || !_interactive) return;

    final FutureOr<void> result = action();
    if (result is! Future<void>) return;

    final Object token = Object();
    _inFlight = token;
    setState(() => _autoLoading = true);
    try {
      await result;
    } finally {
      // The future is not ours to cancel, so a disposed button simply stops
      // reporting. The token guards against a stale future clearing a newer
      // loading state.
      if (mounted && identical(_inFlight, token)) {
        _inFlight = null;
        setState(() => _autoLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = NeoButtonTheme.of(context);
    final brightness =
        widget.brightness ??
        theme.brightness ??
        CupertinoTheme.brightnessOf(context);
    final accent = CupertinoDynamicColor.maybeResolve(widget.accent, context);
    final style = resolveNeoButtonStyle(
      variant: widget.variant,
      brightness: brightness,
      palette: theme.palette,
      accent: accent,
    );
    final spec = theme.specFor(widget.size);
    final radius = spec.radiusFor(theme.radiusRatio);

    return _NeoPressable(
      onPressed: _interactive ? _handleTap : null,
      semanticsLabel: widget.semanticsLabel,
      dimmed: _dimmed,
      disabledOpacity: theme.disabledOpacity,
      pressedScale: theme.pressedScale,
      spring: theme.pressSpring,
      pressStyle: widget.pressStyle ?? theme.pressStyle,
      hoverDuration: theme.hoverDuration,
      enableHapticFeedback:
          widget.enableHapticFeedback ?? theme.enableHapticFeedback,
      // The whole surface is rebuilt per hover/press frame rather than tinted
      // from above, because an overlay painted over the content would wash
      // out the label along with the fill.
      builder:
          (BuildContext context, double hoverProgress, double pressProgress) =>
              _buildSurface(
                style.withHover(hoverProgress).withPress(pressProgress),
                theme,
                spec,
                radius,
              ),
    );
  }

  Widget _buildSurface(
    NeoButtonVisualStyle style,
    NeoButtonThemeData theme,
    NeoButtonSizeSpec spec,
    double radius,
  ) {
    Widget content = Row(
      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: widget.contentAlignment,
      children: [
        if (_loading) ...[
          CupertinoActivityIndicator(
            radius: theme.spinnerRadius,
            color: style.foregroundColor,
          ),
          SizedBox(width: theme.contentSpacing),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: spec.iconSize, color: style.foregroundColor),
          SizedBox(width: theme.contentSpacing),
        ],
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: spec.fontSize,
              fontWeight: style.fontWeight,
              letterSpacing: 0,
              color: style.foregroundColor,
            ).merge(widget.textStyle),
          ),
        ),
      ],
    );

    content = Padding(
      padding: EdgeInsets.symmetric(horizontal: spec.horizontalPadding),
      child: content,
    );

    if (style.borderGradient != null || style.innerHighlightColor != null) {
      content = CustomPaint(
        key: const ValueKey<String>('neo-button-overlay'),
        foregroundPainter: _NeoButtonOverlayPainter(
          radius: radius,
          smoothness: theme.smoothness,
          innerHighlightColor: style.innerHighlightColor,
          innerHighlightBlurRadius: theme.innerHighlightBlurRadius,
          innerHighlightOffset: theme.innerHighlightOffset,
          borderGradient: style.borderGradient,
          borderWidth: style.borderWidth,
        ),
        child: content,
      );
    }

    return SizedBox(
      height: spec.height,
      width: widget.fullWidth ? double.infinity : null,
      child: DecoratedBox(
        key: const ValueKey<String>('neo-button-surface'),
        decoration: ShapeDecoration(
          color: style.fillColor,
          gradient: style.fillGradient,
          shape: SmoothRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            smoothness: theme.smoothness,
            side: style.borderColor == null
                ? BorderSide.none
                : BorderSide(
                    color: style.borderColor!,
                    width: style.borderWidth,
                  ),
          ),
          shadows: style.dropShadow == null
              ? null
              : <BoxShadow>[style.dropShadow!],
        ),
        child: content,
      ),
    );
  }
}

/// A circular icon button ported from ChunUI's `CCNeoIconButton`.
///
/// Flat by default; [filled] adds the card surface, hairline ring, and soft
/// shadow. Shares the press spring with [NeoButton].
class NeoIconButton extends StatelessWidget {
  /// Creates a circular icon button.
  const NeoIconButton({
    required this.icon,
    required this.onPressed,
    required this.semanticsLabel,
    this.filled = false,
    this.variant,
    this.tooltip,
    this.diameter,
    this.iconSize,
    this.tint,
    this.brightness,
    this.enableHapticFeedback,
    this.pressStyle,
    super.key,
  }) : assert(
         variant == null || !filled,
         'Use either variant or filled, not both.',
       );

  /// The glyph shown at the center.
  final IconData icon;

  /// Invoked on tap. A null callback disables the button.
  final VoidCallback? onPressed;

  /// Accessibility label. Required, because there is no visible text.
  final String semanticsLabel;

  /// Whether to paint the card surface, ring, and shadow.
  final bool filled;

  /// Optional semantic variant shared with [NeoButton].
  ///
  /// When null, [filled] retains the original flat-or-card behavior.
  final NeoButtonVariant? variant;

  /// Optional desktop hover tooltip.
  final String? tooltip;

  /// Overrides the diameter of the hit target.
  final double? diameter;

  /// Overrides the glyph size.
  final double? iconSize;

  /// Overrides the glyph color.
  final Color? tint;

  /// Forces a brightness, overriding both the theme and the ambient one.
  final Brightness? brightness;

  /// Whether the tap emits a light impact. Defaults to the theme value.
  final bool? enableHapticFeedback;

  /// Whether pressing scales the button or darkens it in place. Defaults to
  /// the theme value.
  final NeoButtonPressStyle? pressStyle;

  @override
  Widget build(BuildContext context) {
    final theme = NeoButtonTheme.of(context);
    final resolvedBrightness =
        brightness ?? theme.brightness ?? CupertinoTheme.brightnessOf(context);
    final spec = theme.iconButton;
    final palette = theme.palette;
    final color =
        CupertinoDynamicColor.maybeResolve(tint, context) ??
        palette.mutedForeground.resolve(resolvedBrightness);
    final hoverSurface = palette.hoverSurface.resolve(resolvedBrightness);
    final hoverTint = palette.hoverForeground.resolve(resolvedBrightness);
    final dimension = diameter ?? spec.diameter;

    final button = _NeoPressable(
      onPressed: onPressed,
      semanticsLabel: semanticsLabel,
      dimmed: onPressed == null,
      disabledOpacity: theme.disabledOpacity,
      pressedScale: theme.pressedScale,
      spring: theme.pressSpring,
      pressStyle: pressStyle ?? theme.pressStyle,
      hoverDuration: theme.hoverDuration,
      enableHapticFeedback: enableHapticFeedback ?? theme.enableHapticFeedback,
      builder: (BuildContext context, double hoverProgress, double pressProgress) {
        final variant = this.variant;
        if (variant != null) {
          final style = resolveNeoButtonStyle(
            variant: variant,
            brightness: resolvedBrightness,
            palette: palette,
          ).withHover(hoverProgress).withPress(pressProgress);
          final foreground = CupertinoDynamicColor.maybeResolve(tint, context);
          return _buildVariantSurface(
            style,
            theme,
            spec,
            dimension,
            foreground ?? style.foregroundColor,
          );
        }

        // Press darkens whatever hover already produced; icon tint is left
        // alone, matching NeoButton's withPress leaving foregroundColor put.
        final hoverScrim = hoverSurface.withValues(alpha: hoverProgress);
        final pressScrim = _iconPressScrim(pressProgress);
        Widget content = Center(
          child: Icon(
            icon,
            size: iconSize ?? spec.iconSize,
            color: Color.lerp(color, hoverTint, hoverProgress),
          ),
        );

        if (filled) {
          content = DecoratedBox(
            key: const ValueKey<String>('neo-icon-button-surface'),
            decoration: ShapeDecoration(
              color: Color.alphaBlend(
                pressScrim,
                Color.alphaBlend(
                  hoverScrim,
                  palette.card.resolve(resolvedBrightness),
                ),
              ),
              shape: CircleBorder(
                side: BorderSide(
                  color: Color.alphaBlend(
                    pressScrim,
                    palette.border
                        .resolve(resolvedBrightness)
                        .withValues(alpha: spec.borderOpacity),
                  ),
                  width: spec.borderWidth,
                ),
              ),
              shadows: <BoxShadow>[
                BoxShadow(
                  color: palette.shadow
                      .resolve(resolvedBrightness)
                      .withValues(alpha: spec.shadowOpacity),
                  blurRadius: spec.shadowBlurRadius,
                  offset: spec.shadowOffset,
                ),
              ],
            ),
            child: content,
          );
        } else if (hoverProgress > 0 || pressProgress > 0) {
          // A flat icon button stays flat at rest and grows only the hover or
          // press disc, so it never carries a ring or a shadow it did not
          // ask for.
          content = DecoratedBox(
            key: const ValueKey<String>('neo-icon-button-hover'),
            decoration: ShapeDecoration(
              color: Color.alphaBlend(pressScrim, hoverScrim),
              shape: const CircleBorder(),
            ),
            child: content,
          );
        }

        return SizedBox(width: dimension, height: dimension, child: content);
      },
    );
    return ButtonTooltipRegion(message: tooltip, child: button);
  }

  Widget _buildVariantSurface(
    NeoButtonVisualStyle style,
    NeoButtonThemeData theme,
    NeoIconButtonSpec spec,
    double dimension,
    Color foreground,
  ) {
    Widget content = Center(
      child: Icon(icon, size: iconSize ?? spec.iconSize, color: foreground),
    );
    if (style.borderGradient != null || style.innerHighlightColor != null) {
      content = CustomPaint(
        key: const ValueKey<String>('neo-icon-button-overlay'),
        foregroundPainter: _NeoIconButtonOverlayPainter(
          innerHighlightColor: style.innerHighlightColor,
          innerHighlightBlurRadius: theme.innerHighlightBlurRadius,
          innerHighlightOffset: theme.innerHighlightOffset,
          borderGradient: style.borderGradient,
          borderWidth: style.borderWidth,
        ),
        child: content,
      );
    }
    return SizedBox(
      width: dimension,
      height: dimension,
      child: DecoratedBox(
        key: const ValueKey<String>('neo-icon-button-surface'),
        decoration: ShapeDecoration(
          color: style.fillColor,
          gradient: style.fillGradient,
          shape: CircleBorder(
            side: style.borderColor == null
                ? BorderSide.none
                : BorderSide(
                    color: style.borderColor!,
                    width: style.borderWidth,
                  ),
          ),
          shadows: style.dropShadow == null
              ? null
              : <BoxShadow>[style.dropShadow!],
        ),
        child: content,
      ),
    );
  }
}

/// Gives any widget the neo button family's press feel without its paint.
///
/// [child] keeps its own look; this only adds the spring scale to
/// [NeoButtonThemeData.pressedScale], the light impact on tap, the hover
/// cursor, and the disabled dimming. Use it for controls whose design must
/// stay as is, such as bordered picker rows, but should press like a
/// [NeoButton].
///
/// ```dart
/// NeoPressable(
///   onPressed: () => select(product),
///   child: ProductRow(product),
/// )
/// ```
class NeoPressable extends StatelessWidget {
  /// Creates a pressable wrapper around [child].
  const NeoPressable({
    required this.child,
    required this.onPressed,
    this.semanticsLabel,
    this.dimWhenDisabled = true,
    this.enableHapticFeedback,
    super.key,
  });

  /// The content, painted unchanged apart from the press scale.
  final Widget child;

  /// Invoked on tap. A null callback disables the wrapper.
  final VoidCallback? onPressed;

  /// Accessibility label. Defaults to the semantics of [child].
  final String? semanticsLabel;

  /// Whether a disabled wrapper fades to
  /// [NeoButtonThemeData.disabledOpacity].
  final bool dimWhenDisabled;

  /// Whether the tap emits a light impact. Defaults to the theme value.
  final bool? enableHapticFeedback;

  @override
  Widget build(BuildContext context) {
    final theme = NeoButtonTheme.of(context);
    return _NeoPressable(
      onPressed: onPressed,
      semanticsLabel: semanticsLabel,
      dimmed: dimWhenDisabled && onPressed == null,
      disabledOpacity: theme.disabledOpacity,
      pressedScale: theme.pressedScale,
      spring: theme.pressSpring,
      // The sunken style recolors a resolved neo surface, which an arbitrary
      // child does not have, so only the scale applies here.
      pressStyle: NeoButtonPressStyle.scale,
      hoverDuration: theme.hoverDuration,
      enableHapticFeedback: enableHapticFeedback ?? theme.enableHapticFeedback,
      builder: (BuildContext context, double hover, double press) => child,
    );
  }
}

/// Paints a resolved neo surface — fill, drop shadow, inner highlight, and
/// border — behind an arbitrary [child].
///
/// [NeoButton] only lays out a label; use this for richer content such as a
/// picker row, and wrap it in [NeoPressable] to make it tappable. The style
/// is usually built by hand rather than from [resolveNeoButtonStyle], so the
/// caller can pick gradients that suit a fill the palette does not carry.
class NeoSurface extends StatelessWidget {
  /// Creates a neo surface around [child].
  const NeoSurface({
    required this.style,
    required this.child,
    this.borderRadius,
    this.padding = EdgeInsets.zero,
    this.shape = BoxShape.rectangle,
    super.key,
  });

  /// The paint values. [NeoButtonVisualStyle.foregroundColor] and
  /// [NeoButtonVisualStyle.fontWeight] are ignored; the child styles itself.
  final NeoButtonVisualStyle style;

  /// Corner radius. Defaults to the medium button radius of the theme.
  /// Ignored when [shape] is [BoxShape.circle].
  final double? borderRadius;

  /// The outline: a smooth rounded rectangle, or a circle as drawn by
  /// [NeoIconButton].
  final BoxShape shape;

  /// Space between the edge and [child].
  final EdgeInsetsGeometry padding;

  /// The content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = NeoButtonTheme.of(context);
    final radius =
        borderRadius ??
        theme.specFor(NeoButtonSize.medium).radiusFor(theme.radiusRatio);

    final circular = shape == BoxShape.circle;

    Widget content = Padding(padding: padding, child: child);
    if (style.borderGradient != null || style.innerHighlightColor != null) {
      content = CustomPaint(
        foregroundPainter: circular
            ? _NeoIconButtonOverlayPainter(
                innerHighlightColor: style.innerHighlightColor,
                innerHighlightBlurRadius: theme.innerHighlightBlurRadius,
                innerHighlightOffset: theme.innerHighlightOffset,
                borderGradient: style.borderGradient,
                borderWidth: style.borderWidth,
              )
            : _NeoButtonOverlayPainter(
                radius: radius,
                smoothness: theme.smoothness,
                innerHighlightColor: style.innerHighlightColor,
                innerHighlightBlurRadius: theme.innerHighlightBlurRadius,
                innerHighlightOffset: theme.innerHighlightOffset,
                borderGradient: style.borderGradient,
                borderWidth: style.borderWidth,
              ),
        child: content,
      );
    }

    final side = style.borderColor == null
        ? BorderSide.none
        : BorderSide(color: style.borderColor!, width: style.borderWidth);
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: style.fillColor,
        gradient: style.fillGradient,
        shape: circular
            ? CircleBorder(side: side)
            : SmoothRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
                smoothness: theme.smoothness,
                side: side,
              ),
        shadows: style.dropShadow == null
            ? null
            : <BoxShadow>[style.dropShadow!],
      ),
      child: content,
    );
  }
}

/// Press and hover plumbing shared by [NeoButton] and [NeoIconButton].
class _NeoPressable extends StatefulWidget {
  const _NeoPressable({
    required this.onPressed,
    required this.semanticsLabel,
    required this.dimmed,
    required this.disabledOpacity,
    required this.pressedScale,
    required this.spring,
    required this.pressStyle,
    required this.hoverDuration,
    required this.enableHapticFeedback,
    required this.builder,
  });

  final VoidCallback? onPressed;
  final String? semanticsLabel;
  final bool dimmed;
  final double disabledOpacity;
  final double pressedScale;
  final SpringDescription spring;
  final NeoButtonPressStyle pressStyle;
  final Duration hoverDuration;
  final bool enableHapticFeedback;

  /// Builds the surface for a hover progress and a press progress, each
  /// running from 0 to 1.
  ///
  /// [pressProgress] only ever moves under [NeoButtonPressStyle.sunken]; under
  /// [NeoButtonPressStyle.scale] it stays 0 and the [ScaleTransition] below
  /// carries the pressed cue instead.
  final Widget Function(
    BuildContext context,
    double hoverProgress,
    double pressProgress,
  )
  builder;

  @override
  State<_NeoPressable> createState() => _NeoPressableState();
}

class _NeoPressableState extends State<_NeoPressable>
    with TickerProviderStateMixin {
  /// Drives [NeoButtonPressStyle.scale]. Unbounded so the spring's overshoot
  /// past 1 survives into the scale.
  late final AnimationController _scale = AnimationController.unbounded(
    vsync: this,
  );

  /// Drives [NeoButtonPressStyle.sunken]. Bounded and eased rather than
  /// springy: an overshoot on a color fold would read as a flicker, not a
  /// bounce, since there is no physical displacement to sell it.
  late final AnimationController _pressColor = AnimationController(vsync: this);

  late final AnimationController _hover = AnimationController(vsync: this);

  bool _pressed = false;
  bool _hovered = false;

  bool get _enabled => widget.onPressed != null;

  @override
  void didUpdateWidget(covariant _NeoPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled) {
      _setPressed(false);
      _setHovered(false);
    }
  }

  @override
  void dispose() {
    _scale.dispose();
    _pressColor.dispose();
    _hover.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    if (value && !_enabled) return;
    _pressed = value;
    switch (widget.pressStyle) {
      case NeoButtonPressStyle.scale:
        // Seeding the simulation with the live velocity keeps an interrupted
        // press continuous, which a curve cannot do.
        _scale.animateWith(
          SpringSimulation(
            widget.spring,
            _scale.value,
            value ? 1 : 0,
            _scale.velocity,
          ),
        );
      case NeoButtonPressStyle.sunken:
        _pressColor.animateTo(
          value ? 1 : 0,
          duration: NeoButtonMetrics.pressColorDuration,
          curve: Curves.easeOut,
        );
    }
  }

  void _setHovered(bool value) {
    if (_hovered == value) return;
    if (value && !_enabled) return;
    _hovered = value;
    // animateTo resumes from wherever the fade currently sits, so sweeping the
    // pointer across a row of buttons never snaps.
    _hover.animateTo(
      value ? 1 : 0,
      duration: widget.hoverDuration,
      curve: Curves.easeOut,
    );
  }

  void _handleTap() {
    if (widget.enableHapticFeedback) {
      unawaited(HapticFeedback.lightImpact());
    }
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticsLabel,
      button: true,
      enabled: _enabled,
      child: MouseRegion(
        cursor: _enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => _setHovered(true),
        onExit: (_) => _setHovered(false),
        child: Listener(
          onPointerDown: (_) => _setPressed(true),
          onPointerUp: (_) => _setPressed(false),
          onPointerCancel: (_) => _setPressed(false),
          child: CupertinoButton(
            onPressed: _enabled ? _handleTap : null,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            pressedOpacity: 1,
            child: ScaleTransition(
              key: const ValueKey<String>('neo-button-scale'),
              scale: _scale.drive(
                Tween<double>(begin: 1, end: widget.pressedScale),
              ),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 120),
                opacity: widget.dimmed ? widget.disabledOpacity : 1,
                child: AnimatedBuilder(
                  animation: Listenable.merge(<Listenable>[
                    _hover,
                    _pressColor,
                  ]),
                  builder: (BuildContext context, _) =>
                      widget.builder(context, _hover.value, _pressColor.value),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the inner highlight and the inset gradient border.
///
/// Both live here rather than in the [ShapeDecoration] because a [BorderSide]
/// cannot carry a shader, and because a single painter guarantees the highlight
/// sits between the fill and the border without stacking extra layers.
class _NeoButtonOverlayPainter extends CustomPainter {
  const _NeoButtonOverlayPainter({
    required this.radius,
    required this.smoothness,
    required this.innerHighlightColor,
    required this.innerHighlightBlurRadius,
    required this.innerHighlightOffset,
    required this.borderGradient,
    required this.borderWidth,
  });

  /// Converts a CSS style blur radius into the sigma [MaskFilter] expects.
  static const _blurRadiusToSigma = 0.57735;

  final double radius;
  final double smoothness;
  final Color? innerHighlightColor;
  final double innerHighlightBlurRadius;
  final Offset innerHighlightOffset;
  final Gradient? borderGradient;
  final double borderWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outer = _squircle(radius).getOuterPath(rect);

    final highlight = innerHighlightColor;
    final sigma = innerHighlightBlurRadius * _blurRadiusToSigma;
    if (highlight != null && highlight.a > 0 && sigma > 0) {
      canvas
        ..save()
        ..clipPath(outer);
      // Fill everything outside the squircle, blur it, then shift it down: the
      // overhang bleeds back over the top edge as a highlight.
      final hole = Path()
        ..addRect(rect.inflate(innerHighlightBlurRadius * 4))
        ..addPath(outer, Offset.zero)
        ..fillType = PathFillType.evenOdd;
      canvas
        ..drawPath(
          hole.shift(innerHighlightOffset),
          Paint()
            ..color = highlight
            ..maskFilter = MaskFilter.blur(ui.BlurStyle.normal, sigma),
        )
        ..restore();
    }

    final gradient = borderGradient;
    if (gradient != null && borderWidth > 0) {
      // SwiftUI's strokeBorder insets the shape by half the line width, which
      // shrinks the corner radius by the same amount.
      final inset = borderWidth / 2;
      canvas.drawPath(
        _squircle(
          math.max(0, radius - inset),
        ).getOuterPath(rect.deflate(inset)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth
          ..isAntiAlias = true
          // Built from the full rect: the gradient spans the whole button, not
          // the inset path.
          ..shader = gradient.createShader(rect),
      );
    }
  }

  SmoothRectangleBorder _squircle(double cornerRadius) => SmoothRectangleBorder(
    borderRadius: BorderRadius.circular(cornerRadius),
    smoothness: smoothness,
  );

  @override
  bool shouldRepaint(_NeoButtonOverlayPainter oldDelegate) =>
      oldDelegate.radius != radius ||
      oldDelegate.smoothness != smoothness ||
      oldDelegate.innerHighlightColor != innerHighlightColor ||
      oldDelegate.innerHighlightBlurRadius != innerHighlightBlurRadius ||
      oldDelegate.innerHighlightOffset != innerHighlightOffset ||
      oldDelegate.borderGradient != borderGradient ||
      oldDelegate.borderWidth != borderWidth;
}

class _NeoIconButtonOverlayPainter extends CustomPainter {
  const _NeoIconButtonOverlayPainter({
    required this.innerHighlightColor,
    required this.innerHighlightBlurRadius,
    required this.innerHighlightOffset,
    required this.borderGradient,
    required this.borderWidth,
  });

  final Color? innerHighlightColor;
  final double innerHighlightBlurRadius;
  final Offset innerHighlightOffset;
  final Gradient? borderGradient;
  final double borderWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outer = Path()..addOval(rect);
    final highlight = innerHighlightColor;
    final sigma =
        innerHighlightBlurRadius * _NeoButtonOverlayPainter._blurRadiusToSigma;
    if (highlight != null && highlight.a > 0 && sigma > 0) {
      canvas
        ..save()
        ..clipPath(outer);
      final hole = Path()
        ..addRect(rect.inflate(innerHighlightBlurRadius * 4))
        ..addPath(outer, Offset.zero)
        ..fillType = PathFillType.evenOdd;
      canvas
        ..drawPath(
          hole.shift(innerHighlightOffset),
          Paint()
            ..color = highlight
            ..maskFilter = MaskFilter.blur(ui.BlurStyle.normal, sigma),
        )
        ..restore();
    }

    final gradient = borderGradient;
    if (gradient != null && borderWidth > 0) {
      final inset = borderWidth / 2;
      canvas.drawOval(
        rect.deflate(inset),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth
          ..isAntiAlias = true
          ..shader = gradient.createShader(rect),
      );
    }
  }

  @override
  bool shouldRepaint(_NeoIconButtonOverlayPainter oldDelegate) =>
      oldDelegate.innerHighlightColor != innerHighlightColor ||
      oldDelegate.innerHighlightBlurRadius != innerHighlightBlurRadius ||
      oldDelegate.innerHighlightOffset != innerHighlightOffset ||
      oldDelegate.borderGradient != borderGradient ||
      oldDelegate.borderWidth != borderWidth;
}

/// The black scrim [NeoIconButton] folds into its fill and border at
/// [progress], mirroring [NeoButtonVisualStyle.withPress] without going
/// through a resolved style — [NeoIconButton] paints its own decoration
/// directly rather than through the resolver.
Color _iconPressScrim(double progress) => Color.from(
  alpha: NeoButtonMetrics.pressDarkenOpacity * progress.clamp(0, 1),
  red: 0,
  green: 0,
  blue: 0,
);
