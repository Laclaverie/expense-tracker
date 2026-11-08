import 'package:banks/banks.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:storage/storage.dart' show MonthStatus;
import 'package:intl/intl.dart';

import 'l10n/app_localizations.dart';
import 'style.dart';

/// Short name of a statement format from its bank plug-in ("Mastercard").
String statementLabel(BuildContext context, String format) => statementFormat(format)?.label(lang(context)) ?? format;

/// "compte Desjardins manquant", "Mastercard jusqu'au 18 sept.".
String gapText(BuildContext context, (String, MonthCoverage) gap) {
  final l = AppLocalizations.of(context);
  final (format, cov) = gap;
  final label = statementLabel(context, format);
  if (cov.none) return l.gapMissing(label);
  return cov.coveredUntil == null ? l.gapPartial(label) : l.gapUntil(label, shortDate(context, cov.coveredUntil!));
}

String monthsText(BuildContext context, DateTime first, DateTime last) {
  final f = DateFormat.yMMM(lang(context));
  return first == last ? f.format(first) : '${f.format(first)} – ${f.format(last)}';
}

/// Incomplete months in one line; "Details" lists them (consecutive months
/// with the same gaps grouped).
class CoverageNotice extends StatefulWidget {
  const CoverageNotice(this.statuses, {super.key});

  final List<MonthStatus> statuses;

  @override
  State<CoverageNotice> createState() => _CoverageNoticeState();
}

class _CoverageNoticeState extends State<CoverageNotice> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final statuses = widget.statuses;
    final groups = <(DateTime, DateTime, String)>[];
    for (final s in statuses.where((s) => !s.complete)) {
      final text = s.gaps.map((g) => gapText(context, g)).join(', ');
      final prev = groups.isEmpty ? null : groups.last;
      final contiguous = prev != null && DateTime.utc(prev.$2.year, prev.$2.month + 1) == s.month && prev.$3 == text;
      if (contiguous && !text.contains(RegExp(r'\d'))) {
        groups[groups.length - 1] = (prev.$1, s.month, text);
      } else {
        groups.add((s.month, s.month, text));
      }
    }
    if (groups.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 2, 4, 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: scheme.onSecondaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l.incompleteMonthsShort(statuses.where((s) => !s.complete).length),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _open = !_open),
                  child: Text(_open ? l.hideDetails : l.details),
                ),
              ],
            ),
            if (_open)
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [for (final (a, b, text) in groups) Text('• ${monthsText(context, a, b)} : $text')],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
