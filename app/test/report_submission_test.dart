import 'package:bictc/app/design_system.dart';
import 'package:bictc/features/reports/views/community_reports.dart';
import 'package:bictc/features/reports/views/report_form.dart';
import 'package:bictc/shared/models/community_report.dart';
import 'package:bictc/shared/repositories/reports_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class TestReportsRepository extends PreviewReportsRepository {
  bool signedIn = true;
  bool failRead = false;
  bool failWrite = false;
  bool attached = true;
  int submissions = 0;
  ReportDraft? lastDraft;
  @override
  bool get canContribute => signedIn;
  @override
  bool get isPreview => false;
  @override
  Future<void> signIn(String email, String password) async {
    signedIn = true;
    notifyListeners();
  }

  @override
  Future<List<CommunityReport>> fetch({
    String? city,
    ReportStatus? status,
    int offset = 0,
  }) async {
    if (failRead) throw StateError('offline');
    return super.fetch(city: city, status: status, offset: offset);
  }

  @override
  Future<bool> submit(ReportDraft draft) async {
    if (!canContribute || failWrite) throw StateError('denied');
    submissions++;
    lastDraft = draft;
    return attached;
  }

  void expire() {
    signedIn = false;
    notifyListeners();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pickerChannel = MethodChannel('plugins.flutter.io/image_picker');
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pickerChannel, (call) async => null);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pickerChannel, null);
  });
  testWidgets('guest signs in and resumes the requested report form', (
    tester,
  ) async {
    final repository = TestReportsRepository()..signedIn = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CommunityReports(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Report Issue'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in to BICTC'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('email-field')),
      'member@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('password-field')),
      'test-password',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.byType(ReportForm), findsOneWidget);
    expect(repository.canContribute, isTrue);
  });
  Future<void> fill(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Public display name'),
      'A Contributor',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Establishment name'),
      'Community Hall',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'What did you observe?'),
      'Ramp clear at the main entrance.',
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Publish report'));
    await tester.pumpAndSettle();
  }

  testWidgets('signed-in user validates and publishes a good-access report', (
    tester,
  ) async {
    final repository = TestReportsRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppDesign.theme,
        home: Scaffold(body: CommunityReports(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Good Access'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Publish report'));
    await tester.tap(find.text('Publish report'));
    await tester.pumpAndSettle();
    expect(repository.submissions, 0);
    await fill(tester);
    await tester.tap(find.text('Publish report'));
    await tester.pumpAndSettle();
    expect(repository.submissions, 1);
    expect(repository.lastDraft!.status, ReportStatus.accessible);
    expect(find.text('Report published.'), findsOneWidget);
  });
  testWidgets(
    'photo failure reports partial success without keeping the form open',
    (tester) async {
      final repository = TestReportsRepository()..attached = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CommunityReports(repository: repository)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Report Issue'));
      await tester.pumpAndSettle();
      await fill(tester);
      await tester.tap(find.text('Publish report'));
      await tester.pumpAndSettle();
      expect(repository.submissions, 1);
      expect(
        find.text('Report published. Photo attachment could not be confirmed.'),
        findsOneWidget,
      );
      expect(find.byType(ReportForm), findsNothing);
    },
  );
  testWidgets('expired session disables photo attachment and publishing', (
    tester,
  ) async {
    final repository = TestReportsRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ReportForm(
          repository: repository,
          initialStatus: ReportStatus.partial,
        ),
      ),
    );
    repository.expire();
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Publish report'),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Add photo'),
          )
          .onPressed,
      isNull,
    );
    expect(repository.submissions, 0);
  });
  testWidgets('failed publication keeps the draft for recovery', (
    tester,
  ) async {
    final repository = TestReportsRepository()..failWrite = true;
    await tester.pumpWidget(
      MaterialApp(
        home: ReportForm(
          repository: repository,
          initialStatus: ReportStatus.partial,
        ),
      ),
    );
    await fill(tester);
    await tester.tap(find.text('Publish report'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Could not confirm publication.'),
      findsOneWidget,
    );
    expect(find.text('Community Hall'), findsOneWidget);
  });
  testWidgets('offline read shows retry and recovers', (tester) async {
    final repository = TestReportsRepository()..failRead = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CommunityReports(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('You may be offline'), findsOneWidget);
    repository.failRead = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Robinsons Galleria'), findsOneWidget);
  });
  testWidgets('narrow screen and large text do not overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: CommunityReports(repository: TestReportsRepository()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  test('preview adapter rejects direct writes', () async {
    final repository = PreviewReportsRepository();
    await expectLater(
      repository.submit(
        ReportDraft(
          author: 'A',
          place: 'B',
          city: 'C',
          description: 'D',
          status: ReportStatus.partial,
          observedAt: DateTime.now(),
        ),
      ),
      throwsStateError,
    );
    await expectLater(
      repository.setHelpful('sample-1', true),
      throwsStateError,
    );
    repository.dispose();
  });
  test('photos reject unsupported and oversized files', () {
    expect(
      () => ReportPhoto(Uint8List.fromList([1, 2, 3])),
      throwsFormatException,
    );
    expect(
      () => ReportPhoto(Uint8List(5 * 1024 * 1024 + 1)),
      throwsFormatException,
    );
    expect(
      ReportPhoto(Uint8List.fromList([255, 216, 255, 0])).contentType,
      'image/jpeg',
    );
  });
}
