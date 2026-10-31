import 'package:banks/plugin.dart';

import 'anonymizer.dart' as anonymizer;
import 'csv/anonymizer.dart';
import 'csv/reader.dart';
import 'pdf/detect.dart';
import 'pdf/to_core.dart';

/// Desjardins (Québec): account (checking, savings, TFSA, qualifying share)
/// and Odyssée World Elite Mastercard, from the monthly PDF statements
/// (`pdf/`) or the AccèsD CSV export (`csv/`, last 18 months), with the same
/// format ids and account refs.
class DesjardinsImporter extends BankImporter {
  const DesjardinsImporter();

  @override
  String get institution => 'desjardins';

  @override
  String get displayName => 'Desjardins';

  @override
  String get country => 'CA';

  static const account = StatementFormat(
    id: 'desjardins-account',
    labelFr: 'compte Desjardins',
    labelEn: 'Desjardins account',
    accountType: AccountType.checking,
    fileTypes: {'pdf', 'csv'},
  );

  static const card = StatementFormat(
    id: 'desjardins-card',
    labelFr: 'Mastercard',
    labelEn: 'Mastercard',
    accountType: AccountType.creditCard,
    fileTypes: {'pdf', 'csv'},
    // The card export has no balance column.
    uncheckedFileTypes: {'csv'},
  );

  @override
  List<StatementFormat> get formats => const [account, card];

  @override
  List<LineRule> get lineRules => const [...accountRules, ...cardRules, ...csvAccountRules, ...csvCardRules];

  // Screenshots in apps/desktop/assets/guides/desjardins/ (AccèsD, October 2026).
  @override
  ExportGuide get exportGuide => const ExportGuide(
    fileType: 'csv',
    stepsFr: [
      'Ouvrez AccèsD sur un ordinateur (desjardins.com) et connectez-vous.',
      'En haut de la page, cliquez « Rechercher des transactions ».',
      'Sous la recherche, cliquez « téléchargez la liste des transactions ».',
      'Choisissez les comptes ou la carte et la période (18 mois au plus), puis enregistrez le fichier CSV : '
          'un fichier pour les comptes, un pour la carte.',
      'Glissez les fichiers téléchargés ici, sur la page Importer.',
    ],
    stepsEn: [
      'Open AccèsD on a computer (desjardins.com) and sign in.',
      'At the top of the page, click "Rechercher des transactions" (search transactions).',
      'Below the search box, click "téléchargez la liste des transactions" (download the list).',
      'Pick the accounts or the card and the period (18 months at most), then save the CSV file: '
          'one file for the accounts, one for the card.',
      'Drop the downloaded files here, on the Import page.',
    ],
    images: {2: 'search-transactions.png', 3: 'download-list.png'},
    notesFr:
        "Desjardins donne au plus les 18 derniers mois. Téléchargez de nouveau quand vous voulez : "
        'les lignes déjà importées sont reconnues. Pour les mois plus anciens, importez les relevés PDF.',
    notesEn:
        'Desjardins gives the last 18 months at most. Download again whenever you like: lines already '
        'imported are recognized. For older months, import the PDF statements.',
  );

  @override
  String? detect(StatementInput input) => switch (input) {
    PdfInput(:final words) => switch (detectFormat(words)) {
      DesjardinsFormat.account => account.id,
      DesjardinsFormat.card => card.id,
      null => null,
    },
    TextInput() => switch (detectCsv(input)) {
      DesjardinsCsv.account => account.id,
      DesjardinsCsv.card => card.id,
      null => null,
    },
  };

  @override
  ImportedStatement read(StatementInput input) => switch (input) {
    PdfInput(:final words) => toImported(parseStatement(words)),
    TextInput() => readCsv(input),
  };

  @override
  StatementInput anonymize(StatementInput input, {Iterable<String> extra = const []}) => switch (input) {
    PdfInput(:final fileName, :final words) => PdfInput(fileName, anonymizer.anonymize(words, extra: extra)),
    TextInput() => anonymizeCsv(input, extra: extra),
  };
}
