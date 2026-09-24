# Access Able PH Flutter app

The splash screen is the app's entry screen, followed by the Places and Map discovery tabs. Both discovery views follow the visual language in [`docs/figma structure`](../docs/figma%20structure): a blue search header, city and status filters, personalized need tags, and bottom navigation. Places contains the card list; Map uses the remaining content area for the interactive map. Flutter's Material icons replace the prototype's emoji icons.

## Global design config

[`lib/app/design_system.dart`](lib/app/design_system.dart) is the Flutter source of truth for the theme. Update that file when changing the app's visual tokens, then keep this table in sync.

| Token | Value | Use |
| --- | --- | --- |
| Primary | `#005BAA` | Header, selected city, navigation, and actions |
| Primary dark | `#004080` | Darker brand variant |
| Accent | `#CE1126` | PH brand tag |
| Background | `#F2F5F9` | Screen canvas |
| Splash background | `#F7F9FC` | Calm startup canvas |
| Splash primary | `#2457A6` | Splash logo |
| Splash accent | `#2A8C82` | Splash loading indicators |
| Splash ink | `#172033` | Splash title and loading label |
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

## Splash implementation

[`lib/features/splash/views/splash_screen.dart`](lib/features/splash/views/splash_screen.dart) owns the startup presentation and transition. It displays the accessibility/location logo, **Access Able PH**, the **Accessibility within reach** tagline, and indeterminate circular and linear progress indicators with screen-reader labels. The layout scrolls when needed and constrains its width on larger displays.

The splash stays visible only while its injected startup task is pending. If startup fails, it announces an error and offers a retry. The current startup task waits for Flutter's first rendered frame and loads the locally saved accessibility needs. A first launch opens My Accessibility Needs after the splash; later launches restore the saved needs and open Places without an artificial delay. Add Supabase, session, or other required configuration to that task when those integrations exist; do not show a fake percentage.

## Places, Map, and needs implementation

[`lib/features/discovery/views/discovery_home.dart`](lib/features/discovery/views/discovery_home.dart) owns the shared search, city/status filtering, recommendation context, empty state, and place summary sheet. Bottom navigation presents **Places**, **Map**, **Community**, and **More**, in that order. Places renders cards without a map preview. Map renders an interactive full map without place cards or an extra list/map toggle. Search, city filters, status filters, and selected need tags are available in both discovery views.

[`lib/features/needs/views/accessibility_needs_screen.dart`](lib/features/needs/views/accessibility_needs_screen.dart) provides the multi-select **My Accessibility Needs** screen during first-launch onboarding and from More. The app starts with no assumed needs. Saving completes onboarding and persists the selections on the device through [`lib/features/needs/data/accessibility_needs_store.dart`](lib/features/needs/data/accessibility_needs_store.dart); no account or backend write is involved. Leaving the first-launch screen without saving keeps onboarding incomplete. The selected needs rank Places cards by the number of matching fixture tags and add a star to matching map pins. These match hints are recommendations only. The evidence status remains visually and semantically separate.

[`lib/shared/repositories/fixture_places.dart`](lib/shared/repositories/fixture_places.dart) contains **sample data only**, adapted from the Figma reference. The screens label their counts as sample data; no status, report count, supported-need tag, or recommendation is a live or certified accessibility claim. Selecting a place opens its sample address and summary. Community, Favorites, and Settings remain placeholders.

The interactive map uses `flutter_map` with OpenStreetMap tiles. The list and search work without network access or location permission. Map tiles need internet; the map keeps OpenStreetMap attribution visible. The Android app declares internet permission. The tile URL defaults to the public OpenStreetMap server and can be changed at build time with `--dart-define=MAP_TILE_URL=https://your-tile-server/{z}/{x}/{y}.png`. Before public distribution, choose a tile provider suitable for expected traffic and follow its usage terms. The OpenStreetMap default uses the app ID as its user agent and `flutter_map`'s built-in tile cache.

When a shared data contract and backend read model exist, replace the fixture source with a repository adapter under `lib/shared/repositories/`. Keep Supabase calls out of widgets. Persist needs on device by default and use the assessment contract for evidence-linked results. Do not derive personalized accessibility assessments from browse labels or recommendation matches.

## Run and check

From `app/`:

```sh
flutter pub get
flutter run
flutter analyze
flutter test
```

The root `.flutter/` directory is the local Flutter SDK checkout, not product code.
