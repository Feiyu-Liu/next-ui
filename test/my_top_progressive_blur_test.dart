import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_ui/next_ui.dart';
import 'package:progressive_blur/progressive_blur.dart';

void main() {
  testWidgets('uses the shared top fade and keeps its edge guard fixed', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(600, 400);
    addTearDown(tester.view.reset);
    final controller = ScrollController();
    addTearDown(controller.dispose);

    const blurKey = Key('top-blur');
    const guardKey = Key('my-ui-top-progressive-blur-edge-guard');
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: MyTopProgressiveBlur(
            key: blurKey,
            blurExtent: 124,
            edgeGuardColor: const Color(0xFFFAFAFA),
            child: CustomScrollView(
              controller: controller,
              slivers: const [
                SliverToBoxAdapter(child: SizedBox(height: 1200)),
              ],
            ),
          ),
        ),
      ),
    );

    final progressiveBlur = tester.widget<ProgressiveBlurWidget>(
      find.descendant(
        of: find.byKey(blurKey),
        matching: find.byType(ProgressiveBlurWidget),
      ),
    );
    final guard = find.byKey(guardKey);
    final initialGuardTop = tester.getTopLeft(guard);
    final blurHeight = tester.getSize(find.byKey(blurKey)).height;

    expect(progressiveBlur.sigma, 36);
    expect(progressiveBlur.blurTextureDimensions, 384);
    expect(progressiveBlur.tintColor, const Color(0x08FFFFFF));
    final values = progressiveBlur.linearGradientBlur!.values;
    final stops = progressiveBlur.linearGradientBlur!.stops;

    // Full blur at the top edge, fully clear at the end of the fade.
    expect(values.first, 1);
    expect(values.last, 0);
    expect(values.length, stops.length);
    for (var i = 0; i < values.length - 1; i++) {
      expect(
        values[i],
        greaterThan(values[i + 1]),
        reason: 'blur must decrease monotonically toward the fade end',
      );
      expect(stops[i], lessThan(stops[i + 1]));
    }

    // The ramp keeps a long, shallow toe so content entering the blur softens
    // gradually: the last tenth of the fade stays almost perfectly sharp.
    expect(values[values.length - 2], lessThan(0.02));
    expect(
      values[(values.length * 0.75).floor()],
      lessThan(0.25),
      reason: 'the lower quarter of the ramp must stay lightly blurred',
    );

    expect(stops.last, 124 / blurHeight);
    expect(tester.getTopLeft(guard), tester.getTopLeft(find.byKey(blurKey)));
    expect(tester.getSize(guard).height, 1);

    controller.jumpTo(160);
    await tester.pump();

    expect(tester.getTopLeft(guard), initialGuardTop);
  });
}
