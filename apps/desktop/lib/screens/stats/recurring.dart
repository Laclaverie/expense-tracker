// Statistics → Recurring tab: recurring payments, their alerts, sortable.

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storage/storage.dart';

import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../style.dart';
import '../../widgets/keyed_stream.dart';
import '../../widgets/notifications.dart' show anomalyText;
import '../../widgets/recurring_dialog.dart';
import 'charts.dart';
import 'data.dart';
import 'widgets.dart';

/// Recurring payments found in all history up to the end of the range (the
/// range itself is too short to see a yearly payment).
class RecurringTab extends StatefulWidget {
  const RecurringTab(this.d, {super.key});

  final StatsData d;

  @override
  State<RecurringTab> createState() => _RecurringTabState();
}

enum _RecurringSort { name, amount, perMonth, payments, last, next }

class _RecurringTabState extends State<RecurringTab> {
  _RecurringSort _sort = _RecurringSort.perMonth;
  bool _descending = true;

  StatsData get d => widget.d;

  int _compare(Recurring a, Recurring b) => switch (_sort) {
    _RecurringSort.name => a.merchant.toLowerCase().compareTo(b.merchant.toLowerCase()),
    _RecurringSort.amount => a.typicalAmount.compareTo(b.typicalAmount),
    _RecurringSort.perMonth => a.monthlyCost.compareTo(b.monthlyCost),
    _RecurringSort.payments => a.payments.length.compareTo(b.payments.length),
    _RecurringSort.last => a.last.compareTo(b.last),
    _RecurringSort.next => a.nextExpected.compareTo(b.nextExpected),
  };

  List<Recurring> _sorted(Iterable<Recurring> rows) =>
      rows.toList()..sort((a, b) => _descending ? _compare(b, a) : _compare(a, b));

  // Names and the next payment read best soonest / A first; amounts biggest first.
  void _sortBy(_RecurringSort s) => setState(() {
    _descending = s == _sort ? !_descending : s != _RecurringSort.name && s != _RecurringSort.next;
    _sort = s;
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget header(String text, _RecurringSort sort, {double? width, TextAlign align = TextAlign.right}) => SortHeader(
      text,
      active: sort == _sort,
      descending: _descending,
      onTap: () => _sortBy(sort),
      width: width,
      align: align,
    );
    return KeyedStreamBuilder<List<SpendLine>>(
      streamKey: (d.scope, d.to),
      stream: () => context.read<ExpenseRepository>().watchSpendingDetail(d.scope, DateTime.utc(2000), d.to),
      builder: (context, lines) {
        if (lines == null) return const Center(child: CircularProgressIndicator());
        final found = detectRecurring(d.narrow(lines));
        final alerts = {
          for (final a in detectAnomalies(lines))
            if (a.kind == AnomalyKind.regularAmount || a.kind == AnomalyKind.regularMissing) a.merchantId: a,
        };
        final focus = context.watch<AppState>().recurringFocus;
        final active = _sorted(found.where((r) => r.active));
        final stopped = _sorted(found.where((r) => !r.active));
        final small = Theme.of(context).textTheme.labelMedium;
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Kpi(
                    l.recurringPerMonth,
                    money(context, active.fold(0, (s, r) => s + r.monthlyCost), d.currency),
                    sub: l.recurringCount(active.length),
                  ),
                  SizedBox(
                    width: 520,
                    child: Text(
                      found.isEmpty ? l.recurringNone : l.recurringHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (found.isNotEmpty)
              Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const SizedBox(width: 26),
                    header(l.colMerchant, _RecurringSort.name, align: TextAlign.left),
                    SizedBox(width: 220, child: Text(l.colFrequency, style: small)),
                    header(l.colAmount, _RecurringSort.amount, width: 190),
                    header(l.colPerMonth, _RecurringSort.perMonth, width: 110),
                    header(l.colPayments, _RecurringSort.payments, width: 80),
                    header(l.lastVisit, _RecurringSort.last, width: 90),
                    header(l.colNext, _RecurringSort.next, width: 120),
                  ],
                ),
              ),
            for (final r in active) ...[
              _RecurringRow(r, d, alert: alerts[r.merchantId], highlighted: r.merchantId == focus),
              const Divider(height: 1),
            ],
            if (stopped.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(l.recurringStopped, style: Theme.of(context).textTheme.titleSmall),
              ),
              for (final r in stopped) ...[
                Opacity(
                  opacity: 0.6,
                  child: _RecurringRow(r, d, alert: alerts[r.merchantId], highlighted: r.merchantId == focus),
                ),
                const Divider(height: 1),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _RecurringRow extends StatefulWidget {
  const _RecurringRow(this.r, this.d, {this.alert, this.highlighted = false});

  final Recurring r;
  final StatsData d;

  /// A different amount or a missing payment, shown under the merchant.
  final Anomaly? alert;

  /// Opened from that alert: tinted and scrolled into view.
  final bool highlighted;

  @override
  State<_RecurringRow> createState() => _RecurringRowState();
}

class _RecurringRowState extends State<_RecurringRow> {
  @override
  void initState() {
    super.initState();
    if (widget.highlighted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Scrollable.ensureVisible(context, alignment: 0.3, duration: const Duration(milliseconds: 300));
      });
    }
  }

  Recurring get r => widget.r;
  StatsData get d => widget.d;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final index = context.watch<CategoryIndex>();
    final small = Theme.of(context).textTheme.bodySmall;
    final cadence = switch (r.cadence) {
      Cadence.weekly => l.cadenceWeekly,
      Cadence.biweekly => l.cadenceBiweekly,
      Cadence.monthly => l.cadenceMonthly,
      Cadence.quarterly => l.cadenceQuarterly,
      Cadence.yearly => l.cadenceYearly,
    };
    final days = r.dayRange;
    final when = days == null ? null : (days.$1 == days.$2 ? l.onDay(days.$1) : l.dayBetween(days.$1, days.$2));
    final alert = widget.alert;
    final row = InkWell(
      onTap: () => showRecurringDialog(
        context,
        scope: d.scope,
        merchantId: r.merchantId,
        merchant: r.merchant,
        from: r.first,
        to: d.to,
        currency: d.currency,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(r.isPerson ? Icons.person_outline : Icons.autorenew, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.merchant, overflow: TextOverflow.ellipsis),
                  if (alert != null) _AlertLine(alert, d.currency),
                  Row(
                    children: [
                      CircleAvatar(radius: 4, backgroundColor: groupColor(context, r.categoryId)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(index.name(context, r.categoryId), style: small, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 220,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cadence),
                  if (when != null) Text(when, style: small),
                ],
              ),
            ),
            SizedBox(
              width: 190,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(money(context, r.typicalAmount, d.currency)),
                  if (r.minAmount != r.maxAmount)
                    Text(
                      '${money(context, r.minAmount, d.currency)} – ${money(context, r.maxAmount, d.currency)}',
                      style: small,
                    ),
                ],
              ),
            ),
            SizedBox(
              width: 110,
              child: Text(
                money(context, r.monthlyCost, d.currency),
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            SizedBox(width: 80, child: Text('${r.payments.length}', textAlign: TextAlign.right)),
            SizedBox(width: 90, child: Text(shortDate(context, r.last), textAlign: TextAlign.right)),
            SizedBox(
              width: 120,
              child: Text(r.active ? shortDate(context, r.nextExpected) : '—', textAlign: TextAlign.right),
            ),
          ],
        ),
      ),
    );
    if (!widget.highlighted) return row;
    return ColoredBox(color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5), child: row);
  }
}

/// The alert of a regular payment, under its merchant: icon, short text, the
/// title as tooltip.
class _AlertLine extends StatelessWidget {
  const _AlertLine(this.alert, this.currency);

  final Anomaly alert;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final (icon, title, body) = anomalyText(context, alert, currency);
    final color = Theme.of(context).colorScheme.error;
    return Tooltip(
      message: title,
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              body,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
