# next_ui

Reusable desktop controls used by SkillDeck. This is the authoritative source
for the extracted controls; the legacy private package only forwards them.

## Scope

- `NeoButton`, `NeoIconButton`, `NeoPressable`, `NeoSurface`, and their themes
- `MorphingMenuButton`, controller, styles, and theme
- `CapsuleTag`, `MiniFolderIcon`, and `NeumorphicNavBar`
- `MyButtonGroup` and the theme shared with button tooltips
- `MyTopProgressiveBlur`, including its shader precache entry point

No App business logic, photos, private examples, or private Git history is
included. The blur shader belongs to the public `progressive_blur` dependency;
this package owns no image or shader assets. The old `MyButton`, `MyIconButton`,
and `MyMenuButton` implementations are deliberately not included.

## Toolchain and validation

Currently developed with Flutter **3.47.5** / Dart **3.13.4**. The manifest retains
the source baseline constraints (Dart `^3.10.4`, Flutter `>=3.32.0`); those lower
bounds are **unverified**, not newly certified compatibility. Extraction does
not raise consumer SDK requirements. Mobile/web support is not promised. Desktop release evidence must distinguish
macOS arm64, macOS Intel, and Windows; widget tests alone do not validate GPU
shader rendering.

```sh
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos --no-pub
flutter test --no-pub
```

The lockfile is checked in for reproducible package tests. Hosted CI uses a
read-only GitHub-hosted runner, with no private keys or signing credentials.

## Component showcase

The [example desktop app](example/README.md) demonstrates every included control
with light/dark switching and local interactive examples. Run it on macOS:

```sh
cd example
flutter pub get --enforce-lockfile
flutter run -d macos
```

Windows and Linux runners are included but have not yet been built or validated.

## Installation

Publication has not been authorized yet. During local integration use this
repository's **file Git URL pinned to an immutable local commit**, not a path
override or a fictitious public URL. This is intentionally not portable to CI.
Before release, approve the remote owner/name and reviewed file list, publish
this clean history, then replace the temporary Git URL in both consumers and
regenerate their lockfiles. Keep both consumers pinned to the same commit.
This package is not published to pub.dev (`publish_to: none`).

```dart
import 'package:flutter/cupertino.dart';
import 'package:next_ui/next_ui.dart';

Widget action(VoidCallback onPressed) => NeoButton(
  'Continue',
  onPressed: onPressed,
);
```

## Provenance and licenses

The extraction baseline is `my_ui` commit
`3dc634e3ed8221b9c5032a2122f47bdbde32f73e`, not its current working tree.
The ten complete support/component modules plus `MyButtonGroup` were copied
without behavioral redesign. Tests were migrated from that same baseline.
Source Git history for this closure names Feiyu-Liu as author (with AI
co-authorship). The new repository starts with an independent snapshot.

Original code is licensed under MIT; see `LICENSE`. Neo controls and
capsule tags are adaptations of MIT-licensed ChunUI and retain its attribution
and full license in `NOTICE` and `third_party/CHUNUI_LICENSE`. These notices are
not a claim to sole ownership of upstream code. See `THIRD_PARTY_NOTICES.md` for
dependency licenses. Public release still requires final owner/privacy review.

## Acknowledgements

Some components, including the Neo buttons and capsule tags, are Flutter ports
of ChunUI components. Thanks to the ChunUI authors for their original work.
The original MIT copyright and license notices are preserved in
[NOTICE](NOTICE) and [third_party/CHUNUI_LICENSE](third_party/CHUNUI_LICENSE).

部分组件（包括 Neo 按钮和胶囊标签）是 ChunUI 组件的 Flutter 复刻版。
感谢 ChunUI 作者的原创工作，原始 MIT 版权声明和许可证已保留在上述文件中。
