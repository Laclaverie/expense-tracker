import 'package:pdf_words/pdf_words.dart';

/// Thrown when a secret is still present after anonymization.
class AnonymizationLeak implements Exception {
  AnonymizationLeak(this.found);

  /// Number of words still containing a secret (the secrets are not repeated
  /// here so the message itself can't leak them).
  final int found;

  @override
  String toString() => 'AnonymizationLeak: $found word(s) still contain personal data';
}

/// 8+ digits: account / contract / ticket numbers, phone numbers.
bool isLongNumber(String s) => RegExp(r'\d').allMatches(s).length >= 8;

/// Booking references like `HMSXXK2NBM`, `qyvp9rv4fv4f1`: 8+ letters/digits mixing both.
bool isReference(String s) =>
    RegExp(r'^[A-Za-z0-9]{8,}$').hasMatch(s) && RegExp(r'\d').hasMatch(s) && RegExp(r'[A-Za-z]').hasMatch(s);

/// Same shape, no content: letters -> X, digits -> 9.
String mask(String s) => s.replaceAll(RegExp(r'[A-Za-zÀ-ÿ]'), 'X').replaceAll(RegExp(r'\d'), '9');

/// Throws [AnonymizationLeak] if any word of [doc] still contains one of
/// [secrets] (case-insensitive; short secrets must match a whole word).
void verifyAnonymized(DocumentWords doc, Set<String> secrets) {
  final upper = {for (final s in secrets) s.toUpperCase().replaceAll('/', '')}..removeWhere((s) => s.isEmpty);
  var found = 0;
  for (final page in doc.pages) {
    for (final w in page.words) {
      final text = w.text.toUpperCase().replaceAll('/', '');
      // Short secrets (card digits, "QC") must match whole words; longer ones anywhere.
      if (upper.contains(text) || upper.any((s) => s.length >= 5 && text.contains(s))) found++;
    }
  }
  if (found > 0) throw AnonymizationLeak(found);
}

/// [verifyAnonymized] for a text export: every word of [text] is checked.
void verifyTextAnonymized(String text, Set<String> secrets) => verifyAnonymized(
  DocumentWords([
    PageWords(0, 0, [for (final w in text.split(RegExp(r'[\s,;"]+'))) Word(w, 0, 0, 0)]),
  ]),
  secrets,
);
