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
  String unlockFailed(Object error) {
    return 'The database cannot be opened: $error';
  }

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
}
