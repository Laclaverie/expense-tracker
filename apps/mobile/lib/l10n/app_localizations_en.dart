// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Dépenses';

  @override
  String get pairTitle => 'Pair with the desktop';

  @override
  String get pairIntro => 'On the desktop app, open Backups, then Send to phone, and scan the QR code shown there.';

  @override
  String get pairScan => 'Scan the QR code';

  @override
  String get pairNotOurs => 'This QR code is not from Dépenses';

  @override
  String get scanTitle => 'Scan the QR code';

  @override
  String get scanHint => 'Point the camera at the code on the desktop screen.';

  @override
  String get cameraDenied => 'The camera is not available. Allow it in the phone settings.';

  @override
  String get downloadTitle => 'Downloading the database';

  @override
  String downloadPercent(Object percent) {
    return '$percent %';
  }

  @override
  String get retry => 'Try again';

  @override
  String get unpair => 'Pair again';

  @override
  String get unlockTitle => 'Enter your password';

  @override
  String get passwordLabel => 'Database password';

  @override
  String get unlockButton => 'Unlock';

  @override
  String get unlockWrong => 'Wrong password';

  @override
  String get unlockOpening => 'Opening…';

  @override
  String get unlockFailedGeneric => 'Could not open the data.';

  @override
  String get errGeneric => 'Something went wrong, try again.';

  @override
  String get switchPasswordBanner => 'New data is locked with another password. Enter it to switch.';

  @override
  String get switchAction => 'Switch';

  @override
  String get homeTitle => 'Home';

  @override
  String dataFrom(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Data from $dateString';
  }

  @override
  String newDataFrom(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'New data from $dateString';
  }

  @override
  String get downloadAction => 'Download';

  @override
  String get updating => 'Updating…';

  @override
  String get errUnreachable => 'Desktop not reachable on this Wi-Fi. On the desktop: Send to phone.';

  @override
  String get errNotPaired => 'Phone not paired with this database.';

  @override
  String get errIncomplete => 'Transfer incomplete, try again.';

  @override
  String get errUpdatePhone => 'The desktop data is newer than this app. Update the phone app.';

  @override
  String get errUpdateDesktop => 'The desktop data is older than this app. Update the desktop app.';

  @override
  String get navHome => 'Home';

  @override
  String get navTransactions => 'Transactions';

  @override
  String get navStatistics => 'Statistics';

  @override
  String get navSettings => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String scopeCash(String currency) {
    return 'Cash $currency';
  }

  @override
  String get noData => 'No data yet. Send the database from the desktop app.';

  @override
  String spentIn(String month) {
    return 'Spent in $month';
  }

  @override
  String lastMonthIs(String month, String amount) {
    return '$month: $amount';
  }

  @override
  String get statementMissing => 'Statement missing';

  @override
  String get incomplete => 'incomplete';

  @override
  String vsLastMonth(String percent) {
    return '$percent vs last month';
  }

  @override
  String coverageWarning(String accounts) {
    return 'Statements missing or incomplete for $accounts';
  }

  @override
  String get targetsTitle => 'Targets';

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
  String get status_onTrack => 'On track';

  @override
  String get status_atRisk => 'At risk';

  @override
  String get status_over => 'Over target';

  @override
  String get recentTransactions => 'Recent transactions';

  @override
  String get seeAll => 'See all';

  @override
  String get noTransactions => 'No transactions';

  @override
  String get search => 'Search';

  @override
  String get allAccounts => 'All accounts';

  @override
  String get allCategories => 'All categories';

  @override
  String get allDates => 'All dates';

  @override
  String get uncategorized => 'Uncategorized';

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
  String get colDate => 'Date';

  @override
  String get colAccount => 'Account';

  @override
  String get colCategory => 'Category';

  @override
  String get statementText => 'Statement text';

  @override
  String get location => 'Location';

  @override
  String get card => 'Card';

  @override
  String get originalAmount => 'Original amount';

  @override
  String get note => 'Note';

  @override
  String get kind => 'Type';

  @override
  String get splitParts => 'Split';

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
  String get notCounted => 'Not counted in spending';

  @override
  String get statsSoon => 'Statistics';

  @override
  String get pairedDesktop => 'Paired desktop';

  @override
  String get notPaired => 'Not paired';

  @override
  String get checkNewData => 'Check for new data';

  @override
  String get upToDate => 'Your data is up to date.';

  @override
  String get dataUpdated => 'Data updated.';

  @override
  String get dataDateUnknown => 'Data date unknown';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageDevice => 'Device language';

  @override
  String get languageFr => 'Français';

  @override
  String get languageEn => 'English';

  @override
  String get lockNow => 'Lock';

  @override
  String get chooseScope => 'Account';
}
