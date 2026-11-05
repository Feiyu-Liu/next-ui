import 'package:flutter/cupertino.dart';

/// Paint, geometry, and motion used by [MorphingMenuButtonTheme].
@immutable
class MorphingMenuButtonStyle {
  /// Creates a complete morphing-menu style.
  const MorphingMenuButtonStyle({
    this.collapsedBackgroundColor = _fallbackCollapsedBackground,
    this.collapsedHoverColor = _fallbackCollapsedHover,
    this.collapsedPressedColor = _fallbackCollapsedPressed,
    this.expandedBackgroundColor = _fallbackExpandedBackground,
    this.foregroundColor = _fallbackForeground,
    this.borderColor = _fallbackBorder,
    this.focusedBorderColor = _fallbackFocusedBorder,
    this.shadowColor = _fallbackShadow,
    this.dragHandleColor = _fallbackDragHandle,
    this.triggerPadding = const EdgeInsets.symmetric(horizontal: 10),
    this.panelPadding = const EdgeInsets.all(16),
    this.textStyle = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    ),
    this.buttonHeight = 38,
    this.minButtonWidth = 38,
    this.iconSize = 16,
    this.iconLabelSpacing = 8,
    this.collapsedRadius = 11,
    this.expandedRadius = 16,
    this.smoothness = 1,
    this.borderWidth = 1,
    this.gap = 8,
    this.viewportPadding = 12,
    this.expandedWidth = 360,
    this.expandedHeight = 236,
    this.dragHandleWidth = 42,
    this.dragHandleHeight = 4,
    this.dragHandleHitHeight = 32,
    this.dragHandleInset = 20,
    this.disabledOpacity = 0.45,
    this.collapsedShadow = const BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 12,
      offset: Offset(0, 6),
      spreadRadius: -10,
    ),
    this.expandedShadow = const BoxShadow(
      color: Color(0x29000000),
      blurRadius: 28,
      offset: Offset(0, 18),
      spreadRadius: -14,
    ),
    this.duration = const Duration(milliseconds: 700),
    this.reverseDuration = const Duration(milliseconds: 700),
    this.openCurve = const ElasticOutCurve(1.2),
    this.closeCurve = const ElasticOutCurve(1.2),
    this.heightSnapDuration = const Duration(milliseconds: 260),
    this.contentRevealStart = 0,
    this.contentRevealEnd = 1,
  }) : assert(buttonHeight > 0),
       assert(minButtonWidth > 0),
       assert(iconSize > 0),
       assert(collapsedRadius >= 0),
       assert(expandedRadius >= 0),
       assert(smoothness >= 0 && smoothness <= 1),
       assert(borderWidth >= 0),
       assert(gap >= 0),
       assert(viewportPadding >= 0),
       assert(expandedWidth > 0),
       assert(expandedHeight > 0),
       assert(dragHandleWidth > 0),
       assert(dragHandleHeight > 0),
       assert(dragHandleHitHeight >= dragHandleHeight),
       assert(dragHandleInset >= 0),
       assert(disabledOpacity >= 0 && disabledOpacity <= 1),
       assert(contentRevealStart >= 0 && contentRevealStart <= 1),
       assert(contentRevealEnd >= contentRevealStart && contentRevealEnd <= 1);

  /// The trigger fill at rest.
  final Color collapsedBackgroundColor;

  /// The trigger fill under a mouse pointer.
  final Color collapsedHoverColor;

  /// The trigger fill while pressed.
  final Color collapsedPressedColor;

  /// The expanded card fill.
  final Color expandedBackgroundColor;

  /// The icon and label color.
  final Color foregroundColor;

  /// The default trigger and card border color.
  final Color borderColor;

  /// The trigger border color while keyboard-focused.
  final Color focusedBorderColor;

  /// Base shadow color available to product themes.
  final Color shadowColor;

  /// The drag handle color.
  final Color dragHandleColor;

  /// Padding inside the collapsed trigger.
  final EdgeInsetsGeometry triggerPadding;

  /// Padding around caller content in the expanded card.
  ///
  /// This is the caller content's own padding only. The room the drag handle
  /// needs is added separately through [dragHandleInset], on whichever edge the
  /// handle currently occupies, so this value does not have to be rewritten
  /// when the card opens downward instead of upward.
  final EdgeInsetsGeometry panelPadding;

  /// Typography for the optional trigger label.
  final TextStyle textStyle;

  /// Collapsed trigger height.
  final double buttonHeight;

  /// Minimum collapsed trigger width.
  final double minButtonWidth;

  /// Trigger icon size.
  final double iconSize;

  /// Gap between the icon and optional label.
  final double iconLabelSpacing;

  /// Trigger corner radius.
  final double collapsedRadius;

  /// Expanded card corner radius.
  final double expandedRadius;

  /// Corner smoothing passed to `SmoothRectangleBorder`.
  final double smoothness;

  /// Trigger and card border width.
  final double borderWidth;

  /// Final gap between the expanded card and its trigger anchor.
  final double gap;

  /// Minimum distance from the target overlay's edges.
  final double viewportPadding;

  /// Default expanded width before viewport clamping.
  final double expandedWidth;

  /// Default expanded height before viewport clamping.
  final double expandedHeight;

  /// Width of the visible drag handle.
  final double dragHandleWidth;

  /// Height of the visible drag handle.
  final double dragHandleHeight;

  /// Height of the drag handle's gesture target.
  final double dragHandleHitHeight;

  /// Extra content inset added on the edge the drag handle occupies.
  ///
  /// Added to [panelPadding]'s top inset while the card opens upward and to its
  /// bottom inset while the card opens downward, so caller content never sits
  /// underneath the handle.
  final double dragHandleInset;

  /// Opacity applied to a disabled trigger.
  final double disabledOpacity;

  /// Shadow at the collapsed endpoint.
  final BoxShadow collapsedShadow;

  /// Shadow at the expanded endpoint.
  final BoxShadow expandedShadow;

  /// Opening animation duration.
  final Duration duration;

  /// Closing animation duration.
  ///
  /// Closing plays forward through [closeCurve] rather than rewinding the
  /// opening animation, so an elastic curve overshoots on the way in *and* on
  /// the way out.
  final Duration reverseDuration;

  /// Curve driving the morph while opening.
  ///
  /// Values above `1` are honoured, so overshooting curves such as
  /// [ElasticOutCurve] push the card slightly past its target before settling.
  final Curve openCurve;

  /// Curve driving the morph while closing.
  final Curve closeCurve;

  /// Duration used when the dragged card snaps between heights.
  final Duration heightSnapDuration;

  /// Animation progress where expanded content starts appearing.
  final double contentRevealStart;

  /// Animation progress where expanded content is fully visible.
  final double contentRevealEnd;

  /// Returns a copy with the supplied fields replaced.
  MorphingMenuButtonStyle copyWith({
    Color? collapsedBackgroundColor,
    Color? collapsedHoverColor,
    Color? collapsedPressedColor,
    Color? expandedBackgroundColor,
    Color? foregroundColor,
    Color? borderColor,
    Color? focusedBorderColor,
    Color? shadowColor,
    Color? dragHandleColor,
    EdgeInsetsGeometry? triggerPadding,
    EdgeInsetsGeometry? panelPadding,
    TextStyle? textStyle,
    double? buttonHeight,
    double? minButtonWidth,
    double? iconSize,
    double? iconLabelSpacing,
    double? collapsedRadius,
    double? expandedRadius,
    double? smoothness,
    double? borderWidth,
    double? gap,
    double? viewportPadding,
    double? expandedWidth,
    double? expandedHeight,
    double? dragHandleWidth,
    double? dragHandleHeight,
    double? dragHandleHitHeight,
    double? dragHandleInset,
    double? disabledOpacity,
    BoxShadow? collapsedShadow,
    BoxShadow? expandedShadow,
    Duration? duration,
    Duration? reverseDuration,
    Curve? openCurve,
    Curve? closeCurve,
    Duration? heightSnapDuration,
    double? contentRevealStart,
    double? contentRevealEnd,
  }) => MorphingMenuButtonStyle(
    collapsedBackgroundColor:
        collapsedBackgroundColor ?? this.collapsedBackgroundColor,
    collapsedHoverColor: collapsedHoverColor ?? this.collapsedHoverColor,
    collapsedPressedColor: collapsedPressedColor ?? this.collapsedPressedColor,
    expandedBackgroundColor:
        expandedBackgroundColor ?? this.expandedBackgroundColor,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    borderColor: borderColor ?? this.borderColor,
    focusedBorderColor: focusedBorderColor ?? this.focusedBorderColor,
    shadowColor: shadowColor ?? this.shadowColor,
    dragHandleColor: dragHandleColor ?? this.dragHandleColor,
    triggerPadding: triggerPadding ?? this.triggerPadding,
    panelPadding: panelPadding ?? this.panelPadding,
    textStyle: textStyle ?? this.textStyle,
    buttonHeight: buttonHeight ?? this.buttonHeight,
    minButtonWidth: minButtonWidth ?? this.minButtonWidth,
    iconSize: iconSize ?? this.iconSize,
    iconLabelSpacing: iconLabelSpacing ?? this.iconLabelSpacing,
    collapsedRadius: collapsedRadius ?? this.collapsedRadius,
    expandedRadius: expandedRadius ?? this.expandedRadius,
    smoothness: smoothness ?? this.smoothness,
    borderWidth: borderWidth ?? this.borderWidth,
    gap: gap ?? this.gap,
    viewportPadding: viewportPadding ?? this.viewportPadding,
    expandedWidth: expandedWidth ?? this.expandedWidth,
    expandedHeight: expandedHeight ?? this.expandedHeight,
    dragHandleWidth: dragHandleWidth ?? this.dragHandleWidth,
    dragHandleHeight: dragHandleHeight ?? this.dragHandleHeight,
    dragHandleHitHeight: dragHandleHitHeight ?? this.dragHandleHitHeight,
    dragHandleInset: dragHandleInset ?? this.dragHandleInset,
    disabledOpacity: disabledOpacity ?? this.disabledOpacity,
    collapsedShadow: collapsedShadow ?? this.collapsedShadow,
    expandedShadow: expandedShadow ?? this.expandedShadow,
    duration: duration ?? this.duration,
    reverseDuration: reverseDuration ?? this.reverseDuration,
    openCurve: openCurve ?? this.openCurve,
    closeCurve: closeCurve ?? this.closeCurve,
    heightSnapDuration: heightSnapDuration ?? this.heightSnapDuration,
    contentRevealStart: contentRevealStart ?? this.contentRevealStart,
    contentRevealEnd: contentRevealEnd ?? this.contentRevealEnd,
  );

  @override
  bool operator ==(Object other) =>
      other is MorphingMenuButtonStyle &&
      other.collapsedBackgroundColor == collapsedBackgroundColor &&
      other.collapsedHoverColor == collapsedHoverColor &&
      other.collapsedPressedColor == collapsedPressedColor &&
      other.expandedBackgroundColor == expandedBackgroundColor &&
      other.foregroundColor == foregroundColor &&
      other.borderColor == borderColor &&
      other.focusedBorderColor == focusedBorderColor &&
      other.shadowColor == shadowColor &&
      other.dragHandleColor == dragHandleColor &&
      other.triggerPadding == triggerPadding &&
      other.panelPadding == panelPadding &&
      other.textStyle == textStyle &&
      other.buttonHeight == buttonHeight &&
      other.minButtonWidth == minButtonWidth &&
      other.iconSize == iconSize &&
      other.iconLabelSpacing == iconLabelSpacing &&
      other.collapsedRadius == collapsedRadius &&
      other.expandedRadius == expandedRadius &&
      other.smoothness == smoothness &&
      other.borderWidth == borderWidth &&
      other.gap == gap &&
      other.viewportPadding == viewportPadding &&
      other.expandedWidth == expandedWidth &&
      other.expandedHeight == expandedHeight &&
      other.dragHandleWidth == dragHandleWidth &&
      other.dragHandleHeight == dragHandleHeight &&
      other.dragHandleHitHeight == dragHandleHitHeight &&
      other.dragHandleInset == dragHandleInset &&
      other.disabledOpacity == disabledOpacity &&
      other.collapsedShadow == collapsedShadow &&
      other.expandedShadow == expandedShadow &&
      other.duration == duration &&
      other.reverseDuration == reverseDuration &&
      other.openCurve == openCurve &&
      other.closeCurve == closeCurve &&
      other.heightSnapDuration == heightSnapDuration &&
      other.contentRevealStart == contentRevealStart &&
      other.contentRevealEnd == contentRevealEnd;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    collapsedBackgroundColor,
    collapsedHoverColor,
    collapsedPressedColor,
    expandedBackgroundColor,
    foregroundColor,
    borderColor,
    focusedBorderColor,
    shadowColor,
    dragHandleColor,
    triggerPadding,
    panelPadding,
    textStyle,
    buttonHeight,
    minButtonWidth,
    iconSize,
    iconLabelSpacing,
    collapsedRadius,
    expandedRadius,
    smoothness,
    borderWidth,
    gap,
    viewportPadding,
    expandedWidth,
    expandedHeight,
    dragHandleWidth,
    dragHandleHeight,
    dragHandleHitHeight,
    dragHandleInset,
    disabledOpacity,
    collapsedShadow,
    expandedShadow,
    duration,
    reverseDuration,
    openCurve,
    closeCurve,
    heightSnapDuration,
    contentRevealStart,
    contentRevealEnd,
  ]);
}

/// Theme data for [MorphingMenuButtonTheme].
@immutable
class MorphingMenuButtonThemeData {
  /// Creates theme data with a complete menu style.
  const MorphingMenuButtonThemeData({
    this.style = const MorphingMenuButtonStyle(),
  });

  /// The package fallback theme.
  static const fallback = MorphingMenuButtonThemeData();

  /// Default styling for morphing menu buttons in this subtree.
  final MorphingMenuButtonStyle style;

  /// Returns a copy with the supplied style.
  MorphingMenuButtonThemeData copyWith({MorphingMenuButtonStyle? style}) =>
      MorphingMenuButtonThemeData(style: style ?? this.style);

  @override
  bool operator ==(Object other) =>
      other is MorphingMenuButtonThemeData && other.style == style;

  @override
  int get hashCode => style.hashCode;
}

/// Provides morphing menu styling without depending on Material.
class MorphingMenuButtonTheme extends InheritedTheme {
  /// Creates a theme scope.
  const MorphingMenuButtonTheme({
    required this.data,
    required super.child,
    super.key,
  });

  /// Styling inherited by descendants.
  final MorphingMenuButtonThemeData data;

  /// Returns the nearest theme or [MorphingMenuButtonThemeData.fallback].
  static MorphingMenuButtonThemeData of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<MorphingMenuButtonTheme>()
          ?.data ??
      MorphingMenuButtonThemeData.fallback;

  @override
  bool updateShouldNotify(MorphingMenuButtonTheme oldWidget) =>
      data != oldWidget.data;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      MorphingMenuButtonTheme(data: data, child: child);
}

const CupertinoDynamicColor _fallbackCollapsedBackground =
    CupertinoDynamicColor.withBrightness(
      color: Color(0xFFFFFFFF),
      darkColor: Color(0xFF27272A),
    );
const CupertinoDynamicColor _fallbackCollapsedHover =
    CupertinoDynamicColor.withBrightness(
      color: Color(0xFFF4F4F6),
      darkColor: Color(0xFF333338),
    );
const CupertinoDynamicColor _fallbackCollapsedPressed =
    CupertinoDynamicColor.withBrightness(
      color: Color(0xFFE8E8ED),
      darkColor: Color(0xFF3F3F46),
    );
const CupertinoDynamicColor _fallbackExpandedBackground =
    CupertinoDynamicColor.withBrightness(
      color: Color(0xFFFFFFFF),
      darkColor: Color(0xFF27272A),
    );
const CupertinoDynamicColor _fallbackForeground =
    CupertinoDynamicColor.withBrightness(
      color: Color(0xFF171717),
      darkColor: Color(0xFFFAFAFA),
    );
const CupertinoDynamicColor _fallbackBorder =
    CupertinoDynamicColor.withBrightness(
      color: Color(0xFFDCDCE3),
      darkColor: Color(0xFF3F3F46),
    );
const CupertinoDynamicColor _fallbackFocusedBorder =
    CupertinoDynamicColor.withBrightness(
      color: Color(0xFF8E8E93),
      darkColor: Color(0xFFA1A1AA),
    );
const CupertinoDynamicColor _fallbackShadow =
    CupertinoDynamicColor.withBrightness(
      color: Color(0xFF000000),
      darkColor: Color(0xFF000000),
    );
const CupertinoDynamicColor _fallbackDragHandle =
    CupertinoDynamicColor.withBrightness(
      color: Color(0xFFD1D1D6),
      darkColor: Color(0xFF52525B),
    );
