// Adapted from ChunUI (MIT), Copyright (c) 2026 liseami (赵纯想).
// See third_party/CHUNUI_LICENSE and NOTICE.
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

/// A light/dark color pair that is resolved from a [Brightness].
///
/// The neo button family paints part of its surface inside a [CustomPainter],
/// where no [BuildContext] is available. Storing tokens as a [NeoColor] and
/// resolving them once during `build` keeps that boundary honest: painters
/// receive plain [Color] values, so a token that was never resolved is a
/// compile error rather than a silent fallback to the light variant.
@immutable
class NeoColor {
  /// Creates a color pair with distinct light and dark variants.
  const NeoColor({required this.light, required this.dark});

  /// Creates a pair that uses [color] in both brightnesses.
  const NeoColor.constant(Color color) : light = color, dark = color;

  /// The variant used under [Brightness.light].
  final Color light;

  /// The variant used under [Brightness.dark].
  final Color dark;

  /// Returns the variant matching [brightness].
  Color resolve(Brightness brightness) => switch (brightness) {
    Brightness.light => light,
    Brightness.dark => dark,
  };

  /// Returns a copy with [alpha] applied to both variants.
  NeoColor withValues({double? alpha}) => NeoColor(
    light: light.withValues(alpha: alpha),
    dark: dark.withValues(alpha: alpha),
  );

  /// Linearly interpolates between two color pairs.
  static NeoColor? lerp(NeoColor? a, NeoColor? b, double t) {
    if (a == null && b == null) return null;
    return NeoColor(
      light: Color.lerp(a?.light, b?.light, t)!,
      dark: Color.lerp(a?.dark, b?.dark, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NeoColor && other.light == light && other.dark == dark;

  @override
  int get hashCode => Object.hash(light, dark);

  @override
  String toString() => 'NeoColor(light: $light, dark: $dark)';
}

/// The five visual roles of the neo button family.
enum NeoButtonVariant {
  /// Brand-colored gradient fill. The default call to action.
  primary,

  /// Card fill with a hairline border.
  secondary,

  /// No fill and no border.
  ghost,

  /// No fill with a one point border.
  outline,

  /// Destructive gradient fill.
  danger,
}

/// The three control heights of the neo button family.
enum NeoButtonSize {
  /// A 34 point tall button.
  small,

  /// A 44 point tall button.
  medium,

  /// A 52 point tall button.
  large,
}

/// How [NeoButton] and [NeoIconButton] render the pressed state.
enum NeoButtonPressStyle {
  /// The ChunUI original: a spring-simulated scale to
  /// [NeoButtonMetrics.pressedScale], colors untouched.
  scale,

  /// No scale. The fill and border darken as if the button sank into the
  /// surface, mirroring `MyButton`'s pressed state
  /// (`lib/src/widgets/my_button_theme.dart`). The inner highlight and drop
  /// shadow are left alone.
  sunken,
}

/// Geometry for a single [NeoButtonSize].
@immutable
class NeoButtonSizeSpec {
  /// Creates a size specification.
  const NeoButtonSizeSpec({
    required this.height,
    required this.horizontalPadding,
    required this.iconSize,
    required this.fontSize,
  });

  /// Geometry for [NeoButtonSize.small].
  static const small = NeoButtonSizeSpec(
    height: 34,
    horizontalPadding: 14,
    iconSize: 14,
    fontSize: 13,
  );

  /// Geometry for [NeoButtonSize.medium].
  static const medium = NeoButtonSizeSpec(
    height: 44,
    horizontalPadding: 18,
    iconSize: 16,
    fontSize: 17,
  );

  /// Geometry for [NeoButtonSize.large].
  ///
  /// Shares [fontSize] with [medium]; the sizes differ only in height,
  /// padding, and icon size.
  static const large = NeoButtonSizeSpec(
    height: 52,
    horizontalPadding: 22,
    iconSize: 18,
    fontSize: 17,
  );

  /// The fixed control height.
  final double height;

  /// Padding applied to each side of the content row.
  final double horizontalPadding;

  /// The size of the leading icon.
  final double iconSize;

  /// The label font size.
  final double fontSize;

  /// The corner radius for this size, clamped to a capsule at most.
  double radiusFor(double radiusRatio) =>
      math.min(height * radiusRatio, height / 2);

  /// Returns a copy with the given fields replaced.
  NeoButtonSizeSpec copyWith({
    double? height,
    double? horizontalPadding,
    double? iconSize,
    double? fontSize,
  }) => NeoButtonSizeSpec(
    height: height ?? this.height,
    horizontalPadding: horizontalPadding ?? this.horizontalPadding,
    iconSize: iconSize ?? this.iconSize,
    fontSize: fontSize ?? this.fontSize,
  );

  @override
  bool operator ==(Object other) =>
      other is NeoButtonSizeSpec &&
      other.height == height &&
      other.horizontalPadding == horizontalPadding &&
      other.iconSize == iconSize &&
      other.fontSize == fontSize;

  @override
  int get hashCode =>
      Object.hash(height, horizontalPadding, iconSize, fontSize);
}

/// Geometry for [NeoIconButton].
@immutable
class NeoIconButtonSpec {
  /// Creates an icon button specification.
  const NeoIconButtonSpec({
    this.diameter = 40,
    this.iconSize = 18,
    this.borderWidth = NeoButtonMetrics.hairlineBorderWidth,
    this.borderOpacity = 0.9,
    this.shadowOpacity = 0.05,
    this.shadowBlurRadius = NeoButtonMetrics.dropShadowBlurRadius,
    this.shadowOffset = const Offset(0, 1),
  });

  /// The package default specification.
  static const fallback = NeoIconButtonSpec();

  /// The diameter of the circular hit target.
  final double diameter;

  /// The size of the glyph.
  final double iconSize;

  /// Border width used when the button is filled.
  final double borderWidth;

  /// Opacity applied to the border color when the button is filled.
  final double borderOpacity;

  /// Opacity applied to the shadow color when the button is filled.
  final double shadowOpacity;

  /// Shadow blur used when the button is filled.
  final double shadowBlurRadius;

  /// Shadow offset used when the button is filled.
  final Offset shadowOffset;

  /// Returns a copy with the given fields replaced.
  NeoIconButtonSpec copyWith({
    double? diameter,
    double? iconSize,
    double? borderWidth,
    double? borderOpacity,
    double? shadowOpacity,
    double? shadowBlurRadius,
    Offset? shadowOffset,
  }) => NeoIconButtonSpec(
    diameter: diameter ?? this.diameter,
    iconSize: iconSize ?? this.iconSize,
    borderWidth: borderWidth ?? this.borderWidth,
    borderOpacity: borderOpacity ?? this.borderOpacity,
    shadowOpacity: shadowOpacity ?? this.shadowOpacity,
    shadowBlurRadius: shadowBlurRadius ?? this.shadowBlurRadius,
    shadowOffset: shadowOffset ?? this.shadowOffset,
  );

  @override
  bool operator ==(Object other) =>
      other is NeoIconButtonSpec &&
      other.diameter == diameter &&
      other.iconSize == iconSize &&
      other.borderWidth == borderWidth &&
      other.borderOpacity == borderOpacity &&
      other.shadowOpacity == shadowOpacity &&
      other.shadowBlurRadius == shadowBlurRadius &&
      other.shadowOffset == shadowOffset;

  @override
  int get hashCode => Object.hash(
    diameter,
    iconSize,
    borderWidth,
    borderOpacity,
    shadowOpacity,
    shadowBlurRadius,
    shadowOffset,
  );
}

/// The semantic colors the neo button family consumes.
@immutable
class NeoButtonPalette {
  /// Creates a palette, defaulting every slot to the package tokens.
  const NeoButtonPalette({
    this.foreground = NeoButtonColors.foreground,
    this.card = NeoButtonColors.card,
    this.primary = NeoButtonColors.primary,
    this.primaryForeground = NeoButtonColors.primaryForeground,
    this.mutedForeground = NeoButtonColors.mutedForeground,
    this.hoverSurface = NeoButtonColors.hoverSurface,
    this.hoverForeground = NeoButtonColors.hoverForeground,
    this.destructive = NeoButtonColors.destructive,
    this.border = NeoButtonColors.border,
    this.shadow = NeoButtonColors.shadow,
  });

  /// The package default palette.
  static const fallback = NeoButtonPalette();

  /// Label color for the non-solid variants.
  final NeoColor foreground;

  /// Fill color for [NeoButtonVariant.secondary] and filled icon buttons.
  final NeoColor card;

  /// Base color of the [NeoButtonVariant.primary] gradient.
  final NeoColor primary;

  /// Label color on top of [primary].
  final NeoColor primaryForeground;

  /// Default tint for [NeoIconButton].
  final NeoColor mutedForeground;

  /// Surface painted under the pointer on the neutral variants.
  final NeoColor hoverSurface;

  /// Label color reached on top of [hoverSurface].
  final NeoColor hoverForeground;

  /// Base color of the [NeoButtonVariant.danger] gradient.
  final NeoColor destructive;

  /// Border color for the outlined variants.
  final NeoColor border;

  /// Base color for drop shadows.
  final NeoColor shadow;

  /// Returns a copy with the given slots replaced.
  NeoButtonPalette copyWith({
    NeoColor? foreground,
    NeoColor? card,
    NeoColor? primary,
    NeoColor? primaryForeground,
    NeoColor? mutedForeground,
    NeoColor? hoverSurface,
    NeoColor? hoverForeground,
    NeoColor? destructive,
    NeoColor? border,
    NeoColor? shadow,
  }) => NeoButtonPalette(
    foreground: foreground ?? this.foreground,
    card: card ?? this.card,
    primary: primary ?? this.primary,
    primaryForeground: primaryForeground ?? this.primaryForeground,
    mutedForeground: mutedForeground ?? this.mutedForeground,
    hoverSurface: hoverSurface ?? this.hoverSurface,
    hoverForeground: hoverForeground ?? this.hoverForeground,
    destructive: destructive ?? this.destructive,
    border: border ?? this.border,
    shadow: shadow ?? this.shadow,
  );

  @override
  bool operator ==(Object other) =>
      other is NeoButtonPalette &&
      other.foreground == foreground &&
      other.card == card &&
      other.primary == primary &&
      other.primaryForeground == primaryForeground &&
      other.mutedForeground == mutedForeground &&
      other.hoverSurface == hoverSurface &&
      other.hoverForeground == hoverForeground &&
      other.destructive == destructive &&
      other.border == border &&
      other.shadow == shadow;

  @override
  int get hashCode => Object.hash(
    foreground,
    card,
    primary,
    primaryForeground,
    mutedForeground,
    hoverSurface,
    hoverForeground,
    destructive,
    border,
    shadow,
  );
}

/// Fully resolved paint values for one variant at one brightness.
///
/// [borderColor] and [borderGradient] are mutually exclusive. A solid border is
/// painted by the button's [ShapeDecoration]; a gradient border needs a custom
/// painter, because a [BorderSide] cannot carry a shader.
///
/// The values describe the resting surface. Hover is folded in afterwards by
/// [withHover], which keeps this a single description of one variant rather
/// than one per pointer state.
@immutable
class NeoButtonVisualStyle {
  /// Creates a resolved style.
  const NeoButtonVisualStyle({
    required this.foregroundColor,
    required this.fontWeight,
    this.fillColor,
    this.fillGradient,
    this.innerHighlightColor,
    this.borderColor,
    this.borderGradient,
    this.borderWidth = 0,
    this.dropShadow,
    this.hoverOverlayColor,
    this.hoverForegroundColor,
  }) : assert(
         borderColor == null || borderGradient == null,
         'A neo button border is either solid or a gradient, never both.',
       );

  /// Color for the label, icon, and spinner.
  final Color foregroundColor;

  /// Weight for the label.
  final FontWeight fontWeight;

  /// Flat fill, when the variant does not use a gradient.
  final Color? fillColor;

  /// Vertical three stop fill, when the variant uses one.
  ///
  /// Typed as a [LinearGradient] rather than a [Gradient] so [withHover] can
  /// rebuild it stop by stop.
  final LinearGradient? fillGradient;

  /// Highlight drawn just inside the top edge, or null for no highlight.
  final Color? innerHighlightColor;

  /// Solid inset border color, or null when the border is a gradient.
  final Color? borderColor;

  /// Gradient inset border, or null when the border is solid.
  ///
  /// Typed as a [LinearGradient] rather than a [Gradient] so [withPress] can
  /// rebuild it stop by stop, the same reason [fillGradient] is narrowed.
  final LinearGradient? borderGradient;

  /// Width of the inset border. Zero when the variant has no border.
  final double borderWidth;

  /// Shadow cast under the button, or null for no shadow.
  final BoxShadow? dropShadow;

  /// Color composited over the fill while hovered, or null to ignore hover.
  ///
  /// Opaque on the neutral variants, where it takes the surface over outright;
  /// a translucent white lift on the brand variants, which keeps their gradient
  /// intact. Never applied to the border or the shadow: this family carries its
  /// texture on the edge, and hover must not disturb it.
  final Color? hoverOverlayColor;

  /// Label color reached at full hover, or null to hold [foregroundColor].
  final Color? hoverForegroundColor;

  /// Returns this style with the hover overlay composited in at [progress].
  ///
  /// [progress] runs from 0 (resting) to 1 (fully hovered) so the transition
  /// can be animated; a style with no [hoverOverlayColor] returns itself.
  NeoButtonVisualStyle withHover(double progress) {
    final Color? overlay = hoverOverlayColor;
    final double t = progress.clamp(0, 1);
    if (overlay == null || t == 0) return this;

    final Color scrim = overlay.withValues(alpha: overlay.a * t);
    final Color? target = hoverForegroundColor;
    return NeoButtonVisualStyle(
      foregroundColor: target == null
          ? foregroundColor
          : Color.lerp(foregroundColor, target, t)!,
      fontWeight: fontWeight,
      // A gradient fill keeps its color slot null, because ShapeDecoration
      // refuses to hold both.
      fillColor: fillGradient != null
          ? fillColor
          : Color.alphaBlend(scrim, fillColor ?? _transparent),
      fillGradient: _blendGradient(fillGradient, scrim),
      innerHighlightColor: innerHighlightColor,
      borderColor: borderColor,
      borderGradient: borderGradient,
      borderWidth: borderWidth,
      dropShadow: dropShadow,
      hoverOverlayColor: hoverOverlayColor,
      hoverForegroundColor: hoverForegroundColor,
    );
  }

  /// Returns this style with a black scrim folded in to read as pressed into
  /// the surface, for [NeoButtonPressStyle.sunken].
  ///
  /// [progress] runs from 0 (resting) to 1 (fully pressed). Mirrors
  /// [withHover]'s fold, but also darkens the border — unlike hover, which
  /// leaves the edge alone — and never touches [innerHighlightColor] or
  /// [dropShadow]: the raised top edge and the ground shadow stay put while
  /// the fill and the edge sink.
  NeoButtonVisualStyle withPress(double progress) {
    final double t = progress.clamp(0, 1);
    if (t == 0) return this;

    final Color scrim = _pressScrim.withValues(alpha: _pressScrim.a * t);
    return NeoButtonVisualStyle(
      foregroundColor: foregroundColor,
      fontWeight: fontWeight,
      fillColor: fillGradient != null
          ? fillColor
          : Color.alphaBlend(scrim, fillColor ?? _transparent),
      fillGradient: _blendGradient(fillGradient, scrim),
      innerHighlightColor: innerHighlightColor,
      borderColor: borderColor == null
          ? null
          : Color.alphaBlend(scrim, borderColor!),
      borderGradient: _blendGradient(borderGradient, scrim),
      borderWidth: borderWidth,
      dropShadow: dropShadow,
      hoverOverlayColor: hoverOverlayColor,
      hoverForegroundColor: hoverForegroundColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NeoButtonVisualStyle &&
      other.foregroundColor == foregroundColor &&
      other.fontWeight == fontWeight &&
      other.fillColor == fillColor &&
      other.fillGradient == fillGradient &&
      other.innerHighlightColor == innerHighlightColor &&
      other.borderColor == borderColor &&
      other.borderGradient == borderGradient &&
      other.borderWidth == borderWidth &&
      other.dropShadow == dropShadow &&
      other.hoverOverlayColor == hoverOverlayColor &&
      other.hoverForegroundColor == hoverForegroundColor;

  @override
  int get hashCode => Object.hash(
    foregroundColor,
    fontWeight,
    fillColor,
    fillGradient,
    innerHighlightColor,
    borderColor,
    borderGradient,
    borderWidth,
    dropShadow,
    hoverOverlayColor,
    hoverForegroundColor,
  );
}

/// Resolves [variant] into concrete paint values.
///
/// Pure: it takes no [BuildContext] and reads no ambient state, so the whole
/// color model of the family can be asserted without pumping a widget.
///
/// [accent] overrides the fill of [NeoButtonVariant.primary] and forces a white
/// label. Every other variant ignores it.
NeoButtonVisualStyle resolveNeoButtonStyle({
  required NeoButtonVariant variant,
  required Brightness brightness,
  NeoButtonPalette palette = NeoButtonPalette.fallback,
  Color? accent,
}) {
  switch (variant) {
    case NeoButtonVariant.primary:
      final Color fill = accent ?? palette.primary.resolve(brightness);
      return NeoButtonVisualStyle(
        foregroundColor: accent != null
            ? _white
            : palette.primaryForeground.resolve(brightness),
        fontWeight: FontWeight.w600,
        fillGradient: _fillGradient(fill, _primaryTopMix, _primaryBottomMix),
        innerHighlightColor: _white.withValues(alpha: 0.42),
        borderGradient: _borderGradient(fill, 0.45, _primaryBorderMix),
        borderWidth: NeoButtonMetrics.gradientBorderWidth,
        dropShadow: _dropShadow(fill.withValues(alpha: 0.2)),
        hoverOverlayColor: _hoverLift,
      );

    case NeoButtonVariant.danger:
      final Color fill = palette.destructive.resolve(brightness);
      return NeoButtonVisualStyle(
        foregroundColor: _white,
        fontWeight: FontWeight.w600,
        fillGradient: _fillGradient(fill, _dangerTopMix, _dangerBottomMix),
        innerHighlightColor: _white.withValues(alpha: 0.35),
        borderGradient: _borderGradient(fill, 0.4, _dangerBorderMix),
        borderWidth: NeoButtonMetrics.gradientBorderWidth,
        dropShadow: _dropShadow(fill.withValues(alpha: 0.18)),
        hoverOverlayColor: _hoverLift,
      );

    case NeoButtonVariant.secondary:
      return NeoButtonVisualStyle(
        foregroundColor: palette.foreground.resolve(brightness),
        fontWeight: FontWeight.w500,
        fillColor: palette.card.resolve(brightness),
        borderColor: palette.border.resolve(brightness).withValues(alpha: 0.9),
        borderWidth: NeoButtonMetrics.hairlineBorderWidth,
        dropShadow: _dropShadow(
          palette.shadow.resolve(brightness).withValues(alpha: 0.05),
        ),
        hoverOverlayColor: palette.hoverSurface.resolve(brightness),
        hoverForegroundColor: palette.hoverForeground.resolve(brightness),
      );

    case NeoButtonVariant.outline:
      return NeoButtonVisualStyle(
        foregroundColor: palette.foreground.resolve(brightness),
        fontWeight: FontWeight.w500,
        borderColor: palette.border.resolve(brightness),
        borderWidth: NeoButtonMetrics.outlineBorderWidth,
        hoverOverlayColor: palette.hoverSurface.resolve(brightness),
        hoverForegroundColor: palette.hoverForeground.resolve(brightness),
      );

    case NeoButtonVariant.ghost:
      return NeoButtonVisualStyle(
        foregroundColor: palette.foreground.resolve(brightness),
        fontWeight: FontWeight.w500,
        hoverOverlayColor: palette.hoverSurface.resolve(brightness),
        hoverForegroundColor: palette.hoverForeground.resolve(brightness),
      );
  }
}

/// Theme data consumed by [NeoButton] and [NeoIconButton].
@immutable
class NeoButtonThemeData {
  /// Creates theme data, defaulting every value to the package tokens.
  const NeoButtonThemeData({
    this.palette = NeoButtonPalette.fallback,
    this.small = NeoButtonSizeSpec.small,
    this.medium = NeoButtonSizeSpec.medium,
    this.large = NeoButtonSizeSpec.large,
    this.iconButton = NeoIconButtonSpec.fallback,
    this.radiusRatio = NeoButtonMetrics.radiusRatio,
    this.smoothness = NeoButtonMetrics.smoothness,
    this.contentSpacing = NeoButtonMetrics.contentSpacing,
    this.spinnerRadius = NeoButtonMetrics.spinnerRadius,
    this.innerHighlightBlurRadius = NeoButtonMetrics.innerHighlightBlurRadius,
    this.innerHighlightOffset = NeoButtonMetrics.innerHighlightOffset,
    this.disabledOpacity = NeoButtonMetrics.disabledOpacity,
    this.pressedScale = NeoButtonMetrics.pressedScale,
    this.pressSpring = NeoButtonMetrics.pressSpring,
    this.pressStyle = NeoButtonPressStyle.scale,
    this.hoverDuration = NeoButtonMetrics.hoverDuration,
    this.enableHapticFeedback = true,
    this.brightness,
  });

  /// The package default theme.
  static const fallback = NeoButtonThemeData();

  /// Semantic colors for the family.
  final NeoButtonPalette palette;

  /// Geometry for [NeoButtonSize.small].
  final NeoButtonSizeSpec small;

  /// Geometry for [NeoButtonSize.medium].
  final NeoButtonSizeSpec medium;

  /// Geometry for [NeoButtonSize.large].
  final NeoButtonSizeSpec large;

  /// Geometry for [NeoIconButton].
  final NeoIconButtonSpec iconButton;

  /// Corner radius as a fraction of the control height.
  final double radiusRatio;

  /// Corner smoothing passed to `SmoothRectangleBorder`.
  final double smoothness;

  /// Gap between the leading icon or spinner and the label.
  final double contentSpacing;

  /// Radius of the loading spinner.
  final double spinnerRadius;

  /// Blur radius of the inner highlight, in CSS blur units.
  final double innerHighlightBlurRadius;

  /// Offset of the inner highlight.
  final Offset innerHighlightOffset;

  /// Opacity applied while disabled and not loading.
  final double disabledOpacity;

  /// Scale the button springs to while pressed.
  final double pressedScale;

  /// Spring driving the press animation.
  final SpringDescription pressSpring;

  /// Whether pressing scales the button or darkens it in place.
  final NeoButtonPressStyle pressStyle;

  /// How long the hover overlay takes to fade in or out.
  ///
  /// Hover only ever fires under a real pointer, so touch platforms keep the
  /// original iOS behaviour without any opt out.
  final Duration hoverDuration;

  /// Whether taps emit a light impact by default.
  final bool enableHapticFeedback;

  /// Forces a brightness for the subtree, or null to read the ambient one.
  final Brightness? brightness;

  /// Returns the geometry for [size].
  NeoButtonSizeSpec specFor(NeoButtonSize size) => switch (size) {
    NeoButtonSize.small => small,
    NeoButtonSize.medium => medium,
    NeoButtonSize.large => large,
  };

  /// Returns a copy with the given fields replaced.
  NeoButtonThemeData copyWith({
    NeoButtonPalette? palette,
    NeoButtonSizeSpec? small,
    NeoButtonSizeSpec? medium,
    NeoButtonSizeSpec? large,
    NeoIconButtonSpec? iconButton,
    double? radiusRatio,
    double? smoothness,
    double? contentSpacing,
    double? spinnerRadius,
    double? innerHighlightBlurRadius,
    Offset? innerHighlightOffset,
    double? disabledOpacity,
    double? pressedScale,
    SpringDescription? pressSpring,
    NeoButtonPressStyle? pressStyle,
    Duration? hoverDuration,
    bool? enableHapticFeedback,
    Brightness? brightness,
  }) => NeoButtonThemeData(
    palette: palette ?? this.palette,
    small: small ?? this.small,
    medium: medium ?? this.medium,
    large: large ?? this.large,
    iconButton: iconButton ?? this.iconButton,
    radiusRatio: radiusRatio ?? this.radiusRatio,
    smoothness: smoothness ?? this.smoothness,
    contentSpacing: contentSpacing ?? this.contentSpacing,
    spinnerRadius: spinnerRadius ?? this.spinnerRadius,
    innerHighlightBlurRadius:
        innerHighlightBlurRadius ?? this.innerHighlightBlurRadius,
    innerHighlightOffset: innerHighlightOffset ?? this.innerHighlightOffset,
    disabledOpacity: disabledOpacity ?? this.disabledOpacity,
    pressedScale: pressedScale ?? this.pressedScale,
    pressSpring: pressSpring ?? this.pressSpring,
    pressStyle: pressStyle ?? this.pressStyle,
    hoverDuration: hoverDuration ?? this.hoverDuration,
    enableHapticFeedback: enableHapticFeedback ?? this.enableHapticFeedback,
    brightness: brightness ?? this.brightness,
  );

  @override
  bool operator ==(Object other) =>
      other is NeoButtonThemeData &&
      other.palette == palette &&
      other.small == small &&
      other.medium == medium &&
      other.large == large &&
      other.iconButton == iconButton &&
      other.radiusRatio == radiusRatio &&
      other.smoothness == smoothness &&
      other.contentSpacing == contentSpacing &&
      other.spinnerRadius == spinnerRadius &&
      other.innerHighlightBlurRadius == innerHighlightBlurRadius &&
      other.innerHighlightOffset == innerHighlightOffset &&
      other.disabledOpacity == disabledOpacity &&
      other.pressedScale == pressedScale &&
      other.pressSpring == pressSpring &&
      other.pressStyle == pressStyle &&
      other.hoverDuration == hoverDuration &&
      other.enableHapticFeedback == enableHapticFeedback &&
      other.brightness == brightness;

  @override
  int get hashCode => Object.hash(
    palette,
    small,
    medium,
    large,
    iconButton,
    radiusRatio,
    smoothness,
    contentSpacing,
    spinnerRadius,
    innerHighlightBlurRadius,
    innerHighlightOffset,
    disabledOpacity,
    pressedScale,
    pressSpring,
    pressStyle,
    hoverDuration,
    enableHapticFeedback,
    brightness,
  );
}

/// Provides neo button styling to a widget subtree without depending on
/// Material.
class NeoButtonTheme extends InheritedTheme {
  /// Creates a theme scope.
  const NeoButtonTheme({required this.data, required super.child, super.key});

  /// The styling applied to descendants.
  final NeoButtonThemeData data;

  /// Returns the nearest theme data, or [NeoButtonThemeData.fallback].
  static NeoButtonThemeData of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<NeoButtonTheme>()?.data ??
        NeoButtonThemeData.fallback;
  }

  @override
  bool updateShouldNotify(NeoButtonTheme oldWidget) => data != oldWidget.data;

  @override
  Widget wrap(BuildContext context, Widget child) {
    return NeoButtonTheme(data: data, child: child);
  }
}

/// Package fallback colors, ported from ChunUI's `Color.cc` tokens.
abstract final class NeoButtonColors {
  /// Page background. Not painted by the buttons; provided for hosts.
  static const background = NeoColor(
    light: Color(0xFFF7F7F9),
    dark: Color(0xFF18181B),
  );

  /// Primary label color on neutral surfaces.
  static const foreground = NeoColor(
    light: Color(0xFF171717),
    dark: Color(0xFFFAFAFA),
  );

  /// Raised surface fill.
  static const card = NeoColor(
    light: Color(0xFFFFFFFF),
    dark: Color(0xFF27272A),
  );

  /// The brand color. ChunUI keeps it identical in both brightnesses.
  static const primary = NeoColor.constant(Color(0xFFFF00C8));

  /// Label color on top of [primary].
  static const primaryForeground = NeoColor.constant(Color(0xFFFFFFFF));

  /// Recessed neutral fill. Not painted by the buttons; provided for hosts.
  static const muted = NeoColor(
    light: Color(0xFFE8E8ED),
    dark: Color(0xFF27272A),
  );

  /// Secondary label color.
  static const mutedForeground = NeoColor(
    light: Color(0xFF6B6B6B),
    dark: Color(0xFFA1A1AA),
  );

  /// Grayscale surface for hover and selection.
  ///
  /// ChunUI calls this token `accent`; it is renamed here because
  /// [NeoButton.accent] already means "recolor the primary fill".
  static const hoverSurface = NeoColor(
    light: Color(0xFFDEDEE5),
    dark: Color(0xFF3F3F46),
  );

  /// Label color on top of [hoverSurface]. ChunUI's `accentForeground`.
  static const hoverForeground = NeoColor(
    light: Color(0xFF171717),
    dark: Color(0xFFFAFAFA),
  );

  /// Destructive action color.
  static const destructive = NeoColor(
    light: Color(0xFFC13B5F),
    dark: Color(0xFFE07A94),
  );

  /// Hairline separator and border color.
  static const border = NeoColor(
    light: Color(0xFFDCDCE3),
    dark: Color(0xFF3F3F46),
  );

  /// Base color for drop shadows.
  static const shadow = NeoColor.constant(Color(0xFF000000));
}

/// Package fallback metrics, ported from ChunUI's `CCNeoButton`.
abstract final class NeoButtonMetrics {
  /// Corner radius as a fraction of the control height.
  static const radiusRatio = 0.38;

  /// Corner smoothing passed to `SmoothRectangleBorder`.
  static const smoothness = 1.0;

  /// Gap between the leading icon or spinner and the label.
  static const contentSpacing = 7.0;

  /// Spinner radius: SwiftUI's 20 point `ProgressView` scaled by 0.72.
  static const spinnerRadius = 7.2;

  /// Opacity applied while disabled and not loading.
  static const disabledOpacity = 0.45;

  /// Scale the button springs to while pressed.
  static const pressedScale = 0.97;

  /// White lift composited over the brand fills while hovered.
  ///
  /// The neutral variants take the opaque [NeoButtonColors.hoverSurface]
  /// instead; a gray wash over the brand gradient would only muddy it.
  ///
  /// Runs higher than a lift normally would because the brand color saturates
  /// its red channel: over `#FF00C8` only green and blue can move, so the same
  /// opacity buys far less contrast here than it would on a mid tone.
  static const hoverLiftOpacity = 0.18;

  /// How long the hover overlay takes to fade in or out.
  static const hoverDuration = Duration(milliseconds: 120);

  /// Black scrim opacity folded into the fill and border for
  /// [NeoButtonPressStyle.sunken]. Slightly under [hoverLiftOpacity]: darkening
  /// reads as more of a change than lightening at the same magnitude.
  static const pressDarkenOpacity = 0.16;

  /// How long the sunken press color takes to fade in or out. Ported from
  /// `MyButton`'s `_MyButtonBase.transitionDuration`
  /// (`lib/src/widgets/my_button.dart`), the button this style is modeled on.
  static const pressColorDuration = Duration(milliseconds: 90);

  /// Width of the gradient border on the solid variants.
  static const gradientBorderWidth = 0.66;

  /// Width of the hairline border on [NeoButtonVariant.secondary].
  static const hairlineBorderWidth = 0.5;

  /// Width of the border on [NeoButtonVariant.outline].
  static const outlineBorderWidth = 1.0;

  /// Drop shadow blur. SwiftUI's shadow radius 3 doubles into CSS blur units.
  static const dropShadowBlurRadius = 6.0;

  /// Drop shadow offset.
  static const dropShadowOffset = Offset(0, 1.5);

  /// Inner highlight blur. SwiftUI's inner radius 1.5 in CSS blur units.
  static const innerHighlightBlurRadius = 3.0;

  /// Inner highlight offset, which pushes the glow onto the top edge.
  static const innerHighlightOffset = Offset(0, 1.5);

  /// SwiftUI's `.spring(response: 0.28, dampingFraction: 0.72)`.
  ///
  /// `response` is the undamped natural period, so with a unit mass the
  /// stiffness is `(2 * pi / 0.28)^2` and the damping is `2 * 0.72 * sqrt(k)`.
  static const pressSpring = SpringDescription(
    mass: 1,
    stiffness: 503.5512,
    damping: 32.3135,
  );
}

const Color _white = Color(0xFFFFFFFF);
const Color _black = Color(0xFF000000);
const Color _transparent = Color(0x00000000);

/// The white wash the brand variants take on hover.
const Color _hoverLift = Color.from(
  alpha: NeoButtonMetrics.hoverLiftOpacity,
  red: 1,
  green: 1,
  blue: 1,
);

/// The black scrim folded into the fill and border for a sunken press.
const Color _pressScrim = Color.from(
  alpha: NeoButtonMetrics.pressDarkenOpacity,
  red: 0,
  green: 0,
  blue: 0,
);

// Mix amounts lifted verbatim from CCNeoButton.swift. ChunUI's `Color.mix` is a
// per channel sRGB lerp, which `Color.lerp` matches exactly.
const double _primaryTopMix = 0.14;
const double _primaryBottomMix = 0.1;
const double _primaryBorderMix = 0.28;
const double _dangerTopMix = 0.12;
const double _dangerBottomMix = 0.12;
const double _dangerBorderMix = 0.3;

LinearGradient _fillGradient(Color fill, double topMix, double bottomMix) {
  return LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      Color.lerp(fill, _white, topMix)!,
      fill,
      Color.lerp(fill, _black, bottomMix)!,
    ],
    stops: const <double>[0, 0.5, 1],
  );
}

LinearGradient _borderGradient(Color fill, double topAlpha, double shadeMix) {
  return LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      _white.withValues(alpha: topAlpha),
      Color.lerp(fill, _black, shadeMix)!.withValues(alpha: 0.55),
    ],
  );
}

BoxShadow _dropShadow(Color color) {
  return BoxShadow(
    color: color,
    blurRadius: NeoButtonMetrics.dropShadowBlurRadius,
    offset: NeoButtonMetrics.dropShadowOffset,
  );
}

/// Composites [scrim] over every stop of [gradient], preserving its geometry.
LinearGradient? _blendGradient(LinearGradient? gradient, Color scrim) {
  if (gradient == null) return null;
  return LinearGradient(
    begin: gradient.begin,
    end: gradient.end,
    colors: <Color>[
      for (final Color color in gradient.colors) Color.alphaBlend(scrim, color),
    ],
    stops: gradient.stops,
    tileMode: gradient.tileMode,
    transform: gradient.transform,
  );
}
