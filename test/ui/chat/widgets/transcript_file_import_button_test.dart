import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memex/config/app_flavor.dart';
import 'package:memex/domain/models/transcript_import.dart';
import 'package:memex/l10n/app_localizations.dart';
import 'package:memex/ui/chat/widgets/transcript_file_import_button.dart';
import 'package:memex/utils/user_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    AppFlavor.init('global');
    SharedPreferences.setMockInitialValues({});
    await UserStorage.initL10n();
  });

  Future<void> pump(
    WidgetTester tester, {
    required Future<List<int>?> Function() pickBytes,
    required Future<bool> Function(List<TranscriptImport> sources) store,
    List<String> fileNames = const ['conversa.txt'],
    Future<void> Function()? onStored,
    void Function(String text)? onConfirmed,
    VoidCallback? onViewActivity,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          appBar: AppBar(
            actions: [
              TranscriptFileImportButton(
                pickFiles: () async {
                  final bytes = await pickBytes();
                  return bytes == null
                      ? null
                      : [
                          for (final name in fileNames)
                            (name: name, bytes: bytes),
                        ];
                },
                store: store,
                onStored: onStored,
                onConfirmed: onConfirmed,
                onViewActivity: onViewActivity,
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('a dismissed picker does not open the confirmation',
      (tester) async {
    var stores = 0;
    await pump(
      tester,
      pickBytes: () async => null,
      store: (_) async {
        stores += 1;
        return true;
      },
    );

    await tester.tap(find.byKey(const ValueKey('import_transcript_file')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('send_outgoing_text')), findsNothing);
    expect(stores, 0);
  });

  testWidgets('cancel leaves the chosen transcript unstored', (tester) async {
    final bytes = utf8.encode('00:01\nolá');
    var stores = 0;
    await pump(
      tester,
      pickBytes: () async => bytes,
      store: (_) async {
        stores += 1;
        return true;
      },
    );

    await tester.tap(find.byKey(const ValueKey('import_transcript_file')));
    await tester.pumpAndSettle();

    final shown = tester.widget<Text>(
      find.byKey(const ValueKey('send_outgoing_text')),
    );
    expect(shown.data, '[00:00:01]\nolá');
    expect(find.text('conversa.txt'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('send_confirmation_cancel')));
    await tester.pumpAndSettle();

    expect(stores, 0);
  });

  testWidgets('confirm stores the original bytes and refreshes the list',
      (tester) async {
    final bytes = utf8.encode('00:01\nolá');
    final stored = <TranscriptImport>[];
    var refreshes = 0;
    final sent = <String>[];
    await pump(
      tester,
      pickBytes: () async => bytes,
      store: (sources) async {
        stored.addAll(sources);
        return true;
      },
      onStored: () async {
        refreshes += 1;
      },
      onConfirmed: sent.add,
    );

    await tester.tap(find.byKey(const ValueKey('import_transcript_file')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('send_confirmation_confirm')));
    await tester.pumpAndSettle();

    expect(stored, hasLength(1));
    expect(stored.single.originalBytes, bytes);
    expect(stored.single.normalizedText, '[00:00:01]\nolá');
    expect(refreshes, 1);
    expect(sent, ['[00:00:01]\nolá']);
    expect(find.text(UserStorage.l10n.dataImportSuccess), findsOneWidget);
  });

  testWidgets('lists multiple TXT files and stores each original',
      (tester) async {
    final bytes = utf8.encode('00:01\nolá');
    final stored = <TranscriptImport>[];
    final sent = <String>[];
    await pump(
      tester,
      pickBytes: () async => bytes,
      fileNames: const ['parte-1.txt', 'parte-2.txt'],
      store: (sources) async {
        stored.addAll(sources);
        return true;
      },
      onConfirmed: sent.add,
    );

    await tester.tap(find.byKey(const ValueKey('import_transcript_file')));
    await tester.pumpAndSettle();
    expect(find.text('parte-1.txt'), findsOneWidget);
    expect(find.text('parte-2.txt'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('send_confirmation_confirm')));
    await tester.pumpAndSettle();

    expect(stored, hasLength(2));
    expect(
      stored.map((source) => source.originalBytes).toList(),
      [bytes, bytes],
    );
    expect(sent, ['[00:00:01]\nolá\n\n[00:00:01]\nolá']);
  });

  testWidgets('a PDF disguised as text cannot be confirmed', (tester) async {
    var stores = 0;
    await pump(
      tester,
      pickBytes: () async => utf8.encode('%PDF-1.4'),
      store: (_) async {
        stores += 1;
        return true;
      },
    );

    await tester.tap(find.byKey(const ValueKey('import_transcript_file')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('send_pdf_unsupported')), findsOneWidget);
    final confirm = tester.widget<FilledButton>(
      find.byKey(const ValueKey('send_confirmation_confirm')),
    );
    expect(confirm.onPressed, isNull);
    expect(stores, 0);
  });

  testWidgets('shows import progress and opens existing activity on request',
      (tester) async {
    final saving = Completer<bool>();
    var activityOpens = 0;
    await pump(
      tester,
      pickBytes: () async => utf8.encode('00:01\nolá'),
      store: (_) => saving.future,
      onConfirmed: (_) {},
      onViewActivity: () => activityOpens++,
    );

    await tester.tap(find.byKey(const ValueKey('import_transcript_file')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('send_confirmation_confirm')));
    await tester.pump();

    expect(find.text(UserStorage.l10n.importingTranscript), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    saving.complete(true);
    await tester.pumpAndSettle();
    expect(find.text(UserStorage.l10n.viewActivity), findsOneWidget);

    await tester.tap(find.text(UserStorage.l10n.viewActivity));
    expect(activityOpens, 1);
  });

  testWidgets('reports a failed import without sending the transcript',
      (tester) async {
    final sent = <String>[];
    await pump(
      tester,
      pickBytes: () async => utf8.encode('00:01\nolá'),
      store: (_) async => false,
      onConfirmed: sent.add,
    );

    await tester.tap(find.byKey(const ValueKey('import_transcript_file')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('send_confirmation_confirm')));
    await tester.pumpAndSettle();

    expect(find.text(UserStorage.l10n.transcriptImportFailed), findsOneWidget);
    expect(sent, isEmpty);
  });
}
