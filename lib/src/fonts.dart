import 'package:dynamic_fonts/dynamic_fonts.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:orgro/src/preferences.dart';

const _kCustomFonts = [
  _FiraGoFile.name,
  _IosevkaFile.name,
  _JetBrainsMonoFile.name,
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
  );
  DynamicFonts.register(
    _IosevkaFile.name,
    [
      _IosevkaFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.normal,
        ),
        '0400936a2533acda366283a5005b2ae4f7f06c63847ac55e392a70f6a38e1827',
        2864548,
      ),
      _IosevkaFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.normal,
        ),
        '2406c9712439cf1abfa27bb0881fb4404ab6216d2dc6d8363f30b8c4294cdf50',
        2869892,
      ),
      _IosevkaFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.italic,
        ),
        'e28652c6c79847c00d51d1cc215125d9e73ec83ea23f6b050e5673572520859f',
        2959004,
      ),
      _IosevkaFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
        ),
        '63caee9ba55202b4ea384f474c9a5a5c5b75b272d3dc8955509e8a22e1188318',
        2972680,
      ),
    ].fold<Map<DynamicFontsVariant, DynamicFontsFile>>(
      {},
      (acc, file) => acc..[file.variant] = file,
    ),
  );
  DynamicFonts.register(
    _JetBrainsMonoFile.name,
    [
      _JetBrainsMonoFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.normal,
        ),
        '1f376439c75ab33392eb7a2f5ec999809493b378728d723327655c9fcb45cea9',
        171876,
      ),
      _JetBrainsMonoFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.normal,
        ),
        '4e350d30a649ebbaaa6dd2e38a1f38c4c5fa6692516af47be33dbeec42d58763',
        173264,
      ),
      _JetBrainsMonoFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.italic,
        ),
        'd7972492ce345c58cf8984f65e30c3ccd190738582ded5852f5083e27f3ba068',
        175656,
      ),
      _JetBrainsMonoFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
        ),
        'e6cded7e6933741aad7fc09c6db0536bea14b83b8accd5288346bd7367112f30',
        175800,
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
  static const version = '5.0.6';

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

class _JetBrainsMonoFile extends DynamicFontsFile {
  _JetBrainsMonoFile(this.variant, String expectedFileHash, int expectedLength)
      : super(expectedFileHash, expectedLength);

  static const name = 'JetBrainsMono';
  static const version = '2.225';

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
      'https://d35za8cqizqhg.cloudfront.net/assets/fonts/JetBrainsMono/$version/fonts/ttf/JetBrainsMono-$_variantSlug.ttf';
}
