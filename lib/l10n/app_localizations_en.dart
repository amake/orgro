// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Orgro';

  @override
  String get menuItemAppearance => 'Appearance';

  @override
  String get menuItemSettings => 'Settings';

  @override
  String get menuItemClearCache => 'Clear cache';

  @override
  String get menuItemOrgroManual => 'Orgro Manual';

  @override
  String get menuItemOrgManual => 'Org Manual';

  @override
  String get menuItemTestFile => 'Test File';

  @override
  String get menuItemAbout => 'About';

  @override
  String get menuItemOpenUrl => 'Open URL';

  @override
  String get quickActionNewDocument => 'New Document';

  @override
  String quickActionTopPin(String name) {
    return 'Open $name';
  }

  @override
  String get appearanceModeAutomatic => 'Automatic';

  @override
  String get appearanceModeLight => 'Light';

  @override
  String get appearanceModeDark => 'Dark';

  @override
  String get settingsScreenTitle => 'Settings';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsSectionDefaultText => 'Default text';

  @override
  String get settingsSectionNotifications => 'Notifications';

  @override
  String get settingsSectionDataManagement => 'Data management';

  @override
  String get settingsSectionDonate => 'Donate';

  @override
  String get settingsSectionPurchase => 'Purchase';

  @override
  String get agendaNotificationsChannelName => 'Agenda Notifications';

  @override
  String get agendaNotificationsChannelDescription =>
      'Notifications for Org Agenda items';

  @override
  String get agendaNotificationsActionView => 'View';

  @override
  String get settingsItemLoading => 'Loading...';

  @override
  String get settingsItemTheme => 'Theme';

  @override
  String get settingsItemTextScale => 'Scale';

  @override
  String get settingsItemFontFamily => 'Font';

  @override
  String get settingsItemDefaultTextPreviewString =>
      'This is what document text will look like in the selected font and scale.\n\nTap to edit.';

  @override
  String get settingsItemGrantNotificationPermissions => 'Enable notifications';

  @override
  String settingsItemInspectNotifications(num n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString pending notifications',
      one: '1 pending notification',
      zero: 'No notifications',
    );
    return '$_temp0';
  }

  @override
  String get settingsDialogNotificationsTitle => 'Pending notifications';

  @override
  String get settingsItemClearNotifications => 'Clear all notifications';

  @override
  String get settingsActionClearCache => 'Clear cache';

  @override
  String get settingsActionResetPreferences => 'Restore defaults';

  @override
  String get settingsActionResetDirectoryPermissions =>
      'Reset directory permissions';

  @override
  String get snackbarMessageNotificationsCleared => 'Notifications cleared';

  @override
  String get snackbarMessageCacheCleared => 'Cache cleared';

  @override
  String get snackbarMessagePreferencesReset => 'Preferences reset';

  @override
  String get snackbarMessageDirectoryPermissionsReset =>
      'Directory permissions reset';

  @override
  String get confirmResetPreferencesDialogTitle => 'Restore defaults?';

  @override
  String get confirmResetPreferencesDialogMessage =>
      'This will reset all preferences to their default values. This action can’t be undone.';

  @override
  String get confirmResetPreferencesActionReset => 'Restore';

  @override
  String get confirmResetPreferencesActionCancel => 'Cancel';

  @override
  String get aboutLinkSupport => 'Support · Feedback';

  @override
  String get aboutLinkChangelog => 'Changelog';

  @override
  String get buttonOpenFile => 'Open File';

  @override
  String get buttonCreateFile => 'Create File';

  @override
  String get buttonOpenOrgroManual => 'Open Orgro Manual';

  @override
  String get buttonOpenOrgManual => 'Open Org Manual';

  @override
  String get buttonOpenUrl => 'Open URL';

  @override
  String get buttonSupport => 'Support · Feedback';

  @override
  String buttonVersion(String version) {
    return 'v$version';
  }

  @override
  String get sectionHeaderPinnedFiles => 'Pinned files';

  @override
  String get sectionHeaderRecentFiles => 'Recent files';

  @override
  String get recentFilesSortDialogTitle => 'Sort by';

  @override
  String get sortKeyLastOpened => 'Last opened';

  @override
  String get sortKeyName => 'Name';

  @override
  String get sortKeyLocation => 'Location';

  @override
  String get sortOrderAscending => 'Ascending';

  @override
  String get sortOrderDescending => 'Descending';

  @override
  String get fileSourceDocuments => 'Documents';

  @override
  String get fileSourceDownloads => 'Downloads';

  @override
  String get fileSourceGoogleDrive => 'Google Drive';

  @override
  String get menuItemReaderMode => 'Reader mode';

  @override
  String get menuItemWakelock => 'Keep screen on';

  @override
  String get menuItemFullWidth => 'Full width';

  @override
  String get menuItemScrollTop => 'Scroll to top';

  @override
  String get menuItemScrollBottom => 'Scroll to bottom';

  @override
  String get menuItemUndo => 'Undo';

  @override
  String get menuItemRedo => 'Redo';

  @override
  String get hintTextSearch => 'Search...';

  @override
  String searchHits(num n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString hits',
      one: '1 hit',
      zero: '0 hits',
    );
    return '$_temp0';
  }

  @override
  String searchResultSelection(num current, num total) {
    final intl.NumberFormat currentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String currentString = currentNumberFormat.format(current);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$currentString / $totalString';
  }

  @override
  String get customFilterChipName => 'Custom';

  @override
  String get snackbarMessageNeedsDirectoryPermissions =>
      'Orgro doesn’t have permission to resolve relative links';

  @override
  String get snackbarActionGrantAccess => 'Grant access';

  @override
  String get snackbarMessageNeedsEncryptionKey =>
      'Could not save. Missing encryption password.';

  @override
  String get snackbarActionEnterEncryptionKey => 'Enter password';

  @override
  String get snackbarMessageNeedsNotificationsPermissions =>
      'Orgro doesn’t have permission to send notifications';

  @override
  String get snackbarActionGrantNotificationsPermissions => 'Allow';

  @override
  String get dialogTitleError => 'Error';

  @override
  String get dialogActionConfirm => 'OK';

  @override
  String get dialogActionCancel => 'Cancel';

  @override
  String get dialogActionHelp => 'Help';

  @override
  String get pageTitleError => 'Error';

  @override
  String get pageTitleLoading => 'Loading...';

  @override
  String pageTitleNarrow(String name) {
    return '$name › narrow';
  }

  @override
  String pageTitleEditing(String name) {
    return '$name › editing';
  }

  @override
  String get sectionActionNarrow => 'Narrow';

  @override
  String get sectionActionCycleTodo => 'Cycle TODO';

  @override
  String get bannerBodyRemoteImages =>
      'This document contains remote images. Would you like to load them?';

  @override
  String get bannerBodyActionShowAlways => 'Always';

  @override
  String get bannerBodyActionShowNever => 'Never';

  @override
  String get bannerBodyActionShowOnce => 'Just once';

  @override
  String get bannerBodyRelativeLinks =>
      'This document contains relative links. Would you like to grant access?';

  @override
  String get bannerBodyActionGrantNotNow => 'Not now';

  @override
  String get bannerBodyActionGrantNever => 'Never';

  @override
  String get bannerBodyActionGrantNow => 'Grant access';

  @override
  String get bannerBodySaveDocumentOrg =>
      'Would you like to save changes to this document? *This is an experimental feature.* Make sure to back up your files. [[https://orgro.org/faq/#can-i-edit-my-files-with-orgro][Learn More]]';

  @override
  String get bannerBodyActionSaveAlways => 'Always';

  @override
  String get bannerBodyActionSaveNever => 'Never';

  @override
  String get bannerBodyActionSaveOnce => 'Just this time';

  @override
  String get bannerBodyDecryptContent =>
      'This document contains encrypted content. Decrypt it now?';

  @override
  String get bannerBodyActionDecryptNow => 'Decrypt';

  @override
  String get bannerBodyActionDecryptNotNow => 'Not now';

  @override
  String get bannerBodyActionDecryptNever => 'Never';

  @override
  String get bannerBodyAgendaNotifications =>
      'Get notifications for agenda items in this file?';

  @override
  String get bannerBodyActionAgendaEnable => 'Notify me';

  @override
  String get bannerBodyActionAgendaNotNow => 'Not now';

  @override
  String get bannerBodyActionAgendaNever => 'Never';

  @override
  String get saveChangesDialogTitle => 'Save changes?';

  @override
  String get saveChangesDialogMessage =>
      'Orgro can’t write your changes back to the original file.';

  @override
  String get saveActionShare => 'Share';

  @override
  String get saveActionDiscard => 'Discard';

  @override
  String get saveActionSaveAs => 'Save as';

  @override
  String get discardChangesDialogTitle => 'Discard changes?';

  @override
  String get discardActionDiscard => 'Discard';

  @override
  String get discardActionCancel => 'Cancel';

  @override
  String get savedMessage => 'Saved';

  @override
  String get inputDecryptionPasswordDialogTitle =>
      'Enter password for decrypting';

  @override
  String get inputEncryptionPasswordDialogTitle =>
      'Enter password for encrypting';

  @override
  String get inputEncryptionPasswordDialogBody =>
      'This password will be used to encrypt Org Crypt sections for which no password has been specified.';

  @override
  String get inputCustomFilterDialogTitle => 'Custom filter query';

  @override
  String get inputCustomFilterDialogHistoryButton => 'History';

  @override
  String get loadingProgressDialogTitle => 'Loading…';

  @override
  String get preparingProgressDialogTitle => 'Preparing…';

  @override
  String get decryptingProgressDialogTitle => 'Decrypting…';

  @override
  String get encryptingProgressDialogTitle => 'Encrypting…';

  @override
  String get serializingProgressDialogTitle => 'Serializing…';

  @override
  String get savingProgressDialogTitle => 'Saving…';

  @override
  String get searchingProgressDialogTitle => 'Searching…';

  @override
  String get citationsDialogTitle => 'Citations';

  @override
  String get createFileDialogTitle => 'Create new file';

  @override
  String get createFileDefaultName => 'untitled.org';

  @override
  String get saveAsDialogTitle => 'Save as';

  @override
  String get inputUrlDialogTitle => 'Enter URL';

  @override
  String get startTimePickerTitle => 'Select start time';

  @override
  String get endTimePickerTitle => 'Select end time';

  @override
  String get captureToDialogTitle => 'Capture to';

  @override
  String get captureToClipboardItem => 'Clipboard';

  @override
  String get captureToNewDocumentItem => 'New file';

  @override
  String get snackbarMessageInvalidCaptureUri => 'Invalid capture URL';

  @override
  String get snackbarMessageBibliographiesNotFound => 'No bibliographies found';

  @override
  String get snackbarMessageCitationKeysNotFound => 'Citation keys not found';

  @override
  String get snackbarMessageCitationsNotFound => 'Citations not found';

  @override
  String snackbarMessageSomeCitationsNotFound(String citations) {
    return 'Citations not found: $citations';
  }

  @override
  String get errorCannotResolveRelativePath =>
      'Can’t resolve path relative to this document';

  @override
  String errorPathResolvedToNonFile(String path, String resolved) {
    return '$path resolved to a non-file: $resolved';
  }

  @override
  String errorUnknownType(Object type) {
    return 'Unknown type: $type';
  }

  @override
  String errorUnexpectedHttpResponse(Object response) {
    return 'Unexpected HTTP response: $response';
  }

  @override
  String errorOrgParser(Object result) {
    return 'Parser error: $result';
  }

  @override
  String errorOrgExecution(Object message, String code) {
    return 'Execution error in the below code: $message\n\n$code';
  }

  @override
  String errorOrgTimeout(num timeout, String code) {
    final intl.NumberFormat timeoutNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String timeoutString = timeoutNumberFormat.format(timeout);

    return 'Evaluation of the below code timed out after ${timeoutString}ms.\n\n$code';
  }

  @override
  String errorOrgArgument(Object item) {
    return 'Invalid argument: $item';
  }

  @override
  String get errorDecryptionFailed => 'Decryption failed';

  @override
  String errorLinkNotHandled(Object link) {
    return 'Couldn’t open link “$link”';
  }

  @override
  String errorExternalIdNotFound(String id) {
    return 'File with ID “$id” not found';
  }

  @override
  String errorSectionNotFound(String section) {
    return 'Section not found: $section';
  }

  @override
  String errorUnsupportedSearchOption(String option) {
    return 'Unsupported search option: $option';
  }

  @override
  String errorSchedulingNotifications(Object message) {
    return 'Failed to schedule notifications: $message';
  }

  @override
  String get editInsertedHeadline => '[Inserted by edit]';

  @override
  String get donateItemTitle => 'Donate to support Orgro';

  @override
  String get donateItemSubtitle => 'Your support is appreciated!';

  @override
  String get entitlementsLoadingItem => 'Loading info...';

  @override
  String entitlementsFreeTrialItem(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(
      localeName,
    ).add_jm();
    final String dateString = dateDateFormat.format(date);

    return 'Your free trial ends at $dateString';
  }

  @override
  String get entitlementsTrialExpiredItem => 'Your free trial has ended';

  @override
  String entitlementsPurchaseItemTitle(String price) {
    return 'Purchase Orgro for $price (one-time payment)';
  }

  @override
  String get entitlementsPurchaseItemSubtitle =>
      'Unlock all features and support development';

  @override
  String get entitlementsRestorePurchasesItem => 'Restore purchases';

  @override
  String get entitlementsPurchasedItem => 'Purchased';

  @override
  String get entitlementsPurchasedItemSubtitle => 'Thank you for your support';

  @override
  String get entitlementsLegacyPurchaseItemSubtitle =>
      'Thank you for being a long-time supporter!';

  @override
  String get entitlementsLockedDialogTitle => 'Your free trial has ended';

  @override
  String get entitlementsLockedDialogMessage =>
      'To continue using Orgro, please purchase a license or restore your previous purchases.\n\nPurchasing a license is a one-time payment that unlocks all features.';

  @override
  String entitlementsLockedDialogActionPurchase(String price) {
    return 'Purchase ($price)';
  }

  @override
  String get entitlementsLockedDialogActionRestore => 'Restore';

  @override
  String get entitlementsLockedDialogActionMoreInfo => 'Learn more';
}

/// The translations for English, as used in the United Kingdom (`en_GB`).
class AppLocalizationsEnGb extends AppLocalizationsEn {
  AppLocalizationsEnGb() : super('en_GB');

  @override
  String get appTitle => 'Orgro';

  @override
  String get menuItemAppearance => 'Appearance';

  @override
  String get menuItemSettings => 'Settings';

  @override
  String get menuItemClearCache => 'Clear cache';

  @override
  String get menuItemOrgroManual => 'Orgro Manual';

  @override
  String get menuItemOrgManual => 'Org Manual';

  @override
  String get menuItemTestFile => 'Test File';

  @override
  String get menuItemAbout => 'About';

  @override
  String get menuItemOpenUrl => 'Open URL';

  @override
  String get quickActionNewDocument => 'New Document';

  @override
  String quickActionTopPin(String name) {
    return 'Open $name';
  }

  @override
  String get appearanceModeAutomatic => 'Automatic';

  @override
  String get appearanceModeLight => 'Light';

  @override
  String get appearanceModeDark => 'Dark';

  @override
  String get settingsScreenTitle => 'Settings';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsSectionDefaultText => 'Default text';

  @override
  String get settingsSectionNotifications => 'Notifications';

  @override
  String get settingsSectionDataManagement => 'Data management';

  @override
  String get settingsSectionDonate => 'Donate';

  @override
  String get settingsSectionPurchase => 'Purchase';

  @override
  String get agendaNotificationsChannelName => 'Agenda Notifications';

  @override
  String get agendaNotificationsChannelDescription =>
      'Notifications for Org Agenda items';

  @override
  String get agendaNotificationsActionView => 'View';

  @override
  String get settingsItemLoading => 'Loading...';

  @override
  String get settingsItemTheme => 'Theme';

  @override
  String get settingsItemTextScale => 'Scale';

  @override
  String get settingsItemFontFamily => 'Font';

  @override
  String get settingsItemDefaultTextPreviewString =>
      'This is what document text will look like in the selected font and scale.\n\nTap to edit.';

  @override
  String get settingsItemGrantNotificationPermissions => 'Enable notifications';

  @override
  String settingsItemInspectNotifications(num n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString pending notifications',
      one: '1 pending notification',
      zero: 'No notifications',
    );
    return '$_temp0';
  }

  @override
  String get settingsDialogNotificationsTitle => 'Pending notifications';

  @override
  String get settingsItemClearNotifications => 'Clear all notifications';

  @override
  String get settingsActionClearCache => 'Clear cache';

  @override
  String get settingsActionResetPreferences => 'Restore defaults';

  @override
  String get settingsActionResetDirectoryPermissions =>
      'Reset directory permissions';

  @override
  String get snackbarMessageNotificationsCleared => 'Notifications cleared';

  @override
  String get snackbarMessageCacheCleared => 'Cache cleared';

  @override
  String get snackbarMessagePreferencesReset => 'Preferences reset';

  @override
  String get snackbarMessageDirectoryPermissionsReset =>
      'Directory permissions reset';

  @override
  String get confirmResetPreferencesDialogTitle => 'Restore defaults?';

  @override
  String get confirmResetPreferencesDialogMessage =>
      'This will reset all preferences to their default values. This action can’t be undone.';

  @override
  String get confirmResetPreferencesActionReset => 'Restore';

  @override
  String get confirmResetPreferencesActionCancel => 'Cancel';

  @override
  String get aboutLinkSupport => 'Support · Feedback';

  @override
  String get aboutLinkChangelog => 'Changelog';

  @override
  String get buttonOpenFile => 'Open File';

  @override
  String get buttonCreateFile => 'Create File';

  @override
  String get buttonOpenOrgroManual => 'Open Orgro Manual';

  @override
  String get buttonOpenOrgManual => 'Open Org Manual';

  @override
  String get buttonOpenUrl => 'Open URL';

  @override
  String get buttonSupport => 'Support · Feedback';

  @override
  String buttonVersion(String version) {
    return 'v$version';
  }

  @override
  String get sectionHeaderPinnedFiles => 'Pinned files';

  @override
  String get sectionHeaderRecentFiles => 'Recent files';

  @override
  String get recentFilesSortDialogTitle => 'Sort by';

  @override
  String get sortKeyLastOpened => 'Last opened';

  @override
  String get sortKeyName => 'Name';

  @override
  String get sortKeyLocation => 'Location';

  @override
  String get sortOrderAscending => 'Ascending';

  @override
  String get sortOrderDescending => 'Descending';

  @override
  String get fileSourceDocuments => 'Documents';

  @override
  String get fileSourceDownloads => 'Downloads';

  @override
  String get fileSourceGoogleDrive => 'Google Drive';

  @override
  String get menuItemReaderMode => 'Reader mode';

  @override
  String get menuItemWakelock => 'Keep screen on';

  @override
  String get menuItemFullWidth => 'Full width';

  @override
  String get menuItemScrollTop => 'Scroll to top';

  @override
  String get menuItemScrollBottom => 'Scroll to bottom';

  @override
  String get menuItemUndo => 'Undo';

  @override
  String get menuItemRedo => 'Redo';

  @override
  String get hintTextSearch => 'Search...';

  @override
  String searchHits(num n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString hits',
      one: '1 hit',
      zero: '0 hits',
    );
    return '$_temp0';
  }

  @override
  String searchResultSelection(num current, num total) {
    final intl.NumberFormat currentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String currentString = currentNumberFormat.format(current);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$currentString / $totalString';
  }

  @override
  String get customFilterChipName => 'Custom';

  @override
  String get snackbarMessageNeedsDirectoryPermissions =>
      'Orgro doesn’t have permission to resolve relative links';

  @override
  String get snackbarActionGrantAccess => 'Grant access';

  @override
  String get snackbarMessageNeedsEncryptionKey =>
      'Could not save. Missing encryption password.';

  @override
  String get snackbarActionEnterEncryptionKey => 'Enter password';

  @override
  String get snackbarMessageNeedsNotificationsPermissions =>
      'Orgro doesn’t have permission to send notifications';

  @override
  String get snackbarActionGrantNotificationsPermissions => 'Allow';

  @override
  String get dialogTitleError => 'Error';

  @override
  String get dialogActionConfirm => 'OK';

  @override
  String get dialogActionCancel => 'Cancel';

  @override
  String get dialogActionHelp => 'Help';

  @override
  String get pageTitleError => 'Error';

  @override
  String get pageTitleLoading => 'Loading...';

  @override
  String pageTitleNarrow(String name) {
    return '$name › narrow';
  }

  @override
  String pageTitleEditing(String name) {
    return '$name › editing';
  }

  @override
  String get sectionActionNarrow => 'Narrow';

  @override
  String get sectionActionCycleTodo => 'Cycle TODO';

  @override
  String get bannerBodyRemoteImages =>
      'This document contains remote images. Would you like to load them?';

  @override
  String get bannerBodyActionShowAlways => 'Always';

  @override
  String get bannerBodyActionShowNever => 'Never';

  @override
  String get bannerBodyActionShowOnce => 'Just once';

  @override
  String get bannerBodyRelativeLinks =>
      'This document contains relative links. Would you like to grant access?';

  @override
  String get bannerBodyActionGrantNotNow => 'Not now';

  @override
  String get bannerBodyActionGrantNever => 'Never';

  @override
  String get bannerBodyActionGrantNow => 'Grant access';

  @override
  String get bannerBodySaveDocumentOrg =>
      'Would you like to save changes to this document? *This is an experimental feature.* Make sure to back up your files. [[https://orgro.org/faq/#can-i-edit-my-files-with-orgro][Learn More]]';

  @override
  String get bannerBodyActionSaveAlways => 'Always';

  @override
  String get bannerBodyActionSaveNever => 'Never';

  @override
  String get bannerBodyActionSaveOnce => 'Just this time';

  @override
  String get bannerBodyDecryptContent =>
      'This document contains encrypted content. Decrypt it now?';

  @override
  String get bannerBodyActionDecryptNow => 'Decrypt';

  @override
  String get bannerBodyActionDecryptNotNow => 'Not now';

  @override
  String get bannerBodyActionDecryptNever => 'Never';

  @override
  String get bannerBodyAgendaNotifications =>
      'Get notifications for agenda items in this file?';

  @override
  String get bannerBodyActionAgendaEnable => 'Notify me';

  @override
  String get bannerBodyActionAgendaNotNow => 'Not now';

  @override
  String get bannerBodyActionAgendaNever => 'Never';

  @override
  String get saveChangesDialogTitle => 'Save changes?';

  @override
  String get saveChangesDialogMessage =>
      'Orgro can’t write your changes back to the original file.';

  @override
  String get saveActionShare => 'Share';

  @override
  String get saveActionDiscard => 'Discard';

  @override
  String get saveActionSaveAs => 'Save as';

  @override
  String get discardChangesDialogTitle => 'Discard changes?';

  @override
  String get discardActionDiscard => 'Discard';

  @override
  String get discardActionCancel => 'Cancel';

  @override
  String get savedMessage => 'Saved';

  @override
  String get inputDecryptionPasswordDialogTitle =>
      'Enter password for decrypting';

  @override
  String get inputEncryptionPasswordDialogTitle =>
      'Enter password for encrypting';

  @override
  String get inputEncryptionPasswordDialogBody =>
      'This password will be used to encrypt Org Crypt sections for which no password has been specified.';

  @override
  String get inputCustomFilterDialogTitle => 'Custom filter query';

  @override
  String get inputCustomFilterDialogHistoryButton => 'History';

  @override
  String get loadingProgressDialogTitle => 'Loading…';

  @override
  String get preparingProgressDialogTitle => 'Preparing…';

  @override
  String get decryptingProgressDialogTitle => 'Decrypting…';

  @override
  String get encryptingProgressDialogTitle => 'Encrypting…';

  @override
  String get serializingProgressDialogTitle => 'Serialising…';

  @override
  String get savingProgressDialogTitle => 'Saving…';

  @override
  String get searchingProgressDialogTitle => 'Searching…';

  @override
  String get citationsDialogTitle => 'Citations';

  @override
  String get createFileDialogTitle => 'Create new file';

  @override
  String get createFileDefaultName => 'untitled.org';

  @override
  String get saveAsDialogTitle => 'Save as';

  @override
  String get inputUrlDialogTitle => 'Enter URL';

  @override
  String get startTimePickerTitle => 'Select start time';

  @override
  String get endTimePickerTitle => 'Select end time';

  @override
  String get captureToDialogTitle => 'Capture to';

  @override
  String get captureToClipboardItem => 'Clipboard';

  @override
  String get captureToNewDocumentItem => 'New file';

  @override
  String get snackbarMessageInvalidCaptureUri => 'Invalid capture URL';

  @override
  String get snackbarMessageBibliographiesNotFound => 'No bibliographies found';

  @override
  String get snackbarMessageCitationKeysNotFound => 'Citation keys not found';

  @override
  String get snackbarMessageCitationsNotFound => 'Citations not found';

  @override
  String snackbarMessageSomeCitationsNotFound(String citations) {
    return 'Citations not found: $citations';
  }

  @override
  String get errorCannotResolveRelativePath =>
      'Can’t resolve path relative to this document';

  @override
  String errorPathResolvedToNonFile(String path, String resolved) {
    return '$path resolved to a non-file: $resolved';
  }

  @override
  String errorUnknownType(Object type) {
    return 'Unknown type: $type';
  }

  @override
  String errorUnexpectedHttpResponse(Object response) {
    return 'Unexpected HTTP response: $response';
  }

  @override
  String errorOrgParser(Object result) {
    return 'Parser error: $result';
  }

  @override
  String errorOrgExecution(Object message, String code) {
    return 'Execution error in the below code: $message\n\n$code';
  }

  @override
  String errorOrgTimeout(num timeout, String code) {
    final intl.NumberFormat timeoutNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String timeoutString = timeoutNumberFormat.format(timeout);

    return 'Evaluation of the below code timed out after ${timeoutString}ms.\n\n$code';
  }

  @override
  String errorOrgArgument(Object item) {
    return 'Invalid argument: $item';
  }

  @override
  String get errorDecryptionFailed => 'Decryption failed';

  @override
  String errorLinkNotHandled(Object link) {
    return 'Couldn’t open link “$link”';
  }

  @override
  String errorExternalIdNotFound(String id) {
    return 'File with ID “$id” not found';
  }

  @override
  String errorSectionNotFound(String section) {
    return 'Section not found: $section';
  }

  @override
  String errorUnsupportedSearchOption(String option) {
    return 'Unsupported search option: $option';
  }

  @override
  String errorSchedulingNotifications(Object message) {
    return 'Failed to schedule notifications: $message';
  }

  @override
  String get editInsertedHeadline => '[Inserted by edit]';

  @override
  String get donateItemTitle => 'Donate to support Orgro';

  @override
  String get donateItemSubtitle => 'Your support is appreciated!';

  @override
  String get entitlementsLoadingItem => 'Loading info...';

  @override
  String entitlementsFreeTrialItem(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(
      localeName,
    ).add_jm();
    final String dateString = dateDateFormat.format(date);

    return 'Your free trial ends at $dateString';
  }

  @override
  String get entitlementsTrialExpiredItem => 'Your free trial has ended';

  @override
  String entitlementsPurchaseItemTitle(String price) {
    return 'Purchase Orgro for $price (one-time payment)';
  }

  @override
  String get entitlementsPurchaseItemSubtitle =>
      'Unlock all features and support development';

  @override
  String get entitlementsRestorePurchasesItem => 'Restore purchases';

  @override
  String get entitlementsPurchasedItem => 'Purchased';

  @override
  String get entitlementsPurchasedItemSubtitle => 'Thank you for your support';

  @override
  String get entitlementsLegacyPurchaseItemSubtitle =>
      'Thank you for being a long-time supporter!';

  @override
  String get entitlementsLockedDialogTitle => 'Your free trial has ended';

  @override
  String get entitlementsLockedDialogMessage =>
      'To continue using Orgro, please purchase a license or restore your previous purchases.\n\nPurchasing a license is a one-time payment that unlocks all features.';

  @override
  String entitlementsLockedDialogActionPurchase(String price) {
    return 'Purchase ($price)';
  }

  @override
  String get entitlementsLockedDialogActionRestore => 'Restore';

  @override
  String get entitlementsLockedDialogActionMoreInfo => 'Learn more';
}

/// The translations for English, as used in the United States (`en_US`).
class AppLocalizationsEnUs extends AppLocalizationsEn {
  AppLocalizationsEnUs() : super('en_US');

  @override
  String get appTitle => 'Orgro';

  @override
  String get menuItemAppearance => 'Appearance';

  @override
  String get menuItemSettings => 'Settings';

  @override
  String get menuItemClearCache => 'Clear cache';

  @override
  String get menuItemOrgroManual => 'Orgro Manual';

  @override
  String get menuItemOrgManual => 'Org Manual';

  @override
  String get menuItemTestFile => 'Test File';

  @override
  String get menuItemAbout => 'About';

  @override
  String get menuItemOpenUrl => 'Open URL';

  @override
  String get quickActionNewDocument => 'New Document';

  @override
  String quickActionTopPin(String name) {
    return 'Open $name';
  }

  @override
  String get appearanceModeAutomatic => 'Automatic';

  @override
  String get appearanceModeLight => 'Light';

  @override
  String get appearanceModeDark => 'Dark';

  @override
  String get settingsScreenTitle => 'Settings';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsSectionDefaultText => 'Default text';

  @override
  String get settingsSectionNotifications => 'Notifications';

  @override
  String get settingsSectionDataManagement => 'Data management';

  @override
  String get settingsSectionDonate => 'Donate';

  @override
  String get settingsSectionPurchase => 'Purchase';

  @override
  String get agendaNotificationsChannelName => 'Agenda Notifications';

  @override
  String get agendaNotificationsChannelDescription =>
      'Notifications for Org Agenda items';

  @override
  String get agendaNotificationsActionView => 'View';

  @override
  String get settingsItemLoading => 'Loading...';

  @override
  String get settingsItemTheme => 'Theme';

  @override
  String get settingsItemTextScale => 'Scale';

  @override
  String get settingsItemFontFamily => 'Font';

  @override
  String get settingsItemDefaultTextPreviewString =>
      'This is what document text will look like in the selected font and scale.\n\nTap to edit.';

  @override
  String get settingsItemGrantNotificationPermissions => 'Enable notifications';

  @override
  String settingsItemInspectNotifications(num n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString pending notifications',
      one: '1 pending notification',
      zero: 'No notifications',
    );
    return '$_temp0';
  }

  @override
  String get settingsDialogNotificationsTitle => 'Pending notifications';

  @override
  String get settingsItemClearNotifications => 'Clear all notifications';

  @override
  String get settingsActionClearCache => 'Clear cache';

  @override
  String get settingsActionResetPreferences => 'Restore defaults';

  @override
  String get settingsActionResetDirectoryPermissions =>
      'Reset directory permissions';

  @override
  String get snackbarMessageNotificationsCleared => 'Notifications cleared';

  @override
  String get snackbarMessageCacheCleared => 'Cache cleared';

  @override
  String get snackbarMessagePreferencesReset => 'Preferences reset';

  @override
  String get snackbarMessageDirectoryPermissionsReset =>
      'Directory permissions reset';

  @override
  String get confirmResetPreferencesDialogTitle => 'Restore defaults?';

  @override
  String get confirmResetPreferencesDialogMessage =>
      'This will reset all preferences to their default values. This action can’t be undone.';

  @override
  String get confirmResetPreferencesActionReset => 'Restore';

  @override
  String get confirmResetPreferencesActionCancel => 'Cancel';

  @override
  String get aboutLinkSupport => 'Support · Feedback';

  @override
  String get aboutLinkChangelog => 'Changelog';

  @override
  String get buttonOpenFile => 'Open File';

  @override
  String get buttonCreateFile => 'Create File';

  @override
  String get buttonOpenOrgroManual => 'Open Orgro Manual';

  @override
  String get buttonOpenOrgManual => 'Open Org Manual';

  @override
  String get buttonOpenUrl => 'Open URL';

  @override
  String get buttonSupport => 'Support · Feedback';

  @override
  String buttonVersion(String version) {
    return 'v$version';
  }

  @override
  String get sectionHeaderPinnedFiles => 'Pinned files';

  @override
  String get sectionHeaderRecentFiles => 'Recent files';

  @override
  String get recentFilesSortDialogTitle => 'Sort by';

  @override
  String get sortKeyLastOpened => 'Last opened';

  @override
  String get sortKeyName => 'Name';

  @override
  String get sortKeyLocation => 'Location';

  @override
  String get sortOrderAscending => 'Ascending';

  @override
  String get sortOrderDescending => 'Descending';

  @override
  String get fileSourceDocuments => 'Documents';

  @override
  String get fileSourceDownloads => 'Downloads';

  @override
  String get fileSourceGoogleDrive => 'Google Drive';

  @override
  String get menuItemReaderMode => 'Reader mode';

  @override
  String get menuItemWakelock => 'Keep screen on';

  @override
  String get menuItemFullWidth => 'Full width';

  @override
  String get menuItemScrollTop => 'Scroll to top';

  @override
  String get menuItemScrollBottom => 'Scroll to bottom';

  @override
  String get menuItemUndo => 'Undo';

  @override
  String get menuItemRedo => 'Redo';

  @override
  String get hintTextSearch => 'Search...';

  @override
  String searchHits(num n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString hits',
      one: '1 hit',
      zero: '0 hits',
    );
    return '$_temp0';
  }

  @override
  String searchResultSelection(num current, num total) {
    final intl.NumberFormat currentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String currentString = currentNumberFormat.format(current);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$currentString / $totalString';
  }

  @override
  String get customFilterChipName => 'Custom';

  @override
  String get snackbarMessageNeedsDirectoryPermissions =>
      'Orgro doesn’t have permission to resolve relative links';

  @override
  String get snackbarActionGrantAccess => 'Grant access';

  @override
  String get snackbarMessageNeedsEncryptionKey =>
      'Could not save. Missing encryption password.';

  @override
  String get snackbarActionEnterEncryptionKey => 'Enter password';

  @override
  String get snackbarMessageNeedsNotificationsPermissions =>
      'Orgro doesn’t have permission to send notifications';

  @override
  String get snackbarActionGrantNotificationsPermissions => 'Allow';

  @override
  String get dialogTitleError => 'Error';

  @override
  String get dialogActionConfirm => 'OK';

  @override
  String get dialogActionCancel => 'Cancel';

  @override
  String get dialogActionHelp => 'Help';

  @override
  String get pageTitleError => 'Error';

  @override
  String get pageTitleLoading => 'Loading...';

  @override
  String pageTitleNarrow(String name) {
    return '$name › narrow';
  }

  @override
  String pageTitleEditing(String name) {
    return '$name › editing';
  }

  @override
  String get sectionActionNarrow => 'Narrow';

  @override
  String get sectionActionCycleTodo => 'Cycle TODO';

  @override
  String get bannerBodyRemoteImages =>
      'This document contains remote images. Would you like to load them?';

  @override
  String get bannerBodyActionShowAlways => 'Always';

  @override
  String get bannerBodyActionShowNever => 'Never';

  @override
  String get bannerBodyActionShowOnce => 'Just once';

  @override
  String get bannerBodyRelativeLinks =>
      'This document contains relative links. Would you like to grant access?';

  @override
  String get bannerBodyActionGrantNotNow => 'Not now';

  @override
  String get bannerBodyActionGrantNever => 'Never';

  @override
  String get bannerBodyActionGrantNow => 'Grant access';

  @override
  String get bannerBodySaveDocumentOrg =>
      'Would you like to save changes to this document? *This is an experimental feature.* Make sure to back up your files. [[https://orgro.org/faq/#can-i-edit-my-files-with-orgro][Learn More]]';

  @override
  String get bannerBodyActionSaveAlways => 'Always';

  @override
  String get bannerBodyActionSaveNever => 'Never';

  @override
  String get bannerBodyActionSaveOnce => 'Just this time';

  @override
  String get bannerBodyDecryptContent =>
      'This document contains encrypted content. Decrypt it now?';

  @override
  String get bannerBodyActionDecryptNow => 'Decrypt';

  @override
  String get bannerBodyActionDecryptNotNow => 'Not now';

  @override
  String get bannerBodyActionDecryptNever => 'Never';

  @override
  String get bannerBodyAgendaNotifications =>
      'Get notifications for agenda items in this file?';

  @override
  String get bannerBodyActionAgendaEnable => 'Notify me';

  @override
  String get bannerBodyActionAgendaNotNow => 'Not now';

  @override
  String get bannerBodyActionAgendaNever => 'Never';

  @override
  String get saveChangesDialogTitle => 'Save changes?';

  @override
  String get saveChangesDialogMessage =>
      'Orgro can’t write your changes back to the original file.';

  @override
  String get saveActionShare => 'Share';

  @override
  String get saveActionDiscard => 'Discard';

  @override
  String get saveActionSaveAs => 'Save as';

  @override
  String get discardChangesDialogTitle => 'Discard changes?';

  @override
  String get discardActionDiscard => 'Discard';

  @override
  String get discardActionCancel => 'Cancel';

  @override
  String get savedMessage => 'Saved';

  @override
  String get inputDecryptionPasswordDialogTitle =>
      'Enter password for decrypting';

  @override
  String get inputEncryptionPasswordDialogTitle =>
      'Enter password for encrypting';

  @override
  String get inputEncryptionPasswordDialogBody =>
      'This password will be used to encrypt Org Crypt sections for which no password has been specified.';

  @override
  String get inputCustomFilterDialogTitle => 'Custom filter query';

  @override
  String get inputCustomFilterDialogHistoryButton => 'History';

  @override
  String get loadingProgressDialogTitle => 'Loading…';

  @override
  String get preparingProgressDialogTitle => 'Preparing…';

  @override
  String get decryptingProgressDialogTitle => 'Decrypting…';

  @override
  String get encryptingProgressDialogTitle => 'Encrypting…';

  @override
  String get serializingProgressDialogTitle => 'Serializing…';

  @override
  String get savingProgressDialogTitle => 'Saving…';

  @override
  String get searchingProgressDialogTitle => 'Searching…';

  @override
  String get citationsDialogTitle => 'Citations';

  @override
  String get createFileDialogTitle => 'Create new file';

  @override
  String get createFileDefaultName => 'untitled.org';

  @override
  String get saveAsDialogTitle => 'Save as';

  @override
  String get inputUrlDialogTitle => 'Enter URL';

  @override
  String get startTimePickerTitle => 'Select start time';

  @override
  String get endTimePickerTitle => 'Select end time';

  @override
  String get captureToDialogTitle => 'Capture to';

  @override
  String get captureToClipboardItem => 'Clipboard';

  @override
  String get captureToNewDocumentItem => 'New file';

  @override
  String get snackbarMessageInvalidCaptureUri => 'Invalid capture URL';

  @override
  String get snackbarMessageBibliographiesNotFound => 'No bibliographies found';

  @override
  String get snackbarMessageCitationKeysNotFound => 'Citation keys not found';

  @override
  String get snackbarMessageCitationsNotFound => 'Citations not found';

  @override
  String snackbarMessageSomeCitationsNotFound(String citations) {
    return 'Citations not found: $citations';
  }

  @override
  String get errorCannotResolveRelativePath =>
      'Can’t resolve path relative to this document';

  @override
  String errorPathResolvedToNonFile(String path, String resolved) {
    return '$path resolved to a non-file: $resolved';
  }

  @override
  String errorUnknownType(Object type) {
    return 'Unknown type: $type';
  }

  @override
  String errorUnexpectedHttpResponse(Object response) {
    return 'Unexpected HTTP response: $response';
  }

  @override
  String errorOrgParser(Object result) {
    return 'Parser error: $result';
  }

  @override
  String errorOrgExecution(Object message, String code) {
    return 'Execution error in the below code: $message\n\n$code';
  }

  @override
  String errorOrgTimeout(num timeout, String code) {
    final intl.NumberFormat timeoutNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String timeoutString = timeoutNumberFormat.format(timeout);

    return 'Evaluation of the below code timed out after ${timeoutString}ms.\n\n$code';
  }

  @override
  String errorOrgArgument(Object item) {
    return 'Invalid argument: $item';
  }

  @override
  String get errorDecryptionFailed => 'Decryption failed';

  @override
  String errorLinkNotHandled(Object link) {
    return 'Couldn’t open link “$link”';
  }

  @override
  String errorExternalIdNotFound(String id) {
    return 'File with ID “$id” not found';
  }

  @override
  String errorSectionNotFound(String section) {
    return 'Section not found: $section';
  }

  @override
  String errorUnsupportedSearchOption(String option) {
    return 'Unsupported search option: $option';
  }

  @override
  String errorSchedulingNotifications(Object message) {
    return 'Failed to schedule notifications: $message';
  }

  @override
  String get editInsertedHeadline => '[Inserted by edit]';

  @override
  String get donateItemTitle => 'Donate to support Orgro';

  @override
  String get donateItemSubtitle => 'Your support is appreciated!';

  @override
  String get entitlementsLoadingItem => 'Loading info...';

  @override
  String entitlementsFreeTrialItem(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(
      localeName,
    ).add_jm();
    final String dateString = dateDateFormat.format(date);

    return 'Your free trial ends at $dateString';
  }

  @override
  String get entitlementsTrialExpiredItem => 'Your free trial has ended';

  @override
  String entitlementsPurchaseItemTitle(String price) {
    return 'Purchase Orgro for $price (one-time payment)';
  }

  @override
  String get entitlementsPurchaseItemSubtitle =>
      'Unlock all features and support development';

  @override
  String get entitlementsRestorePurchasesItem => 'Restore purchases';

  @override
  String get entitlementsPurchasedItem => 'Purchased';

  @override
  String get entitlementsPurchasedItemSubtitle => 'Thank you for your support';

  @override
  String get entitlementsLegacyPurchaseItemSubtitle =>
      'Thank you for being a long-time supporter!';

  @override
  String get entitlementsLockedDialogTitle => 'Your free trial has ended';

  @override
  String get entitlementsLockedDialogMessage =>
      'To continue using Orgro, please purchase a license or restore your previous purchases.\n\nPurchasing a license is a one-time payment that unlocks all features.';

  @override
  String entitlementsLockedDialogActionPurchase(String price) {
    return 'Purchase ($price)';
  }

  @override
  String get entitlementsLockedDialogActionRestore => 'Restore';

  @override
  String get entitlementsLockedDialogActionMoreInfo => 'Learn more';
}
