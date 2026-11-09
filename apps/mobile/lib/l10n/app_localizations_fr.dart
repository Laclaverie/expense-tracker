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
      'Sur l\'ordinateur, cliquez sur l\'icône du téléphone dans la barre du haut, puis Associer un téléphone, et scannez le code QR affiché.';

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

  @override
  String get range6 => '6 mois';

  @override
  String get range12 => '12 mois';

  @override
  String get rangeThisYear => 'Cette année';

  @override
  String get tabCategories => 'Catégories';

  @override
  String get tabTrends => 'Tendances';

  @override
  String get tabMerchants => 'Marchands';

  @override
  String get tabRecurring => 'Récurrents';

  @override
  String get tabBalances => 'Soldes';

  @override
  String get statTotal => 'Total';

  @override
  String get statAverage => 'Moyenne mensuelle';

  @override
  String overCompleteMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mois complets',
      one: '1 mois complet',
    );
    return 'sur $_temp0';
  }

  @override
  String get share => 'Part';

  @override
  String get other => 'Autres';

  @override
  String get unspecified => 'non précisé';

  @override
  String sharesWithout(String names, String amount) {
    return 'Masqués des parts : $names · $amount / mois';
  }

  @override
  String globalSincePhone(String month) {
    return 'Tous les comptes à partir de $month seulement : avant, un type de relevé manque. Choisissez un compte en haut pour voir tout son historique.';
  }

  @override
  String incompleteMonthsShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mois incomplets',
      one: '1 mois incomplet',
    );
    return '$_temp0 — comptés dans les totaux, exclus des moyennes';
  }

  @override
  String get noSpending => 'Aucune dépense sur cette période.';

  @override
  String get chartMonthlySpending => 'Dépenses mensuelles';

  @override
  String get fadedIncomplete => 'Barres estompées : un relevé manque pour ce mois.';

  @override
  String visits(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count achats', one: '1 achat');
    return '$_temp0';
  }

  @override
  String lastOn(String date) {
    return 'dernier le $date';
  }

  @override
  String get merchantsHint => 'Commerces seulement : les virements à des personnes comptent dans leur catégorie.';

  @override
  String merchantsOf(String name) {
    return '$name : marchands';
  }

  @override
  String get noMerchants => 'Aucun marchand ici.';

  @override
  String get recurringPerMonth => 'Récurrent par mois';

  @override
  String recurringCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paiements récurrents',
      one: '1 paiement récurrent',
    );
    return '$_temp0';
  }

  @override
  String get recurringNone => 'Aucun paiement récurrent trouvé pour l\'instant : importez quelques mois de relevés.';

  @override
  String get recurringStopped => 'Plus vus récemment (probablement arrêtés)';

  @override
  String get cadenceWeekly => 'Chaque semaine';

  @override
  String get cadenceBiweekly => 'Toutes les 2 semaines';

  @override
  String get cadenceMonthly => 'Chaque mois';

  @override
  String get cadenceBimonthly => 'Tous les 2 mois';

  @override
  String get cadenceQuarterly => 'Chaque trimestre';

  @override
  String get cadenceSemiannual => 'Tous les 6 mois';

  @override
  String get cadenceYearly => 'Chaque année';

  @override
  String nextOn(String date) {
    return 'prochain le $date';
  }

  @override
  String perMonth(String amount) {
    return '$amount / mois';
  }

  @override
  String get chartBalances => 'Solde en fin de mois';

  @override
  String get balancesNone =>
      'Pas de solde à suivre ici : choisissez un compte courant ou d\'épargne (ou tous les comptes).';

  @override
  String balanceChange(String amount) {
    return 'Variation sur la période : $amount';
  }

  @override
  String balancesFrom(String month) {
    return 'Soldes connus à partir de $month : avant, un relevé manque ou le compte n\'avait pas encore d\'opérations.';
  }

  @override
  String get withoutHidden => 'hors masqués';

  @override
  String get forgetDesktop => 'Oublier cet ordinateur';

  @override
  String get forgetDesktopConfirm =>
      'Retirer l\'association et la copie de vos données de ce téléphone ? Il faudra l\'associer à nouveau pour voir vos dépenses ici.';

  @override
  String get forgetAction => 'Oublier';

  @override
  String get cancel => 'Annuler';

  @override
  String averageShort(String amount) {
    return 'moy. $amount';
  }

  @override
  String get noBills => 'Aucune opération ici.';

  @override
  String get allGroups => 'Tous les groupes';

  @override
  String perMonthShort(String amount) {
    return '$amount/mois';
  }

  @override
  String get peopleAndOther => 'Personnes et autres';
}
