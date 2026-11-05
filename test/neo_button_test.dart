import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:next_ui/next_ui.dart';
import 'package:smooth_corner/smooth_corner.dart';

/// NOTE: [CupertinoActivityIndicator] runs a repeating animation, so
/// `pumpAndSettle()` never returns while a spinner is on screen. Every loading
/// case below uses `pump(Duration(...))` instead, and lets the action finish so
/// no ticker is still running when the test ends.
void main() {
  const Color white = Color(0xFFFFFFFF);
  const Color black = Color(0xFF000000);
  const Color chunPink = Color(0xFFFF00C8);
  const Color destructiveLight = Color(0xFFC13B5F);

  const surfaceKey = ValueKey<String>('neo-button-surface');
  const overlayKey = ValueKey<String>('neo-button-overlay');
  const scaleKey = ValueKey<String>('neo-button-scale');
  const iconSurfaceKey = ValueKey<String>('neo-icon-button-surface');

  Widget testApp(Widget child, {Brightness brightness = Brightness.light}) {
    return CupertinoApp(
      theme: CupertinoThemeData(brightness: brightness),
      home: CupertinoPageScaffold(child: Center(child: child)),
    );
  }

  ShapeDecoration surfaceOf(WidgetTester tester) {
    return tester.widget<DecoratedBox>(find.byKey(surfaceKey)).decoration
        as ShapeDecoration;
  }

  SmoothRectangleBorder shapeOf(WidgetTester tester) =>
      surfaceOf(tester).shape as SmoothRectangleBorder;

  double radiusOf(WidgetTester tester) =>
      shapeOf(tester).borderRadius.resolve(TextDirection.ltr).topLeft.x;

  double scaleOf(WidgetTester tester) =>
      tester.widget<ScaleTransition>(find.byKey(scaleKey)).scale.value;

  /// Compares as zero padded hex so a failure reads as `ff24d0` vs `ff24d1`
  /// rather than as two nine digit integers.
  void expectColor(Color? actual, int expected, {String? reason}) {
    expect(
      actual?.toARGB32().toRadixString(16).padLeft(8, '0'),
      expected.toRadixString(16).padLeft(8, '0'),
      reason: reason,
    );
  }

  NeoButtonVisualStyle styleOf(
    NeoButtonVariant variant, {
    Brightness brightness = Brightness.light,
    Color? accent,
  }) => resolveNeoButtonStyle(
    variant: variant,
    brightness: brightness,
    accent: accent,
  );

  // ---------------------------------------------------------------------------
  // A. resolveNeoButtonStyle — every ported number is pinned here.
  // ---------------------------------------------------------------------------

  group('resolveNeoButtonStyle', () {
    test('primary fills with the three stop vertical gradient', () {
      final gradient = styleOf(NeoButtonVariant.primary).fillGradient!;

      expect(gradient.begin, Alignment.topCenter);
      expect(gradient.end, Alignment.bottomCenter);
      expect(gradient.stops, const <double>[0, 0.5, 1]);
      expectColor(
        gradient.colors[0],
        0xFFFF24D0,
        reason: 'mix(fill, white, .14)',
      );
      expectColor(gradient.colors[1], 0xFFFF00C8, reason: 'the base fill');
      expectColor(
        gradient.colors[2],
        0xFFE600B4,
        reason: 'mix(fill, black, .10)',
      );
    });

    test('primary draws a gradient border, never a solid one', () {
      final style = styleOf(NeoButtonVariant.primary);
      final border = style.borderGradient!;

      expect(style.borderColor, isNull);
      expect(style.borderWidth, 0.66);
      expect(border.begin, Alignment.topCenter);
      expect(border.end, Alignment.bottomCenter);
      expectColor(border.colors[0], 0x73FFFFFF, reason: 'white @ .45');
      expectColor(
        border.colors[1],
        0x8CB80090,
        reason: 'mix(fill, black, .28) @ .55',
      );
    });

    test(
      'primary highlights inside the top edge and casts a tinted shadow',
      () {
        final style = styleOf(NeoButtonVariant.primary);

        expectColor(
          style.innerHighlightColor,
          0x6BFFFFFF,
          reason: 'white @ .42',
        );
        expectColor(style.dropShadow!.color, 0x33FF00C8, reason: 'fill @ .20');
        expect(style.dropShadow!.blurRadius, 6);
        expect(style.dropShadow!.offset, const Offset(0, 1.5));
        expect(style.dropShadow!.spreadRadius, 0);
      },
    );

    test('danger uses the destructive ramp and a white label', () {
      final style = styleOf(NeoButtonVariant.danger);
      final fill = style.fillGradient!;
      final border = style.borderGradient!;

      expectColor(style.foregroundColor, 0xFFFFFFFF);
      expectColor(fill.colors[0], 0xFFC85372, reason: 'mix(dest, white, .12)');
      expectColor(fill.colors[1], 0xFFC13B5F);
      expectColor(fill.colors[2], 0xFFAA3454, reason: 'mix(dest, black, .12)');
      expectColor(border.colors[0], 0x66FFFFFF, reason: 'white @ .40');
      expectColor(
        border.colors[1],
        Color.lerp(
          destructiveLight,
          black,
          0.3,
        )!.withValues(alpha: 0.55).toARGB32(),
        reason: 'mix(dest, black, .30) @ .55',
      );
      expectColor(style.innerHighlightColor, 0x59FFFFFF, reason: 'white @ .35');
      expectColor(style.dropShadow!.color, 0x2EC13B5F, reason: 'dest @ .18');
      expect(style.borderWidth, 0.66);
    });

    test('secondary is a flat card with a hairline border', () {
      final style = styleOf(NeoButtonVariant.secondary);

      expectColor(style.fillColor, 0xFFFFFFFF);
      expect(style.fillGradient, isNull);
      expect(style.borderGradient, isNull);
      expectColor(style.borderColor, 0xE6DCDCE3, reason: 'border @ .9');
      expect(style.borderWidth, 0.5);
      expectColor(style.dropShadow!.color, 0x0D000000, reason: 'black @ .05');
      expectColor(style.foregroundColor, 0xFF171717);
      expect(style.innerHighlightColor, isNull);
    });

    test('ghost paints nothing but its label', () {
      final style = styleOf(NeoButtonVariant.ghost);

      expect(style.fillColor, isNull);
      expect(style.fillGradient, isNull);
      expect(style.innerHighlightColor, isNull);
      expect(style.borderColor, isNull);
      expect(style.borderGradient, isNull);
      expect(style.borderWidth, 0);
      expect(style.dropShadow, isNull);
      expectColor(style.foregroundColor, 0xFF171717);
    });

    test('outline is a one point border with no fill and no shadow', () {
      final style = styleOf(NeoButtonVariant.outline);

      expectColor(style.borderColor, 0xFFDCDCE3);
      expect(style.borderWidth, 1);
      expect(style.fillColor, isNull);
      expect(style.fillGradient, isNull);
      expect(style.dropShadow, isNull);
    });

    test('dark brightness swaps the whole neutral table', () {
      expectColor(
        styleOf(
          NeoButtonVariant.secondary,
          brightness: Brightness.dark,
        ).fillColor,
        0xFF27272A,
      );
      expectColor(
        styleOf(
          NeoButtonVariant.ghost,
          brightness: Brightness.dark,
        ).foregroundColor,
        0xFFFAFAFA,
      );
      expectColor(
        styleOf(
          NeoButtonVariant.outline,
          brightness: Brightness.dark,
        ).borderColor,
        0xFF3F3F46,
      );
      expectColor(
        styleOf(
          NeoButtonVariant.danger,
          brightness: Brightness.dark,
        ).fillGradient!.colors[1],
        0xFFE07A94,
      );
      // ChunUI keeps the brand color identical in both brightnesses.
      expectColor(
        styleOf(
          NeoButtonVariant.primary,
          brightness: Brightness.dark,
        ).fillGradient!.colors[1],
        0xFFFF00C8,
      );
    });

    test('accent redraws primary and forces a white label', () {
      const accent = Color(0xFF07C160);
      final style = styleOf(NeoButtonVariant.primary, accent: accent);
      final fill = style.fillGradient!;
      final border = style.borderGradient!;

      expectColor(style.foregroundColor, 0xFFFFFFFF);
      expectColor(fill.colors[0], Color.lerp(accent, white, 0.14)!.toARGB32());
      expectColor(fill.colors[1], 0xFF07C160);
      expectColor(fill.colors[2], Color.lerp(accent, black, 0.1)!.toARGB32());
      expectColor(
        border.colors[1],
        Color.lerp(accent, black, 0.28)!.withValues(alpha: 0.55).toARGB32(),
      );
      expectColor(style.dropShadow!.color, 0x3307C160, reason: 'accent @ .20');

      // Every other variant ignores accent entirely.
      expect(
        styleOf(NeoButtonVariant.danger, accent: accent),
        styleOf(NeoButtonVariant.danger),
      );
      expect(
        styleOf(NeoButtonVariant.secondary, accent: accent),
        styleOf(NeoButtonVariant.secondary),
      );
    });

    test('the solid variants carry the heavier label weight', () {
      expect(styleOf(NeoButtonVariant.primary).fontWeight, FontWeight.w600);
      expect(styleOf(NeoButtonVariant.danger).fontWeight, FontWeight.w600);
      expect(styleOf(NeoButtonVariant.secondary).fontWeight, FontWeight.w500);
      expect(styleOf(NeoButtonVariant.ghost).fontWeight, FontWeight.w500);
      expect(styleOf(NeoButtonVariant.outline).fontWeight, FontWeight.w500);
    });
  });

  // ---------------------------------------------------------------------------
  // B. Geometry.
  // ---------------------------------------------------------------------------

  group('NeoButton geometry', () {
    testWidgets('defaults to the medium size', (tester) async {
      await tester.pumpWidget(testApp(NeoButton('Start', onPressed: () {})));

      expect(tester.getSize(find.byType(NeoButton)).height, 44);
      expect(radiusOf(tester), moreOrLessEquals(16.72));
      expect(shapeOf(tester).smoothness, 1.0);
    });

    testWidgets('each size carries its own height, radius, and metrics', (
      tester,
    ) async {
      const cases = <(NeoButtonSize, double, double, double, double)>[
        (NeoButtonSize.small, 34, 12.92, 14, 13),
        (NeoButtonSize.medium, 44, 16.72, 16, 17),
        (NeoButtonSize.large, 52, 19.76, 18, 17),
      ];

      for (final (size, height, radius, iconSize, fontSize) in cases) {
        await tester.pumpWidget(
          testApp(
            NeoButton(
              'Start',
              size: size,
              icon: LucideIcons.sparkles,
              onPressed: () {},
            ),
          ),
        );

        expect(
          tester.getSize(find.byType(NeoButton)).height,
          height,
          reason: '$size',
        );
        expect(radiusOf(tester), moreOrLessEquals(radius), reason: '$size');
        expect(
          tester.widget<Icon>(find.byType(Icon)).size,
          iconSize,
          reason: '$size',
        );
        expect(
          tester.widget<Text>(find.text('Start')).style!.fontSize,
          fontSize,
          reason: '$size',
        );
      }
    });

    testWidgets('horizontal padding matches the ported values', (tester) async {
      const expected = <NeoButtonSize, double>{
        NeoButtonSize.small: 14,
        NeoButtonSize.medium: 18,
        NeoButtonSize.large: 22,
      };

      for (final entry in expected.entries) {
        await tester.pumpWidget(
          testApp(NeoButton('Start', size: entry.key, onPressed: () {})),
        );
        final padding =
            tester
                    .widget<Padding>(
                      find.descendant(
                        of: find.byKey(surfaceKey),
                        matching: find.byType(Padding),
                      ),
                    )
                    .padding
                as EdgeInsets;
        expect(padding.left, entry.value, reason: '${entry.key}');
      }
    });

    testWidgets('the icon sits exactly seven points from the label', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          NeoButton('Start', icon: LucideIcons.sparkles, onPressed: () {}),
        ),
      );

      final gap =
          tester.getTopLeft(find.text('Start')).dx -
          tester.getTopRight(find.byType(Icon)).dx;
      expect(gap, moreOrLessEquals(7, epsilon: 0.01));
    });

    testWidgets('fullWidth fills its parent while the default hugs', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          SizedBox(
            width: 300,
            child: NeoButton('Start', fullWidth: true, onPressed: () {}),
          ),
        ),
      );
      expect(tester.getSize(find.byType(NeoButton)).width, 300);

      await tester.pumpWidget(testApp(NeoButton('Start', onPressed: () {})));
      expect(tester.getSize(find.byType(NeoButton)).width, lessThan(300));
    });

    testWidgets('fullWidth content can align to the leading edge', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          SizedBox(
            width: 300,
            child: NeoButton(
              'Start',
              fullWidth: true,
              contentAlignment: MainAxisAlignment.start,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(
        tester.getTopLeft(find.text('Start')).dx,
        lessThan(tester.getCenter(find.byType(NeoButton)).dx),
      );
    });

    testWidgets('a long label ellipsizes on one line instead of overflowing', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          SizedBox(
            width: 120,
            child: NeoButton(
              'An extremely long call to action label',
              fullWidth: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(
        find.text('An extremely long call to action label'),
      );
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // C. Paint wiring.
  // ---------------------------------------------------------------------------

  group('NeoButton painting', () {
    testWidgets('secondary reads back its fill, hairline, and shadow', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          NeoButton(
            'Start',
            variant: NeoButtonVariant.secondary,
            onPressed: () {},
          ),
        ),
      );

      final decoration = surfaceOf(tester);
      expectColor(decoration.color, 0xFFFFFFFF);
      expect(decoration.gradient, isNull);
      expectColor(shapeOf(tester).side.color, 0xE6DCDCE3);
      expect(shapeOf(tester).side.width, 0.5);
      expectColor(decoration.shadows!.single.color, 0x0D000000);
    });

    testWidgets('ghost and outline stay unfilled and unshadowed', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          NeoButton('Start', variant: NeoButtonVariant.ghost, onPressed: () {}),
        ),
      );
      expect(surfaceOf(tester).color, isNull);
      expect(surfaceOf(tester).shadows, isNull);
      expect(shapeOf(tester).side, BorderSide.none);

      await tester.pumpWidget(
        testApp(
          NeoButton(
            'Start',
            variant: NeoButtonVariant.outline,
            onPressed: () {},
          ),
        ),
      );
      expect(surfaceOf(tester).color, isNull);
      expect(surfaceOf(tester).shadows, isNull);
      expect(shapeOf(tester).side.width, 1);
      expectColor(shapeOf(tester).side.color, 0xFFDCDCE3);
    });

    testWidgets('only the gradient variants add the overlay painter', (
      tester,
    ) async {
      const withOverlay = <NeoButtonVariant>[
        NeoButtonVariant.primary,
        NeoButtonVariant.danger,
      ];
      const withoutOverlay = <NeoButtonVariant>[
        NeoButtonVariant.secondary,
        NeoButtonVariant.ghost,
        NeoButtonVariant.outline,
      ];

      for (final variant in withOverlay) {
        await tester.pumpWidget(
          testApp(NeoButton('Start', variant: variant, onPressed: () {})),
        );
        expect(find.byKey(overlayKey), findsOneWidget, reason: '$variant');
      }
      for (final variant in withoutOverlay) {
        await tester.pumpWidget(
          testApp(NeoButton('Start', variant: variant, onPressed: () {})),
        );
        expect(find.byKey(overlayKey), findsNothing, reason: '$variant');
      }
    });

    testWidgets('an ambient dark CupertinoTheme darkens the card', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          NeoButton(
            'Start',
            variant: NeoButtonVariant.secondary,
            onPressed: () {},
          ),
          brightness: Brightness.dark,
        ),
      );

      expectColor(surfaceOf(tester).color, 0xFF27272A);
    });

    testWidgets('an explicit brightness beats the ambient theme', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          NeoButton(
            'Start',
            variant: NeoButtonVariant.secondary,
            brightness: Brightness.light,
            onPressed: () {},
          ),
          brightness: Brightness.dark,
        ),
      );

      expectColor(surfaceOf(tester).color, 0xFFFFFFFF);
    });

    testWidgets('accent reaches the painted gradient', (tester) async {
      const accent = Color(0xFF07C160);
      await tester.pumpWidget(
        testApp(NeoButton('Start', accent: accent, onPressed: () {})),
      );

      expect(
        surfaceOf(tester).gradient,
        styleOf(NeoButtonVariant.primary, accent: accent).fillGradient,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // D. Interaction.
  // ---------------------------------------------------------------------------

  group('NeoButton interaction', () {
    testWidgets('disabled dims to 0.45 and swallows the tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        testApp(NeoButton('Start', disabled: true, onPressed: () => taps++)),
      );

      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        0.45,
      );
      await tester.tap(find.byType(NeoButton), warnIfMissed: false);
      await tester.pump();
      expect(taps, 0);
    });

    testWidgets('a null callback disables the button', (tester) async {
      await tester.pumpWidget(
        testApp(const NeoButton('Start', onPressed: null)),
      );

      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        0.45,
      );
      expect(
        tester.widget<CupertinoButton>(find.byType(CupertinoButton)).onPressed,
        isNull,
      );
    });

    testWidgets('an async action drives the spinner and blocks re-entry', (
      tester,
    ) async {
      final completer = Completer<void>();
      var runs = 0;

      await tester.pumpWidget(
        testApp(
          NeoButton(
            'Save',
            icon: LucideIcons.sparkles,
            onPressed: () {
              runs++;
              return completer.future;
            },
          ),
        ),
      );

      await tester.tap(find.byType(NeoButton));
      await tester.pump();

      expect(runs, 1);
      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      expect(find.byType(Icon), findsNothing);

      // A second tap while in flight must not start another run.
      await tester.tap(find.byType(NeoButton), warnIfMissed: false);
      await tester.pump();
      expect(runs, 1);

      completer.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(CupertinoActivityIndicator), findsNothing);
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('loading stays at full opacity even when also disabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          NeoButton('Save', loading: true, disabled: true, onPressed: () {}),
        ),
      );

      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        1,
      );
      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);

      // Drop the spinner so no ticker outlives the test.
      await tester.pumpWidget(testApp(const SizedBox()));
    });

    testWidgets('a synchronous action never flashes a spinner', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        testApp(
          NeoButton(
            'Start',
            icon: LucideIcons.sparkles,
            onPressed: () => taps++,
          ),
        ),
      );

      await tester.tap(find.byType(NeoButton));
      await tester.pump();

      expect(taps, 1);
      expect(find.byType(CupertinoActivityIndicator), findsNothing);
      expect(find.byType(Icon), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('an explicit loading flag overrides the automatic state', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          NeoButton(
            'Save',
            loading: false,
            onPressed: () async => Completer<void>().future,
          ),
        ),
      );

      await tester.tap(find.byType(NeoButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(CupertinoActivityIndicator), findsNothing);
    });

    testWidgets('being disposed mid flight does not throw', (tester) async {
      final completer = Completer<void>();

      await tester.pumpWidget(
        testApp(NeoButton('Save', onPressed: () => completer.future)),
      );
      await tester.tap(find.byType(NeoButton));
      await tester.pump();
      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);

      await tester.pumpWidget(testApp(const SizedBox()));
      completer.complete();
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('a throwing action clears loading and reports the error', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          NeoButton(
            'Save',
            icon: LucideIcons.sparkles,
            onPressed: () async => throw StateError('boom'),
          ),
        ),
      );

      await tester.tap(find.byType(NeoButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isA<StateError>());
      expect(find.byType(CupertinoActivityIndicator), findsNothing);
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('pressing springs the scale down and releasing returns it', (
      tester,
    ) async {
      await tester.pumpWidget(testApp(NeoButton('Start', onPressed: () {})));
      expect(scaleOf(tester), 1);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(NeoButton)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      expect(scaleOf(tester), lessThan(1));
      expect(scaleOf(tester), greaterThan(0.9));

      await gesture.up();
      await tester.pumpAndSettle();

      expect(scaleOf(tester), moreOrLessEquals(1, epsilon: 0.001));
    });

    testWidgets('a tap emits a light impact unless haptics are off', (
      tester,
    ) async {
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          calls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      bool tappedLight() => calls.any(
        (call) =>
            call.method == 'HapticFeedback.vibrate' &&
            call.arguments == 'HapticFeedbackType.lightImpact',
      );

      await tester.pumpWidget(testApp(NeoButton('Start', onPressed: () {})));
      await tester.tap(find.byType(NeoButton));
      await tester.pumpAndSettle();
      expect(tappedLight(), isTrue);

      calls.clear();
      await tester.pumpWidget(
        testApp(
          NeoButton('Start', enableHapticFeedback: false, onPressed: () {}),
        ),
      );
      await tester.tap(find.byType(NeoButton));
      await tester.pumpAndSettle();
      expect(tappedLight(), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // E. NeoIconButton.
  // ---------------------------------------------------------------------------

  group('NeoIconButton', () {
    testWidgets('is a forty point circle around an eighteen point glyph', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          NeoIconButton(
            icon: LucideIcons.layoutGrid,
            semanticsLabel: 'Layout',
            onPressed: () {},
          ),
        ),
      );

      expect(tester.getSize(find.byType(NeoIconButton)), const Size(40, 40));
      expect(tester.widget<Icon>(find.byType(Icon)).size, 18);
    });

    testWidgets('filled adds the card circle, hairline ring, and shadow', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          NeoIconButton(
            icon: LucideIcons.layers,
            semanticsLabel: 'Layers',
            filled: true,
            onPressed: () {},
          ),
        ),
      );

      final decoration =
          tester.widget<DecoratedBox>(find.byKey(iconSurfaceKey)).decoration
              as ShapeDecoration;
      final shape = decoration.shape as CircleBorder;

      expectColor(decoration.color, 0xFFFFFFFF);
      expect(shape.side.width, 0.5);
      expectColor(shape.side.color, 0xE6DCDCE3);
      expectColor(decoration.shadows!.single.color, 0x0D000000);
      expect(decoration.shadows!.single.offset, const Offset(0, 1));
    });

    testWidgets('the flat variant paints no surface', (tester) async {
      await tester.pumpWidget(
        testApp(
          NeoIconButton(
            icon: LucideIcons.layers,
            semanticsLabel: 'Layers',
            onPressed: () {},
          ),
        ),
      );

      expect(find.byKey(iconSurfaceKey), findsNothing);
    });

    testWidgets('semantic variants reuse NeoButton surface styling', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          NeoIconButton(
            icon: LucideIcons.plus,
            semanticsLabel: 'Add',
            variant: NeoButtonVariant.primary,
            onPressed: () {},
          ),
        ),
      );

      final decoration =
          tester.widget<DecoratedBox>(find.byKey(iconSurfaceKey)).decoration
              as ShapeDecoration;
      expect(
        decoration.gradient,
        styleOf(NeoButtonVariant.primary).fillGradient,
      );
      expect(decoration.shape, isA<CircleBorder>());
      expectColor(tester.widget<Icon>(find.byType(Icon)).color, 0xFFFFFFFF);
      expect(
        find.byKey(const ValueKey<String>('neo-icon-button-overlay')),
        findsOneWidget,
      );
    });

    testWidgets('shows its optional desktop tooltip after hover', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          NeoIconButton(
            icon: LucideIcons.layers,
            semanticsLabel: 'Layers',
            tooltip: 'Choose layers',
            onPressed: () {},
          ),
        ),
      );

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer();
      await mouse.moveTo(tester.getCenter(find.byType(NeoIconButton)));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Choose layers'), findsOneWidget);
    });

    testWidgets('shares the press spring and fires its callback', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        testApp(
          NeoIconButton(
            icon: LucideIcons.layers,
            semanticsLabel: 'Layers',
            onPressed: () => taps++,
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(NeoIconButton)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(scaleOf(tester), lessThan(1));

      await gesture.up();
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(scaleOf(tester), moreOrLessEquals(1, epsilon: 0.001));
    });

    testWidgets('tints with mutedForeground unless overridden', (tester) async {
      await tester.pumpWidget(
        testApp(
          NeoIconButton(
            icon: LucideIcons.layers,
            semanticsLabel: 'Layers',
            onPressed: () {},
          ),
        ),
      );
      expectColor(tester.widget<Icon>(find.byType(Icon)).color, 0xFF6B6B6B);

      await tester.pumpWidget(
        testApp(
          NeoIconButton(
            icon: LucideIcons.layers,
            semanticsLabel: 'Layers',
            tint: const Color(0xFF07C160),
            onPressed: () {},
          ),
        ),
      );
      expectColor(tester.widget<Icon>(find.byType(Icon)).color, 0xFF07C160);
    });

    testWidgets('a null callback dims the button', (tester) async {
      await tester.pumpWidget(
        testApp(
          const NeoIconButton(
            icon: LucideIcons.layers,
            semanticsLabel: 'Layers',
            onPressed: null,
          ),
        ),
      );

      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        0.45,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // F. Theming.
  // ---------------------------------------------------------------------------

  group('NeoButtonTheme', () {
    testWidgets('overrides geometry and palette for the whole family', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          NeoButtonTheme(
            data: NeoButtonThemeData(
              medium: NeoButtonSizeSpec.medium.copyWith(height: 60),
              smoothness: 0.9,
              iconButton: NeoIconButtonSpec.fallback.copyWith(diameter: 56),
              palette: const NeoButtonPalette(
                card: NeoColor.constant(Color(0xFF102030)),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NeoButton(
                  'Start',
                  variant: NeoButtonVariant.secondary,
                  onPressed: () {},
                ),
                NeoIconButton(
                  icon: LucideIcons.layers,
                  semanticsLabel: 'Layers',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(NeoButton)).height, 60);
      expect(radiusOf(tester), moreOrLessEquals(22.8));
      expect(shapeOf(tester).smoothness, 0.9);
      expectColor(surfaceOf(tester).color, 0xFF102030);
      expect(tester.getSize(find.byType(NeoIconButton)), const Size(56, 56));
    });

    testWidgets('a theme brightness overrides the ambient one', (tester) async {
      await tester.pumpWidget(
        testApp(
          NeoButtonTheme(
            data: const NeoButtonThemeData(brightness: Brightness.dark),
            child: NeoButton(
              'Start',
              variant: NeoButtonVariant.secondary,
              onPressed: () {},
            ),
          ),
        ),
      );

      expectColor(surfaceOf(tester).color, 0xFF27272A);
    });

    test('theme data copies and compares by value', () {
      const base = NeoButtonThemeData.fallback;

      expect(base.copyWith(), base);
      expect(base.copyWith(smoothness: 0.9), isNot(base));
      expect(base.copyWith(smoothness: 0.9).smoothness, 0.9);
      expect(base.copyWith(smoothness: 0.9).palette, base.palette);
      expect(base.hashCode, const NeoButtonThemeData().hashCode);
      expect(base.specFor(NeoButtonSize.small), NeoButtonSizeSpec.small);
      expect(base.specFor(NeoButtonSize.medium), NeoButtonSizeSpec.medium);
      expect(base.specFor(NeoButtonSize.large), NeoButtonSizeSpec.large);
      expect(NeoButtonSizeSpec.medium.radiusFor(0.38), moreOrLessEquals(16.72));
      // The radius is clamped to a capsule at most.
      expect(NeoButtonSizeSpec.medium.radiusFor(0.9), 22);
    });

    test('NeoColor resolves and interpolates per brightness', () {
      const pair = NeoColor(light: white, dark: black);

      expect(pair.resolve(Brightness.light), white);
      expect(pair.resolve(Brightness.dark), black);
      expect(
        const NeoColor.constant(chunPink).resolve(Brightness.dark),
        chunPink,
      );
      expectColor(pair.withValues(alpha: 0.5).light, 0x80FFFFFF);
      expect(pair, const NeoColor(light: white, dark: black));
      expect(pair.hashCode, const NeoColor(light: white, dark: black).hashCode);
      expect(pair.toString(), contains('NeoColor'));

      final mid = NeoColor.lerp(pair, const NeoColor.constant(black), 1)!;
      expect(mid.light, black);
      expect(NeoColor.lerp(null, null, 0.5), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // G. Hover. ChunUI's CCNeoButton is iOS only and has none; the tokens come
  // from its `accent` / `accentForeground` pair, which the design system
  // documents as the grayscale hover and selection surface.
  // ---------------------------------------------------------------------------

  group('NeoButton hover', () {
    Future<void> hoverOver(WidgetTester tester, Finder finder) async {
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(finder));
      await tester.pumpAndSettle();
    }

    test(
      'the brand variants take a white lift, the neutrals take a surface',
      () {
        // A gray wash over the neon gradient would only muddy it.
        expectColor(
          styleOf(NeoButtonVariant.primary).hoverOverlayColor,
          0x2EFFFFFF,
        );
        expectColor(
          styleOf(NeoButtonVariant.danger).hoverOverlayColor,
          0x2EFFFFFF,
        );
        expect(styleOf(NeoButtonVariant.primary).hoverForegroundColor, isNull);
        expect(styleOf(NeoButtonVariant.danger).hoverForegroundColor, isNull);

        for (final variant in <NeoButtonVariant>[
          NeoButtonVariant.secondary,
          NeoButtonVariant.outline,
          NeoButtonVariant.ghost,
        ]) {
          final style = styleOf(variant);
          expectColor(
            style.hoverOverlayColor,
            0xFFDEDEE5,
            reason: '$variant hover surface',
          );
          expectColor(
            style.hoverForegroundColor,
            0xFF171717,
            reason: '$variant hover label',
          );

          final dark = styleOf(variant, brightness: Brightness.dark);
          expectColor(
            dark.hoverOverlayColor,
            0xFF3F3F46,
            reason: '$variant dark',
          );
          expectColor(dark.hoverForegroundColor, 0xFFFAFAFA);
        }
      },
    );

    test('resting is the identity of the fold', () {
      final style = styleOf(NeoButtonVariant.ghost);

      expect(style.withHover(0), same(style));
      expect(style.withHover(-1), same(style));
      expect(style.withHover(2), style.withHover(1));
    });

    test('the neutral overlay fades in and then takes the surface over', () {
      final ghost = styleOf(NeoButtonVariant.ghost).withHover(1);
      final half = styleOf(NeoButtonVariant.ghost).withHover(0.5);
      final secondary = styleOf(NeoButtonVariant.secondary).withHover(1);

      // Ghost and outline have no resting fill, so the overlay becomes one.
      expectColor(ghost.fillColor, 0xFFDEDEE5);
      expectColor(half.fillColor, 0x80DEDEE5);
      // An opaque overlay covers the card outright.
      expectColor(secondary.fillColor, 0xFFDEDEE5);
    });

    test('hover never touches the edge or the shadow', () {
      final rest = styleOf(NeoButtonVariant.secondary);
      final hovered = rest.withHover(1);

      expect(hovered.borderColor, rest.borderColor);
      expect(hovered.borderWidth, rest.borderWidth);
      expect(hovered.dropShadow, rest.dropShadow);
      expect(hovered.innerHighlightColor, rest.innerHighlightColor);
      expect(
        styleOf(NeoButtonVariant.primary).withHover(1).borderGradient,
        styleOf(NeoButtonVariant.primary).borderGradient,
      );
    });

    test('the brand lift brightens every stop and keeps the ramp', () {
      final rest = styleOf(NeoButtonVariant.primary).fillGradient!;
      final hovered = styleOf(NeoButtonVariant.primary).withHover(1);
      final lifted = hovered.fillGradient!;

      // ShapeDecoration refuses to hold a color and a gradient at once.
      expect(hovered.fillColor, isNull);
      expect(lifted.stops, rest.stops);
      expect(lifted.begin, rest.begin);
      expect(lifted.end, rest.end);
      for (var i = 0; i < rest.colors.length; i++) {
        expect(
          lifted.colors[i].g,
          greaterThan(rest.colors[i].g),
          reason: 'stop $i should lift',
        );
        expect(lifted.colors[i].b, greaterThan(rest.colors[i].b));
      }
    });

    test('the label crosses to the hover foreground', () {
      const palette = NeoButtonPalette(
        hoverForeground: NeoColor.constant(Color(0xFF000000)),
      );
      final style = resolveNeoButtonStyle(
        variant: NeoButtonVariant.ghost,
        brightness: Brightness.light,
        palette: palette,
      );
      final half = style.withHover(0.5).foregroundColor;

      expectColor(style.withHover(1).foregroundColor, 0xFF000000);
      expect(half.r, lessThan(style.foregroundColor.r));
      expect(half.r, greaterThan(0));
      // The default palette repeats `foreground` here, so hover is invisible.
      expectColor(
        styleOf(NeoButtonVariant.ghost).withHover(1).foregroundColor,
        0xFF171717,
      );
    });

    testWidgets('a ghost button grows a surface under the pointer', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          NeoButton('Ghost', variant: NeoButtonVariant.ghost, onPressed: () {}),
        ),
      );

      expect(surfaceOf(tester).color, isNull);

      await hoverOver(tester, find.byType(NeoButton));
      expectColor(surfaceOf(tester).color, 0xFFDEDEE5);
    });

    testWidgets('the fade runs rather than snapping', (tester) async {
      await tester.pumpWidget(
        testApp(
          NeoButton('Ghost', variant: NeoButtonVariant.ghost, onPressed: () {}),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.byType(NeoButton)));
      await tester.pump();
      await tester.pump(NeoButtonMetrics.hoverDuration ~/ 2);

      final Color? mid = surfaceOf(tester).color;
      expect(mid, isNotNull);
      expect(mid!.a, greaterThan(0));
      expect(mid.a, lessThan(1));

      await tester.pumpAndSettle();
      expectColor(surfaceOf(tester).color, 0xFFDEDEE5);

      // Leaving takes it back to a bare surface.
      await gesture.moveTo(Offset.zero);
      await tester.pumpAndSettle();
      expect(surfaceOf(tester).color, isNull);
    });

    testWidgets('a primary button lifts without tripping ShapeDecoration', (
      tester,
    ) async {
      await tester.pumpWidget(testApp(NeoButton('Go', onPressed: () {})));

      final LinearGradient rest = surfaceOf(tester).gradient! as LinearGradient;

      await hoverOver(tester, find.byType(NeoButton));
      final LinearGradient lifted =
          surfaceOf(tester).gradient! as LinearGradient;

      expect(surfaceOf(tester).color, isNull);
      expect(lifted.colors[1].g, greaterThan(rest.colors[1].g));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a disabled button ignores the pointer', (tester) async {
      await tester.pumpWidget(
        testApp(
          const NeoButton(
            'Ghost',
            variant: NeoButtonVariant.ghost,
            onPressed: null,
          ),
        ),
      );

      await hoverOver(tester, find.byType(NeoButton));
      expect(surfaceOf(tester).color, isNull);
    });

    testWidgets('a flat icon button grows a disc and darkens its glyph', (
      tester,
    ) async {
      const hoverKey = ValueKey<String>('neo-icon-button-hover');
      await tester.pumpWidget(
        testApp(
          NeoIconButton(
            icon: LucideIcons.layers,
            semanticsLabel: 'Layers',
            onPressed: () {},
          ),
        ),
      );

      expect(find.byKey(hoverKey), findsNothing);
      expect(find.byKey(iconSurfaceKey), findsNothing);
      expectColor(tester.widget<Icon>(find.byType(Icon)).color, 0xFF6B6B6B);

      await hoverOver(tester, find.byType(NeoIconButton));

      final disc =
          tester.widget<DecoratedBox>(find.byKey(hoverKey)).decoration
              as ShapeDecoration;
      expectColor(disc.color, 0xFFDEDEE5);
      expect(disc.shape, isA<CircleBorder>());
      // A flat button stays flat: the disc brings no ring and no shadow.
      expect((disc.shape as CircleBorder).side, BorderSide.none);
      expect(disc.shadows, isNull);
      expectColor(tester.widget<Icon>(find.byType(Icon)).color, 0xFF171717);
    });

    testWidgets('a filled icon button blends the scrim over its card', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          NeoIconButton(
            icon: LucideIcons.layers,
            semanticsLabel: 'Layers',
            filled: true,
            onPressed: () {},
          ),
        ),
      );

      final ShapeDecoration rest =
          tester.widget<DecoratedBox>(find.byKey(iconSurfaceKey)).decoration
              as ShapeDecoration;
      expectColor(rest.color, 0xFFFFFFFF);

      await hoverOver(tester, find.byType(NeoIconButton));

      final ShapeDecoration hovered =
          tester.widget<DecoratedBox>(find.byKey(iconSurfaceKey)).decoration
              as ShapeDecoration;
      expectColor(hovered.color, 0xFFDEDEE5);
      // The ring and the shadow are untouched.
      expect(hovered.shape, rest.shape);
      expect(hovered.shadows, rest.shadows);
    });

    testWidgets('a theme retimes the fade', (tester) async {
      await tester.pumpWidget(
        testApp(
          NeoButtonTheme(
            data: const NeoButtonThemeData(
              hoverDuration: Duration(milliseconds: 600),
            ),
            child: NeoButton(
              'Ghost',
              variant: NeoButtonVariant.ghost,
              onPressed: () {},
            ),
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.byType(NeoButton)));
      await tester.pump();
      // The default 120ms fade would already be finished by here.
      await tester.pump(const Duration(milliseconds: 200));

      expect(surfaceOf(tester).color!.a, lessThan(1));
      await tester.pumpAndSettle();
      expectColor(surfaceOf(tester).color, 0xFFDEDEE5);
    });
  });

  // ---------------------------------------------------------------------------
  // H. Press style. `.scale` is the ChunUI original and stays the default;
  // `.sunken` is modeled on MyButton's pressed state
  // (lib/src/widgets/my_button_theme.dart) — no scale, only the fill and
  // border darken. The inner highlight and drop shadow are left alone.
  // ---------------------------------------------------------------------------

  group('NeoButton press style — sunken', () {
    test('resting is the identity of the fold', () {
      final style = styleOf(NeoButtonVariant.secondary);

      expect(style.withPress(0), same(style));
      expect(style.withPress(-1), same(style));
      expect(style.withPress(2), style.withPress(1));
    });

    test('a gradient fill and border darken stop by stop', () {
      final rest = styleOf(NeoButtonVariant.primary);
      final pressed = rest.withPress(1);
      final restFill = rest.fillGradient!;
      final pressedFill = pressed.fillGradient!;
      final restBorder = rest.borderGradient!;
      final pressedBorder = pressed.borderGradient!;

      expect(pressed.fillColor, isNull);
      for (var i = 0; i < restFill.colors.length; i++) {
        expect(
          pressedFill.colors[i].r,
          lessThan(restFill.colors[i].r),
          reason: 'fill stop $i should darken',
        );
      }
      // A darkened translucent stop reads as darker and slightly more opaque
      // — Porter-Duff compositing a black scrim over it, same technique
      // withHover already uses, just with a black rather than a colored one.
      expect(pressedBorder.colors[0].r, lessThan(restBorder.colors[0].r));
      expect(pressedBorder.colors[0].a, greaterThan(restBorder.colors[0].a));
    });

    test('a flat fill and solid border darken toward black', () {
      final rest = styleOf(NeoButtonVariant.secondary);
      final pressed = rest.withPress(1);

      expect(pressed.fillColor!.r, lessThan(rest.fillColor!.r));
      expect(pressed.borderColor!.r, lessThan(rest.borderColor!.r));
    });

    test('a variant with no fill or border gains a translucent scrim', () {
      final rest = styleOf(NeoButtonVariant.ghost);
      final pressed = rest.withPress(1);

      expect(rest.fillColor, isNull);
      expect(rest.borderColor, isNull);
      expect(pressed.fillColor, isNotNull);
      expect(pressed.fillColor!.a, greaterThan(0));
      expect(pressed.borderColor, isNull);
    });

    test('the highlight, the shadow, and the label stay put', () {
      final rest = styleOf(NeoButtonVariant.primary);
      final pressed = rest.withPress(1);

      expect(pressed.innerHighlightColor, rest.innerHighlightColor);
      expect(pressed.dropShadow, rest.dropShadow);
      expect(pressed.foregroundColor, rest.foregroundColor);
      expect(pressed.fontWeight, rest.fontWeight);
    });

    testWidgets('the default style scales and never darkens the surface', (
      tester,
    ) async {
      await tester.pumpWidget(testApp(NeoButton('Start', onPressed: () {})));
      final rest = surfaceOf(tester).gradient! as LinearGradient;

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(NeoButton)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      expect(scaleOf(tester), lessThan(1));
      final pressed = surfaceOf(tester).gradient! as LinearGradient;
      expect(pressed.colors, rest.colors);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('sunken never scales and darkens the surface instead', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          NeoButton(
            'Start',
            pressStyle: NeoButtonPressStyle.sunken,
            onPressed: () {},
          ),
        ),
      );
      final rest = surfaceOf(tester).gradient! as LinearGradient;
      expect(scaleOf(tester), 1);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(NeoButton)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 45));

      // Mid fade: darker than rest, not yet as dark as fully pressed. Stop 1
      // is the pure fill color, whose green channel is already zero, so the
      // red channel is what actually shows the darken.
      final mid = surfaceOf(tester).gradient! as LinearGradient;
      expect(mid.colors[1].r, lessThan(rest.colors[1].r));
      expect(scaleOf(tester), 1);

      await tester.pump(NeoButtonMetrics.pressColorDuration);
      final full = surfaceOf(tester).gradient! as LinearGradient;
      expect(full.colors[1].r, lessThanOrEqualTo(mid.colors[1].r));

      await gesture.up();
      await tester.pumpAndSettle();
      final settled = surfaceOf(tester).gradient! as LinearGradient;
      expect(settled.colors, rest.colors);
      expect(scaleOf(tester), 1);
    });

    testWidgets('a theme sets sunken for the whole family', (tester) async {
      await tester.pumpWidget(
        testApp(
          NeoButtonTheme(
            data: const NeoButtonThemeData(
              pressStyle: NeoButtonPressStyle.sunken,
            ),
            child: NeoButton('Start', onPressed: () {}),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(NeoButton)),
      );
      await tester.pumpAndSettle();

      expect(scaleOf(tester), 1);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a widget override wins over the theme', (tester) async {
      await tester.pumpWidget(
        testApp(
          NeoButtonTheme(
            data: const NeoButtonThemeData(
              pressStyle: NeoButtonPressStyle.sunken,
            ),
            child: NeoButton(
              'Start',
              pressStyle: NeoButtonPressStyle.scale,
              onPressed: () {},
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(NeoButton)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      expect(scaleOf(tester), lessThan(1));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a filled icon button darkens its card and ring on press', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          NeoIconButton(
            icon: LucideIcons.layers,
            semanticsLabel: 'Layers',
            filled: true,
            pressStyle: NeoButtonPressStyle.sunken,
            onPressed: () {},
          ),
        ),
      );
      final ShapeDecoration rest =
          tester.widget<DecoratedBox>(find.byKey(iconSurfaceKey)).decoration
              as ShapeDecoration;

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(NeoIconButton)),
      );
      await tester.pump();
      await tester.pump(NeoButtonMetrics.pressColorDuration);

      final ShapeDecoration pressed =
          tester.widget<DecoratedBox>(find.byKey(iconSurfaceKey)).decoration
              as ShapeDecoration;
      expect(pressed.color!.r, lessThan(rest.color!.r));
      expect(
        (pressed.shape as CircleBorder).side.color.r,
        lessThan((rest.shape as CircleBorder).side.color.r),
      );
      // The shadow is left alone.
      expect(pressed.shadows, rest.shadows);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a flat icon button grows a scrim disc even without hover', (
      tester,
    ) async {
      const hoverKey = ValueKey<String>('neo-icon-button-hover');
      await tester.pumpWidget(
        testApp(
          NeoIconButton(
            icon: LucideIcons.layers,
            semanticsLabel: 'Layers',
            pressStyle: NeoButtonPressStyle.sunken,
            onPressed: () {},
          ),
        ),
      );
      expect(find.byKey(hoverKey), findsNothing);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(NeoIconButton)),
      );
      await tester.pump();
      await tester.pump(NeoButtonMetrics.pressColorDuration);

      final disc =
          tester.widget<DecoratedBox>(find.byKey(hoverKey)).decoration
              as ShapeDecoration;
      expect(disc.color!.a, greaterThan(0));

      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.byKey(hoverKey), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  // I. NeoPressable and NeoSurface.
  // ---------------------------------------------------------------------------

  group('NeoPressable', () {
    const childKey = ValueKey<String>('pressable-child');

    double opacityOf(WidgetTester tester) => tester
        .widget<AnimatedOpacity>(
          find.descendant(
            of: find.byType(NeoPressable),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .opacity;

    testWidgets('taps through and scales its child on press', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        testApp(
          NeoPressable(
            onPressed: () => taps++,
            child: const SizedBox(key: childKey, width: 120, height: 44),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(childKey)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(scaleOf(tester), lessThan(1));

      await gesture.up();
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(opacityOf(tester), 1);
    });

    testWidgets('a disabled wrapper dims unless told not to', (tester) async {
      await tester.pumpWidget(
        testApp(
          const NeoPressable(
            onPressed: null,
            child: SizedBox(key: childKey, width: 120, height: 44),
          ),
        ),
      );
      expect(opacityOf(tester), NeoButtonThemeData().disabledOpacity);

      await tester.pumpWidget(
        testApp(
          const NeoPressable(
            onPressed: null,
            dimWhenDisabled: false,
            child: SizedBox(key: childKey, width: 120, height: 44),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(opacityOf(tester), 1);
    });
  });

  group('NeoSurface', () {
    ShapeDecoration decorationOf(WidgetTester tester) =>
        tester
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: find.byType(NeoSurface),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as ShapeDecoration;

    testWidgets('paints the style in a smooth rectangle', (tester) async {
      final style = styleOf(NeoButtonVariant.primary);
      await tester.pumpWidget(
        testApp(
          NeoSurface(
            style: style,
            borderRadius: 12,
            padding: const EdgeInsets.all(8),
            child: const SizedBox(width: 100, height: 40),
          ),
        ),
      );

      final decoration = decorationOf(tester);
      expect(decoration.gradient, style.fillGradient);
      expect(decoration.shadows, <BoxShadow>[style.dropShadow!]);
      final shape = decoration.shape as SmoothRectangleBorder;
      expect(shape.borderRadius.resolve(TextDirection.ltr).topLeft.x, 12);
      expect(tester.getSize(find.byType(NeoSurface)), const Size(116, 56));
    });

    testWidgets('a circle shape draws a disc', (tester) async {
      await tester.pumpWidget(
        testApp(
          NeoSurface(
            style: styleOf(NeoButtonVariant.primary),
            shape: BoxShape.circle,
            child: const SizedBox.square(dimension: 64),
          ),
        ),
      );

      expect(decorationOf(tester).shape, isA<CircleBorder>());
    });
  });
}
