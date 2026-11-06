import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_ui_example/main.dart';

void main() {
  testWidgets('theme toggle updates Cupertino and platform brightness', (
    tester,
  ) async {
    await tester.pumpWidget(const ShowcaseApp(enableBlur: false));
    expect(
      tester.widget<CupertinoApp>(find.byType(CupertinoApp)).theme!.brightness,
      Brightness.light,
    );
    await tester.tap(find.byKey(const Key('theme-toggle')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<CupertinoApp>(find.byType(CupertinoApp)).theme!.brightness,
      Brightness.dark,
    );
    expect(
      MediaQuery.platformBrightnessOf(
        tester.element(find.byKey(const Key('action-status'))),
      ),
      Brightness.dark,
    );
  });

  testWidgets('async button reports working and completion', (tester) async {
    await tester.pumpWidget(const ShowcaseApp(enableBlur: false));
    await tester.tap(find.byKey(const Key('async-action')));
    await tester.pump();
    expect(find.text('Working…'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Finished — ready again'), findsOneWidget);
  });

  testWidgets('menu selection closes its card and navigation selects a tab', (
    tester,
  ) async {
    await tester.pumpWidget(const ShowcaseApp(enableBlur: false));
    await tester.ensureVisible(find.byKey(const Key('menu-trigger')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('menu-trigger')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose blue'));
    await tester.pumpAndSettle();
    expect(find.text('Choose blue'), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const Key('nav-status')),
      250,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('studio-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    expect(find.text('Selected: Favorites'), findsOneWidget);
  });

  testWidgets('narrow window lays out without overflow', (tester) async {
    tester.view.physicalSize = const Size(380, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ShowcaseApp(enableBlur: false));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.drag(
      find.byKey(const Key('studio-scroll')),
      const Offset(0, -1100),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
