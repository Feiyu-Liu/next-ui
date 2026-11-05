import 'package:flutter/cupertino.dart';

import 'my_button_theme.dart';

/// Places command buttons in a consistently spaced horizontal row.
class MyButtonGroup extends StatelessWidget {
  const MyButtonGroup({required this.children, this.spacing, super.key});

  final List<Widget> children;
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    final resolvedSpacing = spacing ?? MyButtonTheme.of(context).groupSpacing;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) SizedBox(width: resolvedSpacing),
          children[index],
        ],
      ],
    );
  }
}
