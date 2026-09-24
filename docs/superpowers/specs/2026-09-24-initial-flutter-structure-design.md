# Initial Flutter Structure Design

## Goal

Create the first Android-only Flutter client for BICTC under `app/`. The initial product surface consists of an accessible landing page and a dummy login form. This establishes a small, testable application shell without connecting Supabase or creating speculative feature structure.

## Constraints

- Use the repository-local Flutter 3.47.5 SDK at `.flutter/`.
- Generate only the Android platform.
- Use Android application ID `com.artemis.bictc`.
- Use `BICTC` as the user-facing application name and `bictc` as the Dart package name.
- Keep all product Flutter code under `app/`; never modify or version `.flutter/`.
- Do not add Supabase, routing, state-management, dependency-injection, or other third-party packages.
- Do not store or transmit login values.
- Create directories only when they contain working files.

## Structure

```text
app/
├── android/
├── lib/
│   ├── main.dart
│   ├── app/
│   │   └── bictc_app.dart
│   └── features/
│       ├── landing/
│       │   └── views/
│       │       └── landing_page.dart
│       └── auth/
│           └── views/
│               └── login_page.dart
├── test/
│   ├── landing_page_test.dart
│   └── login_page_test.dart
├── analysis_options.yaml
└── pubspec.yaml
```

Flutter-generated Android and tool configuration files remain in place. Generated sample counter code and its test are replaced by the BICTC application shell.

## Application Composition

`main.dart` starts a `BictcApp` widget. `BictcApp` owns the `MaterialApp`, application title, Material theme, and initial `LandingPage`. No dependency container or global mutable state is needed. The user-facing name remains `BICTC`.

The landing page presents:

- the BICTC name;
- a concise explanation that the app helps people inspect community accessibility evidence for establishments; and
- a clearly labeled **Sign in** button.

The button opens `LoginPage` with Flutter's built-in `Navigator` and `MaterialPageRoute`. A routing dependency is deferred until the application has deep links or navigation complexity that justifies it.

## Login Behavior

The login page contains a `Form` with labeled email and password fields. The password is obscured. Local validation requires both fields and checks that the email has a basic address shape suitable for immediate user feedback.

Submitting valid values does not authenticate, persist, log, or transmit them. It displays the message **Authentication isn't connected yet.** in a `SnackBar`. This gives every active control a clear result while keeping authentication explicitly out of scope.

## Accessibility

- Use standard Material widgets so controls participate in Flutter's semantics tree.
- Keep explicit visible labels on both fields and the primary action.
- Ensure layouts remain usable with large system text by placing page content in a scrollable, width-constrained layout.
- Use text in addition to any color or icon cues.
- Use standard Material button sizing with a minimum 48-by-48 logical-pixel target.
- Keep validation messages specific and adjacent to the relevant field.

## Tests and Verification

Widget tests verify:

1. the landing page renders its purpose and sign-in action;
2. the sign-in action opens the login page;
3. empty or malformed input shows validation feedback; and
4. valid dummy input shows the not-connected message.

Run the project-local SDK commands:

```powershell
Push-Location app
& ..\.flutter\bin\flutter.bat analyze
& ..\.flutter\bin\flutter.bat test
Pop-Location
```

The scaffold is complete when both commands pass and Git confirms `.flutter/` remains ignored.

## Deferred Work

- Supabase Auth and all network access.
- Session state and credential persistence.
- Repository adapters and data contracts.
- Discovery, establishments, assessment, reports, and needs features.
- Advanced routing, dependency injection, and state-management packages.
- Additional target platforms.

These are added only when their corresponding product slices are implemented.

## Official References

- Flutter command-line tooling: https://docs.flutter.dev/reference/flutter-cli
- Flutter navigation and routing: https://docs.flutter.dev/ui/navigation
- Flutter form recipes: https://docs.flutter.dev/cookbook/forms
- Flutter accessibility guidance: https://docs.flutter.dev/ui/accessibility
- Flutter accessible UI design: https://docs.flutter.dev/ui/accessibility/ui-design-and-styling
