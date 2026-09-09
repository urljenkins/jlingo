import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_sprint/models/book.dart';
import 'package:lingua_sprint/providers/book_provider.dart';
import 'package:lingua_sprint/screens/book_library_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Book and Document Models', () {
    test('BookManifestEntry parses category or defaults cleanly', () {
      final jsonWithCategory = {
        'id': 'bank_statement_es',
        'title': 'Monthly Bank Statement',
        'author': 'Banco Continental',
        'originalLanguage': 'spanish',
        'translatedLanguage': 'english',
        'category': 'document',
        'description': 'A bank statement',
        'difficulty': 'beginner',
        'totalWords': 480,
        'chapterCount': 3,
      };

      final entry = BookManifestEntry.fromJson(jsonWithCategory);
      expect(entry.id, 'bank_statement_es');
      expect(entry.category, 'document');

      final jsonWithoutCategory = {
        'id': 'legacy_book',
        'title': 'Legacy Story',
        'author': 'Unknown',
        'originalLanguage': 'spanish',
        'translatedLanguage': 'english',
        'description': 'A story',
        'difficulty': 'intermediate',
        'totalWords': 1000,
        'chapterCount': 2,
      };

      final legacyEntry = BookManifestEntry.fromJson(jsonWithoutCategory);
      expect(legacyEntry.category, isNull);
    });

    test('BilingualBook parses document asset files cleanly', () {
      final docFiles = [
        'bank_statement_es.json',
        'city_registration_es.json',
        'lease_agreement_es.json',
        'aesop_fables_es.json',
        'little_red_riding_hood_fr.json',
      ];

      for (final filename in docFiles) {
        final file = File('assets/books/$filename');
        expect(file.existsSync(), isTrue, reason: '$filename should exist');
        final json =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final book = BilingualBook.fromJson(json);

        expect(book.id, isNotEmpty);
        expect(book.title, isNotEmpty);
        expect(book.chapters, isNotEmpty);
        for (final chapter in book.chapters) {
          expect(chapter.paragraphs, isNotEmpty);
          for (final p in chapter.paragraphs) {
            expect(p.originalText, isNotEmpty);
            expect(p.translatedText, isNotEmpty);
            expect(p.vocabularyWords, isNotEmpty);
          }
        }
      }
    });
  });

  group('BookProvider category and language filtering', () {
    test('filteredBooks filters by category and language', () async {
      final provider = BookProvider();
      await provider.loadAvailableBooks();

      expect(provider.availableBooks, isNotEmpty);

      // Verify new documents and beginner stories are present in availableBooks
      final bookIds = provider.availableBooks.map((b) => b.id).toSet();
      expect(bookIds.contains('bank_statement_es'), isTrue);
      expect(bookIds.contains('city_registration_es'), isTrue);
      expect(bookIds.contains('lease_agreement_es'), isTrue);
      expect(bookIds.contains('aesop_fables_es'), isTrue);
      expect(bookIds.contains('little_red_riding_hood_fr'), isTrue);

      // Filter by document category
      provider.setCategoryFilter('document');
      expect(provider.filteredBooks.isNotEmpty, isTrue);
      expect(
        provider.filteredBooks.every((b) => b.category == 'document'),
        isTrue,
      );

      // Filter by literature category
      provider.setCategoryFilter('literature');
      expect(provider.filteredBooks.isNotEmpty, isTrue);
      expect(
        provider.filteredBooks.every(
          (b) => b.category == 'literature' || b.category == null,
        ),
        isTrue,
      );

      // Clear category filter
      provider.setCategoryFilter(null);
      expect(provider.filteredBooks.length, provider.availableBooks.length);

      // Filter by language
      provider.setLanguageFilter('french');
      expect(
        provider.filteredBooks.every((b) =>
            b.originalLanguage == 'french' || b.translatedLanguage == 'french'),
        isTrue,
      );
      expect(
        provider.filteredBooks.any((b) => b.id == 'little_red_riding_hood_fr'),
        isTrue,
      );
    });
  });

  group('BookLibraryScreen UI', () {
    testWidgets('renders category and difficulty filter chips and book cards',
        (tester) async {
      final provider = BookProvider();
      await tester.runAsync(provider.loadAvailableBooks);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<BookProvider>.value(
            value: provider,
            child: const BookLibraryScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();

      // Check category chips
      expect(find.text('All Types'), findsOneWidget);
      expect(find.text('Stories & Fables'), findsOneWidget);
      expect(find.text('Official Documents'), findsOneWidget);

      // Check difficulty chips
      expect(find.text('All Levels'), findsOneWidget);
      expect(find.text('Beginner'), findsOneWidget);
      expect(find.text('Intermediate'), findsOneWidget);
      expect(find.text('Advanced'), findsOneWidget);

      // Tap Official Documents filter chip
      await tester.tap(find.text('Official Documents'));
      await tester.pump();

      // Should show document cards with DOCUMENT badge
      expect(find.text('Monthly Bank Statement'), findsOneWidget);
      expect(find.text('DOCUMENT'), findsWidgets);
    });
  });
}
