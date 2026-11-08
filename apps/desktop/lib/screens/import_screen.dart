import 'package:banks/banks.dart' show BankImporter, bankFor, banks, statementFileTypes, statementFormat;
import 'package:core/core.dart' show AccountType, DayRange, MonthCoverage, monthCoverage;
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:storage/storage.dart';

import '../app_state.dart';
import '../coverage_view.dart';
import '../db_location.dart';
import '../l10n/app_localizations.dart';
import '../phone_sync.dart';
import '../statement_reader.dart';
import '../style.dart';
import '../widgets/backup_dialog.dart';
import '../widgets/export_guide.dart';
import '../widgets/phone_dialog.dart';
import 'add_bank.dart';

/// One file's import outcome, shown until the screen is left.
class _FileResult {
  _FileResult(this.name);

  final String name;
  bool done = false;
  bool ok = false;
  String message = '';
  List<String> details = const [];

  /// A PDF of a bank that has an export: its guide is offered.
  BankImporter? exportOf;
}

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key, required this.onImported});

  /// Called after an import that left lines to review.
  final VoidCallback onImported;

  @override
  State<ImportScreen> createState() => ImportScreenState();
}

class ImportScreenState extends State<ImportScreen> {
  final _results = <_FileResult>[];
  bool _hovering = false;

  /// Imports the statement files at [paths], as a drop on the page does.
  @visibleForTesting
  Future<void> importPaths(List<String> paths) async {
    final l = AppLocalizations.of(context);
    final importer = context.read<ImportService>();
    final repo = context.read<ExpenseRepository>();
    final state = context.read<AppState>();
    final phoneSync = context.read<PhoneSync?>();
    // Stable order; balances keep the newest statement whatever the order.
    // Files of a type no plug-in can read (photos, Word documents…) are skipped.
    paths = paths.where((f) => statementFileTypes.contains(p.extension(f).replaceFirst('.', '').toLowerCase())).toList()
      ..sort();
    if (paths.isEmpty || !await backupBefore(context, 'before-import')) return;
    final results = [for (final f in paths) _FileResult(p.basename(f))];
    setState(() => _results.insertAll(0, results));
    var anyImported = false;
    for (final (i, path) in paths.indexed) {
      final r = results[i];
      try {
        final read = await readStatementFile(path);
        final bank = bankFor(read.statement.institution);
        if (p.extension(path).toLowerCase() == '.pdf' && bank?.exportGuide != null) r.exportOf = bank;
        final outcome = await importer.importStatement(
          read.statement,
          fileHash: read.fileHash,
          fileName: r.name,
          fileType: p.extension(path).replaceFirst('.', '').toLowerCase(),
        );
        switch (outcome.status) {
          case ImportStatus.imported:
            anyImported = true;
            r.ok = true;
            r.message = [
              l.importDone(outcome.newCount, outcome.duplicateCount, outcome.reviewCount, outcome.transferCount),
              if (outcome.unmatchedCount > 0) l.importUnmatched(outcome.unmatchedCount),
              if (!outcome.verified) l.importNotVerified,
            ].join('\n');
          case ImportStatus.alreadyImported:
            r.ok = true;
            final when = outcome.existing == null ? '' : _date(outcome.existing!.importedAt);
            r.message = switch (outcome.duplicateReason) {
              DuplicateReason.sameFile => l.importAlreadySameFile(outcome.existing!.fileName, when),
              DuplicateReason.sameStatement => l.importAlreadySameStatement(outcome.existing!.fileName, when),
              _ => l.importAlreadySameLines,
            };
          case ImportStatus.invalid:
            r.message = l.importInvalid;
            r.details = outcome.failedChecks;
        }
      } on FormatException {
        r.message = l.importUnknown([for (final b in banks) b.displayName].join(', '));
      } on Object catch (e) {
        r.message = l.importError('$e');
      }
      if (mounted) setState(() => r.done = true);
    }
    // The current month usually has no statement yet: show the latest month with data.
    final latest = await repo.latestTransactionDate();
    if (latest != null && latest.isBefore(state.month)) state.month = latest;
    if (anyImported && mounted) await _offerPhone(phoneSync);
  }

  /// A phone is paired: offer to send it the new lines (once per import, whatever the number of files).
  Future<void> _offerPhone(PhoneSync? sync) async {
    if (sync == null || sync.phone == null) return;
    if (sync.serving) {
      await showPhoneDialog(context);
      return;
    }
    final l = AppLocalizations.of(context);
    final send = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(l.phoneAfterImport),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.phoneNotNow)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.phoneAfterImportSend)),
        ],
      ),
    );
    if (send != true || !mounted) return;
    await sync.send();
    if (mounted) await showPhoneDialog(context);
  }

  Future<void> _choose() async {
    final files = await openFiles(
      acceptedTypeGroups: [
        XTypeGroup(label: 'PDF, CSV, OFX…', extensions: [...statementFileTypes]),
      ],
    );
    if (files.isNotEmpty) await importPaths([for (final f in files) f.path]);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(l.importTitle, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        DropTarget(
          onDragEntered: (_) => setState(() => _hovering = true),
          onDragExited: (_) => setState(() => _hovering = false),
          onDragDone: (d) {
            setState(() => _hovering = false);
            importPaths([for (final f in d.files) f.path]);
          },
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: _hovering ? scheme.primaryContainer : scheme.surfaceContainerLow,
              border: Border.all(color: _hovering ? scheme.primary : scheme.outlineVariant, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.picture_as_pdf_outlined, size: 40, color: scheme.primary),
                  const SizedBox(height: 8),
                  Text(l.importDrop),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: _choose,
                    icon: const Icon(Icons.folder_open),
                    label: Text(l.importChoose),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(l.importPrivacy, style: Theme.of(context).textTheme.bodySmall),
        FutureBuilder<String>(
          future: databasePath(),
          builder: (context, snap) => snap.hasData
              ? SelectableText(l.dataLocation(snap.data!), style: Theme.of(context).textTheme.bodySmall)
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),
        const _SupportedBanks(),
        const SizedBox(height: 16),
        for (final r in _results)
          Card(
            child: ListTile(
              leading: !r.done
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(r.ok ? Icons.check_circle : Icons.error, color: r.ok ? Colors.green : scheme.error),
              title: Text(r.name),
              subtitle: Text(
                r.done
                    ? [
                        r.message,
                        ...r.details,
                        if (r.exportOf case final b?)
                          l.importExportHint(b.displayName, b.exportGuide!.fileType.toUpperCase()),
                      ].join('\n')
                    : l.importReading,
              ),
              trailing: r.done && r.exportOf != null
                  ? TextButton(onPressed: () => showExportGuide(context, r.exportOf!), child: Text(l.guideOpen))
                  : null,
            ),
          ),
        if (_results.any((r) => r.done && r.ok))
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: widget.onImported,
              icon: const Icon(Icons.fact_check),
              label: Text(l.navReview),
            ),
          ),
        const SizedBox(height: 24),
        const _CoverageGrid(),
        const SizedBox(height: 24),
        Text(l.importHistory, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        StreamBuilder<List<List<Statement>>>(
          stream: context.read<ExpenseRepository>().watchDuplicateStatements(),
          builder: (context, snap) {
            final groups = snap.data ?? const <List<Statement>>[];
            if (groups.isEmpty) {
              return ListTile(
                dense: true,
                leading: const Icon(Icons.verified_outlined, color: Color(0xFF0CA30C)),
                title: Text(l.noDuplicates),
              );
            }
            return Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.onErrorContainer),
                        const SizedBox(width: 8),
                        Expanded(child: Text(l.duplicatesFound(groups.fold(0, (n, g) => n + g.length)))),
                      ],
                    ),
                    for (final g in groups)
                      for (final st in g)
                        ListTile(
                          dense: true,
                          title: Text(st.fileName),
                          subtitle: Text(l.importedOn(_date(st.importedAt))),
                          trailing: IconButton(
                            tooltip: l.delete,
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _confirmDelete(context, st),
                          ),
                        ),
                  ],
                ),
              ),
            );
          },
        ),
        StreamBuilder<List<Statement>>(
          stream: context.read<ExpenseRepository>().watchStatements(),
          builder: (context, snap) => Column(
            children: [
              for (final s in snap.data ?? const <Statement>[])
                ListTile(
                  dense: true,
                  leading: Icon(accountIcon((statementFormat(s.format)?.accountType ?? AccountType.checking).name)),
                  title: Text(
                    '${_statementTitle(context, s)} — '
                    '${DateFormat.yMMMd(lang(context)).format(s.periodEnd)}',
                  ),
                  subtitle: Text(
                    '${s.fileName} · ${l.transactionCount(s.newCount)} · ${l.importedOn(_date(s.importedAt))}',
                  ),
                  trailing: IconButton(
                    tooltip: l.delete,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(context, s),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _date(DateTime d) => DateFormat.yMMMd(lang(context)).format(d.toLocal());

  Future<void> _confirmDelete(BuildContext context, Statement s) async {
    final l = AppLocalizations.of(context);
    final repo = context.read<ExpenseRepository>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(l.deleteStatementConfirm(s.newCount)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.delete)),
        ],
      ),
    );
    if (ok == true) await repo.deleteStatement(s.id);
  }
}

/// Every registered bank with its statement types and file types, and the way
/// in for a bank that isn't there ([AddBankScreen]).
class _SupportedBanks extends StatelessWidget {
  const _SupportedBanks();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final small = Theme.of(context).textTheme.bodySmall;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.supportedTitle, style: Theme.of(context).textTheme.titleMedium),
            for (final b in banks) ...[
              for (final f in b.formats)
                ListTile(
                  dense: true,
                  leading: Icon(accountIcon(f.accountType.name)),
                  title: Text(_bankAndLabel(b.displayName, f.label(lang(context)))),
                  trailing: Text([b.country, ...f.fileTypes.map((t) => t.toUpperCase())].join(' · '), style: small),
                ),
              if (b.exportGuide case final g?)
                Padding(
                  padding: const EdgeInsets.only(left: 56),
                  child: TextButton.icon(
                    onPressed: () => showExportGuide(context, b),
                    icon: const Icon(Icons.help_outline),
                    label: Text(l.guideButton(g.fileType.toUpperCase())),
                  ),
                ),
            ],
            TextButton.icon(
              onPressed: () =>
                  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AddBankScreen())),
              icon: const Icon(Icons.add_business_outlined),
              label: Text(l.addBankLink),
            ),
          ],
        ),
      ),
    );
  }
}

/// Months × statement types: which statements are imported (last 12 months
/// up to the latest statement).
class _CoverageGrid extends StatelessWidget {
  const _CoverageGrid();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final repo = context.read<ExpenseRepository>();
    final scope = context.watch<AppState>().scope?.whole;
    if (scope == null || scope.institution == 'cash') return const SizedBox.shrink();
    return StreamBuilder<Map<String, List<DayRange>>>(
      stream: repo.watchCoverage(scope),
      builder: (context, snap) {
        final cov = snap.data ?? const <String, List<DayRange>>{};
        if (cov.isEmpty) return const SizedBox.shrink();
        final last = cov.values.expand((r) => r).map((r) => r.$2).reduce((a, b) => a.isAfter(b) ? a : b);
        final months = [for (var i = 11; i >= 0; i--) DateTime.utc(last.year, last.month - i)];
        final small = Theme.of(context).textTheme.bodySmall;
        Widget cell(MonthCoverage c, String label) {
          final (icon, color, tip) = c.full
              ? (Icons.check_circle, const Color(0xFF0CA30C), label)
              : c.none
              ? (Icons.cancel_outlined, Theme.of(context).colorScheme.error, l.gapMissing(label))
              : (
                  Icons.timelapse,
                  const Color(0xFFFAB219),
                  c.coveredUntil == null ? l.incomplete : l.gapUntil(label, shortDate(context, c.coveredUntil!)),
                );
          return Tooltip(
            message: tip,
            child: Icon(icon, color: color, size: 20),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.coverageTitle, style: Theme.of(context).textTheme.titleMedium),
            Text(l.coverageHint, style: small),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                defaultColumnWidth: const FixedColumnWidth(64),
                columnWidths: const {0: FixedColumnWidth(160)},
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(
                    children: [
                      const SizedBox(),
                      for (final m in months)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            DateFormat.yMMM(lang(context)).format(m),
                            style: small,
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                  for (final MapEntry(key: format, value: ranges) in cov.entries)
                    TableRow(
                      children: [
                        Text(statementLabel(context, format)),
                        for (final m in months)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Center(child: cell(monthCoverage(ranges, m), statementLabel(context, format))),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// "Desjardins · Mastercard"; the bank name once when the label already has it.
String _statementTitle(BuildContext context, Statement s) =>
    _bankAndLabel(bankFor(s.institution)?.displayName ?? s.institution, statementLabel(context, s.format));

String _bankAndLabel(String bank, String label) => label.contains(bank) ? label : '$bank · $label';
