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
  /// **'On the desktop app, open Backups, then Send to phone, and scan the QR code shown there.'**
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
