import 'package:core/core.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:storage/storage.dart';

import '../l10n/app_localizations.dart';
import '../style.dart';
import 'keyed_stream.dart';
import 'notifications.dart' show anomalyText;
import 'transactions_dialog.dart';

const _blue = Color(0xFF2A78D6), _red = Color(0xFFE34948), _orange = Color(0xFFEDA100);

/// One regular payment: its payments over time around the usual amount, why
/// a payment was flagged, a way to mark it normal, and the lines.
Future<void> showRecurringDialog(
  BuildContext context, {
  required Scope scope,
  required int merchantId,
  required String merchant,
  required DateTime from,
  required DateTime to,
  required String currency,
}) => showDialog(
  context: context,
  builder: (c) => AlertDialog(
    title: Text(merchant),
    content: SizedBox(
      width: 900,
      height: 680,
      child: _RecurringDetail(scope: scope, merchantId: merchantId, from: from, to: to, currency: currency),
    ),
    actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text(AppLocalizations.of(c).close))],
  ),
);

class _RecurringDetail extends StatelessWidget {
  const _RecurringDetail({
    required this.scope,
    required this.merchantId,
    required this.from,
    required this.to,
    required this.currency,
  });

  final Scope scope;
  final int merchantId;
  final DateTime from, to;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ExpenseRepository>();
    return KeyedStreamBuilder<List<SpendLine>>(
      streamKey: (scope, to, merchantId),
      stream: () => repo.watchSpendingDetail(scope, DateTime.utc(2000), to),
      builder: (context, lines) {
        if (lines == null) return const Center(child: CircularProgressIndicator());
        final alerts = [
          for (final a in detectAnomalies(lines))
            if (a.merchantId == merchantId) a,
        ];
        final series = detectRecurring(lines).where((r) => r.merchantId == merchantId).firstOrNull;
        // Older unusual payments of the bill: shown, never alerted.
        final alerted = {for (final a in alerts) a.date};
        final past = [
          for (final o in (regularOutliers(lines)[merchantId] ?? const <Outlier>[]).reversed)
            if (!o.ok && !alerted.contains(o.date))
              Anomaly(AnomalyKind.regularAmount, o.date, o.merchant, merchantId, o.cents, o.usual),
        ];
        // Same-day lines summed, as the alerts and the series count them.
        final days = <DateTime, int>{};
        final okDays = <DateTime>{};
        for (final l in lines) {
          if (l.merchantId != merchantId || l.cents <= 0) continue;
          days[l.date] = (days[l.date] ?? 0) + l.cents;
          if (l.anomalyOk) okDays.add(l.date);
        }
        final usual = alerts.where((a) => a.kind != AnomalyKind.highAmount).firstOrNull?.usual ?? series?.typicalAmount;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 220,
              child: _PaymentsChart(
                days: days,
                okDays: okDays,
                usual: usual,
                alerts: alerts,
                past: {for (final p in past) p.date},
                currency: currency,
              ),
            ),
            const SizedBox(height: 12),
            // Explanations scroll on their own: a bill may have several.
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 230),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final a in alerts) AlertExplanation(a, currency),
                    for (final p in past) AlertExplanation(p, currency, past: true),
                    for (final d in okDays.toList()..sort((a, b) => b.compareTo(a)))
                      _MarkedNormal(merchantId: merchantId, day: d, cents: days[d]!, currency: currency),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SpendingList(
                filter: TxnFilter(scope: scope, from: from, to: to, merchantId: merchantId),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Payments as dots by date; the usual amount as a band (± the accepted
/// spread); a payment with an alert in red, an older unusual one in orange,
/// one marked normal hollow; a missing payment as a dashed line at its
/// expected date.
class _PaymentsChart extends StatelessWidget {
  const _PaymentsChart({
    required this.days,
    required this.okDays,
    required this.usual,
    required this.alerts,
    required this.past,
    required this.currency,
  });

  final Map<DateTime, int> days;
  final Set<DateTime> okDays;
  final int? usual;
  final List<Anomaly> alerts;

  /// Older unusual payments (no alert): orange.
  final Set<DateTime> past;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dates = days.keys.toList()..sort();
    final missing = alerts.where((a) => a.kind == AnomalyKind.regularMissing).toList();
    if (dates.isEmpty) return const SizedBox.shrink();
    final start = dates.first;
    double x(DateTime d) => d.difference(start).inDays.toDouble();
    final flagged = {
      for (final a in alerts)
        if (a.kind != AnomalyKind.regularMissing) a.date,
    };
    final lastX = [x(dates.last), for (final a in missing) x(a.date)].reduce((a, b) => a > b ? a : b);
    final format = DateFormat.MMMd(lang(context));
    return LineChart(
      LineChartData(
        minX: -3,
        maxX: lastX + 3,
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: [for (final d in dates) FlSpot(x(d), days[d]! / 100)],
            color: scheme.outlineVariant,
            barWidth: 1,
            dotData: FlDotData(
              getDotPainter: (spot, _, _, i) {
                final d = dates[i];
                if (okDays.contains(d)) {
                  return FlDotCirclePainter(
                    radius: 5,
                    color: scheme.surface,
                    strokeWidth: 2,
                    strokeColor: scheme.outline,
                  );
                }
                final bad = flagged.contains(d), old = past.contains(d);
                return FlDotCirclePainter(
                  radius: bad || old ? 7 : 4,
                  color: bad ? _red : (old ? _orange : _blue),
                  strokeWidth: 2,
                  strokeColor: scheme.surface,
                );
              },
            ),
          ),
        ],
        rangeAnnotations: RangeAnnotations(
          horizontalRangeAnnotations: [
            if (usual != null)
              HorizontalRangeAnnotation(
                y1: usual! * (1 - regularSpread) / 100,
                y2: usual! * (1 + regularSpread) / 100,
                color: _blue.withValues(alpha: 0.15),
              ),
          ],
        ),
        extraLinesData: ExtraLinesData(
          verticalLines: [
            for (final a in missing)
              VerticalLine(
                x: x(a.date),
                color: _red,
                strokeWidth: 2,
                dashArray: [6, 4],
                label: VerticalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  style: const TextStyle(color: _red, fontSize: 11),
                  labelResolver: (_) => AppLocalizations.of(context).expectedOn(format.format(a.date)),
                ),
              ),
          ],
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: scheme.outlineVariant, strokeWidth: 0.5),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 56,
              getTitlesWidget: (v, meta) => SideTitleWidget(
                meta: meta,
                child: Text(money(context, (v * 100).round(), currency), style: const TextStyle(fontSize: 11)),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 1,
              getTitlesWidget: (v, meta) {
                // A label under the first payment of each month.
                final i = dates.indexWhere((d) => x(d) == v);
                if (i < 0 || (i > 0 && dates[i - 1].month == dates[i].month)) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  child: Text(format.format(dates[i]), style: const TextStyle(fontSize: 11)),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => scheme.inverseSurface,
            fitInsideHorizontally: true,
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  '${format.format(dates[s.spotIndex])}  ${money(context, days[dates[s.spotIndex]]!, currency)}',
                  TextStyle(color: scheme.onInverseSurface),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Why a payment was flagged, in plain words; "this payment is normal" for
/// a payment that exists (a missing one can't be marked).
class AlertExplanation extends StatelessWidget {
  const AlertExplanation(this.alert, this.currency, {super.key, this.closeOnMark = false, this.past = false});

  final Anomaly alert;
  final String currency;

  /// An older unusual payment, shown without an alert (orange, neutral card).
  final bool past;

  /// Shown above a plain list of lines (bell): marking normal closes it.
  final bool closeOnMark;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final (alertIcon, alertTitle, _) = anomalyText(context, alert, currency);
    final (icon, title, color) = past ? (Icons.history, l.pastUnusual, _orange) : (alertIcon, alertTitle, _red);
    return Card(
      color: past
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(anomalyWhy(context, alert, currency)),
                ],
              ),
            ),
            if (alert.kind != AnomalyKind.regularMissing && alert.merchantId != null) ...[
              const SizedBox(width: 12),
              FilledButton.tonalIcon(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await context.read<ExpenseRepository>().setAnomalyOk(alert.merchantId!, alert.date, true);
                  if (closeOnMark) navigator.pop();
                },
                icon: const Icon(Icons.check),
                label: Text(l.markNormal),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A payment the user marked normal, with a way back.
class _MarkedNormal extends StatelessWidget {
  const _MarkedNormal({required this.merchantId, required this.day, required this.cents, required this.currency});

  final int merchantId;
  final DateTime day;
  final int cents;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      children: [
        Icon(Icons.check_circle_outline, size: 16, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 8),
        Text(l.markedNormal(DateFormat.yMMMd(lang(context)).format(day), money(context, cents, currency))),
        TextButton(
          onPressed: () => context.read<ExpenseRepository>().setAnomalyOk(merchantId, day, false),
          child: Text(l.undo),
        ),
      ],
    );
  }
}

/// The reason in plain words: "On Sep 13, $47.48: +$25.00 (+111 %) compared
/// with the usual $22.48 (median of the 3 payments before; ±5 % is normal)."
String anomalyWhy(BuildContext context, Anomaly a, String currency) {
  final l = AppLocalizations.of(context);
  final date = DateFormat.yMMMd(lang(context)).format(a.date);
  final amount = money(context, a.cents, currency);
  final usual = money(context, a.usual, currency);
  switch (a.kind) {
    case AnomalyKind.regularAmount:
      final diff = a.cents - a.usual;
      final sign = diff > 0 ? '+' : '−';
      return l.whyRegularAmount(
        date,
        amount,
        '$sign${money(context, diff.abs(), currency)}',
        '$sign${(diff.abs() * 100 / a.usual).round()} %',
        usual,
        minRegularPayments,
        (regularSpread * 100).round(),
      );
    case AnomalyKind.regularMissing:
      return l.whyRegularMissing(
        usual,
        date,
        a.toleranceDays,
        DateFormat.yMMMd(lang(context)).format(a.seenUntil ?? a.date),
      );
    case AnomalyKind.highAmount:
      return l.whyHigh(date, amount, (highShare * 100).round(), usual);
    case AnomalyKind.newFee:
      return l.whyNewFee(date, amount);
  }
}
