import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/attachments.dart';

void main() {
  group('Relative path for tree', () {
    testWidgets('None', (tester) async {
      await tester.pumpWidget(
        _Harness((context) {
          final doc = OrgDocument.parse('* foo');
          expect(getAttachmentRelativePath(context, doc), isNull);
          expect(
            getAttachmentRelativePath(context, doc.sections.first),
            isNull,
          );
        }),
      );
    });
    testWidgets('id type section', (tester) async {
      await tester.pumpWidget(
        _Harness((context) {
          final doc = OrgDocument.parse('''
* foo
  :PROPERTIES:
  :ID:       C259CE94-D4C8-4C4F-9C9E-9ABE446E7DA3
  :END:
''');
          expect(getAttachmentRelativePath(context, doc), isNull);
          expect(
            getAttachmentRelativePath(context, doc.sections.first),
            'data/C2/59CE94-D4C8-4C4F-9C9E-9ABE446E7DA3',
          );
        }),
      );
    });
    testWidgets('id type doc', (tester) async {
      await tester.pumpWidget(
        _Harness((context) {
          final doc = OrgDocument.parse('''
:PROPERTIES:
:ID:       C259CE94-D4C8-4C4F-9C9E-9ABE446E7DA3
:END:
* foo
''');
          expect(
            getAttachmentRelativePath(context, doc),
            'data/C2/59CE94-D4C8-4C4F-9C9E-9ABE446E7DA3',
          );
          expect(
            getAttachmentRelativePath(context, doc.sections.first),
            isNull,
          );
        }),
      );
    });
    testWidgets('dir type section', (tester) async {
      await tester.pumpWidget(
        _Harness((context) {
          final doc = OrgDocument.parse('''
* foo
  :PROPERTIES:
  :DIR:       foobar
  :END:
''');
          expect(getAttachmentRelativePath(context, doc), isNull);
          expect(
            getAttachmentRelativePath(context, doc.sections.first),
            'foobar',
          );
        }),
      );
    });
    testWidgets('dir type doc', (tester) async {
      await tester.pumpWidget(
        _Harness((context) {
          final doc = OrgDocument.parse('''
:PROPERTIES:
:DIR:       foobar
:END:
* foo
''');
          expect(getAttachmentRelativePath(context, doc), 'foobar');
          expect(
            getAttachmentRelativePath(context, doc.sections.first),
            isNull,
          );
        }),
      );
    });
  });
  group('Relative path at offset', () {
    testWidgets('None', (tester) async {
      await tester.pumpWidget(
        _Harness((context) {
          final doc = OrgDocument.parse('* foo');
          expect(getAttachmentRelativePathAtOffset(context, doc, 0), isNull);
          expect(getAttachmentRelativePathAtOffset(context, doc, 2), isNull);
        }),
      );
    });
    testWidgets('id type section', (tester) async {
      await tester.pumpWidget(
        _Harness((context) {
          final doc = OrgDocument.parse('''a
* foo
  :PROPERTIES:
  :ID:       C259CE94-D4C8-4C4F-9C9E-9ABE446E7DA3
  :END:
''');
          expect(getAttachmentRelativePathAtOffset(context, doc, 0), isNull);
          expect(
            getAttachmentRelativePathAtOffset(context, doc, 10),
            'data/C2/59CE94-D4C8-4C4F-9C9E-9ABE446E7DA3',
          );
        }),
      );
    });
    testWidgets('id type doc', (tester) async {
      await tester.pumpWidget(
        _Harness((context) {
          final doc = OrgDocument.parse('''
:PROPERTIES:
:ID:       C259CE94-D4C8-4C4F-9C9E-9ABE446E7DA3
:END:
* foo
''');
          expect(
            getAttachmentRelativePathAtOffset(context, doc, 0),
            'data/C2/59CE94-D4C8-4C4F-9C9E-9ABE446E7DA3',
          );
          expect(getAttachmentRelativePathAtOffset(context, doc, 70), isNull);
        }),
      );
    });
    testWidgets('dir type section', (tester) async {
      await tester.pumpWidget(
        _Harness((context) {
          final doc = OrgDocument.parse('''a
* foo
  :PROPERTIES:
  :DIR:       foobar
  :END:
''');
          expect(getAttachmentRelativePathAtOffset(context, doc, 0), isNull);
          expect(getAttachmentRelativePathAtOffset(context, doc, 10), 'foobar');
        }),
      );
    });
    testWidgets('dir type doc', (tester) async {
      await tester.pumpWidget(
        _Harness((context) {
          final doc = OrgDocument.parse('''
:PROPERTIES:
:DIR:       foobar
:END:
* foo
''');
          expect(getAttachmentRelativePathAtOffset(context, doc, 0), 'foobar');
          expect(getAttachmentRelativePathAtOffset(context, doc, 40), isNull);
        }),
      );
    });
  });
}

class _Harness extends StatelessWidget {
  final void Function(BuildContext) builder;

  const _Harness(this.builder);

  @override
  Widget build(BuildContext context) {
    return InheritedOrgSettings(
      [OrgSettings.defaults],
      child: Builder(
        builder: (context) {
          builder(context);
          return SizedBox.shrink();
        },
      ),
    );
  }
}
