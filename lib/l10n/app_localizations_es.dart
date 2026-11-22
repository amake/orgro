// ignore_for_file: deprecated_member_use

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Orgro';

  @override
  String get menuItemAppearance => 'Apariencia';

  @override
  String get menuItemSettings => 'Ajustes';

  @override
  String get menuItemClearCache => 'Borrar caché';

  @override
  String get menuItemOrgroManual => 'Manual de Orgro';

  @override
  String get menuItemOrgManual => 'Manual de Org';

  @override
  String get menuItemTestFile => 'Archivo de prueba';

  @override
  String get menuItemAbout => 'Acerca de';

  @override
  String get menuItemOpenUrl => 'Abrir URL';

  @override
  String get quickActionNewDocument => 'Nuevo documento';

  @override
  String quickActionTopPin(String name) {
    return 'Abrir $name';
  }

  @override
  String get appearanceModeAutomatic => 'Automático';

  @override
  String get appearanceModeLight => 'Claro';

  @override
  String get appearanceModeDark => 'Oscuro';

  @override
  String get settingsScreenTitle => 'Ajustes';

  @override
  String get settingsSectionAppearance => 'Apariencia';

  @override
  String get settingsSectionDefaultText => 'Texto predeterminado';

  @override
  String get settingsSectionAgenda => 'Agenda';

  @override
  String get settingsSectionDataManagement => 'Gestión de datos';

  @override
  String get settingsSectionDonate => 'Donaciones';

  @override
  String get settingsSectionPurchase => 'Compra';

  @override
  String get agendaNotificationsChannelName => 'Notificaciones de la agenda';

  @override
  String get agendaNotificationsChannelDescription =>
      'Notificaciones de elementos de Org Agenda';

  @override
  String get agendaNotificationsActionView => 'Ver';

  @override
  String get settingsItemLoading => 'Cargando...';

  @override
  String get settingsItemTheme => 'Tema';

  @override
  String get settingsItemTextScale => 'Tamaño';

  @override
  String get settingsItemFontFamily => 'Fuente';

  @override
  String get settingsItemDefaultTextPreviewString =>
      'Así se verá el texto de los documentos con la fuente y el tamaño seleccionados.\n\nToca para editar.';

  @override
  String get settingsItemEnableAgendaPrompts =>
      'Ofrecer añadir documentos a la agenda';

  @override
  String settingsItemInspectNotifications(num n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString notificaciones pendientes',
      one: '1 notificación pendiente',
      zero: 'Sin notificaciones',
    );
    return '$_temp0';
  }

  @override
  String get settingsItemGrantNotificationPermissions =>
      'Activar notificaciones';

  @override
  String get settingsItemEnableAgendaNotifications =>
      'Notificaciones de la agenda';

  @override
  String get settingsItemEventNotificationTime =>
      'Cuándo notificar los eventos';

  @override
  String get eventNotificationTimeAtEventTime => 'A la hora del evento';

  @override
  String get eventNotificationTimeFiveMinutesBefore => '5 minutos antes';

  @override
  String get eventNotificationTimeTenMinutesBefore => '10 minutos antes';

  @override
  String get eventNotificationTimeFifteenMinutesBefore => '15 minutos antes';

  @override
  String get eventNotificationTimeThirtyMinutesBefore => '30 minutos antes';

  @override
  String get eventNotificationTimeOneHourBefore => '1 hora antes';

  @override
  String get eventNotificationTimeTwoHoursBefore => '2 horas antes';

  @override
  String get eventNotificationTimeOneDayBefore => '1 día antes';

  @override
  String get eventNotificationTimeTwoDaysBefore => '2 días antes';

  @override
  String get eventNotificationTimeOneWeekBefore => '1 semana antes';

  @override
  String get settingsItemAllDayEventNotificationTime =>
      'Cuándo notificar los eventos de todo el día';

  @override
  String allDayEventNotificationTimeAtEventTime(DateTime time) {
    final intl.DateFormat timeDateFormat = intl.DateFormat.jm(localeName);
    final String timeString = timeDateFormat.format(time);

    return 'El día del evento ($timeString)';
  }

  @override
  String allDayEventNotificationTimeOneDayBefore(DateTime time) {
    final intl.DateFormat timeDateFormat = intl.DateFormat.jm(localeName);
    final String timeString = timeDateFormat.format(time);

    return '1 día antes ($timeString)';
  }

  @override
  String allDayEventNotificationTimeTwoDaysBefore(DateTime time) {
    final intl.DateFormat timeDateFormat = intl.DateFormat.jm(localeName);
    final String timeString = timeDateFormat.format(time);

    return '2 días antes ($timeString)';
  }

  @override
  String allDayEventNotificationTimeOneWeekBefore(DateTime time) {
    final intl.DateFormat timeDateFormat = intl.DateFormat.jm(localeName);
    final String timeString = timeDateFormat.format(time);

    return '1 semana antes ($timeString)';
  }

  @override
  String get settingsDialogNotificationsTitle => 'Notificaciones pendientes';

  @override
  String get settingsItemClearNotifications =>
      'Borrar todas las notificaciones';

  @override
  String get settingsItemClearAgenda => 'Vaciar la agenda';

  @override
  String get confirmClearAgendaDialogTitle => '¿Vaciar la agenda?';

  @override
  String confirmClearAgendaDialogMessage(num n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'los siguientes $n archivos',
      one: 'el siguiente archivo',
    );
    return 'La agenda dejará de incluir $_temp0. Esta acción no se puede deshacer.';
  }

  @override
  String get confirmClearAgendaActionClear => 'Vaciar';

  @override
  String get confirmClearAgendaActionCancel => 'Cancelar';

  @override
  String get settingsActionClearCache => 'Borrar caché';

  @override
  String get settingsActionResetPreferences =>
      'Restablecer valores predeterminados';

  @override
  String get settingsActionResetPermissions => 'Restablecer permisos';

  @override
  String get snackbarMessageNotificationsCleared => 'Notificaciones borradas';

  @override
  String get snackbarMessageAgendaCleared => 'Agenda vaciada';

  @override
  String get snackbarMessageCacheCleared => 'Caché borrada';

  @override
  String get snackbarMessagePreferencesReset => 'Preferencias restablecidas';

  @override
  String get snackbarMessagePermissionsReset => 'Permisos restablecidos';

  @override
  String get confirmResetPreferencesDialogTitle =>
      '¿Restablecer valores predeterminados?';

  @override
  String get confirmResetPreferencesDialogMessage =>
      'Todas las preferencias volverán a sus valores predeterminados. Esta acción no se puede deshacer.';

  @override
  String get confirmResetPreferencesActionReset => 'Restablecer';

  @override
  String get confirmResetPreferencesActionCancel => 'Cancelar';

  @override
  String get aboutLinkSupport => 'Soporte · Comentarios';

  @override
  String get aboutLinkChangelog => 'Registro de cambios';

  @override
  String get buttonOpenFile => 'Abrir archivo';

  @override
  String get buttonCreateFile => 'Crear archivo';

  @override
  String get buttonOpenOrgroManual => 'Abrir el manual de Orgro';

  @override
  String get buttonOpenOrgManual => 'Abrir el manual de Org';

  @override
  String get buttonOpenUrl => 'Abrir URL';

  @override
  String get tooltipCreateFile => 'Crear archivo';

  @override
  String get tooltipOpenFile => 'Abrir archivo';

  @override
  String get buttonSupport => 'Soporte · Comentarios';

  @override
  String buttonVersion(String version) {
    return 'v$version';
  }

  @override
  String get sectionHeaderPinnedFiles => 'Archivos fijados';

  @override
  String get sectionHeaderRecentFiles => 'Archivos recientes';

  @override
  String get recentFilesSortDialogTitle => 'Ordenar por';

  @override
  String get sortKeyLastOpened => 'Última apertura';

  @override
  String get sortKeyName => 'Nombre';

  @override
  String get sortKeyLocation => 'Ubicación';

  @override
  String get sortOrderAscending => 'Ascendente';

  @override
  String get sortOrderDescending => 'Descendente';

  @override
  String get fileSourceDocuments => 'Documentos';

  @override
  String get fileSourceDownloads => 'Descargas';

  @override
  String get fileSourceGoogleDrive => 'Google Drive';

  @override
  String get filesTabTitle => 'Archivos';

  @override
  String get agendaTabTitle => 'Agenda';

  @override
  String get unknownAgendaTitle => 'Sin título';

  @override
  String get emptyAgendaMessage => 'No hay elementos pendientes en la agenda';

  @override
  String get notFoundDialogTitle => 'Archivo no encontrado';

  @override
  String get notFoundDialogBody =>
      'No se ha encontrado el archivo que intentas abrir. Puede que se haya movido o eliminado. Puedes conceder acceso a un directorio superior (recomendado), intentar localizar el archivo manualmente o quitarlo de la lista de archivos recientes.';

  @override
  String get notFoundDialogNoDirAccessBody =>
      'No se ha encontrado el archivo que intentas abrir. Puede que se haya movido o eliminado. Puedes intentar localizar el archivo manualmente o quitarlo de la lista de archivos recientes.';

  @override
  String get notFoundDialogActionGrantAccess =>
      'Conceder acceso al directorio superior';

  @override
  String get notFoundDialogActionLocate => 'Localizar archivo';

  @override
  String get notFoundDialogActionRemove => 'Quitar de archivos recientes';

  @override
  String get menuItemReaderMode => 'Modo lectura';

  @override
  String get menuItemWakelock => 'Mantener la pantalla encendida';

  @override
  String get menuItemFullWidth => 'Ancho completo';

  @override
  String get menuItemScrollTop => 'Desplazarse al principio';

  @override
  String get menuItemScrollBottom => 'Desplazarse al final';

  @override
  String get menuItemUndo => 'Deshacer';

  @override
  String get menuItemRedo => 'Rehacer';

  @override
  String get tooltipFullWidth => 'Alternar ancho completo';

  @override
  String get tooltipReaderMode => 'Alternar modo lectura';

  @override
  String get tooltipScrollTop => 'Desplazarse al principio';

  @override
  String get tooltipScrollBottom => 'Desplazarse al final';

  @override
  String get tooltipTextStyle => 'Estilo de texto';

  @override
  String get tooltipDecreaseTextScale => 'Reducir el tamaño del texto';

  @override
  String get tooltipIncreaseTextScale => 'Aumentar el tamaño del texto';

  @override
  String get tooltipCycleVisibility => 'Cambiar visibilidad';

  @override
  String get tooltipEditDocument => 'Editar documento';

  @override
  String get tooltipSearchDocument => 'Buscar en el documento';

  @override
  String get tooltipPreviousSearchHit => 'Resultado de búsqueda anterior';

  @override
  String get tooltipNextSearchHit => 'Siguiente resultado de búsqueda';

  @override
  String get hintTextSearch => 'Buscar...';

  @override
  String get tooltipClearSearch => 'Borrar búsqueda';

  @override
  String searchHits(num n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString coincidencias',
      one: '1 coincidencia',
      zero: '0 coincidencias',
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
  String get customFilterChipName => 'Personalizado';

  @override
  String get snackbarMessageNeedsDirectoryPermissions =>
      'Orgro no tiene permiso para resolver enlaces relativos';

  @override
  String get snackbarActionGrantAccess => 'Conceder acceso';

  @override
  String get snackbarMessageNeedsEncryptionKey =>
      'No se ha podido guardar. Falta la contraseña de cifrado.';

  @override
  String get snackbarActionEnterEncryptionKey => 'Introducir contraseña';

  @override
  String get snackbarMessageNeedsNotificationsPermissions =>
      'Orgro no tiene permiso para enviar notificaciones';

  @override
  String get snackbarActionGrantNotificationsPermissions => 'Permitir';

  @override
  String get dialogTitleError => 'Error';

  @override
  String get dialogActionConfirm => 'Aceptar';

  @override
  String get dialogActionCancel => 'Cancelar';

  @override
  String get dialogActionHelp => 'Ayuda';

  @override
  String get pageTitleError => 'Error';

  @override
  String get pageTitleLoading => 'Cargando...';

  @override
  String pageTitleNarrow(String name) {
    return '$name › acotado';
  }

  @override
  String pageTitleEditing(String name) {
    return '$name › edición';
  }

  @override
  String get sectionActionNarrow => 'Acotar';

  @override
  String get sectionActionCycleTodo => 'Cambiar estado TODO';

  @override
  String get bannerBodyRemoteImages =>
      'Este documento contiene imágenes remotas. ¿Quieres cargarlas?';

  @override
  String get bannerBodyActionShowAlways => 'Siempre';

  @override
  String get bannerBodyActionShowNever => 'Nunca';

  @override
  String get bannerBodyActionShowOnce => 'Solo una vez';

  @override
  String get bannerBodyRelativeLinks =>
      'Este documento contiene enlaces relativos. ¿Quieres conceder acceso?';

  @override
  String get bannerBodyActionGrantNotNow => 'Ahora no';

  @override
  String get bannerBodyActionGrantNever => 'Nunca';

  @override
  String get bannerBodyActionGrantNow => 'Conceder acceso';

  @override
  String get bannerBodySaveDocument =>
      '¿Quieres guardar los cambios a medida que los hagas?';

  @override
  String get bannerBodyActionSaveAlways => 'Siempre';

  @override
  String get bannerBodyActionSaveNever => 'Nunca';

  @override
  String get bannerBodyActionSaveOnce => 'Solo esta vez';

  @override
  String get bannerBodyDecryptContent =>
      'Este documento tiene contenido cifrado. ¿Quieres descifrarlo ahora?';

  @override
  String get bannerBodyActionDecryptNow => 'Descifrar';

  @override
  String get bannerBodyActionDecryptNotNow => 'Ahora no';

  @override
  String get bannerBodyActionDecryptNever => 'Nunca';

  @override
  String get bannerBodyAddToAgenda =>
      '¿Quieres añadir este archivo a tu agenda?';

  @override
  String get bannerBodyActionAgendaAdd => 'Añadir';

  @override
  String get bannerBodyActionAgendaNotNow => 'Ahora no';

  @override
  String get bannerBodyActionAgendaNever => 'Nunca';

  @override
  String get transclusionPermissionsMessage =>
      'La transclusión requiere permisos de acceso a directorios.';

  @override
  String get saveChangesDialogTitle => '¿Guardar los cambios?';

  @override
  String get saveChangesDialogMessage =>
      'Orgro no puede guardar los cambios en el archivo original.';

  @override
  String get saveChangesDialogForbiddenMessage =>
      'Has decidido no permitir que Orgro guarde los cambios en el archivo original.';

  @override
  String get saveActionShare => 'Compartir';

  @override
  String get saveActionDiscard => 'Descartar';

  @override
  String get saveActionSaveAs => 'Guardar como';

  @override
  String get discardChangesDialogTitle => '¿Descartar los cambios?';

  @override
  String get discardActionDiscard => 'Descartar';

  @override
  String get discardActionCancel => 'Cancelar';

  @override
  String get savedMessage => 'Guardado';

  @override
  String get inputDecryptionPasswordDialogTitle =>
      'Introduce la contraseña para descifrar';

  @override
  String get inputEncryptionPasswordDialogTitle =>
      'Introduce la contraseña para cifrar';

  @override
  String get inputEncryptionPasswordDialogBody =>
      'Esta contraseña se usará para cifrar las secciones de Org Crypt que no tengan una contraseña propia.';

  @override
  String get inputCustomFilterDialogTitle => 'Consulta de filtro personalizado';

  @override
  String get inputCustomFilterDialogHistoryButton => 'Historial';

  @override
  String get loadingProgressDialogTitle => 'Cargando…';

  @override
  String get preparingProgressDialogTitle => 'Preparando…';

  @override
  String get decryptingProgressDialogTitle => 'Descifrando…';

  @override
  String get encryptingProgressDialogTitle => 'Cifrando…';

  @override
  String get serializingProgressDialogTitle => 'Serializando…';

  @override
  String get savingProgressDialogTitle => 'Guardando…';

  @override
  String get searchingProgressDialogTitle => 'Buscando…';

  @override
  String get citationsDialogTitle => 'Citas';

  @override
  String get citationsDialogOpenLink => 'Abrir enlace';

  @override
  String get createFileDialogTitle => 'Crear archivo nuevo';

  @override
  String get createFileDefaultName => 'sin_titulo.org';

  @override
  String get saveAsDialogTitle => 'Guardar como';

  @override
  String get inputUrlDialogTitle => 'Introduce una URL';

  @override
  String get startTimePickerTitle => 'Selecciona la hora de inicio';

  @override
  String get endTimePickerTitle => 'Selecciona la hora de fin';

  @override
  String get captureToDialogTitle => 'Capturar en';

  @override
  String get captureToClipboardItem => 'Portapapeles';

  @override
  String get captureToNewDocumentItem => 'Archivo nuevo';

  @override
  String get captureToExistingFileToBeChosen => 'Elegir archivo…';

  @override
  String get snackbarMessageInvalidCaptureUri => 'URL de captura no válida';

  @override
  String get snackbarMessageBibliographiesNotFound =>
      'No se ha encontrado ninguna bibliografía';

  @override
  String get snackbarMessageCitationKeysNotFound =>
      'No se han encontrado las claves de cita';

  @override
  String get snackbarMessageCitationsNotFound =>
      'No se han encontrado las citas';

  @override
  String snackbarMessageSomeCitationsNotFound(String citations) {
    return 'Citas no encontradas: $citations';
  }

  @override
  String get errorCannotResolveRelativePath =>
      'No se puede resolver la ruta relativa a este documento';

  @override
  String errorPathResolvedToNonFile(String path, String resolved) {
    return '$path no apunta a un archivo: $resolved';
  }

  @override
  String errorUnknownType(Object type) {
    return 'Tipo desconocido: $type';
  }

  @override
  String errorUnexpectedHttpResponse(Object response) {
    return 'Respuesta HTTP inesperada: $response';
  }

  @override
  String errorOrgParser(Object result) {
    return 'Error del analizador: $result';
  }

  @override
  String errorOrgExecution(Object message, String code) {
    return 'Error de ejecución en el siguiente código: $message\n\n$code';
  }

  @override
  String errorOrgTimeout(num timeout, String code) {
    final intl.NumberFormat timeoutNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String timeoutString = timeoutNumberFormat.format(timeout);

    return 'La evaluación del siguiente código ha superado el tiempo límite de $timeoutString ms.\n\n$code';
  }

  @override
  String errorOrgArgument(Object item) {
    return 'Argumento no válido: $item';
  }

  @override
  String get errorDecryptionFailed => 'Error al descifrar';

  @override
  String errorLinkNotHandled(Object link) {
    return 'No se ha podido abrir el enlace «$link»';
  }

  @override
  String errorExternalIdNotFound(String id) {
    return 'No se ha encontrado el archivo con ID «$id»';
  }

  @override
  String errorFileNamePrefixNotFound(String prefix) {
    return 'No se ha encontrado ningún archivo cuyo nombre empiece por «$prefix»';
  }

  @override
  String errorSectionNotFound(String section) {
    return 'Sección no encontrada: $section';
  }

  @override
  String errorUnsupportedSearchOption(String option) {
    return 'Opción de búsqueda no admitida: $option';
  }

  @override
  String errorSchedulingNotifications(Object message) {
    return 'No se han podido programar las notificaciones: $message';
  }

  @override
  String errorUnsupportedLinkType(Object link) {
    return 'Tipo de enlace no admitido: $link';
  }

  @override
  String errorUnsupportedDataSource(Object source) {
    return 'Origen de datos no admitido: $source';
  }

  @override
  String get errorInvalidUrl => 'URL no válida';

  @override
  String get errorUnknown => 'Error desconocido';

  @override
  String get tooltipErrorDetails => 'Ver detalles del error';

  @override
  String get editInsertedHeadline => '[Insertado al editar]';

  @override
  String get pasteImageContextMenuTitle => 'Pegar imagen';

  @override
  String get pasteImageErrorNoFiles => 'No se ha podido pegar ninguna imagen';

  @override
  String get tooltipApplyChanges => 'Aplicar cambios';

  @override
  String get tooltipUndo => 'Deshacer';

  @override
  String get tooltipRedo => 'Rehacer';

  @override
  String get tooltipInsertHeadline => 'Insertar encabezado';

  @override
  String get tooltipToggleUnorderedList => 'Alternar lista con viñetas';

  @override
  String get tooltipToggleOrderedList => 'Alternar lista numerada';

  @override
  String get tooltipDecreaseIndent => 'Reducir sangría';

  @override
  String get tooltipIncreaseIndent => 'Aumentar sangría';

  @override
  String get tooltipBold => 'Negrita';

  @override
  String get tooltipItalic => 'Cursiva';

  @override
  String get tooltipUnderline => 'Subrayado';

  @override
  String get tooltipStrikethrough => 'Tachado';

  @override
  String get tooltipCode => 'Estilo de código';

  @override
  String get tooltipInsertLink => 'Insertar enlace';

  @override
  String get tooltipInsertDate => 'Insertar fecha';

  @override
  String get tooltipSubscript => 'Subíndice';

  @override
  String get tooltipSuperscript => 'Superíndice';

  @override
  String get tooltipEncryptSection => 'Cifrar sección';

  @override
  String tooltipKeywordChip(String keyword) {
    return 'Palabra clave «$keyword»';
  }

  @override
  String tooltipTagChip(String tag) {
    return 'Etiqueta «$tag»';
  }

  @override
  String tooltipPriorityChip(String priority) {
    return 'Prioridad «$priority»';
  }

  @override
  String tooltipCustomFilterQueryChip(String query) {
    return 'Filtro personalizado: $query';
  }

  @override
  String get donateItemTitle => 'Haz una donación para apoyar Orgro';

  @override
  String get donateItemSubtitle => '¡Se agradece tu apoyo!';

  @override
  String get entitlementsLoadingItem => 'Cargando información...';

  @override
  String entitlementsFreeTrialItem(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(localeName)
        .add_jm();
    final String dateString = dateDateFormat.format(date);

    return 'Tu prueba gratuita termina el $dateString';
  }

  @override
  String get entitlementsTrialExpiredItem => 'Tu prueba gratuita ha terminado';

  @override
  String entitlementsPurchaseItemTitle(String price) {
    return 'Compra Orgro por $price (pago único)';
  }

  @override
  String get entitlementsPurchaseItemSubtitle =>
      'Desbloquea todas las funciones y apoya el desarrollo';

  @override
  String get entitlementsRestorePurchasesItem => 'Restaurar compras';

  @override
  String get entitlementsPurchasedItem => 'Comprado';

  @override
  String get entitlementsPurchasedItemSubtitle => 'Gracias por tu apoyo';

  @override
  String get entitlementsLegacyPurchaseItemSubtitle =>
      '¡Gracias por tu apoyo durante tanto tiempo!';

  @override
  String get entitlementsLockedDialogTitle => 'Tu prueba gratuita ha terminado';

  @override
  String get entitlementsLockedDialogMessage =>
      'Para seguir usando Orgro, compra una licencia o restaura tus compras anteriores.\n\nLa licencia se paga una sola vez y desbloquea todas las funciones.';

  @override
  String entitlementsLockedDialogActionPurchase(String price) {
    return 'Comprar ($price)';
  }

  @override
  String get entitlementsLockedDialogActionRestore => 'Restaurar';

  @override
  String get entitlementsLockedDialogActionMoreInfo => 'Más información';
}
