import 'dart:ui';

import 'package:flutter/cupertino.dart';

/// A compact folder graphic that keeps [FolderCard]'s shape proportions.
class MiniFolderIcon extends StatelessWidget {
  const MiniFolderIcon({
    super.key,
    this.size = 18,
    this.frontHighlightColors = const [Color(0x73FFFFFF), Color(0x00FFFFFF)],
    this.frontGradientColors = const [Color(0x597BCAFF), Color(0xBF1F91E9)],
    this.backGradientColors = const [Color(0xFF67BCF8), Color(0xFF2885D5)],
    this.paperColor = const CupertinoDynamicColor.withBrightness(
      color: Color(0xFFF9FAFB),
      darkColor: Color(0xFF444448),
    ),
    this.blurSigma = 3,
    this.opacity = 1,
  });

  /// The icon width. Height follows a compact folder ratio: width * 0.78.
  final double size;

  final List<Color> frontHighlightColors;
  final List<Color> frontGradientColors;
  final List<Color> backGradientColors;

  /// Defaults to #F9FAFB in light appearance and derived #444448 in dark.
  final Color paperColor;
  final double blurSigma;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final width = size;
    final height = width * 0.78;
    final dark =
        MediaQuery.maybePlatformBrightnessOf(context) == Brightness.dark;
    final paper = paperColor;
    final resolvedPaper = paper is CupertinoDynamicColor
        ? (dark ? paper.darkColor : paper.color)
        : paper;
    return Opacity(
      opacity: opacity.clamp(0, 1),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned.fill(
              child: _MiniFolderBack(gradientColors: backGradientColors),
            ),
            Positioned(
              left: width * 0.08,
              top: height * 0.14,
              bottom: 0,
              child: Container(
                width: width * 0.84,
                decoration: BoxDecoration(
                  color: resolvedPaper,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(width * 0.05),
                    topRight: Radius.circular(width * 0.05),
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: const Color(
                        0xFF000000,
                      ).withValues(alpha: dark ? 0.24 : 0.08),
                      blurRadius: width * 0.02,
                      offset: Offset(0, -height * 0.01),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _MiniFolderFront(
                height: height * 0.78,
                highlightColors: frontHighlightColors,
                gradientColors: frontGradientColors,
                blurSigma: blurSigma,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniFolderBack extends StatelessWidget {
  const _MiniFolderBack({required this.gradientColors});

  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _MiniFolderBackClipper(),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
        ),
      ),
    );
  }
}

class _MiniFolderFront extends StatelessWidget {
  const _MiniFolderFront({
    required this.height,
    required this.highlightColors,
    required this.gradientColors,
    required this.blurSigma,
  });

  final double height;
  final List<Color> highlightColors;
  final List<Color> gradientColors;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipPath(
        clipper: _MiniFolderFrontClipper(),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: gradientColors,
              ),
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: FractionallySizedBox(
                heightFactor: 0.15,
                widthFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: highlightColors,
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
}

class _MiniFolderBackClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final r = size.width * 0.08;
    final path = Path()
      ..moveTo(r, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - r)
      ..lineTo(0, r * 1.5)
      ..quadraticBezierTo(0, 0, r * 1.2, 0)
      ..lineTo(size.width * 0.25, 0)
      ..cubicTo(
        size.width * 0.32,
        0,
        size.width * 0.32,
        r * 0.8,
        size.width * 0.45,
        r * 0.8,
      )
      ..lineTo(size.width - r, r * 0.8)
      ..quadraticBezierTo(size.width, r * 0.8, size.width, r * 1.8)
      ..lineTo(size.width, size.height - r)
      ..quadraticBezierTo(size.width, size.height, size.width - r, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _MiniFolderFrontClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final r = size.width * 0.08;
    final path = Path()
      ..moveTo(r, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - r)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..lineTo(size.width - r, 0)
      ..quadraticBezierTo(size.width, 0, size.width, r)
      ..lineTo(size.width, size.height - r)
      ..quadraticBezierTo(size.width, size.height, size.width - r, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
