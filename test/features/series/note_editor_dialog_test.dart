import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangabaka_app/core/constants/mock_series_data.dart';
import 'package:mangabaka_app/core/localization/localization_service.dart';
import 'package:mangabaka_app/core/widgets/adaptive_sheet.dart';
import 'package:mangabaka_app/features/library/models/library_entry.dart';
import 'package:mangabaka_app/features/series/widgets/note_editor_dialog.dart';
import 'package:mangabaka_app/features/series/widgets/series_my_list_card.dart';
import 'package:mangabaka_app/features/series/widgets/series_note_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    LocalizationService.resetForTesting();
    await LocalizationService().init();
  });

  group('NoteEditorDialog', () {
    testWidgets('initializes with existing note, previews markdown, and saves',
        (tester) async {
      String? savedNote;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteEditorDialog(
              initialNote: '# Arc 1\n**Great** start',
              onSave: (value) => savedNote = value,
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('# Arc 1\n**Great** start'), findsOneWidget);

      // Switch to Preview tab and verify MarkdownBody renders.
      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      expect(find.byType(SeriesNoteMarkdown), findsOneWidget);
      expect(find.byType(MarkdownBody), findsOneWidget);

      // Switch back to Write, update text, and save.
      await tester.tap(find.text('Write'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Updated *markdown*');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(savedNote, 'Updated *markdown*');
    });

    testWidgets('toolbar bold button wraps selection', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteEditorDialog(
              initialNote: 'hello',
              onSave: (_) {},
            ),
          ),
        ),
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      field.controller!.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 5,
      );

      await tester.tap(find.byIcon(Icons.format_bold_rounded));
      await tester.pump();

      expect(field.controller!.text, '**hello**');
    });

    testWidgets('clear button empties text field', (tester) async {
      String? savedNote;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteEditorDialog(
              initialNote: 'Old note',
              onSave: (value) => savedNote = value,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Clear'));
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(savedNote, '');
    });

    testWidgets('Ctrl+B wraps selected text and inserts **|** when collapsed',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteEditorDialog(
              initialNote: 'hello world',
              onSave: (_) {},
            ),
          ),
        ),
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      // 1. Selected text: "hello" -> "**hello**"
      field.controller!.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 5,
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(field.controller!.text, '**hello** world');
      expect(
        field.controller!.selection,
        const TextSelection(baseOffset: 2, extentOffset: 7),
      );

      // 2. Collapsed cursor at end: inserts "****" with cursor in the middle.
      field.controller!.selection = TextSelection.collapsed(
        offset: field.controller!.text.length,
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(field.controller!.text, '**hello** world****');
      expect(
        field.controller!.selection,
        const TextSelection.collapsed(offset: 17),
      );
    });
  });

  group('AdaptiveSheetHandle', () {
    testWidgets('is visible in portrait and hidden in landscape',
        (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(size: Size(400, 800)),
          child: MaterialApp(home: Scaffold(body: AdaptiveSheetHandle())),
        ),
      );
      expect(find.byType(Container), findsOneWidget);

      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(size: Size(800, 400)),
          child: MaterialApp(home: Scaffold(body: AdaptiveSheetHandle())),
        ),
      );
      expect(find.byType(Container), findsNothing);
    });
  });

  group('SeriesMyListCard note section', () {
    LibraryEntry makeEntry({String? note}) => LibraryEntry(
      id: 'entry-1',
      state: 'reading',
      progressChapter: 10,
      progressVolume: 2,
      rating: 80,
      note: note,
      series: mockSeries222,
    );

    testWidgets('shows placeholder when note is empty and invokes onUpdateNote',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SeriesMyListCard(
                series: mockSeries222,
                entry: makeEntry(),
                l10n: LocalizationService(),
                onStateChanged: (_) {},
                onUpdateChapter: () {},
                onUpdateVolume: () {},
                onUpdateRating: () {},
                onUpdateNote: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('NOTES'), findsOneWidget);
      expect(find.byType(SeriesNoteMarkdown), findsNothing);
      await tester.tap(find.byIcon(Icons.add).last);
      expect(tapped, isTrue);
    });

    testWidgets('renders markdown when note is present', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SeriesMyListCard(
                series: mockSeries222,
                entry: makeEntry(note: '- Item 1\n- **Item 2**'),
                l10n: LocalizationService(),
                onStateChanged: (_) {},
                onUpdateChapter: () {},
                onUpdateVolume: () {},
                onUpdateRating: () {},
                onUpdateNote: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SeriesNoteMarkdown), findsOneWidget);
      expect(find.byType(MarkdownBody), findsOneWidget);
    });
  });
}
