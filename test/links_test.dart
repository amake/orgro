import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/pages/document/links.dart';

void main() {
  group('Abbreviations', () {
    group('LINK directives', () {
      test('None present', () {
        final doc = OrgDocument.parse('* foo');
        final found = extractLinkAbbreviations(doc);
        expect(found, isEmpty);
      });
      test('Finds one', () {
        final doc = OrgDocument.parse('''#+LINK: foo bar''');
        final found = extractLinkAbbreviations(doc);
        expect(found, [(linkword: 'foo', format: 'bar')]);
      });
      test('With spaces', () {
        final doc = OrgDocument.parse('''#+LINK: "foo bar" baz''');
        final found = extractLinkAbbreviations(doc);
        expect(found, [(linkword: 'foo bar', format: 'baz')]);
      });
      test('Multiple', () {
        final doc = OrgDocument.parse('''
#+LINK: foo bar
#+LINK: "baz buzz" bazinga
''');
        final found = extractLinkAbbreviations(doc);
        expect(found, [
          (linkword: 'foo', format: 'bar'),
          (linkword: 'baz buzz', format: 'bazinga'),
        ]);
      });
    });
    group('Extraction', () {
      test('Appending', () {
        final doc = OrgDocument.parse('''#+LINK: foo bar''');
        final link = OrgPlainLink('foo:buzz');
        final result = extractUrl(doc, link);
        expect(result, Uri.parse('barbuzz'));
      });
      test('Replacing', () {
        final doc = OrgDocument.parse('''#+LINK: foo bar=%s&blah''');
        final link = OrgPlainLink('foo:buzz');
        final result = extractUrl(doc, link);
        expect(result, Uri.parse('bar=buzz&blah'));
      });
      test('Percent-encoding', () {
        final doc = OrgDocument.parse('''#+LINK: foo bar=%h&blah''');
        final link = OrgPlainLink('foo:あ');
        final result = extractUrl(doc, link);
        expect(result, Uri.parse('bar=%E3%81%82&blah'));
      });
      test('Missing definition', () {
        final doc = OrgDocument.parse('''#+LINK: foo bar=%h&blah''');
        final link = OrgPlainLink('foof:あ');
        final result = extractUrl(doc, link);
        expect(result, Uri.parse('foof:あ'));
      });
      test('Space in linkword', () {
        final doc = OrgDocument.parse('''#+LINK: "foo bar" baz=%h&blah''');
        final link = OrgPlainLink('foo bar:あ');
        final result = extractUrl(doc, link);
        expect(result, Uri.parse('baz=%E3%81%82&blah'));
      });
      test('Multiple placeholders (same)', () {
        final doc = OrgDocument.parse('''#+LINK: foo bar=%s&%s''');
        final link = OrgPlainLink('foo:baz');
        final result = extractUrl(doc, link);
        expect(result, Uri.parse('bar=baz&%s'));
      });
      test('Multiple placeholders (different)', () {
        final doc = OrgDocument.parse('''#+LINK: foo bar=%h&%s''');
        final link = OrgPlainLink('foo:baz');
        final result = extractUrl(doc, link);
        expect(result, Uri.parse('bar=%h&baz'));
      });
    });
  });
}
