import 'package:dynamic_fonts/dynamic_fonts.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:orgro/src/preferences.dart';

const _kCustomFontFiraGo = 'FiraGO';
const _kCustomFontIosevka = 'Iosevka';
const _kCustomFontJetBrainsMono = 'JetBrainsMono';
const _kCustomFonts = [
  _kCustomFontFiraGo,
  _kCustomFontIosevka,
  _kCustomFontJetBrainsMono,
];

void _initCustomFonts() {
  if (_kCustomFonts.every(DynamicFonts.asMap().containsKey)) {
    return;
  }
  DynamicFonts.register(
    _kCustomFontFiraGo,
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
  );
  DynamicFonts.register(
    _kCustomFontIosevka,
    [
      _IosevkaFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.normal,
        ),
        '3d9508aefff92c38f7ce9aa555bd0bd9ddc225addd74e02e1b80373ed4831e86',
        1105184,
      ),
      _IosevkaFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.normal,
        ),
        '105253113aed74f77f7499e6591cf9dea3c25cfde63ff631279ec87dd1542c5c',
        1115148,
      ),
      _IosevkaFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.italic,
        ),
        '35e0dd96f86db215604d277c3140882d55f30cd11fd503b38b217e4ac1ebfbde',
        1151820,
      ),
      _IosevkaFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
        ),
        '8df3b9b762c47332bb9cbdc710e78b67bfe83063287b4b15a90086f0d2789ff4',
        1160068,
      ),
    ].fold<Map<DynamicFontsVariant, DynamicFontsFile>>(
      {},
      (acc, file) => acc..[file.variant] = file,
    ),
  );
  DynamicFonts.register(
    _kCustomFontJetBrainsMono,
    [
      _JetBrainsMonoFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.normal,
        ),
        '2221c1e43699ef294f702f406964dc6a06907e80308e80e19a9027ba74570128',
        158608,
      ),
      _JetBrainsMonoFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.normal,
        ),
        '85cc17ebec56464ef286841669b62ae1c2a3b17757ab6e320861543511bd70f4',
        159796,
      ),
      _JetBrainsMonoFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.italic,
        ),
        '817b3f304b26dc1d1219a7341e680c8c19f3c2fd94e7bb9b00de6aafdca1b121',
        162016,
      ),
      _JetBrainsMonoFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
        ),
        'dc1ea64a3aa04e6781fb5b1eab214bb3876d1cb963ef80764be900e054177cf9',
        162424,
      ),
    ].fold<Map<DynamicFontsVariant, DynamicFontsFile>>(
      {},
      (acc, file) => acc..[file.variant] = file,
    ),
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
  'VT323',
  'Fira Mono',
  'Space Mono',
  'Overpass Mono',
  'Cutive Mono',
  'Oxygen Mono',
  'Courier Prime',
  'B612 Mono',
  'Nova Mono',
  'Fira Code',
  'Major Mono Display'
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
  GoogleFonts.getFont(fontFamily, fontWeight: FontWeight.bold);
  GoogleFonts.getFont(fontFamily, fontStyle: FontStyle.italic);
  GoogleFonts.getFont(fontFamily,
      fontWeight: FontWeight.bold, fontStyle: FontStyle.italic);
  return GoogleFonts.getFont(fontFamily);
}

TextStyle _loadDynamicFont(String fontFamily) {
  _initCustomFonts();
  // Load actual bold and italic to avoid synthetics
  DynamicFonts.getFont(fontFamily, fontWeight: FontWeight.bold);
  DynamicFonts.getFont(fontFamily, fontStyle: FontStyle.italic);
  DynamicFonts.getFont(fontFamily,
      fontWeight: FontWeight.bold, fontStyle: FontStyle.italic);
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

  final DynamicFontsVariant variant;

  String get _dir {
    switch (variant.fontStyle) {
      case FontStyle.normal:
        return 'Roman';
      case FontStyle.italic:
        return 'Italic';
    }
    throw Exception('Unknown style: ${variant.fontStyle}');
  }

  @override
  String get url =>
      'https://d35za8cqizqhg.cloudfront.net/assets/fonts/FiraGO_TTF_1001/$_dir/FiraGO-${variant.toApiFilenamePart()}.ttf';
}

class _IosevkaFile extends DynamicFontsFile {
  _IosevkaFile(this.variant, String expectedFileHash, int expectedLength)
      : super(expectedFileHash, expectedLength);

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
      'https://d35za8cqizqhg.cloudfront.net/assets/fonts/iosevka-orgro-v3.5.0/ttf/iosevka-orgro-$_variantSlug.ttf';
}

class _JetBrainsMonoFile extends DynamicFontsFile {
  _JetBrainsMonoFile(this.variant, String expectedFileHash, int expectedLength)
      : super(expectedFileHash, expectedLength);

  final DynamicFontsVariant variant;

  bool get _italic => variant.fontStyle == FontStyle.italic;

  bool get _bold => variant.fontWeight == FontWeight.bold;

  String get _variantSlug {
    if (_bold && _italic) {
      return 'BoldItalic';
    } else if (_bold) {
      return 'Bold';
    } else if (_italic) {
      return 'Italic';
    } else {
      return 'Regular';
    }
  }

  @override
  String get url =>
      'https://d35za8cqizqhg.cloudfront.net/assets/fonts/JetBrainsMono/2.200/fonts/ttf/JetBrainsMono-$_variantSlug.ttf';
}
