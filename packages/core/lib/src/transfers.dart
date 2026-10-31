/// A transfer-kind transaction not yet paired with its other side.
class TransferCandidate {
  const TransferCandidate(this.id, this.accountId, this.amount, this.date);

  final String id;
  final int accountId;

  /// Signed cents.
  final int amount;
  final DateTime date;
}

/// Pairs transfers inside one institution: same absolute amount, opposite
/// signs, different accounts, dates at most [maxDays] apart (a card payment
/// is booked on the card a few days after leaving checking). Each candidate
/// is used once; the closest date wins.
List<(TransferCandidate, TransferCandidate)> matchTransfers(List<TransferCandidate> candidates, {int maxDays = 5}) {
  final outs = candidates.where((c) => c.amount < 0).toList()..sort((a, b) => a.date.compareTo(b.date));
  final ins = candidates.where((c) => c.amount > 0).toList();
  final pairs = <(TransferCandidate, TransferCandidate)>[];
  for (final out in outs) {
    TransferCandidate? best;
    var bestDays = maxDays + 1;
    for (final inn in ins) {
      if (inn.accountId == out.accountId || inn.amount != -out.amount) continue;
      final days = inn.date.difference(out.date).inDays.abs();
      if (days < bestDays) {
        best = inn;
        bestDays = days;
      }
    }
    if (best != null) {
      pairs.add((out, best));
      ins.remove(best);
    }
  }
  return pairs;
}
