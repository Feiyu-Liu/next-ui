import 'package:flutter/cupertino.dart';

/// Visual roles shared by every button form.
enum MyButtonStyle {
  primary,
  secondary,
  ghost,
  @Deprecated('Use primary for actions and reserve green for status UI.')
  success,
  danger,
}

/// Standard desktop control sizes.
enum MyButtonSize { compact, regular }

/// Paint values for one interaction state.
@immutable
class MyButtonStateStyle {
  const MyButtonStateStyle({
    this.backgroundColor,
    this.backgroundGradient,
    required this.border,
  });

  final Color? backgroundColor;
  final Gradient? backgroundGradient;
  final BorderSide border;
}

/// Foreground and state paints for one semantic button style.
@immutable
class MyButtonStyleData {
  const MyButtonStyleData({
    required this.foregroundColor,
    required this.idle,
    required this.hovered,
    required this.pressed,
    required this.focused,
  });

  final Color foregroundColor;
  final MyButtonStateStyle idle;
  final MyButtonStateStyle hovered;
  final MyButtonStateStyle pressed;
  final MyButtonStateStyle focused;
}

/// Theme data consumed by [MyButton], [MyIconButton], and [MyMenuButton].
@immutable
class MyButtonThemeData {
  const MyButtonThemeData({
    required this.primary,
    required this.secondary,
    required this.ghost,
    required this.success,
    required this.danger,
    this.compactHeight = MyButtonMetrics.compactHeight,
    this.regularHeight = MyButtonMetrics.regularHeight,
    this.iconSize = MyButtonMetrics.iconSize,
    this.smallIconSize = MyButtonMetrics.smallIconSize,
    this.radius = MyButtonMetrics.radius,
    this.iconRadius = MyButtonMetrics.iconRadius,
    this.smoothness = MyButtonMetrics.smoothness,
    this.groupSpacing = MyButtonMetrics.groupSpacing,
    this.disabledOpacity = MyButtonMetrics.disabledOpacity,
    this.textStyle = MyButtonTypography.label,
  });

  static const fallback = MyButtonThemeData(
    primary: MyButtonStyleData(
      foregroundColor: MyButtonColors.foreground,
      idle: MyButtonStateStyle(
        backgroundGradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            MyButtonColors.primaryHighlight,
            MyButtonColors.primaryTop,
            MyButtonColors.primaryBottom,
          ],
          stops: [0, 0.08, 1],
        ),
        border: BorderSide(color: MyButtonColors.primaryBorder),
      ),
      hovered: MyButtonStateStyle(
        backgroundGradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            MyButtonColors.primaryHighlight,
            MyButtonColors.primaryHoverTop,
            MyButtonColors.primaryHoverBottom,
          ],
          stops: [0, 0.1, 1],
        ),
        border: BorderSide(color: MyButtonColors.primaryBorder),
      ),
      pressed: MyButtonStateStyle(
        backgroundGradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            MyButtonColors.primaryPressedTop,
            MyButtonColors.primaryPressedBottom,
          ],
        ),
        border: BorderSide(color: MyButtonColors.primaryPressedBorder),
      ),
      focused: MyButtonStateStyle(
        backgroundGradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            MyButtonColors.primaryHighlight,
            MyButtonColors.primaryTop,
            MyButtonColors.primaryBottom,
          ],
          stops: [0, 0.08, 1],
        ),
        border: BorderSide(color: MyButtonColors.textSecondary, width: 1.5),
      ),
    ),
    secondary: MyButtonStyleData(
      foregroundColor: MyButtonColors.textPrimary,
      idle: MyButtonStateStyle(
        backgroundColor: MyButtonColors.surface,
        border: BorderSide(color: MyButtonColors.border),
      ),
      hovered: MyButtonStateStyle(
        backgroundColor: MyButtonColors.surfaceHovered,
        border: BorderSide(color: MyButtonColors.border),
      ),
      pressed: MyButtonStateStyle(
        backgroundColor: MyButtonColors.surfacePressed,
        border: BorderSide(color: MyButtonColors.textSecondary),
      ),
      focused: MyButtonStateStyle(
        backgroundColor: MyButtonColors.surface,
        border: BorderSide(color: MyButtonColors.textSecondary, width: 1.5),
      ),
    ),
    ghost: MyButtonStyleData(
      foregroundColor: MyButtonColors.textPrimary,
      idle: MyButtonStateStyle(
        backgroundColor: MyButtonColors.transparentSurface,
        border: BorderSide(color: MyButtonColors.transparent),
      ),
      hovered: MyButtonStateStyle(
        backgroundColor: MyButtonColors.surfaceHovered,
        border: BorderSide(color: MyButtonColors.transparent),
      ),
      pressed: MyButtonStateStyle(
        backgroundColor: MyButtonColors.surfacePressed,
        border: BorderSide(color: MyButtonColors.transparent),
      ),
      focused: MyButtonStateStyle(
        backgroundColor: MyButtonColors.transparentSurface,
        border: BorderSide(color: MyButtonColors.textSecondary, width: 1.5),
      ),
    ),
    success: MyButtonStyleData(
      foregroundColor: MyButtonColors.foreground,
      idle: MyButtonStateStyle(
        backgroundColor: MyButtonColors.success,
        border: BorderSide(color: MyButtonColors.success),
      ),
      hovered: MyButtonStateStyle(
        backgroundColor: MyButtonColors.successHovered,
        border: BorderSide(color: MyButtonColors.successHovered),
      ),
      pressed: MyButtonStateStyle(
        backgroundColor: MyButtonColors.successPressed,
        border: BorderSide(color: MyButtonColors.successPressed),
      ),
      focused: MyButtonStateStyle(
        backgroundColor: MyButtonColors.success,
        border: BorderSide(color: MyButtonColors.textSecondary, width: 1.5),
      ),
    ),
    danger: MyButtonStyleData(
      foregroundColor: MyButtonColors.foreground,
      idle: MyButtonStateStyle(
        backgroundColor: MyButtonColors.danger,
        border: BorderSide(color: MyButtonColors.danger),
      ),
      hovered: MyButtonStateStyle(
        backgroundColor: MyButtonColors.dangerHovered,
        border: BorderSide(color: MyButtonColors.dangerHovered),
      ),
      pressed: MyButtonStateStyle(
        backgroundColor: MyButtonColors.dangerPressed,
        border: BorderSide(color: MyButtonColors.dangerPressed),
      ),
      focused: MyButtonStateStyle(
        backgroundColor: MyButtonColors.danger,
        border: BorderSide(color: MyButtonColors.textSecondary, width: 1.5),
      ),
    ),
  );

  /// Dark default for button groups and their child controls.
  ///
  /// Derived interaction fills are white for primary hover, #C6C6CA for
  /// primary press, #EAEAEA for focus, #333336 for neutral hover, and
  /// #38383C for neutral press.
  static final darkFallback = MyButtonThemeData(
    primary: MyButtonStyleData(
      foregroundColor: Color(0xFF161618),
      idle: MyButtonStateStyle(
        backgroundGradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFAFAFA), Color(0xFFD9D9DC)],
        ),
        border: BorderSide(color: Color(0xFFB8B8BD)),
      ),
      hovered: MyButtonStateStyle(
        backgroundColor: Color(0xFFFFFFFF),
        border: BorderSide(color: Color(0xFFB8B8BD)),
      ),
      pressed: MyButtonStateStyle(
        backgroundColor: Color(0xFFC6C6CA),
        border: BorderSide(color: Color(0xFFB8B8BD)),
      ),
      focused: MyButtonStateStyle(
        backgroundColor: Color(0xFFEAEAEA),
        border: BorderSide(color: Color(0xFF8D8D94), width: 1.5),
      ),
    ),
    secondary: MyButtonStyleData(
      foregroundColor: Color(0xFFF2F2F3),
      idle: MyButtonStateStyle(
        backgroundColor: Color(0xFF252528),
        border: BorderSide(color: Color(0x1AFFFFFF)),
      ),
      hovered: MyButtonStateStyle(
        backgroundColor: Color(0xFF333336),
        border: BorderSide(color: Color(0x1AFFFFFF)),
      ),
      pressed: MyButtonStateStyle(
        backgroundColor: Color(0xFF38383C),
        border: BorderSide(color: Color(0xFF8D8D94)),
      ),
      focused: MyButtonStateStyle(
        backgroundColor: Color(0xFF252528),
        border: BorderSide(color: Color(0xFF8D8D94), width: 1.5),
      ),
    ),
    ghost: MyButtonStyleData(
      foregroundColor: Color(0xFFF2F2F3),
      idle: MyButtonStateStyle(
        backgroundColor: Color(0x00000000),
        border: BorderSide(color: Color(0x00000000)),
      ),
      hovered: MyButtonStateStyle(
        backgroundColor: Color(0xFF333336),
        border: BorderSide(color: Color(0x00000000)),
      ),
      pressed: MyButtonStateStyle(
        backgroundColor: Color(0xFF38383C),
        border: BorderSide(color: Color(0x00000000)),
      ),
      focused: MyButtonStateStyle(
        backgroundColor: Color(0x00000000),
        border: BorderSide(color: Color(0xFF8D8D94), width: 1.5),
      ),
    ),
    success: fallback.success,
    danger: fallback.danger,
  );

  final MyButtonStyleData primary;
  final MyButtonStyleData secondary;
  final MyButtonStyleData ghost;
  final MyButtonStyleData success;
  final MyButtonStyleData danger;
  final double compactHeight;
  final double regularHeight;
  final double iconSize;
  final double smallIconSize;
  final double radius;
  final double iconRadius;
  final double smoothness;
  final double groupSpacing;
  final double disabledOpacity;
  final TextStyle textStyle;

  MyButtonStyleData styleFor(MyButtonStyle style) => switch (style) {
    MyButtonStyle.primary => primary,
    MyButtonStyle.secondary => secondary,
    MyButtonStyle.ghost => ghost,
    MyButtonStyle.success => success,
    MyButtonStyle.danger => danger,
  };

  double heightFor(MyButtonSize size) => switch (size) {
    MyButtonSize.compact => compactHeight,
    MyButtonSize.regular => regularHeight,
  };
}

/// Provides button styling to a widget subtree without depending on Material.
class MyButtonTheme extends InheritedTheme {
  const MyButtonTheme({required this.data, required super.child, super.key});

  final MyButtonThemeData data;

  static MyButtonThemeData of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MyButtonTheme>()?.data ??
        (MediaQuery.maybePlatformBrightnessOf(context) == Brightness.dark
            ? MyButtonThemeData.darkFallback
            : MyButtonThemeData.fallback);
  }

  @override
  bool updateShouldNotify(MyButtonTheme oldWidget) => data != oldWidget.data;

  @override
  Widget wrap(BuildContext context, Widget child) {
    return MyButtonTheme(data: data, child: child);
  }
}

/// Package fallback colors. Product applications should provide a theme.
abstract final class MyButtonColors {
  static const primaryHighlight = Color(0xFF6F9CFC);
  static const primaryTop = Color(0xFF4E83F9);
  static const primaryBottom = Color(0xFF306CF6);
  static const primaryHoverTop = Color(0xFF6B99FC);
  static const primaryHoverBottom = Color(0xFF306CF7);
  static const primaryPressedTop = Color(0xFF2D63E4);
  static const primaryPressedBottom = Color(0xFF2454C8);
  static const primaryBorder = Color(0xFF285DD6);
  static const primaryPressedBorder = Color(0xFF214CAD);

  static const foreground = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF8E8E93);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceHovered = Color(0xFFF9F9F9);
  static const surfacePressed = Color(0xFFF2F2F1);
  static const border = Color(0xFFD6D6D4);
  static const success = Color(0xFF1E9E64);
  static const successHovered = Color(0xFF2EAA70);
  static const successPressed = Color(0xFF178052);
  static const danger = Color(0xFFDC2626);
  static const dangerHovered = Color(0xFFE23B3B);
  static const dangerPressed = Color(0xFFB91C1C);
  static const transparent = Color(0x00000000);
  static const transparentSurface = Color(0x00FFFFFF);
}

/// Package fallback metrics.
abstract final class MyButtonMetrics {
  static const compactHeight = 30.0;
  static const regularHeight = 34.0;
  static const iconSize = 15.0;
  static const smallIconSize = 13.0;
  static const radius = 9.0;
  static const iconRadius = 999.0;
  static const smoothness = 0.8;
  static const groupSpacing = 12.0;
  static const disabledOpacity = 0.45;
}

/// Package fallback typography.
abstract final class MyButtonTypography {
  static const label = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: MyButtonColors.textPrimary,
  );
}
