import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_ui/next_ui.dart';
import 'package:smooth_corner/smooth_corner.dart';

void main() {
  Future<void> pumpTag(WidgetTester tester, {required Widget child}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  ShapeDecoration decorationOf(WidgetTester tester, Finder finder) {
    return tester.widget<Container>(finder).decoration! as ShapeDecoration;
  }

  testWidgets('CapsuleTag exposes its key', (WidgetTester tester) async {
    await pumpTag(
      tester,
      child: const CapsuleTag('Hello', key: ValueKey<String>('my-tag')),
    );

    expect(find.byKey(const ValueKey<String>('my-tag')), findsOneWidget);
  });

  group('cute variant', () {
    testWidgets('renders its text without an icon by default', (
      WidgetTester tester,
    ) async {
      await pumpTag(tester, child: const CapsuleTag('128 人'));

      expect(find.text('128 人'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('renders a leading icon when provided', (
      WidgetTester tester,
    ) async {
      await pumpTag(
        tester,
        child: const CapsuleTag('128 人', icon: CupertinoIcons.heart_fill),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, CupertinoIcons.heart_fill);
      expect(icon.size, 12);
    });

    testWidgets('paints an opaque capsule shape', (WidgetTester tester) async {
      await pumpTag(tester, child: const CapsuleTag('BETA'));

      final decoration = decorationOf(
        tester,
        find.ancestor(of: find.text('BETA'), matching: find.byType(Container)),
      );
      final shape = decoration.shape as SmoothRectangleBorder;

      expect(decoration.color, isNotNull);
      expect(shape.borderRadius.resolve(TextDirection.ltr).topLeft.x, 999);
      expect(tester.getSize(find.byType(CapsuleTag)).height, 24);
    });

    testWidgets('accepts a wider horizontal inset', (
      WidgetTester tester,
    ) async {
      await pumpTag(
        tester,
        child: const CapsuleTag('BETA', horizontalPadding: 8),
      );

      final container = tester.widget<Container>(
        find.ancestor(of: find.text('BETA'), matching: find.byType(Container)),
      );
      expect(container.padding, const EdgeInsets.symmetric(horizontal: 8));
    });
  });

  group('keycap variant', () {
    testWidgets('re-derives its face and text color from a custom color', (
      WidgetTester tester,
    ) async {
      await pumpTag(
        tester,
        child: const CapsuleTag(
          'NEW',
          variant: CapsuleTagVariant.keycap,
          color: CupertinoColors.systemGreen,
        ),
      );

      final defaultText = tester.widget<Text>(find.text('NEW'));
      expect(defaultText.style!.color, isNotNull);

      await pumpTag(
        tester,
        child: const CapsuleTag(
          'NEW',
          variant: CapsuleTagVariant.keycap,
          color: CupertinoColors.systemOrange,
        ),
      );

      final overriddenText = tester.widget<Text>(find.text('NEW'));
      expect(overriddenText.style!.color, isNot(defaultText.style!.color));
    });

    testWidgets('shows an optional leading icon', (WidgetTester tester) async {
      await pumpTag(
        tester,
        child: const CapsuleTag(
          'BETA',
          variant: CapsuleTagVariant.keycap,
          icon: CupertinoIcons.star_fill,
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, CupertinoIcons.star_fill);
    });
  });

  group('pro variant', () {
    testWidgets('fills with the default accent and bold white text', (
      WidgetTester tester,
    ) async {
      await pumpTag(
        tester,
        child: const CapsuleTag('PRO', variant: CapsuleTagVariant.pro),
      );

      final decoration =
          tester.widget<DecoratedBox>(find.byType(DecoratedBox)).decoration
              as ShapeDecoration;
      final text = tester.widget<Text>(find.text('PRO'));

      expect(decoration.color, const Color(0xFFFF00C8));
      expect(text.style!.fontWeight, FontWeight.w700);
      expect(text.style!.color, CupertinoColors.white);
    });

    testWidgets('honors a caller-supplied accent color', (
      WidgetTester tester,
    ) async {
      await pumpTag(
        tester,
        child: const CapsuleTag(
          'PRO',
          variant: CapsuleTagVariant.pro,
          color: CupertinoColors.systemPink,
        ),
      );

      final decoration =
          tester.widget<DecoratedBox>(find.byType(DecoratedBox)).decoration
              as ShapeDecoration;

      expect(decoration.color, CupertinoColors.systemPink);
    });
  });
}
