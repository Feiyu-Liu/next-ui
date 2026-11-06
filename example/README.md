# next_ui component studio

A small Cupertino desktop app demonstrating the package's buttons, icon buttons,
button groups, morphing menu, capsule tags, folder icon, navigation bar, and
progressive blur. Switch between light and dark with the top-right button.
All content is synthetic and local; no images or private application code are used.

## Run

Developed and tested with Flutter **3.47.5 / Dart 3.13.4**. The manifest keeps
the package baseline constraints; lower SDK versions are not verified.

From this directory:

```sh
flutter pub get --enforce-lockfile
flutter run -d macos
# On the corresponding host:
flutter run -d windows
flutter run -d linux
```

The `next_ui` dependency is the adjacent package (`path: ../`). The only added
runtime dependency is `cupertino_icons`, for the showcase's icon font.

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze --fatal-infos --no-pub
flutter test --no-pub
flutter build macos --debug --no-pub
```

The actual app precaches and renders the progressive blur shader. CPU widget
tests explicitly use `ShowcaseApp(enableBlur: false)` while testing theme,
loading, menu selection, navigation, and narrow layouts. Those tests do **not**
validate GPU blur rendering. Native runner scaffolds are provided for desktop;
a build on one platform is not validation of another. No signing or release
configuration is included.

## License

First-party example source is covered by the package's MIT [LICENSE](../LICENSE).
Component attribution remains in [NOTICE](../NOTICE) and
[THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md); this example does not replace
or remove upstream notices. Flutter-generated runner files retain their own
copyright/license headers. Cupertino Icons is MIT-licensed (see its installed
package license).
