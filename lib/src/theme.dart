import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:org_parser/org_parser.dart';

const orgLevelColors = [
  Color(0xff0000ff),
  Color(0xffa0522d),
  Color(0xffa020f0),
  Color(0xffb22222),
  Color(0xff228b22),
  Color(0xff008b8b),
  Color(0xff483d8b),
  Color(0xff8b2252),
];
const orgTodoColor = Color(0xffff0000);
const orgDoneColor = Color(0xff228b22);
const orgCodeColor = Color(0xff7f7f7f);
const orgLinkColor = Color(0xff3a5fcd);
const orgMetaColor = Color(0xffb22222);
final TextStyle orgStyle = GoogleFonts.firaMono(fontSize: 18);

TextStyle fontStyleForOrgStyle(TextStyle base, OrgStyle style) {
  switch (style) {
    case OrgStyle.bold:
      return base.copyWith(fontWeight: FontWeight.bold);
    case OrgStyle.verbatim: // fallthrough
    case OrgStyle.code:
      return base.copyWith(color: orgCodeColor);
    case OrgStyle.italic:
      return base.copyWith(fontStyle: FontStyle.italic);
    case OrgStyle.strikeThrough:
      return base.copyWith(decoration: TextDecoration.lineThrough);
    case OrgStyle.underline:
      return base.copyWith(decoration: TextDecoration.underline);
  }
  throw Exception('Unknown style: $style');
}
