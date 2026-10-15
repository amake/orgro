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
  String get menuItemSettings => 'Налаштування';

  @override
  String get menuItemClearCache => 'Очистити кеш';

  @override
  String get menuItemOrgroManual => 'Посібник Orgro';

  @override
  String get menuItemOrgManual => 'Посібник Org';

  @override
  String get menuItemTestFile => 'Тестовий файл';

  @override
  String get menuItemAbout => 'Про застосунок';

  @override
  String get menuItemOpenUrl => 'Відкрити URL';

  @override
  String get quickActionNewDocument => 'Новий документ';

  @override
  String quickActionTopPin(String name) {
    return 'Відкрити $name';
  }

  @override
  String get appearanceModeAutomatic => 'Автоматичний';

  @override
  String get appearanceModeLight => 'Світлий';

  @override
  String get appearanceModeDark => 'Темний';

  @override
  String get settingsScreenTitle => 'Налаштування';

  @override
  String get settingsSectionAppearance => 'Вигляд';

  @override
  String get settingsSectionDefaultText => 'Текст за замовчуванням';

  @override
  String get settingsSectionAgenda => 'Розклад';

  @override
  String get settingsSectionDataManagement => 'Керування даними';

  @override
  String get settingsSectionDonate => 'Пожертви';

  @override
  String get settingsSectionPurchase => 'Придбання';

  @override
  String get agendaNotificationsChannelName => 'Сповіщення розкладу';

  @override
  String get agendaNotificationsChannelDescription =>
      'Сповіщення про пункти розкладу Org';

  @override
  String get agendaNotificationsActionView => 'Переглянути';

  @override
  String get settingsItemLoading => 'Завантаження...';

  @override
  String get settingsItemTheme => 'Тема';

  @override
  String get settingsItemTextScale => 'Масштаб';

  @override
  String get settingsItemFontFamily => 'Шрифт';

  @override
  String get settingsItemDefaultTextPreviewString =>
      'Так виглядатиме текст документа з вибраним шрифтом і масштабом.\n\nТоркніться, щоб редагувати.';

  @override
  String get settingsItemEnableAgendaPrompts =>
      'Пропонувати додавати документи до розкладу';

  @override
  String settingsItemInspectNotifications(num n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString запланованого сповіщення',
      many: '$nString запланованих сповіщень',
      few: '$nString заплановані сповіщення',
      one: '$nString заплановане сповіщення',
      zero: 'Немає сповіщень',
    );
    return '$_temp0';
  }

  @override
  String get settingsItemGrantNotificationPermissions => 'Увімкнути сповіщення';

  @override
  String get settingsItemEnableAgendaNotifications => 'Сповіщення розкладу';

  @override
  String get settingsDialogNotificationsTitle => 'Заплановані сповіщення';

  @override
  String get settingsItemClearNotifications => 'Очистити всі сповіщення';

  @override
  String get settingsItemClearAgenda => 'Очистити розклад';

  @override
  String get confirmClearAgendaDialogTitle => 'Очистити розклад?';

  @override
  String confirmClearAgendaDialogMessage(num n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Наведені нижче $n файлу розкладу більше не відстежуватимуться.',
      many: 'Наведені нижче $n файлів розкладу більше не відстежуватимуться.',
      few: 'Наведені нижче $n файли розкладу більше не відстежуватимуться.',
      one: 'Наведений нижче $n файл розкладу більше не відстежуватиметься.',
    );
    return '$_temp0 Цю дію не можна скасувати.';
  }

  @override
  String get confirmClearAgendaActionClear => 'Очистити';

  @override
  String get confirmClearAgendaActionCancel => 'Скасувати';

  @override
  String get settingsActionClearCache => 'Очистити кеш';

  @override
  String get settingsActionResetPreferences => 'Відновити типові налаштування';

  @override
  String get settingsActionResetPermissions => 'Скинути дозволи';

  @override
  String get snackbarMessageNotificationsCleared => 'Сповіщення очищено';

  @override
  String get snackbarMessageAgendaCleared => 'Розклад очищено';

  @override
  String get snackbarMessageCacheCleared => 'Кеш очищено';

  @override
  String get snackbarMessagePreferencesReset => 'Налаштування скинуто';

  @override
  String get snackbarMessagePermissionsReset => 'Дозволи скинуто';

  @override
  String get confirmResetPreferencesDialogTitle =>
      'Відновити типові налаштування?';

  @override
  String get confirmResetPreferencesDialogMessage =>
      'Усі налаштування буде скинуто до типових значень. Цю дію не можна скасувати.';

  @override
  String get confirmResetPreferencesActionReset => 'Відновити';

  @override
  String get confirmResetPreferencesActionCancel => 'Скасувати';

  @override
  String get aboutLinkSupport => 'Підтримка · Зворотний звʼязок';

  @override
  String get aboutLinkChangelog => 'Список змін';

  @override
  String get buttonOpenFile => 'Відкрити файл';

  @override
  String get buttonCreateFile => 'Створити файл';

  @override
  String get buttonOpenOrgroManual => 'Відкрити Посібник Orgro';

  @override
  String get buttonOpenOrgManual => 'Відкрити Посібник Org';

  @override
  String get buttonOpenUrl => 'Відкрити URL';

  @override
  String get tooltipCreateFile => 'Створити файл';

  @override
  String get tooltipOpenFile => 'Відкрити файл';

  @override
  String get buttonSupport => 'Підтримка · Зворотний звʼязок';

  @override
  String buttonVersion(String version) {
    return 'v$version';
  }

  @override
  String get sectionHeaderPinnedFiles => 'Закріплені файли';

  @override
  String get sectionHeaderRecentFiles => 'Останні файли';

  @override
  String get recentFilesSortDialogTitle => 'Сортувати за';

  @override
  String get sortKeyLastOpened => 'Останнім відкриттям';

  @override
  String get sortKeyName => 'Назвою';

  @override
  String get sortKeyLocation => 'Розташуванням';

  @override
  String get sortOrderAscending => 'За зростанням';

  @override
  String get sortOrderDescending => 'За спаданням';

  @override
  String get fileSourceDocuments => 'Документи';

  @override
  String get fileSourceDownloads => 'Завантаження';

  @override
  String get fileSourceGoogleDrive => 'Google Диск';

  @override
  String get filesTabTitle => 'Файли';

  @override
  String get agendaTabTitle => 'Розклад';

  @override
  String get unknownAgendaTitle => 'Невідомо';

  @override
  String get emptyAgendaMessage => 'Запланованих пунктів розкладу не знайдено';

  @override
  String get notFoundDialogTitle => 'Не знайдено';

  @override
  String get notFoundDialogBody =>
      'Не вдалося знайти файл, який ви намагаєтеся відкрити. Можливо, його переміщено або видалено. Ви можете надати доступ до батьківської теки (рекомендовано), спробувати знайти файл вручну або вилучити його зі списку останніх файлів.';

  @override
  String get notFoundDialogNoDirAccessBody =>
      'Не вдалося знайти файл, який ви намагаєтеся відкрити. Можливо, його переміщено або видалено. Ви можете спробувати знайти файл вручну або вилучити його зі списку останніх файлів.';

  @override
  String get notFoundDialogActionGrantAccess =>
      'Надати доступ до батьківської теки';

  @override
  String get notFoundDialogActionLocate => 'Знайти файл';

  @override
  String get notFoundDialogActionRemove => 'Вилучити з останніх файлів';

  @override
  String get menuItemReaderMode => 'Режим читання';

  @override
  String get menuItemWakelock => 'Не вимикати екран';

  @override
  String get menuItemFullWidth => 'На всю ширину';

  @override
  String get menuItemScrollTop => 'Прокрутити вгору';

  @override
  String get menuItemScrollBottom => 'Прокрутити вниз';

  @override
  String get menuItemUndo => 'Відмінити';

  @override
  String get menuItemRedo => 'Повторити';

  @override
  String get tooltipFullWidth => 'Перемкнути режим на всю ширину';

  @override
  String get tooltipReaderMode => 'Перемкнути режим читання';

  @override
  String get tooltipScrollTop => 'Прокрутити вгору';

  @override
  String get tooltipScrollBottom => 'Прокрутити вниз';

  @override
  String get tooltipTextStyle => 'Стиль тексту';

  @override
  String get tooltipDecreaseTextScale => 'Зменшити масштаб тексту';

  @override
  String get tooltipIncreaseTextScale => 'Збільшити масштаб тексту';

  @override
  String get tooltipCycleVisibility => 'Перемкнути видимість';

  @override
  String get tooltipEditDocument => 'Редагувати документ';

  @override
  String get tooltipSearchDocument => 'Шукати в документі';

  @override
  String get tooltipPreviousSearchHit => 'Попередній результат пошуку';

  @override
  String get tooltipNextSearchHit => 'Наступний результат пошуку';

  @override
  String get hintTextSearch => 'Шукати...';

  @override
  String get tooltipClearSearch => 'Очистити пошук';

  @override
  String searchHits(num n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString збігу',
      many: '$nString збігів',
      few: '$nString збіги',
      one: '$nString збіг',
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
  String get customFilterChipName => 'Власний';

  @override
  String get snackbarMessageNeedsDirectoryPermissions =>
      'Orgro не має дозволу на обробку відносних посилань';

  @override
  String get snackbarActionGrantAccess => 'Надати дозвіл';

  @override
  String get snackbarMessageNeedsEncryptionKey =>
      'Не вдалося зберегти. Немає пароля шифрування.';

  @override
  String get snackbarActionEnterEncryptionKey => 'Ввести пароль';

  @override
  String get snackbarMessageNeedsNotificationsPermissions =>
      'Orgro не має дозволу надсилати сповіщення';

  @override
  String get snackbarActionGrantNotificationsPermissions => 'Дозволити';

  @override
  String get dialogTitleError => 'Помилка';

  @override
  String get dialogActionConfirm => 'OK';

  @override
  String get dialogActionCancel => 'Скасувати';

  @override
  String get dialogActionHelp => 'Довідка';

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
    return '$name › редагування';
  }

  @override
  String get sectionActionNarrow => 'Гілка';

  @override
  String get sectionActionCycleTodo => 'Змінити стан TODO';

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
  String get bannerBodySaveDocument =>
      'Бажаєте зберігати зміни одразу під час редагування?';

  @override
  String get bannerBodyActionSaveAlways => 'Завжди';

  @override
  String get bannerBodyActionSaveNever => 'Ніколи';

  @override
  String get bannerBodyActionSaveOnce => 'Лише цього разу';

  @override
  String get bannerBodyDecryptContent =>
      'Цей документ містить зашифрований вміст. Розшифрувати його зараз?';

  @override
  String get bannerBodyActionDecryptNow => 'Розшифрувати';

  @override
  String get bannerBodyActionDecryptNotNow => 'Не зараз';

  @override
  String get bannerBodyActionDecryptNever => 'Ніколи';

  @override
  String get bannerBodyAddToAgenda => 'Додати цей файл до розкладу?';

  @override
  String get bannerBodyActionAgendaAdd => 'Додати';

  @override
  String get bannerBodyActionAgendaNotNow => 'Не зараз';

  @override
  String get bannerBodyActionAgendaNever => 'Ніколи';

  @override
  String get transclusionPermissionsMessage =>
      'Для трансклюзії потрібен дозвіл на доступ до теки.';

  @override
  String get saveChangesDialogTitle => 'Зберегти зміни?';

  @override
  String get saveChangesDialogMessage =>
      'Orgro не може записати зміни в початковий файл.';

  @override
  String get saveChangesDialogForbiddenMessage =>
      'Ви заборонили Orgro зберігати зміни в початковий файл.';

  @override
  String get saveActionShare => 'Поділитися';

  @override
  String get saveActionDiscard => 'Відкинути';

  @override
  String get saveActionSaveAs => 'Зберегти як';

  @override
  String get discardChangesDialogTitle => 'Відкинути зміни?';

  @override
  String get discardActionDiscard => 'Відкинути';

  @override
  String get discardActionCancel => 'Скасувати';

  @override
  String get savedMessage => 'Збережено';

  @override
  String get inputDecryptionPasswordDialogTitle =>
      'Введіть пароль для розшифрування';

  @override
  String get inputEncryptionPasswordDialogTitle =>
      'Введіть пароль для шифрування';

  @override
  String get inputEncryptionPasswordDialogBody =>
      'Цей пароль буде використано для шифрування розділів Org Crypt, для яких пароль не вказано.';

  @override
  String get inputCustomFilterDialogTitle => 'Власний запит фільтра';

  @override
  String get inputCustomFilterDialogHistoryButton => 'Історія';

  @override
  String get loadingProgressDialogTitle => 'Завантаження…';

  @override
  String get preparingProgressDialogTitle => 'Підготовка…';

  @override
  String get decryptingProgressDialogTitle => 'Розшифрування…';

  @override
  String get encryptingProgressDialogTitle => 'Шифрування…';

  @override
  String get serializingProgressDialogTitle => 'Серіалізація…';

  @override
  String get savingProgressDialogTitle => 'Збереження…';

  @override
  String get searchingProgressDialogTitle => 'Пошук…';

  @override
  String get citationsDialogTitle => 'Цитування';

  @override
  String get citationsDialogOpenLink => 'Відкрити посилання';

  @override
  String get createFileDialogTitle => 'Створити новий файл';

  @override
  String get createFileDefaultName => 'untitled.org';

  @override
  String get saveAsDialogTitle => 'Зберегти як';

  @override
  String get inputUrlDialogTitle => 'Введіть URL';

  @override
  String get startTimePickerTitle => 'Виберіть час початку';

  @override
  String get endTimePickerTitle => 'Виберіть час завершення';

  @override
  String get captureToDialogTitle => 'Зберегти до';

  @override
  String get captureToClipboardItem => 'Буфер обміну';

  @override
  String get captureToNewDocumentItem => 'Новий файл';

  @override
  String get snackbarMessageInvalidCaptureUri => 'Недійсний URL для збереження';

  @override
  String get snackbarMessageBibliographiesNotFound =>
      'Бібліографій не знайдено';

  @override
  String get snackbarMessageCitationKeysNotFound =>
      'Ключі цитувань не знайдено';

  @override
  String get snackbarMessageCitationsNotFound => 'Цитування не знайдено';

  @override
  String snackbarMessageSomeCitationsNotFound(String citations) {
    return 'Цитування не знайдено: $citations';
  }

  @override
  String get errorCannotResolveRelativePath =>
      'Неможливо визначити шлях відносно цього документа';

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
    return 'Помилка синтаксичного аналізу: $result';
  }

  @override
  String errorOrgExecution(Object message, String code) {
    return 'Помилка виконання коду нижче: $message\n\n$code';
  }

  @override
  String errorOrgTimeout(num timeout, String code) {
    final intl.NumberFormat timeoutNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String timeoutString = timeoutNumberFormat.format(timeout);

    return 'Час виконання коду нижче вичерпано через $timeoutString мс.\n\n$code';
  }

  @override
  String errorOrgArgument(Object item) {
    return 'Недійсний аргумент: $item';
  }

  @override
  String get errorDecryptionFailed => 'Не вдалося розшифрувати';

  @override
  String errorLinkNotHandled(Object link) {
    return 'Не вдалося відкрити посилання «$link»';
  }

  @override
  String errorExternalIdNotFound(String id) {
    return 'Файл з ID «$id» не знайдено';
  }

  @override
  String errorFileNamePrefixNotFound(String prefix) {
    return 'Файл із префіксом назви «$prefix» не знайдено';
  }

  @override
  String errorSectionNotFound(String section) {
    return 'Розділ не знайдено: $section';
  }

  @override
  String errorUnsupportedSearchOption(String option) {
    return 'Непідтримуваний параметр пошуку: $option';
  }

  @override
  String errorSchedulingNotifications(Object message) {
    return 'Не вдалося запланувати сповіщення: $message';
  }

  @override
  String errorUnsupportedLinkType(Object link) {
    return 'Непідтримуваний тип посилання: $link';
  }

  @override
  String errorUnsupportedDataSource(Object source) {
    return 'Непідтримуване джерело даних: $source';
  }

  @override
  String get errorInvalidUrl => 'Недійсний URL';

  @override
  String get errorUnknown => 'Невідома помилка';

  @override
  String get tooltipErrorDetails => 'Переглянути подробиці помилки';

  @override
  String get editInsertedHeadline => '[Вставлено під час редагування]';

  @override
  String get pasteImageContextMenuTitle => 'Вставити зображення';

  @override
  String get pasteImageErrorNoFiles => 'Не вдалося вставити жодного зображення';

  @override
  String get tooltipApplyChanges => 'Застосувати зміни';

  @override
  String get tooltipUndo => 'Відмінити';

  @override
  String get tooltipRedo => 'Повторити';

  @override
  String get tooltipInsertHeadline => 'Вставити заголовок';

  @override
  String get tooltipToggleUnorderedList => 'Перемкнути маркований список';

  @override
  String get tooltipToggleOrderedList => 'Перемкнути нумерований список';

  @override
  String get tooltipDecreaseIndent => 'Зменшити відступ';

  @override
  String get tooltipIncreaseIndent => 'Збільшити відступ';

  @override
  String get tooltipBold => 'Жирний';

  @override
  String get tooltipItalic => 'Курсив';

  @override
  String get tooltipUnderline => 'Підкреслений';

  @override
  String get tooltipStrikethrough => 'Закреслений';

  @override
  String get tooltipCode => 'Стиль коду';

  @override
  String get tooltipInsertLink => 'Вставити посилання';

  @override
  String get tooltipInsertDate => 'Вставити дату';

  @override
  String get tooltipSubscript => 'Нижній індекс';

  @override
  String get tooltipSuperscript => 'Верхній індекс';

  @override
  String get tooltipEncryptSection => 'Зашифрувати розділ';

  @override
  String tooltipKeywordChip(String keyword) {
    return 'Ключове слово «$keyword»';
  }

  @override
  String tooltipTagChip(String tag) {
    return 'Тег «$tag»';
  }

  @override
  String tooltipPriorityChip(String priority) {
    return 'Пріоритет «$priority»';
  }

  @override
  String tooltipCustomFilterQueryChip(String query) {
    return 'Власний фільтр: $query';
  }

  @override
  String get donateItemTitle => 'Підтримати Orgro пожертвою';

  @override
  String get donateItemSubtitle => 'Ваша підтримка дуже цінна!';

  @override
  String get entitlementsLoadingItem => 'Завантаження інформації...';

  @override
  String entitlementsFreeTrialItem(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName)
        .add_jm();
    final String dateString = dateDateFormat.format(date);

    return 'Безкоштовний пробний період закінчується $dateString';
  }

  @override
  String get entitlementsTrialExpiredItem =>
      'Безкоштовний пробний період закінчився';

  @override
  String entitlementsPurchaseItemTitle(String price) {
    return 'Придбати Orgro за $price (одноразовий платіж)';
  }

  @override
  String get entitlementsPurchaseItemSubtitle =>
      'Відкрийте доступ до всіх функцій і підтримайте розробку';

  @override
  String get entitlementsRestorePurchasesItem => 'Відновити покупки';

  @override
  String get entitlementsPurchasedItem => 'Придбано';

  @override
  String get entitlementsPurchasedItemSubtitle => 'Дякуємо за вашу підтримку';

  @override
  String get entitlementsLegacyPurchaseItemSubtitle =>
      'Дякуємо, що давно підтримуєте Orgro!';

  @override
  String get entitlementsLockedDialogTitle =>
      'Безкоштовний пробний період закінчився';

  @override
  String get entitlementsLockedDialogMessage =>
      'Щоб і далі користуватися Orgro, придбайте ліцензію або відновіть попередні покупки.\n\nЛіцензія купується одноразовим платежем і відкриває доступ до всіх функцій.';

  @override
  String entitlementsLockedDialogActionPurchase(String price) {
    return 'Придбати ($price)';
  }

  @override
  String get entitlementsLockedDialogActionRestore => 'Відновити';

  @override
  String get entitlementsLockedDialogActionMoreInfo => 'Докладніше';
}
