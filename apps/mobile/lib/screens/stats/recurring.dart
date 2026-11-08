import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storage/storage.dart';

import '../../keyed_stream.dart';
import '../../l10n/app_localizations.dart';
import '../../style.dart';
import 'widgets.dart';

/// Recurring payments found in the whole history up to the end of the range (same detection as the desktop).
class RecurringView extends StatelessWidget {
  const RecurringView(this.d, {super.key});

  final StatsData d;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return KeyedStreamBuilder<List<SpendLine>>(
      streamKey: (d.scope, d.to),
      stream: () => context.read<ExpenseRepository>().watchSpendingDetail(d.scope, DateTime.utc(2000), d.to),
      builder: (context, lines) {
        if (lines == null) return const Center(child: CircularProgressIndicator());
        final found = detectRecurring(lines);
        final active = found.where((r) => r.active).toList();
        final stopped = found.where((r) => !r.active).toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          children: [
            Kpi(
              l.recurringPerMonth,
              money(context, active.fold(0, (s, r) => s + r.monthlyCost), d.currency),
              sub: l.recurringCount(active.length),
            ),
            if (found.isEmpty) Padding(padding: const EdgeInsets.all(16), child: Text(l.recurringNone)),
            const SizedBox(height: 8),
            for (final r in active) ...[_RecurringTile(r, d.currency), const Divider(height: 1)],
            if (stopped.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
                child: Text(l.recurringStopped, style: Theme.of(context).textTheme.titleSmall),
              ),
              for (final r in stopped) ...[
                Opacity(opacity: 0.6, child: _RecurringTile(r, d.currency, stopped: true)),
                const Divider(height: 1),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _RecurringTile extends StatelessWidget {
  const _RecurringTile(this.r, this.currency, {this.stopped = false});

  final Recurring r;
  final String currency;
  final bool stopped;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: CircleAvatar(radius: 6, backgroundColor: groupColor(context, r.categoryId)),
      minLeadingWidth: 12,
      title: Text(r.merchant, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          cadenceLabel(l, r.cadence),
          if (stopped) l.lastOn(shortDate(context, r.last)) else l.nextOn(shortDate(context, r.nextExpected)),
        ].join(' · '),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(money(context, r.typicalAmount, currency)),
          Text(l.perMonth(money(context, r.monthlyCost, currency)), style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
