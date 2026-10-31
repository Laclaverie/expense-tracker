import 'package:banks/banks.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'l10n/app_localizations.dart';
import 'style.dart';

/// A month and the statement types that don't fully cover it.
class MonthStatus {
  const MonthStatus(this.month, this.gaps);

  final DateTime month;
  final List<(String, MonthCoverage)> gaps;

  bool get complete => gaps.isEmpty;
}

/// Status of each month for every statement type ever imported in the scope.
/// A scope without statements (cash wallet) is always complete.
List<MonthStatus> monthStatuses(Map<String, List<DayRange>> coverage, List<DateTime> months) => [
  for (final m in months)
    MonthStatus(m, [
      for (final MapEntry(key: format, value: ranges) in coverage.entries)
        if (!monthCoverage(ranges, m).full) (format, monthCoverage(ranges, m)),
    ]),
];

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

/// Lists incomplete months (consecutive months with the same gaps grouped).
class CoverageNotice extends StatelessWidget {
  const CoverageNotice(this.statuses, {super.key});

  final List<MonthStatus> statuses;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: scheme.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.incompleteMonths, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  for (final (a, b, text) in groups) Text('• ${monthsText(context, a, b)} : $text'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
