import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:orgro/src/fonts.dart';
import 'package:orgro/src/preferences.dart';

class ViewSettings extends StatefulWidget {
  static InheritedViewSettings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InheritedViewSettings>()!;

  ViewSettings.defaults(
    BuildContext context, {
    required Widget child,
    Key? key,
  }) : this(
          data: ViewSettingsData.defaults(context),
          child: child,
          key: key,
        );

  const ViewSettings({required this.data, required this.child, super.key});

  final Widget child;
  final ViewSettingsData data;

  @override
  State<ViewSettings> createState() => _ViewSettingsState();
}

class _ViewSettingsState extends State<ViewSettings> {
  late ViewSettingsData _data;

  @override
  void initState() {
    super.initState();
    _data = widget.data;
  }

  void _update(ViewSettingsData Function(ViewSettingsData) transform) =>
      setState(() => _data = transform(_data));

  @override
  Widget build(BuildContext context) =>
      InheritedViewSettings(_data, _update, Preferences.of(context),
          child: widget.child);
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
  final Preferences _prefs;
  final void Function(ViewSettingsData Function(ViewSettingsData)) _update;

  TextStyle get textStyle => loadFontWithVariants(fontFamily).copyWith(
        fontSize: TextScaler.linear(textScale).scale(18),
      );

  double get textScale => data.textScale;
  set textScale(double value) {
    _prefs.setTextScale(value);
    _update((data) => data.copyWith(textScale: value));
  }

  String get fontFamily => data.fontFamily;
  set fontFamily(String value) {
    _prefs.setFontFamily(value);
    _update((data) => data.copyWith(fontFamily: value));
  }

  String? get queryString => data.queryString;
  set queryString(String? value) =>
      _update((data) => data.copyWith(queryString: value));

  FilterData get filterData => data.filterData;
  set filterData(FilterData value) =>
      _update((data) => data.copyWith(filterData: value));

  bool get readerMode => data.readerMode;
  set readerMode(bool value) {
    _prefs.setReaderMode(value);
    _update((data) => data.copyWith(readerMode: value));
  }

  RemoteImagesPolicy get remoteImagesPolicy => data.remoteImagesPolicy;
  void setRemoteImagesPolicy(RemoteImagesPolicy value, {bool persist = false}) {
    if (persist) {
      _prefs.setRemoteImagesPolicy(value);
    }
    _update((data) => data.copyWith(remoteImagesPolicy: value));
  }

  LocalLinksPolicy get localLinksPolicy => data.localLinksPolicy;
  void setLocalLinksPolicy(LocalLinksPolicy value, {bool persist = false}) {
    if (persist) {
      _prefs.setLocalLinksPolicy(value);
    }
    _update((data) => data.copyWith(localLinksPolicy: value));
  }

  SaveChangesPolicy get saveChangesPolicy => data.saveChangesPolicy;
  void setSaveChangesPolicy(SaveChangesPolicy value, {bool persist = false}) {
    if (persist) {
      _prefs.setSaveChangesPolicy(value);
    }
    _update((data) => data.copyWith(saveChangesPolicy: value));
  }

  DecryptPolicy get decryptPolicy => data.decryptPolicy;
  void setDecryptPolicy(DecryptPolicy value, {bool persist = false}) {
    if (persist) {
      _prefs.setDecryptPolicy(value);
    }
    _update((data) => data.copyWith(decryptPolicy: value));
  }

  bool get fullWidth => data.fullWidth;
  set fullWidth(bool value) {
    _prefs.setFullWidth(value);
    _update((data) => data.copyWith(fullWidth: value));
  }

  @override
  bool updateShouldNotify(InheritedViewSettings oldWidget) =>
      data != oldWidget.data;
}

class ViewSettingsData {
  factory ViewSettingsData.defaults(BuildContext context) {
    final prefs = Preferences.of(context);
    return ViewSettingsData(
      textScale: prefs.textScale ?? kDefaultTextScale,
      fontFamily: prefs.fontFamily ?? kDefaultFontFamily,
      queryString: kDefaultQueryString,
      filterData: FilterData.defaults(),
      readerMode: prefs.readerMode ?? kDefaultReaderMode,
      remoteImagesPolicy:
          prefs.remoteImagesPolicy ?? kDefaultRemoteImagesPolicy,
      localLinksPolicy: prefs.localLinksPolicy ?? kDefaultLocalLinksPolicy,
      saveChangesPolicy: prefs.saveChangesPolicy ?? kDefaultSaveChangesPolicy,
      decryptPolicy: prefs.decryptPolicy ?? kDefaultDecryptPolicy,
      fullWidth: prefs.fullWidth ?? kDefaultFullWidth,
    );
  }

  const ViewSettingsData({
    required this.textScale,
    required this.fontFamily,
    required this.queryString,
    required this.filterData,
    required this.readerMode,
    required this.remoteImagesPolicy,
    required this.localLinksPolicy,
    required this.saveChangesPolicy,
    required this.decryptPolicy,
    required this.fullWidth,
  });

  final double textScale;
  final String fontFamily;
  final String? queryString;
  final FilterData filterData;
  final bool readerMode;
  final RemoteImagesPolicy remoteImagesPolicy;
  final LocalLinksPolicy localLinksPolicy;
  final SaveChangesPolicy saveChangesPolicy;
  final DecryptPolicy decryptPolicy;
  final bool fullWidth;

  ViewSettingsData copyWith({
    double? textScale,
    String? fontFamily,
    String? queryString,
    FilterData? filterData,
    bool? readerMode,
    RemoteImagesPolicy? remoteImagesPolicy,
    LocalLinksPolicy? localLinksPolicy,
    SaveChangesPolicy? saveChangesPolicy,
    DecryptPolicy? decryptPolicy,
    bool? fullWidth,
  }) =>
      ViewSettingsData(
        textScale: textScale ?? this.textScale,
        fontFamily: fontFamily ?? this.fontFamily,
        queryString: queryString ?? this.queryString,
        filterData: filterData ?? this.filterData,
        readerMode: readerMode ?? this.readerMode,
        remoteImagesPolicy: remoteImagesPolicy ?? this.remoteImagesPolicy,
        localLinksPolicy: localLinksPolicy ?? this.localLinksPolicy,
        saveChangesPolicy: saveChangesPolicy ?? this.saveChangesPolicy,
        decryptPolicy: decryptPolicy ?? this.decryptPolicy,
        fullWidth: fullWidth ?? this.fullWidth,
      );

  @override
  bool operator ==(Object other) =>
      other is ViewSettingsData &&
      textScale == other.textScale &&
      fontFamily == other.fontFamily &&
      queryString == other.queryString &&
      filterData == other.filterData &&
      readerMode == other.readerMode &&
      remoteImagesPolicy == other.remoteImagesPolicy &&
      localLinksPolicy == other.localLinksPolicy &&
      saveChangesPolicy == other.saveChangesPolicy &&
      decryptPolicy == other.decryptPolicy &&
      fullWidth == other.fullWidth;

  @override
  int get hashCode => Object.hash(
        textScale,
        fontFamily,
        queryString,
        filterData,
        readerMode,
        remoteImagesPolicy,
        localLinksPolicy,
        saveChangesPolicy,
        decryptPolicy,
        fullWidth,
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
  }) =>
      FilterData(
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
}
