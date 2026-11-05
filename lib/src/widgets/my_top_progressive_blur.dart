import 'package:flutter/cupertino.dart';
import 'package:progressive_blur/progressive_blur.dart';

/// Applies the shared soft progressive blur that fades away from the top edge.
///
/// [blurExtent] is the logical height over which the blur fades to zero. The
/// widget normalizes that extent against its rendered height, so it remains
/// visually consistent when used in pages with different dimensions.
class MyTopProgressiveBlur extends StatelessWidget {
  /// Creates a top-edge progressive blur around [child].
  const MyTopProgressiveBlur({
    required this.child,
    required this.blurExtent,
    this.sigma = _defaultSigma,
    this.blurTextureDimensions = _defaultBlurTextureDimensions,
    this.tintColor = _defaultTintColor,
    this.edgeGuardColor = _defaultEdgeGuardColor,
    super.key,
  }) : assert(blurExtent >= 0),
       assert(sigma >= 0),
       assert(blurTextureDimensions > 0);

  /// The child whose top edge receives the progressive blur.
  final Widget child;

  /// The logical height over which the blur fades from full strength to zero.
  final double blurExtent;

  /// The maximum Gaussian blur standard deviation.
  final double sigma;

  /// The dimensions of the generated blur texture.
  final int blurTextureDimensions;

  /// A subtle color tint composited into the blurred region.
  final Color tintColor;

  /// The page background color used by the fixed texture-edge guard.
  final Color edgeGuardColor;

  static const _defaultSigma = 36.0;
  static const _defaultBlurTextureDimensions = 384;
  static const _defaultTintColor = Color(0x08FFFFFF);
  static const _defaultEdgeGuardColor = Color(0xFFFFFFFF);
  static const _topEdgeGuardExtent = 1.0;

  /// The blur ramp, sampled from an eased `smoothstep(s) ^ 1.35` where `s` is
  /// the normalized distance up from the bottom of the blur region.
  ///
  /// The exponent biases the ramp into a long, shallow toe near the bottom
  /// edge, so content entering the blur softens gradually instead of snapping
  /// out of focus. The curve still saturates high enough near the top that a
  /// translucent header composited over this region stays legible.
  static const _blurValues = <double>[
    1,
    0.981,
    0.919,
    0.795,
    0.64,
    0.473,
    0.315,
    0.193,
    0.107,
    0.047,
    0.013,
    0.002,
    0,
  ];
  static const _blurStopFractions = <double>[
    0,
    0.07,
    0.15,
    0.25,
    0.35,
    0.45,
    0.55,
    0.64,
    0.72,
    0.8,
    0.88,
    0.94,
    1,
  ];

  /// Precaches the blur shader to avoid a first-render pop-in effect.
  static Future<void> precache() => ProgressiveBlurWidget.precache();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final blurStop = constraints.maxHeight > 0
            ? (blurExtent / constraints.maxHeight).clamp(0.0, 1.0).toDouble()
            : 0.0;
        return ProgressiveBlurWidget(
          sigma: sigma,
          blurTextureDimensions: blurTextureDimensions,
          tintColor: tintColor,
          linearGradientBlur: LinearGradientBlur(
            values: _blurValues,
            stops: [
              for (final fraction in _blurStopFractions) blurStop * fraction,
            ],
            start: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              child,
              Positioned(
                key: const Key('my-ui-top-progressive-blur-edge-guard'),
                top: 0,
                left: 0,
                right: 0,
                height: _topEdgeGuardExtent,
                child: IgnorePointer(child: ColoredBox(color: edgeGuardColor)),
              ),
            ],
          ),
        );
      },
    );
  }
}
