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
  /// **'Dépenses'**
  String get appTitle;

  /// No description provided for @pairTitle.
  ///
  /// In en, this message translates to:
  /// **'Pair with the desktop'**
  String get pairTitle;

  /// No description provided for @pairIntro.
  ///
  /// In en, this message translates to:
  /// **'On the computer, click the phone icon in the top bar, then Pair a phone, and scan the QR code shown there.'**
  String get pairIntro;

  /// No description provided for @pairScan.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code'**
  String get pairScan;

  /// No description provided for @pairNotOurs.
  ///
  /// In en, this message translates to:
  /// **'This QR code is not from Dépenses'**
  String get pairNotOurs;

  /// No description provided for @scanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code'**
  String get scanTitle;

  /// No description provided for @scanHint.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the code on the desktop screen.'**
  String get scanHint;

  /// No description provided for @cameraDenied.
  ///
  /// In en, this message translates to:
  /// **'The camera is not available. Allow it in the phone settings.'**
  String get cameraDenied;

  /// No description provided for @downloadTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloading the database'**
  String get downloadTitle;

  /// No description provided for @downloadPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent} %'**
  String downloadPercent(Object percent);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @unpair.
  ///
  /// In en, this message translates to:
  /// **'Pair again'**
  String get unpair;

  /// No description provided for @unlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get unlockTitle;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Database password'**
  String get passwordLabel;

  /// No description provided for @unlockButton.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlockButton;

  /// No description provided for @unlockWrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong password'**
  String get unlockWrong;

  /// No description provided for @unlockOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening…'**
  String get unlockOpening;

  /// No description provided for @unlockFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Could not open the data.'**
  String get unlockFailedGeneric;

  /// No description provided for @errGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong, try again.'**
  String get errGeneric;

  /// No description provided for @switchPasswordBanner.
  ///
  /// In en, this message translates to:
  /// **'New data is locked with another password. Enter it to switch.'**
  String get switchPasswordBanner;

  /// No description provided for @switchAction.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get switchAction;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @dataFrom.
  ///
  /// In en, this message translates to:
  /// **'Data from {date}'**
  String dataFrom(DateTime date);

  /// No description provided for @newDataFrom.
  ///
  /// In en, this message translates to:
  /// **'New data from {date}'**
  String newDataFrom(DateTime date);

  /// No description provided for @downloadAction.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadAction;

  /// No description provided for @updating.
  ///
  /// In en, this message translates to:
  /// **'Updating…'**
  String get updating;

  /// No description provided for @errUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Desktop not reachable on this Wi-Fi. On the desktop: Send to phone.'**
  String get errUnreachable;

  /// No description provided for @errNotPaired.
  ///
  /// In en, this message translates to:
  /// **'Phone not paired with this database.'**
  String get errNotPaired;

  /// No description provided for @errIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Transfer incomplete, try again.'**
  String get errIncomplete;

  /// No description provided for @errUpdatePhone.
  ///
  /// In en, this message translates to:
  /// **'The desktop data is newer than this app. Update the phone app.'**
  String get errUpdatePhone;

  /// No description provided for @errUpdateDesktop.
  ///
  /// In en, this message translates to:
  /// **'The desktop data is older than this app. Update the desktop app.'**
  String get errUpdateDesktop;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get navTransactions;

  /// No description provided for @navStatistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get navStatistics;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @scopeCash.
  ///
  /// In en, this message translates to:
  /// **'Cash {currency}'**
  String scopeCash(String currency);

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data yet. Send the database from the desktop app.'**
  String get noData;

  /// No description provided for @spentIn.
  ///
  /// In en, this message translates to:
  /// **'Spent in {month}'**
  String spentIn(String month);

  /// No description provided for @lastMonthIs.
  ///
  /// In en, this message translates to:
  /// **'{month}: {amount}'**
  String lastMonthIs(String month, String amount);

  /// No description provided for @statementMissing.
  ///
  /// In en, this message translates to:
  /// **'Statement missing'**
  String get statementMissing;

  /// No description provided for @incomplete.
  ///
  /// In en, this message translates to:
  /// **'incomplete'**
  String get incomplete;

  /// No description provided for @vsLastMonth.
  ///
  /// In en, this message translates to:
  /// **'{percent} vs last month'**
  String vsLastMonth(String percent);

  /// No description provided for @coverageWarning.
  ///
  /// In en, this message translates to:
  /// **'Statements missing or incomplete for {accounts}'**
  String coverageWarning(String accounts);

  /// No description provided for @targetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Targets'**
  String get targetsTitle;

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

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent transactions'**
  String get recentTransactions;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions'**
  String get noTransactions;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @allAccounts.
  ///
  /// In en, this message translates to:
  /// **'All accounts'**
  String get allAccounts;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get allCategories;

  /// No description provided for @allDates.
  ///
  /// In en, this message translates to:
  /// **'All dates'**
  String get allDates;

  /// No description provided for @uncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get uncategorized;

  /// No description provided for @transactionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No transactions} =1{1 transaction} other{{count} transactions}}'**
  String transactionCount(int count);

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

  /// No description provided for @colCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get colCategory;

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

  /// No description provided for @card.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get card;

  /// No description provided for @originalAmount.
  ///
  /// In en, this message translates to:
  /// **'Original amount'**
  String get originalAmount;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @kind.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get kind;

  /// No description provided for @splitParts.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get splitParts;

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

  /// No description provided for @notCounted.
  ///
  /// In en, this message translates to:
  /// **'Not counted in spending'**
  String get notCounted;

  /// No description provided for @pairedDesktop.
  ///
  /// In en, this message translates to:
  /// **'Paired desktop'**
  String get pairedDesktop;

  /// No description provided for @notPaired.
  ///
  /// In en, this message translates to:
  /// **'Not paired'**
  String get notPaired;

  /// No description provided for @checkNewData.
  ///
  /// In en, this message translates to:
  /// **'Check for new data'**
  String get checkNewData;

  /// No description provided for @upToDate.
  ///
  /// In en, this message translates to:
  /// **'Your data is up to date.'**
  String get upToDate;

  /// No description provided for @dataUpdated.
  ///
  /// In en, this message translates to:
  /// **'Data updated.'**
  String get dataUpdated;

  /// No description provided for @dataDateUnknown.
  ///
  /// In en, this message translates to:
  /// **'Data date unknown'**
  String get dataDateUnknown;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageDevice.
  ///
  /// In en, this message translates to:
  /// **'Device language'**
  String get languageDevice;

  /// No description provided for @languageFr.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get languageFr;

  /// No description provided for @languageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @lockNow.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get lockNow;

  /// No description provided for @chooseScope.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get chooseScope;

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

  /// No description provided for @tabCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get tabCategories;

  /// No description provided for @tabTrends.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get tabTrends;

  /// No description provided for @tabMerchants.
  ///
  /// In en, this message translates to:
  /// **'Merchants'**
  String get tabMerchants;

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

  /// No description provided for @overCompleteMonths.
  ///
  /// In en, this message translates to:
  /// **'over {count, plural, =1{1 complete month} other{{count} complete months}}'**
  String overCompleteMonths(int count);

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @unspecified.
  ///
  /// In en, this message translates to:
  /// **'unspecified'**
  String get unspecified;

  /// No description provided for @sharesWithout.
  ///
  /// In en, this message translates to:
  /// **'Hidden from shares: {names} · {amount} / month'**
  String sharesWithout(String names, String amount);

  /// No description provided for @globalSincePhone.
  ///
  /// In en, this message translates to:
  /// **'All accounts from {month} only: before that, one type of statement is missing. Pick one account at the top to see its whole history.'**
  String globalSincePhone(String month);

  /// No description provided for @incompleteMonthsShort.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 incomplete month} other{{count} incomplete months}} — counted in totals, left out of averages'**
  String incompleteMonthsShort(int count);

  /// No description provided for @noSpending.
  ///
  /// In en, this message translates to:
  /// **'No spending in this period.'**
  String get noSpending;

  /// No description provided for @chartMonthlySpending.
  ///
  /// In en, this message translates to:
  /// **'Monthly spending'**
  String get chartMonthlySpending;

  /// No description provided for @fadedIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Faded bars: a statement is missing for that month.'**
  String get fadedIncomplete;

  /// No description provided for @visits.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 purchase} other{{count} purchases}}'**
  String visits(int count);

  /// No description provided for @lastOn.
  ///
  /// In en, this message translates to:
  /// **'last {date}'**
  String lastOn(String date);

  /// No description provided for @merchantsHint.
  ///
  /// In en, this message translates to:
  /// **'Businesses only: transfers to people count in their category.'**
  String get merchantsHint;

  /// No description provided for @merchantsOf.
  ///
  /// In en, this message translates to:
  /// **'{name}: merchants'**
  String merchantsOf(String name);

  /// No description provided for @noMerchants.
  ///
  /// In en, this message translates to:
  /// **'No merchant here.'**
  String get noMerchants;

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

  /// No description provided for @cadenceBimonthly.
  ///
  /// In en, this message translates to:
  /// **'Every 2 months'**
  String get cadenceBimonthly;

  /// No description provided for @cadenceQuarterly.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get cadenceQuarterly;

  /// No description provided for @cadenceSemiannual.
  ///
  /// In en, this message translates to:
  /// **'Every 6 months'**
  String get cadenceSemiannual;

  /// No description provided for @cadenceYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get cadenceYearly;

  /// No description provided for @nextOn.
  ///
  /// In en, this message translates to:
  /// **'next {date}'**
  String nextOn(String date);

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **'{amount} / month'**
  String perMonth(String amount);

  /// No description provided for @chartBalances.
  ///
  /// In en, this message translates to:
  /// **'Month-end balance'**
  String get chartBalances;

  /// No description provided for @balancesNone.
  ///
  /// In en, this message translates to:
  /// **'No balance to follow here: pick a checking or savings account (or all accounts).'**
  String get balancesNone;

  /// No description provided for @balanceChange.
  ///
  /// In en, this message translates to:
  /// **'Change over the period: {amount}'**
  String balanceChange(String amount);

  /// No description provided for @balancesFrom.
  ///
  /// In en, this message translates to:
  /// **'Balances known from {month}: before, a statement is missing or the account had no transactions yet.'**
  String balancesFrom(String month);

  /// No description provided for @withoutHidden.
  ///
  /// In en, this message translates to:
  /// **'without hidden'**
  String get withoutHidden;

  /// No description provided for @forgetDesktop.
  ///
  /// In en, this message translates to:
  /// **'Forget this desktop'**
  String get forgetDesktop;

  /// No description provided for @forgetDesktopConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove the pairing and the copy of your data from this phone? You will need to pair again to see your expenses here.'**
  String get forgetDesktopConfirm;

  /// No description provided for @forgetAction.
  ///
  /// In en, this message translates to:
  /// **'Forget'**
  String get forgetAction;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;
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
