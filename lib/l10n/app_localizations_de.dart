// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Orgro';

  @override
  String get menuItemAppearance => 'Aussehen';

  @override
  String get menuItemSettings => 'Einstellungen';

  @override
  String get menuItemClearCache => 'Cache löschen';

  @override
  String get menuItemOrgroManual => 'Orgro Handbuch';

  @override
  String get menuItemOrgManual => 'Org Handbuch';

  @override
  String get menuItemTestFile => 'Test Datei';

  @override
  String get menuItemAbout => 'Über';

  @override
  String get menuItemOpenUrl => 'Open URL';

  @override
  String get quickActionNewDocument => 'New Document';

  @override
  String quickActionTopPin(String name) {
    return 'Open $name';
  }

  @override
  String get appearanceModeAutomatic => 'Automatisch';

  @override
  String get appearanceModeLight => 'Hell';

  @override
  String get appearanceModeDark => 'Dunkel';

  @override
  String get settingsScreenTitle => 'Einstellungen';

  @override
  String get settingsSectionDefaultText => 'Schrift';

  @override
  String get settingsSectionNotifications => 'Notifications';

  @override
  String get settingsSectionDataManagement => 'Datenverwaltung';

  @override
  String get agendaNotificationsChannelName => 'Agenda Notifications';

  @override
  String get agendaNotificationsChannelDescription =>
      'Notifications for Org Agenda items';

  @override
  String get settingsItemLoading => 'Loading...';

  @override
  String get settingsItemAppearance => 'Farbschema';

  @override
  String get settingsItemTextScale => 'Größe';

  @override
  String get settingsItemFontFamily => 'Schriftart';

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
  String get settingsActionClearCache => 'Cache löschen';

  @override
  String get settingsActionResetPreferences => 'Einstellungen Zurücksetzen';

  @override
  String get snackbarMessageNotificationsCleared => 'Notifications cleared';

  @override
  String get snackbarMessageCacheCleared => 'Cache gelöscht';

  @override
  String get snackbarMessagePreferencesReset => 'Einstellungen Zurückgesetzt';

  @override
  String get confirmResetPreferencesDialogTitle =>
      'Einstellungen Zurücksetzen?';

  @override
  String get confirmResetPreferencesDialogMessage =>
      'Es werden alle Einstellungen zurückgesetzt. Dies kann nicht rückgängig gemacht werden.';

  @override
  String get confirmResetPreferencesActionReset => 'Zurücksetzen';

  @override
  String get confirmResetPreferencesActionCancel => 'Abbrechen';

  @override
  String get aboutLinkSupport => 'Support · Feedback';

  @override
  String get aboutLinkChangelog => 'Changelog';

  @override
  String get buttonOpenFile => 'Datei öffnen';

  @override
  String get buttonCreateFile => 'Datei erstellen';

  @override
  String get buttonOpenOrgroManual => 'Orgro Handbuch öffnen';

  @override
  String get buttonOpenOrgManual => 'Org Handbuch öffnen';

  @override
  String get buttonOpenUrl => 'Open URL';

  @override
  String get buttonSupport => 'Hilfe · Feedback';

  @override
  String buttonVersion(String version) {
    return 'v$version';
  }

  @override
  String get sectionHeaderPinnedFiles => 'Pinned files';

  @override
  String get sectionHeaderRecentFiles => 'Zuletzt geöffnet';

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
  String get fileSourceDocuments => 'Dokumente';

  @override
  String get fileSourceDownloads => 'Downloads';

  @override
  String get fileSourceGoogleDrive => 'Google Drive';

  @override
  String get menuItemReaderMode => 'Lesemodus';

  @override
  String get menuItemFullWidth => 'Volle Breite';

  @override
  String get menuItemScrollTop => 'Nach Oben Scrollen';

  @override
  String get menuItemScrollBottom => 'Nach Unten Scrollen';

  @override
  String get menuItemUndo => 'Rückgängig';

  @override
  String get menuItemRedo => 'Wiederholen';

  @override
  String get hintTextSearch => 'Suchen...';

  @override
  String searchHits(num n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString Treffer',
      one: '1 Treffer',
      zero: '0 Treffer',
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
  String get customFilterChipName => 'Benutzerdefiniert';

  @override
  String get snackbarMessageNeedsDirectoryPermissions =>
      'Orgro hat nicht die Berechtigung um relative Links aufzulösen';

  @override
  String get snackbarActionGrantAccess => 'Zugriff erlauben';

  @override
  String get snackbarMessageNeedsEncryptionKey =>
      'Konnte nicht Speichern. Verschlüsselung Passwort fehlt.';

  @override
  String get snackbarActionEnterEncryptionKey => 'Passwort eingeben';

  @override
  String get snackbarMessageNotificationPermissionsDenied =>
      'No permission for notifications';

  @override
  String get dialogTitleError => 'Fehler';

  @override
  String get dialogActionConfirm => 'OK';

  @override
  String get dialogActionCancel => 'Abbrechen';

  @override
  String get dialogActionHelp => 'Hilfe';

  @override
  String get pageTitleError => 'Fehler';

  @override
  String get pageTitleLoading => 'Laden...';

  @override
  String pageTitleNarrow(String name) {
    return '$name › Beschränkt';
  }

  @override
  String pageTitleEditing(String name) {
    return '$name › Bearbeiten';
  }

  @override
  String get sectionActionNarrow => 'Beschränkt';

  @override
  String get sectionActionCycleTodo => 'TODO wechseln';

  @override
  String get bannerBodyRemoteImages =>
      'Dieses Dokument beinhaltet Bilder aus externen Quellen. Sollen diese Bilder geladen werden?';

  @override
  String get bannerBodyActionShowAlways => 'Immer';

  @override
  String get bannerBodyActionShowNever => 'Nie';

  @override
  String get bannerBodyActionShowOnce => 'Nur dieses Mal';

  @override
  String get bannerBodyRelativeLinks =>
      'Dieses Dokument beinhaltet relative Links. Zugriff erlauben?';

  @override
  String get bannerBodyActionGrantNotNow => 'Nicht jetzt';

  @override
  String get bannerBodyActionGrantNever => 'Nie';

  @override
  String get bannerBodyActionGrantNow => 'Zugriff erlauben';

  @override
  String get bannerBodySaveDocumentOrg =>
      'Änderungen speichern? *Dies ist ein experimentales Feature.* Stelle sicher deine Dateien zu sichern. [[https://orgro.org/faq/#can-i-edit-my-files-with-orgro][Mehr lernen]]';

  @override
  String get bannerBodyActionSaveAlways => 'Immer';

  @override
  String get bannerBodyActionSaveNever => 'Nie';

  @override
  String get bannerBodyActionSaveOnce => 'Nur dieses Mal';

  @override
  String get bannerBodyDecryptContent =>
      'Dieses Dokument beinhaltet verschlüsselte Inhalte. Jetzt entschlüsseln?';

  @override
  String get bannerBodyActionDecryptNow => 'Entschlüsseln';

  @override
  String get bannerBodyActionDecryptNotNow => 'Nicht jetzt';

  @override
  String get bannerBodyActionDecryptNever => 'Nie';

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
  String get saveChangesDialogTitle => 'Änderungen speichern?';

  @override
  String get saveChangesDialogMessage =>
      'Orgro kann deine Änderungen nicht speichern.';

  @override
  String get saveActionShare => 'Teilen';

  @override
  String get saveActionDiscard => 'Wegwerfen';

  @override
  String get saveActionSaveAs => 'Save as';

  @override
  String get discardChangesDialogTitle => 'Änderungen wegwerfen?';

  @override
  String get discardActionDiscard => 'Wegwerfen';

  @override
  String get discardActionCancel => 'Abbrechen';

  @override
  String get savedMessage => 'Gespeichert';

  @override
  String get inputDecryptionPasswordDialogTitle =>
      'Passwort für Entschlüsselung eingeben';

  @override
  String get inputEncryptionPasswordDialogTitle =>
      'Passwort für Verschlüsselung eingeben';

  @override
  String get inputEncryptionPasswordDialogBody =>
      'Dieses Password wird für die Verschlüsselung der Org Crypt Teile benutzt.';

  @override
  String get inputCustomFilterDialogTitle => 'Benutzerdefinierter Filter';

  @override
  String get inputCustomFilterDialogHistoryButton => 'Verlauf';

  @override
  String get loadingProgressDialogTitle => 'Loading…';

  @override
  String get preparingProgressDialogTitle => 'Preparing…';

  @override
  String get decryptingProgressDialogTitle => 'Entschlüsseln…';

  @override
  String get encryptingProgressDialogTitle => 'Verschlüsseln…';

  @override
  String get serializingProgressDialogTitle => 'Serialisieren…';

  @override
  String get savingProgressDialogTitle => 'Speichern…';

  @override
  String get searchingProgressDialogTitle => 'Suchen…';

  @override
  String get citationsDialogTitle => 'Zitate';

  @override
  String get createFileDialogTitle => 'Neue Datei erstellen';

  @override
  String get createFileDefaultName => 'unbetitelt.org';

  @override
  String get saveAsDialogTitle => 'Save as';

  @override
  String get inputUrlDialogTitle => 'Enter URL';

  @override
  String get startTimePickerTitle => 'Wähle Startzeit';

  @override
  String get endTimePickerTitle => 'Wähle Endzeit';

  @override
  String get snackbarMessageBibliographiesNotFound =>
      'Keine Bibliografien gefunden';

  @override
  String get snackbarMessageCitationKeysNotFound => 'Zitate nicht gefunden';

  @override
  String get snackbarMessageCitationsNotFound => 'Zitate nicht gefunden';

  @override
  String snackbarMessageSomeCitationsNotFound(String citations) {
    return 'Folgende Zitate nicht gefunden: $citations';
  }

  @override
  String get errorCannotResolveRelativePath =>
      'Kann nicht relativen Pfad zu diesem Dokument lösen';

  @override
  String errorPathResolvedToNonFile(String path, String resolved) {
    return '$path gelöst zu einer nicht vorhandenen Datei: $resolved';
  }

  @override
  String errorUnknownType(Object type) {
    return 'Unbekannter Typ: $type';
  }

  @override
  String errorUnexpectedHttpResponse(Object response) {
    return 'Unerwartete HTTP-Antwort: $response';
  }

  @override
  String errorOrgParser(Object result) {
    return 'Parser Fehler: $result';
  }

  @override
  String errorOrgExecution(Object message, String code) {
    return 'Fehler beim Ausführen vom unteren Code: $message\n\n$code';
  }

  @override
  String errorOrgTimeout(num timeout, String code) {
    final intl.NumberFormat timeoutNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String timeoutString = timeoutNumberFormat.format(timeout);

    return 'Durchführung vom unteren Code nach ${timeoutString}ms. unterbrochen\n\n$code';
  }

  @override
  String errorOrgArgument(Object item) {
    return 'Ungültiges Argument: $item';
  }

  @override
  String get errorDecryptionFailed => 'Entschlüsseln fehlgeschlagen';

  @override
  String errorLinkNotHandled(Object link) {
    return 'Konnte nicht Link öffnen: “$link”';
  }

  @override
  String errorExternalIdNotFound(String id) {
    return 'Datei mit ID “$id” nicht gefunden';
  }

  @override
  String get editInsertedHeadline => '[Von Bearbeitung eingefügt]';
}
