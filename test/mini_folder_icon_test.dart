import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_ui/next_ui.dart';

void main() {
  testWidgets('MiniFolderIcon renders at the configured size', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: MiniFolderIcon(size: 24)),
      ),
    );

    expect(find.byType(MiniFolderIcon), findsOneWidget);
    final iconSize = tester.getSize(find.byType(MiniFolderIcon));
    expect(iconSize.width, 24);
    expect(iconSize.height, closeTo(18.72, 0.001));
  });

  testWidgets('paper and shadow follow platform brightness', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(platformBrightness: Brightness.dark),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: MiniFolderIcon(),
        ),
      ),
    );
    final paper = tester.widget<Container>(
      find.descendant(
        of: find.byType(MiniFolderIcon),
        matching: find.byType(Container),
      ),
    );
    final decoration = paper.decoration! as BoxDecoration;
    expect(decoration.color!.toARGB32(), 0xFF444448);
    expect(decoration.boxShadow!.single.color.a, closeTo(0.24, 0.01));
  });
}
