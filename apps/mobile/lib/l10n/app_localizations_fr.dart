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

  @override
  String get navHome => 'Accueil';

  @override
  String get navTransactions => 'Transactions';

  @override
  String get navStatistics => 'Statistiques';

  @override
  String get navSettings => 'Réglages';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String scopeCash(String currency) {
    return 'Espèces $currency';
  }

  @override
  String get noData => 'Aucune donnée pour l\'instant. Envoyez la base depuis l\'application de bureau.';

  @override
  String spentIn(String month) {
    return 'Dépensé en $month';
  }

  @override
  String lastMonthIs(String month, String amount) {
    return '$month : $amount';
  }

  @override
  String get statementMissing => 'Relevé manquant';

  @override
  String get incomplete => 'incomplet';

  @override
  String vsLastMonth(String percent) {
    return '$percent par rapport au mois dernier';
  }

  @override
  String coverageWarning(String accounts) {
    return 'Relevés manquants ou incomplets pour $accounts';
  }

  @override
  String get targetsTitle => 'Objectifs';

  @override
  String get allSpending => 'Toutes les dépenses';

  @override
  String get period_week => 'Hebdomadaire';

  @override
  String get period_month => 'Mensuel';

  @override
  String get period_year => 'Annuel';

  @override
  String targetSpent(String spent, String target) {
    return '$spent sur $target';
  }

  @override
  String get status_onTrack => 'En bonne voie';

  @override
  String get status_atRisk => 'À surveiller';

  @override
  String get status_over => 'Dépassé';

  @override
  String get recentTransactions => 'Dernières transactions';

  @override
  String get seeAll => 'Tout voir';

  @override
  String get noTransactions => 'Aucune transaction';

  @override
  String get search => 'Rechercher';

  @override
  String get allAccounts => 'Tous les comptes';

  @override
  String get allCategories => 'Toutes les catégories';

  @override
  String get allDates => 'Toutes les dates';

  @override
  String get uncategorized => 'Non catégorisé';

  @override
  String transactionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
      zero: 'Aucune transaction',
    );
    return '$_temp0';
  }

  @override
  String get colDate => 'Date';

  @override
  String get colAccount => 'Compte';

  @override
  String get colCategory => 'Catégorie';

  @override
  String get statementText => 'Texte du relevé';

  @override
  String get location => 'Lieu';

  @override
  String get card => 'Carte';

  @override
  String get originalAmount => 'Montant d\'origine';

  @override
  String get note => 'Note';

  @override
  String get kind => 'Type';

  @override
  String get splitParts => 'Réparti';

  @override
  String get kind_expense => 'Dépense';

  @override
  String get kind_income => 'Revenu';

  @override
  String get kind_refund => 'Remboursement';

  @override
  String get kind_fee => 'Frais';

  @override
  String get kind_interest => 'Intérêts';

  @override
  String get kind_transfer => 'Virement entre mes comptes';

  @override
  String get kind_externalTransfer => 'Virement vers une autre banque';

  @override
  String get notCounted => 'Non compté dans les dépenses';

  @override
  String get statsSoon => 'Statistiques';

  @override
  String get pairedDesktop => 'Bureau associé';

  @override
  String get notPaired => 'Non associé';

  @override
  String get checkNewData => 'Chercher de nouvelles données';

  @override
  String get upToDate => 'Vos données sont à jour.';

  @override
  String get dataUpdated => 'Données mises à jour.';

  @override
  String get dataDateUnknown => 'Date des données inconnue';

  @override
  String get languageLabel => 'Langue';

  @override
  String get languageDevice => 'Langue de l\'appareil';

  @override
  String get languageFr => 'Français';

  @override
  String get languageEn => 'English';

  @override
  String get lockNow => 'Verrouiller';

  @override
  String get chooseScope => 'Compte';
}
