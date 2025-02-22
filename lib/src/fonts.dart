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
  _TerminusFile.name,
  _CascadiaCodeFile.name,
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
        '87c0918d66f2497e71754629f7c20a338e1e64fa1cae049b7dc8f2e962b78849',
        8485064,
      ),
      _IosevkaFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.normal,
        ),
        '07478ec3802aba626b3b5486eefc59a7228df4709ace8da52f922de540a36c0b',
        8458740,
      ),
      _IosevkaFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.italic,
        ),
        '554bebafb3be456a81b863681f72e65d2419498b61ad136d81b5f7d9518c2bf5',
        8815160,
      ),
      _IosevkaFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
        ),
        'b7582f0f1c7a1aa9a927ab25bb8e4b8e09235e9357773d2116bfdd01c2eacf09',
        8818280,
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
        '1af31bba86bd438a7aa5cd072db4e8ec9c36d20e2ed3f34e664b6a2bf37b3633',
        201740,
      ),
      _VictorMonoFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.normal,
        ),
        '4efe29edefdf765d14e9ccdb045918911613f2a33e26949194fa77d52db2f5cc',
        207184,
      ),
      _VictorMonoFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.italic,
        ),
        '39a2d5cbb5396b9f88878d482b442f24e4fbad59f09973ba9a91179d87a16b18',
        245568,
      ),
      _VictorMonoFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
        ),
        'b424d02260bd70bc858024f5e1f425dc6cf2fb1dba285bf9f74d727b1d83b5d9',
        256064,
      ),
    ].fold<Map<DynamicFontsVariant, DynamicFontsFile>>(
      {},
      (acc, file) => acc..[file.variant] = file,
    ),
    eager: true,
  );
  DynamicFonts.register(
    _TerminusFile.name,
    [
      _TerminusFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.normal,
        ),
        'f668ad7884635e112bcfa2ced6ccb9550128f643bf539cb049bd90bd8afbf4b3',
        500668,
      ),
      _TerminusFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.normal,
        ),
        '6be22b2f690c54a848da85cbbb2461843105214ef74f4a71ba139fbeecb25ef5',
        500572,
      ),
      _TerminusFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.italic,
        ),
        '525ee0ced02939f1a0eedb7f56be5328d255aa49d96cd5bc48070b6d276585c2',
        525996,
      ),
      _TerminusFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
        ),
        '115392036be665973d8dae3038708ce173f14af6b1888bdf3817961c23535be6',
        546696,
      ),
    ].fold<Map<DynamicFontsVariant, DynamicFontsFile>>(
      {},
      (acc, file) => acc..[file.variant] = file,
    ),
    eager: true,
  );
  DynamicFonts.register(
    _CascadiaCodeFile.name,
    [
      _CascadiaCodeFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.normal,
        ),
        '0ae311a93c046a346150b828f70075a2ef7d45f70f7d39708cc930c2a514255b',
        600344,
      ),
      _CascadiaCodeFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.normal,
        ),
        '7ab1792ff3173242b08f903bf4183155af47f87d91352d7bb4f9b8dd477e632d',
        606984,
      ),
      _CascadiaCodeFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.italic,
        ),
        '006e3251e8047c14e21bca50ef7265e3501aedacc28a6c8a3690b9ce03dbd422',
        453188,
      ),
      _CascadiaCodeFile(
        const DynamicFontsVariant(
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
        ),
        'f76f1376ceab64953019645bde803879a800f928c7aace8d14827555808b4dc1',
        458624,
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
  'Azeret Mono',
  'Chivo Mono',
  'Fragment Mono',
  'Martian Mono',
  'Noto Sans Mono',
  'Red Hat Mono',
  'Spline Sans Mono',
  // 'Syne Mono',
  // 'Xanh Mono',

  // By user request
  'Roboto Slab',
  'Merriweather',
  'PT Serif',

  // https://github.com/amake/orgro/issues/113
  'M PLUS 1 Code',
  'Noto Sans SC',
  'Noto Sans TC',
  // Korean represented by Nanum Gothic Coding
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
    Preferences.of(context, PrefsAspect.viewSettings).fontFamily,
  ),
);

class _FiraGoFile extends DynamicFontsFile {
  _FiraGoFile(this.variant, String expectedFileHash, int expectedLength)
    : super(expectedFileHash, expectedLength);

  static const name = 'FiraGO';
  static const version = '1001';

  final DynamicFontsVariant variant;

  String get _dir => switch (variant.fontStyle) {
    FontStyle.normal => 'Roman',
    FontStyle.italic => 'Italic',
  };

  @override
  String get url =>
      'https://cdn.orgro.org/assets/fonts/FiraGO_TTF_$version/$_dir/FiraGO-${variant.toApiFilenamePart()}.ttf';
}

class _IosevkaFile extends DynamicFontsFile {
  _IosevkaFile(this.variant, String expectedFileHash, int expectedLength)
    : super(expectedFileHash, expectedLength);

  static const name = 'Iosevka';
  static const version = '32.3.1';

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
      'https://cdn.orgro.org/assets/fonts/iosevka-orgro-v$version/TTF/IosevkaOrgro-$_variantSlug.ttf';
}

class _VictorMonoFile extends DynamicFontsFile {
  _VictorMonoFile(this.variant, String expectedFileHash, int expectedLength)
    : super(expectedFileHash, expectedLength);

  static const name = 'Victor Mono';
  static const version = '1.5.6';

  final DynamicFontsVariant variant;

  @override
  String get url =>
      'https://cdn.orgro.org/assets/fonts/VictorMono/$version/TTF/VictorMono-${variant.toApiFilenamePart()}.ttf';
}

class _TerminusFile extends DynamicFontsFile {
  _TerminusFile(this.variant, String expectedFileHash, int expectedLength)
    : super(expectedFileHash, expectedLength);

  static const name = 'Terminus';
  static const version = '4.49.3';

  final DynamicFontsVariant variant;

  bool get _italic => variant.fontStyle == FontStyle.italic;

  bool get _bold => variant.fontWeight == FontWeight.bold;

  String get _variantSlug {
    if (_bold && _italic) {
      return 'Bold-Italic-';
    } else if (_bold) {
      return 'Bold-';
    } else if (_italic) {
      return 'Italic-';
    } else {
      return '';
    }
  }

  @override
  String get url =>
      'https://cdn.orgro.org/assets/fonts/Terminus/terminus-ttf-$version/TerminusTTF-$_variantSlug$version.ttf';
}

class _CascadiaCodeFile extends DynamicFontsFile {
  _CascadiaCodeFile(this.variant, String expectedFileHash, int expectedLength)
    : super(expectedFileHash, expectedLength);

  static const name = 'Cascadia Code';
  static const version = '2404.23';

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
      'https://cdn.orgro.org/assets/fonts/CascadiaCode/$version/ttf/static/CascadiaCode-$_variantSlug.ttf';
}
