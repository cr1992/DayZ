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
  String get journalNameInputPlaceholder => 'Enter journal name';

  @override
  String get journalNameLabel => 'Journal name';

  @override
  String get journalColorLabel => 'Journal color';

  @override
  String get settings => 'Settings';

  @override
  String get timeline => 'Timeline';

  @override
  String get reader => 'Reader';

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
}
