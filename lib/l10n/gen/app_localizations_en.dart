// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'DayZ';

  @override
  String onThisDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries today',
      one: '1 entry today',
      zero: 'No entries today',
    );
    return '$_temp0';
  }

  @override
  String yearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years ago',
      one: '1 year ago',
      zero: 'This year',
    );
    return '$_temp0';
  }

  @override
  String get locale_zh => '中文';

  @override
  String get locale_en => 'English';

  @override
  String get followSystem => 'Follow System';

  @override
  String get languageSetting => 'Language';

  @override
  String get toastDefault => 'Notice';

  @override
  String get toastUndo => 'Undo';

  @override
  String get toastView => 'View';

  @override
  String get toastRetry => 'Retry';

  @override
  String get toastDismiss => 'Dismiss';

  @override
  String get sheetCancel => 'Cancel';

  @override
  String get sheetDelete => 'Delete';

  @override
  String get sheetConfirm => 'Confirm';

  @override
  String get sheetSelected => 'Selected';

  @override
  String get emptyTitle => 'No content yet';

  @override
  String get emptyDescription =>
      'Write your first journal entry and it will appear here.';

  @override
  String get favorite => 'Favorite';

  @override
  String get unfavorite => 'Unfavorite';

  @override
  String get menu => 'Menu';

  @override
  String get more => 'More';

  @override
  String get close => 'Close';

  @override
  String get search => 'Search';

  @override
  String get searchCancel => 'Cancel search';

  @override
  String get searchHint => 'Search entries, tags, locations';

  @override
  String get clear => 'Clear';

  @override
  String get remove => 'Remove';

  @override
  String get add => 'Add';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get selected => 'Selected';

  @override
  String get unselected => 'Not selected';

  @override
  String get switchOn => 'On';

  @override
  String get switchOff => 'Off';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get showMore => 'Show more';

  @override
  String get camera => 'Camera';

  @override
  String get voice => 'Voice';

  @override
  String get plainText => 'Text';

  @override
  String galleryMoreCount(int count) {
    return '+$count';
  }

  @override
  String entryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
    );
    return '$_temp0';
  }

  @override
  String get loadingEarlier => 'Loading earlier...';

  @override
  String get reachedOldest => 'You have reached the oldest entry';

  @override
  String get timelineEmptyTitle => 'No journal entries yet';

  @override
  String get timelineEmptyDescription =>
      'Tap the button in the lower right to write the first page.';

  @override
  String get jumpToDate => 'Jump to date';

  @override
  String get backToToday => 'Back to today';

  @override
  String get drawerProfileName => 'DayZ';

  @override
  String get drawerProfileInitial => 'D';

  @override
  String get drawerProfileStatus => 'Local · Encrypted';

  @override
  String get shellPlaceholderSuffix =>
      'Waiting for page-level spec implementation';

  @override
  String get allJournals => 'All journals';

  @override
  String get journalSectionHeader => 'Journals';

  @override
  String get browseSectionHeader => 'Browse';

  @override
  String get newJournal => 'New journal';

  @override
  String get sheetCreate => 'Create';

  @override
  String get journalNameInputPlaceholder => 'e.g., Reading, Fitness, Travel';

  @override
  String get journalNameLabel => 'Name';

  @override
  String get journalColorLabel => 'Cover Color';

  @override
  String get settings => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsGroupPrivacy => 'Privacy & Encryption';

  @override
  String get settingsGroupBackup => 'Backup & Export';

  @override
  String get settingsGroupAppearance => 'Appearance';

  @override
  String get settingsGroupWriting => 'Writing';

  @override
  String settingsAccountStats(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
    );
    return '$_temp0 · Local library $size';
  }

  @override
  String get settingsAppLockTitle => 'App Lock';

  @override
  String get settingsAppLockSubtitle => 'Face ID / passcode unlock';

  @override
  String get settingsDbEncryptionTitle => 'Database encryption';

  @override
  String get settingsDbEncryptionSubtitle => 'SQLCipher · always on';

  @override
  String get settingsDbEncryptedValue => 'Encrypted';

  @override
  String get settingsMediaNotLockedByPassword =>
      'Setting a master password does not encrypt photos. Photos are always protected by the device key.';

  @override
  String get settingsBackupTitle => 'Local backup';

  @override
  String get settingsBackupSubtitle => 'Last · Today 08:30';

  @override
  String get settingsExportTitle => 'Export';

  @override
  String get settingsExportSubtitle => 'PDF · Markdown · JSON';

  @override
  String get settingsThemeTitle => 'Theme color';

  @override
  String get settingsThemeSubtitle => 'Mist purple / warm amber / fog sage';

  @override
  String get settingsAppearanceModeTitle => 'Appearance mode';

  @override
  String get settingsAppearanceModeSubtitle => 'Follow system';

  @override
  String get settingsDraftRecoveryTitle => 'Recover unfinished edits';

  @override
  String get settingsDraftRecoverySubtitle =>
      'Prompt for residual drafts on launch';

  @override
  String get settingsThemePurple => 'Mist purple';

  @override
  String get settingsThemeAmber => 'Warm amber';

  @override
  String get settingsThemeSage => 'Fog sage';

  @override
  String get settingsModeSystem => 'Follow system';

  @override
  String get settingsModeLight => 'Light';

  @override
  String get settingsModeDark => 'Dark';

  @override
  String get settingsBackSemanticLabel => 'Back';

  @override
  String get settingsAppLockSemanticLabel => 'App Lock switch';

  @override
  String get settingsDraftRecoverySemanticLabel =>
      'Recover unfinished edits switch';

  @override
  String get settingsActionUnavailableToast => 'Feature coming later';

  @override
  String get timeline => 'Timeline';

  @override
  String get reader => 'Reader';

  @override
  String get readerMetaDate => 'Date';

  @override
  String get readerMetaWeather => 'Weather';

  @override
  String get readerMetaPlace => 'Place';

  @override
  String get readerMetaMood => 'Mood';

  @override
  String get readerMetaTags => 'Tags';

  @override
  String readerDateSemantic(String date) {
    return 'Journal date: $date';
  }

  @override
  String readerWeatherSemantic(String weather) {
    return 'Weather: $weather';
  }

  @override
  String readerPlaceSemantic(String place) {
    return 'Place: $place';
  }

  @override
  String readerMoodSemantic(String mood) {
    return 'Mood: $mood';
  }

  @override
  String readerTagSemantic(String tag) {
    return 'Tag: $tag';
  }

  @override
  String get readerActionsSemantic => 'Reader actions';

  @override
  String get readerActionEdit => 'Edit';

  @override
  String get readerActionShare => 'Share';

  @override
  String get readerActionMoveToJournal => 'Move to journal';

  @override
  String get readerActionFavorite => 'Favorite';

  @override
  String get readerActionUnfavorite => 'Unfavorite';

  @override
  String get readerActionDelete => 'Delete';

  @override
  String get readerDeleteTitle => 'Delete this entry?';

  @override
  String get readerDeleteMessage =>
      'It will move to Trash and can be restored there.';

  @override
  String get readerDeleteConfirm => 'Move to Trash';

  @override
  String get readerEmptyTitle => 'Entry not found';

  @override
  String get readerEmptyDescription =>
      'It may have been deleted or is not in this journal.';

  @override
  String get readerToastFavoriteAdded => 'Added to favorites';

  @override
  String get readerToastFavoriteRemoved => 'Removed from favorites';

  @override
  String get readerToastDeleted => 'Moved to Trash';

  @override
  String get readerToastRestored => 'Restored';

  @override
  String readerToastMovedToJournal(String journalName) {
    return 'Moved to \"$journalName\"';
  }

  @override
  String get readerToastSharePending => 'Share will be available later';

  @override
  String get readerToastActionFailed => 'Action failed. Try again.';

  @override
  String get editor => 'Editor';

  @override
  String get onThisDay => 'On This Day';

  @override
  String get calendar => 'Calendar';

  @override
  String get favorites => 'Favorites';

  @override
  String get trash => 'Trash';

  @override
  String get memoryCardExport => 'Memory card export';

  @override
  String get debugHome => 'Debug Home';

  @override
  String get notFound => 'Not Found';

  @override
  String get editorTitleNew => 'New Entry';

  @override
  String get editorTitleDraftSaved => 'Draft Saved';

  @override
  String get editorTitlePlaceholder => 'Title';

  @override
  String get editorBodyPlaceholderEmpty => 'Write something...';

  @override
  String get editorBodyPlaceholderWriting => 'Keep writing today\'s story here';

  @override
  String get editorDone => 'Done';

  @override
  String get editorCloseSemanticLabel => 'Close editor';

  @override
  String get editorDoneSemanticLabel => 'Save and return';

  @override
  String get editorMetaMood => 'Mood';

  @override
  String get editorMetaWeather => 'Weather';

  @override
  String get editorMetaLocation => 'Location';

  @override
  String get editorMetaTags => 'Tags';

  @override
  String get editorMetaPlaceholderSheet =>
      'Picker flow will be connected by a later spec';

  @override
  String editorDateKickerToday(String date, String weekday) {
    return 'Today · $date $weekday';
  }

  @override
  String editorDateKicker(String date, String weekday) {
    return '$date $weekday';
  }

  @override
  String get editorToolbarHeading => 'Heading';

  @override
  String get editorToolbarBold => 'Bold';

  @override
  String get editorToolbarItalic => 'Italic';

  @override
  String get editorToolbarUnderline => 'Underline';

  @override
  String get editorToolbarStrikethrough => 'Strikethrough';

  @override
  String get editorToolbarCode => 'Code';

  @override
  String get editorToolbarColor => 'Highlight Color';

  @override
  String get editorToolbarBulletedList => 'Bulleted List';

  @override
  String get editorToolbarNumberedList => 'Numbered List';

  @override
  String get editorToolbarTodoList => 'Todo List';

  @override
  String get editorToolbarQuote => 'Quote';

  @override
  String get editorToolbarLink => 'Link';

  @override
  String get editorToolbarDivider => 'Divider';

  @override
  String get editorToolbarImage => 'Image';

  @override
  String get editorColorTextRust => 'Rust';

  @override
  String get editorColorTextAmber => 'Amber';

  @override
  String get editorColorTextBronze => 'Bronze';

  @override
  String get editorColorTextOlive => 'Olive';

  @override
  String get editorColorTextSlate => 'Slate';

  @override
  String get editorColorTextLilac => 'Lilac';

  @override
  String get editorColorHighlightYellow => 'Warm Yellow';

  @override
  String get editorColorHighlightGreen => 'Light Green';

  @override
  String get editorColorHighlightBlue => 'Light Blue';

  @override
  String get editorColorHighlightPurple => 'Light Purple';

  @override
  String get editorColorHighlightPink => 'Light Pink';

  @override
  String get editorHeadingParagraphGlyph => 'Body';

  @override
  String get editorHeadingParagraphLabel => 'Paragraph';

  @override
  String get editorHeadingLabelH1 => 'Title';

  @override
  String get editorHeadingLabelH2 => 'Heading';

  @override
  String get editorHeadingLabelH3 => 'Subheading';
}
