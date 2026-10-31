/// Spending worth a look, in the latest [anomalyWindowDays] of data:
/// - a very large expense (among the largest of the past year);
/// - a regular payment (bill, subscription, rent) at a different amount than
///   usual, or missing;
/// - a fee from a source never charged before.
///
/// Shops without regular amounts (groceries, Costco) are never reported for
/// their amounts: a big grocery run is normal.
library;

import 'analysis.dart';
import 'recurring.dart';

enum AnomalyKind { highAmount, regularAmount, regularMissing, newFee }

class Anomaly {
  const Anomaly(
    this.kind,
    this.date,
    this.merchant,
    this.merchantId,
    this.cents,
    this.usual, {
    this.toleranceDays = 0,
    this.seenUntil,
  });

  final AnomalyKind kind;

  /// When it happened; for a missing payment, when it was expected.
  final DateTime date;
  final String merchant;
  final int? merchantId;

  /// The amount that stands out (a missing payment: its usual amount).
  final int cents;

  /// What it is compared with: the regular amount, or the "very large"
  /// threshold; 0 for a new fee.
  final int usual;

  /// Missing payment: allowed drift around [date], and the latest line of
  /// its account (lines exist after the expected date).
  final int toleranceDays;
  final DateTime? seenUntil;
}

/// Days of data, before the latest line, in which anomalies are reported.
const anomalyWindowDays = 45;

/// Very large: in the top [highShare] of the past year's lines (at least
/// [minHighHistory] of them) and at least [minHighCents].
const highShare = 0.01, minHighHistory = 50, minHighCents = 30000;

/// Regular: a recurring series with [minRegularPayments] payments before the
/// window, all within [regularSpread] of their median (a fixed price). An
/// amount differs when off by [minRegularChange] and [minRegularChangeCents].
const minRegularPayments = 3, regularSpread = 0.05, minRegularChange = 0.05, minRegularChangeCents = 100;

/// Anomalies in [lines] (spending, positive cents) within the last
/// [anomalyWindowDays] before [asOf] (default: the latest line), newest first.
/// Lines marked normal ([SpendLine.anomalyOk]) are never reported and don't
/// count in a regular payment's usual amount; they still count as paid.
List<Anomaly> detectAnomalies(List<SpendLine> lines, {DateTime? asOf}) {
  if (lines.isEmpty) return const [];
  final sorted = [...lines]..sort((a, b) => a.date.compareTo(b.date));
  final end = asOf ?? sorted.last.date;
  final since = end.subtract(const Duration(days: anomalyWindowDays));
  bool inWindow(DateTime d) => !d.isBefore(since) && !d.isAfter(end);
  final out = <Anomaly>[];

  // New fees.
  final charged = <int>{};
  for (final l in sorted) {
    final id = l.merchantId;
    if (id == null || l.cents <= 0 || !(l.categoryId?.startsWith('finance.') ?? false)) continue;
    if (charged.add(id) && inWindow(l.date) && !l.anomalyOk) {
      out.add(Anomaly(AnomalyKind.newFee, l.date, l.merchant, id, l.cents, 0));
    }
  }

  // Very large expenses, compared with the past year (people left out: money
  // sent to them is not a purchase).
  final year = [
    for (final l in sorted)
      if (!l.isPerson && l.cents > 0 && l.date.isAfter(end.subtract(const Duration(days: 365))) && !l.date.isAfter(end))
        l.cents,
  ]..sort();
  if (year.length >= minHighHistory) {
    final threshold = [year[(year.length * (1 - highShare)).floor()], minHighCents].reduce((a, b) => a > b ? a : b);
    for (final l in sorted) {
      if (!l.isPerson && !l.anomalyOk && inWindow(l.date) && l.cents >= threshold) {
        out.add(Anomaly(AnomalyKind.highAmount, l.date, l.merchant, l.merchantId, l.cents, threshold));
      }
    }
  }

  // Regular payments at a different amount: the payments of the window that
  // stand out from the usual amount at the time.
  for (final MapEntry(key: merchantId, value: list) in regularOutliers(sorted).entries) {
    for (final o in list) {
      if (inWindow(o.date) && !o.ok) {
        out.add(Anomaly(AnomalyKind.regularAmount, o.date, o.merchant, merchantId, o.cents, o.usual));
      }
    }
  }

  // Missing regular payments: expected (with the usual drift) before the
  // latest line of the account they are paid from, so a statement not
  // imported yet doesn't count.
  final latestByAccount = <int?, DateTime>{};
  final accountOf = <int, int?>{};
  for (final l in sorted) {
    latestByAccount[l.accountId] = l.date;
    if (l.merchantId != null) accountOf[l.merchantId!] = l.accountId;
  }
  final okDays = {
    for (final l in sorted)
      if (l.anomalyOk && l.merchantId != null) (l.merchantId, l.date),
  };
  for (final r in detectRecurring(lines, asOf: end)) {
    final before = [
      for (final p in r.payments)
        if (p.$1.isBefore(since) && !okDays.contains((r.merchantId, p.$1))) p.$2,
    ];
    if (before.length < minRegularPayments) continue;
    final last = before.sublist(before.length - minRegularPayments);
    final usual = _median(last);
    if (!last.every((p) => _fits(p, usual))) continue;
    final expected = r.nextExpected;
    final seenUntil = latestByAccount[accountOf[r.merchantId]] ?? end;
    final tolerance = r.cadence.tolerance.ceil();
    if (inWindow(expected) && expected.add(Duration(days: tolerance)).isBefore(seenUntil)) {
      out.add(
        Anomaly(
          AnomalyKind.regularMissing,
          expected,
          r.merchant,
          r.merchantId,
          usual,
          usual,
          toleranceDays: tolerance,
          seenUntil: seenUntil,
        ),
      );
    }
  }
  return out..sort((a, b) => b.date.compareTo(a.date));
}

/// A payment of a regular bill that stood out from its usual amount at the
/// time ([ok]: marked normal by the user).
class Outlier {
  const Outlier(this.date, this.merchant, this.cents, this.usual, {this.ok = false});

  final DateTime date;
  final String merchant;
  final int cents;
  final int usual;
  final bool ok;
}

/// A merchant counts as a regular bill when at least this share of its
/// payments (after the first) match an amount seen before: a steady price,
/// even one that changed once (fuel, groceries are not).
const minSteadyShare = 0.75;

bool _fits(int cents, int usual) => (cents - usual).abs() <= usual * regularSpread;

/// Over the whole history, the payments of regular bills that stood out from
/// the usual amount at the time, by merchant, oldest first.
///
/// Walks each bill's payments (same-day lines summed) keeping groups of
/// similar amounts; a group is a steady price after [minRegularPayments]
/// payments within [regularSpread]. A payment that fits no group, nor the sum
/// of the steady ones (two policies paid the same day), stands out while a
/// steady price exists, then starts a group of its own: after a price change
/// only the first payment at the new price stands out. Payments marked normal
/// are listed (with [Outlier.ok]) but never join a group.
Map<int, List<Outlier>> regularOutliers(List<SpendLine> lines) {
  final sorted = [...lines]..sort((a, b) => a.date.compareTo(b.date));
  final out = <int, List<Outlier>>{};
  for (final r in detectRecurring(sorted)) {
    if (out.containsKey(r.merchantId)) continue;

    final days = <DateTime, int>{};
    final ok = <DateTime>{};
    for (final l in sorted) {
      if (l.merchantId != r.merchantId || l.cents <= 0) continue;
      days[l.date] = (days[l.date] ?? 0) + l.cents;
      if (l.anomalyOk) ok.add(l.date);
    }
    final groups = <List<int>>[];
    int reference(List<int> g) => _median(g.sublist(g.length < minRegularPayments ? 0 : g.length - minRegularPayments));
    bool steady(List<int> g) {
      if (g.length < minRegularPayments) return false;
      final ref = reference(g);
      return g.sublist(g.length - minRegularPayments).every((a) => _fits(a, ref));
    }

    final found = <Outlier>[];
    var matched = 0;
    for (final MapEntry(key: date, value: cents) in days.entries) {
      final steadyRefs = [
        for (final g in groups)
          if (steady(g)) reference(g),
      ];
      final group = groups.where((g) => _fits(cents, reference(g))).firstOrNull;
      final sumOfSteady = steadyRefs.fold(0, (s, u) => s + u);
      if (group != null || (steadyRefs.length > 1 && _fits(cents, sumOfSteady))) {
        matched++;
        if (!ok.contains(date)) group?.add(cents);
        continue;
      }
      if (steadyRefs.isNotEmpty) {
        final usual = steadyRefs.reduce((a, b) => (cents - a).abs() <= (cents - b).abs() ? a : b);
        final change = (cents - usual).abs();
        if (change >= minRegularChangeCents && change >= usual * minRegularChange) {
          found.add(Outlier(date, r.merchant, cents, usual, ok: ok.contains(date)));
        }
      }
      if (!ok.contains(date)) groups.add([cents]);
    }
    if (days.length > 1 && matched >= (days.length - 1) * minSteadyShare) out[r.merchantId] = found;
  }
  return out;
}

int _median(List<int> values) {
  final s = [...values]..sort();
  return s[s.length ~/ 2];
}
