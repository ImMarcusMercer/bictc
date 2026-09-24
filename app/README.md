# AccessPH Flutter app

The Map/Home screen is the app's first screen. It follows the layout in [`docs/figma structure`](../docs/figma%20structure): a blue search header, city and status filters, a list/map switch, a map preview, place cards, and bottom navigation. Flutter's Material icons replace the prototype's emoji icons.

## Global design config

[`lib/app/design_system.dart`](lib/app/design_system.dart) is the Flutter source of truth for the theme. Update that file when changing the app's visual tokens, then keep this table in sync.

| Token | Value | Use |
| --- | --- | --- |
| Primary | `#005BAA` | Header, selected city, actions, map button |
| Primary dark | `#004080` | Darker brand variant |
| Accent | `#CE1126` | PH brand tag |
| Background | `#F2F5F9` | Screen canvas |
| Card | `#FFFFFF` | Cards and controls |
| Border | `#D4DDE8` | Dividers and outlines |
| Ink | `#0F1F2E` | Main text and selected status filter |
| Muted | `#64748B` | Secondary text |
| Accessible | `#008A5B` | Status icon, text, and card rail |
| Partial | `#B45309` | Status icon, text, and card rail |
| Barrier | `#B42318` | Status icon, text, and card rail |
| Unknown | `#667085` | Status icon, text, and card rail |

- **Fonts:** Outfit for headings and Nunito for body and controls. The bundled variable font files and their Open Font Licenses are in `assets/fonts/`, so text works offline. The app theme applies Nunito globally and Outfit to title styles.
- **Shape and spacing:** 20 px card corners, 14 px control corners, 16 px horizontal page padding, and at least 48 px touch targets. Interactive status controls combine a label, icon, and color.
- **Accessibility:** Keep semantic labels on map markers, use text alongside status colors, preserve scrolling at large text sizes, and make the list available without map connectivity or location permission.
- **Result language:** The status chips on this screen are sample browse labels. Personalized results must use the four outcomes in `docs/project-structure-and-flow.md` and cite actual evidence when the backend is connected.

## Map/Home implementation

[`lib/features/discovery/views/discovery_home.dart`](lib/features/discovery/views/discovery_home.dart) owns search, city/status filtering, list/map switching, empty state, and the place summary sheet. [`lib/shared/repositories/fixture_places.dart`](lib/shared/repositories/fixture_places.dart) contains **sample data only**, adapted from the Figma reference. The screen labels its counts as sample data; no status or report count is a live or certified accessibility claim. Selecting a place opens its sample address and summary. The other main tabs remain placeholders.

The interactive map uses `flutter_map` with OpenStreetMap tiles. The list and search work without network access or location permission. Map tiles need internet; the map keeps OpenStreetMap attribution visible. The Android app declares internet permission. The tile URL defaults to the public OpenStreetMap server and can be changed at build time with `--dart-define=MAP_TILE_URL=https://your-tile-server/{z}/{x}/{y}.png`. Before public distribution, choose a tile provider suitable for expected traffic and follow its usage terms. The OpenStreetMap default uses the app ID as its user agent and `flutter_map`'s built-in tile cache.

When a shared data contract and backend read model exist, replace the fixture source with a repository adapter under `lib/shared/repositories/`. Keep Supabase calls out of widgets. Do not derive personalized accessibility assessments from these browse labels.

## Run and check

From `app/`:

```sh
flutter pub get
flutter run
flutter analyze
flutter test
```

The root `.flutter/` directory is the local Flutter SDK checkout, not product code.
