import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('fr')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get appTitle;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get navTransactions;

  /// No description provided for @navReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get navReview;

  /// No description provided for @navImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get navImport;

  /// No description provided for @navAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get navAccounts;

  /// No description provided for @navCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories & rules'**
  String get navCategories;

  /// No description provided for @scopeCash.
  ///
  /// In en, this message translates to:
  /// **'Cash {currency}'**
  String scopeCash(String currency);

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data yet. Import a statement to start.'**
  String get noData;

  /// No description provided for @spentIn.
  ///
  /// In en, this message translates to:
  /// **'Spent in {month}'**
  String spentIn(String month);

  /// No description provided for @incomeIn.
  ///
  /// In en, this message translates to:
  /// **'Income in {month}'**
  String incomeIn(String month);

  /// No description provided for @average6.
  ///
  /// In en, this message translates to:
  /// **'6-month average'**
  String get average6;

  /// No description provided for @vsAverage.
  ///
  /// In en, this message translates to:
  /// **'{percent} vs 6-month average'**
  String vsAverage(String percent);

  /// No description provided for @monthlyByGroup.
  ///
  /// In en, this message translates to:
  /// **'Monthly spending by group'**
  String get monthlyByGroup;

  /// No description provided for @byCategory.
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get byCategory;

  /// No description provided for @topMerchants.
  ///
  /// In en, this message translates to:
  /// **'Top merchants'**
  String get topMerchants;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @uncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get uncategorized;

  /// No description provided for @transfersExcluded.
  ///
  /// In en, this message translates to:
  /// **'Transfers between your own accounts and card payments are not counted as spending.'**
  String get transfersExcluded;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get allCategories;

  /// No description provided for @allAccounts.
  ///
  /// In en, this message translates to:
  /// **'All accounts'**
  String get allAccounts;

  /// No description provided for @allDates.
  ///
  /// In en, this message translates to:
  /// **'All dates'**
  String get allDates;

  /// No description provided for @colDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get colDate;

  /// No description provided for @colAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get colAccount;

  /// No description provided for @colMerchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get colMerchant;

  /// No description provided for @colCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get colCategory;

  /// No description provided for @colAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get colAmount;

  /// No description provided for @transactionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No transactions} =1{1 transaction} other{{count} transactions}}'**
  String transactionCount(int count);

  /// No description provided for @categorySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search (e.g. gas, rent, Costco) — Enter to pick'**
  String get categorySearchHint;

  /// No description provided for @frequentCategories.
  ///
  /// In en, this message translates to:
  /// **'Frequent'**
  String get frequentCategories;

  /// No description provided for @sortDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get sortDate;

  /// No description provided for @sortAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get sortAmount;

  /// No description provided for @sortMerchant.
  ///
  /// In en, this message translates to:
  /// **'By merchant'**
  String get sortMerchant;

  /// No description provided for @selectUnder.
  ///
  /// In en, this message translates to:
  /// **'Select under {amount}'**
  String selectUnder(String amount);

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 selected} other{{count} selected}}'**
  String selectedCount(int count);

  /// No description provided for @clearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get clearSelection;

  /// No description provided for @bulkSetQuestion.
  ///
  /// In en, this message translates to:
  /// **'Set “{category}” on {count, plural, =1{1 line} other{{count} lines}}?'**
  String bulkSetQuestion(String category, int count);

  /// No description provided for @bulkConfirmQuestion.
  ///
  /// In en, this message translates to:
  /// **'Accept the suggested category for {count, plural, =1{1 line} other{{count} lines}}?'**
  String bulkConfirmQuestion(int count);

  /// No description provided for @bulkConfirmSkipped.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 line without a precise category stays} other{{count} lines without a precise category stay}} in review.'**
  String bulkConfirmSkipped(int count);

  /// No description provided for @reasonRule.
  ///
  /// In en, this message translates to:
  /// **'Rule'**
  String get reasonRule;

  /// No description provided for @reasonMerchant.
  ///
  /// In en, this message translates to:
  /// **'Chosen before for this merchant'**
  String get reasonMerchant;

  /// No description provided for @reasonBank.
  ///
  /// In en, this message translates to:
  /// **'Bank hint → {category}'**
  String reasonBank(String category);

  /// No description provided for @reasonSeed.
  ///
  /// In en, this message translates to:
  /// **'Known merchant'**
  String get reasonSeed;

  /// No description provided for @reasonKeyword.
  ///
  /// In en, this message translates to:
  /// **'Keyword “{word}”'**
  String reasonKeyword(String word);

  /// No description provided for @reasonHint.
  ///
  /// In en, this message translates to:
  /// **'Bonidollars {rate} % → {category}'**
  String reasonHint(String rate, String category);

  /// No description provided for @reasonLearned.
  ///
  /// In en, this message translates to:
  /// **'Like {count, plural, =1{1 line} other{{count} lines}} with “{word}”'**
  String reasonLearned(int count, String word);

  /// No description provided for @reasonNone.
  ///
  /// In en, this message translates to:
  /// **'No clue: pick one'**
  String get reasonNone;

  /// No description provided for @anomalyHigh.
  ///
  /// In en, this message translates to:
  /// **'Very large expense: {merchant}'**
  String anomalyHigh(String merchant);

  /// No description provided for @anomalyHighBody.
  ///
  /// In en, this message translates to:
  /// **'{amount} on {date}'**
  String anomalyHighBody(String amount, String date);

  /// No description provided for @anomalyRegular.
  ///
  /// In en, this message translates to:
  /// **'Regular payment changed: {merchant}'**
  String anomalyRegular(String merchant);

  /// No description provided for @anomalyRegularBody.
  ///
  /// In en, this message translates to:
  /// **'{amount} on {date} — usually {usual}'**
  String anomalyRegularBody(String amount, String date, String usual);

  /// No description provided for @anomalyMissing.
  ///
  /// In en, this message translates to:
  /// **'Regular payment missing: {merchant}'**
  String anomalyMissing(String merchant);

  /// No description provided for @anomalyMissingBody.
  ///
  /// In en, this message translates to:
  /// **'{usual} expected around {date}, not found'**
  String anomalyMissingBody(String usual, String date);

  /// No description provided for @markNormal.
  ///
  /// In en, this message translates to:
  /// **'This payment is normal'**
  String get markNormal;

  /// No description provided for @markedNormal.
  ///
  /// In en, this message translates to:
  /// **'{date} · {amount} — marked normal'**
  String markedNormal(String date, String amount);

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @expectedOn.
  ///
  /// In en, this message translates to:
  /// **'expected {date}'**
  String expectedOn(String date);

  /// No description provided for @whyRegularAmount.
  ///
  /// In en, this message translates to:
  /// **'On {date}, {amount}: {diff} ({pct}) compared with the usual {usual} (median of the {count} payments before; ±{spread} % is normal).'**
  String whyRegularAmount(String date, String amount, String diff, String pct, String usual, int count, int spread);

  /// No description provided for @whyRegularMissing.
  ///
  /// In en, this message translates to:
  /// **'{usual} expected around {date} (± {days} days): no payment found, though the account has lines until {until}. A statement missing, or the payment stopped?'**
  String whyRegularMissing(String usual, String date, int days, String until);

  /// No description provided for @whyHigh.
  ///
  /// In en, this message translates to:
  /// **'On {date}, {amount}: among your top {share} % expenses of the year (from {threshold}).'**
  String whyHigh(String date, String amount, int share, String threshold);

  /// No description provided for @whyNewFee.
  ///
  /// In en, this message translates to:
  /// **'On {date}, {amount}: the first fee of this kind.'**
  String whyNewFee(String date, String amount);

  /// No description provided for @pastUnusual.
  ///
  /// In en, this message translates to:
  /// **'Past unusual payment (no alert)'**
  String get pastUnusual;

  /// No description provided for @anomalyNewFee.
  ///
  /// In en, this message translates to:
  /// **'New fee: {merchant}'**
  String anomalyNewFee(String merchant);

  /// No description provided for @anomalyNewFeeBody.
  ///
  /// In en, this message translates to:
  /// **'{amount} on {date}'**
  String anomalyNewFeeBody(String amount, String date);

  /// No description provided for @copyForSearch.
  ///
  /// In en, this message translates to:
  /// **'Copy name and location (to search online)'**
  String get copyForSearch;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied: {text}'**
  String copied(String text);

  /// No description provided for @reviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to review.'**
  String get reviewEmpty;

  /// No description provided for @reviewHint.
  ///
  /// In en, this message translates to:
  /// **'Check the suggested category, or pick another. Your choice can be remembered for the merchant.'**
  String get reviewHint;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @chooseCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get chooseCategory;

  /// No description provided for @rememberMerchant.
  ///
  /// In en, this message translates to:
  /// **'Always use this category for {merchant}'**
  String rememberMerchant(String merchant);

  /// No description provided for @updatedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 transaction updated} other{{count} transactions updated}}'**
  String updatedCount(int count);

  /// No description provided for @importTitle.
  ///
  /// In en, this message translates to:
  /// **'Import statements'**
  String get importTitle;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'Nothing to report'**
  String get noNotifications;

  /// No description provided for @goImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get goImport;

  /// No description provided for @statementDue.
  ///
  /// In en, this message translates to:
  /// **'{statement}: new statement to download'**
  String statementDue(String statement);

  /// No description provided for @statementDueBody.
  ///
  /// In en, this message translates to:
  /// **'Last imported: up to {last}. The next one (to {next}) should be available.'**
  String statementDueBody(String last, String next);

  /// No description provided for @statementsDue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 statement to download} other{{count} statements to download}}'**
  String statementsDue(int count);

  /// No description provided for @exportTransactions.
  ///
  /// In en, this message translates to:
  /// **'Export…'**
  String get exportTransactions;

  /// No description provided for @exportHint.
  ///
  /// In en, this message translates to:
  /// **'Save these transactions (this month or all dates, with the filters) as Excel or CSV'**
  String get exportHint;

  /// No description provided for @exportFileName.
  ///
  /// In en, this message translates to:
  /// **'transactions'**
  String get exportFileName;

  /// No description provided for @exportedLines.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 line exported} other{{count} lines exported}}'**
  String exportedLines(int count);

  /// No description provided for @openFile.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openFile;

  /// No description provided for @splitPart.
  ///
  /// In en, this message translates to:
  /// **'part'**
  String get splitPart;

  /// No description provided for @hdrBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get hdrBank;

  /// No description provided for @hdrDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get hdrDescription;

  /// No description provided for @hdrGroup.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get hdrGroup;

  /// No description provided for @hdrType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get hdrType;

  /// No description provided for @hdrCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get hdrCurrency;

  /// No description provided for @hdrForeignAmount.
  ///
  /// In en, this message translates to:
  /// **'Original amount'**
  String get hdrForeignAmount;

  /// No description provided for @hdrForeignCurrency.
  ///
  /// In en, this message translates to:
  /// **'Original currency'**
  String get hdrForeignCurrency;

  /// No description provided for @hdrNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get hdrNote;

  /// No description provided for @importDrop.
  ///
  /// In en, this message translates to:
  /// **'Drop your bank statements here (PDF, CSV, OFX…)'**
  String get importDrop;

  /// No description provided for @importChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose files…'**
  String get importChoose;

  /// No description provided for @importReading.
  ///
  /// In en, this message translates to:
  /// **'Reading…'**
  String get importReading;

  /// No description provided for @importDone.
  ///
  /// In en, this message translates to:
  /// **'{count} new · {duplicates} already known · {review} to review · {transfers} transfers matched'**
  String importDone(int count, int duplicates, int review, int transfers);

  /// No description provided for @importUnmatched.
  ///
  /// In en, this message translates to:
  /// **'{count} new lines on days already imported from another file (PDF or CSV) were not found there: check them in Transactions'**
  String importUnmatched(int count);

  /// No description provided for @importNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Not verified: this file has no balance or total to check its lines against'**
  String get importNotVerified;

  /// No description provided for @guideTitle.
  ///
  /// In en, this message translates to:
  /// **'{bank}: download your transactions ({fileType})'**
  String guideTitle(String bank, String fileType);

  /// No description provided for @guideButton.
  ///
  /// In en, this message translates to:
  /// **'How to get your {fileType} files'**
  String guideButton(String fileType);

  /// No description provided for @importExportHint.
  ///
  /// In en, this message translates to:
  /// **'{bank} also exports your transactions as {fileType}: more reliable than reading PDFs.'**
  String importExportHint(String bank, String fileType);

  /// No description provided for @guideOpen.
  ///
  /// In en, this message translates to:
  /// **'How?'**
  String get guideOpen;

  /// No description provided for @importAlready.
  ///
  /// In en, this message translates to:
  /// **'Already imported'**
  String get importAlready;

  /// No description provided for @importInvalid.
  ///
  /// In en, this message translates to:
  /// **'Not imported: the statement\'s own totals don\'t match'**
  String get importInvalid;

  /// No description provided for @importUnknown.
  ///
  /// In en, this message translates to:
  /// **'Statement not recognized. Supported banks: {banks}'**
  String importUnknown(String banks);

  /// No description provided for @importError.
  ///
  /// In en, this message translates to:
  /// **'Could not read the file: {message}'**
  String importError(String message);

  /// No description provided for @importHistory.
  ///
  /// In en, this message translates to:
  /// **'Imported statements'**
  String get importHistory;

  /// No description provided for @importPrivacy.
  ///
  /// In en, this message translates to:
  /// **'PDFs are read and then discarded. Only their content fingerprint is kept to detect re-imports.'**
  String get importPrivacy;

  /// No description provided for @deleteStatementConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this statement and its {count} transactions?'**
  String deleteStatementConfirm(int count);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @balanceEndOf.
  ///
  /// In en, this message translates to:
  /// **'Balance at end of {month}'**
  String balanceEndOf(String month);

  /// No description provided for @balanceAsOf.
  ///
  /// In en, this message translates to:
  /// **'Balance on {date}'**
  String balanceAsOf(String date);

  /// No description provided for @addCashExpense.
  ///
  /// In en, this message translates to:
  /// **'Add cash expense'**
  String get addCashExpense;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @merchantOptional.
  ///
  /// In en, this message translates to:
  /// **'Merchant (optional)'**
  String get merchantOptional;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @rules.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get rules;

  /// No description provided for @addRule.
  ///
  /// In en, this message translates to:
  /// **'Add rule'**
  String get addRule;

  /// No description provided for @ruleContains.
  ///
  /// In en, this message translates to:
  /// **'Description contains'**
  String get ruleContains;

  /// No description provided for @ruleSummary.
  ///
  /// In en, this message translates to:
  /// **'“{text}” → {category}'**
  String ruleSummary(String text, String category);

  /// No description provided for @merchantRule.
  ///
  /// In en, this message translates to:
  /// **'{merchant} → {category}'**
  String merchantRule(String merchant, String category);

  /// No description provided for @noRules.
  ///
  /// In en, this message translates to:
  /// **'No rules yet. Choosing “always” when reviewing remembers a merchant; rules here match description text.'**
  String get noRules;

  /// No description provided for @rememberedMerchants.
  ///
  /// In en, this message translates to:
  /// **'Remembered merchants'**
  String get rememberedMerchants;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @statementText.
  ///
  /// In en, this message translates to:
  /// **'Statement text'**
  String get statementText;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @originalAmount.
  ///
  /// In en, this message translates to:
  /// **'Original amount'**
  String get originalAmount;

  /// No description provided for @kind.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get kind;

  /// No description provided for @card.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get card;

  /// No description provided for @kind_expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get kind_expense;

  /// No description provided for @kind_income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get kind_income;

  /// No description provided for @kind_refund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get kind_refund;

  /// No description provided for @kind_fee.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get kind_fee;

  /// No description provided for @kind_interest.
  ///
  /// In en, this message translates to:
  /// **'Interest'**
  String get kind_interest;

  /// No description provided for @kind_transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer between my accounts'**
  String get kind_transfer;

  /// No description provided for @kind_externalTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer to another bank'**
  String get kind_externalTransfer;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @notCounted.
  ///
  /// In en, this message translates to:
  /// **'Not counted in spending'**
  String get notCounted;

  /// No description provided for @navTargets.
  ///
  /// In en, this message translates to:
  /// **'Targets'**
  String get navTargets;

  /// No description provided for @addTarget.
  ///
  /// In en, this message translates to:
  /// **'Add target'**
  String get addTarget;

  /// No description provided for @editTarget.
  ///
  /// In en, this message translates to:
  /// **'Edit target'**
  String get editTarget;

  /// No description provided for @allSpending.
  ///
  /// In en, this message translates to:
  /// **'All spending'**
  String get allSpending;

  /// No description provided for @period_week.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get period_week;

  /// No description provided for @period_month.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get period_month;

  /// No description provided for @period_year.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get period_year;

  /// No description provided for @targetSpent.
  ///
  /// In en, this message translates to:
  /// **'{spent} of {target}'**
  String targetSpent(String spent, String target);

  /// No description provided for @targetProjected.
  ///
  /// In en, this message translates to:
  /// **'Projected: {amount}'**
  String targetProjected(String amount);

  /// No description provided for @status_onTrack.
  ///
  /// In en, this message translates to:
  /// **'On track'**
  String get status_onTrack;

  /// No description provided for @status_atRisk.
  ///
  /// In en, this message translates to:
  /// **'At risk'**
  String get status_atRisk;

  /// No description provided for @status_over.
  ///
  /// In en, this message translates to:
  /// **'Over target'**
  String get status_over;

  /// No description provided for @targetSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Suggestion: {amount} (average of the last 3 periods)'**
  String targetSuggestion(String amount);

  /// No description provided for @noTargets.
  ///
  /// In en, this message translates to:
  /// **'No targets yet. Set a limit per week, month or year for all spending, a group or a category.'**
  String get noTargets;

  /// No description provided for @targetsHint.
  ///
  /// In en, this message translates to:
  /// **'Targets are indicators only: nothing is blocked or moved.'**
  String get targetsHint;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @withinTarget.
  ///
  /// In en, this message translates to:
  /// **'Within target'**
  String get withinTarget;

  /// No description provided for @split.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get split;

  /// No description provided for @splitTitle.
  ///
  /// In en, this message translates to:
  /// **'Split across categories'**
  String get splitTitle;

  /// No description provided for @splitAddPart.
  ///
  /// In en, this message translates to:
  /// **'Add a part'**
  String get splitAddPart;

  /// No description provided for @splitRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining: {amount}'**
  String splitRemaining(String amount);

  /// No description provided for @splitRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove split'**
  String get splitRemove;

  /// No description provided for @splitLabel.
  ///
  /// In en, this message translates to:
  /// **'Split · {count}'**
  String splitLabel(int count);

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @importAlreadySameFile.
  ///
  /// In en, this message translates to:
  /// **'Already imported: same file as “{file}” (imported {date})'**
  String importAlreadySameFile(String file, String date);

  /// No description provided for @importAlreadySameStatement.
  ///
  /// In en, this message translates to:
  /// **'Already imported: same statement as “{file}” (imported {date}), from another file'**
  String importAlreadySameStatement(String file, String date);

  /// No description provided for @importAlreadySameLines.
  ///
  /// In en, this message translates to:
  /// **'Already imported: every line of this file is already known'**
  String get importAlreadySameLines;

  /// No description provided for @noDuplicates.
  ///
  /// In en, this message translates to:
  /// **'No statement imported twice'**
  String get noDuplicates;

  /// No description provided for @duplicatesFound.
  ///
  /// In en, this message translates to:
  /// **'{count} files are the same statement imported more than once. Delete the extra copies:'**
  String duplicatesFound(int count);

  /// No description provided for @importedOn.
  ///
  /// In en, this message translates to:
  /// **'imported {date}'**
  String importedOn(String date);

  /// No description provided for @emptyMonth.
  ///
  /// In en, this message translates to:
  /// **'No transactions in {month} yet: statements arrive after the month ends.'**
  String emptyMonth(String month);

  /// No description provided for @goToMonth.
  ///
  /// In en, this message translates to:
  /// **'Go to {month}'**
  String goToMonth(String month);

  /// No description provided for @noSpendingThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No spending this month.'**
  String get noSpendingThisMonth;

  /// No description provided for @dataLocation.
  ///
  /// In en, this message translates to:
  /// **'Data is saved on this computer: {path}'**
  String dataLocation(String path);

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get addCategory;

  /// No description provided for @addGroup.
  ///
  /// In en, this message translates to:
  /// **'Add group'**
  String get addGroup;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get editCategory;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @nameFr.
  ///
  /// In en, this message translates to:
  /// **'Name (French)'**
  String get nameFr;

  /// No description provided for @nameEn.
  ///
  /// In en, this message translates to:
  /// **'Name (English, optional)'**
  String get nameEn;

  /// No description provided for @archiveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Archive “{name}”? It will no longer be offered; past reports keep their numbers.'**
  String archiveConfirm(String name);

  /// No description provided for @archiveMove.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 transaction uses it.} other{{count} transactions use it.}} Choose where to move them.'**
  String archiveMove(int count);

  /// No description provided for @categoriesHint.
  ///
  /// In en, this message translates to:
  /// **'Click a category to rename or archive it.'**
  String get categoriesHint;

  /// No description provided for @newCategory.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get newCategory;

  /// No description provided for @createNamed.
  ///
  /// In en, this message translates to:
  /// **'Create “{name}”'**
  String createNamed(String name);

  /// No description provided for @group.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get group;

  /// No description provided for @addToGroup.
  ///
  /// In en, this message translates to:
  /// **'Add a category to {group}'**
  String addToGroup(String group);

  /// No description provided for @navStats.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get navStats;

  /// No description provided for @range6.
  ///
  /// In en, this message translates to:
  /// **'6 months'**
  String get range6;

  /// No description provided for @range12.
  ///
  /// In en, this message translates to:
  /// **'12 months'**
  String get range12;

  /// No description provided for @rangeThisYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get rangeThisYear;

  /// No description provided for @rangeLastYear.
  ///
  /// In en, this message translates to:
  /// **'Last year'**
  String get rangeLastYear;

  /// No description provided for @rangeAll.
  ///
  /// In en, this message translates to:
  /// **'Everything'**
  String get rangeAll;

  /// No description provided for @tabTrends.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get tabTrends;

  /// No description provided for @tabCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get tabCategories;

  /// No description provided for @tabMerchants.
  ///
  /// In en, this message translates to:
  /// **'Merchants'**
  String get tabMerchants;

  /// No description provided for @tabCompare.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get tabCompare;

  /// No description provided for @tabRecurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get tabRecurring;

  /// No description provided for @tabBalances.
  ///
  /// In en, this message translates to:
  /// **'Balances'**
  String get tabBalances;

  /// No description provided for @chartBalances.
  ///
  /// In en, this message translates to:
  /// **'Month-end balance'**
  String get chartBalances;

  /// No description provided for @balancesHint.
  ///
  /// In en, this message translates to:
  /// **'Rebuilt from the latest statement balance and the transactions before it. Transfers between your accounts count as deposits and withdrawals.'**
  String get balancesHint;

  /// No description provided for @balancesNone.
  ///
  /// In en, this message translates to:
  /// **'No balance to follow here: pick a checking or savings account (or All accounts).'**
  String get balancesNone;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @balanceChange.
  ///
  /// In en, this message translates to:
  /// **'Change over the period'**
  String get balanceChange;

  /// No description provided for @colYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get colYear;

  /// No description provided for @colDeposits.
  ///
  /// In en, this message translates to:
  /// **'Deposits'**
  String get colDeposits;

  /// No description provided for @colWithdrawals.
  ///
  /// In en, this message translates to:
  /// **'Withdrawals'**
  String get colWithdrawals;

  /// No description provided for @colInterest.
  ///
  /// In en, this message translates to:
  /// **'Interest'**
  String get colInterest;

  /// No description provided for @colChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get colChange;

  /// No description provided for @colYearEnd.
  ///
  /// In en, this message translates to:
  /// **'Balance at end'**
  String get colYearEnd;

  /// No description provided for @interestOf.
  ///
  /// In en, this message translates to:
  /// **'incl. {amount} interest'**
  String interestOf(String amount);

  /// No description provided for @globalSince.
  ///
  /// In en, this message translates to:
  /// **'All accounts from {month} only: before that there is no {label} statement, so spending would look lower. Pick one account at the top to see its whole history.'**
  String globalSince(String month, String label);

  /// No description provided for @recurringPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Recurring per month'**
  String get recurringPerMonth;

  /// No description provided for @recurringCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 recurring payment} other{{count} recurring payments}}'**
  String recurringCount(int count);

  /// No description provided for @recurringHint.
  ///
  /// In en, this message translates to:
  /// **'Found automatically in all imported history: same merchant, regular interval, similar amount, even when the date varies (a bill paid by hand). Needs at least 3 payments.'**
  String get recurringHint;

  /// No description provided for @recurringNone.
  ///
  /// In en, this message translates to:
  /// **'No recurring payment found yet: import a few months of statements.'**
  String get recurringNone;

  /// No description provided for @recurringStopped.
  ///
  /// In en, this message translates to:
  /// **'Not seen lately (probably stopped)'**
  String get recurringStopped;

  /// No description provided for @cadenceWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get cadenceWeekly;

  /// No description provided for @cadenceBiweekly.
  ///
  /// In en, this message translates to:
  /// **'Every 2 weeks'**
  String get cadenceBiweekly;

  /// No description provided for @cadenceMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get cadenceMonthly;

  /// No description provided for @cadenceQuarterly.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get cadenceQuarterly;

  /// No description provided for @cadenceYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get cadenceYearly;

  /// No description provided for @onDay.
  ///
  /// In en, this message translates to:
  /// **'on day {day}'**
  String onDay(int day);

  /// No description provided for @dayBetween.
  ///
  /// In en, this message translates to:
  /// **'between day {from} and {to}'**
  String dayBetween(int from, int to);

  /// No description provided for @colFrequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get colFrequency;

  /// No description provided for @colPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Per month'**
  String get colPerMonth;

  /// No description provided for @colPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get colPayments;

  /// No description provided for @colNext.
  ///
  /// In en, this message translates to:
  /// **'Next expected'**
  String get colNext;

  /// No description provided for @statTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get statTotal;

  /// No description provided for @statAverage.
  ///
  /// In en, this message translates to:
  /// **'Monthly average'**
  String get statAverage;

  /// No description provided for @statVsPrevious.
  ///
  /// In en, this message translates to:
  /// **'vs previous period'**
  String get statVsPrevious;

  /// No description provided for @statMostExpensive.
  ///
  /// In en, this message translates to:
  /// **'Most expensive month'**
  String get statMostExpensive;

  /// No description provided for @statLeastExpensive.
  ///
  /// In en, this message translates to:
  /// **'Least expensive month'**
  String get statLeastExpensive;

  /// No description provided for @chartMonthlySpending.
  ///
  /// In en, this message translates to:
  /// **'Monthly spending'**
  String get chartMonthlySpending;

  /// No description provided for @chartIncomeSpending.
  ///
  /// In en, this message translates to:
  /// **'Income and spending'**
  String get chartIncomeSpending;

  /// No description provided for @legendSpending.
  ///
  /// In en, this message translates to:
  /// **'Spending'**
  String get legendSpending;

  /// No description provided for @legendIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get legendIncome;

  /// No description provided for @showEverything.
  ///
  /// In en, this message translates to:
  /// **'Show everything'**
  String get showEverything;

  /// No description provided for @chartSpendingByStore.
  ///
  /// In en, this message translates to:
  /// **'Spending by store'**
  String get chartSpendingByStore;

  /// No description provided for @byStore.
  ///
  /// In en, this message translates to:
  /// **'By store'**
  String get byStore;

  /// No description provided for @byCategoryTrend.
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get byCategoryTrend;

  /// No description provided for @purchasesPerMonth.
  ///
  /// In en, this message translates to:
  /// **'{count} purchases / month'**
  String purchasesPerMonth(String count);

  /// No description provided for @analyzeOnly.
  ///
  /// In en, this message translates to:
  /// **'Analyze {name} only'**
  String analyzeOnly(String name);

  /// No description provided for @byGroupTrend.
  ///
  /// In en, this message translates to:
  /// **'Trend by group'**
  String get byGroupTrend;

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **'per month'**
  String get perMonth;

  /// No description provided for @trend.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get trend;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @visits.
  ///
  /// In en, this message translates to:
  /// **'Purchases'**
  String get visits;

  /// No description provided for @averageTicket.
  ///
  /// In en, this message translates to:
  /// **'Average ticket'**
  String get averageTicket;

  /// No description provided for @lastVisit.
  ///
  /// In en, this message translates to:
  /// **'Last'**
  String get lastVisit;

  /// No description provided for @merchantsHint.
  ///
  /// In en, this message translates to:
  /// **'Businesses only: transfers to people count in their category.'**
  String get merchantsHint;

  /// No description provided for @cmpPreviousMonth.
  ///
  /// In en, this message translates to:
  /// **'vs previous month'**
  String get cmpPreviousMonth;

  /// No description provided for @cmpSameMonthLastYear.
  ///
  /// In en, this message translates to:
  /// **'vs same month last year'**
  String get cmpSameMonthLastYear;

  /// No description provided for @cmpYearToDate.
  ///
  /// In en, this message translates to:
  /// **'Year to date vs last year'**
  String get cmpYearToDate;

  /// No description provided for @yearToDate.
  ///
  /// In en, this message translates to:
  /// **'Jan – this month {year}'**
  String yearToDate(int year);

  /// No description provided for @difference.
  ///
  /// In en, this message translates to:
  /// **'Difference'**
  String get difference;

  /// No description provided for @lessSpent.
  ///
  /// In en, this message translates to:
  /// **'less'**
  String get lessSpent;

  /// No description provided for @moreSpent.
  ///
  /// In en, this message translates to:
  /// **'more'**
  String get moreSpent;

  /// No description provided for @unspecified.
  ///
  /// In en, this message translates to:
  /// **'unspecified'**
  String get unspecified;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @partOf.
  ///
  /// In en, this message translates to:
  /// **'part of {amount}'**
  String partOf(String amount);

  /// No description provided for @gapMissing.
  ///
  /// In en, this message translates to:
  /// **'{label} statement missing'**
  String gapMissing(String label);

  /// No description provided for @gapUntil.
  ///
  /// In en, this message translates to:
  /// **'{label} only until {date}'**
  String gapUntil(String label, String date);

  /// No description provided for @incompleteMonths.
  ///
  /// In en, this message translates to:
  /// **'Incomplete months — counted in totals, left out of averages and comparisons:'**
  String get incompleteMonths;

  /// No description provided for @incomplete.
  ///
  /// In en, this message translates to:
  /// **'incomplete'**
  String get incomplete;

  /// No description provided for @overCompleteMonths.
  ///
  /// In en, this message translates to:
  /// **'over {count, plural, =1{1 complete month} other{{count} complete months}}'**
  String overCompleteMonths(int count);

  /// No description provided for @previousIncomplete.
  ///
  /// In en, this message translates to:
  /// **'previous period incomplete'**
  String get previousIncomplete;

  /// No description provided for @coverageTitle.
  ///
  /// In en, this message translates to:
  /// **'Statement coverage'**
  String get coverageTitle;

  /// No description provided for @coverageHint.
  ///
  /// In en, this message translates to:
  /// **'A gap means a statement to import (or a month not yet closed).'**
  String get coverageHint;

  /// No description provided for @gapPartial.
  ///
  /// In en, this message translates to:
  /// **'{label} statement partial'**
  String gapPartial(String label);

  /// No description provided for @exportCategories.
  ///
  /// In en, this message translates to:
  /// **'Export…'**
  String get exportCategories;

  /// No description provided for @importCategories.
  ///
  /// In en, this message translates to:
  /// **'Import…'**
  String get importCategories;

  /// No description provided for @exportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export my categories'**
  String get exportTitle;

  /// No description provided for @exportRules.
  ///
  /// In en, this message translates to:
  /// **'Description-text rules ({count})'**
  String exportRules(int count);

  /// No description provided for @exportMerchants.
  ///
  /// In en, this message translates to:
  /// **'Remembered merchants: your “Always use this category for …” choices ({count}, businesses only)'**
  String exportMerchants(int count);

  /// No description provided for @exportPrivacy.
  ///
  /// In en, this message translates to:
  /// **'The file only holds category names, rules and business names: no transactions, amounts, accounts or people.'**
  String get exportPrivacy;

  /// No description provided for @exportDone.
  ///
  /// In en, this message translates to:
  /// **'Exported to {path}'**
  String exportDone(String path);

  /// No description provided for @importDoneCategories.
  ///
  /// In en, this message translates to:
  /// **'Added: {categories} categories, {rules} rules, {merchants} merchants · {moved} transactions recategorized'**
  String importDoneCategories(int categories, int rules, int merchants, int moved);

  /// No description provided for @importBadFile.
  ///
  /// In en, this message translates to:
  /// **'This file is not a categories export.'**
  String get importBadFile;

  /// No description provided for @exportCategoriesCount.
  ///
  /// In en, this message translates to:
  /// **'Your categories and groups ({count})'**
  String exportCategoriesCount(int count);

  /// No description provided for @supportedTitle.
  ///
  /// In en, this message translates to:
  /// **'Banks the app can read'**
  String get supportedTitle;

  /// No description provided for @addBankLink.
  ///
  /// In en, this message translates to:
  /// **'My bank or card isn\'t listed'**
  String get addBankLink;

  /// No description provided for @addBankTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a bank'**
  String get addBankTitle;

  /// No description provided for @addBankIntro.
  ///
  /// In en, this message translates to:
  /// **'To read a new bank, someone writes a small reader for it. They need to see how your statements are laid out, not what is in them. This page makes a masked copy: letters become X, digits 9. Nothing leaves your computer: you choose where the copy is saved and who you send it to.'**
  String get addBankIntro;

  /// No description provided for @addBankStep1.
  ///
  /// In en, this message translates to:
  /// **'1. Choose a few statements of that bank: 3 to 6 months, of every type you have (account, card…).'**
  String get addBankStep1;

  /// No description provided for @addBankDrop.
  ///
  /// In en, this message translates to:
  /// **'Drop the statements here'**
  String get addBankDrop;

  /// No description provided for @addBankReading.
  ///
  /// In en, this message translates to:
  /// **'Reading {count} files…'**
  String addBankReading(int count);

  /// No description provided for @addBankFiles.
  ///
  /// In en, this message translates to:
  /// **'{count} statements read'**
  String addBankFiles(int count);

  /// No description provided for @addBankStep2.
  ///
  /// In en, this message translates to:
  /// **'2. Words that may stay readable. All are hidden to begin with. Tick the statement\'s own words: column titles, sections, transaction codes, months. Never tick a personal word: your name, your family, street, city, employer, people you pay, shops you\'d rather keep private.'**
  String get addBankStep2;

  /// No description provided for @addBankKept.
  ///
  /// In en, this message translates to:
  /// **'{kept} of {total} words readable'**
  String addBankKept(int kept, int total);

  /// No description provided for @addBankKeepAll.
  ///
  /// In en, this message translates to:
  /// **'Keep all'**
  String get addBankKeepAll;

  /// No description provided for @addBankHideAll.
  ///
  /// In en, this message translates to:
  /// **'Hide all'**
  String get addBankHideAll;

  /// No description provided for @addBankSearch.
  ///
  /// In en, this message translates to:
  /// **'Find a word'**
  String get addBankSearch;

  /// No description provided for @addBankInFiles.
  ///
  /// In en, this message translates to:
  /// **'In {count} statements'**
  String addBankInFiles(int count);

  /// No description provided for @addBankNoWords.
  ///
  /// In en, this message translates to:
  /// **'No word appears in more than one statement: everything will be masked.'**
  String get addBankNoWords;

  /// No description provided for @addBankStep3.
  ///
  /// In en, this message translates to:
  /// **'3. What will be shared (first page of the first statement)'**
  String get addBankStep3;

  /// No description provided for @addBankNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes for whoever writes the reader (optional, saved as notes.txt)'**
  String get addBankNotesLabel;

  /// No description provided for @addBankNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Which account or card is each file? What do the account codes mean (e.g. EOP = checking)? What dates did you download? Does the export show pending card transactions?'**
  String get addBankNotesHint;

  /// No description provided for @addBankStep4.
  ///
  /// In en, this message translates to:
  /// **'4. Save the masked copy, look at it, then send the folder to whoever adds your bank.'**
  String get addBankStep4;

  /// No description provided for @addBankSave.
  ///
  /// In en, this message translates to:
  /// **'Save to a folder…'**
  String get addBankSave;

  /// No description provided for @addBankSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved in {folder}: {count} files'**
  String addBankSaved(String folder, int count);

  /// No description provided for @addBankReadme.
  ///
  /// In en, this message translates to:
  /// **'Masked copy of bank statements, made by the expense tracker (Import > My bank or card isn\'t listed).\nLetters are replaced by X, digits by 9; only the words listed in reveal.txt stay readable. File names are numbered so they don\'t show the original names.\n\nstatement-N.shape.txt: the layout of each statement, line by line, with each word\'s position.\nstatement-N.shape.json: the same for PDF files, as data a program can read.\nreveal.txt: the words the statements\' owner approved.\nnotes.txt: what the owner wrote about the files, if anything.\n\nFor whoever writes the reader: docs/10-adding-a-bank.md in the expense tracker\'s repository.'**
  String get addBankReadme;

  /// No description provided for @backupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backups'**
  String get backupTitle;

  /// No description provided for @backupHint.
  ///
  /// In en, this message translates to:
  /// **'A copy is made automatically before each import, before an app update changes the database and before a restore; the last {count} are kept. Save a copy elsewhere (USB key, another disk) from time to time.'**
  String backupHint(int count);

  /// No description provided for @backupNone.
  ///
  /// In en, this message translates to:
  /// **'No automatic copy yet.'**
  String get backupNone;

  /// No description provided for @backupSave.
  ///
  /// In en, this message translates to:
  /// **'Save a copy…'**
  String get backupSave;

  /// No description provided for @backupSaved.
  ///
  /// In en, this message translates to:
  /// **'Copy saved: {path}'**
  String backupSaved(String path);

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not make a backup copy, nothing was changed: {message}'**
  String backupFailed(String message);

  /// No description provided for @backupOpenFolder.
  ///
  /// In en, this message translates to:
  /// **'Copies folder'**
  String get backupOpenFolder;

  /// No description provided for @backupRestoreFile.
  ///
  /// In en, this message translates to:
  /// **'Restore a file…'**
  String get backupRestoreFile;

  /// No description provided for @backupRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get backupRestore;

  /// No description provided for @backupRestoreConfirm.
  ///
  /// In en, this message translates to:
  /// **'Go back to the data of {date}? The app restarts. Your current data is copied first, so this can be undone.'**
  String backupRestoreConfirm(String date);

  /// No description provided for @backupRestoreAction.
  ///
  /// In en, this message translates to:
  /// **'Restore and restart'**
  String get backupRestoreAction;

  /// No description provided for @backupReasonImport.
  ///
  /// In en, this message translates to:
  /// **'before an import'**
  String get backupReasonImport;

  /// No description provided for @backupReasonUpdate.
  ///
  /// In en, this message translates to:
  /// **'before an app update'**
  String get backupReasonUpdate;

  /// No description provided for @backupReasonRestore.
  ///
  /// In en, this message translates to:
  /// **'before a restore'**
  String get backupReasonRestore;

  /// No description provided for @backupReasonCategories.
  ///
  /// In en, this message translates to:
  /// **'before a categories import'**
  String get backupReasonCategories;

  /// No description provided for @restoreNotDatabase.
  ///
  /// In en, this message translates to:
  /// **'This file is not a database.'**
  String get restoreNotDatabase;

  /// No description provided for @restoreNewer.
  ///
  /// In en, this message translates to:
  /// **'This copy comes from a newer version of the app: update the app first.'**
  String get restoreNewer;

  /// No description provided for @restoreNotExpenses.
  ///
  /// In en, this message translates to:
  /// **'This database doesn\'t come from this app.'**
  String get restoreNotExpenses;

  /// No description provided for @savingsRate.
  ///
  /// In en, this message translates to:
  /// **'Savings rate'**
  String get savingsRate;

  /// No description provided for @savingsRateIs.
  ///
  /// In en, this message translates to:
  /// **'Savings rate: {rate}'**
  String savingsRateIs(String rate);

  /// No description provided for @savingsRateOver.
  ///
  /// In en, this message translates to:
  /// **'Savings rate {rate} · {months, plural, =1{1 complete month} other{{months} complete months}}'**
  String savingsRateOver(String rate, int months);

  /// No description provided for @globalSearchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search all transactions (Ctrl+K)'**
  String get globalSearchTooltip;

  /// No description provided for @globalSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Merchant, amount (42,50), date (2026-10 or 12/10), note…'**
  String get globalSearchHint;

  /// No description provided for @globalSearchNone.
  ///
  /// In en, this message translates to:
  /// **'No transaction found.'**
  String get globalSearchNone;

  /// No description provided for @globalSearchMore.
  ///
  /// In en, this message translates to:
  /// **'First {count} shown: add a word to narrow.'**
  String globalSearchMore(int count);

  /// No description provided for @passwordShow.
  ///
  /// In en, this message translates to:
  /// **'Show the password'**
  String get passwordShow;

  /// No description provided for @passwordHide.
  ///
  /// In en, this message translates to:
  /// **'Hide the password'**
  String get passwordHide;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordNew.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get passwordNew;

  /// No description provided for @passwordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type it again'**
  String get passwordConfirm;

  /// No description provided for @passwordCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get passwordCurrent;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'The two entries differ.'**
  String get passwordMismatch;

  /// No description provided for @passwordRule.
  ///
  /// In en, this message translates to:
  /// **'At least {min} characters. A sentence of a few words is the easiest to remember.'**
  String passwordRule(int min);

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Too short: {count, plural, =1{1 character} other{{count} characters}}, at least {min} needed ({missing} more).'**
  String passwordTooShort(int count, int min, int missing);

  /// No description provided for @passwordLengthOk.
  ///
  /// In en, this message translates to:
  /// **'{count} characters: long enough'**
  String passwordLengthOk(int count);

  /// No description provided for @unlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock your data'**
  String get unlockTitle;

  /// No description provided for @unlockAction.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlockAction;

  /// No description provided for @unlockWrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong password.'**
  String get unlockWrong;

  /// No description provided for @unlockOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening…'**
  String get unlockOpening;

  /// No description provided for @unlockSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a password'**
  String get unlockSetupTitle;

  /// No description provided for @unlockSetupWhy.
  ///
  /// In en, this message translates to:
  /// **'Your data is encrypted on this computer: without this password, no program and no one with a copy of the file can read it. Use a sentence of a few words: more than 16 characters.'**
  String get unlockSetupWhy;

  /// No description provided for @unlockSetupForget.
  ///
  /// In en, this message translates to:
  /// **'The password is never saved. If you forget it, your data cannot be recovered: statements can be imported again, but your categories and choices are lost. Keep it in a password manager or on paper.'**
  String get unlockSetupForget;

  /// No description provided for @unlockSetupExisting.
  ///
  /// In en, this message translates to:
  /// **'Your existing data and the app\'s automatic copies are encrypted now. Copies you saved yourself elsewhere stay readable: delete them, or restore one once to make an encrypted copy.'**
  String get unlockSetupExisting;

  /// No description provided for @unlockSetupAction.
  ///
  /// In en, this message translates to:
  /// **'Encrypt and open'**
  String get unlockSetupAction;

  /// No description provided for @unlockEncrypting.
  ///
  /// In en, this message translates to:
  /// **'Encrypting… (a few seconds)'**
  String get unlockEncrypting;

  /// No description provided for @passwordChange.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get passwordChange;

  /// No description provided for @passwordChangeHint.
  ///
  /// In en, this message translates to:
  /// **'Copies made before keep the old password: restoring one will ask for it.'**
  String get passwordChangeHint;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed.'**
  String get passwordChanged;

  /// No description provided for @restorePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Password of this copy'**
  String get restorePasswordTitle;

  /// No description provided for @restorePasswordHint.
  ///
  /// In en, this message translates to:
  /// **'This copy doesn\'t open with your current password. Type the password it was made with: it will be restored with your current one.'**
  String get restorePasswordHint;

  /// No description provided for @restoreWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'This file doesn\'t open with that password, or it is not a copy of this app.'**
  String get restoreWrongPassword;

  /// No description provided for @devCopyButton.
  ///
  /// In en, this message translates to:
  /// **'Anonymized copy for a developer'**
  String get devCopyButton;

  /// No description provided for @devCopyTitle.
  ///
  /// In en, this message translates to:
  /// **'Anonymized copy for a developer'**
  String get devCopyTitle;

  /// No description provided for @devCopyWhat.
  ///
  /// In en, this message translates to:
  /// **'A copy of the whole database where every shop becomes MARCHAND 001, MARCHAND 002… (big chains like Costco or IGA too), people PERSONNE01…, cities VILLE01…, notes, cards, account names and numbers are hidden, and every amount is multiplied by a hidden factor. Categories, rules, targets and dates are kept, so a developer can work on data shaped like yours. Habits still show (when you travel, how your spending is split).'**
  String get devCopyWhat;

  /// No description provided for @devCopyNotBackup.
  ///
  /// In en, this message translates to:
  /// **'This is not a backup: it cannot be restored, and it never replaces your data.'**
  String get devCopyNotBackup;

  /// No description provided for @devCopyExtra.
  ///
  /// In en, this message translates to:
  /// **'Other words to hide (optional)'**
  String get devCopyExtra;

  /// No description provided for @devCopyExtraHint.
  ///
  /// In en, this message translates to:
  /// **'Your name, your street…: checked as well. Words not on a public list are already replaced.'**
  String get devCopyExtraHint;

  /// No description provided for @devCopyAction.
  ///
  /// In en, this message translates to:
  /// **'Choose a folder and create'**
  String get devCopyAction;

  /// No description provided for @devCopyWorking.
  ///
  /// In en, this message translates to:
  /// **'Anonymizing and checking… (a few seconds)'**
  String get devCopyWorking;

  /// No description provided for @devCopySamePassword.
  ///
  /// In en, this message translates to:
  /// **'Choose another password than yours: you will give this one to the developer.'**
  String get devCopySamePassword;

  /// No description provided for @devCopyDone.
  ///
  /// In en, this message translates to:
  /// **'Copy created and checked: nothing of your data was found in it.'**
  String get devCopyDone;

  /// No description provided for @devCopySummary.
  ///
  /// In en, this message translates to:
  /// **'{merchants} shops replaced (big chains included), {people} people, {cities} cities, {notes} notes hidden. {cells} texts checked against {words} words of your data.'**
  String devCopySummary(int merchants, int people, int cities, int notes, int cells, int words);

  /// No description provided for @devCopyGive.
  ///
  /// In en, this message translates to:
  /// **'Give the developer this folder and the password you chose. To open it: EXPENSES_DB_DIR=<folder> and the password.'**
  String get devCopyGive;

  /// No description provided for @devCopyLeak.
  ///
  /// In en, this message translates to:
  /// **'Words of your data were still in the copy: nothing was written. Please report it (without these words):'**
  String get devCopyLeak;

  /// No description provided for @restoreDevCopy.
  ///
  /// In en, this message translates to:
  /// **'This is an anonymized developer copy: it can\'t replace your data.'**
  String get restoreDevCopy;

  /// No description provided for @databaseHome.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get databaseHome;

  /// No description provided for @databaseChange.
  ///
  /// In en, this message translates to:
  /// **'Change file'**
  String get databaseChange;

  /// No description provided for @databaseChooseTitle.
  ///
  /// In en, this message translates to:
  /// **'Open a data file'**
  String get databaseChooseTitle;

  /// No description provided for @databaseChooseHint.
  ///
  /// In en, this message translates to:
  /// **'Each file has its own password: an anonymized copy, a copy someone shared with you… The file stays where it is: keep it on the computer\'s disk, not on a USB key.'**
  String get databaseChooseHint;

  /// No description provided for @databaseMissing.
  ///
  /// In en, this message translates to:
  /// **'Not found: {path}'**
  String databaseMissing(String path);

  /// No description provided for @databaseForget.
  ///
  /// In en, this message translates to:
  /// **'Remove from the list (the file is not deleted)'**
  String get databaseForget;

  /// No description provided for @databaseMakeMain.
  ///
  /// In en, this message translates to:
  /// **'Use as my data'**
  String get databaseMakeMain;

  /// No description provided for @databaseMakeMainTitle.
  ///
  /// In en, this message translates to:
  /// **'Make “{name}” your data?'**
  String databaseMakeMainTitle(String name);

  /// No description provided for @databaseMakeMainNew.
  ///
  /// In en, this message translates to:
  /// **'It is copied into the app\'s folder and opens at every start, with its own password. The original file stays where it is.'**
  String get databaseMakeMainNew;

  /// No description provided for @databaseMakeMainReplace.
  ///
  /// In en, this message translates to:
  /// **'It is copied into the app\'s folder and opens at every start, with its own password. Your current data is kept as a copy (Backups). The original file stays where it is.'**
  String get databaseMakeMainReplace;

  /// No description provided for @databaseMakeMainAction.
  ///
  /// In en, this message translates to:
  /// **'Use this file'**
  String get databaseMakeMainAction;

  /// No description provided for @databaseMakeMainFailed.
  ///
  /// In en, this message translates to:
  /// **'The copy failed: {error}'**
  String databaseMakeMainFailed(String error);

  /// No description provided for @databaseBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse…'**
  String get databaseBrowse;

  /// No description provided for @databaseNotFound.
  ///
  /// In en, this message translates to:
  /// **'This file doesn\'t exist.'**
  String get databaseNotFound;

  /// No description provided for @databasePlaintext.
  ///
  /// In en, this message translates to:
  /// **'This file isn\'t encrypted: it\'s a copy from before the password. To get its data back, open your data, then Backups → Restore a file.'**
  String get databasePlaintext;

  /// No description provided for @lockTooltip.
  ///
  /// In en, this message translates to:
  /// **'Lock (or switch file)'**
  String get lockTooltip;

  /// No description provided for @lockConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Lock?'**
  String get lockConfirmTitle;

  /// No description provided for @lockConfirm.
  ///
  /// In en, this message translates to:
  /// **'The file closes. You\'ll need its password to open it again.'**
  String get lockConfirm;

  /// No description provided for @lockAction.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get lockAction;

  /// No description provided for @backupDatabaseFile.
  ///
  /// In en, this message translates to:
  /// **'Open file: {path}'**
  String backupDatabaseFile(String path);

  /// No description provided for @backupShowFile.
  ///
  /// In en, this message translates to:
  /// **'Show the file in Explorer'**
  String get backupShowFile;

  /// No description provided for @shareKept.
  ///
  /// In en, this message translates to:
  /// **'Share excl.'**
  String get shareKept;

  /// No description provided for @excludeFromShare.
  ///
  /// In en, this message translates to:
  /// **'Leave {name} out of shares (rent, taxes…)'**
  String excludeFromShare(String name);

  /// No description provided for @includeInShare.
  ///
  /// In en, this message translates to:
  /// **'Put {name} back in shares'**
  String includeInShare(String name);

  /// No description provided for @sharesWithout.
  ///
  /// In en, this message translates to:
  /// **'Shares without: {names} · {amount} / month'**
  String sharesWithout(String names, String amount);

  /// No description provided for @includeAllInShare.
  ///
  /// In en, this message translates to:
  /// **'Put all back'**
  String get includeAllInShare;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
