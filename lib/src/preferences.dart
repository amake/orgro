import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:orgro/l10n/app_localizations.dart';
import 'package:orgro/src/components/dialogs.dart';
import 'package:orgro/src/components/remembered_files.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/error.dart';
import 'package:orgro/src/file_picker.dart';
import 'package:orgro/src/util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences/util/legacy_to_async_migration_util.dart';

enum RemoteImagesPolicy { allow, deny, ask }

enum LocalLinksPolicy { deny, ask }

enum SaveChangesPolicy { allow, deny, ask }

enum DecryptPolicy { deny, ask }

enum SortOrder { ascending, descending }

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
const kDefaultTextPreviewString =
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.';
const kDefaultRecentFilesSortKey = RecentFilesSortKey.lastOpened;
const kDefaultRecentFilesSortOrder = SortOrder.descending;

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
const kTextPreviewStringKey = 'text_preview_string';
const kThemeModeKey = 'theme_mode';
const kRecentFilesSortKey = 'recent_files_sort_key';
const kRecentFilesSortOrder = 'recent_files_sort_order';

const _kMigrationCompletedKey = 'migration_completed_key';

class Preferences extends StatefulWidget {
  static InheritedPreferences of(BuildContext context, [PrefsAspect? aspect]) =>
      InheritedModel.inheritFrom<InheritedPreferences>(
        context,
        aspect: aspect,
      )!;

  const Preferences({required this.child, super.key});

  final Widget child;

  @override
  State<Preferences> createState() => _PreferencesState();
}

class _PreferencesState extends State<Preferences> {
  final _prefs = SharedPreferencesAsync();
  var _inited = false;
  var _data = PreferencesData.defaults();

  @override
  void initState() {
    super.initState();
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    await time('prefs migration', _doMigration);
    final data = await time(
      'prefs load',
      () => PreferencesData.fromSharedPreferences(_prefs),
    );
    setState(() {
      _data = data;
      _inited = true;
    });
  }

  Future<void> _doMigration() async {
    if (await _prefs.containsKey(_kMigrationCompletedKey)) {
      // Simply instantiating the legacy instance forces a read of all data, so
      // we avoid by doing the same check as the migration function does
      // internally.
      return;
    }
    final legacyInstance = await SharedPreferences.getInstance();
    await migrateLegacySharedPreferencesToSharedPreferencesAsyncIfNecessary(
      legacySharedPreferencesInstance: legacyInstance,
      sharedPreferencesAsyncOptions: SharedPreferencesOptions(),
      migrationCompletedKey: _kMigrationCompletedKey,
    );
    debugPrint('Migration completed successfully');
  }

  void _update(PreferencesData Function(PreferencesData) transform) =>
      setState(() => _data = transform(_data));

  @override
  Widget build(BuildContext context) {
    return InheritedPreferences(
      _data,
      _inited,
      _update,
      _prefs,
      child: widget.child,
    );
  }
}

enum PrefsAspect {
  init,
  appearance,
  recentFiles,
  viewSettings,
  accessibleDirs,
  customFilterQueries,
  customization,
  // For uses where a value is written but not read
  nil,
}

class InheritedPreferences extends InheritedModel<PrefsAspect> {
  const InheritedPreferences(
    this.data,
    this.isInitialized,
    this._update,
    this._prefs, {
    required super.child,
    super.key,
  });

  final PreferencesData data;
  final bool isInitialized;
  final SharedPreferencesAsync _prefs;
  final void Function(PreferencesData Function(PreferencesData)) _update;

  @override
  bool updateShouldNotify(InheritedPreferences oldWidget) =>
      isInitialized != oldWidget.isInitialized || data != oldWidget.data;

  @override
  bool updateShouldNotifyDependent(
    InheritedPreferences oldWidget,
    Set<PrefsAspect> dependencies,
  ) =>
      _updateShouldNotifyDependentInit(oldWidget, dependencies) ||
      _updateShouldNotifyDependentAppearance(oldWidget, dependencies) ||
      _updateShouldNotifyDependentRecentFiles(oldWidget, dependencies) ||
      _updateShouldNotifyDependentViewSettings(oldWidget, dependencies) ||
      _updateShouldNotifyDependentAccessibleDirectories(
        oldWidget,
        dependencies,
      ) ||
      _updateShouldNotifyDependentCustomFilterQueries(
        oldWidget,
        dependencies,
      ) ||
      _updateShouldNotifyDependentCustomization(oldWidget, dependencies);

  Future<void> reload() async {
    final reloaded = await PreferencesData.fromSharedPreferences(_prefs);
    _update((_) => reloaded);
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
    final cleared = await PreferencesData.fromSharedPreferences(_prefs);
    _update((_) => cleared);
  }

  Future<void> _setOrRemove<T>(String key, T? value) {
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
        localizedMessage:
            (context) => AppLocalizations.of(context)!.errorUnknownType(T),
      );
    }
  }
}

extension InitExt on InheritedPreferences {
  bool _updateShouldNotifyDependentInit(
    InheritedPreferences oldWidget,
    Set<PrefsAspect> dependencies,
  ) =>
      dependencies.contains(PrefsAspect.init) &&
      isInitialized != oldWidget.isInitialized;
}

extension AppearanceExt on InheritedPreferences {
  ThemeMode get themeMode => data.themeMode;
  Future<void> setThemeMode(ThemeMode value) async {
    _update((data) => data.copyWith(themeMode: value));
    return _setOrRemove(kThemeModeKey, value.persistableString);
  }

  bool _updateShouldNotifyDependentAppearance(
    InheritedPreferences oldWidget,
    Set<PrefsAspect> dependencies,
  ) =>
      dependencies.contains(PrefsAspect.appearance) &&
      data.themeMode != oldWidget.data.themeMode;
}

extension RecentFilesExt on InheritedPreferences {
  List<RememberedFile> get rememberedFiles => data.recentFiles;
  Future<void> _setRecentFiles(List<RememberedFile> value) async {
    _update((data) => data.copyWith(recentFiles: value));
    return _setOrRemove(
      kRecentFilesJsonKey,
      value.map((file) => json.encode(file.toJson())).toList(),
    );
  }

  Future<void> addRecentFiles(List<RememberedFile> files) async {
    final sortedFiles = [...files, ...rememberedFiles]
      ..sort((a, b) => -a.isPinned.compareTo(b.isPinned));
    final uniqueFiles = sortedFiles
        .unique(
          cache: LinkedHashSet(
            equals: (a, b) => a.uri == b.uri,
            hashCode: (o) => o.uri.hashCode,
          ),
        )
        .toList(growable: false);
    final retained = [
      ...uniqueFiles.where((f) => f.isPinned),
      ...uniqueFiles.where((f) => f.isNotPinned).take(kMaxRecentFiles),
    ];
    return await _setRecentFiles(retained);
  }

  Future<void> removeRecentFile(RememberedFile file) async {
    final files = List.of(rememberedFiles)..remove(file);
    return await _setRecentFiles(files);
  }

  Future<void> pinFile(RememberedFile file) async {
    final pinnedIdx = rememberedFiles.where((f) => f.isPinned).length;
    final files = rememberedFiles
        .map((f) => f.uri == file.uri ? file.copyWith(pinnedIdx: pinnedIdx) : f)
        .toList(growable: false)
      ..sort((a, b) => -a.isPinned.compareTo(b.isPinned));
    return await _setRecentFiles(files);
  }

  Future<void> unpinFile(RememberedFile file) async {
    final files = rememberedFiles
        .map((f) => f.uri == file.uri ? file.copyWith(pinnedIdx: -1) : f)
        .toList(growable: false)
      ..sort((a, b) => -a.isPinned.compareTo(b.isPinned));
    return await _setRecentFiles(files);
  }

  RecentFilesSortKey get recentFilesSortKey => data.recentFilesSortKey;
  Future<void> setRecentFilesSortKey(RecentFilesSortKey value) async {
    _update((data) => data.copyWith(recentFilesSortKey: value));
    return await _setOrRemove(kRecentFilesSortKey, value.persistableString);
  }

  SortOrder get recentFilesSortOrder => data.recentFilesSortOrder;
  Future<void> setRecentFilesSortOrder(SortOrder value) async {
    _update((data) => data.copyWith(recentFilesSortOrder: value));
    return await _setOrRemove(kRecentFilesSortOrder, value.persistableString);
  }

  bool _updateShouldNotifyDependentRecentFiles(
    InheritedPreferences oldWidget,
    Set<PrefsAspect> dependencies,
  ) =>
      dependencies.contains(PrefsAspect.recentFiles) &&
          !listEquals(data.recentFiles, oldWidget.data.recentFiles) ||
      data.recentFilesSortKey != oldWidget.data.recentFilesSortKey ||
      data.recentFilesSortOrder != oldWidget.data.recentFilesSortOrder;
}

extension ViewSettingsExt on InheritedPreferences {
  double get textScale => data.textScale;
  Future<void> setTextScale(double value) async {
    _update((data) => data.copyWith(textScale: value));
    return await _setOrRemove(kTextScaleKey, value);
  }

  String get fontFamily => data.fontFamily;
  Future<void> setFontFamily(String value) async {
    _update((data) => data.copyWith(fontFamily: value));
    return _setOrRemove(kFontFamilyKey, value);
  }

  bool get readerMode => data.readerMode;
  Future<void> setReaderMode(bool value) async {
    _update((data) => data.copyWith(readerMode: value));
    return _setOrRemove(kReaderModeKey, value);
  }

  RemoteImagesPolicy get remoteImagesPolicy => data.remoteImagesPolicy;
  Future<void> setRemoteImagesPolicy(RemoteImagesPolicy value) async {
    _update((data) => data.copyWith(remoteImagesPolicy: value));
    return _setOrRemove(kRemoteImagesPolicyKey, value.persistableString);
  }

  LocalLinksPolicy get localLinksPolicy => data.localLinksPolicy;
  Future<void> setLocalLinksPolicy(LocalLinksPolicy value) async {
    _update((data) => data.copyWith(localLinksPolicy: value));
    return _setOrRemove(kLocalLinksPolicyKey, value.persistableString);
  }

  SaveChangesPolicy get saveChangesPolicy => data.saveChangesPolicy;
  Future<void> setSaveChangesPolicy(SaveChangesPolicy value) async {
    _update((data) => data.copyWith(saveChangesPolicy: value));
    return _setOrRemove(kSaveChangesPolicyKey, value.persistableString);
  }

  DecryptPolicy get decryptPolicy => data.decryptPolicy;
  Future<void> setDecryptPolicy(DecryptPolicy value) async {
    _update((data) => data.copyWith(decryptPolicy: value));
    return _setOrRemove(kDecryptPolicyKey, value.persistableString);
  }

  bool get fullWidth => data.fullWidth;
  Future<void> setFullWidth(bool value) async {
    _update((data) => data.copyWith(fullWidth: value));
    return _setOrRemove(kFullWidthKey, value);
  }

  Map<String, dynamic> get scopedPreferences => data.scopedPreferences;
  Future<void> setScopedPreferences(Map<String, dynamic> value) async {
    _update((data) => data.copyWith(scopedPreferences: value));
    return _setOrRemove(kScopedPreferencesJsonKey, json.encode(value));
  }

  bool _updateShouldNotifyDependentViewSettings(
    InheritedPreferences oldWidget,
    Set<PrefsAspect> dependencies,
  ) =>
      dependencies.contains(PrefsAspect.viewSettings) &&
          data.textScale != oldWidget.data.textScale ||
      data.fontFamily != oldWidget.data.fontFamily ||
      data.readerMode != oldWidget.data.readerMode ||
      data.remoteImagesPolicy != oldWidget.data.remoteImagesPolicy ||
      data.localLinksPolicy != oldWidget.data.localLinksPolicy ||
      data.saveChangesPolicy != oldWidget.data.saveChangesPolicy ||
      data.decryptPolicy != oldWidget.data.decryptPolicy ||
      data.fullWidth != oldWidget.data.fullWidth ||
      !data.scopedPreferences.unorderedEquals(oldWidget.data.scopedPreferences);
}

extension AccessibleDirectoriesExt on InheritedPreferences {
  List<String> get accessibleDirs => data.accessibleDirs;
  Future<void> _setAccessibleDirs(List<String> value) async {
    _update((data) => data.copyWith(accessibleDirs: value));
    return _setOrRemove(kAccessibleDirectoriesKey, value);
  }

  Future<void> addAccessibleDir(String dir) async {
    final dirs = [...accessibleDirs, dir].unique().toList(growable: false);
    return await _setAccessibleDirs(dirs);
  }

  bool _updateShouldNotifyDependentAccessibleDirectories(
    InheritedPreferences oldWidget,
    Set<PrefsAspect> dependencies,
  ) =>
      dependencies.contains(PrefsAspect.accessibleDirs) &&
      !listEquals(data.accessibleDirs, oldWidget.data.accessibleDirs);
}

extension CustomFilterQueriesExt on InheritedPreferences {
  List<String> get customFilterQueries => data.customFilterQueries;
  Future<void> _setCustomFilterQueries(List<String> value) async {
    _update((data) => data.copyWith(customFilterQueries: value));
    return _setOrRemove(kCustomFilterQueriesKey, value);
  }

  Future<void> addCustomFilterQuery(String value) async {
    // Maintain order, so don't just prepend and uniquify
    if (!customFilterQueries.contains(value)) {
      return await _setCustomFilterQueries([
        value,
        ...customFilterQueries.take(9),
      ]);
    }
  }

  bool _updateShouldNotifyDependentCustomFilterQueries(
    InheritedPreferences oldWidget,
    Set<PrefsAspect> dependencies,
  ) =>
      dependencies.contains(PrefsAspect.customFilterQueries) &&
      !listEquals(data.customFilterQueries, oldWidget.data.customFilterQueries);
}

extension CustomizationExt on InheritedPreferences {
  String get textPreviewString => data.textPreviewString;
  Future<void> setTextPreviewString(String value) async {
    _update((data) => data.copyWith(textPreviewString: value));
    return _setOrRemove(kTextPreviewStringKey, value);
  }

  bool _updateShouldNotifyDependentCustomization(
    InheritedPreferences oldWidget,
    Set<PrefsAspect> dependencies,
  ) =>
      dependencies.contains(PrefsAspect.customization) &&
      data.textPreviewString != oldWidget.data.textPreviewString;
}

class PreferencesData {
  factory PreferencesData.defaults() => const PreferencesData(
    textScale: kDefaultTextScale,
    fontFamily: kDefaultFontFamily,
    readerMode: kDefaultReaderMode,
    recentFiles: [],
    recentFilesSortKey: kDefaultRecentFilesSortKey,
    recentFilesSortOrder: kDefaultRecentFilesSortOrder,
    themeMode: _kDefaultThemeMode,
    remoteImagesPolicy: kDefaultRemoteImagesPolicy,
    localLinksPolicy: kDefaultLocalLinksPolicy,
    saveChangesPolicy: kDefaultSaveChangesPolicy,
    decryptPolicy: kDefaultDecryptPolicy,
    accessibleDirs: [],
    customFilterQueries: [],
    fullWidth: kDefaultFullWidth,
    scopedPreferences: {},
    textPreviewString: kDefaultTextPreviewString,
  );

  static Future<PreferencesData> fromSharedPreferences(
    SharedPreferencesAsync prefs,
  ) async {
    // TODO(aaron): Parallelize these gets if necessary
    final scopedPreferencesJson = await prefs.getString(
      kScopedPreferencesJsonKey,
    );
    final scopedPreferences =
        scopedPreferencesJson == null
            ? null
            : json.decode(scopedPreferencesJson) as Map<String, dynamic>;
    return PreferencesData.defaults().copyWith(
      textScale: await prefs.getDouble(kTextScaleKey),
      fontFamily: await prefs.getString(kFontFamilyKey),
      readerMode: await prefs.getBool(kReaderModeKey),
      recentFiles: (await prefs.getStringList(kRecentFilesJsonKey))
          ?.map<dynamic>(json.decode)
          .cast<Map<String, dynamic>>()
          .map((json) => RememberedFile.fromJson(json))
          .toList(growable: false),
      recentFilesSortKey: RecentFilesSortKeyPersistence.fromString(
        await prefs.getString(kRecentFilesSortKey),
      ),
      recentFilesSortOrder: SortOrderPersistence.fromString(
        await prefs.getString(kRecentFilesSortOrder),
      ),
      themeMode: ThemeModePersistence.fromString(
        await prefs.getString(kThemeModeKey),
      ),
      remoteImagesPolicy: RemoteImagesPolicyPersistence.fromString(
        await prefs.getString(kRemoteImagesPolicyKey),
      ),
      localLinksPolicy: LocalLinksPolicyPersistence.fromString(
        await prefs.getString(kLocalLinksPolicyKey),
      ),
      saveChangesPolicy: SaveChangesPolicyPersistence.fromString(
        await prefs.getString(kSaveChangesPolicyKey),
      ),
      decryptPolicy: DecryptPolicyPersistence.fromString(
        await prefs.getString(kDecryptPolicyKey),
      ),
      accessibleDirs: await prefs.getStringList(kAccessibleDirectoriesKey),
      customFilterQueries: await prefs.getStringList(kCustomFilterQueriesKey),
      fullWidth: await prefs.getBool(kFullWidthKey),
      scopedPreferences: scopedPreferences,
    );
  }

  const PreferencesData({
    required this.textScale,
    required this.fontFamily,
    required this.readerMode,
    required this.recentFiles,
    required this.recentFilesSortKey,
    required this.recentFilesSortOrder,
    required this.themeMode,
    required this.remoteImagesPolicy,
    required this.localLinksPolicy,
    required this.saveChangesPolicy,
    required this.decryptPolicy,
    required this.accessibleDirs,
    required this.customFilterQueries,
    required this.fullWidth,
    required this.scopedPreferences,
    required this.textPreviewString,
  });

  final double textScale;
  final String fontFamily;
  final bool readerMode;
  final List<RememberedFile> recentFiles;
  final RecentFilesSortKey recentFilesSortKey;
  final SortOrder recentFilesSortOrder;
  final ThemeMode themeMode;
  final RemoteImagesPolicy remoteImagesPolicy;
  final LocalLinksPolicy localLinksPolicy;
  final SaveChangesPolicy saveChangesPolicy;
  final DecryptPolicy decryptPolicy;
  final List<String> accessibleDirs;
  final List<String> customFilterQueries;
  final bool fullWidth;
  final Map<String, dynamic> scopedPreferences;
  final String textPreviewString;

  PreferencesData copyWith({
    double? textScale,
    String? fontFamily,
    bool? readerMode,
    List<RememberedFile>? recentFiles,
    RecentFilesSortKey? recentFilesSortKey,
    SortOrder? recentFilesSortOrder,
    ThemeMode? themeMode,
    RemoteImagesPolicy? remoteImagesPolicy,
    LocalLinksPolicy? localLinksPolicy,
    SaveChangesPolicy? saveChangesPolicy,
    DecryptPolicy? decryptPolicy,
    List<String>? accessibleDirs,
    List<String>? customFilterQueries,
    bool? fullWidth,
    Map<String, dynamic>? scopedPreferences,
    String? textPreviewString,
  }) => PreferencesData(
    textScale: textScale ?? this.textScale,
    fontFamily: fontFamily ?? this.fontFamily,
    readerMode: readerMode ?? this.readerMode,
    recentFiles: recentFiles ?? this.recentFiles,
    recentFilesSortKey: recentFilesSortKey ?? this.recentFilesSortKey,
    recentFilesSortOrder: recentFilesSortOrder ?? this.recentFilesSortOrder,
    themeMode: themeMode ?? this.themeMode,
    remoteImagesPolicy: remoteImagesPolicy ?? this.remoteImagesPolicy,
    localLinksPolicy: localLinksPolicy ?? this.localLinksPolicy,
    saveChangesPolicy: saveChangesPolicy ?? this.saveChangesPolicy,
    decryptPolicy: decryptPolicy ?? this.decryptPolicy,
    accessibleDirs: accessibleDirs ?? this.accessibleDirs,
    customFilterQueries: customFilterQueries ?? this.customFilterQueries,
    fullWidth: fullWidth ?? this.fullWidth,
    scopedPreferences: scopedPreferences ?? this.scopedPreferences,
    textPreviewString: textPreviewString ?? this.textPreviewString,
  );

  @override
  bool operator ==(Object other) =>
      other is PreferencesData &&
      textScale == other.textScale &&
      fontFamily == other.fontFamily &&
      readerMode == other.readerMode &&
      listEquals(recentFiles, other.recentFiles) &&
      recentFilesSortKey == other.recentFilesSortKey &&
      recentFilesSortOrder == other.recentFilesSortOrder &&
      themeMode == other.themeMode &&
      remoteImagesPolicy == other.remoteImagesPolicy &&
      localLinksPolicy == other.localLinksPolicy &&
      saveChangesPolicy == other.saveChangesPolicy &&
      decryptPolicy == other.decryptPolicy &&
      listEquals(accessibleDirs, other.accessibleDirs) &&
      listEquals(customFilterQueries, other.customFilterQueries) &&
      fullWidth == other.fullWidth &&
      scopedPreferences.unorderedEquals(
        other.scopedPreferences,
        valueEquals:
            (a, b) => mapEquals(
              a as Map<String, dynamic>?,
              b as Map<String, dynamic>?,
            ),
      ) &&
      textPreviewString == other.textPreviewString;

  @override
  int get hashCode => Object.hash(
    textScale,
    fontFamily,
    readerMode,
    Object.hashAll(recentFiles),
    recentFilesSortKey,
    recentFilesSortOrder,
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
    textPreviewString,
  );
}

extension RemoteImagesPolicyPersistence on RemoteImagesPolicy? {
  static RemoteImagesPolicy? fromString(String? value) => switch (value) {
    _kRemoteImagesPolicyAllow => RemoteImagesPolicy.allow,
    _kRemoteImagesPolicyDeny => RemoteImagesPolicy.deny,
    _kRemoteImagesPolicyAsk => RemoteImagesPolicy.ask,
    _ => null,
  };

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
  static LocalLinksPolicy? fromString(String? value) => switch (value) {
    _kLocalLinksPolicyDeny => LocalLinksPolicy.deny,
    _kLocalLinksPolicyAsk => LocalLinksPolicy.ask,
    _ => null,
  };

  String? get persistableString => switch (this) {
    LocalLinksPolicy.deny => _kLocalLinksPolicyDeny,
    LocalLinksPolicy.ask => _kLocalLinksPolicyAsk,
    null => null,
  };
}

const _kLocalLinksPolicyDeny = 'remote_images_policy_deny';
const _kLocalLinksPolicyAsk = 'remote_images_policy_ask';

extension SaveChangesPolicyPersistence on SaveChangesPolicy? {
  static SaveChangesPolicy? fromString(String? value) => switch (value) {
    _kSaveChangesPolicyAllow => SaveChangesPolicy.allow,
    _kSaveChangesPolicyDeny => SaveChangesPolicy.deny,
    _kSaveChangesPolicyAsk => SaveChangesPolicy.ask,
    _ => null,
  };

  String? get persistableString => switch (this) {
    SaveChangesPolicy.allow => _kSaveChangesPolicyAllow,
    SaveChangesPolicy.deny => _kSaveChangesPolicyDeny,
    SaveChangesPolicy.ask => _kSaveChangesPolicyAsk,
    null => null,
  };
}

const _kSaveChangesPolicyAllow = 'save_changes_policy_allow';
const _kSaveChangesPolicyDeny = 'save_changes_policy_deny';
const _kSaveChangesPolicyAsk = 'save_changes_policy_ask';

extension DecryptPolicyPersistence on DecryptPolicy? {
  static DecryptPolicy? fromString(String? value) => switch (value) {
    _kDecryptPolicyDeny => DecryptPolicy.deny,
    _kDecryptPolicyAsk => DecryptPolicy.ask,
    _ => null,
  };

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
    null => null,
  };

  static ThemeMode? fromString(String? value) => switch (value) {
    _kThemeModeSystem => ThemeMode.system,
    _kThemeModeLight => ThemeMode.light,
    _kThemeModeDark => ThemeMode.dark,
    _ => null,
  };
}

const _kThemeModeSystem = 'theme_mode_system';
const _kThemeModeLight = 'theme_mode_light';
const _kThemeModeDark = 'theme_mode_dark';

const _kDefaultThemeMode = ThemeMode.system;

extension SortOrderPersistence on SortOrder? {
  static SortOrder? fromString(String? key) => switch (key) {
    _kSortOrderAscending => SortOrder.ascending,
    _kSortOrderDescending => SortOrder.descending,
    _ => null,
  };

  String? get persistableString => switch (this) {
    SortOrder.ascending => _kSortOrderAscending,
    SortOrder.descending => _kSortOrderDescending,
    null => null,
  };
}

const _kSortOrderAscending = 'ascending';
const _kSortOrderDescending = 'descending';

Widget resetPreferencesListItem(BuildContext context) => ListTile(
  title: Text(AppLocalizations.of(context)!.settingsActionResetPreferences),
  onTap: () async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmResetDialog(),
    );
    if (result != true || !context.mounted) return;
    await Preferences.of(context, PrefsAspect.nil).reset();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.snackbarMessagePreferencesReset,
          ),
        ),
      );
    }
  },
);
