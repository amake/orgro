import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ru.dart';
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
    Locale('en'),
    Locale('de'),
    Locale('en', 'GB'),
    Locale('en', 'US'),
    Locale('ja'),
    Locale('ru'),
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

  /// No description provided for @menuItemOpenUrl.
  ///
  /// In en, this message translates to:
  /// **'Open URL'**
  String get menuItemOpenUrl;

  /// No description provided for @quickActionNewDocument.
  ///
  /// In en, this message translates to:
  /// **'New Document'**
  String get quickActionNewDocument;

  /// No description provided for @quickActionTopPin.
  ///
  /// In en, this message translates to:
  /// **'Open {name}'**
  String quickActionTopPin(String name);

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

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsSectionDefaultText.
  ///
  /// In en, this message translates to:
  /// **'Default text'**
  String get settingsSectionDefaultText;

  /// No description provided for @settingsSectionNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsSectionNotifications;

  /// No description provided for @settingsSectionDataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data management'**
  String get settingsSectionDataManagement;

  /// No description provided for @settingsSectionDonate.
  ///
  /// In en, this message translates to:
  /// **'Donate'**
  String get settingsSectionDonate;

  /// No description provided for @settingsSectionPurchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get settingsSectionPurchase;

  /// No description provided for @agendaNotificationsChannelName.
  ///
  /// In en, this message translates to:
  /// **'Agenda Notifications'**
  String get agendaNotificationsChannelName;

  /// No description provided for @agendaNotificationsChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Notifications for Org Agenda items'**
  String get agendaNotificationsChannelDescription;

  /// No description provided for @agendaNotificationsActionView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get agendaNotificationsActionView;

  /// No description provided for @settingsItemLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get settingsItemLoading;

  /// No description provided for @settingsItemTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsItemTheme;

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

  /// No description provided for @settingsItemDefaultTextPreviewString.
  ///
  /// In en, this message translates to:
  /// **'This is what document text will look like in the selected font and scale.\n\nTap to edit.'**
  String get settingsItemDefaultTextPreviewString;

  /// No description provided for @settingsItemGrantNotificationPermissions.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get settingsItemGrantNotificationPermissions;

  /// No description provided for @settingsItemInspectNotifications.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{No notifications} =1{1 pending notification} other{{n} pending notifications}}'**
  String settingsItemInspectNotifications(num n);

  /// No description provided for @settingsDialogNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending notifications'**
  String get settingsDialogNotificationsTitle;

  /// No description provided for @settingsItemClearNotifications.
  ///
  /// In en, this message translates to:
  /// **'Clear all notifications'**
  String get settingsItemClearNotifications;

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

  /// No description provided for @settingsActionResetDirectoryPermissions.
  ///
  /// In en, this message translates to:
  /// **'Reset directory permissions'**
  String get settingsActionResetDirectoryPermissions;

  /// No description provided for @snackbarMessageNotificationsCleared.
  ///
  /// In en, this message translates to:
  /// **'Notifications cleared'**
  String get snackbarMessageNotificationsCleared;

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

  /// No description provided for @snackbarMessageDirectoryPermissionsReset.
  ///
  /// In en, this message translates to:
  /// **'Directory permissions reset'**
  String get snackbarMessageDirectoryPermissionsReset;

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

  /// No description provided for @buttonOpenUrl.
  ///
  /// In en, this message translates to:
  /// **'Open URL'**
  String get buttonOpenUrl;

  /// No description provided for @tooltipCreateFile.
  ///
  /// In en, this message translates to:
  /// **'Create file'**
  String get tooltipCreateFile;

  /// No description provided for @tooltipOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Open file'**
  String get tooltipOpenFile;

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

  /// No description provided for @sectionHeaderPinnedFiles.
  ///
  /// In en, this message translates to:
  /// **'Pinned files'**
  String get sectionHeaderPinnedFiles;

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

  /// No description provided for @menuItemWakelock.
  ///
  /// In en, this message translates to:
  /// **'Keep screen on'**
  String get menuItemWakelock;

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

  /// No description provided for @tooltipFullWidth.
  ///
  /// In en, this message translates to:
  /// **'Toggle full width'**
  String get tooltipFullWidth;

  /// No description provided for @tooltipReaderMode.
  ///
  /// In en, this message translates to:
  /// **'Toggle reader mode'**
  String get tooltipReaderMode;

  /// No description provided for @tooltipScrollTop.
  ///
  /// In en, this message translates to:
  /// **'Scroll to top'**
  String get tooltipScrollTop;

  /// No description provided for @tooltipScrollBottom.
  ///
  /// In en, this message translates to:
  /// **'Scroll to bottom'**
  String get tooltipScrollBottom;

  /// No description provided for @tooltipTextStyle.
  ///
  /// In en, this message translates to:
  /// **'Text style'**
  String get tooltipTextStyle;

  /// No description provided for @tooltipDecreaseTextScale.
  ///
  /// In en, this message translates to:
  /// **'Decrease text scale'**
  String get tooltipDecreaseTextScale;

  /// No description provided for @tooltipIncreaseTextScale.
  ///
  /// In en, this message translates to:
  /// **'Increase text scale'**
  String get tooltipIncreaseTextScale;

  /// No description provided for @tooltipCycleVisibility.
  ///
  /// In en, this message translates to:
  /// **'Cycle visibility'**
  String get tooltipCycleVisibility;

  /// No description provided for @tooltipEditDocument.
  ///
  /// In en, this message translates to:
  /// **'Edit document'**
  String get tooltipEditDocument;

  /// No description provided for @tooltipSearchDocument.
  ///
  /// In en, this message translates to:
  /// **'Search document'**
  String get tooltipSearchDocument;

  /// No description provided for @tooltipPreviousSearchHit.
  ///
  /// In en, this message translates to:
  /// **'Previous search result'**
  String get tooltipPreviousSearchHit;

  /// No description provided for @tooltipNextSearchHit.
  ///
  /// In en, this message translates to:
  /// **'Next search result'**
  String get tooltipNextSearchHit;

  /// No description provided for @hintTextSearch.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get hintTextSearch;

  /// No description provided for @tooltipClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get tooltipClearSearch;

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

  /// No description provided for @snackbarMessageNeedsNotificationsPermissions.
  ///
  /// In en, this message translates to:
  /// **'Orgro doesn’t have permission to send notifications'**
  String get snackbarMessageNeedsNotificationsPermissions;

  /// No description provided for @snackbarActionGrantNotificationsPermissions.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get snackbarActionGrantNotificationsPermissions;

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

  /// No description provided for @bannerBodySaveDocument.
  ///
  /// In en, this message translates to:
  /// **'Would you like to save your changes?'**
  String get bannerBodySaveDocument;

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

  /// No description provided for @bannerBodyAgendaNotifications.
  ///
  /// In en, this message translates to:
  /// **'Get notifications for agenda items in this file?'**
  String get bannerBodyAgendaNotifications;

  /// No description provided for @bannerBodyActionAgendaEnable.
  ///
  /// In en, this message translates to:
  /// **'Notify me'**
  String get bannerBodyActionAgendaEnable;

  /// No description provided for @bannerBodyActionAgendaNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get bannerBodyActionAgendaNotNow;

  /// No description provided for @bannerBodyActionAgendaNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get bannerBodyActionAgendaNever;

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

  /// No description provided for @saveActionSaveAs.
  ///
  /// In en, this message translates to:
  /// **'Save as'**
  String get saveActionSaveAs;

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

  /// No description provided for @loadingProgressDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loadingProgressDialogTitle;

  /// No description provided for @preparingProgressDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Preparing…'**
  String get preparingProgressDialogTitle;

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

  /// No description provided for @citationsDialogOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Open link'**
  String get citationsDialogOpenLink;

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

  /// No description provided for @saveAsDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Save as'**
  String get saveAsDialogTitle;

  /// No description provided for @inputUrlDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter URL'**
  String get inputUrlDialogTitle;

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

  /// No description provided for @captureToDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Capture to'**
  String get captureToDialogTitle;

  /// No description provided for @captureToClipboardItem.
  ///
  /// In en, this message translates to:
  /// **'Clipboard'**
  String get captureToClipboardItem;

  /// No description provided for @captureToNewDocumentItem.
  ///
  /// In en, this message translates to:
  /// **'New file'**
  String get captureToNewDocumentItem;

  /// No description provided for @snackbarMessageInvalidCaptureUri.
  ///
  /// In en, this message translates to:
  /// **'Invalid capture URL'**
  String get snackbarMessageInvalidCaptureUri;

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

  /// No description provided for @errorSectionNotFound.
  ///
  /// In en, this message translates to:
  /// **'Section not found: {section}'**
  String errorSectionNotFound(String section);

  /// No description provided for @errorUnsupportedSearchOption.
  ///
  /// In en, this message translates to:
  /// **'Unsupported search option: {option}'**
  String errorUnsupportedSearchOption(String option);

  /// No description provided for @errorSchedulingNotifications.
  ///
  /// In en, this message translates to:
  /// **'Failed to schedule notifications: {message}'**
  String errorSchedulingNotifications(Object message);

  /// No description provided for @tooltipErrorDetails.
  ///
  /// In en, this message translates to:
  /// **'View error details'**
  String get tooltipErrorDetails;

  /// No description provided for @editInsertedHeadline.
  ///
  /// In en, this message translates to:
  /// **'[Inserted by edit]'**
  String get editInsertedHeadline;

  /// No description provided for @tooltipApplyChanges.
  ///
  /// In en, this message translates to:
  /// **'Apply changes'**
  String get tooltipApplyChanges;

  /// No description provided for @tooltipUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get tooltipUndo;

  /// No description provided for @tooltipRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get tooltipRedo;

  /// No description provided for @tooltipToggleUnorderedList.
  ///
  /// In en, this message translates to:
  /// **'Toggle unordered list'**
  String get tooltipToggleUnorderedList;

  /// No description provided for @tooltipToggleOrderedList.
  ///
  /// In en, this message translates to:
  /// **'Toggle ordered list'**
  String get tooltipToggleOrderedList;

  /// No description provided for @tooltipDecreaseIndent.
  ///
  /// In en, this message translates to:
  /// **'Decrease indent'**
  String get tooltipDecreaseIndent;

  /// No description provided for @tooltipIncreaseIndent.
  ///
  /// In en, this message translates to:
  /// **'Increase indent'**
  String get tooltipIncreaseIndent;

  /// No description provided for @tooltipBold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get tooltipBold;

  /// No description provided for @tooltipItalic.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get tooltipItalic;

  /// No description provided for @tooltipUnderline.
  ///
  /// In en, this message translates to:
  /// **'Underline'**
  String get tooltipUnderline;

  /// No description provided for @tooltipStrikethrough.
  ///
  /// In en, this message translates to:
  /// **'Strikethrough'**
  String get tooltipStrikethrough;

  /// No description provided for @tooltipCode.
  ///
  /// In en, this message translates to:
  /// **'Code style'**
  String get tooltipCode;

  /// No description provided for @tooltipInsertLink.
  ///
  /// In en, this message translates to:
  /// **'Insert link'**
  String get tooltipInsertLink;

  /// No description provided for @tooltipInsertDate.
  ///
  /// In en, this message translates to:
  /// **'Insert date'**
  String get tooltipInsertDate;

  /// No description provided for @tooltipSubscript.
  ///
  /// In en, this message translates to:
  /// **'Subscript'**
  String get tooltipSubscript;

  /// No description provided for @tooltipSuperscript.
  ///
  /// In en, this message translates to:
  /// **'Superscript'**
  String get tooltipSuperscript;

  /// No description provided for @donateItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Donate to support Orgro'**
  String get donateItemTitle;

  /// No description provided for @donateItemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your support is appreciated!'**
  String get donateItemSubtitle;

  /// No description provided for @entitlementsLoadingItem.
  ///
  /// In en, this message translates to:
  /// **'Loading info...'**
  String get entitlementsLoadingItem;

  /// No description provided for @entitlementsFreeTrialItem.
  ///
  /// In en, this message translates to:
  /// **'Your free trial ends at {date}'**
  String entitlementsFreeTrialItem(DateTime date);

  /// No description provided for @entitlementsTrialExpiredItem.
  ///
  /// In en, this message translates to:
  /// **'Your free trial has ended'**
  String get entitlementsTrialExpiredItem;

  /// No description provided for @entitlementsPurchaseItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Purchase Orgro for {price} (one-time payment)'**
  String entitlementsPurchaseItemTitle(String price);

  /// No description provided for @entitlementsPurchaseItemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock all features and support development'**
  String get entitlementsPurchaseItemSubtitle;

  /// No description provided for @entitlementsRestorePurchasesItem.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get entitlementsRestorePurchasesItem;

  /// No description provided for @entitlementsPurchasedItem.
  ///
  /// In en, this message translates to:
  /// **'Purchased'**
  String get entitlementsPurchasedItem;

  /// No description provided for @entitlementsPurchasedItemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your support'**
  String get entitlementsPurchasedItemSubtitle;

  /// No description provided for @entitlementsLegacyPurchaseItemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Thank you for being a long-time supporter!'**
  String get entitlementsLegacyPurchaseItemSubtitle;

  /// No description provided for @entitlementsLockedDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Your free trial has ended'**
  String get entitlementsLockedDialogTitle;

  /// No description provided for @entitlementsLockedDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'To continue using Orgro, please purchase a license or restore your previous purchases.\n\nPurchasing a license is a one-time payment that unlocks all features.'**
  String get entitlementsLockedDialogMessage;

  /// No description provided for @entitlementsLockedDialogActionPurchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase ({price})'**
  String entitlementsLockedDialogActionPurchase(String price);

  /// No description provided for @entitlementsLockedDialogActionRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get entitlementsLockedDialogActionRestore;

  /// No description provided for @entitlementsLockedDialogActionMoreInfo.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get entitlementsLockedDialogActionMoreInfo;
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
      <String>['de', 'en', 'ja', 'ru', 'uk'].contains(locale.languageCode);

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
    case 'ru':
      return AppLocalizationsRu();
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
