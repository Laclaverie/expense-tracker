/// Recurring payments (subscriptions, bills, rent) found in spending history:
/// same merchant, regular interval, roughly the same amount. The date may
/// drift (a bill paid by hand) and occurrences may be missing (a statement
/// not imported yet).
library;

import 'analysis.dart';

enum Cadence {
  weekly(7, 2),
  biweekly(14, 3),
  monthly(30.44, 6),
  quarterly(91.31, 15),
  yearly(365.25, 25);

  const Cadence(this.days, this.tolerance);

  /// Average days between two payments.
  final double days;

  /// Allowed drift, in days, on one interval.
  final double tolerance;

  /// One payment expressed per month.
  double get perMonth => 30.44 / days;
}

/// One payment of a recurring series (same-day lines of a merchant summed).
typedef Payment = (DateTime, int);

class Recurring {
  Recurring({
    required this.merchantId,
    required this.merchant,
    required this.categoryId,
    required this.isPerson,
    required this.cadence,
    required this.payments,
    required this.active,
  });

  final int merchantId;
  final String merchant;

  /// Most frequent category of the merchant's lines.
  final String? categoryId;
  final bool isPerson;
  final Cadence cadence;

  /// Oldest first.
  final List<Payment> payments;

  /// Still seen: the latest data is not well past [nextExpected].
  final bool active;

  DateTime get first => payments.first.$1;
  DateTime get last => payments.last.$1;
  int get lastAmount => payments.last.$2;
  int get minAmount => payments.map((p) => p.$2).reduce((a, b) => a < b ? a : b);
  int get maxAmount => payments.map((p) => p.$2).reduce((a, b) => a > b ? a : b);

  /// Current price: median of the last three payments (one unusual bill
  /// doesn't count, a price change does after two payments).
  int get typicalAmount =>
      _median([for (final p in payments.skip(payments.length < 3 ? 0 : payments.length - 3)) p.$2]);

  int get monthlyCost => (typicalAmount * cadence.perMonth).round();

  DateTime get nextExpected => _next(last, cadence);

  /// Day-of-month range of the payments (monthly and slower), wrapping over
  /// the month end: `(28, 3)` means from the 28th to the 3rd.
  (int, int)? get dayRange {
    if (cadence.days < 28) return null;
    final (from, to, _) = _dayRange([for (final p in payments) p.$1.day]);
    return (from, to);
  }

  /// Paid on the same date each time (automatic debit) rather than a date
  /// that drifts (paid by hand).
  bool get fixedDate {
    if (cadence.days >= 28) return _dayRange([for (final p in payments) p.$1.day]).$3 <= 3;
    for (var i = 1; i < payments.length; i++) {
      final d = _days(payments[i - 1].$1, payments[i].$1);
      final k = (d / cadence.days).round();
      if ((d - k * cadence.days).abs() > 1.5) return false;
    }
    return true;
  }
}

/// Recurring payments in [lines], active ones first, then by monthly cost.
/// [asOf] is the end of the data (defaults to the latest line): a series
/// whose next payment is well before it is reported as no longer active.
/// Each series is judged against the latest line of the account it is paid
/// from (at most [asOf]): rent on an account statement ending Sept 30 is not
/// stopped because a card statement goes to Oct 20.
List<Recurring> detectRecurring(List<SpendLine> lines, {DateTime? asOf}) {
  final byMerchant = <int, Map<DateTime, int>>{};
  final names = <int, String>{};
  final persons = <int>{};
  final categories = <int, Map<String?, int>>{};
  final latestByAccount = <int?, DateTime>{};
  final accountOf = <int, (DateTime, int?)>{};
  DateTime? end;
  for (final l in lines) {
    if (end == null || l.date.isAfter(end)) end = l.date;
    final seen = latestByAccount[l.accountId];
    if (seen == null || l.date.isAfter(seen)) latestByAccount[l.accountId] = l.date;
    final id = l.merchantId;
    if (id == null || l.cents <= 0) continue;
    final day = DateTime.utc(l.date.year, l.date.month, l.date.day);
    byMerchant.putIfAbsent(id, () => {}).update(day, (v) => v + l.cents, ifAbsent: () => l.cents);
    names[id] = l.merchant;
    final paid = accountOf[id];
    if (paid == null || !l.date.isBefore(paid.$1)) accountOf[id] = (l.date, l.accountId);
    if (l.isPerson) persons.add(id);
    categories.putIfAbsent(id, () => {}).update(l.categoryId, (n) => n + 1, ifAbsent: () => 1);
  }
  end = asOf ?? end;
  if (end == null) return [];

  final out = <Recurring>[];
  for (final MapEntry(key: id, value: days) in byMerchant.entries) {
    final payments = [for (final e in days.entries) (e.key, e.value)]..sort((a, b) => a.$1.compareTo(b.$1));
    // The whole merchant first (amount may vary: phone bill with extras, price
    // change); otherwise separate series by amount (two policies at one insurer,
    // a subscription among one-off purchases).
    // A yearly series needs only two payments, so it must be the whole
    // merchant: two similar amounts a year apart among many purchases (a
    // grocery store) are chance.
    var series = [?_series(payments, amountTolerance: 0.35, amountShare: 0.5)];
    if (series.isEmpty) {
      series = [
        for (final cluster in _amountClusters(payments))
          ?_series(cluster, amountTolerance: 0.15, amountShare: 1, allowYearly: false),
      ];
    }
    final category = categories[id]!.entries.reduce((a, b) => b.value > a.value ? b : a).key;
    final accountEnd = latestByAccount[accountOf[id]!.$2]!;
    final seenUntil = accountEnd.isBefore(end) ? accountEnd : end;
    for (final (cadence, kept) in series) {
      final next = _next(kept.last.$1, cadence);
      final grace = cadence.tolerance > cadence.days / 2 ? cadence.tolerance : cadence.days / 2;
      out.add(
        Recurring(
          merchantId: id,
          merchant: names[id]!,
          categoryId: category,
          isPerson: persons.contains(id),
          cadence: cadence,
          payments: kept,
          active: !seenUntil.isAfter(_addDays(next, grace)),
        ),
      );
    }
  }
  out.sort((a, b) {
    if (a.active != b.active) return a.active ? -1 : 1;
    return b.monthlyCost.compareTo(a.monthlyCost);
  });
  return out;
}

/// Best regular series in [payments] (date order), or null. Payments that
/// don't fit (an extra purchase, a late one) may be left out, up to a quarter.
(Cadence, List<Payment>)? _series(
  List<Payment> payments, {
  required double amountTolerance,
  required double amountShare,
  bool allowYearly = true,
}) {
  (Cadence, List<Payment>)? best;
  (int, int, double)? bestScore;
  for (final cadence in Cadence.values) {
    if (cadence == Cadence.yearly && !allowYearly) continue;
    final yearly = cadence == Cadence.yearly;
    for (var start = 0; start < payments.length && start < 3; start++) {
      final kept = [payments[start]];
      var consecutive = 0;
      var drift = 0.0;
      for (final p in payments.skip(start + 1)) {
        final d = _days(kept.last.$1, p.$1);
        final k = (d / cadence.days).round();
        final off = (d - k * cadence.days).abs();
        // Up to two missed payments in a row (often a missing statement).
        if (k < 1 || k > 3 || off > cadence.tolerance) continue;
        kept.add(p);
        if (k == 1) consecutive++;
        drift += off;
      }
      if (kept.length < (yearly ? 2 : 3) || kept.length < payments.length * 0.75) continue;
      if (consecutive < (yearly ? 1 : 2)) continue;
      final median = _median([for (final p in kept) p.$2]);
      final close = kept.where((p) => (p.$2 - median).abs() <= median * amountTolerance).length;
      if (close < kept.length * amountShare) continue;
      // More payments explained, then more back-to-back intervals, then less drift.
      final score = (kept.length, consecutive, -drift / kept.length);
      if (bestScore == null || _better(score, bestScore)) (best, bestScore) = ((cadence, kept), score);
    }
  }
  return best;
}

bool _better((int, int, double) a, (int, int, double) b) =>
    a.$1 != b.$1 ? a.$1 > b.$1 : (a.$2 != b.$2 ? a.$2 > b.$2 : a.$3 > b.$3);

/// Payments grouped by similar amount (within 15 %), each group in date order.
List<List<Payment>> _amountClusters(List<Payment> payments) {
  final sorted = [...payments]..sort((a, b) => a.$2.compareTo(b.$2));
  final clusters = <List<Payment>>[];
  for (final p in sorted) {
    if (clusters.isEmpty || p.$2 > clusters.last.first.$2 * 1.15) {
      clusters.add([p]);
    } else {
      clusters.last.add(p);
    }
  }
  return [
    for (final c in clusters)
      if (c.length >= 2) c..sort((a, b) => a.$1.compareTo(b.$1)),
  ];
}

int _median(List<int> values) {
  final s = [...values]..sort();
  final n = s.length;
  return n.isOdd ? s[n ~/ 2] : ((s[n ~/ 2 - 1] + s[n ~/ 2]) / 2).round();
}

int _days(DateTime a, DateTime b) => b.difference(a).inHours ~/ 24;

DateTime _addDays(DateTime d, double days) => d.add(Duration(days: days.round()));

/// Next payment after [d]: same day of the month for monthly and slower
/// (clamped to the month end), otherwise a fixed number of days.
DateTime _next(DateTime d, Cadence cadence) {
  final months = switch (cadence) {
    Cadence.monthly => 1,
    Cadence.quarterly => 3,
    Cadence.yearly => 12,
    _ => 0,
  };
  if (months == 0) return _addDays(d, cadence.days);
  final lastDay = DateTime.utc(d.year, d.month + months + 1, 0).day;
  return DateTime.utc(d.year, d.month + months, d.day > lastDay ? lastDay : d.day);
}

/// `(from, to, spread)` of days of the month, choosing the tightest range
/// around the calendar (28th → 3rd when payments straddle the month end).
(int, int, int) _dayRange(List<int> days) {
  final s = {...days}.toList()..sort();
  final n = s.length;
  var gap = s.first + 31 - s.last, start = 0;
  for (var i = 1; i < n; i++) {
    if (s[i] - s[i - 1] > gap) (gap, start) = (s[i] - s[i - 1], i);
  }
  return (s[start], s[(start - 1 + n) % n], 31 - gap);
}
