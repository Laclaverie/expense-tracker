// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Dépenses';

  @override
  String get pairTitle => 'Associer au bureau';

  @override
  String get pairIntro =>
      'Dans l\'application de bureau, ouvrez Sauvegardes puis Envoyer au téléphone, et scannez le code QR affiché.';

  @override
  String get pairScan => 'Scanner le code QR';

  @override
  String get pairNotOurs => 'Ce code QR ne vient pas de Dépenses';

  @override
  String get scanTitle => 'Scanner le code QR';

  @override
  String get scanHint => 'Pointez la caméra vers le code affiché sur l\'écran du bureau.';

  @override
  String get cameraDenied => 'La caméra n\'est pas disponible. Autorisez-la dans les réglages du téléphone.';

  @override
  String get downloadTitle => 'Téléchargement de la base de données';

  @override
  String downloadPercent(Object percent) {
    return '$percent %';
  }

  @override
  String get retry => 'Réessayer';

  @override
  String get unpair => 'Associer à nouveau';

  @override
  String get unlockTitle => 'Entrez votre mot de passe';

  @override
  String get passwordLabel => 'Mot de passe de la base';

  @override
  String get unlockButton => 'Déverrouiller';

  @override
  String get unlockWrong => 'Mot de passe incorrect';

  @override
  String get unlockOpening => 'Ouverture…';

  @override
  String get unlockFailedGeneric => 'Impossible d\'ouvrir les données.';

  @override
  String get errGeneric => 'Une erreur est survenue, réessayez.';

  @override
  String get switchPasswordBanner =>
      'Les nouvelles données sont protégées par un autre mot de passe. Entrez-le pour basculer.';

  @override
  String get switchAction => 'Basculer';

  @override
  String get homeTitle => 'Accueil';

  @override
  String dataFrom(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Données du $dateString';
  }

  @override
  String newDataFrom(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Nouvelles données du $dateString';
  }

  @override
  String get downloadAction => 'Télécharger';

  @override
  String get updating => 'Mise à jour…';

  @override
  String get errUnreachable => 'Bureau introuvable sur ce Wi-Fi. Sur le bureau : Envoyer au téléphone.';

  @override
  String get errNotPaired => 'Téléphone non associé à cette base.';

  @override
  String get errIncomplete => 'Transfert incomplet, réessayez.';

  @override
  String get errUpdatePhone =>
      'Les données du bureau sont plus récentes que cette application. Mettez à jour l\'application du téléphone.';

  @override
  String get errUpdateDesktop =>
      'Les données du bureau sont plus anciennes que cette application. Mettez à jour l\'application de bureau.';
}
