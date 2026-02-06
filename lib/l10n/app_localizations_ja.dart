// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Orgro';

  @override
  String get menuItemAppearance => '外観';

  @override
  String get menuItemSettings => '設定';

  @override
  String get menuItemClearCache => 'キャッシュを削除';

  @override
  String get menuItemOrgroManual => 'Orgroマニュアル';

  @override
  String get menuItemOrgManual => 'Orgマニュアル';

  @override
  String get menuItemTestFile => 'テストファイル';

  @override
  String get menuItemAbout => 'アプリについて';

  @override
  String get menuItemOpenUrl => 'URLを開く';

  @override
  String get quickActionNewDocument => '新規ドキュメント';

  @override
  String quickActionTopPin(String name) {
    return '$nameを開く';
  }

  @override
  String get appearanceModeAutomatic => '自動';

  @override
  String get appearanceModeLight => 'ライト';

  @override
  String get appearanceModeDark => 'ダーク';

  @override
  String get settingsScreenTitle => '設定';

  @override
  String get settingsSectionAppearance => '外観';

  @override
  String get settingsSectionDefaultText => 'デフォルトの書式';

  @override
  String get settingsSectionNotifications => '通知';

  @override
  String get settingsSectionDataManagement => 'データ管理';

  @override
  String get settingsSectionDonate => '支援';

  @override
  String get settingsSectionPurchase => '購入';

  @override
  String get agendaNotificationsChannelName => 'アジェンダ通知';

  @override
  String get agendaNotificationsChannelDescription => 'Org Agenda項目の通知';

  @override
  String get agendaNotificationsActionView => '表示';

  @override
  String get settingsItemLoading => 'ロード中...';

  @override
  String get settingsItemTheme => 'モード';

  @override
  String get settingsItemTextScale => '文字サイズ';

  @override
  String get settingsItemFontFamily => '書体';

  @override
  String get settingsItemDefaultTextPreviewString =>
      '【プレビュー】This is what document text will look like in the selected font and scale.\n\nタップして編集できます。';

  @override
  String get settingsItemGrantNotificationPermissions => '通知を有効にする';

  @override
  String settingsItemInspectNotifications(num n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$nString 件の通知',
      zero: '通知なし',
    );
    return '$_temp0';
  }

  @override
  String get settingsDialogNotificationsTitle => '設定済みの通知';

  @override
  String get settingsItemClearNotifications => 'すべての通知を削除';

  @override
  String get settingsActionClearCache => 'キャッシュを削除';

  @override
  String get settingsActionResetPreferences => '設定を初期化';

  @override
  String get settingsActionResetDirectoryPermissions => 'ディレクトリのアクセス権限をリセット';

  @override
  String get snackbarMessageNotificationsCleared => '通知を削除しました';

  @override
  String get snackbarMessageCacheCleared => 'キャッシュを削除しました';

  @override
  String get snackbarMessagePreferencesReset => '設定を初期化しました';

  @override
  String get snackbarMessageDirectoryPermissionsReset =>
      'ディレクトリのアクセス権限をリセットしました';

  @override
  String get confirmResetPreferencesDialogTitle => '設定を初期化しますか?';

  @override
  String get confirmResetPreferencesDialogMessage =>
      'すべての設定が初期値に戻されます。この操作は元に戻せません。';

  @override
  String get confirmResetPreferencesActionReset => '初期化';

  @override
  String get confirmResetPreferencesActionCancel => 'キャンセル';

  @override
  String get aboutLinkSupport => 'サポート・お問い合わせ';

  @override
  String get aboutLinkChangelog => '変更履歴';

  @override
  String get buttonOpenFile => 'ファイルを開く';

  @override
  String get buttonCreateFile => 'ファイルを作成';

  @override
  String get buttonOpenOrgroManual => 'Orgroマニュアルを開く';

  @override
  String get buttonOpenOrgManual => 'Orgマニュアルを開く';

  @override
  String get buttonOpenUrl => 'URLを開く';

  @override
  String get tooltipCreateFile => 'ファイルを作成';

  @override
  String get tooltipOpenFile => 'ファイルを開く';

  @override
  String get buttonSupport => 'サポート・お問い合わせ';

  @override
  String buttonVersion(String version) {
    return 'v$version';
  }

  @override
  String get sectionHeaderPinnedFiles => 'ピン留めされたファイル';

  @override
  String get sectionHeaderRecentFiles => '最近のファイル';

  @override
  String get recentFilesSortDialogTitle => '並び替え';

  @override
  String get sortKeyLastOpened => '最終アクセス';

  @override
  String get sortKeyName => '名前';

  @override
  String get sortKeyLocation => '保存場所';

  @override
  String get sortOrderAscending => '昇順';

  @override
  String get sortOrderDescending => '降順';

  @override
  String get fileSourceDocuments => 'ドキュメント';

  @override
  String get fileSourceDownloads => 'ダウンロード';

  @override
  String get fileSourceGoogleDrive => 'Google ドライブ';

  @override
  String get menuItemReaderMode => 'リーダーモード';

  @override
  String get menuItemWakelock => '画面を常にオンにする';

  @override
  String get menuItemFullWidth => '画面幅いっぱいで表示';

  @override
  String get menuItemScrollTop => '上へスクロール';

  @override
  String get menuItemScrollBottom => '下へスクロール';

  @override
  String get menuItemUndo => '取り消す';

  @override
  String get menuItemRedo => 'やり直す';

  @override
  String get tooltipFullWidth => '画面幅いっぱい表示の切替';

  @override
  String get tooltipReaderMode => 'リーダーモードの切替';

  @override
  String get tooltipScrollTop => '上へスクロール';

  @override
  String get tooltipScrollBottom => '下へスクロール';

  @override
  String get tooltipTextStyle => '文字スタイル';

  @override
  String get tooltipDecreaseTextScale => '文字サイズを小さく';

  @override
  String get tooltipIncreaseTextScale => '文字サイズを大きく';

  @override
  String get tooltipCycleVisibility => 'TODOを巡回';

  @override
  String get tooltipEditDocument => 'ドキュメントを編集';

  @override
  String get tooltipSearchDocument => 'ドキュメントを検索';

  @override
  String get tooltipPreviousSearchHit => '前の検索結果';

  @override
  String get tooltipNextSearchHit => '次の検索結果';

  @override
  String get hintTextSearch => '検索...';

  @override
  String get tooltipClearSearch => '検索をクリア';

  @override
  String searchHits(num n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$nString件';
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
  String get customFilterChipName => 'カスタム';

  @override
  String get snackbarMessageNeedsDirectoryPermissions => '相対リンクを解決する権限がありません';

  @override
  String get snackbarActionGrantAccess => '許可する';

  @override
  String get snackbarMessageNeedsEncryptionKey => '保存できませんでした。暗号化するためのパスワードが必要';

  @override
  String get snackbarActionEnterEncryptionKey => 'パスワードを入力';

  @override
  String get snackbarMessageNeedsNotificationsPermissions => '通知を送信する権限がありません';

  @override
  String get snackbarActionGrantNotificationsPermissions => '許可する';

  @override
  String get dialogTitleError => 'エラー';

  @override
  String get dialogActionConfirm => 'OK';

  @override
  String get dialogActionCancel => 'キャンセル';

  @override
  String get dialogActionHelp => 'ヘルプ';

  @override
  String get pageTitleError => 'エラー';

  @override
  String get pageTitleLoading => 'ロード中...';

  @override
  String pageTitleNarrow(String name) {
    return '$name › ナロー';
  }

  @override
  String pageTitleEditing(String name) {
    return '$name › 編集';
  }

  @override
  String get sectionActionNarrow => 'ナロー';

  @override
  String get sectionActionCycleTodo => 'TODO を巡回';

  @override
  String get bannerBodyRemoteImages => '本ドキュメントにはリモート画像が含まれています。表示しますか？';

  @override
  String get bannerBodyActionShowAlways => '常に表示';

  @override
  String get bannerBodyActionShowNever => '表示しない';

  @override
  String get bannerBodyActionShowOnce => '1 回のみ';

  @override
  String get bannerBodyRelativeLinks => '本ドキュメントには相対リンクが含まれています。アクセスを許可しますか？';

  @override
  String get bannerBodyActionGrantNotNow => '今は許可しない';

  @override
  String get bannerBodyActionGrantNever => '許可しない';

  @override
  String get bannerBodyActionGrantNow => '許可';

  @override
  String get bannerBodySaveDocument => '変更を保存しますか？';

  @override
  String get bannerBodyActionSaveAlways => '常に保存';

  @override
  String get bannerBodyActionSaveNever => '保存しない';

  @override
  String get bannerBodyActionSaveOnce => '今回だけ';

  @override
  String get bannerBodyDecryptContent => '本ドキュメントに暗号化されたコンテンツが含まれています。復号しますか？';

  @override
  String get bannerBodyActionDecryptNow => '復号する';

  @override
  String get bannerBodyActionDecryptNotNow => '今は復号しない';

  @override
  String get bannerBodyActionDecryptNever => '復号しない';

  @override
  String get bannerBodyAgendaNotifications => 'このファイルのアジェンダ項目の通知を受け取りますか？';

  @override
  String get bannerBodyActionAgendaEnable => '受け取る';

  @override
  String get bannerBodyActionAgendaNotNow => '今は受け取らない';

  @override
  String get bannerBodyActionAgendaNever => '受け取らない';

  @override
  String get saveChangesDialogTitle => '変更を保存しますか？';

  @override
  String get saveChangesDialogMessage => '元ファイルに書き戻しできません。';

  @override
  String get saveChangesDialogForbiddenMessage => '元ファイルに書き戻さないよう設定されています。';

  @override
  String get saveActionShare => '共有する';

  @override
  String get saveActionDiscard => '破棄する';

  @override
  String get saveActionSaveAs => '名前をつけて保存する';

  @override
  String get discardChangesDialogTitle => '変更を破棄しますか？';

  @override
  String get discardActionDiscard => '破棄する';

  @override
  String get discardActionCancel => 'キャンセル';

  @override
  String get savedMessage => '保存しました';

  @override
  String get inputDecryptionPasswordDialogTitle => '復号のためのパスワードを入力';

  @override
  String get inputEncryptionPasswordDialogTitle => '暗号化のためのパスワードを入力';

  @override
  String get inputEncryptionPasswordDialogBody =>
      'パスワードが未指定の Org Crypt セクションを暗号化するために使用されます。';

  @override
  String get inputCustomFilterDialogTitle => 'カスタムフィルタ';

  @override
  String get inputCustomFilterDialogHistoryButton => '履歴';

  @override
  String get loadingProgressDialogTitle => 'ロード中…';

  @override
  String get preparingProgressDialogTitle => '準備中…';

  @override
  String get decryptingProgressDialogTitle => '復号中…';

  @override
  String get encryptingProgressDialogTitle => '暗号化中…';

  @override
  String get serializingProgressDialogTitle => '書き出し中…';

  @override
  String get savingProgressDialogTitle => '保存中…';

  @override
  String get searchingProgressDialogTitle => '検索中…';

  @override
  String get citationsDialogTitle => '参考文献';

  @override
  String get citationsDialogOpenLink => 'リンクを開く';

  @override
  String get createFileDialogTitle => 'ファイルを作成';

  @override
  String get createFileDefaultName => '名称未設定.org';

  @override
  String get saveAsDialogTitle => '名前をつけて保存';

  @override
  String get inputUrlDialogTitle => 'URLを入力';

  @override
  String get startTimePickerTitle => '開始時間の選択';

  @override
  String get endTimePickerTitle => '終了時間の選択';

  @override
  String get captureToDialogTitle => 'キャプチャ先';

  @override
  String get captureToClipboardItem => 'クリップボード';

  @override
  String get captureToNewDocumentItem => '新規ファイル';

  @override
  String get snackbarMessageInvalidCaptureUri => '不正なキャプチャURL';

  @override
  String get snackbarMessageBibliographiesNotFound => '参考文献ファイルの指定がありませんでした';

  @override
  String get snackbarMessageCitationKeysNotFound => '文献キーが見つかりませんでした';

  @override
  String get snackbarMessageCitationsNotFound => '文献情報が見つかりませんでした';

  @override
  String snackbarMessageSomeCitationsNotFound(String citations) {
    return '文献情報が見つかりませんでした: $citations';
  }

  @override
  String get errorCannotResolveRelativePath => '本ドキュメントからの相対パスは解決できません。';

  @override
  String errorPathResolvedToNonFile(String path, String resolved) {
    return '$path を解決した結果はファイルではありませんでした。結果: $resolved';
  }

  @override
  String errorUnknownType(Object type) {
    return '不明な型: $type';
  }

  @override
  String errorUnexpectedHttpResponse(Object response) {
    return '予期しない HTTP レスポンス: $response';
  }

  @override
  String errorOrgParser(Object result) {
    return 'パーサーエラー: $result';
  }

  @override
  String errorOrgExecution(Object message, String code) {
    return '以下のコードに実行エラーが発生しました: $message\n\n$code';
  }

  @override
  String errorOrgTimeout(num timeout, String code) {
    final intl.NumberFormat timeoutNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String timeoutString = timeoutNumberFormat.format(timeout);

    return '以下のコードの実行が ${timeoutString}ms でタイムアウトしました\n\n$code';
  }

  @override
  String errorOrgArgument(Object item) {
    return '不正な引数: $item';
  }

  @override
  String get errorDecryptionFailed => '復号が失敗しました';

  @override
  String errorLinkNotHandled(Object link) {
    return 'リンク「$link」を開けませんでした';
  }

  @override
  String errorExternalIdNotFound(String id) {
    return 'ID「$id」のファイルが見つかりませんでした';
  }

  @override
  String errorSectionNotFound(String section) {
    return '「$section」が見つかりませんでした';
  }

  @override
  String errorUnsupportedSearchOption(String option) {
    return '未対応の検索オプション: $option';
  }

  @override
  String errorSchedulingNotifications(Object message) {
    return '通知の設定に失敗しました: $message';
  }

  @override
  String get tooltipErrorDetails => 'エラー詳細を見る';

  @override
  String get editInsertedHeadline => '[編集によって挿入]';

  @override
  String get tooltipApplyChanges => '変更を適用する';

  @override
  String get tooltipUndo => '元に戻す';

  @override
  String get tooltipRedo => 'やり直す';

  @override
  String get tooltipToggleUnorderedList => '箇条書きリストの切替';

  @override
  String get tooltipToggleOrderedList => '番号付きリストの切替';

  @override
  String get tooltipDecreaseIndent => 'インデントを減らす';

  @override
  String get tooltipIncreaseIndent => 'インデントを増やす';

  @override
  String get tooltipBold => '太字';

  @override
  String get tooltipItalic => '斜体';

  @override
  String get tooltipUnderline => '下線';

  @override
  String get tooltipStrikethrough => '取り消し線';

  @override
  String get tooltipCode => 'コード';

  @override
  String get tooltipInsertLink => 'リンクを挿入';

  @override
  String get tooltipInsertDate => '日付を挿入';

  @override
  String get tooltipSubscript => '下付き文字';

  @override
  String get tooltipSuperscript => '上付き文字';

  @override
  String get donateItemTitle => 'Orgroの開発を支援する';

  @override
  String get donateItemSubtitle => 'ご支援に感謝します！';

  @override
  String get entitlementsLoadingItem => 'ロード中…';

  @override
  String entitlementsFreeTrialItem(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMMd(
      localeName,
    ).add_jm();
    final String dateString = dateDateFormat.format(date);

    return '無料期間は$dateStringに終了します';
  }

  @override
  String get entitlementsTrialExpiredItem => '無料期間は終了しました';

  @override
  String entitlementsPurchaseItemTitle(String price) {
    return 'Orgroを$priceで購入（買切り）';
  }

  @override
  String get entitlementsPurchaseItemSubtitle => '全機能が解放され、開発者の士気が上がります';

  @override
  String get entitlementsRestorePurchasesItem => '購入を復元';

  @override
  String get entitlementsPurchasedItem => '購入済み';

  @override
  String get entitlementsPurchasedItemSubtitle => 'ご購入頂きありがとうございます';

  @override
  String get entitlementsLegacyPurchaseItemSubtitle => '長い間ご支援頂きありがとうございます！';

  @override
  String get entitlementsLockedDialogTitle => '無料期間は終了しました';

  @override
  String get entitlementsLockedDialogMessage =>
      '引き続きOrgroをご利用いただくには、購入するか、購入済みの場合は復元してください。\n\n購入は一度きりの支払いで、すべての機能が解放されます。';

  @override
  String entitlementsLockedDialogActionPurchase(String price) {
    return '購入する（$price）';
  }

  @override
  String get entitlementsLockedDialogActionRestore => '購入を復元';

  @override
  String get entitlementsLockedDialogActionMoreInfo => '詳しく見る';
}
