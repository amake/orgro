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
  String get menuItemClearCache => 'Clear cache';

  @override
  String get menuItemOrgroManual => 'Orgro Handbuch';

  @override
  String get menuItemOrgManual => 'Org Handbuch';

  @override
  String get menuItemTestFile => 'Testdatei';

  @override
  String get menuItemAbout => 'Über';

  @override
  String get menuItemOpenUrl => 'Öffne URL';

  @override
  String get quickActionNewDocument => 'Neues Dokument';

  @override
  String quickActionTopPin(String name) {
    return 'Öffne $name';
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
  String get settingsSectionAppearance => 'Aussehen';

  @override
  String get settingsSectionDefaultText => 'Vorgegebener Text';

  @override
  String get settingsSectionNotifications => 'Benachrichtigungen';

  @override
  String get settingsSectionDataManagement => 'Datenverwaltung';

  @override
  String get settingsSectionDonate => 'Donate';

  @override
  String get settingsSectionPurchase => 'Purchase';

  @override
  String get agendaNotificationsChannelName => 'Agenda Benachrichtigungen';

  @override
  String get agendaNotificationsChannelDescription =>
      'Benachrichtigungen für Org Agenda Einträge';

  @override
  String get agendaNotificationsActionView => 'View';

  @override
  String get settingsItemLoading => 'Ladet…';

  @override
  String get settingsItemTheme => 'Theme';

  @override
  String get settingsItemTextScale => 'Größe';

  @override
  String get settingsItemFontFamily => 'Schriftart';

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
      other: '$nString offene Benachrichtigungen',
      one: '1 offene Benachrichtigung',
      zero: 'Keine Benachrichtigungen',
    );
    return '$_temp0';
  }

  @override
  String get settingsDialogNotificationsTitle => 'Offene Benachrichtigungen';

  @override
  String get settingsItemClearNotifications => 'Lösche alle Benachrichtigungen';

  @override
  String get settingsActionClearCache => 'Cache löschen';

  @override
  String get settingsActionResetPreferences => 'Einstellungen zurücksetzen';

  @override
  String get settingsActionResetDirectoryPermissions =>
      'Verzeichnisberechtigungen zurücksetzen';

  @override
  String get snackbarMessageNotificationsCleared =>
      'Benachrichtigungen gelöscht';

  @override
  String get snackbarMessageCacheCleared => 'Cache gelöscht';

  @override
  String get snackbarMessagePreferencesReset => 'Einstellungen zurückgesetzt';

  @override
  String get snackbarMessageDirectoryPermissionsReset =>
      'Verzeichnisberechtigungen zurückgesetzt';

  @override
  String get confirmResetPreferencesDialogTitle => 'Einstellungen löschen?';

  @override
  String get confirmResetPreferencesDialogMessage =>
      'Es werden alle Einstellungen zurückgesetzt. Dies kann nicht rückgängig gemacht werden.';

  @override
  String get confirmResetPreferencesActionReset => 'Löschen';

  @override
  String get confirmResetPreferencesActionCancel => 'Abbrechen';

  @override
  String get aboutLinkSupport => 'Unterstützung · Feedback';

  @override
  String get aboutLinkChangelog => 'Changelog';

  @override
  String get buttonOpenFile => 'Öffne Datei';

  @override
  String get buttonCreateFile => 'Erstelle Datei';

  @override
  String get buttonOpenOrgroManual => 'Öffne Orgro Handbuch';

  @override
  String get buttonOpenOrgManual => 'Öffne Org Handbuch';

  @override
  String get buttonOpenUrl => 'Öffne URL';

  @override
  String get buttonSupport => 'Support · Feedback';

  @override
  String buttonVersion(String version) {
    return 'v$version';
  }

  @override
  String get sectionHeaderPinnedFiles => 'Angeheftete Dateien';

  @override
  String get sectionHeaderRecentFiles => 'Letzte Dateien';

  @override
  String get recentFilesSortDialogTitle => 'Sorte nach';

  @override
  String get sortKeyLastOpened => 'Letztens geöffnet';

  @override
  String get sortKeyName => 'Name';

  @override
  String get sortKeyLocation => 'Ort';

  @override
  String get sortOrderAscending => 'Aufsteigend';

  @override
  String get sortOrderDescending => 'Absteigend';

  @override
  String get fileSourceDocuments => 'Dokumente';

  @override
  String get fileSourceDownloads => 'Downloads';

  @override
  String get fileSourceGoogleDrive => 'Google Drive';

  @override
  String get menuItemReaderMode => 'Lesemodus';

  @override
  String get menuItemWakelock => 'Keep screen on';

  @override
  String get menuItemFullWidth => 'Volle breite';

  @override
  String get menuItemScrollTop => 'Nach oben scrollen';

  @override
  String get menuItemScrollBottom => 'Nach unten scrollen';

  @override
  String get menuItemUndo => 'Rückgängig';

  @override
  String get menuItemRedo => 'Wiederholen';

  @override
  String get hintTextSearch => 'Suchen…';

  @override
  String searchHits(num n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString Ergebnisse',
      one: '1 Ergebnis',
      zero: '0 Ergebnisse',
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
      'Konnte nicht Speichern. Verschlüsselungspasswort fehlt.';

  @override
  String get snackbarActionEnterEncryptionKey => 'Passwort eingeben';

  @override
  String get snackbarMessageNeedsNotificationsPermissions =>
      'Orgro doesn’t have permission to send notifications';

  @override
  String get snackbarActionGrantNotificationsPermissions => 'Allow';

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
  String get pageTitleLoading => 'Ladet…';

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
      'Willst du Benachrichtigungen für Agenda Einträge in dieser Datei bekommen?';

  @override
  String get bannerBodyActionAgendaEnable => 'Ja';

  @override
  String get bannerBodyActionAgendaNotNow => 'Nicht jetzt';

  @override
  String get bannerBodyActionAgendaNever => 'Nie';

  @override
  String get saveChangesDialogTitle => 'Änderungen speichern?';

  @override
  String get saveChangesDialogMessage =>
      'Orgro kann deine Änderungen nicht speichern.';

  @override
  String get saveActionShare => 'Teilen';

  @override
  String get saveActionDiscard => 'Verwerfen';

  @override
  String get saveActionSaveAs => 'Speichern als';

  @override
  String get discardChangesDialogTitle => 'Änderung verwerfen?';

  @override
  String get discardActionDiscard => 'Verwerfen';

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
  String get loadingProgressDialogTitle => 'Laden…';

  @override
  String get preparingProgressDialogTitle => 'Vorbereiten…';

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
  String get createFileDefaultName => 'unbenannt.org';

  @override
  String get saveAsDialogTitle => 'Speichern als';

  @override
  String get inputUrlDialogTitle => 'URL eingeben';

  @override
  String get startTimePickerTitle => 'Startzeit eingeben';

  @override
  String get endTimePickerTitle => 'Endzeit eingeben';

  @override
  String get captureToDialogTitle => 'Capture to';

  @override
  String get captureToClipboardItem => 'Clipboard';

  @override
  String get captureToNewDocumentItem => 'New file';

  @override
  String get snackbarMessageInvalidCaptureUri => 'Invalid capture URL';

  @override
  String get snackbarMessageBibliographiesNotFound =>
      'Keine Bibliografien gefunden';

  @override
  String get snackbarMessageCitationKeysNotFound =>
      'Zitatenschlüssel nicht gefunden';

  @override
  String get snackbarMessageCitationsNotFound => 'Zitate nicht gefunden';

  @override
  String snackbarMessageSomeCitationsNotFound(String citations) {
    return 'Zitate nicht gefunden: $citations';
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
    return 'Parserfehler: $result';
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
    return 'Konnte nicht Link Öffnen: “$link”';
  }

  @override
  String errorExternalIdNotFound(String id) {
    return 'Datei mit ID “$id” nicht gefunden';
  }

  @override
  String errorSectionNotFound(String section) {
    return 'Teil nicht gefunden: $section';
  }

  @override
  String errorUnsupportedSearchOption(String option) {
    return 'Nicht unterstützte Suchoption: $option';
  }

  @override
  String errorSchedulingNotifications(Object message) {
    return 'Failed to schedule notifications: $message';
  }

  @override
  String get editInsertedHeadline => '[Eingefügt durch Bearbeitung]';

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
  String get entitlementsPurchaseItemTitle => 'Purchase Orgro';

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
      'To continue using Orgro, please purchase a license or restore your previous purchases.';

  @override
  String get entitlementsLockedDialogActionPurchase => 'Purchase';

  @override
  String get entitlementsLockedDialogActionRestore => 'Restore';

  @override
  String get entitlementsLockedDialogActionMoreInfo => 'Learn more';
}
