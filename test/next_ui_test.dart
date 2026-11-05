import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_ui/next_ui.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('group preserves default spacing in $brightness', (
      tester,
    ) async {
      await tester.pumpWidget(
        CupertinoApp(
          theme: CupertinoThemeData(brightness: brightness),
          home: const Center(
            child: MyButtonGroup(
              children: [
                SizedBox(key: Key('first'), width: 34, height: 34),
                SizedBox(key: Key('second'), width: 34, height: 34),
              ],
            ),
          ),
        ),
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('second'))).dx -
            tester.getTopRight(find.byKey(const Key('first'))).dx,
        12,
      );
    });
  }

  testWidgets('explicit group spacing overrides inherited theme', (
    tester,
  ) async {
    final fallback = MyButtonThemeData.fallback;
    await tester.pumpWidget(
      CupertinoApp(
        home: MyButtonTheme(
          data: MyButtonThemeData(
            primary: fallback.primary,
            secondary: fallback.secondary,
            ghost: fallback.ghost,
            success: fallback.success,
            danger: fallback.danger,
            groupSpacing: 7,
          ),
          child: const Center(
            child: MyButtonGroup(
              spacing: 3,
              children: [
                SizedBox(key: Key('first'), width: 34, height: 34),
                SizedBox(key: Key('second'), width: 34, height: 34),
              ],
            ),
          ),
        ),
      ),
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('second'))).dx -
          tester.getTopRight(find.byKey(const Key('first'))).dx,
      3,
    );
  });
}
