import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:org_flutter/org_flutter.dart';
import 'package:orgro/src/debug.dart';
import 'package:orgro/src/fonts.dart';
import 'package:orgro/src/preferences.dart';

class ViewSettings extends StatefulWidget {
  static InheritedViewSettings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InheritedViewSettings>()!;

  ViewSettings.defaults(BuildContext context, {required Widget child, Key? key})
    : this(data: ViewSettingsData.defaults(context), child: child, key: key);

  const ViewSettings({required this.data, required this.child, super.key});

  final Widget child;
  final ViewSettingsData data;

  @override
  State<ViewSettings> createState() => _ViewSettingsState();
}

class _ViewSettingsState extends State<ViewSettings> {
  InheritedPreferences get _prefs =>
      Preferences.of(context, PrefsAspect.viewSettings);

  late ViewSettingsData _data;

  @override
  void initState() {
    super.initState();
    _data = widget.data;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final prefs = _prefs;
    _update(
      (data) => data.copyWith(
        textScale: prefs.textScale,
        fontFamily: prefs.fontFamily,
        readerMode: prefs.readerMode,
        remoteImagesPolicy: prefs.remoteImagesPolicy,
        localLinksPolicy: prefs.localLinksPolicy,
        saveChangesPolicy: prefs.saveChangesPolicy,
        decryptPolicy: prefs.decryptPolicy,
        fullWidth: prefs.fullWidth,
      ),
    );
  }

  void _update(ViewSettingsData Function(ViewSettingsData) transform) =>
      setState(() => _data = transform(_data));

  @override
  Widget build(BuildContext context) =>
      InheritedViewSettings(_data, _update, _prefs, child: widget.child);
}

class InheritedViewSettings extends InheritedWidget {
  const InheritedViewSettings(
    this.data,
    this._update,
    this._prefs, {
    required super.child,
    super.key,
  });

  final ViewSettingsData data;
  final InheritedPreferences _prefs;
  final void Function(ViewSettingsData Function(ViewSettingsData)) _update;

  void _setScopedValue(String scopeKey, String valueKey, dynamic value) {
    final allData = {..._prefs.scopedPreferences};
    allData[scopeKey] ??= {...kDefaultScopedPreferences};
    allData[scopeKey][valueKey] = value;
    _prefs.setScopedPreferences(allData);
  }

  TextStyle get textStyle => data.textStyle;

  double get textScale => data.textScale;
  set textScale(double value) {
    _prefs.setTextScale(value);
  }

  void setTextScale(String key, double value) {
    _setScopedValue(key, kTextScaleKey, value);
    // Don't set preference
    _update((data) => data.copyWith(textScale: value));
  }

  String get fontFamily => data.fontFamily;
  set fontFamily(String value) {
    _prefs.setFontFamily(value);
  }

  void setFontFamily(String key, String value) {
    _setScopedValue(key, kFontFamilyKey, value);
    // Don't set preference
    _update((data) => data.copyWith(fontFamily: value));
  }

  bool get readerMode => data.readerMode;
  set readerMode(bool value) {
    _prefs.setReaderMode(value);
  }

  RemoteImagesPolicy get remoteImagesPolicy => data.remoteImagesPolicy;
  void setRemoteImagesPolicy(RemoteImagesPolicy value, {bool persist = false}) {
    if (persist) {
      _prefs.setRemoteImagesPolicy(value);
    } else {
      _update((data) => data.copyWith(remoteImagesPolicy: value));
    }
  }

  LocalLinksPolicy get localLinksPolicy => data.localLinksPolicy;
  void setLocalLinksPolicy(LocalLinksPolicy value, {bool persist = false}) {
    if (persist) {
      _prefs.setLocalLinksPolicy(value);
    } else {
      _update((data) => data.copyWith(localLinksPolicy: value));
    }
  }

  SaveChangesPolicy get saveChangesPolicy => data.saveChangesPolicy;
  void setSaveChangesPolicy(SaveChangesPolicy value, {bool persist = false}) {
    if (persist) {
      _prefs.setSaveChangesPolicy(value);
    } else {
      _update((data) => data.copyWith(saveChangesPolicy: value));
    }
  }

  DecryptPolicy get decryptPolicy => data.decryptPolicy;
  void setDecryptPolicy(DecryptPolicy value, {bool persist = false}) {
    if (persist) {
      _prefs.setDecryptPolicy(value);
    } else {
      _update((data) => data.copyWith(decryptPolicy: value));
    }
  }

  AgendaNotificationsPolicy get agendaNotificationsPolicy =>
      data.agendaNotificationsPolicy;
  void setAgendaNotificationsPolicy(
    AgendaNotificationsPolicy value, {
    bool persist = false,
  }) {
    if (persist) {
      _prefs.setAgendaNotificationsPolicy(value);
    } else {
      _update((data) => data.copyWith(agendaNotificationsPolicy: value));
    }
  }

  bool get fullWidth => data.fullWidth;
  set fullWidth(bool value) {
    _prefs.setFullWidth(value);
  }

  String? get queryString => data.queryString;
  set queryString(String? value) =>
      _update((data) => data.copyWith(queryString: value));

  FilterData get filterData => data.filterData;
  set filterData(FilterData value) =>
      _update((data) => data.copyWith(filterData: value));

  ViewSettingsData forScope(String key) {
    try {
      return ViewSettingsData._scoped(_prefs, key, data);
    } catch (e, s) {
      logError(e, s);
      return data;
    }
  }

  @override
  bool updateShouldNotify(InheritedViewSettings oldWidget) =>
      data != oldWidget.data;
}

class ViewSettingsData {
  factory ViewSettingsData.defaults(BuildContext context) {
    final prefs = Preferences.of(context, PrefsAspect.viewSettings);
    return ViewSettingsData(
      textScale: prefs.textScale,
      fontFamily: prefs.fontFamily,
      readerMode: prefs.readerMode,
      remoteImagesPolicy: prefs.remoteImagesPolicy,
      localLinksPolicy: prefs.localLinksPolicy,
      saveChangesPolicy: prefs.saveChangesPolicy,
      decryptPolicy: prefs.decryptPolicy,
      agendaNotificationsPolicy: prefs.agendaNotificationsPolicy,
      fullWidth: prefs.fullWidth,
      queryString: kDefaultQueryString,
      filterData: FilterData.defaults(),
    );
  }

  factory ViewSettingsData._scoped(
    InheritedPreferences prefs,
    String key,
    ViewSettingsData defaults,
  ) {
    final allData = prefs.scopedPreferences;
    final scopedData = allData[key] ?? kDefaultScopedPreferences;
    return defaults.copyWith(
      textScale: scopedData[kTextScaleKey] as double?,
      fontFamily: scopedData[kFontFamilyKey] as String?,
      // TODO(aaron): For now we only support textScale and fontFamily as scoped
      // values, but we could add more as such:
      //
      // readerMode: scopedData[key]?[kReaderModeKey] as bool?,
      // fullWidth: scopedData[key]?[kFullWidthKey] as bool?,
    );
  }

  const ViewSettingsData({
    required this.textScale,
    required this.fontFamily,
    required this.readerMode,
    required this.remoteImagesPolicy,
    required this.localLinksPolicy,
    required this.saveChangesPolicy,
    required this.decryptPolicy,
    required this.agendaNotificationsPolicy,
    required this.fullWidth,
    required this.filterData,
    required this.queryString,
  });

  // From preferences
  final double textScale;
  final String fontFamily;
  final bool readerMode;
  final RemoteImagesPolicy remoteImagesPolicy;
  final LocalLinksPolicy localLinksPolicy;
  final SaveChangesPolicy saveChangesPolicy;
  final DecryptPolicy decryptPolicy;
  final AgendaNotificationsPolicy agendaNotificationsPolicy;
  final bool fullWidth;
  // Not persisted
  final FilterData filterData;
  final String? queryString;

  TextStyle get textStyle => loadFontWithVariants(
    fontFamily,
  ).copyWith(fontSize: TextScaler.linear(textScale).scale(18));

  ViewSettingsData copyWith({
    double? textScale,
    String? fontFamily,
    bool? readerMode,
    RemoteImagesPolicy? remoteImagesPolicy,
    LocalLinksPolicy? localLinksPolicy,
    SaveChangesPolicy? saveChangesPolicy,
    DecryptPolicy? decryptPolicy,
    AgendaNotificationsPolicy? agendaNotificationsPolicy,
    bool? fullWidth,
    String? queryString,
    FilterData? filterData,
  }) => ViewSettingsData(
    textScale: textScale ?? this.textScale,
    fontFamily: fontFamily ?? this.fontFamily,
    readerMode: readerMode ?? this.readerMode,
    remoteImagesPolicy: remoteImagesPolicy ?? this.remoteImagesPolicy,
    localLinksPolicy: localLinksPolicy ?? this.localLinksPolicy,
    saveChangesPolicy: saveChangesPolicy ?? this.saveChangesPolicy,
    decryptPolicy: decryptPolicy ?? this.decryptPolicy,
    agendaNotificationsPolicy:
        agendaNotificationsPolicy ?? this.agendaNotificationsPolicy,
    fullWidth: fullWidth ?? this.fullWidth,
    queryString: queryString ?? this.queryString,
    filterData: filterData ?? this.filterData,
  );

  @override
  bool operator ==(Object other) =>
      other is ViewSettingsData &&
      textScale == other.textScale &&
      fontFamily == other.fontFamily &&
      readerMode == other.readerMode &&
      remoteImagesPolicy == other.remoteImagesPolicy &&
      localLinksPolicy == other.localLinksPolicy &&
      saveChangesPolicy == other.saveChangesPolicy &&
      decryptPolicy == other.decryptPolicy &&
      agendaNotificationsPolicy == other.agendaNotificationsPolicy &&
      fullWidth == other.fullWidth &&
      queryString == other.queryString &&
      filterData == other.filterData;

  @override
  int get hashCode => Object.hash(
    textScale,
    fontFamily,
    readerMode,
    remoteImagesPolicy,
    localLinksPolicy,
    saveChangesPolicy,
    decryptPolicy,
    agendaNotificationsPolicy,
    fullWidth,
    queryString,
    filterData,
  );
}

class FilterData {
  factory FilterData.defaults() => const FilterData(
    keywords: kDefaultFilterKeywords,
    tags: kDefaultFilterTags,
    priorities: kDefaultFilterPriorities,
    customFilter: kDefaultCustomFilter,
  );

  factory FilterData.fromJson(Map<String, dynamic> json) => FilterData(
    keywords: (json['keywords'] as List).cast(),
    tags: (json['tags'] as List).cast(),
    priorities: (json['priorities'] as List).cast(),
    customFilter: json['customFilter'] as String,
  );

  const FilterData({
    required this.keywords,
    required this.tags,
    required this.priorities,
    required this.customFilter,
  });

  final List<String> keywords;
  final List<String> tags;
  final List<String> priorities;
  final String customFilter;

  bool get isEmpty =>
      keywords.isEmpty &&
      tags.isEmpty &&
      priorities.isEmpty &&
      customFilter.isEmpty;

  bool get isNotEmpty => !isEmpty;

  FilterData copyWith({
    List<String>? keywords,
    List<String>? tags,
    List<String>? priorities,
    String? customFilter,
  }) => FilterData(
    keywords: keywords ?? this.keywords,
    tags: tags ?? this.tags,
    priorities: priorities ?? this.priorities,
    customFilter: customFilter ?? this.customFilter,
  );

  Map<String, dynamic> toJson() => {
    'keywords': keywords,
    'tags': tags,
    'priorities': priorities,
    'customFilter': customFilter,
  };

  @override
  bool operator ==(Object other) =>
      other is FilterData &&
      listEquals(keywords, other.keywords) &&
      listEquals(tags, other.tags) &&
      listEquals(priorities, other.priorities) &&
      customFilter == other.customFilter;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(keywords),
    Object.hashAll(tags),
    Object.hashAll(priorities),
    customFilter,
  );

  OrgQueryMatcher? asSparseQuery() {
    if (isEmpty) return null;

    return OrgQueryAndMatcher([
      if (customFilter.isNotEmpty) OrgQueryMatcher.fromMarkup(customFilter),
      ...keywords.map(
        (value) => OrgQueryPropertyMatcher(
          property: 'TODO',
          operator: '=',
          value: value,
        ),
      ),
      ...tags.map((value) => OrgQueryTagMatcher(value)),
      ...priorities.map(
        (value) => OrgQueryPropertyMatcher(
          property: 'PRIORITY',
          operator: '=',
          value: value,
        ),
      ),
    ]);
  }
}
