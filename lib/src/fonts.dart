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
        '389f0c93a0c5fb1279ff85a7e900254cdcd55943d0efd8d669f928a06a6997f0',
        1502864,
      ),
      _IosevkaFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.normal,
        ),
        '882d392abcd01f5fd7621c2d01c99426e340f980e6c50331e2a0f65ca5ae07f2',
        1514504,
      ),
      _IosevkaFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.italic,
        ),
        '9514fc2730678d0bbf95e132e66a82fc3658e5faf78c13bcdd66dd3249956a8a',
        1559648,
      ),
      _IosevkaFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
        ),
        '9abd41a5928c5100e42eaf911044bef4651e52d48cc94c84f0f3499b491a5228',
        1572548,
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
        '8c7f27df5824afe4d83ec4827646aef4b845e31a967bd1c2d635a7b324202054',
        163964,
      ),
      _JetBrainsMonoFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.normal,
        ),
        'd02e658030761319ede19b3438e5c2bd2deadf7947847978aea1e17b1edc72bd',
        165408,
      ),
      _JetBrainsMonoFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.italic,
        ),
        '886d1932b40c46b651a7e5ee18bcdf5674e9cd66ef14e6534c780037dbd77d9d',
        167596,
      ),
      _JetBrainsMonoFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
        ),
        '55757a65cd7775b7f3b1efae754c9029058eb3b6590d6035411312ad815f8057',
        167680,
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
      'https://d35za8cqizqhg.cloudfront.net/assets/fonts/iosevka-orgro-v4.0.0/ttf/iosevka-orgro-$_variantSlug.ttf';
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
      'https://d35za8cqizqhg.cloudfront.net/assets/fonts/JetBrainsMono/2.210/fonts/ttf/JetBrainsMono-$_variantSlug.ttf';
}
