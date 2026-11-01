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
  String get navDashboard => 'Tableau de bord';

  @override
  String get navTransactions => 'Transactions';

  @override
  String get navReview => 'À vérifier';

  @override
  String get navImport => 'Importer';

  @override
  String get navAccounts => 'Comptes';

  @override
  String get navCategories => 'Catégories et règles';

  @override
  String scopeCash(String currency) {
    return 'Espèces $currency';
  }

  @override
  String get noData => 'Aucune donnée pour l\'instant. Importez un relevé pour commencer.';

  @override
  String spentIn(String month) {
    return 'Dépensé en $month';
  }

  @override
  String incomeIn(String month) {
    return 'Revenus en $month';
  }

  @override
  String get average6 => 'Moyenne sur 6 mois';

  @override
  String vsAverage(String percent) {
    return '$percent par rapport à la moyenne sur 6 mois';
  }

  @override
  String get monthlyByGroup => 'Dépenses mensuelles par groupe';

  @override
  String get byCategory => 'Par catégorie';

  @override
  String get topMerchants => 'Principaux marchands';

  @override
  String get other => 'Autres';

  @override
  String get uncategorized => 'Non catégorisé';

  @override
  String get transfersExcluded =>
      'Les virements entre vos comptes et les paiements de carte ne sont pas comptés comme dépenses.';

  @override
  String get search => 'Rechercher';

  @override
  String get allCategories => 'Toutes les catégories';

  @override
  String get allAccounts => 'Tous les comptes';

  @override
  String get allDates => 'Toutes les dates';

  @override
  String get colDate => 'Date';

  @override
  String get colAccount => 'Compte';

  @override
  String get colMerchant => 'Marchand';

  @override
  String get colCategory => 'Catégorie';

  @override
  String get colAmount => 'Montant';

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
  String get categorySearchHint => 'Rechercher (ex. essence, loyer, Costco) — Entrée pour choisir';

  @override
  String get frequentCategories => 'Fréquentes';

  @override
  String get sortDate => 'Date';

  @override
  String get sortAmount => 'Montant';

  @override
  String get sortMerchant => 'Par marchand';

  @override
  String selectUnder(String amount) {
    return 'Sélectionner < $amount';
  }

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sélectionnées',
      one: '1 sélectionnée',
    );
    return '$_temp0';
  }

  @override
  String get clearSelection => 'Désélectionner';

  @override
  String bulkSetQuestion(String category, int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count lignes', one: '1 ligne');
    return 'Mettre « $category » sur $_temp0 ?';
  }

  @override
  String bulkConfirmQuestion(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count lignes', one: '1 ligne');
    return 'Accepter la catégorie proposée pour $_temp0 ?';
  }

  @override
  String bulkConfirmSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lignes sans catégorie précise restent',
      one: '1 ligne sans catégorie précise reste',
    );
    return '$_temp0 à vérifier.';
  }

  @override
  String get reasonRule => 'Règle';

  @override
  String get reasonMerchant => 'Déjà choisi pour ce marchand';

  @override
  String reasonBank(String category) {
    return 'Indice de la banque → $category';
  }

  @override
  String get reasonSeed => 'Marchand connu';

  @override
  String reasonKeyword(String word) {
    return 'Mot-clé « $word »';
  }

  @override
  String reasonHint(String rate, String category) {
    return 'Bonidollars $rate % → $category';
  }

  @override
  String reasonLearned(int count, String word) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count lignes', one: '1 ligne');
    return 'Comme $_temp0 avec « $word »';
  }

  @override
  String get reasonNone => 'Aucune piste : à choisir';

  @override
  String anomalyHigh(String merchant) {
    return 'Très grosse dépense : $merchant';
  }

  @override
  String anomalyHighBody(String amount, String date) {
    return '$amount le $date';
  }

  @override
  String anomalyRegular(String merchant) {
    return 'Paiement régulier différent : $merchant';
  }

  @override
  String anomalyRegularBody(String amount, String date, String usual) {
    return '$amount le $date — d\'habitude $usual';
  }

  @override
  String anomalyMissing(String merchant) {
    return 'Paiement régulier manquant : $merchant';
  }

  @override
  String anomalyMissingBody(String usual, String date) {
    return '$usual attendu vers le $date, pas trouvé';
  }

  @override
  String get markNormal => 'Ce paiement est normal';

  @override
  String markedNormal(String date, String amount) {
    return '$date · $amount — marqué normal';
  }

  @override
  String get undo => 'Annuler';

  @override
  String expectedOn(String date) {
    return 'attendu le $date';
  }

  @override
  String whyRegularAmount(String date, String amount, String diff, String pct, String usual, int count, int spread) {
    return 'Le $date, $amount : $diff ($pct) par rapport au montant habituel $usual (médiane des $count paiements précédents ; ±$spread % est normal).';
  }

  @override
  String whyRegularMissing(String usual, String date, int days, String until) {
    return '$usual attendu vers le $date (± $days jours) : aucun paiement trouvé, alors que le compte a des opérations jusqu\'au $until. Relevé manquant, ou paiement arrêté ?';
  }

  @override
  String whyHigh(String date, String amount, int share, String threshold) {
    return 'Le $date, $amount : parmi vos $share % plus grosses dépenses de l\'année (à partir de $threshold).';
  }

  @override
  String whyNewFee(String date, String amount) {
    return 'Le $date, $amount : premiers frais de ce type.';
  }

  @override
  String get pastUnusual => 'Paiement inhabituel passé (sans alerte)';

  @override
  String anomalyNewFee(String merchant) {
    return 'Nouveaux frais : $merchant';
  }

  @override
  String anomalyNewFeeBody(String amount, String date) {
    return '$amount le $date';
  }

  @override
  String get copyForSearch => 'Copier le nom et le lieu (pour chercher en ligne)';

  @override
  String copied(String text) {
    return 'Copié : $text';
  }

  @override
  String get reviewEmpty => 'Rien à vérifier.';

  @override
  String get reviewHint =>
      'Vérifiez la catégorie proposée ou choisissez-en une autre. Votre choix peut être retenu pour le marchand.';

  @override
  String get confirm => 'Confirmer';

  @override
  String get chooseCategory => 'Choisir une catégorie';

  @override
  String rememberMerchant(String merchant) {
    return 'Toujours utiliser cette catégorie pour $merchant';
  }

  @override
  String updatedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions mises à jour',
      one: '1 transaction mise à jour',
    );
    return '$_temp0';
  }

  @override
  String get importTitle => 'Importer des relevés';

  @override
  String get notifications => 'Notifications';

  @override
  String get noNotifications => 'Rien à signaler';

  @override
  String get goImport => 'Importer';

  @override
  String statementDue(String statement) {
    return '$statement : nouveau relevé à télécharger';
  }

  @override
  String statementDueBody(String last, String next) {
    return 'Dernier importé : jusqu\'au $last. Le suivant (jusqu\'au $next) devrait être disponible.';
  }

  @override
  String statementsDue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count relevés à télécharger',
      one: '1 relevé à télécharger',
    );
    return '$_temp0';
  }

  @override
  String get exportTransactions => 'Exporter…';

  @override
  String get exportHint =>
      'Enregistrer ces transactions (ce mois ou toutes les dates, avec les filtres) en Excel ou CSV';

  @override
  String get exportFileName => 'transactions';

  @override
  String exportedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lignes exportées',
      one: '1 ligne exportée',
    );
    return '$_temp0';
  }

  @override
  String get openFile => 'Ouvrir';

  @override
  String get splitPart => 'partie';

  @override
  String get hdrBank => 'Banque';

  @override
  String get hdrDescription => 'Description';

  @override
  String get hdrGroup => 'Groupe';

  @override
  String get hdrType => 'Type';

  @override
  String get hdrCurrency => 'Devise';

  @override
  String get hdrForeignAmount => 'Montant d\'origine';

  @override
  String get hdrForeignCurrency => 'Devise d\'origine';

  @override
  String get hdrNote => 'Note';

  @override
  String get importDrop => 'Déposez ici vos relevés bancaires (PDF, CSV, OFX…)';

  @override
  String get importChoose => 'Choisir des fichiers…';

  @override
  String get importReading => 'Lecture…';

  @override
  String importDone(int count, int duplicates, int review, int transfers) {
    return '$count nouvelles · $duplicates déjà connues · $review à vérifier · $transfers virements associés';
  }

  @override
  String importUnmatched(int count) {
    return '$count nouvelles lignes de jours déjà importés depuis un autre fichier (PDF ou CSV) n\'y figurent pas : vérifiez-les dans Transactions';
  }

  @override
  String get importNotVerified => 'Non vérifié : ce fichier n\'a ni solde ni total pour contrôler ses lignes';

  @override
  String guideTitle(String bank, String fileType) {
    return '$bank : télécharger vos transactions ($fileType)';
  }

  @override
  String guideButton(String fileType) {
    return 'Obtenir vos fichiers $fileType';
  }

  @override
  String importExportHint(String bank, String fileType) {
    return '$bank exporte aussi vos transactions en $fileType : plus fiable que la lecture des PDF.';
  }

  @override
  String get guideOpen => 'Comment ?';

  @override
  String get importAlready => 'Déjà importé';

  @override
  String get importInvalid => 'Non importé : les totaux du relevé ne concordent pas';

  @override
  String importUnknown(String banks) {
    return 'Relevé non reconnu. Banques prises en charge : $banks';
  }

  @override
  String importError(String message) {
    return 'Impossible de lire le fichier : $message';
  }

  @override
  String get importHistory => 'Relevés importés';

  @override
  String get importPrivacy =>
      'Les PDF sont lus puis oubliés. Seule leur empreinte est conservée pour détecter les réimportations.';

  @override
  String deleteStatementConfirm(int count) {
    return 'Supprimer ce relevé et ses $count transactions ?';
  }

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get save => 'Enregistrer';

  @override
  String balanceEndOf(String month) {
    return 'Solde fin $month';
  }

  @override
  String balanceAsOf(String date) {
    return 'Solde au $date';
  }

  @override
  String get addCashExpense => 'Ajouter une dépense en espèces';

  @override
  String get amount => 'Montant';

  @override
  String get merchantOptional => 'Marchand (facultatif)';

  @override
  String get note => 'Note';

  @override
  String get date => 'Date';

  @override
  String get rules => 'Règles';

  @override
  String get addRule => 'Ajouter une règle';

  @override
  String get ruleContains => 'La description contient';

  @override
  String ruleSummary(String text, String category) {
    return '« $text » → $category';
  }

  @override
  String merchantRule(String merchant, String category) {
    return '$merchant → $category';
  }

  @override
  String get noRules =>
      'Aucune règle. Choisir « toujours » lors de la vérification retient un marchand ; les règles ici portent sur le texte de la description.';

  @override
  String get rememberedMerchants => 'Marchands retenus';

  @override
  String get categories => 'Catégories';

  @override
  String get details => 'Détails';

  @override
  String get statementText => 'Texte du relevé';

  @override
  String get location => 'Lieu';

  @override
  String get originalAmount => 'Montant d\'origine';

  @override
  String get kind => 'Type';

  @override
  String get card => 'Carte';

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
  String get language => 'Langue';

  @override
  String get notCounted => 'Non compté dans les dépenses';

  @override
  String get navTargets => 'Objectifs';

  @override
  String get addTarget => 'Ajouter un objectif';

  @override
  String get editTarget => 'Modifier l\'objectif';

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
  String targetProjected(String amount) {
    return 'Projection : $amount';
  }

  @override
  String get status_onTrack => 'En bonne voie';

  @override
  String get status_atRisk => 'À surveiller';

  @override
  String get status_over => 'Dépassé';

  @override
  String targetSuggestion(String amount) {
    return 'Suggestion : $amount (moyenne des 3 dernières périodes)';
  }

  @override
  String get noTargets =>
      'Aucun objectif. Fixez une limite par semaine, mois ou année pour toutes les dépenses, un groupe ou une catégorie.';

  @override
  String get targetsHint => 'Les objectifs sont indicatifs : rien n\'est bloqué ni déplacé.';

  @override
  String get history => 'Historique';

  @override
  String get withinTarget => 'Dans l\'objectif';

  @override
  String get split => 'Répartir';

  @override
  String get splitTitle => 'Répartir entre catégories';

  @override
  String get splitAddPart => 'Ajouter une part';

  @override
  String splitRemaining(String amount) {
    return 'Reste : $amount';
  }

  @override
  String get splitRemove => 'Annuler la répartition';

  @override
  String splitLabel(int count) {
    return 'Réparti · $count';
  }

  @override
  String get edit => 'Modifier';

  @override
  String importAlreadySameFile(String file, String date) {
    return 'Déjà importé : même fichier que « $file » (importé le $date)';
  }

  @override
  String importAlreadySameStatement(String file, String date) {
    return 'Déjà importé : même relevé que « $file » (importé le $date), depuis un autre fichier';
  }

  @override
  String get importAlreadySameLines => 'Déjà importé : toutes les lignes de ce fichier sont déjà connues';

  @override
  String get noDuplicates => 'Aucun relevé importé en double';

  @override
  String duplicatesFound(int count) {
    return '$count fichiers sont le même relevé importé plusieurs fois. Supprimez les copies en trop :';
  }

  @override
  String importedOn(String date) {
    return 'importé le $date';
  }

  @override
  String emptyMonth(String month) {
    return 'Pas encore de transactions en $month : les relevés arrivent après la fin du mois.';
  }

  @override
  String goToMonth(String month) {
    return 'Aller à $month';
  }

  @override
  String get noSpendingThisMonth => 'Aucune dépense ce mois-ci.';

  @override
  String dataLocation(String path) {
    return 'Les données sont enregistrées sur cet ordinateur : $path';
  }

  @override
  String get addCategory => 'Ajouter une catégorie';

  @override
  String get addGroup => 'Ajouter un groupe';

  @override
  String get editCategory => 'Modifier la catégorie';

  @override
  String get archive => 'Archiver';

  @override
  String get nameFr => 'Nom (français)';

  @override
  String get nameEn => 'Nom (anglais, facultatif)';

  @override
  String archiveConfirm(String name) {
    return 'Archiver « $name » ? Elle ne sera plus proposée ; les rapports passés restent justes.';
  }

  @override
  String archiveMove(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions l\'utilisent.',
      one: '1 transaction l\'utilise.',
    );
    return '$_temp0 Choisissez où les déplacer.';
  }

  @override
  String get categoriesHint => 'Cliquez sur une catégorie pour la renommer ou l\'archiver.';

  @override
  String get newCategory => 'Nouvelle catégorie';

  @override
  String createNamed(String name) {
    return 'Créer « $name »';
  }

  @override
  String get group => 'Groupe';

  @override
  String addToGroup(String group) {
    return 'Ajouter une catégorie à $group';
  }

  @override
  String get navStats => 'Statistiques';

  @override
  String get range6 => '6 mois';

  @override
  String get range12 => '12 mois';

  @override
  String get rangeThisYear => 'Cette année';

  @override
  String get rangeLastYear => 'Année passée';

  @override
  String get rangeAll => 'Tout';

  @override
  String get tabTrends => 'Tendances';

  @override
  String get tabCategories => 'Catégories';

  @override
  String get tabMerchants => 'Marchands';

  @override
  String get tabCompare => 'Comparer';

  @override
  String get tabRecurring => 'Récurrents';

  @override
  String get tabBalances => 'Soldes';

  @override
  String get chartBalances => 'Solde en fin de mois';

  @override
  String get balancesHint =>
      'Reconstitué à partir du solde du dernier relevé et des opérations précédentes. Les virements entre vos comptes comptent comme dépôts et retraits.';

  @override
  String get balancesNone =>
      'Pas de solde à suivre ici : choisissez un compte courant ou d\'épargne (ou Tous les comptes).';

  @override
  String get balance => 'Solde';

  @override
  String get balanceChange => 'Variation sur la période';

  @override
  String get colYear => 'Année';

  @override
  String get colDeposits => 'Dépôts';

  @override
  String get colWithdrawals => 'Retraits';

  @override
  String get colInterest => 'Intérêts';

  @override
  String get colChange => 'Variation';

  @override
  String get colYearEnd => 'Solde en fin';

  @override
  String interestOf(String amount) {
    return 'dont $amount d\'intérêts';
  }

  @override
  String globalSince(String month, String label) {
    return 'Tous les comptes à partir de $month seulement : avant, il n\'y a pas de relevé $label, les dépenses paraîtraient plus faibles. Choisissez un compte en haut pour voir tout son historique.';
  }

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
  String get recurringHint =>
      'Trouvés automatiquement dans tout l\'historique importé : même marchand, intervalle régulier, montant semblable, même si la date varie (facture payée à la main). Il faut au moins 3 paiements (2 pour un paiement annuel).';

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
  String get cadenceQuarterly => 'Chaque trimestre';

  @override
  String get cadenceYearly => 'Chaque année';

  @override
  String onDay(int day) {
    return 'le $day';
  }

  @override
  String dayBetween(int from, int to) {
    return 'entre le $from et le $to';
  }

  @override
  String get colFrequency => 'Fréquence';

  @override
  String get colPerMonth => 'Par mois';

  @override
  String get colPayments => 'Paiements';

  @override
  String get colNext => 'Prochain prévu';

  @override
  String get statTotal => 'Total';

  @override
  String get statAverage => 'Moyenne mensuelle';

  @override
  String get statVsPrevious => 'vs période précédente';

  @override
  String get statMostExpensive => 'Mois le plus cher';

  @override
  String get statLeastExpensive => 'Mois le moins cher';

  @override
  String get chartMonthlySpending => 'Dépenses mensuelles';

  @override
  String get chartIncomeSpending => 'Revenus et dépenses';

  @override
  String get legendSpending => 'Dépenses';

  @override
  String get legendIncome => 'Revenus';

  @override
  String get showEverything => 'Tout afficher';

  @override
  String get chartSpendingByStore => 'Dépenses par magasin';

  @override
  String get byStore => 'Par magasin';

  @override
  String get byCategoryTrend => 'Par catégorie';

  @override
  String purchasesPerMonth(String count) {
    return '$count achats / mois';
  }

  @override
  String analyzeOnly(String name) {
    return 'Analyser seulement $name';
  }

  @override
  String get byGroupTrend => 'Tendance par groupe';

  @override
  String get perMonth => 'par mois';

  @override
  String get trend => 'Tendance';

  @override
  String get share => 'Part';

  @override
  String get visits => 'Achats';

  @override
  String get averageTicket => 'Panier moyen';

  @override
  String get lastVisit => 'Dernier';

  @override
  String get merchantsHint => 'Commerces seulement : les virements à des personnes comptent dans leur catégorie.';

  @override
  String get cmpPreviousMonth => 'vs mois précédent';

  @override
  String get cmpSameMonthLastYear => 'vs même mois l\'an passé';

  @override
  String get cmpYearToDate => 'Depuis janvier vs l\'an passé';

  @override
  String yearToDate(int year) {
    final intl.NumberFormat yearNumberFormat = intl.NumberFormat.compact(locale: localeName);
    final String yearString = yearNumberFormat.format(year);

    return 'Janv. – ce mois $yearString';
  }

  @override
  String get difference => 'Écart';

  @override
  String get lessSpent => 'moins';

  @override
  String get moreSpent => 'plus';

  @override
  String get unspecified => 'non précisé';

  @override
  String get close => 'Fermer';

  @override
  String partOf(String amount) {
    return 'part de $amount';
  }

  @override
  String gapMissing(String label) {
    return 'relevé $label manquant';
  }

  @override
  String gapUntil(String label, String date) {
    return '$label seulement jusqu\'au $date';
  }

  @override
  String get incompleteMonths => 'Mois incomplets — comptés dans les totaux, exclus des moyennes et des comparaisons :';

  @override
  String get incomplete => 'incomplet';

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
  String get previousIncomplete => 'période précédente incomplète';

  @override
  String get coverageTitle => 'Couverture des relevés';

  @override
  String get coverageHint => 'Un trou indique un relevé à importer (ou un mois pas encore clos).';

  @override
  String gapPartial(String label) {
    return 'relevé $label partiel';
  }

  @override
  String get exportCategories => 'Exporter…';

  @override
  String get importCategories => 'Importer…';

  @override
  String get exportTitle => 'Exporter mes catégories';

  @override
  String exportRules(int count) {
    return 'Règles sur le texte de la description ($count)';
  }

  @override
  String exportMerchants(int count) {
    return 'Marchands retenus : vos choix « Toujours utiliser cette catégorie pour … » ($count, commerces seulement)';
  }

  @override
  String get exportPrivacy =>
      'Le fichier contient seulement des noms de catégories, des règles et des noms de commerces : aucune transaction, aucun montant, aucun compte, aucune personne.';

  @override
  String exportDone(String path) {
    return 'Exporté dans $path';
  }

  @override
  String importDoneCategories(int categories, int rules, int merchants, int moved) {
    return 'Ajouté : $categories catégories, $rules règles, $merchants marchands · $moved transactions reclassées';
  }

  @override
  String get importBadFile => 'Ce fichier n\'est pas un export de catégories.';

  @override
  String exportCategoriesCount(int count) {
    return 'Vos catégories et groupes ($count)';
  }

  @override
  String get supportedTitle => 'Banques que l\'app sait lire';

  @override
  String get addBankLink => 'Ma banque ou ma carte n\'est pas dans la liste';

  @override
  String get addBankTitle => 'Ajouter une banque';

  @override
  String get addBankIntro =>
      'Pour lire une nouvelle banque, quelqu\'un écrit un petit lecteur pour elle. Il a besoin de voir la mise en page de vos relevés, pas leur contenu. Cette page en fait une copie masquée : les lettres deviennent X, les chiffres 9. Rien ne quitte votre ordinateur : vous choisissez où la copie est enregistrée et à qui vous l\'envoyez.';

  @override
  String get addBankStep1 =>
      '1. Choisissez quelques relevés de cette banque : 3 à 6 mois, de chaque type que vous avez (compte, carte…).';

  @override
  String get addBankDrop => 'Déposez les relevés ici';

  @override
  String addBankReading(int count) {
    return 'Lecture de $count fichiers…';
  }

  @override
  String addBankFiles(int count) {
    return '$count relevés lus';
  }

  @override
  String get addBankStep2 =>
      '2. Mots qui peuvent rester lisibles. Au départ, tous sont masqués. Cochez les mots du relevé lui-même : titres de colonnes, sections, codes d\'opération, mois. Ne cochez jamais un mot personnel : votre nom, votre famille, rue, ville, employeur, personnes que vous payez, commerces que vous préférez garder pour vous.';

  @override
  String addBankKept(int kept, int total) {
    return '$kept mots lisibles sur $total';
  }

  @override
  String get addBankKeepAll => 'Tout garder';

  @override
  String get addBankHideAll => 'Tout masquer';

  @override
  String get addBankSearch => 'Chercher un mot';

  @override
  String addBankInFiles(int count) {
    return 'Dans $count relevés';
  }

  @override
  String get addBankNoWords => 'Aucun mot n\'apparaît dans plus d\'un relevé : tout sera masqué.';

  @override
  String get addBankStep3 => '3. Ce qui sera partagé (première page du premier relevé)';

  @override
  String get addBankNotesLabel =>
      'Notes pour la personne qui écrit le lecteur (facultatif, enregistrées dans notes.txt)';

  @override
  String get addBankNotesHint =>
      'Quel compte ou quelle carte est dans chaque fichier ? Que veulent dire les codes de compte (ex. EOP = compte chèques) ? Quelles dates avez-vous téléchargées ? L\'export montre-t-il les transactions de carte en attente ?';

  @override
  String get addBankStep4 =>
      '4. Enregistrez la copie masquée, regardez-la, puis envoyez le dossier à la personne qui ajoute votre banque.';

  @override
  String get addBankSave => 'Enregistrer dans un dossier…';

  @override
  String addBankSaved(String folder, int count) {
    return 'Enregistré dans $folder : $count fichiers';
  }

  @override
  String get addBankReadme =>
      'Copie masquée de relevés bancaires, faite par l\'application de dépenses (Importer > Ma banque ou ma carte n\'est pas dans la liste).\nLes lettres sont remplacées par X, les chiffres par 9 ; seuls les mots de reveal.txt restent lisibles. Les fichiers sont numérotés pour ne pas montrer leur nom d\'origine.\n\nstatement-N.shape.txt : la mise en page de chaque relevé, ligne par ligne, avec la position de chaque mot.\nstatement-N.shape.json : la même chose pour les PDF, en données lisibles par un programme.\nreveal.txt : les mots approuvés par la personne à qui appartiennent les relevés.\nnotes.txt : ce que cette personne a écrit sur les fichiers, s\'il y a lieu.\n\nPour la personne qui écrit le lecteur : docs/10-adding-a-bank.md dans le dépôt de l\'application.';

  @override
  String get backupTitle => 'Sauvegardes';

  @override
  String backupHint(int count) {
    return 'Une copie est faite automatiquement avant chaque import, avant qu\'une mise à jour de l\'app modifie la base et avant une restauration ; les $count dernières sont gardées. Enregistrez de temps en temps une copie ailleurs (clé USB, autre disque).';
  }

  @override
  String get backupNone => 'Aucune copie automatique pour l\'instant.';

  @override
  String get backupSave => 'Enregistrer une copie…';

  @override
  String backupSaved(String path) {
    return 'Copie enregistrée : $path';
  }

  @override
  String backupFailed(String message) {
    return 'Impossible de faire une copie de sauvegarde, rien n\'a été modifié : $message';
  }

  @override
  String get backupOpenFolder => 'Dossier des copies';

  @override
  String get backupRestoreFile => 'Restaurer un fichier…';

  @override
  String get backupRestore => 'Restaurer';

  @override
  String backupRestoreConfirm(String date) {
    return 'Revenir aux données du $date ? L\'app redémarre. Vos données actuelles sont copiées d\'abord : vous pourrez revenir en arrière.';
  }

  @override
  String get backupRestoreAction => 'Restaurer et redémarrer';

  @override
  String get backupReasonImport => 'avant un import';

  @override
  String get backupReasonUpdate => 'avant une mise à jour de l\'app';

  @override
  String get backupReasonRestore => 'avant une restauration';

  @override
  String get backupReasonCategories => 'avant un import de catégories';

  @override
  String get restoreNotDatabase => 'Ce fichier n\'est pas une base de données.';

  @override
  String get restoreNewer => 'Cette copie vient d\'une version plus récente de l\'app : mettez l\'app à jour d\'abord.';

  @override
  String get restoreNotExpenses => 'Cette base de données ne vient pas de cette app.';

  @override
  String get savingsRate => 'Taux d\'épargne';

  @override
  String savingsRateIs(String rate) {
    return 'Taux d\'épargne : $rate';
  }

  @override
  String savingsRateOver(String rate, int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months mois complets',
      one: '1 mois complet',
    );
    return 'Taux d\'épargne $rate · $_temp0';
  }

  @override
  String get globalSearchTooltip => 'Chercher dans toutes les transactions (Ctrl+K)';

  @override
  String get globalSearchHint => 'Marchand, montant (42,50), date (2026-10 ou 12/10), note…';

  @override
  String get globalSearchNone => 'Aucune transaction trouvée.';

  @override
  String globalSearchMore(int count) {
    return '$count premières affichées : ajoutez un mot pour affiner.';
  }

  @override
  String get passwordShow => 'Afficher le mot de passe';

  @override
  String get passwordHide => 'Masquer le mot de passe';

  @override
  String get passwordLabel => 'Mot de passe';

  @override
  String get passwordNew => 'Nouveau mot de passe';

  @override
  String get passwordConfirm => 'Retapez-le';

  @override
  String get passwordCurrent => 'Mot de passe actuel';

  @override
  String get passwordMismatch => 'Les deux saisies sont différentes.';

  @override
  String passwordRule(int min) {
    return 'Au moins $min caractères. Une phrase de quelques mots est le plus facile à retenir.';
  }

  @override
  String passwordTooShort(int count, int min, int missing) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count caractères', one: '1 caractère');
    return 'Trop court : $_temp0, il en faut au moins $min (encore $missing).';
  }

  @override
  String passwordLengthOk(int count) {
    return '$count caractères : assez long';
  }

  @override
  String get unlockTitle => 'Déverrouiller vos données';

  @override
  String get unlockAction => 'Déverrouiller';

  @override
  String get unlockWrong => 'Mot de passe incorrect.';

  @override
  String get unlockOpening => 'Ouverture…';

  @override
  String get unlockSetupTitle => 'Choisissez un mot de passe';

  @override
  String get unlockSetupWhy =>
      'Vos données sont chiffrées sur cet ordinateur : sans ce mot de passe, aucun programme ni personne ayant une copie du fichier ne peut les lire. Prenez une phrase de quelques mots : plus de 16 caractères.';

  @override
  String get unlockSetupForget =>
      'Le mot de passe n\'est enregistré nulle part. Si vous l\'oubliez, vos données sont perdues : les relevés peuvent être réimportés, mais vos catégories et vos choix sont perdus. Gardez-le dans un gestionnaire de mots de passe ou sur papier.';

  @override
  String get unlockSetupExisting =>
      'Vos données actuelles et les copies automatiques de l\'app sont chiffrées maintenant. Les copies que vous avez enregistrées ailleurs restent lisibles : supprimez-les, ou restaurez-en une pour en refaire une copie chiffrée.';

  @override
  String get unlockSetupAction => 'Chiffrer et ouvrir';

  @override
  String get unlockEncrypting => 'Chiffrement… (quelques secondes)';

  @override
  String get passwordChange => 'Changer le mot de passe';

  @override
  String get passwordChangeHint =>
      'Les copies faites avant gardent l\'ancien mot de passe : la restauration le demandera.';

  @override
  String get passwordChanged => 'Mot de passe changé.';

  @override
  String get restorePasswordTitle => 'Mot de passe de cette copie';

  @override
  String get restorePasswordHint =>
      'Cette copie ne s\'ouvre pas avec votre mot de passe actuel. Tapez le mot de passe avec lequel elle a été faite : elle sera restaurée avec votre mot de passe actuel.';

  @override
  String get restoreWrongPassword =>
      'Ce fichier ne s\'ouvre pas avec ce mot de passe, ou ce n\'est pas une copie de cette app.';

  @override
  String get devCopyButton => 'Copie anonymisée pour un développeur';

  @override
  String get devCopyTitle => 'Copie anonymisée pour un développeur';

  @override
  String get devCopyWhat =>
      'Une copie de toute la base où chaque magasin devient MARCHAND 001, MARCHAND 002… (grandes chaînes comme Costco ou IGA comprises), les personnes PERSONNE01…, les villes VILLE01…, où les notes, cartes, noms et numéros de compte sont masqués, et chaque montant multiplié par un facteur caché. Les catégories, règles, objectifs et dates sont gardés : un développeur peut travailler sur des données qui ressemblent aux vôtres. Les habitudes restent visibles (quand vous voyagez, comment se répartissent vos dépenses).';

  @override
  String get devCopyNotBackup =>
      'Ce n\'est pas une sauvegarde : elle ne peut pas être restaurée et ne remplace jamais vos données.';

  @override
  String get devCopyExtra => 'Autres mots à masquer (facultatif)';

  @override
  String get devCopyExtraHint =>
      'Votre nom, votre rue… : vérifiés aussi. Les mots qui ne sont pas sur une liste publique sont déjà remplacés.';

  @override
  String get devCopyAction => 'Choisir un dossier et créer';

  @override
  String get devCopyWorking => 'Anonymisation et vérification… (quelques secondes)';

  @override
  String get devCopySamePassword =>
      'Choisissez un autre mot de passe que le vôtre : c\'est celui-ci que vous donnerez au développeur.';

  @override
  String get devCopyDone => 'Copie créée et vérifiée : rien de vos données n\'y a été trouvé.';

  @override
  String devCopySummary(int merchants, int people, int cities, int notes, int cells, int words) {
    return '$merchants magasins remplacés (grandes chaînes comprises), $people personnes, $cities villes, $notes notes masquées. $cells textes vérifiés contre $words mots de vos données.';
  }

  @override
  String get devCopyGive =>
      'Donnez au développeur ce dossier et le mot de passe choisi. Pour l\'ouvrir : EXPENSES_DB_DIR=<dossier> et le mot de passe.';

  @override
  String get devCopyLeak =>
      'Des mots de vos données étaient encore dans la copie : rien n\'a été écrit. Signalez-le (sans ces mots) :';

  @override
  String get restoreDevCopy =>
      'C\'est une copie anonymisée pour un développeur : elle ne peut pas remplacer vos données.';

  @override
  String get databaseHome => 'Vos données';

  @override
  String get databaseChange => 'Changer de fichier';

  @override
  String get databaseChooseTitle => 'Ouvrir un fichier de données';

  @override
  String get databaseChooseHint =>
      'Chaque fichier a son propre mot de passe : une copie anonymisée, une copie qu\'on vous a partagée… Le fichier reste où il est : gardez-le sur le disque de l\'ordinateur, pas sur une clé USB.';

  @override
  String databaseMissing(String path) {
    return 'Introuvable : $path';
  }

  @override
  String get databaseForget => 'Retirer de la liste (le fichier n\'est pas supprimé)';

  @override
  String get databaseMakeMain => 'Utiliser comme mes données';

  @override
  String databaseMakeMainTitle(String name) {
    return 'Faire de « $name » vos données ?';
  }

  @override
  String get databaseMakeMainNew =>
      'Il est copié dans le dossier de l\'application et s\'ouvrira à chaque démarrage, avec son propre mot de passe. Le fichier d\'origine reste où il est.';

  @override
  String get databaseMakeMainReplace =>
      'Il est copié dans le dossier de l\'application et s\'ouvrira à chaque démarrage, avec son propre mot de passe. Vos données actuelles sont gardées comme copie (Sauvegardes). Le fichier d\'origine reste où il est.';

  @override
  String get databaseMakeMainAction => 'Utiliser ce fichier';

  @override
  String databaseMakeMainFailed(String error) {
    return 'La copie n\'a pas pu être faite : $error';
  }

  @override
  String get databaseBrowse => 'Parcourir…';

  @override
  String get databaseNotFound => 'Ce fichier n\'existe pas.';

  @override
  String get databasePlaintext =>
      'Ce fichier n\'est pas chiffré : c\'est une copie d\'avant le mot de passe. Pour en reprendre les données, ouvrez vos données puis Sauvegardes → Restaurer un fichier.';

  @override
  String get lockTooltip => 'Verrouiller (ou changer de fichier)';

  @override
  String get lockConfirmTitle => 'Verrouiller ?';

  @override
  String get lockConfirm => 'Le fichier se ferme. Il faudra son mot de passe pour le rouvrir.';

  @override
  String get lockAction => 'Verrouiller';

  @override
  String backupDatabaseFile(String path) {
    return 'Fichier ouvert : $path';
  }

  @override
  String get backupShowFile => 'Montrer le fichier dans l\'Explorateur';

  @override
  String get shareKept => 'Part hors masqués';

  @override
  String excludeFromShare(String name) {
    return 'Masquer $name des parts (loyer, impôts…)';
  }

  @override
  String includeInShare(String name) {
    return 'Remettre $name dans les parts';
  }

  @override
  String sharesWithout(String names, String amount) {
    return 'Masqués des parts : $names · $amount / mois';
  }

  @override
  String get includeAllInShare => 'Tout remettre';

  @override
  String get allGroups => 'Tout';

  @override
  String get changeNeedsComplete =>
      'Pas de comparaison : un mois de cette période ou de la précédente n\'a pas tous ses relevés';

  @override
  String incompleteMonthsShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mois incomplets — comptés dans les totaux, exclus des moyennes et des comparaisons',
      one: '1 mois incomplet — compté dans les totaux, exclu des moyennes et des comparaisons',
    );
    return '$_temp0';
  }

  @override
  String get hideDetails => 'Masquer';

  @override
  String balancesFrom(String month) {
    return 'Soldes connus à partir de $month : avant, un relevé manque ou le compte n\'avait pas encore d\'opérations.';
  }
}
