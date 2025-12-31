// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Orgro';

  @override
  String get menuItemAppearance => 'Внешний вид';

  @override
  String get menuItemSettings => 'Настройки';

  @override
  String get menuItemClearCache => 'Очистить кэш';

  @override
  String get menuItemOrgroManual => 'Руководство к Orgro';

  @override
  String get menuItemOrgManual => 'Руководство по Org';

  @override
  String get menuItemTestFile => 'Тестовый файл';

  @override
  String get menuItemAbout => 'О приложении';

  @override
  String get menuItemOpenUrl => 'Открыть URL-адрес';

  @override
  String get quickActionNewDocument => 'Новый документ';

  @override
  String quickActionTopPin(String name) {
    return 'Открытый $name';
  }

  @override
  String get appearanceModeAutomatic => 'Автоматически';

  @override
  String get appearanceModeLight => 'Светлая';

  @override
  String get appearanceModeDark => 'Тёмная';

  @override
  String get settingsScreenTitle => 'Настройки';

  @override
  String get settingsSectionAppearance => 'Внешний вид';

  @override
  String get settingsSectionDefaultText => 'Текст по умолчанию';

  @override
  String get settingsSectionNotifications => 'Notifications';

  @override
  String get settingsSectionDataManagement => 'Управление данных';

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
  String get settingsItemTextScale => 'Размер';

  @override
  String get settingsItemFontFamily => 'Шрифт';

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
  String get settingsActionClearCache => 'Очистить кэш';

  @override
  String get settingsActionResetPreferences =>
      'Восстановить изначальные настройки';

  @override
  String get settingsActionResetDirectoryPermissions =>
      'Reset directory permissions';

  @override
  String get snackbarMessageNotificationsCleared => 'Notifications cleared';

  @override
  String get snackbarMessageCacheCleared => 'Кэш очищен';

  @override
  String get snackbarMessagePreferencesReset => 'Сбросить настройки';

  @override
  String get snackbarMessageDirectoryPermissionsReset =>
      'Directory permissions reset';

  @override
  String get confirmResetPreferencesDialogTitle =>
      'Восстановить изначальные настройки?';

  @override
  String get confirmResetPreferencesDialogMessage =>
      'Это сбросит все настройки к изначальным значения. Это действие необратимо.';

  @override
  String get confirmResetPreferencesActionReset => 'Восстановить';

  @override
  String get confirmResetPreferencesActionCancel => 'Отмена';

  @override
  String get aboutLinkSupport => 'Поддержка · Обратная связь';

  @override
  String get aboutLinkChangelog => 'Список изменений';

  @override
  String get buttonOpenFile => 'Открыть файл';

  @override
  String get buttonCreateFile => 'Создать файл';

  @override
  String get buttonOpenOrgroManual => 'Открыть пособие по Orgro';

  @override
  String get buttonOpenOrgManual => 'Открыть руководство по Org';

  @override
  String get buttonOpenUrl => 'Открыть URL-адрес';

  @override
  String get buttonSupport => 'Поддержка · Обратная связь';

  @override
  String buttonVersion(String version) {
    return 'v$version';
  }

  @override
  String get sectionHeaderPinnedFiles => 'Прикреплённые файлы';

  @override
  String get sectionHeaderRecentFiles => 'Последние файлы';

  @override
  String get recentFilesSortDialogTitle => 'Сортировать по';

  @override
  String get sortKeyLastOpened => 'Последнее открытие';

  @override
  String get sortKeyName => 'Название';

  @override
  String get sortKeyLocation => 'Место';

  @override
  String get sortOrderAscending => 'Восходящий';

  @override
  String get sortOrderDescending => 'Нисходящий';

  @override
  String get fileSourceDocuments => 'Документы';

  @override
  String get fileSourceDownloads => 'Скачанное';

  @override
  String get fileSourceGoogleDrive => 'Google Drive';

  @override
  String get menuItemReaderMode => 'Режим чтения';

  @override
  String get menuItemWakelock => 'Keep screen on';

  @override
  String get menuItemFullWidth => 'Полноширинный';

  @override
  String get menuItemScrollTop => 'Прокрутить наверх';

  @override
  String get menuItemScrollBottom => 'Прокрутить вниз';

  @override
  String get menuItemUndo => 'Откатить';

  @override
  String get menuItemRedo => 'Повторить';

  @override
  String get hintTextSearch => 'Поиск...';

  @override
  String searchHits(num n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString совпадений',
      one: '1 совпадение',
      zero: '0 совпадений',
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
  String get customFilterChipName => 'Свой';

  @override
  String get snackbarMessageNeedsDirectoryPermissions =>
      'Orgro не имеет разрешения определять относительные пути';

  @override
  String get snackbarActionGrantAccess => 'Дать разрешение';

  @override
  String get snackbarMessageNeedsEncryptionKey =>
      'Не могу сохранить. Отсутствует пароль шифрования.';

  @override
  String get snackbarActionEnterEncryptionKey => 'Введите пароль';

  @override
  String get snackbarMessageNeedsNotificationsPermissions =>
      'Orgro doesn’t have permission to send notifications';

  @override
  String get snackbarActionGrantNotificationsPermissions => 'Allow';

  @override
  String get dialogTitleError => 'Ошибка';

  @override
  String get dialogActionConfirm => 'Ладно';

  @override
  String get dialogActionCancel => 'Отмена';

  @override
  String get dialogActionHelp => 'Справка';

  @override
  String get pageTitleError => 'Ошибка';

  @override
  String get pageTitleLoading => 'Загрузка...';

  @override
  String pageTitleNarrow(String name) {
    return '$name › ветка';
  }

  @override
  String pageTitleEditing(String name) {
    return '$name › правка';
  }

  @override
  String get sectionActionNarrow => 'Ветка';

  @override
  String get sectionActionCycleTodo => 'Цикл TODO';

  @override
  String get bannerBodyRemoteImages =>
      'Этот документ содержит внешние изображения. Вы хотите скачать их?';

  @override
  String get bannerBodyActionShowAlways => 'Всегда';

  @override
  String get bannerBodyActionShowNever => 'Никогда';

  @override
  String get bannerBodyActionShowOnce => 'Только в этот раз';

  @override
  String get bannerBodyRelativeLinks =>
      'Этот документ содержит относительные ссылки. Вы хотите дать доступ?';

  @override
  String get bannerBodyActionGrantNotNow => 'Не сейчас';

  @override
  String get bannerBodyActionGrantNever => 'Никогда';

  @override
  String get bannerBodyActionGrantNow => 'Дать доступ';

  @override
  String get bannerBodySaveDocumentOrg =>
      'Вы хотите сохранить изменения в этом документе? *Экспериментальная возможность.* Убедитесь что вы зарезервировали файлы. [[https://orgro.org/faq/#can-i-edit-my-files-with-orgro][Подробнее]]';

  @override
  String get bannerBodyActionSaveAlways => 'Всегда';

  @override
  String get bannerBodyActionSaveNever => 'Никогда';

  @override
  String get bannerBodyActionSaveOnce => 'Только в этот раз';

  @override
  String get bannerBodyDecryptContent =>
      'Этот документ содержит зашифрованный текст. Расшифровать его?';

  @override
  String get bannerBodyActionDecryptNow => 'Расшифровать';

  @override
  String get bannerBodyActionDecryptNotNow => 'Не сейчас';

  @override
  String get bannerBodyActionDecryptNever => 'Никогда';

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
  String get saveChangesDialogTitle => 'Сохранить изменения?';

  @override
  String get saveChangesDialogMessage =>
      'Orgro не может записать изменения в изначальный файл.';

  @override
  String get saveActionShare => 'Поделиться';

  @override
  String get saveActionDiscard => 'Отбросить изменения';

  @override
  String get saveActionSaveAs => 'Сохранить как';

  @override
  String get discardChangesDialogTitle => 'Отбросить изменения?';

  @override
  String get discardActionDiscard => 'Отбросить';

  @override
  String get discardActionCancel => 'Отмена';

  @override
  String get savedMessage => 'Сохранено';

  @override
  String get inputDecryptionPasswordDialogTitle =>
      'Введите пароль для расшифрования';

  @override
  String get inputEncryptionPasswordDialogTitle =>
      'Введите пароль для шифрования';

  @override
  String get inputEncryptionPasswordDialogBody =>
      'Этот пароль будет использоваться для шифрования разделов Org Crypt, для которых не указан пароль.';

  @override
  String get inputCustomFilterDialogTitle => 'Свой запрос фильтра';

  @override
  String get inputCustomFilterDialogHistoryButton => 'История';

  @override
  String get loadingProgressDialogTitle => 'Loading…';

  @override
  String get preparingProgressDialogTitle => 'Preparing…';

  @override
  String get decryptingProgressDialogTitle => 'Расшифрование…';

  @override
  String get encryptingProgressDialogTitle => 'Шифрование…';

  @override
  String get serializingProgressDialogTitle => 'Сериализация…';

  @override
  String get savingProgressDialogTitle => 'Сохранение…';

  @override
  String get searchingProgressDialogTitle => 'Поиск…';

  @override
  String get citationsDialogTitle => 'Цитаты';

  @override
  String get createFileDialogTitle => 'Создать новый файл';

  @override
  String get createFileDefaultName => 'untitled.org';

  @override
  String get saveAsDialogTitle => 'Сохранить как';

  @override
  String get inputUrlDialogTitle => 'Введите URL-адрес';

  @override
  String get startTimePickerTitle => 'Выбрать время начала';

  @override
  String get endTimePickerTitle => 'Выбрать время конца';

  @override
  String get captureToDialogTitle => 'Capture to';

  @override
  String get snackbarMessageInvalidCaptureUri => 'Invalid capture URL';

  @override
  String get snackbarMessageBibliographiesNotFound => 'Не найдены библиографии';

  @override
  String get snackbarMessageCitationKeysNotFound => 'Слова цитат найдены';

  @override
  String get snackbarMessageCitationsNotFound => 'Цитаты не найдены';

  @override
  String snackbarMessageSomeCitationsNotFound(String citations) {
    return 'Цитаты не найдены: $citations';
  }

  @override
  String get errorCannotResolveRelativePath =>
      'Невозможно определить относительный путь к этому документу';

  @override
  String errorPathResolvedToNonFile(String path, String resolved) {
    return '$path определён как не файл: $resolved';
  }

  @override
  String errorUnknownType(Object type) {
    return 'Неизвестный тип: $type';
  }

  @override
  String errorUnexpectedHttpResponse(Object response) {
    return 'Неожиданный ответ HTTP: $response';
  }

  @override
  String errorOrgParser(Object result) {
    return 'Ошибка разбора ответа: $result';
  }

  @override
  String errorOrgExecution(Object message, String code) {
    return 'Ошибка при выполнении кода ниже: $message\n\n$code';
  }

  @override
  String errorOrgTimeout(num timeout, String code) {
    final intl.NumberFormat timeoutNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String timeoutString = timeoutNumberFormat.format(timeout);

    return 'Выполнение кода ниже заняло больше чем $timeoutStringмс.\n\n$code';
  }

  @override
  String errorOrgArgument(Object item) {
    return 'Неправильный аргумент: $item';
  }

  @override
  String get errorDecryptionFailed => 'Не удалось расшифровать';

  @override
  String errorLinkNotHandled(Object link) {
    return 'Не могу открыть ссылку “$link”';
  }

  @override
  String errorExternalIdNotFound(String id) {
    return 'Файл с ID “$id” не найден';
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
  String get editInsertedHeadline => '[Вставлено при изменении]';
}
