import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/pages/document/citations.dart';
import 'package:petit_bibtex/bibtex.dart';

void main() {
  group('Citations', () {
    group('Bibliographies', () {
      test('None present', () {
        final doc = OrgDocument.parse('* foo');
        final found = extractBibliograpies(doc);
        expect(found, isEmpty);
      });
      test('Finds one', () {
        final doc = OrgDocument.parse('''#+bibliography: foo.bib''');
        final found = extractBibliograpies(doc);
        expect(found, ['foo.bib']);
      });
      test('With spaces', () {
        final doc = OrgDocument.parse('''#+bibliography: "foo bar.bib"''');
        final found = extractBibliograpies(doc);
        expect(found, ['foo bar.bib']);
      });
      test('Multiple', () {
        final doc = OrgDocument.parse('''
#+bibliography: "foo bar.bib"
#+bibliography: /bizbaz.bib
''');
        final found = extractBibliograpies(doc);
        expect(found, ['foo bar.bib', '/bizbaz.bib']);
      });
    });
    group('Presentation', () {
      test('Pretty URL', () {
        const entry = BibTeXEntry(
          type: 'book',
          key: 'key',
          fields: {
            'url': 'http://example.com',
            'url-quoted': '"http://example.com/2"',
            'url-braces': '{http://example.com/3}',
            'url-markup': r'\url{http://example.com/4}'
          },
        );
        expect(entry.getPrettyValue('url'), 'http://example.com');
        expect(entry.getPrettyValue('url-quoted'), 'http://example.com/2');
        expect(entry.getPrettyValue('url-braces'), 'http://example.com/3');
        expect(entry.getPrettyValue('url-markup'), 'http://example.com/4');
      });
      group('Extract URL', () {
        test('url field', () {
          const entry = BibTeXEntry(
            type: 'book',
            key: 'key',
            fields: {'url': 'http://example.com'},
          );
          expect(entry.getUrl(), Uri.parse('http://example.com'));
        });
        test('howpublished field', () {
          const entry = BibTeXEntry(
            type: 'book',
            key: 'key',
            fields: {'howpublished': 'http://example.com'},
          );
          expect(entry.getUrl(), Uri.parse('http://example.com'));
        });
        test('howpublished field not a URL', () {
          const entry = BibTeXEntry(
            type: 'book',
            key: 'key',
            fields: {'howpublished': 'i dunno'},
          );
          expect(entry.getUrl(), isNull);
        });
      });
      test('Volume', () {
        const entry = BibTeXEntry(
          type: 'book',
          key: 'key',
          fields: {'volume': '1'},
        );
        expect(entry.getPrettyValue('volume'), 'Vol. 1');
      });
      test('Number', () {
        const entry = BibTeXEntry(
          type: 'book',
          key: 'key',
          fields: {'number': '1'},
        );
        expect(entry.getPrettyValue('number'), 'No. 1');
      });
      test('Month', () {
        const entry = BibTeXEntry(
          type: 'book',
          key: 'key',
          fields: {'month': 'jan'},
        );
        expect(entry.getPrettyValue('month'), 'January');
      });
      group('Pages', () {
        test('En dash range', () {
          const entry = BibTeXEntry(
            type: 'book',
            key: 'key',
            fields: {'pages': '1--2'},
          );
          expect(entry.getPrettyValue('pages'), 'pp. 1–2');
        });
        test('Dash range', () {
          const entry = BibTeXEntry(
            type: 'book',
            key: 'key',
            fields: {'pages': '1-2'},
          );
          expect(entry.getPrettyValue('pages'), 'pp. 1-2');
        });
        test('Comma', () {
          const entry = BibTeXEntry(
            type: 'book',
            key: 'key',
            fields: {'pages': '1,2'},
          );
          expect(entry.getPrettyValue('pages'), 'pp. 1,2');
        });
        test('Single', () {
          const entry = BibTeXEntry(
            type: 'book',
            key: 'key',
            fields: {'pages': '1'},
          );
          expect(entry.getPrettyValue('pages'), 'p. 1');
        });
      });
      test('Details', () {
        const entry = BibTeXEntry(
          type: 'book',
          key: 'key',
          fields: {
            'title': 'My Book',
            'author': 'Foo Bar',
            'publisher': 'Pseudorandom House',
            'address': 'New York, NY',
            'month': 'sep',
            'year': '2024',
            'pages': '1--10',
          },
        );
        expect(
          entry.getDetails(),
          'Foo Bar • Pseudorandom House • New York, NY • September • 2024 • pp. 1–10',
        );
      });
    });
  });
}
