// First-party example code, licensed under MIT. See ../../LICENSE and NOTICE.
import 'package:flutter/cupertino.dart';
import 'package:next_ui/next_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MyTopProgressiveBlur.precache();
  runApp(const ShowcaseApp());
}

class ShowcaseApp extends StatefulWidget {
  const ShowcaseApp({super.key, this.enableBlur = true});

  /// CPU widget tests opt out; the desktop app always uses the real shader.
  final bool enableBlur;

  @override
  State<ShowcaseApp> createState() => _ShowcaseAppState();
}

class _ShowcaseAppState extends State<ShowcaseApp> {
  final _dark = ValueNotifier(false);

  @override
  void dispose() {
    _dark.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: _dark,
    builder: (context, dark, _) => CupertinoApp(
      title: 'next_ui · Component studio',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        brightness: dark ? Brightness.dark : Brightness.light,
        primaryColor: CupertinoColors.systemBlue,
      ),
      // The nav bar uses platformBrightness; keep it aligned with the toggle.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          platformBrightness: dark ? Brightness.dark : Brightness.light,
        ),
        child: NeoButtonTheme(
          data: const NeoButtonThemeData(enableHapticFeedback: false),
          child: child!,
        ),
      ),
      home: _Studio(dark: _dark, enableBlur: widget.enableBlur),
    ),
  );
}

class _Studio extends StatefulWidget {
  const _Studio({required this.dark, required this.enableBlur});
  final ValueNotifier<bool> dark;
  final bool enableBlur;

  @override
  State<_Studio> createState() => _StudioState();
}

class _StudioState extends State<_Studio> {
  final _status = ValueNotifier('Ready to explore');
  final _tab = ValueNotifier(0);
  final _menu = MorphingMenuButtonController();

  @override
  void dispose() {
    _status.dispose();
    _tab.dispose();
    super.dispose();
  }

  void _activate(String name) => _status.value = '$name pressed';

  Future<void> _simulateWork() async {
    _status.value = 'Working…';
    await Future<void>.delayed(const Duration(seconds: 1));
    if (mounted) _status.value = 'Finished — ready again';
  }

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    child: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            key: const Key('studio-scroll'),
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'next_ui',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'A small studio for desktop controls.',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  NeoIconButton(
                    key: const Key('theme-toggle'),
                    icon: widget.dark.value
                        ? CupertinoIcons.sun_max
                        : CupertinoIcons.moon,
                    semanticsLabel: 'Toggle light and dark theme',
                    tooltip: 'Toggle appearance',
                    filled: true,
                    onPressed: () => widget.dark.value = !widget.dark.value,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _Section(
                title: '01 / Buttons',
                description:
                    'Five roles, three sizes. Try the async action to see automatic loading.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final variant in NeoButtonVariant.values)
                          NeoButton(
                            variant.name,
                            variant: variant,
                            onPressed: () => _activate(variant.name),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final size in NeoButtonSize.values)
                          NeoButton(
                            size.name,
                            size: size,
                            variant: NeoButtonVariant.secondary,
                            onPressed: () => _activate(size.name),
                          ),
                        const NeoButton('Disabled', onPressed: null),
                        NeoButton(
                          'Run task',
                          key: const Key('async-action'),
                          icon: CupertinoIcons.play_fill,
                          onPressed: _simulateWork,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final variant in NeoButtonVariant.values)
                          NeoIconButton(
                            icon: CupertinoIcons.star,
                            variant: variant,
                            semanticsLabel: '${variant.name} icon',
                            tooltip: '${variant.name} icon',
                            onPressed: () => _activate('${variant.name} icon'),
                          ),
                        const NeoIconButton(
                          icon: CupertinoIcons.lock,
                          semanticsLabel: 'Disabled icon',
                          onPressed: null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ValueListenableBuilder<String>(
                      valueListenable: _status,
                      builder: (context, value, _) => Text(
                        value,
                        key: const Key('action-status'),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              _Section(
                title: '02 / Groups & menus',
                description:
                    'Grouped actions and an anchored card. Click outside or press Escape to dismiss.',
                child: Wrap(
                  spacing: 20,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    MyButtonGroup(
                      children: [
                        NeoIconButton(
                          icon: CupertinoIcons.arrow_uturn_left,
                          semanticsLabel: 'Undo',
                          onPressed: () => _activate('Undo'),
                        ),
                        NeoIconButton(
                          icon: CupertinoIcons.arrow_uturn_right,
                          semanticsLabel: 'Redo',
                          onPressed: () => _activate('Redo'),
                        ),
                      ],
                    ),
                    MorphingMenuButton(
                      key: const Key('menu-trigger'),
                      controller: _menu,
                      icon: CupertinoIcons.slider_horizontal_3,
                      label: 'Quick actions',
                      expandedWidth: 260,
                      expandedHeight: 170,
                      onTriggerPressed: _menu.toggle,
                      contentBuilder: (context, close) => Padding(
                        padding: const EdgeInsets.all(20),
                        child: ListView(
                          primary: false,
                          padding: EdgeInsets.zero,
                          children: [
                            const Text(
                              'Make it yours',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 16),
                            NeoButton(
                              'Choose blue',
                              onPressed: () {
                                _activate('Blue selected');
                                close();
                              },
                            ),
                            const SizedBox(height: 8),
                            NeoButton(
                              'Close',
                              variant: NeoButtonVariant.ghost,
                              onPressed: close,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const _Section(
                title: '03 / Small details',
                description:
                    'CapsuleTag treatments and a layered MiniFolderIcon.',
                child: Wrap(
                  spacing: 18,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    CapsuleTag('Favorite', icon: CupertinoIcons.star),
                    CapsuleTag(
                      '⌘ K',
                      variant: CapsuleTagVariant.keycap,
                      color: CupertinoColors.systemBlue,
                    ),
                    CapsuleTag(
                      'PRO',
                      variant: CapsuleTagVariant.pro,
                      color: CupertinoColors.systemIndigo,
                    ),
                    MiniFolderIcon(size: 32),
                    MiniFolderIcon(size: 48),
                  ],
                ),
              ),
              _Section(
                title: '04 / Navigation',
                description:
                    'A softly recessed track with an animated selection.',
                child: ValueListenableBuilder<int>(
                  valueListenable: _tab,
                  builder: (context, selected, _) => Column(
                    children: [
                      NeumorphicNavBar(
                        selectedIndex: selected,
                        onItemSelected: (index) => _tab.value = index,
                        items: const [
                          NeumorphicNavItem(
                            label: 'Library',
                            icon: CupertinoIcons.square_grid_2x2,
                          ),
                          NeumorphicNavItem(
                            label: 'Favorites',
                            icon: CupertinoIcons.star,
                          ),
                          NeumorphicNavItem(
                            label: 'Settings',
                            icon: CupertinoIcons.gear,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Selected: ${['Library', 'Favorites', 'Settings'][selected]}',
                        key: const Key('nav-status'),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              _Section(
                title: '05 / Progressive blur',
                description:
                    'Scroll inside the preview. Color and detail soften toward the top edge.',
                child: _BlurPreview(enabled: widget.enableBlur),
              ),
              const Text(
                'Local components. Synthetic content. No network requests.\nExample source: MIT · Upstream credits in the package NOTICE.',
                style: TextStyle(fontSize: 12, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.description,
    required this.child,
  });
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 20),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: CupertinoDynamicColor.resolve(
        CupertinoColors.secondarySystemGroupedBackground,
        context,
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: CupertinoDynamicColor.resolve(
          CupertinoColors.separator,
          context,
        ).withValues(alpha: 0.15),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(description, style: const TextStyle(fontSize: 13, height: 1.5)),
        const SizedBox(height: 20),
        child,
      ],
    ),
  );
}

class _BlurPreview extends StatelessWidget {
  const _BlurPreview({required this.enabled});
  final bool enabled;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: SizedBox(
      height: 240,
      child: enabled
          ? MyTopProgressiveBlur(
              blurExtent: 90,
              edgeGuardColor: CupertinoTheme.of(
                context,
              ).scaffoldBackgroundColor,
              child: const _ColorStrips(),
            )
          : const _ColorStrips(),
    ),
  );
}

class _ColorStrips extends StatelessWidget {
  const _ColorStrips();
  static const _colors = [
    Color(0xFF285B85),
    Color(0xFF236C66),
    Color(0xFF805629),
    Color(0xFF6B5180),
  ];

  @override
  Widget build(BuildContext context) => ListView.builder(
    primary: false,
    itemCount: 12,
    itemBuilder: (context, index) => Container(
      height: 76,
      color: _colors[index % _colors.length],
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerLeft,
      child: Text(
        'Color study ${(index + 1).toString().padLeft(2, '0')}  /  ${'• ' * 8}',
        style: const TextStyle(
          color: CupertinoColors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
