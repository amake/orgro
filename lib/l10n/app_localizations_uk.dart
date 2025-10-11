// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get appTitle => 'Orgro';

  @override
  String get menuItemAppearance => 'Вигляд';

  @override
  String get menuItemSettings => 'Settings';

  @override
  String get menuItemClearCache => 'Очистити кеш';

  @override
  String get menuItemOrgroManual => 'Посібник Orgro';

  @override
  String get menuItemOrgManual => 'Посібник Org';

  @override
  String get menuItemTestFile => 'Test File';

  @override
  String get menuItemAbout => 'Про застосунок';

  @override
  String get menuItemOpenUrl => 'Open URL';

  @override
  String get quickActionNewDocument => 'New Document';

  @override
  String quickActionTopPin(String name) {
    return 'Open $name';
  }

  @override
  String get appearanceModeAutomatic => 'Автоматичний';

  @override
  String get appearanceModeLight => 'Світлий';

  @override
  String get appearanceModeDark => 'Темний';

  @override
  String get settingsScreenTitle => 'Settings';

  @override
  String get settingsSectionDefaultText => 'Default text';

  @override
  String get settingsSectionNotifications => 'Notifications';

  @override
  String get settingsSectionDataManagement => 'Data management';

  @override
  String get agendaNotificationsChannelName => 'Agenda Notifications';

  @override
  String get agendaNotificationsChannelDescription =>
      'Notifications for Org Agenda items';

  @override
  String get settingsItemLoading => 'Loading...';

  @override
  String get settingsItemAppearance => 'Appearance';

  @override
  String get settingsItemTextScale => 'Scale';

  @override
  String get settingsItemFontFamily => 'Font';

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
  String get snackbarMessageNotificationsCleared => 'Notifications cleared';

  @override
  String get snackbarMessageCacheCleared => 'Кеш очищено';

  @override
  String get snackbarMessagePreferencesReset => 'Preferences reset';

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
  String get aboutLinkSupport => 'Підтримка · Зворотній звʼязок';

  @override
  String get aboutLinkChangelog => 'Список змін';

  @override
  String get buttonOpenFile => 'Відкрити файл';

  @override
  String get buttonCreateFile => 'Create File';

  @override
  String get buttonOpenOrgroManual => 'Відкрити Посібник Orgro';

  @override
  String get buttonOpenOrgManual => 'Відкрити Посібник Org';

  @override
  String get buttonOpenUrl => 'Open URL';

  @override
  String get buttonSupport => 'Підтримка · Зворотній звʼязок';

  @override
  String buttonVersion(String version) {
    return 'в$version';
  }

  @override
  String get sectionHeaderPinnedFiles => 'Pinned files';

  @override
  String get sectionHeaderRecentFiles => 'Останні файли';

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
  String get menuItemReaderMode => 'Режим читання';

  @override
  String get menuItemFullWidth => 'Full width';

  @override
  String get menuItemScrollTop => 'Прокрутити вверх';

  @override
  String get menuItemScrollBottom => 'Прокрутити вниз';

  @override
  String get menuItemUndo => 'Undo';

  @override
  String get menuItemRedo => 'Redo';

  @override
  String get hintTextSearch => 'Шукати...';

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
      'Orgro немає прав для розвʼязання відносних посилань';

  @override
  String get snackbarActionGrantAccess => 'Надати дозвіл';

  @override
  String get snackbarMessageNeedsEncryptionKey =>
      'Could not save. Missing encryption password.';

  @override
  String get snackbarActionEnterEncryptionKey => 'Enter password';

  @override
  String get snackbarMessageNotificationPermissionsDenied =>
      'No permission for notifications';

  @override
  String get dialogTitleError => 'Помилка';

  @override
  String get dialogActionConfirm => 'OK';

  @override
  String get dialogActionCancel => 'Cancel';

  @override
  String get dialogActionHelp => 'Help';

  @override
  String get pageTitleError => 'Помилка';

  @override
  String get pageTitleLoading => 'Завантаження...';

  @override
  String pageTitleNarrow(String name) {
    return '$name › гілка';
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
      'Цей документ містить віддалені зображення. Бажаєте завантажувати їх?';

  @override
  String get bannerBodyActionShowAlways => 'Завжди';

  @override
  String get bannerBodyActionShowNever => 'Ніколи';

  @override
  String get bannerBodyActionShowOnce => 'Лише раз';

  @override
  String get bannerBodyRelativeLinks =>
      'Цей документ містить відносні посилання. Бажаєте надати дозвіл?';

  @override
  String get bannerBodyActionGrantNotNow => 'Не зараз';

  @override
  String get bannerBodyActionGrantNever => 'Ніколи';

  @override
  String get bannerBodyActionGrantNow => 'Надати дозвіл';

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
      'Не можливо розвʼязати шлях відносно цього документа';

  @override
  String errorPathResolvedToNonFile(String path, String resolved) {
    return '$path визначено як не файл: $resolved';
  }

  @override
  String errorUnknownType(Object type) {
    return 'Невідомий тип: $type';
  }

  @override
  String errorUnexpectedHttpResponse(Object response) {
    return 'Неочікувана відповідь HTTP: $response';
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
  String get editInsertedHeadline => '[Inserted by edit]';
}
