import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_ui/next_ui.dart';

void main() {
  testWidgets('compact capsule has concentric ends in both positions', (
    tester,
  ) async {
    for (final selected in [0, 1]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 124,
              child: NeumorphicNavBar(
                height: 42,
                padding: const EdgeInsets.all(3),
                thumbInset: 4,
                smoothness: 0,
                selectedIndex: selected,
                onItemSelected: (_) {},
                iconSize: 14,
                labelFontSize: 0,
                labelSpacing: 0,
                items: const [
                  NeumorphicNavItem(label: 'Preview', icon: Icons.visibility),
                  NeumorphicNavItem(label: 'Settings', icon: Icons.settings),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final track = tester.getRect(
        find.byKey(const Key('neumorphic_nav_track')),
      );
      final thumbFinder = find.descendant(
        of: find.byKey(const Key('neumorphic_nav_thumb_visual')),
        matching: find.byType(AnimatedContainer),
      );
      final thumb = tester.getRect(thumbFinder);
      expect(thumb.height, 28);
      expect(thumb.top - track.top, 4);
      expect(track.bottom - thumb.bottom, 4);
      // The centers of the end semicircles must coincide on either side.
      expect(
        selected == 0
            ? thumb.left + thumb.height / 2
            : thumb.right - thumb.height / 2,
        selected == 0
            ? track.left + track.height / 2
            : track.right - track.height / 2,
      );
      final decoration =
          tester.widget<AnimatedContainer>(thumbFinder).decoration!
              as ShapeDecoration;
      final path = decoration.shape.getOuterPath(Offset.zero & thumb.size);
      final expected = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Offset.zero & thumb.size,
            const Radius.circular(14),
          ),
        );
      expect(
        Path.combine(PathOperation.xor, path, expected).getBounds().isEmpty,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('navigation defaults follow platform brightness', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 300,
            child: NeumorphicNavBar(
              selectedIndex: 0,
              onItemSelected: (_) {},
              items: const [
                NeumorphicNavItem(label: 'Preview', icon: Icons.visibility),
                NeumorphicNavItem(label: 'Settings', icon: Icons.settings),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final track = tester.widget<Container>(
      find.byKey(const Key('neumorphic_nav_track')),
    );
    expect(
      (track.decoration! as ShapeDecoration).color,
      const Color(0xFF1F1F21),
    );
    final thumb = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byKey(const Key('neumorphic_nav_thumb_visual')),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect(
      (thumb.decoration! as ShapeDecoration).color,
      const Color(0xFFF2F2F3),
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.visibility)).color,
      const Color(0xFF161618),
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.settings)).color,
      const Color(0xFF8D8D94),
    );
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    final light = tester.widget<Container>(
      find.byKey(const Key('neumorphic_nav_track')),
    );
    expect(
      (light.decoration! as ShapeDecoration).color,
      const Color(0xFFF2F3F5),
    );
  });
}
