/// Desjardins statement parsers (account and Odyssée Mastercard) with
/// self-validation against the statement's own balances and totals.
library;

export 'src/desjardins/pdf/account_parser.dart' show parseAccountStatement;
export 'src/desjardins/anonymizer.dart' show anonymize;
export 'src/desjardins/csv/anonymizer.dart';
export 'src/desjardins/csv/reader.dart';
export 'src/desjardins/pdf/card_parser.dart' show parseCardStatement;
export 'src/desjardins/pdf/card_parser_2026.dart' show parseCardStatement2026, splitMerchant;
export 'src/desjardins/pdf/detect.dart';
export 'src/desjardins/importer.dart';
export 'src/desjardins/pdf/model.dart';
export 'src/desjardins/pdf/text.dart' show formatCents;
export 'src/desjardins/pdf/to_core.dart';
