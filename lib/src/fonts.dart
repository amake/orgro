import 'dart:io';

import 'package:dynamic_fonts/dynamic_fonts.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:orgro/src/preferences.dart';
import 'package:path_provider/path_provider.dart';

Future<void> clearFontCache() async {
  final dir = await getApplicationSupportDirectory();
  for (final entry in dir.listSync()) {
    if (entry is File && entry.path.endsWith('.ttf')) {
      entry.deleteSync();
      debugPrint('Deleted cached font: ${entry.path}');
    }
  }
}

const _kCustomFonts = [
  _FiraGoFile.name,
  _IosevkaFile.name,
  _VictorMonoFile.name,
];

void _initCustomFonts() {
  if (_kCustomFonts.every(DynamicFonts.asMap().containsKey)) {
    return;
  }
  DynamicFonts.register(
    _FiraGoFile.name,
    [
      _FiraGoFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.normal,
        ),
        '495901c0c608ea265f4c31aa2a4c7a313e5cc2a3dd610da78a447fe8e07454a2',
        804888,
      ),
      _FiraGoFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.normal,
        ),
        'ab720753c39073556260ebbaee7e7af89f9ca202a7c7abc257d935db590a1e35',
        807140,
      ),
      _FiraGoFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.italic,
        ),
        '36713ecac376845daa58738d2c2ba797cf6f6477b8c5bb4fa79721dc970e8081',
        813116,
      ),
      _FiraGoFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
        ),
        '51ad0da400568385e038ccb962a692f145dfbd9071d7fe5cb0903fd2a8912ccd',
        813028,
      ),
    ].fold<Map<DynamicFontsVariant, DynamicFontsFile>>(
      {},
      (acc, file) => acc..[file.variant] = file,
    ),
    eager: true,
  );
  DynamicFonts.register(
    _IosevkaFile.name,
    [
      _IosevkaFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.normal,
        ),
        'df55fbb9aed60efecfbe6823f6ccad375cc930bc9dba5328e4216bd6a58c2b43',
        5448112,
      ),
      _IosevkaFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.normal,
        ),
        'e31f1503523e5377a699e080d83aab51a076cf41405f4b623c74bf0afd404c10',
        5445864,
      ),
      _IosevkaFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.italic,
        ),
        'fc919f2da273ff8cc261e0da71ebb8116780d0c151660eb8d4c178600e925c18',
        5668064,
      ),
      _IosevkaFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
        ),
        '0929d18cefa582b42db2d2b2969bda7a5089f69ecef9264103e4d752958fa9c0',
        5674032,
      ),
    ].fold<Map<DynamicFontsVariant, DynamicFontsFile>>(
      {},
      (acc, file) => acc..[file.variant] = file,
    ),
    eager: true,
  );
  DynamicFonts.register(
    _VictorMonoFile.name,
    [
      _VictorMonoFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.normal,
        ),
        '9b9c3863e68a572984eb48964c414e0da42960bfcb37dc497bbe3c7e47028cab',
        171516,
      ),
      _VictorMonoFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.normal,
        ),
        '8a09d1ce29df3b842c74c30f0a713461b80e79eea65e6b4324132df6b3f1c2c4',
        176360,
      ),
      _VictorMonoFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.italic,
        ),
        '15d91689b35fae7071c2e43dab13532dcadf3ab6a0247dff3bad899415654647',
        217468,
      ),
      _VictorMonoFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
        ),
        '7a1fe4c98c75e7a0948afe3f9f449151d30b5702c8217ef821da180e4b25e833',
        226964,
      ),
    ].fold<Map<DynamicFontsVariant, DynamicFontsFile>>(
      {},
      (acc, file) => acc..[file.variant] = file,
    ),
    eager: true,
  );
}

Iterable<String> get availableFontFamilies sync* {
  yield* _kCustomFonts;
  for (final family in GoogleFonts.asMap().keys) {
    if (_kMonospaceGoogleFontFamilies.contains(family)) {
      yield family;
    }
  }
}

// There is currently no way to filter by category. This list manually compiled from
// https://fonts.google.com/?category=Monospace
//
// TODO(aaron): Remove this pending solution to
// https://github.com/material-foundation/google-fonts-flutter/issues/112
const _kMonospaceGoogleFontFamilies = <String>{
  'Roboto Mono',
  'DM Mono',
  'Inconsolata',
  'Source Code Pro',
  'PT Mono',
  'Nanum Gothic Coding',
  'Ubuntu Mono',
  'IBM Plex Mono',
  'Cousine',
  'Share Tech Mono',
  'Anonymous Pro',
  // 'VT323',
  'Fira Mono',
  'Space Mono',
  'Overpass Mono',
  'Cutive Mono',
  'Oxygen Mono',
  'Courier Prime',
  'B612 Mono',
  'Nova Mono',
  'Fira Code',
  // 'Major Mono Display',

  // Added post-1.19.0
  'JetBrains Mono',
};

TextStyle loadFontWithVariants(String family) {
  try {
    return _loadDynamicFont(family);
  } on Exception catch (e) {
    debugPrint(e.toString());
    // debugPrint(s.toString());
  }
  try {
    return _loadGoogleFont(family);
  } on Exception {
    return _loadGoogleFont(kDefaultFontFamily);
  }
}

TextStyle _loadGoogleFont(String fontFamily) {
  // Load actual bold and italic to avoid synthetics
  //
  // You might think this would work (it *does* download all of these variants)
  // but actually each variant is registered as a separate font, so we *still*
  // get synthetic bold and italic. See
  // https://github.com/material-foundation/google-fonts-flutter/issues/35#issuecomment-959043020
  //
  // GoogleFonts.getFont(fontFamily, fontWeight: FontWeight.bold);
  // GoogleFonts.getFont(fontFamily, fontStyle: FontStyle.italic);
  // GoogleFonts.getFont(fontFamily,
  //     fontWeight: FontWeight.bold, fontStyle: FontStyle.italic);
  return GoogleFonts.getFont(fontFamily);
}

TextStyle _loadDynamicFont(String fontFamily) {
  _initCustomFonts();
  return DynamicFonts.getFont(fontFamily);
}

// Hack: Load the preferred content font in a dummy widget before it's actually
// needed. This helps prevent Flash of Unstyled Text, which in turn makes
// restoring the scroll position more accurate.
Widget fontPreloader(BuildContext context) => Text(
      '',
      style: loadFontWithVariants(
          Preferences.of(context).fontFamily ?? kDefaultFontFamily),
    );

class _FiraGoFile extends DynamicFontsFile {
  _FiraGoFile(this.variant, String expectedFileHash, int expectedLength)
      : super(expectedFileHash, expectedLength);

  static const name = 'FiraGO';
  static const version = '1001';

  final DynamicFontsVariant variant;

  String get _dir {
    switch (variant.fontStyle) {
      case FontStyle.normal:
        return 'Roman';
      case FontStyle.italic:
        return 'Italic';
    }
  }

  @override
  String get url =>
      'https://d35za8cqizqhg.cloudfront.net/assets/fonts/FiraGO_TTF_$version/$_dir/FiraGO-${variant.toApiFilenamePart()}.ttf';
}

class _IosevkaFile extends DynamicFontsFile {
  _IosevkaFile(this.variant, String expectedFileHash, int expectedLength)
      : super(expectedFileHash, expectedLength);

  static const name = 'Iosevka';
  static const version = '15.3.1';

  final DynamicFontsVariant variant;

  bool get _italic => variant.fontStyle == FontStyle.italic;

  bool get _bold => variant.fontWeight == FontWeight.bold;

  String get _variantSlug {
    if (_bold && _italic) {
      return 'bolditalic';
    } else if (_bold) {
      return 'bold';
    } else if (_italic) {
      return 'italic';
    } else {
      return 'regular';
    }
  }

  @override
  String get url =>
      'https://d35za8cqizqhg.cloudfront.net/assets/fonts/iosevka-orgro-v$version/ttf/iosevka-orgro-$_variantSlug.ttf';
}

class _VictorMonoFile extends DynamicFontsFile {
  _VictorMonoFile(this.variant, String expectedFileHash, int expectedLength)
      : super(expectedFileHash, expectedLength);

  static const name = 'Victor Mono';
  static const version = '1.5.3';

  final DynamicFontsVariant variant;

  @override
  String get url =>
      'https://d35za8cqizqhg.cloudfront.net/assets/fonts/VictorMono/$version/TTF/VictorMono-${variant.toApiFilenamePart()}.ttf';
}
