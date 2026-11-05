// Adapted from ChunUI (MIT), Copyright (c) 2026 liseami (赵纯想).
// See third_party/CHUNUI_LICENSE and NOTICE.
import 'package:flutter/cupertino.dart';
import 'package:smooth_corner/smooth_corner.dart';

/// Visual treatment of a [CapsuleTag].
enum CapsuleTagVariant {
  /// A flat opaque capsule: neutral surface, hairline border, faint ground
  /// shadow. Ported from ChunUI's `CCCuteTag`.
  cute,

  /// A rounded-rectangle "keycap" chip: a tinted gradient face with an
  /// embossed top highlight and a thick offset base, colored by
  /// [CapsuleTag.color]. Ported from ChunUI's `CCKeycapTag`.
  keycap,

  /// A solid capsule filled with [CapsuleTag.color] and white text, sized
  /// for short labels like "PRO". Ported from ChunUI's `CCProTag`.
  pro,
}

/// A small pill-shaped label ported from ChunUI's "胶囊标签" family.
class CapsuleTag extends StatelessWidget {
  const CapsuleTag(
    this.text, {
    super.key,
    this.variant = CapsuleTagVariant.cute,
    this.icon,
    this.color,
    this.horizontalPadding = 6,
  });

  /// The label text.
  final String text;

  /// Which of the three ChunUI tag treatments to draw.
  final CapsuleTagVariant variant;

  /// A 12pt leading icon. Ignored by [CapsuleTagVariant.pro].
  final IconData? icon;

  /// The accent color for [CapsuleTagVariant.keycap] and
  /// [CapsuleTagVariant.pro]. Defaults to ChunUI's brand accent, `#FF00C8`.
  /// Ignored by [CapsuleTagVariant.cute].
  final Color? color;

  /// Horizontal inset used by [CapsuleTagVariant.cute].
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) => switch (variant) {
    CapsuleTagVariant.cute => _CuteCapsule(
      text: text,
      icon: icon,
      horizontalPadding: horizontalPadding,
    ),
    CapsuleTagVariant.keycap => _KeycapCapsule(
      text: text,
      icon: icon,
      color: color ?? _defaultAccent,
    ),
    CapsuleTagVariant.pro => _ProCapsule(
      text: text,
      color: color ?? _defaultAccent,
    ),
  };
}

class _CuteCapsule extends StatelessWidget {
  const _CuteCapsule({
    required this.text,
    required this.horizontalPadding,
    this.icon,
  });

  final String text;
  final IconData? icon;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final foreground = CupertinoDynamicColor.resolve(
      _capsuleForeground,
      context,
    );
    final background = CupertinoDynamicColor.resolve(
      _capsuleBackground,
      context,
    );
    final border = CupertinoDynamicColor.resolve(_capsuleBorder, context);

    return Container(
      height: 24,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: ShapeDecoration(
        color: background,
        shape: SmoothRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(999)),
          smoothness: 0.8,
          side: BorderSide(color: border.withValues(alpha: border.a * 0.8)),
        ),
        shadows: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeycapCapsule extends StatelessWidget {
  const _KeycapCapsule({required this.text, required this.color, this.icon});

  final String text;
  final Color color;
  final IconData? icon;

  static const double _height = 22;
  static const double _radius = 6;

  @override
  Widget build(BuildContext context) {
    final card = CupertinoDynamicColor.resolve(_capsuleCard, context);
    final muted = CupertinoDynamicColor.resolve(_capsuleMuted, context);
    final border = CupertinoDynamicColor.resolve(_capsuleBorder, context);
    final foreground = CupertinoDynamicColor.resolve(
      _capsuleForeground,
      context,
    );
    final textColor = _mix(color, foreground, 0.24);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 2,
            left: 0,
            right: 0,
            child: Container(
              height: _height,
              decoration: BoxDecoration(
                color: _mix(color, border, 0.28),
                borderRadius: BorderRadius.circular(_radius),
              ),
            ),
          ),
          Container(
            height: _height,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: ShapeDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_mix(color, card, 0.76), _mix(color, muted, 0.66)],
              ),
              shape: SmoothRectangleBorder(
                borderRadius: BorderRadius.circular(_radius),
                smoothness: 0.8,
                side: BorderSide(color: _mix(color, border, 0.52)),
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 1,
                  left: 3,
                  right: 3,
                  child: Container(
                    height: 1,
                    color: CupertinoColors.white.withValues(alpha: 0.52),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 12, color: textColor),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        shadows: [
                          Shadow(
                            color: CupertinoColors.white.withValues(
                              alpha: 0.52,
                            ),
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProCapsule extends StatelessWidget {
  const _ProCapsule({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: color,
        shape: SmoothRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(999)),
          smoothness: 0.8,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: CupertinoColors.white,
          ),
        ),
      ),
    );
  }
}

Color _mix(Color base, Color other, double amount) =>
    Color.lerp(base, other, amount)!;

const _defaultAccent = Color(0xFFFF00C8);

const _capsuleForeground = CupertinoDynamicColor.withBrightness(
  color: Color(0xFF171717),
  darkColor: Color(0xFFFAFAFA),
);

const _capsuleBackground = CupertinoDynamicColor.withBrightness(
  color: Color(0xFFF7F7F9),
  darkColor: Color(0xFF18181B),
);

const _capsuleCard = CupertinoDynamicColor.withBrightness(
  color: Color(0xFFFFFFFF),
  darkColor: Color(0xFF27272A),
);

const _capsuleBorder = CupertinoDynamicColor.withBrightness(
  color: Color(0xFFDCDCE3),
  darkColor: Color(0xFF3F3F46),
);

const _capsuleMuted = CupertinoDynamicColor.withBrightness(
  color: Color(0xFFE8E8ED),
  darkColor: Color(0xFF27272A),
);
