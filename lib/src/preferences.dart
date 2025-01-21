import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orgro/src/components/recent_files.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/error.dart';
import 'package:orgro/src/file_picker.dart';
import 'package:orgro/src/pages/pages.dart';
import 'package:orgro/src/util.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum RemoteImagesPolicy { allow, deny, ask }

enum LocalLinksPolicy { deny, ask }

enum SaveChangesPolicy { allow, deny, ask }

enum DecryptPolicy { deny, ask }

const kDefaultFontFamily = 'Fira Code';
const kDefaultTextScale = 1.0;
const String? kDefaultQueryString = null;
const kDefaultFilterKeywords = <String>[];
const kDefaultFilterTags = <String>[];
const kDefaultFilterPriorities = <String>[];
const kDefaultCustomFilter = '';
const kDefaultReaderMode = false;
const kDefaultRemoteImagesPolicy = RemoteImagesPolicy.ask;
const kDefaultLocalLinksPolicy = LocalLinksPolicy.ask;
const kDefaultSaveChangesPolicy = SaveChangesPolicy.ask;
const kDefaultDecryptPolicy = DecryptPolicy.ask;
const kDefaultFullWidth = false;
const kDefaultScopedPreferences = <String, dynamic>{};

const kMaxRecentFiles = 10;

const kFontFamilyKey = 'font_family';
const kTextScaleKey = 'text_scale';
const kReaderModeKey = 'reader_mode';
const kRemoteImagesPolicyKey = 'remote_images_policy';
const kLocalLinksPolicyKey = 'local_links_policy';
const kSaveChangesPolicyKey = 'save_changes_policy';
const kDecryptPolicyKey = 'decrypt_policy';
const kRecentFilesJsonKey = 'recent_files_json';
const kAccessibleDirectoriesKey = 'accessible_directories_json';
const kCustomFilterQueriesKey = 'custom_filter_queries_json';
const kFullWidthKey = 'full_width';
const kScopedPreferencesJsonKey = 'scoped_preferences';

const kThemeModeKey = 'theme_mode';

class SharedPreferencesProvider extends StatefulWidget {
  const SharedPreferencesProvider(
      {required this.child, this.waiting, super.key});
  final Widget child;
  final Widget? waiting;

  @override
  State<SharedPreferencesProvider> createState() =>
      _SharedPreferencesProviderState();
}

class _SharedPreferencesProviderState extends State<SharedPreferencesProvider> {
  late final Future<SharedPreferences> _instance;

  @override
  void initState() {
    super.initState();
    _instance = SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: _instance,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Preferences(prefs: snapshot.data!, child: widget.child);
        } else if (snapshot.hasError) {
          return ErrorPage(error: snapshot.error.toString());
        } else {
          return widget.waiting ?? const SizedBox.shrink();
        }
      },
    );
  }
}

class Preferences extends StatefulWidget {
  static InheritedPreferences of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InheritedPreferences>()!;

  const Preferences({required this.prefs, required this.child, super.key});

  final Widget child;
  final SharedPreferences prefs;

  @override
  State<Preferences> createState() => _PreferencesState();
}

class _PreferencesState extends State<Preferences> {
  late PreferencesData _data;

  @override
  void initState() {
    super.initState();
    _data = PreferencesData.fromSharedPreferences(widget.prefs);
  }

  void _update(PreferencesData Function(PreferencesData) transform) =>
      setState(() => _data = transform(_data));

  @override
  Widget build(BuildContext context) {
    return InheritedPreferences(
      _data,
      _update,
      widget.prefs,
      child: widget.child,
    );
  }
}

class InheritedPreferences extends InheritedWidget {
  const InheritedPreferences(this.data, this._update, this._prefs,
      {required super.child, super.key});

  final PreferencesData data;
  final SharedPreferences _prefs;
  final void Function(PreferencesData Function(PreferencesData)) _update;

  @override
  bool updateShouldNotify(InheritedPreferences oldWidget) =>
      data != oldWidget.data;

  Future<void> reload() async {
    await _prefs.reload();
    _update((_) => PreferencesData.fromSharedPreferences(_prefs));
  }

  Future<void> reset() async {
    for (final dir in accessibleDirs) {
      try {
        await disposeNativeSourceIdentifier(dir);
      } catch (e, s) {
        logError(e, s);
      }
    }
    await _prefs.clear();
    _update((_) => PreferencesData.fromSharedPreferences(_prefs));
  }

  double get textScale => data.textScale;
  Future<bool> setTextScale(double value) async {
    _update((data) => data.copyWith(textScale: value));
    return await _setOrRemove(kTextScaleKey, value);
  }

  String get fontFamily => data.fontFamily;
  Future<bool> setFontFamily(String value) async {
    _update((data) => data.copyWith(fontFamily: value));
    return _setOrRemove(kFontFamilyKey, value);
  }

  bool get readerMode => data.readerMode;
  Future<bool> setReaderMode(bool value) async {
    _update((data) => data.copyWith(readerMode: value));
    return _setOrRemove(kReaderModeKey, value);
  }

  List<RecentFile> get recentFiles => data.recentFiles;
  Future<bool> _setRecentFiles(List<RecentFile> value) async {
    _update((data) => data.copyWith(recentFiles: value));
    return _setOrRemove(
      kRecentFilesJsonKey,
      value.map((file) => json.encode(file.toJson())).toList(),
    );
  }

  Future<bool> addRecentFile(RecentFile file) async {
    final files = [file, ...recentFiles]
        .unique(
          cache: LinkedHashSet(
            equals: (a, b) => a.uri == b.uri,
            hashCode: (o) => o.uri.hashCode,
          ),
        )
        .take(kMaxRecentFiles)
        .toList(growable: false);
    return await _setRecentFiles(files);
  }

  Future<bool> removeRecentFile(RecentFile file) async {
    final files = List.of(recentFiles)..remove(file);
    return await _setRecentFiles(files);
  }

  ThemeMode get themeMode => data.themeMode;
  Future<bool> setThemeMode(ThemeMode value) async {
    _update((data) => data.copyWith(themeMode: value));
    return _setOrRemove(kThemeModeKey, value.persistableString);
  }

  RemoteImagesPolicy get remoteImagesPolicy => data.remoteImagesPolicy;
  Future<bool> setRemoteImagesPolicy(RemoteImagesPolicy value) async {
    _update((data) => data.copyWith(remoteImagesPolicy: value));
    return _setOrRemove(kRemoteImagesPolicyKey, value.persistableString);
  }

  LocalLinksPolicy get localLinksPolicy => data.localLinksPolicy;
  Future<bool> setLocalLinksPolicy(LocalLinksPolicy value) async {
    _update((data) => data.copyWith(localLinksPolicy: value));
    return _setOrRemove(kLocalLinksPolicyKey, value.persistableString);
  }

  SaveChangesPolicy get saveChangesPolicy => data.saveChangesPolicy;
  Future<bool> setSaveChangesPolicy(SaveChangesPolicy value) async {
    _update((data) => data.copyWith(saveChangesPolicy: value));
    return _setOrRemove(kSaveChangesPolicyKey, value.persistableString);
  }

  DecryptPolicy get decryptPolicy => data.decryptPolicy;
  Future<bool> setDecryptPolicy(DecryptPolicy value) async {
    _update((data) => data.copyWith(decryptPolicy: value));
    return _setOrRemove(kDecryptPolicyKey, value.persistableString);
  }

  List<String> get accessibleDirs => data.accessibleDirs;
  Future<bool> _setAccessibleDirs(List<String> value) async {
    _update((data) => data.copyWith(accessibleDirs: value));
    return _setOrRemove(kAccessibleDirectoriesKey, value);
  }

  Future<bool> addAccessibleDir(String dir) async {
    final dirs = [...accessibleDirs, dir].unique().toList(growable: false);
    return await _setAccessibleDirs(dirs);
  }

  List<String> get customFilterQueries => data.customFilterQueries;
  Future<bool> _setCustomFilterQueries(List<String> value) async {
    _update((data) => data.copyWith(customFilterQueries: value));
    return _setOrRemove(kCustomFilterQueriesKey, value);
  }

  Future<bool> addCustomFilterQuery(String value) async {
    // Maintain order, so don't just prepend and uniquify
    if (!customFilterQueries.contains(value)) {
      return await _setCustomFilterQueries(
          [value, ...customFilterQueries.take(9)]);
    }
    return true;
  }

  bool get fullWidth => data.fullWidth;
  Future<bool> setFullWidth(bool value) async {
    _update((data) => data.copyWith(fullWidth: value));
    return _setOrRemove(kFullWidthKey, value);
  }

  Map<String, dynamic> get scopedPreferences => data.scopedPreferences;
  Future<bool> setScopedPreferences(Map<String, dynamic> value) async {
    _update((data) => data.copyWith(scopedPreferences: value));
    return _setOrRemove(kScopedPreferencesJsonKey, json.encode(value));
  }

  Future<bool> _setOrRemove<T>(String key, T? value) {
    if (value == null) {
      return _prefs.remove(key);
    } else if (value is String) {
      return _prefs.setString(key, value);
    } else if (value is bool) {
      return _prefs.setBool(key, value);
    } else if (value is double) {
      return _prefs.setDouble(key, value);
    } else if (value is List<String>) {
      return _prefs.setStringList(key, value);
    } else {
      throw OrgroError(
        'Unknown type: $T',
        localizedMessage: (context) =>
            AppLocalizations.of(context)!.errorUnknownType(T),
      );
    }
  }
}

class PreferencesData {
  factory PreferencesData.defaults() => const PreferencesData(
        textScale: kDefaultTextScale,
        fontFamily: kDefaultFontFamily,
        readerMode: kDefaultReaderMode,
        recentFiles: [],
        themeMode: _kDefaultThemeMode,
        remoteImagesPolicy: kDefaultRemoteImagesPolicy,
        localLinksPolicy: kDefaultLocalLinksPolicy,
        saveChangesPolicy: kDefaultSaveChangesPolicy,
        decryptPolicy: kDefaultDecryptPolicy,
        accessibleDirs: [],
        customFilterQueries: [],
        fullWidth: kDefaultFullWidth,
        scopedPreferences: {},
      );

  factory PreferencesData.fromSharedPreferences(SharedPreferences prefs) {
    final scopedPreferencesJson = prefs.getString(kScopedPreferencesJsonKey);
    final scopedPreferences = scopedPreferencesJson == null
        ? null
        : json.decode(scopedPreferencesJson) as Map<String, dynamic>;
    return PreferencesData.defaults().copyWith(
      textScale: prefs.getDouble(kTextScaleKey),
      fontFamily: prefs.getString(kFontFamilyKey),
      readerMode: prefs.getBool(kReaderModeKey),
      recentFiles: prefs
          .getStringList(kRecentFilesJsonKey)
          ?.map<dynamic>(json.decode)
          .cast<Map<String, dynamic>>()
          .map((json) => RecentFile.fromJson(json))
          .toList(growable: false),
      themeMode:
          ThemeModePersistence.fromString(prefs.getString(kThemeModeKey)),
      remoteImagesPolicy: RemoteImagesPolicyPersistence.fromString(
          prefs.getString(kRemoteImagesPolicyKey)),
      localLinksPolicy: LocalLinksPolicyPersistence.fromString(
          prefs.getString(kLocalLinksPolicyKey)),
      saveChangesPolicy: SaveChangesPolicyPersistence.fromString(
          prefs.getString(kSaveChangesPolicyKey)),
      decryptPolicy: DecryptPolicyPersistence.fromString(
          prefs.getString(kDecryptPolicyKey)),
      accessibleDirs: prefs.getStringList(kAccessibleDirectoriesKey),
      customFilterQueries: prefs.getStringList(kCustomFilterQueriesKey),
      fullWidth: prefs.getBool(kFullWidthKey),
      scopedPreferences: scopedPreferences,
    );
  }

  const PreferencesData({
    required this.textScale,
    required this.fontFamily,
    required this.readerMode,
    required this.recentFiles,
    required this.themeMode,
    required this.remoteImagesPolicy,
    required this.localLinksPolicy,
    required this.saveChangesPolicy,
    required this.decryptPolicy,
    required this.accessibleDirs,
    required this.customFilterQueries,
    required this.fullWidth,
    required this.scopedPreferences,
  });

  final double textScale;
  final String fontFamily;
  final bool readerMode;
  final List<RecentFile> recentFiles;
  final ThemeMode themeMode;
  final RemoteImagesPolicy remoteImagesPolicy;
  final LocalLinksPolicy localLinksPolicy;
  final SaveChangesPolicy saveChangesPolicy;
  final DecryptPolicy decryptPolicy;
  final List<String> accessibleDirs;
  final List<String> customFilterQueries;
  final bool fullWidth;
  final Map<String, dynamic> scopedPreferences;

  PreferencesData copyWith({
    double? textScale,
    String? fontFamily,
    bool? readerMode,
    List<RecentFile>? recentFiles,
    ThemeMode? themeMode,
    RemoteImagesPolicy? remoteImagesPolicy,
    LocalLinksPolicy? localLinksPolicy,
    SaveChangesPolicy? saveChangesPolicy,
    DecryptPolicy? decryptPolicy,
    List<String>? accessibleDirs,
    List<String>? customFilterQueries,
    bool? fullWidth,
    Map<String, dynamic>? scopedPreferences,
  }) =>
      PreferencesData(
        textScale: textScale ?? this.textScale,
        fontFamily: fontFamily ?? this.fontFamily,
        readerMode: readerMode ?? this.readerMode,
        recentFiles: recentFiles ?? this.recentFiles,
        themeMode: themeMode ?? this.themeMode,
        remoteImagesPolicy: remoteImagesPolicy ?? this.remoteImagesPolicy,
        localLinksPolicy: localLinksPolicy ?? this.localLinksPolicy,
        saveChangesPolicy: saveChangesPolicy ?? this.saveChangesPolicy,
        decryptPolicy: decryptPolicy ?? this.decryptPolicy,
        accessibleDirs: accessibleDirs ?? this.accessibleDirs,
        customFilterQueries: customFilterQueries ?? this.customFilterQueries,
        fullWidth: fullWidth ?? this.fullWidth,
        scopedPreferences: scopedPreferences ?? this.scopedPreferences,
      );

  @override
  bool operator ==(Object other) =>
      other is PreferencesData &&
      textScale == other.textScale &&
      fontFamily == other.fontFamily &&
      readerMode == other.readerMode &&
      listEquals(recentFiles, other.recentFiles) &&
      themeMode == other.themeMode &&
      remoteImagesPolicy == other.remoteImagesPolicy &&
      localLinksPolicy == other.localLinksPolicy &&
      saveChangesPolicy == other.saveChangesPolicy &&
      decryptPolicy == other.decryptPolicy &&
      listEquals(accessibleDirs, other.accessibleDirs) &&
      listEquals(customFilterQueries, other.customFilterQueries) &&
      fullWidth == other.fullWidth &&
      mapEquals(scopedPreferences, other.scopedPreferences);

  @override
  int get hashCode => Object.hash(
        textScale,
        fontFamily,
        readerMode,
        Object.hashAll(recentFiles),
        themeMode,
        remoteImagesPolicy,
        localLinksPolicy,
        saveChangesPolicy,
        decryptPolicy,
        Object.hashAll(accessibleDirs),
        Object.hashAll(customFilterQueries),
        fullWidth,
        Object.hashAll(scopedPreferences.keys),
        Object.hashAll(scopedPreferences.values),
      );
}

extension RemoteImagesPolicyPersistence on RemoteImagesPolicy? {
  static RemoteImagesPolicy? fromString(String? value) {
    switch (value) {
      case _kRemoteImagesPolicyAllow:
        return RemoteImagesPolicy.allow;
      case _kRemoteImagesPolicyDeny:
        return RemoteImagesPolicy.deny;
      case _kRemoteImagesPolicyAsk:
        return RemoteImagesPolicy.ask;
    }
    return null;
  }

  String? get persistableString => switch (this) {
        RemoteImagesPolicy.allow => _kRemoteImagesPolicyAllow,
        RemoteImagesPolicy.deny => _kRemoteImagesPolicyDeny,
        RemoteImagesPolicy.ask => _kRemoteImagesPolicyAsk,
        null => null,
      };
}

const _kRemoteImagesPolicyAllow = 'remote_images_policy_allow';
const _kRemoteImagesPolicyDeny = 'remote_images_policy_deny';
const _kRemoteImagesPolicyAsk = 'remote_images_policy_ask';

extension LocalLinksPolicyPersistence on LocalLinksPolicy? {
  static LocalLinksPolicy? fromString(String? value) {
    switch (value) {
      case _kLocalLinksPolicyDeny:
        return LocalLinksPolicy.deny;
      case _kLocalLinksPolicyAsk:
        return LocalLinksPolicy.ask;
    }
    return null;
  }

  String? get persistableString => switch (this) {
        LocalLinksPolicy.deny => _kLocalLinksPolicyDeny,
        LocalLinksPolicy.ask => _kLocalLinksPolicyAsk,
        null => null,
      };
}

const _kLocalLinksPolicyDeny = 'remote_images_policy_deny';
const _kLocalLinksPolicyAsk = 'remote_images_policy_ask';

extension SaveChangesPolicyPersistence on SaveChangesPolicy? {
  static SaveChangesPolicy? fromString(String? value) {
    switch (value) {
      case _kSaveChangesPolicyAllow:
        return SaveChangesPolicy.allow;
      case _kSaveChangesPolicyDeny:
        return SaveChangesPolicy.deny;
      case _kSaveChangesPolicyAsk:
        return SaveChangesPolicy.ask;
    }
    return null;
  }

  String? get persistableString => switch (this) {
        SaveChangesPolicy.allow => _kSaveChangesPolicyAllow,
        SaveChangesPolicy.deny => _kSaveChangesPolicyDeny,
        SaveChangesPolicy.ask => _kSaveChangesPolicyAsk,
        null => null
      };
}

const _kSaveChangesPolicyAllow = 'save_changes_policy_allow';
const _kSaveChangesPolicyDeny = 'save_changes_policy_deny';
const _kSaveChangesPolicyAsk = 'save_changes_policy_ask';

extension DecryptPolicyPersistence on DecryptPolicy? {
  static DecryptPolicy? fromString(String? value) {
    switch (value) {
      case _kDecryptPolicyDeny:
        return DecryptPolicy.deny;
      case _kDecryptPolicyAsk:
        return DecryptPolicy.ask;
    }
    return null;
  }

  String? get persistableString => switch (this) {
        DecryptPolicy.deny => _kDecryptPolicyDeny,
        DecryptPolicy.ask => _kDecryptPolicyAsk,
        null => null,
      };
}

const _kDecryptPolicyDeny = 'decrypt_policy_deny';
const _kDecryptPolicyAsk = 'decrypt_policy_ask';

extension ThemeModePersistence on ThemeMode? {
  String? get persistableString => switch (this) {
        ThemeMode.system => _kThemeModeSystem,
        ThemeMode.light => _kThemeModeLight,
        ThemeMode.dark => _kThemeModeDark,
        null => null
      };

  static ThemeMode? fromString(String? value) {
    switch (value) {
      case _kThemeModeSystem:
        return ThemeMode.system;
      case _kThemeModeLight:
        return ThemeMode.light;
      case _kThemeModeDark:
        return ThemeMode.dark;
    }
    return null;
  }
}

const _kThemeModeSystem = 'theme_mode_system';
const _kThemeModeLight = 'theme_mode_light';
const _kThemeModeDark = 'theme_mode_dark';

const _kDefaultThemeMode = ThemeMode.system;

Future<void> resetPreferences(BuildContext context) async {
  final prefs = Preferences.of(context);
  await prefs.reset();
}
