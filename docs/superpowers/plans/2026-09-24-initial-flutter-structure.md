# Initial Flutter Structure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create an Android-only BICTC Flutter application under `app/` with an accessible landing page and a locally validated dummy login form.

**Architecture:** Use a dependency-free Material application with feature-owned views and Flutter's built-in `Navigator`. Keep the app shell in `lib/app/`, the two screens in their feature directories, and defer repositories, state management, Supabase, and advanced routing until a real product slice needs them.

**Tech Stack:** Flutter 3.47.5, Dart 3.13.4, Material 3, Flutter widget tests, Android/Kotlin scaffold.

**Spec:** `docs/superpowers/specs/2026-09-24-initial-flutter-structure-design.md`

## Global Constraints

- Use the repository-local Flutter 3.47.5 SDK at `.flutter/`.
- Generate only the Android platform under `app/`.
- Use Android application ID `com.artemis.bictc`.
- Use `BICTC` as the user-facing name and `bictc` as the Dart package name.
- Keep product code out of `.flutter/`, and keep `.flutter/` ignored by Git.
- Add no Supabase, routing, state-management, dependency-injection, or other runtime package.
- Never persist, log, or transmit the dummy login values.
- Create only directories that contain working files.
- Use standard Material semantics, visible labels, text alongside visual cues, scrollable layouts, and minimum 48-by-48 logical-pixel actions.

## File Map

- Create `app/`: Flutter package root and generated Android project.
- Modify `app/android/app/src/main/AndroidManifest.xml`: set the launcher label to `BICTC`.
- Modify `app/lib/main.dart`: start the application and contain no product logic.
- Create `app/lib/app/bictc_app.dart`: own `MaterialApp`, app title, theme, and initial page.
- Create `app/lib/features/landing/views/landing_page.dart`: explain BICTC and navigate to sign-in.
- Create `app/lib/features/auth/views/login_page.dart`: own form state, local validation, and dummy result message.
- Replace any generated sample test with `app/test/landing_page_test.dart`: cover landing content, navigation, back behavior, and large-text layout.
- Create `app/test/login_page_test.dart`: cover empty input, malformed email, dummy success, and large-text layout.

## Review Focus

- A 320-by-568 Android viewport at 2x text scale must remain scrollable without layout exceptions; Tasks 1 and 2 add explicit widget tests.
- Returning with Android-style back navigation from login must restore the landing screen; Task 1 tests the route stack.
- Empty email and password values must show distinct, field-adjacent corrections; Task 2 tests both messages.
- A malformed email with a non-empty password must show only the email correction and must not show the dummy success message; Task 2 tests this path.
- Syntactically acceptable dummy values must show the not-connected message without changing screen or introducing network dependencies; Task 2 tests the visible result and Task 3 audits dependencies.

---

### Task 1: Android Scaffold, App Shell, and Landing Flow

**Files:**
- Create: `app/` using Flutter's Android-only empty template
- Modify: `app/android/app/src/main/AndroidManifest.xml`
- Modify: `app/lib/main.dart`
- Create: `app/lib/app/bictc_app.dart`
- Create: `app/lib/features/landing/views/landing_page.dart`
- Create: `app/lib/features/auth/views/login_page.dart`
- Test: `app/test/landing_page_test.dart`

**Interfaces:**
- Consumes: repository-local executable `.flutter/bin/flutter.bat`
- Produces: `const BictcApp()`, `const LandingPage()`, and `const LoginPage()` widgets for Task 2

- [ ] **Step 1: Generate the minimal Android-only Flutter package**

Run from the repository root:

```powershell
& .\.flutter\bin\flutter.bat --suppress-analytics create `
  --platforms=android `
  --org com.artemis `
  --project-name bictc `
  --description "BICTC accessibility app." `
  --empty `
  app
```

Confirm that `app/android/`, `app/lib/`, and `app/pubspec.yaml` exist and that no `ios/`, `web/`, `windows/`, `linux/`, or `macos/` directory was generated.

- [ ] **Step 2: Remove the generated unused runtime dependency**

The installed Flutter 3.47.5 app template declares `cupertino_icons`, but this Material-only shell does not use it. Remove it through Flutter's package command so both dependency files stay consistent:

```powershell
Push-Location app
& ..\.flutter\bin\flutter.bat pub remove cupertino_icons
Pop-Location
```

Expected: `app/pubspec.yaml` has no `cupertino_icons` entry and `app/pubspec.lock` is refreshed.

- [ ] **Step 3: Write the failing landing and navigation tests**

Delete any generated sample widget test and create `app/test/landing_page_test.dart`:

```dart
import 'package:bictc/app/bictc_app.dart';
import 'package:bictc/features/auth/views/login_page.dart';
import 'package:bictc/features/landing/views/landing_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('landing explains BICTC and opens login', (tester) async {
    await tester.pumpWidget(const BictcApp());

    expect(find.text('BICTC'), findsOneWidget);
    expect(
      find.text(
        'Explore community accessibility evidence before visiting an establishment.',
      ),
      findsOneWidget,
    );

    final signInButton = find.widgetWithText(FilledButton, 'Sign in');
    expect(signInButton, findsOneWidget);

    await tester.tap(signInButton);
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Sign in to BICTC'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(LandingPage), findsOneWidget);
  });

  testWidgets('landing supports narrow screens with large text', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(2)),
          child: child!,
        ),
        home: const LandingPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
  });
}
```

- [ ] **Step 4: Run the landing test and verify the red state**

```powershell
Push-Location app
& ..\.flutter\bin\flutter.bat test test\landing_page_test.dart
Pop-Location
```

Expected: FAIL because `bictc_app.dart`, `landing_page.dart`, and `login_page.dart` do not exist.

- [ ] **Step 5: Implement the minimal app entry point**

Replace `app/lib/main.dart` with:

```dart
import 'package:bictc/app/bictc_app.dart';
import 'package:flutter/widgets.dart';

void main() {
  runApp(const BictcApp());
}
```

- [ ] **Step 6: Implement the application shell**

Create `app/lib/app/bictc_app.dart`:

```dart
import 'package:bictc/features/landing/views/landing_page.dart';
import 'package:flutter/material.dart';

class BictcApp extends StatelessWidget {
  const BictcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BICTC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006A60),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 48),
          ),
        ),
        useMaterial3: true,
      ),
      home: const LandingPage(),
    );
  }
}
```

- [ ] **Step 7: Implement the landing page and native navigation**

Create `app/lib/features/landing/views/landing_page.dart`:

```dart
import 'package:bictc/features/auth/views/login_page.dart';
import 'package:flutter/material.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BICTC')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Know what access looks like before you arrive.',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Explore community accessibility evidence before visiting an establishment.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 8: Add the minimal login route needed by the completed landing flow**

Create `app/lib/features/auth/views/login_page.dart`:

```dart
import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in to BICTC')),
      body: const SizedBox.shrink(),
    );
  }
}
```

- [ ] **Step 9: Set the Android launcher label**

In `app/android/app/src/main/AndroidManifest.xml`, set the generated application label to:

```xml
<application
    android:label="BICTC"
```

Keep the generated `android:name`, icon, activity, and intent-filter values unchanged. Confirm the generated namespace/application ID is `com.artemis.bictc` in the Android Gradle configuration.

- [ ] **Step 10: Format, analyze, and verify Task 1**

```powershell
Push-Location app
& ..\.flutter\bin\dart.bat format lib test
& ..\.flutter\bin\flutter.bat analyze
& ..\.flutter\bin\flutter.bat test test\landing_page_test.dart
Pop-Location
```

Expected: formatting succeeds, analysis reports no issues, and both landing tests pass.

- [ ] **Step 11: Commit the scaffold and landing flow**

```powershell
git add app
git commit -m "feat: add Android Flutter app shell"
```

### Task 2: Accessible Dummy Login Form

**Files:**
- Modify: `app/lib/features/auth/views/login_page.dart`
- Test: `app/test/login_page_test.dart`

**Interfaces:**
- Consumes: `const LoginPage()` route created by Task 1
- Produces: a self-contained `LoginPage` that validates locally and reports dummy submission through `ScaffoldMessenger`

- [ ] **Step 1: Write the failing login behavior tests**

Create `app/test/login_page_test.dart`:

```dart
import 'package:bictc/features/auth/views/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildLogin() => const MaterialApp(home: LoginPage());

  testWidgets('empty submission explains both required fields', (tester) async {
    await tester.pumpWidget(buildLogin());

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();

    expect(find.text('Enter your email.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    expect(find.text("Authentication isn't connected yet."), findsNothing);
  });

  testWidgets('malformed email shows an email correction only', (tester) async {
    await tester.pumpWidget(buildLogin());

    await tester.enterText(
      find.byKey(const Key('email-field')),
      'not-an-email',
    );
    await tester.enterText(
      find.byKey(const Key('password-field')),
      'dummy-password',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();

    expect(find.text('Enter a valid email.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsNothing);
    expect(find.text("Authentication isn't connected yet."), findsNothing);
  });

  testWidgets('valid dummy submission reports that auth is disconnected', (
    tester,
  ) async {
    await tester.pumpWidget(buildLogin());

    await tester.enterText(
      find.byKey(const Key('email-field')),
      'person@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('password-field')),
      'dummy-password',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(
      find.text("Authentication isn't connected yet."),
      findsOneWidget,
    );
  });

  testWidgets('login supports narrow screens with large text', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(2)),
          child: child!,
        ),
        home: const LoginPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('email-field')), findsOneWidget);
    expect(find.byKey(const Key('password-field')), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the login tests and verify the red state**

```powershell
Push-Location app
& ..\.flutter\bin\flutter.bat test test\login_page_test.dart
Pop-Location
```

Expected: FAIL because the minimal login route has no form fields or submit button.

- [ ] **Step 3: Implement the local-only login form**

Replace `app/lib/features/auth/views/login_page.dart` with:

```dart
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  String? _validateEmail(String? input) {
    final value = input?.trim() ?? '';
    if (value.isEmpty) {
      return 'Enter your email.';
    }

    final parts = value.split('@');
    if (parts.length != 2 || parts.any((part) => part.isEmpty)) {
      return 'Enter a valid email.';
    }

    return null;
  }

  String? _validatePassword(String? input) {
    if (input == null || input.isEmpty) {
      return 'Enter your password.';
    }
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text("Authentication isn't connected yet."),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in to BICTC')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Welcome back',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign-in is a preview and is not connected yet.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      key: const Key('email-field'),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      validator: _validateEmail,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Email',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('password-field'),
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      enableSuggestions: false,
                      autocorrect: false,
                      validator: _validatePassword,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Password',
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _submit,
                      child: const Text('Sign in'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Format and run the focused login tests**

```powershell
Push-Location app
& ..\.flutter\bin\dart.bat format lib test
& ..\.flutter\bin\flutter.bat test test\login_page_test.dart
Pop-Location
```

Expected: all four login tests pass.

- [ ] **Step 5: Run the complete Flutter validation suite**

```powershell
Push-Location app
& ..\.flutter\bin\flutter.bat analyze
& ..\.flutter\bin\flutter.bat test
Pop-Location
```

Expected: analysis reports no issues and all six widget tests pass.

- [ ] **Step 6: Commit the login form**

```powershell
git add app/lib/features/auth/views/login_page.dart app/test/login_page_test.dart
git commit -m "feat: add dummy login form"
```

### Task 3: Repository Boundary and Final Verification

**Files:**
- Verify: `.gitignore`
- Verify: `app/pubspec.yaml`
- Verify: all tracked files under `app/`

**Interfaces:**
- Consumes: completed application from Tasks 1 and 2
- Produces: evidence that the SDK is ignored, only Android is scaffolded, runtime dependencies remain minimal, and the full Flutter suite passes

- [ ] **Step 1: Verify the SDK boundary and generated platforms**

```powershell
git check-ignore -v .flutter\bin\flutter.bat
Get-ChildItem app -Directory | Select-Object -ExpandProperty Name
```

Expected: `.flutter/bin/flutter.bat` is ignored by the root `.gitignore`; the generated platform list contains `android` and does not contain iOS, web, Windows, Linux, or macOS directories.

- [ ] **Step 2: Audit runtime dependencies**

```powershell
Get-Content app\pubspec.yaml
```

Expected: the only runtime dependency is Flutter from the local SDK; `cupertino_icons` was removed in Task 1 and no application package was added.

- [ ] **Step 3: Run formatting, analysis, and the full test suite from a clean command path**

```powershell
Push-Location app
& ..\.flutter\bin\dart.bat format --output=none --set-exit-if-changed lib test
& ..\.flutter\bin\flutter.bat analyze
& ..\.flutter\bin\flutter.bat test
Pop-Location
git diff --check
```

Expected: every command exits zero, analysis reports no issues, and all six widget tests pass.

- [ ] **Step 4: Inspect the final repository state**

```powershell
git status --short
git log --oneline --decorate -3
```

Expected: no generated SDK files are tracked, no unexpected platform directories appear, and the two implementation commits follow the committed design specification.
