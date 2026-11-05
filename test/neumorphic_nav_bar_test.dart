import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_ui/next_ui.dart';

void main() {
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
