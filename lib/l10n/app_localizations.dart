import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_uk.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('en', 'GB'),
    Locale('en', 'US'),
    Locale('ja'),
    Locale('uk'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Orgro'**
  String get appTitle;

  /// No description provided for @menuItemAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get menuItemAppearance;

  /// No description provided for @menuItemSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get menuItemSettings;

  /// No description provided for @menuItemClearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get menuItemClearCache;

  /// No description provided for @menuItemOrgroManual.
  ///
  /// In en, this message translates to:
  /// **'Orgro Manual'**
  String get menuItemOrgroManual;

  /// No description provided for @menuItemOrgManual.
  ///
  /// In en, this message translates to:
  /// **'Org Manual'**
  String get menuItemOrgManual;

  /// No description provided for @menuItemTestFile.
  ///
  /// In en, this message translates to:
  /// **'Test File'**
  String get menuItemTestFile;

  /// No description provided for @menuItemAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get menuItemAbout;

  /// No description provided for @appearanceModeAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get appearanceModeAutomatic;

  /// No description provided for @appearanceModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appearanceModeLight;

  /// No description provided for @appearanceModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appearanceModeDark;

  /// No description provided for @settingsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsScreenTitle;

  /// No description provided for @settingsSectionDefaultText.
  ///
  /// In en, this message translates to:
  /// **'Default text'**
  String get settingsSectionDefaultText;

  /// No description provided for @settingsSectionDataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data management'**
  String get settingsSectionDataManagement;

  /// No description provided for @settingsItemAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsItemAppearance;

  /// No description provided for @settingsItemTextScale.
  ///
  /// In en, this message translates to:
  /// **'Scale'**
  String get settingsItemTextScale;

  /// No description provided for @settingsItemFontFamily.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get settingsItemFontFamily;

  /// No description provided for @settingsActionClearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get settingsActionClearCache;

  /// No description provided for @settingsActionResetPreferences.
  ///
  /// In en, this message translates to:
  /// **'Restore defaults'**
  String get settingsActionResetPreferences;

  /// No description provided for @snackbarMessageCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared'**
  String get snackbarMessageCacheCleared;

  /// No description provided for @snackbarMessagePreferencesReset.
  ///
  /// In en, this message translates to:
  /// **'Preferences reset'**
  String get snackbarMessagePreferencesReset;

  /// No description provided for @confirmResetPreferencesDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore defaults?'**
  String get confirmResetPreferencesDialogTitle;

  /// No description provided for @confirmResetPreferencesDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'This will reset all preferences to their default values. This action can’t be undone.'**
  String get confirmResetPreferencesDialogMessage;

  /// No description provided for @confirmResetPreferencesActionReset.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get confirmResetPreferencesActionReset;

  /// No description provided for @confirmResetPreferencesActionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get confirmResetPreferencesActionCancel;

  /// No description provided for @aboutLinkSupport.
  ///
  /// In en, this message translates to:
  /// **'Support · Feedback'**
  String get aboutLinkSupport;

  /// No description provided for @aboutLinkChangelog.
  ///
  /// In en, this message translates to:
  /// **'Changelog'**
  String get aboutLinkChangelog;

  /// No description provided for @buttonOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Open File'**
  String get buttonOpenFile;

  /// No description provided for @buttonCreateFile.
  ///
  /// In en, this message translates to:
  /// **'Create File'**
  String get buttonCreateFile;

  /// No description provided for @buttonOpenOrgroManual.
  ///
  /// In en, this message translates to:
  /// **'Open Orgro Manual'**
  String get buttonOpenOrgroManual;

  /// No description provided for @buttonOpenOrgManual.
  ///
  /// In en, this message translates to:
  /// **'Open Org Manual'**
  String get buttonOpenOrgManual;

  /// No description provided for @buttonSupport.
  ///
  /// In en, this message translates to:
  /// **'Support · Feedback'**
  String get buttonSupport;

  /// No description provided for @buttonVersion.
  ///
  /// In en, this message translates to:
  /// **'v{version}'**
  String buttonVersion(String version);

  /// No description provided for @sectionHeaderRecentFiles.
  ///
  /// In en, this message translates to:
  /// **'Recent files'**
  String get sectionHeaderRecentFiles;

  /// No description provided for @recentFilesSortDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get recentFilesSortDialogTitle;

  /// No description provided for @sortKeyLastOpened.
  ///
  /// In en, this message translates to:
  /// **'Last opened'**
  String get sortKeyLastOpened;

  /// No description provided for @sortKeyName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortKeyName;

  /// No description provided for @sortKeyLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get sortKeyLocation;

  /// No description provided for @sortOrderAscending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get sortOrderAscending;

  /// No description provided for @sortOrderDescending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get sortOrderDescending;

  /// No description provided for @fileSourceDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get fileSourceDocuments;

  /// No description provided for @fileSourceDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get fileSourceDownloads;

  /// No description provided for @fileSourceGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Google Drive'**
  String get fileSourceGoogleDrive;

  /// No description provided for @menuItemReaderMode.
  ///
  /// In en, this message translates to:
  /// **'Reader mode'**
  String get menuItemReaderMode;

  /// No description provided for @menuItemFullWidth.
  ///
  /// In en, this message translates to:
  /// **'Full width'**
  String get menuItemFullWidth;

  /// No description provided for @menuItemScrollTop.
  ///
  /// In en, this message translates to:
  /// **'Scroll to top'**
  String get menuItemScrollTop;

  /// No description provided for @menuItemScrollBottom.
  ///
  /// In en, this message translates to:
  /// **'Scroll to bottom'**
  String get menuItemScrollBottom;

  /// No description provided for @menuItemUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get menuItemUndo;

  /// No description provided for @menuItemRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get menuItemRedo;

  /// No description provided for @hintTextSearch.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get hintTextSearch;

  /// No description provided for @searchHits.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{0 hits} =1{1 hit} other{{n} hits}}'**
  String searchHits(num n);

  /// No description provided for @searchResultSelection.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String searchResultSelection(num current, num total);

  /// No description provided for @customFilterChipName.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customFilterChipName;

  /// No description provided for @snackbarMessageNeedsDirectoryPermissions.
  ///
  /// In en, this message translates to:
  /// **'Orgro doesn’t have permission to resolve relative links'**
  String get snackbarMessageNeedsDirectoryPermissions;

  /// No description provided for @snackbarActionGrantAccess.
  ///
  /// In en, this message translates to:
  /// **'Grant access'**
  String get snackbarActionGrantAccess;

  /// No description provided for @snackbarMessageNeedsEncryptionKey.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Missing encryption password.'**
  String get snackbarMessageNeedsEncryptionKey;

  /// No description provided for @snackbarActionEnterEncryptionKey.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get snackbarActionEnterEncryptionKey;

  /// No description provided for @dialogTitleError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get dialogTitleError;

  /// No description provided for @dialogActionConfirm.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get dialogActionConfirm;

  /// No description provided for @dialogActionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dialogActionCancel;

  /// No description provided for @dialogActionHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get dialogActionHelp;

  /// No description provided for @pageTitleError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get pageTitleError;

  /// No description provided for @pageTitleLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get pageTitleLoading;

  /// No description provided for @pageTitleNarrow.
  ///
  /// In en, this message translates to:
  /// **'{name} › narrow'**
  String pageTitleNarrow(String name);

  /// No description provided for @pageTitleEditing.
  ///
  /// In en, this message translates to:
  /// **'{name} › editing'**
  String pageTitleEditing(String name);

  /// No description provided for @sectionActionNarrow.
  ///
  /// In en, this message translates to:
  /// **'Narrow'**
  String get sectionActionNarrow;

  /// No description provided for @sectionActionCycleTodo.
  ///
  /// In en, this message translates to:
  /// **'Cycle TODO'**
  String get sectionActionCycleTodo;

  /// No description provided for @bannerBodyRemoteImages.
  ///
  /// In en, this message translates to:
  /// **'This document contains remote images. Would you like to load them?'**
  String get bannerBodyRemoteImages;

  /// No description provided for @bannerBodyActionShowAlways.
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get bannerBodyActionShowAlways;

  /// No description provided for @bannerBodyActionShowNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get bannerBodyActionShowNever;

  /// No description provided for @bannerBodyActionShowOnce.
  ///
  /// In en, this message translates to:
  /// **'Just once'**
  String get bannerBodyActionShowOnce;

  /// No description provided for @bannerBodyRelativeLinks.
  ///
  /// In en, this message translates to:
  /// **'This document contains relative links. Would you like to grant access?'**
  String get bannerBodyRelativeLinks;

  /// No description provided for @bannerBodyActionGrantNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get bannerBodyActionGrantNotNow;

  /// No description provided for @bannerBodyActionGrantNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get bannerBodyActionGrantNever;

  /// No description provided for @bannerBodyActionGrantNow.
  ///
  /// In en, this message translates to:
  /// **'Grant access'**
  String get bannerBodyActionGrantNow;

  /// No description provided for @bannerBodySaveDocumentOrg.
  ///
  /// In en, this message translates to:
  /// **'Would you like to save changes to this document? *This is an experimental feature.* Make sure to back up your files. [[https://orgro.org/faq/#can-i-edit-my-files-with-orgro][Learn More]]'**
  String get bannerBodySaveDocumentOrg;

  /// No description provided for @bannerBodyActionSaveAlways.
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get bannerBodyActionSaveAlways;

  /// No description provided for @bannerBodyActionSaveNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get bannerBodyActionSaveNever;

  /// No description provided for @bannerBodyActionSaveOnce.
  ///
  /// In en, this message translates to:
  /// **'Just this time'**
  String get bannerBodyActionSaveOnce;

  /// No description provided for @bannerBodyDecryptContent.
  ///
  /// In en, this message translates to:
  /// **'This document contains encrypted content. Decrypt it now?'**
  String get bannerBodyDecryptContent;

  /// No description provided for @bannerBodyActionDecryptNow.
  ///
  /// In en, this message translates to:
  /// **'Decrypt'**
  String get bannerBodyActionDecryptNow;

  /// No description provided for @bannerBodyActionDecryptNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get bannerBodyActionDecryptNotNow;

  /// No description provided for @bannerBodyActionDecryptNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get bannerBodyActionDecryptNever;

  /// No description provided for @saveChangesDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Save changes?'**
  String get saveChangesDialogTitle;

  /// No description provided for @saveChangesDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Orgro can’t write your changes back to the original file.'**
  String get saveChangesDialogMessage;

  /// No description provided for @saveActionShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get saveActionShare;

  /// No description provided for @saveActionDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get saveActionDiscard;

  /// No description provided for @discardChangesDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardChangesDialogTitle;

  /// No description provided for @discardActionDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardActionDiscard;

  /// No description provided for @discardActionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get discardActionCancel;

  /// No description provided for @savedMessage.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedMessage;

  /// No description provided for @inputDecryptionPasswordDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter password for decrypting'**
  String get inputDecryptionPasswordDialogTitle;

  /// No description provided for @inputEncryptionPasswordDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter password for encrypting'**
  String get inputEncryptionPasswordDialogTitle;

  /// No description provided for @inputEncryptionPasswordDialogBody.
  ///
  /// In en, this message translates to:
  /// **'This password will be used to encrypt Org Crypt sections for which no password has been specified.'**
  String get inputEncryptionPasswordDialogBody;

  /// No description provided for @inputCustomFilterDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom filter query'**
  String get inputCustomFilterDialogTitle;

  /// No description provided for @inputCustomFilterDialogHistoryButton.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get inputCustomFilterDialogHistoryButton;

  /// No description provided for @decryptingProgressDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Decrypting…'**
  String get decryptingProgressDialogTitle;

  /// No description provided for @encryptingProgressDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Encrypting…'**
  String get encryptingProgressDialogTitle;

  /// No description provided for @serializingProgressDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Serializing…'**
  String get serializingProgressDialogTitle;

  /// No description provided for @savingProgressDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get savingProgressDialogTitle;

  /// No description provided for @searchingProgressDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Searching…'**
  String get searchingProgressDialogTitle;

  /// No description provided for @citationsDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Citations'**
  String get citationsDialogTitle;

  /// No description provided for @createFileDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Create new file'**
  String get createFileDialogTitle;

  /// No description provided for @createFileDefaultName.
  ///
  /// In en, this message translates to:
  /// **'untitled.org'**
  String get createFileDefaultName;

  /// No description provided for @startTimePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Select start time'**
  String get startTimePickerTitle;

  /// No description provided for @endTimePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Select end time'**
  String get endTimePickerTitle;

  /// No description provided for @snackbarMessageBibliographiesNotFound.
  ///
  /// In en, this message translates to:
  /// **'No bibliographies found'**
  String get snackbarMessageBibliographiesNotFound;

  /// No description provided for @snackbarMessageCitationKeysNotFound.
  ///
  /// In en, this message translates to:
  /// **'Citation keys not found'**
  String get snackbarMessageCitationKeysNotFound;

  /// No description provided for @snackbarMessageCitationsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Citations not found'**
  String get snackbarMessageCitationsNotFound;

  /// No description provided for @snackbarMessageSomeCitationsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Citations not found: {citations}'**
  String snackbarMessageSomeCitationsNotFound(String citations);

  /// No description provided for @errorCannotResolveRelativePath.
  ///
  /// In en, this message translates to:
  /// **'Can’t resolve path relative to this document'**
  String get errorCannotResolveRelativePath;

  /// No description provided for @errorPathResolvedToNonFile.
  ///
  /// In en, this message translates to:
  /// **'{path} resolved to a non-file: {resolved}'**
  String errorPathResolvedToNonFile(String path, String resolved);

  /// No description provided for @errorUnknownType.
  ///
  /// In en, this message translates to:
  /// **'Unknown type: {type}'**
  String errorUnknownType(Object type);

  /// No description provided for @errorUnexpectedHttpResponse.
  ///
  /// In en, this message translates to:
  /// **'Unexpected HTTP response: {response}'**
  String errorUnexpectedHttpResponse(Object response);

  /// No description provided for @errorOrgParser.
  ///
  /// In en, this message translates to:
  /// **'Parser error: {result}'**
  String errorOrgParser(Object result);

  /// No description provided for @errorOrgExecution.
  ///
  /// In en, this message translates to:
  /// **'Execution error in the below code: {message}\n\n{code}'**
  String errorOrgExecution(Object message, String code);

  /// No description provided for @errorOrgTimeout.
  ///
  /// In en, this message translates to:
  /// **'Evaluation of the below code timed out after {timeout}ms.\n\n{code}'**
  String errorOrgTimeout(num timeout, String code);

  /// No description provided for @errorOrgArgument.
  ///
  /// In en, this message translates to:
  /// **'Invalid argument: {item}'**
  String errorOrgArgument(Object item);

  /// No description provided for @errorDecryptionFailed.
  ///
  /// In en, this message translates to:
  /// **'Decryption failed'**
  String get errorDecryptionFailed;

  /// No description provided for @errorLinkNotHandled.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t open link “{link}”'**
  String errorLinkNotHandled(Object link);

  /// No description provided for @errorExternalIdNotFound.
  ///
  /// In en, this message translates to:
  /// **'File with ID “{id}” not found'**
  String errorExternalIdNotFound(String id);

  /// No description provided for @editInsertedHeadline.
  ///
  /// In en, this message translates to:
  /// **'[Inserted by edit]'**
  String get editInsertedHeadline;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'ja', 'uk'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'en':
      {
        switch (locale.countryCode) {
          case 'GB':
            return AppLocalizationsEnGb();
          case 'US':
            return AppLocalizationsEnUs();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'uk':
      return AppLocalizationsUk();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
