# Third-party notices

## Adapted source: ChunUI (MIT)

`neo_button.dart`, `neo_button_theme.dart`, and `capsule_tag.dart` contain
Flutter adaptations of ChunUI button/tag designs and behavior. Copyright (c)
2026 liseami (赵纯想). Full permission and disclaimer are in
[`third_party/CHUNUI_LICENSE`](third_party/CHUNUI_LICENSE), retained independently
of this package's Apache-2.0 license.

Provenance: the extraction source's commits `ea10d15772d18533e42db6b56a4cc26973079079`
and `e24646bab5fffe8488766e1bf4734b5d19f0dc87` explicitly identify the ports.
The MIT text was verified against the ChunUI source checkout at
`65fcbf895f8dc8aba7161b85ad3ae30ac0929901`.

## Package dependencies

- Flutter SDK: BSD-3-Clause and its own third-party notices.
- `smooth_corner` 1.1.1: BSD-3-Clause, Copyright (c) 2021 Hosea Tao.
- `progressive_blur` 0.0.2: MIT, Copyright 2025 Erzhan Kabdykairov.
  Its shader is loaded by `MyTopProgressiveBlur.precache()` and is distributed
  by that dependency, not copied into this repository.
- `lucide_icons_flutter` is a test-only dependency. Its icon licenses remain in
  that package and are not replaced by Apache-2.0.

Full runtime dependency license copies accompany this file in `third_party/`.
Resolved transitive dependencies and their license texts remain supplied by
Pub/Flutter; binary distributors must retain their generated license bundle
as well as this package's LICENSE, NOTICE, and ChunUI license.
