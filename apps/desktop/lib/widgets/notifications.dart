import 'package:banks/banks.dart' show bankFor;
import 'package:core/core.dart' show Anomaly, AnomalyKind, DueStatement, detectAnomalies, dueStatements;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:storage/storage.dart';

import '../app_state.dart';
import '../clock.dart';
import '../coverage_view.dart';
import '../l10n/app_localizations.dart';
import '../style.dart';
import 'keyed_stream.dart';
import 'recurring_dialog.dart' show AlertExplanation;
import 'transactions_dialog.dart';

/// Statements whose next one should be out by now (recomputed from the
/// imported statements: importing the new one clears it).
Stream<List<DueStatement>> watchDueStatements(ExpenseRepository repo) => repo.watchStatements().map(
  (rows) => dueStatements([for (final s in rows) (s.institution, s.format, s.periodEnd)], appNow()),
);

/// "Desjardins · Mastercard".
String dueTitle(BuildContext context, DueStatement s) {
  final bank = bankFor(s.institution)?.displayName ?? s.institution;
  final label = statementLabel(context, s.format);
  final title = label.contains(bank) ? label : '$bank · $label';
  return title.isEmpty ? title : title[0].toUpperCase() + title.substring(1);
}

/// Bell with the number of notifications; the list opens below it.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key, required this.onImport});

  /// Opens the Import page.
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final repo = context.read<ExpenseRepository>();
    final scope = context.watch<AppState>().scope;
    return KeyedStreamBuilder<List<Anomaly>>(
      streamKey: scope,
      stream: () => scope == null
          ? Stream.value(const [])
          : repo
                .watchSpendingDetail(
                  scope.whole, // anomalies look at the whole bank, whatever account is shown
                  DateTime.utc(2000),
                  DateTime.utc(2100),
                )
                .map(detectAnomalies),
      builder: (context, anomalies) => StreamBuilder<List<DueStatement>>(
        stream: watchDueStatements(repo),
        builder: (context, snap) {
          final due = snap.data ?? const <DueStatement>[];
          final alerts = anomalies ?? const <Anomaly>[];
          final count = due.length + alerts.length;
          return PopupMenuButton<void>(
            tooltip: l.notifications,
            constraints: const BoxConstraints(minWidth: 320, maxWidth: 520),
            icon: Badge(
              isLabelVisible: count > 0,
              label: Text('$count'),
              child: Icon(count == 0 ? Icons.notifications_none : Icons.notifications_active_outlined),
            ),
            itemBuilder: (context) => [
              PopupMenuItem<void>(
                enabled: false,
                child: Text(l.notifications, style: Theme.of(context).textTheme.titleSmall),
              ),
              if (count == 0) PopupMenuItem<void>(enabled: false, child: Text(l.noNotifications)),
              for (final s in due)
                PopupMenuItem<void>(
                  onTap: onImport,
                  child: SizedBox(
                    width: 480,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.file_download_outlined),
                      title: Text(l.statementDue(dueTitle(context, s))),
                      subtitle: Text(
                        l.statementDueBody(
                          DateFormat.yMMMd(lang(context)).format(s.lastEnd),
                          DateFormat.yMMMd(lang(context)).format(s.expectedEnd),
                        ),
                      ),
                      trailing: Text(l.goImport, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                    ),
                  ),
                ),
              for (final a in alerts)
                PopupMenuItem<void>(
                  // A regular payment's alert is detailed with its series; the others show the shop's lines.
                  onTap: switch (a.kind) {
                    AnomalyKind.regularAmount ||
                    AnomalyKind.regularMissing => () => context.read<AppState>().showRecurring(a.merchantId),
                    _ => () => showSpendingDialog(
                      context,
                      title: a.merchant,
                      filter: TxnFilter(scope: scope, merchantId: a.merchantId),
                      header: AlertExplanation(a, scope?.currency ?? 'CAD', closeOnMark: true),
                    ),
                  },
                  child: SizedBox(
                    width: 480,
                    child: Builder(
                      builder: (context) {
                        final (icon, title, body) = anomalyText(context, a, scope?.currency ?? 'CAD');
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(icon),
                          title: Text(title),
                          subtitle: Text(body),
                        );
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Icon, title and detail of an alert: "Regular payment changed: ACME
/// MOBILE", "$47.48 on Sep 13 — usually $22.48".
(IconData, String, String) anomalyText(BuildContext context, Anomaly a, String currency) {
  final l = AppLocalizations.of(context);
  final date = DateFormat.MMMd(lang(context)).format(a.date);
  final amount = money(context, a.cents, currency);
  final usual = money(context, a.usual, currency);
  return switch (a.kind) {
    AnomalyKind.highAmount => (Icons.trending_up, l.anomalyHigh(a.merchant), l.anomalyHighBody(amount, date)),
    AnomalyKind.regularAmount => (
      Icons.price_change_outlined,
      l.anomalyRegular(a.merchant),
      l.anomalyRegularBody(amount, date, usual),
    ),
    AnomalyKind.regularMissing => (Icons.event_busy, l.anomalyMissing(a.merchant), l.anomalyMissingBody(usual, date)),
    AnomalyKind.newFee => (Icons.receipt_long, l.anomalyNewFee(a.merchant), l.anomalyNewFeeBody(amount, date)),
  };
}
