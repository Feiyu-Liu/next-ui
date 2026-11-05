import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_ui/next_ui.dart';
import 'package:smooth_corner/smooth_corner.dart';

void main() {
  const instantStyle = MorphingMenuButtonStyle(
    duration: Duration(milliseconds: 200),
    reverseDuration: Duration(milliseconds: 100),
    openCurve: Curves.linear,
    closeCurve: Curves.linear,
  );

  Widget testApp(
    Widget child, {
    Size size = const Size(800, 600),
    bool disableAnimations = false,
    Brightness brightness = Brightness.light,
  }) {
    return MediaQuery(
      data: MediaQueryData(size: size, disableAnimations: disableAnimations),
      child: CupertinoApp(
        theme: CupertinoThemeData(brightness: brightness),
        home: CupertinoPageScaffold(child: child),
      ),
    );
  }

  Future<void> setSurfaceSize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  MorphingMenuButton menu({
    MorphingMenuContentBuilder? contentBuilder,
    bool enabled = true,
    bool enableDragResize = true,
    String? label,
    String? semanticsLabel = 'Open commands',
    double? expandedWidth,
    double? expandedHeight,
    double? maxExpandedHeight,
    MorphingMenuAlignment alignment = MorphingMenuAlignment.start,
    MorphingMenuDirection direction = MorphingMenuDirection.auto,
    ValueChanged<bool>? onExpandedChanged,
    VoidCallback? onTriggerPressed,
    MorphingMenuButtonController? controller,
    MorphingMenuButtonStyle? style = instantStyle,
    Widget? leading,
    String? tooltip,
  }) {
    return MorphingMenuButton(
      icon: leading == null ? CupertinoIcons.command : null,
      leading: leading,
      label: label,
      semanticsLabel: semanticsLabel,
      tooltip: tooltip,
      enabled: enabled,
      enableDragResize: enableDragResize,
      expandedWidth: expandedWidth,
      expandedHeight: expandedHeight,
      maxExpandedHeight: maxExpandedHeight,
      alignment: alignment,
      direction: direction,
      onExpandedChanged: onExpandedChanged,
      onTriggerPressed: onTriggerPressed,
      controller: controller,
      style: style,
      contentBuilder:
          contentBuilder ??
          (BuildContext context, VoidCallback close) => CupertinoButton(
            key: const ValueKey<String>('menu-action'),
            onPressed: close,
            child: const Text('Run command'),
          ),
    );
  }

  Finder overlaySurface() =>
      find.byKey(const ValueKey<String>('morphing-menu-button-surface'));

  testWidgets('renders icon-only and labeled triggers at stable heights', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              menu(),
              const SizedBox(width: 12),
              menu(label: 'Commands', semanticsLabel: null),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(MorphingMenuButton), findsNWidgets(2));
    for (final Element element in find.byType(MorphingMenuButton).evaluate()) {
      expect(tester.getSize(find.byWidget(element.widget)).height, 38);
    }
    expect(find.text('Commands'), findsOneWidget);
  });

  testWidgets('accepts custom leading content and a desktop tooltip', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        Center(
          child: menu(
            leading: const SizedBox(
              key: ValueKey<String>('custom-leading'),
              width: 16,
              height: 16,
            ),
            tooltip: 'Choose an agent',
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('custom-leading')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('morphing-menu-button-trigger')),
    );
    await tester.pump();
    expect(overlaySurface(), findsOneWidget);
    await tester.tapAt(const Offset(8, 8));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    await mouse.moveTo(tester.getCenter(find.byType(MorphingMenuButton)));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Choose an agent'), findsOneWidget);
  });

  testWidgets('a tight slot is filled by the surface, not centred inside it', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        Center(
          child: SizedBox(
            width: 320,
            child: menu(label: 'All', expandedWidth: 400, expandedHeight: 200),
          ),
        ),
      ),
    );

    final Finder painted = find.byKey(
      const ValueKey<String>('morphing-menu-button-trigger-surface'),
    );
    // The focus ring, the tap target and the morph's starting rect all belong
    // to the button's box, so the surface has to fill that box rather than
    // shrink-wrap its label and sit centred in a wider slot.
    final Rect collapsed = tester.getRect(painted);
    expect(collapsed, tester.getRect(find.byType(MorphingMenuButton)));
    expect(collapsed.width, 320);

    await tester.tap(painted);
    await tester.pump();
    // No un-animated jump on open: the first frame of the card is exactly the
    // surface the collapsed button was painting.
    expect(tester.getRect(overlaySurface()), collapsed);

    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.getRect(overlaySurface()).width, 400);

    await tester.tapAt(const Offset(8, 8));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    // And none on close: the trigger comes back where the card left off.
    expect(overlaySurface(), findsNothing);
    expect(tester.getRect(painted), collapsed);
  });

  testWidgets('an unconstrained button still shrink-wraps to its content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(testApp(Center(child: menu(label: 'All'))));

    final Rect box = tester.getRect(find.byType(MorphingMenuButton));
    final Rect painted = tester.getRect(
      find.byKey(
        const ValueKey<String>('morphing-menu-button-trigger-surface'),
      ),
    );
    // Filling a slot is a floor, never a ceiling: with nothing imposed the
    // button sizes to its label as it always has.
    expect(painted, box);
    expect(box.width, lessThan(320));
  });

  testWidgets('builds content lazily and reports logical state once', (
    WidgetTester tester,
  ) async {
    int builds = 0;
    final changes = <bool>[];
    await tester.pumpWidget(
      testApp(
        Center(
          child: menu(
            onExpandedChanged: changes.add,
            contentBuilder: (BuildContext context, VoidCallback close) {
              builds++;
              return const Text('Lazy content');
            },
          ),
        ),
      ),
    );

    expect(builds, 0);
    await tester.tap(
      find.byKey(const ValueKey<String>('morphing-menu-button-trigger')),
    );
    await tester.pump();
    expect(builds, 1);
    expect(changes, <bool>[true]);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 201));
    expect(find.text('Lazy content'), findsOneWidget);

    await tester.tapAt(const Offset(8, 8));
    await tester.pump();
    expect(changes, <bool>[true, false]);
    expect(find.text('Lazy content'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(find.text('Lazy content'), findsNothing);
  });

  testWidgets('morphs in the overlay without moving its layout anchor', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: menu(expandedWidth: 320, expandedHeight: 220),
          ),
        ),
      ),
    );
    final trigger = find.byKey(
      const ValueKey<String>('morphing-menu-button-trigger'),
    );
    final anchorRect = tester.getRect(trigger);

    await tester.tap(trigger);
    await tester.pump();
    expect(tester.getRect(overlaySurface()).size, anchorRect.size);

    await tester.pump(const Duration(milliseconds: 100));
    final midpoint = tester.getRect(overlaySurface());
    expect(midpoint.width, inExclusiveRange(anchorRect.width, 320.0));
    expect(midpoint.height, inExclusiveRange(anchorRect.height, 220.0));
    expect(tester.getRect(find.byType(MorphingMenuButton)), anchorRect);

    await tester.pump(const Duration(milliseconds: 100));
    final expanded = tester.getRect(overlaySurface());
    expect(expanded.width, 320);
    expect(expanded.height, 220);
    expect(expanded.bottom, closeTo(anchorRect.top - 8, 0.01));
  });

  testWidgets('elastic open overshoots the target rect before settling', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: menu(style: null, expandedWidth: 320, expandedHeight: 220),
          ),
        ),
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('morphing-menu-button-trigger')),
    );
    await tester.pump();

    // ElasticOutCurve(1.2) peaks at 60% of the run.
    await tester.pump(const Duration(milliseconds: 420));
    final peak = tester.getRect(overlaySurface());
    expect(peak.width, greaterThan(320));
    expect(peak.height, greaterThan(220));

    await tester.pump(const Duration(milliseconds: 280));
    final settled = tester.getRect(overlaySurface());
    expect(settled.width, closeTo(320, 0.01));
    expect(settled.height, closeTo(220, 0.01));
  });

  testWidgets('closing plays the elastic curve forward over its own duration', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: menu(style: null, expandedWidth: 320, expandedHeight: 220),
          ),
        ),
      ),
    );
    final trigger = find.byKey(
      const ValueKey<String>('morphing-menu-button-trigger'),
    );
    final anchor = tester.getRect(trigger);
    await tester.tap(trigger);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    await tester.tap(find.byKey(const ValueKey<String>('menu-action')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 420));

    // Still collapsing at 420ms, and undershooting past the anchor rather than
    // easing into it — the same curve the reference project uses both ways.
    final undershoot = tester.getRect(overlaySurface());
    expect(undershoot.width, lessThan(anchor.width));
    expect(undershoot.height, lessThan(anchor.height));

    await tester.pump(const Duration(milliseconds: 280));
    await tester.pump();
    expect(overlaySurface(), findsNothing);
  });

  testWidgets('a tap mid-close reverses the card back open', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: menu(expandedWidth: 320, expandedHeight: 220),
          ),
        ),
      ),
    );
    final trigger = find.byKey(
      const ValueKey<String>('morphing-menu-button-trigger'),
    );
    final interrupt = find.byKey(
      const ValueKey<String>('morphing-menu-button-interrupt'),
    );

    await tester.tap(trigger);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.getRect(overlaySurface()).width, 320);
    // Settled open: the catcher is gone so the live content owns every tap.
    expect(interrupt, findsNothing);

    // Dismiss from outside, then catch the collapse half way down.
    await tester.tapAt(const Offset(8, 8));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final midClose = tester.getRect(overlaySurface()).width;
    expect(midClose, lessThan(320));
    expect(interrupt, findsOneWidget);

    await tester.tap(interrupt);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    // Reversed in place: already growing back out from where the close was.
    expect(tester.getRect(overlaySurface()).width, greaterThan(midClose));

    await tester.pump(const Duration(milliseconds: 200));
    expect(overlaySurface(), findsOneWidget);
    expect(tester.getRect(overlaySurface()).width, 320);
    expect(interrupt, findsNothing);
  });

  testWidgets('an interrupted close reopens with the latest content', (
    WidgetTester tester,
  ) async {
    var selected = 'A';

    await tester.pumpWidget(
      testApp(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) => Center(
            child: menu(
              label: selected,
              semanticsLabel: null,
              expandedWidth: 320,
              expandedHeight: 220,
              contentBuilder: (BuildContext context, VoidCallback close) =>
                  Column(
                    children: <Widget>[
                      Text(
                        selected,
                        key: const ValueKey<String>('panel-selection'),
                      ),
                      CupertinoButton(
                        key: const ValueKey<String>('select-b'),
                        onPressed: () {
                          setState(() => selected = 'B');
                          close();
                        },
                        child: const Text('Select B'),
                      ),
                    ],
                  ),
            ),
          ),
        ),
      ),
    );

    final trigger = find.byKey(
      const ValueKey<String>('morphing-menu-button-trigger'),
    );
    final interrupt = find.byKey(
      const ValueKey<String>('morphing-menu-button-interrupt'),
    );
    final panelSelection = find.byKey(
      const ValueKey<String>('panel-selection'),
    );

    await tester.tap(trigger);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 201));
    expect(tester.widget<Text>(panelSelection).data, 'A');

    await tester.tap(find.byKey(const ValueKey<String>('select-b')));
    await tester.pump();
    expect(
      tester.widget<MorphingMenuButton>(find.byType(MorphingMenuButton)).label,
      'B',
    );

    await tester.pump(const Duration(milliseconds: 40));
    expect(interrupt, findsOneWidget);
    await tester.tap(interrupt);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 201));

    expect(tester.widget<Text>(panelSelection).data, 'B');
  });

  testWidgets('a tap mid-open drops the card back onto the trigger', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: menu(expandedWidth: 320, expandedHeight: 220),
          ),
        ),
      ),
    );
    final trigger = find.byKey(
      const ValueKey<String>('morphing-menu-button-trigger'),
    );
    final interrupt = find.byKey(
      const ValueKey<String>('morphing-menu-button-interrupt'),
    );
    final anchor = tester.getRect(trigger);

    await tester.tap(trigger);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final midOpen = tester.getRect(overlaySurface()).width;
    expect(midOpen, greaterThan(anchor.width));
    expect(midOpen, lessThan(320));
    expect(interrupt, findsOneWidget);

    await tester.tap(interrupt);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 140));
    await tester.pump();
    // Interrupting an open reverses it straight back to nothing.
    expect(overlaySurface(), findsNothing);
  });

  testWidgets('content grows with the card without reflowing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: menu(
              style: null,
              expandedWidth: 320,
              expandedHeight: 220,
              contentBuilder: (BuildContext context, VoidCallback close) =>
                  const Row(
                    children: <Widget>[
                      SizedBox(
                        key: ValueKey<String>('wide-content'),
                        width: 288,
                        height: 40,
                      ),
                    ],
                  ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('morphing-menu-button-trigger')),
    );

    const content = ValueKey<String>('wide-content');
    var previousPainted = 0.0;
    var sampled = 0;
    for (var elapsed = 0; elapsed < 200; elapsed += 20) {
      await tester.pump(const Duration(milliseconds: 20));
      expect(tester.takeException(), isNull);

      // A 288px child only fits the fully expanded card, so it must always be
      // laid out at its destination size...
      expect(tester.getSize(find.byKey(content)).width, 288);

      // ...while what is painted tracks the card as it grows.
      final painted = tester.getRect(find.byKey(content)).width;
      final card = tester.getRect(overlaySurface()).width;
      expect(painted, closeTo(288 * card / 320, 0.01));
      expect(painted, greaterThan(previousPainted));
      previousPainted = painted;
      sampled++;
    }
    expect(sampled, greaterThan(4));

    await tester.pump(const Duration(milliseconds: 520));
    expect(tester.getRect(find.byKey(content)).width, closeTo(288, 0.01));
  });

  testWidgets('content close callback reverses and restores the trigger', (
    WidgetTester tester,
  ) async {
    final changes = <bool>[];
    await tester.pumpWidget(
      testApp(Center(child: menu(onExpandedChanged: changes.add))),
    );

    final trigger = find.byKey(
      const ValueKey<String>('morphing-menu-button-trigger'),
    );
    await tester.tap(trigger);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 201));
    await tester.tap(find.byKey(const ValueKey<String>('menu-action')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(changes, <bool>[true, false]);
    expect(overlaySurface(), findsNothing);
    expect(trigger, findsOneWidget);
    expect(
      tester.widget<CupertinoButton>(trigger).focusNode!.hasFocus,
      isFalse,
    );
  });

  testWidgets('pointer opening does not highlight the first panel control', (
    WidgetTester tester,
  ) async {
    final actionFocus = FocusNode();
    addTearDown(actionFocus.dispose);
    await tester.pumpWidget(
      testApp(
        Center(
          child: menu(
            contentBuilder: (BuildContext context, VoidCallback close) =>
                CupertinoButton(
                  key: const ValueKey<String>('menu-action'),
                  focusNode: actionFocus,
                  onPressed: close,
                  child: const Text('Run command'),
                ),
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('morphing-menu-button-trigger')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 201));
    await tester.pump();

    expect(actionFocus.hasFocus, isFalse);
  });

  testWidgets('keyboard opening moves focus into the expanded card', (
    WidgetTester tester,
  ) async {
    final actionFocus = FocusNode();
    addTearDown(actionFocus.dispose);
    await tester.pumpWidget(
      testApp(
        Center(
          child: menu(
            contentBuilder: (BuildContext context, VoidCallback close) =>
                CupertinoButton(
                  key: const ValueKey<String>('menu-action'),
                  focusNode: actionFocus,
                  onPressed: close,
                  child: const Text('Run command'),
                ),
          ),
        ),
      ),
    );

    final trigger = find.byKey(
      const ValueKey<String>('morphing-menu-button-trigger'),
    );
    final triggerFocus = tester.widget<CupertinoButton>(trigger).focusNode!;
    triggerFocus.requestFocus();
    await tester.pump();
    expect(triggerFocus.hasPrimaryFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(triggerFocus.hasFocus, isFalse);

    await tester.pump(const Duration(milliseconds: 201));
    await tester.pump();
    expect(triggerFocus.hasFocus, isFalse);
    expect(actionFocus.hasPrimaryFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 101));
    await tester.pump();
    expect(triggerFocus.hasPrimaryFocus, isTrue);
  });

  testWidgets('Escape closes the expanded card', (WidgetTester tester) async {
    await tester.pumpWidget(testApp(Center(child: menu())));
    await tester.tap(
      find.byKey(const ValueKey<String>('morphing-menu-button-trigger')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 201));

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(overlaySurface(), findsNothing);
  });

  testWidgets('Escape closes while the card is still opening', (
    WidgetTester tester,
  ) async {
    final changes = <bool>[];
    await tester.pumpWidget(
      testApp(Center(child: menu(onExpandedChanged: changes.add))),
    );
    final trigger = find.byKey(
      const ValueKey<String>('morphing-menu-button-trigger'),
    );
    tester.widget<CupertinoButton>(trigger).focusNode!.requestFocus();
    await tester.pump();
    await tester.tap(trigger);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(changes, <bool>[true, false]);
    expect(overlaySurface(), findsNothing);
  });

  testWidgets('outside dismissal preserves focus acquired elsewhere', (
    WidgetTester tester,
  ) async {
    final fieldFocus = FocusNode();
    addTearDown(fieldFocus.dispose);
    await tester.pumpWidget(
      testApp(
        Column(
          children: <Widget>[
            menu(),
            CupertinoTextField(
              key: const ValueKey<String>('outside-field'),
              focusNode: fieldFocus,
            ),
          ],
        ),
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('morphing-menu-button-trigger')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 201));

    fieldFocus.requestFocus();
    await tester.tapAt(const Offset(790, 590));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(fieldFocus.hasFocus, isTrue);
  });

  testWidgets('disabled trigger remains inert', (WidgetTester tester) async {
    await tester.pumpWidget(testApp(Center(child: menu(enabled: false))));
    await tester.tap(
      find.byKey(const ValueKey<String>('morphing-menu-button-trigger')),
    );
    await tester.pump();

    expect(overlaySurface(), findsNothing);
    expect(find.byKey(const ValueKey<String>('menu-action')), findsNothing);
  });

  testWidgets('a press handler replaces opening on press', (
    WidgetTester tester,
  ) async {
    int presses = 0;
    await tester.pumpWidget(
      testApp(Center(child: menu(onTriggerPressed: () => presses++))),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('morphing-menu-button-trigger')),
    );
    await tester.pump(const Duration(milliseconds: 201));

    expect(presses, 1);
    expect(overlaySurface(), findsNothing);
  });

  testWidgets('a controller opens and closes the card', (
    WidgetTester tester,
  ) async {
    final controller = MorphingMenuButtonController();
    final changes = <bool>[];
    await tester.pumpWidget(
      testApp(
        Center(
          child: menu(controller: controller, onExpandedChanged: changes.add),
        ),
      ),
    );

    expect(controller.isAttached, isTrue);
    expect(controller.isExpanded, isFalse);

    controller.open();
    await tester.pump(const Duration(milliseconds: 201));
    expect(controller.isExpanded, isTrue);
    expect(changes, <bool>[true]);
    expect(overlaySurface(), findsOneWidget);

    controller.close();
    await tester.pump();
    expect(controller.isExpanded, isFalse);
    expect(changes, <bool>[true, false]);
    await tester.pump(const Duration(milliseconds: 101));
    await tester.pump();
    expect(overlaySurface(), findsNothing);
  });

  testWidgets('a press handler opens through its controller', (
    WidgetTester tester,
  ) async {
    final controller = MorphingMenuButtonController();
    bool direct = false;
    await tester.pumpWidget(
      testApp(
        Center(
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) => menu(
              controller: controller,
              onTriggerPressed: () {
                if (direct) {
                  setState(() => direct = false);
                  return;
                }
                controller.open();
              },
            ),
          ),
        ),
      ),
    );
    final trigger = find.byKey(
      const ValueKey<String>('morphing-menu-button-trigger'),
    );

    // The direct-action state consumes the press without morphing.
    direct = true;
    await tester.tap(trigger);
    await tester.pump(const Duration(milliseconds: 201));
    expect(overlaySurface(), findsNothing);
    expect(direct, isFalse);

    // The state that needs the card opens it explicitly.
    await tester.tap(trigger);
    await tester.pump(const Duration(milliseconds: 201));
    expect(overlaySurface(), findsOneWidget);
    expect(controller.isExpanded, isTrue);
  });

  testWidgets('a controller cannot open a disabled trigger', (
    WidgetTester tester,
  ) async {
    final controller = MorphingMenuButtonController();
    await tester.pumpWidget(
      testApp(Center(child: menu(controller: controller, enabled: false))),
    );

    controller.open();
    await tester.pump(const Duration(milliseconds: 201));

    expect(controller.isExpanded, isFalse);
    expect(overlaySurface(), findsNothing);
  });

  testWidgets('a controller follows the button it is moved to', (
    WidgetTester tester,
  ) async {
    final controller = MorphingMenuButtonController();
    await tester.pumpWidget(
      testApp(Center(child: menu(controller: controller))),
    );
    expect(controller.isAttached, isTrue);

    // Rebuilding without the controller releases it, so handing it to another
    // button never trips the single-attachment assertion.
    await tester.pumpWidget(testApp(Center(child: menu())));
    expect(controller.isAttached, isFalse);

    await tester.pumpWidget(
      testApp(Center(child: menu(controller: controller))),
    );
    controller.open();
    await tester.pump(const Duration(milliseconds: 201));
    expect(overlaySurface(), findsOneWidget);
  });

  testWidgets('auto keeps the card above and clamps it to the viewport', (
    WidgetTester tester,
  ) async {
    await setSurfaceSize(tester, const Size(320, 420));
    await tester.pumpWidget(
      testApp(
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: menu(expandedWidth: 600, expandedHeight: 500),
          ),
        ),
        size: const Size(320, 420),
      ),
    );
    final trigger = find.byKey(
      const ValueKey<String>('morphing-menu-button-trigger'),
    );
    final anchor = tester.getRect(trigger);
    await tester.tap(trigger);
    await tester.pump(const Duration(milliseconds: 201));

    final card = tester.getRect(overlaySurface());
    expect(card.left, greaterThanOrEqualTo(4));
    expect(card.right, lessThanOrEqualTo(316));
    expect(card.top, greaterThanOrEqualTo(4));
    expect(card.bottom, lessThanOrEqualTo(416));
    if (anchor.top - 8 >= 500) {
      expect(card.bottom, closeTo(anchor.top - 8, 0.01));
    }
  });

  testWidgets('directional start alignment mirrors in RTL', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        Directionality(
          textDirection: TextDirection.rtl,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: menu(expandedWidth: 260),
            ),
          ),
        ),
      ),
    );
    final trigger = find.byKey(
      const ValueKey<String>('morphing-menu-button-trigger'),
    );
    final anchor = tester.getRect(trigger);
    await tester.tap(trigger);
    await tester.pump(const Duration(milliseconds: 201));

    expect(tester.getRect(overlaySurface()).right, closeTo(anchor.right, 0.01));
  });

  // Geometry below assumes the default 800x600 test view with the default
  // buttonHeight 38, gap 8, and viewportPadding 12.

  Future<Rect> openAt(
    WidgetTester tester,
    AlignmentGeometry alignment,
    EdgeInsets padding,
    MorphingMenuButton button,
  ) async {
    await tester.pumpWidget(
      testApp(
        Align(
          alignment: alignment,
          child: Padding(padding: padding, child: button),
        ),
      ),
    );
    final anchor = tester.getRect(
      find.byKey(const ValueKey<String>('morphing-menu-button-trigger')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('morphing-menu-button-trigger')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 201));
    return anchor;
  }

  testWidgets('explicit down opens below the anchor', (
    WidgetTester tester,
  ) async {
    final anchor = await openAt(
      tester,
      Alignment.center,
      EdgeInsets.zero,
      menu(
        direction: MorphingMenuDirection.down,
        expandedWidth: 320,
        expandedHeight: 220,
      ),
    );

    final card = tester.getRect(overlaySurface());
    expect(card.top, closeTo(anchor.bottom + 8, 0.01));
    expect(card.height, closeTo(220, 0.01));
    expect(card.left, closeTo(anchor.left, 0.01));
  });

  testWidgets('auto flips below when the card cannot fit above', (
    WidgetTester tester,
  ) async {
    final anchor = await openAt(
      tester,
      Alignment.topLeft,
      const EdgeInsets.all(8),
      menu(expandedHeight: 220),
    );

    final card = tester.getRect(overlaySurface());
    expect(card.top, closeTo(anchor.bottom + 8, 0.01));
    expect(card.height, closeTo(220, 0.01));
    expect(card.bottom, lessThanOrEqualTo(588));
  });

  testWidgets('auto stays above when the requested height fits above', (
    WidgetTester tester,
  ) async {
    final anchor = await openAt(
      tester,
      Alignment.bottomLeft,
      const EdgeInsets.all(40),
      menu(expandedHeight: 220),
    );

    expect(
      tester.getRect(overlaySurface()).bottom,
      closeTo(anchor.top - 8, 0.01),
    );
  });

  testWidgets('auto prefers up when both sides offer the same room', (
    WidgetTester tester,
  ) async {
    // A centered trigger leaves 261px on each side, and 280 fits neither, so
    // only the tie-break keeps this card above its trigger.
    final anchor = await openAt(
      tester,
      Alignment.center,
      EdgeInsets.zero,
      menu(expandedHeight: 280),
    );

    final card = tester.getRect(overlaySurface());
    expect(card.bottom, closeTo(anchor.top - 8, 0.01));
    expect(card.height, closeTo(261, 0.01));
  });

  testWidgets('explicit up compresses instead of flipping below', (
    WidgetTester tester,
  ) async {
    final anchor = await openAt(
      tester,
      Alignment.topLeft,
      const EdgeInsets.only(top: 120),
      menu(direction: MorphingMenuDirection.up, expandedHeight: 220),
    );

    final card = tester.getRect(overlaySurface());
    expect(card.height, closeTo(100, 0.01));
    expect(card.bottom, closeTo(anchor.top - 8, 0.01));
    expect(card.top, closeTo(12, 0.01));
    // The card never crossed to the roomier side below the trigger.
    expect(card.top, lessThan(anchor.top));
  });

  testWidgets('explicit down compresses instead of flipping above', (
    WidgetTester tester,
  ) async {
    final anchor = await openAt(
      tester,
      Alignment.bottomLeft,
      const EdgeInsets.only(bottom: 100),
      menu(direction: MorphingMenuDirection.down, expandedHeight: 220),
    );

    final card = tester.getRect(overlaySurface());
    expect(card.height, closeTo(80, 0.01));
    expect(card.top, closeTo(anchor.bottom + 8, 0.01));
    expect(card.bottom, closeTo(588, 0.01));
    expect(card.top, greaterThan(anchor.top));
  });

  testWidgets('a side with no room keeps the collapsed height on screen', (
    WidgetTester tester,
  ) async {
    await openAt(
      tester,
      Alignment.topLeft,
      EdgeInsets.zero,
      menu(direction: MorphingMenuDirection.up, expandedHeight: 220),
    );

    final card = tester.getRect(overlaySurface());
    expect(card.height, closeTo(38, 0.01));
    expect(card.top, closeTo(12, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('downward drag grows a downward card from its fixed top', (
    WidgetTester tester,
  ) async {
    final anchor = await openAt(
      tester,
      Alignment.topLeft,
      const EdgeInsets.all(8),
      menu(
        direction: MorphingMenuDirection.down,
        expandedHeight: 180,
        maxExpandedHeight: 300,
      ),
    );

    await tester.drag(
      find.byKey(const ValueKey<String>('morphing-menu-button-drag-handle')),
      const Offset(0, 100),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));

    final card = tester.getRect(overlaySurface());
    expect(card.height, closeTo(300, 0.01));
    expect(card.top, closeTo(anchor.bottom + 8, 0.01));
  });

  testWidgets('upward drag closes a downward card', (
    WidgetTester tester,
  ) async {
    final changes = <bool>[];
    await openAt(
      tester,
      Alignment.topLeft,
      const EdgeInsets.all(8),
      menu(
        direction: MorphingMenuDirection.down,
        expandedHeight: 180,
        onExpandedChanged: changes.add,
      ),
    );

    await tester.drag(
      find.byKey(const ValueKey<String>('morphing-menu-button-drag-handle')),
      const Offset(0, -180),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(changes, <bool>[true, false]);
    expect(overlaySurface(), findsNothing);
  });

  testWidgets('disabling drag resize keeps the card fixed without a handle', (
    WidgetTester tester,
  ) async {
    await openAt(
      tester,
      Alignment.topLeft,
      const EdgeInsets.all(8),
      menu(
        contentBuilder: (_, _) => const SizedBox.shrink(),
        direction: MorphingMenuDirection.down,
        expandedHeight: 180,
        maxExpandedHeight: 300,
        enableDragResize: false,
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('morphing-menu-button-drag-handle')),
      findsNothing,
    );
    final before = tester.getRect(overlaySurface());
    final gesture = await tester.startGesture(before.center);
    await gesture.moveBy(const Offset(0, 100));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(
      tester.getRect(overlaySurface()).height,
      closeTo(before.height, 0.01),
    );
  });

  testWidgets('the drag handle rides the top edge of an upward card', (
    WidgetTester tester,
  ) async {
    await openAt(
      tester,
      Alignment.bottomLeft,
      const EdgeInsets.all(40),
      menu(direction: MorphingMenuDirection.up, expandedHeight: 220),
    );
    expect(
      tester
          .getRect(
            find.byKey(
              const ValueKey<String>('morphing-menu-button-drag-handle'),
            ),
          )
          .top,
      closeTo(tester.getRect(overlaySurface()).top, 0.01),
    );
  });

  testWidgets('the drag handle rides the bottom edge of a downward card', (
    WidgetTester tester,
  ) async {
    await openAt(
      tester,
      Alignment.topLeft,
      const EdgeInsets.all(8),
      menu(direction: MorphingMenuDirection.down, expandedHeight: 220),
    );
    expect(
      tester
          .getRect(
            find.byKey(
              const ValueKey<String>('morphing-menu-button-drag-handle'),
            ),
          )
          .bottom,
      closeTo(tester.getRect(overlaySurface()).bottom, 0.01),
    );
  });

  Widget paddedFiller(BuildContext context, VoidCallback close) =>
      const SizedBox.expand(key: ValueKey<String>('padded-content'));

  testWidgets('an upward card reserves its handle clearance on top', (
    WidgetTester tester,
  ) async {
    await openAt(
      tester,
      Alignment.bottomLeft,
      const EdgeInsets.all(40),
      menu(
        direction: MorphingMenuDirection.up,
        expandedHeight: 220,
        contentBuilder: paddedFiller,
      ),
    );
    final card = tester.getRect(overlaySurface());
    final box = tester.getRect(
      find.byKey(const ValueKey<String>('padded-content')),
    );
    expect(box.top - card.top, closeTo(36, 0.01));
    expect(card.bottom - box.bottom, closeTo(16, 0.01));
  });

  testWidgets('a downward card moves its handle clearance to the bottom', (
    WidgetTester tester,
  ) async {
    await openAt(
      tester,
      Alignment.topLeft,
      const EdgeInsets.all(8),
      menu(
        direction: MorphingMenuDirection.down,
        expandedHeight: 220,
        contentBuilder: paddedFiller,
      ),
    );
    final card = tester.getRect(overlaySurface());
    final box = tester.getRect(
      find.byKey(const ValueKey<String>('padded-content')),
    );
    expect(box.top - card.top, closeTo(16, 0.01));
    expect(card.bottom - box.bottom, closeTo(36, 0.01));
  });

  testWidgets('elastic overshoot opening down stays inside the viewport', (
    WidgetTester tester,
  ) async {
    final anchor = await openAt(
      tester,
      Alignment.topLeft,
      const EdgeInsets.all(8),
      menu(
        style: null,
        direction: MorphingMenuDirection.down,
        expandedHeight: 220,
      ),
    );

    // openAt already pumped 201ms of the 700ms elastic run; 219 more reaches
    // the curve's peak at 60%.
    await tester.pump(const Duration(milliseconds: 219));
    final peak = tester.getRect(overlaySurface());
    expect(peak.height, greaterThan(220));
    expect(peak.bottom, lessThanOrEqualTo(600));

    await tester.pump(const Duration(milliseconds: 280));
    final settled = tester.getRect(overlaySurface());
    expect(settled.height, closeTo(220, 0.01));
    expect(settled.top, closeTo(anchor.bottom + 8, 0.01));
  });

  testWidgets('auto latches its side for the lifetime of one open', (
    WidgetTester tester,
  ) async {
    late StateSetter rebuild;
    var topInset = 500.0;
    await tester.pumpWidget(
      testApp(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            rebuild = setState;
            return Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.only(top: topInset),
                child: menu(expandedHeight: 220),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('morphing-menu-button-trigger')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 201));
    expect(tester.getRect(overlaySurface()).height, closeTo(220, 0.01));

    // Move the anchor to where `auto` would now choose to open downward.
    rebuild(() => topInset = 150);
    await tester.pump();

    final anchor = tester.getRect(
      find.byKey(const ValueKey<String>('morphing-menu-button-trigger')),
    );
    final card = tester.getRect(overlaySurface());
    expect(card.bottom, closeTo(anchor.top - 8, 0.01));
    expect(card.bottom, lessThan(anchor.top));
  });

  testWidgets('a maximized downward card cannot leave the viewport', (
    WidgetTester tester,
  ) async {
    await openAt(
      tester,
      Alignment.topLeft,
      const EdgeInsets.all(8),
      menu(
        direction: MorphingMenuDirection.down,
        expandedHeight: 180,
        maxExpandedHeight: 900,
      ),
    );

    await tester.drag(
      find.byKey(const ValueKey<String>('morphing-menu-button-drag-handle')),
      const Offset(0, 900),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));

    expect(tester.getRect(overlaySurface()).bottom, lessThanOrEqualTo(588.01));
  });

  testWidgets('dragging below the threshold closes the card', (
    WidgetTester tester,
  ) async {
    final changes = <bool>[];
    await tester.pumpWidget(
      testApp(
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: menu(onExpandedChanged: changes.add),
          ),
        ),
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('morphing-menu-button-trigger')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 201));

    await tester.drag(
      find.byKey(const ValueKey<String>('morphing-menu-button-drag-handle')),
      const Offset(0, 180),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(changes, <bool>[true, false]);
    expect(overlaySurface(), findsNothing);
  });

  testWidgets('upward drag can snap to the configured maximum height', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: menu(expandedHeight: 180, maxExpandedHeight: 300),
          ),
        ),
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('morphing-menu-button-trigger')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 201));

    await tester.drag(
      find.byKey(const ValueKey<String>('morphing-menu-button-drag-handle')),
      const Offset(0, -100),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.getSize(overlaySurface()).height, inExclusiveRange(280, 300));
    await tester.pump(const Duration(milliseconds: 180));
    expect(tester.getSize(overlaySurface()).height, 300);
  });

  testWidgets('theme and per-widget style resolve smooth card geometry', (
    WidgetTester tester,
  ) async {
    const themed = MorphingMenuButtonStyle(
      expandedBackgroundColor: Color(0xFF123456),
      expandedWidth: 280,
      expandedHeight: 190,
      smoothness: 0.75,
      duration: Duration.zero,
      reverseDuration: Duration.zero,
    );
    await tester.pumpWidget(
      testApp(
        Center(
          child: MorphingMenuButtonTheme(
            data: const MorphingMenuButtonThemeData(style: themed),
            child: menu(style: null),
          ),
        ),
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('morphing-menu-button-trigger')),
    );
    await tester.pump();

    final surface = tester.widget<DecoratedBox>(overlaySurface());
    final decoration = surface.decoration as ShapeDecoration;
    expect(decoration.color, const Color(0xFF123456));
    expect((decoration.shape as SmoothRectangleBorder).smoothness, 0.75);
    expect(tester.getSize(overlaySurface()), const Size(280, 190));
  });

  testWidgets('dark mode resolves the fallback dynamic surface', (
    WidgetTester tester,
  ) async {
    const zeroMotion = MorphingMenuButtonStyle(
      duration: Duration.zero,
      reverseDuration: Duration.zero,
    );
    await tester.pumpWidget(
      testApp(
        Center(child: menu(style: zeroMotion)),
        brightness: Brightness.dark,
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('morphing-menu-button-trigger')),
    );
    await tester.pump();

    final decoration =
        tester.widget<DecoratedBox>(overlaySurface()).decoration
            as ShapeDecoration;
    expect(decoration.color, const Color(0xFF27272A));
  });

  testWidgets('reduced motion opens and closes immediately', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      testApp(Center(child: menu()), disableAnimations: true),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('morphing-menu-button-trigger')),
    );
    await tester.pump();
    expect(tester.getSize(overlaySurface()), const Size(360, 236));

    await tester.tap(find.byKey(const ValueKey<String>('menu-action')));
    await tester.pump();
    expect(overlaySurface(), findsNothing);
  });

  test('style supports copy and value equality', () {
    const original = MorphingMenuButtonStyle();
    final copy = original.copyWith();
    final changed = original.copyWith(expandedWidth: 420);

    expect(copy, original);
    expect(copy.hashCode, original.hashCode);
    expect(changed, isNot(original));
    expect(changed.expandedWidth, 420);
    expect(
      const MorphingMenuButtonThemeData().copyWith(),
      const MorphingMenuButtonThemeData(),
    );
  });

  group('in place', () {
    const glyph = ValueKey<String>('in-place-glyph');
    const field = ValueKey<String>('in-place-field');

    MorphingMenuButton inPlaceMenu({
      MorphingMenuAlignment alignment = MorphingMenuAlignment.end,
      bool enableDragResize = true,
    }) => menu(
      leading: const Icon(CupertinoIcons.search, key: glyph, size: 14),
      direction: MorphingMenuDirection.inPlace,
      alignment: alignment,
      enableDragResize: enableDragResize,
      expandedWidth: 240,
      expandedHeight: 220,
      maxExpandedHeight: 320,
      contentBuilder: (_, _) => const SizedBox(key: field, height: 20),
    );

    Finder trigger() =>
        find.byKey(const ValueKey<String>('morphing-menu-button-trigger'));

    testWidgets('grows over the trigger at the trigger height', (
      WidgetTester tester,
    ) async {
      final anchor = await openAt(
        tester,
        Alignment.center,
        EdgeInsets.zero,
        inPlaceMenu(),
      );

      final card = tester.getRect(overlaySurface());
      expect(card.top, closeTo(anchor.top, 0.01));
      expect(card.height, closeTo(anchor.height, 0.01));
      expect(card.right, closeTo(anchor.right, 0.01));
      expect(card.width, closeTo(240, 0.01));
    });

    testWidgets('ignores the requested height and shows no drag handle', (
      WidgetTester tester,
    ) async {
      final anchor = await openAt(
        tester,
        Alignment.center,
        EdgeInsets.zero,
        inPlaceMenu(),
      );

      expect(
        find.byKey(const ValueKey<String>('morphing-menu-button-drag-handle')),
        findsNothing,
      );
      final gesture = await tester.startGesture(
        tester.getRect(overlaySurface()).center,
      );
      await gesture.moveBy(const Offset(0, -100));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        tester.getRect(overlaySurface()).height,
        closeTo(anchor.height, 0.01),
      );
    });

    testWidgets('keeps content unscaled and held to the fixed edge', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testApp(Center(child: inPlaceMenu())));
      final anchor = tester.getRect(trigger());
      await tester.tap(trigger());
      await tester.pump();

      var sampled = 0;
      for (var elapsed = 0; elapsed < 200; elapsed += 20) {
        await tester.pump(const Duration(milliseconds: 20));
        expect(tester.takeException(), isNull);
        final content = tester.getRect(find.byKey(field));
        final padding = instantStyle.panelPadding.resolve(TextDirection.ltr);
        expect(content.width, closeTo(240 - padding.horizontal, 0.01));
        expect(content.right, closeTo(anchor.right - padding.right, 0.01));
        sampled++;
      }
      expect(sampled, greaterThan(4));
    });

    testWidgets('keeps the fading trigger glyph on the fixed edge', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testApp(Center(child: inPlaceMenu())));
      final collapsedGlyph = tester.getRect(find.byKey(glyph));
      await tester.tap(trigger());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      expect(tester.getRect(overlaySurface()).width, greaterThan(60));
      expect(
        tester.getRect(find.byKey(glyph).last).center.dx,
        closeTo(collapsedGlyph.center.dx, 0.01),
      );
    });

    testWidgets('opens under a scaled ancestor without a height clash', (
      WidgetTester tester,
    ) async {
      // A scaled ancestor makes the trigger shorter in overlay coordinates
      // than the style's buttonHeight.
      await tester.pumpWidget(
        testApp(
          Center(
            child: Transform.scale(
              scale: 0.8,
              // A glyph small enough to fit the trigger at this scale, so the
              // test isolates the card's height.
              child: menu(
                leading: const Icon(CupertinoIcons.search, size: 8),
                direction: MorphingMenuDirection.inPlace,
                alignment: MorphingMenuAlignment.end,
                expandedWidth: 240,
                contentBuilder: (_, _) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );
      final anchor = tester.getRect(trigger());
      await tester.tap(trigger());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 201));

      expect(tester.takeException(), isNull);
      final card = tester.getRect(overlaySurface());
      expect(card.height, closeTo(anchor.height, 0.01));
      expect(card.right, closeTo(anchor.right, 0.01));
    });

    testWidgets('start alignment holds the trailing edge in RTL', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          Directionality(
            textDirection: TextDirection.rtl,
            child: Center(
              child: inPlaceMenu(alignment: MorphingMenuAlignment.start),
            ),
          ),
        ),
      );
      final anchor = tester.getRect(trigger());
      await tester.tap(trigger());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 201));

      final card = tester.getRect(overlaySurface());
      expect(card.right, closeTo(anchor.right, 0.01));
      expect(card.top, closeTo(anchor.top, 0.01));
      expect(card.height, closeTo(anchor.height, 0.01));
    });
  });
}
