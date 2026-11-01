// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Expenses';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navTransactions => 'Transactions';

  @override
  String get navReview => 'Review';

  @override
  String get navImport => 'Import';

  @override
  String get navAccounts => 'Accounts';

  @override
  String get navCategories => 'Categories & rules';

  @override
  String scopeCash(String currency) {
    return 'Cash $currency';
  }

  @override
  String get noData => 'No data yet. Import a statement to start.';

  @override
  String spentIn(String month) {
    return 'Spent in $month';
  }

  @override
  String incomeIn(String month) {
    return 'Income in $month';
  }

  @override
  String get average6 => '6-month average';

  @override
  String vsAverage(String percent) {
    return '$percent vs 6-month average';
  }

  @override
  String get monthlyByGroup => 'Monthly spending by group';

  @override
  String get byCategory => 'By category';

  @override
  String get topMerchants => 'Top merchants';

  @override
  String get other => 'Other';

  @override
  String get uncategorized => 'Uncategorized';

  @override
  String get transfersExcluded => 'Transfers between your own accounts and card payments are not counted as spending.';

  @override
  String get search => 'Search';

  @override
  String get allCategories => 'All categories';

  @override
  String get allAccounts => 'All accounts';

  @override
  String get allDates => 'All dates';

  @override
  String get colDate => 'Date';

  @override
  String get colAccount => 'Account';

  @override
  String get colMerchant => 'Merchant';

  @override
  String get colCategory => 'Category';

  @override
  String get colAmount => 'Amount';

  @override
  String transactionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
      zero: 'No transactions',
    );
    return '$_temp0';
  }

  @override
  String get categorySearchHint => 'Search (e.g. gas, rent, Costco) — Enter to pick';

  @override
  String get frequentCategories => 'Frequent';

  @override
  String get sortDate => 'Date';

  @override
  String get sortAmount => 'Amount';

  @override
  String get sortMerchant => 'By merchant';

  @override
  String selectUnder(String amount) {
    return 'Select under $amount';
  }

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count selected', one: '1 selected');
    return '$_temp0';
  }

  @override
  String get clearSelection => 'Clear selection';

  @override
  String bulkSetQuestion(String category, int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count lines', one: '1 line');
    return 'Set “$category” on $_temp0?';
  }

  @override
  String bulkConfirmQuestion(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count lines', one: '1 line');
    return 'Accept the suggested category for $_temp0?';
  }

  @override
  String bulkConfirmSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lines without a precise category stay',
      one: '1 line without a precise category stays',
    );
    return '$_temp0 in review.';
  }

  @override
  String get reasonRule => 'Rule';

  @override
  String get reasonMerchant => 'Chosen before for this merchant';

  @override
  String reasonBank(String category) {
    return 'Bank hint → $category';
  }

  @override
  String get reasonSeed => 'Known merchant';

  @override
  String reasonKeyword(String word) {
    return 'Keyword “$word”';
  }

  @override
  String reasonHint(String rate, String category) {
    return 'Bonidollars $rate % → $category';
  }

  @override
  String reasonLearned(int count, String word) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count lines', one: '1 line');
    return 'Like $_temp0 with “$word”';
  }

  @override
  String get reasonNone => 'No clue: pick one';

  @override
  String anomalyHigh(String merchant) {
    return 'Very large expense: $merchant';
  }

  @override
  String anomalyHighBody(String amount, String date) {
    return '$amount on $date';
  }

  @override
  String anomalyRegular(String merchant) {
    return 'Regular payment changed: $merchant';
  }

  @override
  String anomalyRegularBody(String amount, String date, String usual) {
    return '$amount on $date — usually $usual';
  }

  @override
  String anomalyMissing(String merchant) {
    return 'Regular payment missing: $merchant';
  }

  @override
  String anomalyMissingBody(String usual, String date) {
    return '$usual expected around $date, not found';
  }

  @override
  String get markNormal => 'This payment is normal';

  @override
  String markedNormal(String date, String amount) {
    return '$date · $amount — marked normal';
  }

  @override
  String get undo => 'Undo';

  @override
  String expectedOn(String date) {
    return 'expected $date';
  }

  @override
  String whyRegularAmount(String date, String amount, String diff, String pct, String usual, int count, int spread) {
    return 'On $date, $amount: $diff ($pct) compared with the usual $usual (median of the $count payments before; ±$spread % is normal).';
  }

  @override
  String whyRegularMissing(String usual, String date, int days, String until) {
    return '$usual expected around $date (± $days days): no payment found, though the account has lines until $until. A statement missing, or the payment stopped?';
  }

  @override
  String whyHigh(String date, String amount, int share, String threshold) {
    return 'On $date, $amount: among your top $share % expenses of the year (from $threshold).';
  }

  @override
  String whyNewFee(String date, String amount) {
    return 'On $date, $amount: the first fee of this kind.';
  }

  @override
  String get pastUnusual => 'Past unusual payment (no alert)';

  @override
  String anomalyNewFee(String merchant) {
    return 'New fee: $merchant';
  }

  @override
  String anomalyNewFeeBody(String amount, String date) {
    return '$amount on $date';
  }

  @override
  String get copyForSearch => 'Copy name and location (to search online)';

  @override
  String copied(String text) {
    return 'Copied: $text';
  }

  @override
  String get reviewEmpty => 'Nothing to review.';

  @override
  String get reviewHint =>
      'Check the suggested category, or pick another. Your choice can be remembered for the merchant.';

  @override
  String get confirm => 'Confirm';

  @override
  String get chooseCategory => 'Choose a category';

  @override
  String rememberMerchant(String merchant) {
    return 'Always use this category for $merchant';
  }

  @override
  String updatedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions updated',
      one: '1 transaction updated',
    );
    return '$_temp0';
  }

  @override
  String get importTitle => 'Import statements';

  @override
  String get notifications => 'Notifications';

  @override
  String get noNotifications => 'Nothing to report';

  @override
  String get goImport => 'Import';

  @override
  String statementDue(String statement) {
    return '$statement: new statement to download';
  }

  @override
  String statementDueBody(String last, String next) {
    return 'Last imported: up to $last. The next one (to $next) should be available.';
  }

  @override
  String statementsDue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count statements to download',
      one: '1 statement to download',
    );
    return '$_temp0';
  }

  @override
  String get exportTransactions => 'Export…';

  @override
  String get exportHint => 'Save these transactions (this month or all dates, with the filters) as Excel or CSV';

  @override
  String get exportFileName => 'transactions';

  @override
  String exportedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lines exported',
      one: '1 line exported',
    );
    return '$_temp0';
  }

  @override
  String get openFile => 'Open';

  @override
  String get splitPart => 'part';

  @override
  String get hdrBank => 'Bank';

  @override
  String get hdrDescription => 'Description';

  @override
  String get hdrGroup => 'Group';

  @override
  String get hdrType => 'Type';

  @override
  String get hdrCurrency => 'Currency';

  @override
  String get hdrForeignAmount => 'Original amount';

  @override
  String get hdrForeignCurrency => 'Original currency';

  @override
  String get hdrNote => 'Note';

  @override
  String get importDrop => 'Drop your bank statements here (PDF, CSV, OFX…)';

  @override
  String get importChoose => 'Choose files…';

  @override
  String get importReading => 'Reading…';

  @override
  String importDone(int count, int duplicates, int review, int transfers) {
    return '$count new · $duplicates already known · $review to review · $transfers transfers matched';
  }

  @override
  String importUnmatched(int count) {
    return '$count new lines on days already imported from another file (PDF or CSV) were not found there: check them in Transactions';
  }

  @override
  String get importNotVerified => 'Not verified: this file has no balance or total to check its lines against';

  @override
  String guideTitle(String bank, String fileType) {
    return '$bank: download your transactions ($fileType)';
  }

  @override
  String guideButton(String fileType) {
    return 'How to get your $fileType files';
  }

  @override
  String importExportHint(String bank, String fileType) {
    return '$bank also exports your transactions as $fileType: more reliable than reading PDFs.';
  }

  @override
  String get guideOpen => 'How?';

  @override
  String get importAlready => 'Already imported';

  @override
  String get importInvalid => 'Not imported: the statement\'s own totals don\'t match';

  @override
  String importUnknown(String banks) {
    return 'Statement not recognized. Supported banks: $banks';
  }

  @override
  String importError(String message) {
    return 'Could not read the file: $message';
  }

  @override
  String get importHistory => 'Imported statements';

  @override
  String get importPrivacy =>
      'PDFs are read and then discarded. Only their content fingerprint is kept to detect re-imports.';

  @override
  String deleteStatementConfirm(int count) {
    return 'Delete this statement and its $count transactions?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String balanceEndOf(String month) {
    return 'Balance at end of $month';
  }

  @override
  String balanceAsOf(String date) {
    return 'Balance on $date';
  }

  @override
  String get addCashExpense => 'Add cash expense';

  @override
  String get amount => 'Amount';

  @override
  String get merchantOptional => 'Merchant (optional)';

  @override
  String get note => 'Note';

  @override
  String get date => 'Date';

  @override
  String get rules => 'Rules';

  @override
  String get addRule => 'Add rule';

  @override
  String get ruleContains => 'Description contains';

  @override
  String ruleSummary(String text, String category) {
    return '“$text” → $category';
  }

  @override
  String merchantRule(String merchant, String category) {
    return '$merchant → $category';
  }

  @override
  String get noRules =>
      'No rules yet. Choosing “always” when reviewing remembers a merchant; rules here match description text.';

  @override
  String get rememberedMerchants => 'Remembered merchants';

  @override
  String get categories => 'Categories';

  @override
  String get details => 'Details';

  @override
  String get statementText => 'Statement text';

  @override
  String get location => 'Location';

  @override
  String get originalAmount => 'Original amount';

  @override
  String get kind => 'Type';

  @override
  String get card => 'Card';

  @override
  String get kind_expense => 'Expense';

  @override
  String get kind_income => 'Income';

  @override
  String get kind_refund => 'Refund';

  @override
  String get kind_fee => 'Fee';

  @override
  String get kind_interest => 'Interest';

  @override
  String get kind_transfer => 'Transfer between my accounts';

  @override
  String get kind_externalTransfer => 'Transfer to another bank';

  @override
  String get language => 'Language';

  @override
  String get notCounted => 'Not counted in spending';

  @override
  String get navTargets => 'Targets';

  @override
  String get addTarget => 'Add target';

  @override
  String get editTarget => 'Edit target';

  @override
  String get allSpending => 'All spending';

  @override
  String get period_week => 'Weekly';

  @override
  String get period_month => 'Monthly';

  @override
  String get period_year => 'Yearly';

  @override
  String targetSpent(String spent, String target) {
    return '$spent of $target';
  }

  @override
  String targetProjected(String amount) {
    return 'Projected: $amount';
  }

  @override
  String get status_onTrack => 'On track';

  @override
  String get status_atRisk => 'At risk';

  @override
  String get status_over => 'Over target';

  @override
  String targetSuggestion(String amount) {
    return 'Suggestion: $amount (average of the last 3 periods)';
  }

  @override
  String get noTargets =>
      'No targets yet. Set a limit per week, month or year for all spending, a group or a category.';

  @override
  String get targetsHint => 'Targets are indicators only: nothing is blocked or moved.';

  @override
  String get history => 'History';

  @override
  String get withinTarget => 'Within target';

  @override
  String get split => 'Split';

  @override
  String get splitTitle => 'Split across categories';

  @override
  String get splitAddPart => 'Add a part';

  @override
  String splitRemaining(String amount) {
    return 'Remaining: $amount';
  }

  @override
  String get splitRemove => 'Remove split';

  @override
  String splitLabel(int count) {
    return 'Split · $count';
  }

  @override
  String get edit => 'Edit';

  @override
  String importAlreadySameFile(String file, String date) {
    return 'Already imported: same file as “$file” (imported $date)';
  }

  @override
  String importAlreadySameStatement(String file, String date) {
    return 'Already imported: same statement as “$file” (imported $date), from another file';
  }

  @override
  String get importAlreadySameLines => 'Already imported: every line of this file is already known';

  @override
  String get noDuplicates => 'No statement imported twice';

  @override
  String duplicatesFound(int count) {
    return '$count files are the same statement imported more than once. Delete the extra copies:';
  }

  @override
  String importedOn(String date) {
    return 'imported $date';
  }

  @override
  String emptyMonth(String month) {
    return 'No transactions in $month yet: statements arrive after the month ends.';
  }

  @override
  String goToMonth(String month) {
    return 'Go to $month';
  }

  @override
  String get noSpendingThisMonth => 'No spending this month.';

  @override
  String dataLocation(String path) {
    return 'Data is saved on this computer: $path';
  }

  @override
  String get addCategory => 'Add category';

  @override
  String get addGroup => 'Add group';

  @override
  String get editCategory => 'Edit category';

  @override
  String get archive => 'Archive';

  @override
  String get nameFr => 'Name (French)';

  @override
  String get nameEn => 'Name (English, optional)';

  @override
  String archiveConfirm(String name) {
    return 'Archive “$name”? It will no longer be offered; past reports keep their numbers.';
  }

  @override
  String archiveMove(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions use it.',
      one: '1 transaction uses it.',
    );
    return '$_temp0 Choose where to move them.';
  }

  @override
  String get categoriesHint => 'Click a category to rename or archive it.';

  @override
  String get newCategory => 'New category';

  @override
  String createNamed(String name) {
    return 'Create “$name”';
  }

  @override
  String get group => 'Group';

  @override
  String addToGroup(String group) {
    return 'Add a category to $group';
  }

  @override
  String get navStats => 'Statistics';

  @override
  String get range6 => '6 months';

  @override
  String get range12 => '12 months';

  @override
  String get rangeThisYear => 'This year';

  @override
  String get rangeLastYear => 'Last year';

  @override
  String get rangeAll => 'Everything';

  @override
  String get tabTrends => 'Trends';

  @override
  String get tabCategories => 'Categories';

  @override
  String get tabMerchants => 'Merchants';

  @override
  String get tabCompare => 'Compare';

  @override
  String get tabRecurring => 'Recurring';

  @override
  String get tabBalances => 'Balances';

  @override
  String get chartBalances => 'Month-end balance';

  @override
  String get balancesHint =>
      'Rebuilt from the latest statement balance and the transactions before it. Transfers between your accounts count as deposits and withdrawals.';

  @override
  String get balancesNone => 'No balance to follow here: pick a checking or savings account (or All accounts).';

  @override
  String get balance => 'Balance';

  @override
  String get balanceChange => 'Change over the period';

  @override
  String get colYear => 'Year';

  @override
  String get colDeposits => 'Deposits';

  @override
  String get colWithdrawals => 'Withdrawals';

  @override
  String get colInterest => 'Interest';

  @override
  String get colChange => 'Change';

  @override
  String get colYearEnd => 'Balance at end';

  @override
  String interestOf(String amount) {
    return 'incl. $amount interest';
  }

  @override
  String globalSince(String month, String label) {
    return 'All accounts from $month only: before that there is no $label statement, so spending would look lower. Pick one account at the top to see its whole history.';
  }

  @override
  String get recurringPerMonth => 'Recurring per month';

  @override
  String recurringCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recurring payments',
      one: '1 recurring payment',
    );
    return '$_temp0';
  }

  @override
  String get recurringHint =>
      'Found automatically in all imported history: same merchant, regular interval, similar amount, even when the date varies (a bill paid by hand). Needs at least 3 payments.';

  @override
  String get recurringNone => 'No recurring payment found yet: import a few months of statements.';

  @override
  String get recurringStopped => 'Not seen lately (probably stopped)';

  @override
  String get cadenceWeekly => 'Weekly';

  @override
  String get cadenceBiweekly => 'Every 2 weeks';

  @override
  String get cadenceMonthly => 'Monthly';

  @override
  String get cadenceQuarterly => 'Quarterly';

  @override
  String get cadenceYearly => 'Yearly';

  @override
  String onDay(int day) {
    return 'on day $day';
  }

  @override
  String dayBetween(int from, int to) {
    return 'between day $from and $to';
  }

  @override
  String get colFrequency => 'Frequency';

  @override
  String get colPerMonth => 'Per month';

  @override
  String get colPayments => 'Payments';

  @override
  String get colNext => 'Next expected';

  @override
  String get statTotal => 'Total';

  @override
  String get statAverage => 'Monthly average';

  @override
  String get statVsPrevious => 'vs previous period';

  @override
  String get statMostExpensive => 'Most expensive month';

  @override
  String get statLeastExpensive => 'Least expensive month';

  @override
  String get chartMonthlySpending => 'Monthly spending';

  @override
  String get chartIncomeSpending => 'Income and spending';

  @override
  String get legendSpending => 'Spending';

  @override
  String get legendIncome => 'Income';

  @override
  String get showEverything => 'Show everything';

  @override
  String get chartSpendingByStore => 'Spending by store';

  @override
  String get byStore => 'By store';

  @override
  String get byCategoryTrend => 'By category';

  @override
  String purchasesPerMonth(String count) {
    return '$count purchases / month';
  }

  @override
  String analyzeOnly(String name) {
    return 'Analyze $name only';
  }

  @override
  String get byGroupTrend => 'Trend by group';

  @override
  String get perMonth => 'per month';

  @override
  String get trend => 'Trend';

  @override
  String get share => 'Share';

  @override
  String get visits => 'Purchases';

  @override
  String get averageTicket => 'Average ticket';

  @override
  String get lastVisit => 'Last';

  @override
  String get merchantsHint => 'Businesses only: transfers to people count in their category.';

  @override
  String get cmpPreviousMonth => 'vs previous month';

  @override
  String get cmpSameMonthLastYear => 'vs same month last year';

  @override
  String get cmpYearToDate => 'Year to date vs last year';

  @override
  String yearToDate(int year) {
    final intl.NumberFormat yearNumberFormat = intl.NumberFormat.compact(locale: localeName);
    final String yearString = yearNumberFormat.format(year);

    return 'Jan – this month $yearString';
  }

  @override
  String get difference => 'Difference';

  @override
  String get lessSpent => 'less';

  @override
  String get moreSpent => 'more';

  @override
  String get unspecified => 'unspecified';

  @override
  String get close => 'Close';

  @override
  String partOf(String amount) {
    return 'part of $amount';
  }

  @override
  String gapMissing(String label) {
    return '$label statement missing';
  }

  @override
  String gapUntil(String label, String date) {
    return '$label only until $date';
  }

  @override
  String get incompleteMonths => 'Incomplete months — counted in totals, left out of averages and comparisons:';

  @override
  String get incomplete => 'incomplete';

  @override
  String overCompleteMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count complete months',
      one: '1 complete month',
    );
    return 'over $_temp0';
  }

  @override
  String get previousIncomplete => 'previous period incomplete';

  @override
  String get coverageTitle => 'Statement coverage';

  @override
  String get coverageHint => 'A gap means a statement to import (or a month not yet closed).';

  @override
  String gapPartial(String label) {
    return '$label statement partial';
  }

  @override
  String get exportCategories => 'Export…';

  @override
  String get importCategories => 'Import…';

  @override
  String get exportTitle => 'Export my categories';

  @override
  String exportRules(int count) {
    return 'Description-text rules ($count)';
  }

  @override
  String exportMerchants(int count) {
    return 'Remembered merchants: your “Always use this category for …” choices ($count, businesses only)';
  }

  @override
  String get exportPrivacy =>
      'The file only holds category names, rules and business names: no transactions, amounts, accounts or people.';

  @override
  String exportDone(String path) {
    return 'Exported to $path';
  }

  @override
  String importDoneCategories(int categories, int rules, int merchants, int moved) {
    return 'Added: $categories categories, $rules rules, $merchants merchants · $moved transactions recategorized';
  }

  @override
  String get importBadFile => 'This file is not a categories export.';

  @override
  String exportCategoriesCount(int count) {
    return 'Your categories and groups ($count)';
  }

  @override
  String get supportedTitle => 'Banks the app can read';

  @override
  String get addBankLink => 'My bank or card isn\'t listed';

  @override
  String get addBankTitle => 'Add a bank';

  @override
  String get addBankIntro =>
      'To read a new bank, someone writes a small reader for it. They need to see how your statements are laid out, not what is in them. This page makes a masked copy: letters become X, digits 9. Nothing leaves your computer: you choose where the copy is saved and who you send it to.';

  @override
  String get addBankStep1 =>
      '1. Choose a few statements of that bank: 3 to 6 months, of every type you have (account, card…).';

  @override
  String get addBankDrop => 'Drop the statements here';

  @override
  String addBankReading(int count) {
    return 'Reading $count files…';
  }

  @override
  String addBankFiles(int count) {
    return '$count statements read';
  }

  @override
  String get addBankStep2 =>
      '2. Words that may stay readable. All are hidden to begin with. Tick the statement\'s own words: column titles, sections, transaction codes, months. Never tick a personal word: your name, your family, street, city, employer, people you pay, shops you\'d rather keep private.';

  @override
  String addBankKept(int kept, int total) {
    return '$kept of $total words readable';
  }

  @override
  String get addBankKeepAll => 'Keep all';

  @override
  String get addBankHideAll => 'Hide all';

  @override
  String get addBankSearch => 'Find a word';

  @override
  String addBankInFiles(int count) {
    return 'In $count statements';
  }

  @override
  String get addBankNoWords => 'No word appears in more than one statement: everything will be masked.';

  @override
  String get addBankStep3 => '3. What will be shared (first page of the first statement)';

  @override
  String get addBankNotesLabel => 'Notes for whoever writes the reader (optional, saved as notes.txt)';

  @override
  String get addBankNotesHint =>
      'Which account or card is each file? What do the account codes mean (e.g. EOP = checking)? What dates did you download? Does the export show pending card transactions?';

  @override
  String get addBankStep4 => '4. Save the masked copy, look at it, then send the folder to whoever adds your bank.';

  @override
  String get addBankSave => 'Save to a folder…';

  @override
  String addBankSaved(String folder, int count) {
    return 'Saved in $folder: $count files';
  }

  @override
  String get addBankReadme =>
      'Masked copy of bank statements, made by the expense tracker (Import > My bank or card isn\'t listed).\nLetters are replaced by X, digits by 9; only the words listed in reveal.txt stay readable. File names are numbered so they don\'t show the original names.\n\nstatement-N.shape.txt: the layout of each statement, line by line, with each word\'s position.\nstatement-N.shape.json: the same for PDF files, as data a program can read.\nreveal.txt: the words the statements\' owner approved.\nnotes.txt: what the owner wrote about the files, if anything.\n\nFor whoever writes the reader: docs/10-adding-a-bank.md in the expense tracker\'s repository.';

  @override
  String get backupTitle => 'Backups';

  @override
  String backupHint(int count) {
    return 'A copy is made automatically before each import, before an app update changes the database and before a restore; the last $count are kept. Save a copy elsewhere (USB key, another disk) from time to time.';
  }

  @override
  String get backupNone => 'No automatic copy yet.';

  @override
  String get backupSave => 'Save a copy…';

  @override
  String backupSaved(String path) {
    return 'Copy saved: $path';
  }

  @override
  String backupFailed(String message) {
    return 'Could not make a backup copy, nothing was changed: $message';
  }

  @override
  String get backupOpenFolder => 'Copies folder';

  @override
  String get backupRestoreFile => 'Restore a file…';

  @override
  String get backupRestore => 'Restore';

  @override
  String backupRestoreConfirm(String date) {
    return 'Go back to the data of $date? The app restarts. Your current data is copied first, so this can be undone.';
  }

  @override
  String get backupRestoreAction => 'Restore and restart';

  @override
  String get backupReasonImport => 'before an import';

  @override
  String get backupReasonUpdate => 'before an app update';

  @override
  String get backupReasonRestore => 'before a restore';

  @override
  String get backupReasonCategories => 'before a categories import';

  @override
  String get restoreNotDatabase => 'This file is not a database.';

  @override
  String get restoreNewer => 'This copy comes from a newer version of the app: update the app first.';

  @override
  String get restoreNotExpenses => 'This database doesn\'t come from this app.';

  @override
  String get savingsRate => 'Savings rate';

  @override
  String savingsRateIs(String rate) {
    return 'Savings rate: $rate';
  }

  @override
  String savingsRateOver(String rate, int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months complete months',
      one: '1 complete month',
    );
    return 'Savings rate $rate · $_temp0';
  }

  @override
  String get globalSearchTooltip => 'Search all transactions (Ctrl+K)';

  @override
  String get globalSearchHint => 'Merchant, amount (42,50), date (2026-10 or 12/10), note…';

  @override
  String get globalSearchNone => 'No transaction found.';

  @override
  String globalSearchMore(int count) {
    return 'First $count shown: add a word to narrow.';
  }

  @override
  String get passwordShow => 'Show the password';

  @override
  String get passwordHide => 'Hide the password';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordNew => 'New password';

  @override
  String get passwordConfirm => 'Type it again';

  @override
  String get passwordCurrent => 'Current password';

  @override
  String get passwordMismatch => 'The two entries differ.';

  @override
  String passwordRule(int min) {
    return 'At least $min characters. A sentence of a few words is the easiest to remember.';
  }

  @override
  String passwordTooShort(int count, int min, int missing) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count characters', one: '1 character');
    return 'Too short: $_temp0, at least $min needed ($missing more).';
  }

  @override
  String passwordLengthOk(int count) {
    return '$count characters: long enough';
  }

  @override
  String get unlockTitle => 'Unlock your data';

  @override
  String get unlockAction => 'Unlock';

  @override
  String get unlockWrong => 'Wrong password.';

  @override
  String get unlockOpening => 'Opening…';

  @override
  String get unlockSetupTitle => 'Choose a password';

  @override
  String get unlockSetupWhy =>
      'Your data is encrypted on this computer: without this password, no program and no one with a copy of the file can read it. Use a sentence of a few words: more than 16 characters.';

  @override
  String get unlockSetupForget =>
      'The password is never saved. If you forget it, your data cannot be recovered: statements can be imported again, but your categories and choices are lost. Keep it in a password manager or on paper.';

  @override
  String get unlockSetupExisting =>
      'Your existing data and the app\'s automatic copies are encrypted now. Copies you saved yourself elsewhere stay readable: delete them, or restore one once to make an encrypted copy.';

  @override
  String get unlockSetupAction => 'Encrypt and open';

  @override
  String get unlockEncrypting => 'Encrypting… (a few seconds)';

  @override
  String get passwordChange => 'Change password';

  @override
  String get passwordChangeHint => 'Copies made before keep the old password: restoring one will ask for it.';

  @override
  String get passwordChanged => 'Password changed.';

  @override
  String get restorePasswordTitle => 'Password of this copy';

  @override
  String get restorePasswordHint =>
      'This copy doesn\'t open with your current password. Type the password it was made with: it will be restored with your current one.';

  @override
  String get restoreWrongPassword => 'This file doesn\'t open with that password, or it is not a copy of this app.';

  @override
  String get devCopyButton => 'Anonymized copy for a developer';

  @override
  String get devCopyTitle => 'Anonymized copy for a developer';

  @override
  String get devCopyWhat =>
      'A copy of the whole database where every shop becomes MARCHAND 001, MARCHAND 002… (big chains like Costco or IGA too), people PERSONNE01…, cities VILLE01…, notes, cards, account names and numbers are hidden, and every amount is multiplied by a hidden factor. Categories, rules, targets and dates are kept, so a developer can work on data shaped like yours. Habits still show (when you travel, how your spending is split).';

  @override
  String get devCopyNotBackup => 'This is not a backup: it cannot be restored, and it never replaces your data.';

  @override
  String get devCopyExtra => 'Other words to hide (optional)';

  @override
  String get devCopyExtraHint =>
      'Your name, your street…: checked as well. Words not on a public list are already replaced.';

  @override
  String get devCopyAction => 'Choose a folder and create';

  @override
  String get devCopyWorking => 'Anonymizing and checking… (a few seconds)';

  @override
  String get devCopySamePassword => 'Choose another password than yours: you will give this one to the developer.';

  @override
  String get devCopyDone => 'Copy created and checked: nothing of your data was found in it.';

  @override
  String devCopySummary(int merchants, int people, int cities, int notes, int cells, int words) {
    return '$merchants shops replaced (big chains included), $people people, $cities cities, $notes notes hidden. $cells texts checked against $words words of your data.';
  }

  @override
  String get devCopyGive =>
      'Give the developer this folder and the password you chose. To open it: EXPENSES_DB_DIR=<folder> and the password.';

  @override
  String get devCopyLeak =>
      'Words of your data were still in the copy: nothing was written. Please report it (without these words):';

  @override
  String get restoreDevCopy => 'This is an anonymized developer copy: it can\'t replace your data.';

  @override
  String get databaseHome => 'Your data';

  @override
  String get databaseChange => 'Change file';

  @override
  String get databaseChooseTitle => 'Open a data file';

  @override
  String get databaseChooseHint =>
      'Each file has its own password: an anonymized copy, a copy someone shared with you… The file stays where it is: keep it on the computer\'s disk, not on a USB key.';

  @override
  String databaseMissing(String path) {
    return 'Not found: $path';
  }

  @override
  String get databaseForget => 'Remove from the list (the file is not deleted)';

  @override
  String get databaseMakeMain => 'Use as my data';

  @override
  String databaseMakeMainTitle(String name) {
    return 'Make “$name” your data?';
  }

  @override
  String get databaseMakeMainNew =>
      'It is copied into the app\'s folder and opens at every start, with its own password. The original file stays where it is.';

  @override
  String get databaseMakeMainReplace =>
      'It is copied into the app\'s folder and opens at every start, with its own password. Your current data is kept as a copy (Backups). The original file stays where it is.';

  @override
  String get databaseMakeMainAction => 'Use this file';

  @override
  String databaseMakeMainFailed(String error) {
    return 'The copy failed: $error';
  }

  @override
  String get databaseBrowse => 'Browse…';

  @override
  String get databaseNotFound => 'This file doesn\'t exist.';

  @override
  String get databasePlaintext =>
      'This file isn\'t encrypted: it\'s a copy from before the password. To get its data back, open your data, then Backups → Restore a file.';

  @override
  String get lockTooltip => 'Lock (or switch file)';

  @override
  String get lockConfirmTitle => 'Lock?';

  @override
  String get lockConfirm => 'The file closes. You\'ll need its password to open it again.';

  @override
  String get lockAction => 'Lock';

  @override
  String backupDatabaseFile(String path) {
    return 'Open file: $path';
  }

  @override
  String get backupShowFile => 'Show the file in Explorer';

  @override
  String get shareKept => 'Share excl.';

  @override
  String excludeFromShare(String name) {
    return 'Leave $name out of shares (rent, taxes…)';
  }

  @override
  String includeInShare(String name) {
    return 'Put $name back in shares';
  }

  @override
  String sharesWithout(String names, String amount) {
    return 'Shares without: $names · $amount / month';
  }

  @override
  String get includeAllInShare => 'Put all back';
}
