// Statistics → Compare tab: one month against another period.

import 'dart:math';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storage/storage.dart';

import '../../coverage_view.dart';
import '../../l10n/app_localizations.dart';
import '../../style.dart';
import '../../widgets/keyed_stream.dart';
import 'charts.dart';

enum _Comparison { previousMonth, sameMonthLastYear, yearToDate }

class CompareTab extends StatefulWidget {
  const CompareTab(this.d, {super.key, required this.month, required this.coverage});

  final StatsData d;

  /// Latest month with data; the tab starts on the latest complete month up
  /// to it (an unfinished month would compare rent not imported yet).
  /// Arrows in the tab move it.
  final DateTime month;
  final Map<String, List<DayRange>> coverage;

  @override
  State<CompareTab> createState() => _CompareTabState();
}

class _CompareTabState extends State<CompareTab> {
  _Comparison _mode = _Comparison.previousMonth;
  late DateTime _month = _start();

  /// The latest complete month among the last three, else the latest month.
  DateTime _start() {
    final m = widget.month;
    final recent = [for (var i = 0; i < 3; i++) DateTime.utc(m.year, m.month - i)];
    return monthStatuses(widget.coverage, recent).where((s) => s.complete).firstOrNull?.month ?? m;
  }

  @override
  void didUpdateWidget(CompareTab old) {
    super.didUpdateWidget(old);
    // New data (an import) moves the latest month, coverage may load after the tab: follow them.
    if (old.month != widget.month || (old.coverage.isEmpty && widget.coverage.isNotEmpty)) _month = _start();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final index = context.watch<CategoryIndex>();
    final m = _month;
    final next = DateTime.utc(m.year, m.month + 1);
    final ((DateTime, DateTime) a, (DateTime, DateTime) b, String labelA, String labelB) = switch (_mode) {
      _Comparison.previousMonth => (
        (m, next),
        (DateTime.utc(m.year, m.month - 1), m),
        monthLabel(context, m),
        monthLabel(context, DateTime.utc(m.year, m.month - 1)),
      ),
      _Comparison.sameMonthLastYear => (
        (m, next),
        (DateTime.utc(m.year - 1, m.month), DateTime.utc(m.year - 1, m.month + 1)),
        monthLabel(context, m),
        monthLabel(context, DateTime.utc(m.year - 1, m.month)),
      ),
      _Comparison.yearToDate => (
        (DateTime.utc(m.year), next),
        (DateTime.utc(m.year - 1), DateTime.utc(m.year - 1, m.month + 1)),
        l.yearToDate(m.year),
        l.yearToDate(m.year - 1),
      ),
    };
    final repo = context.read<ExpenseRepository>();
    final loadFrom = a.$1.isBefore(b.$1) ? a.$1 : b.$1;
    return KeyedStreamBuilder<List<SpendLine>>(
      streamKey: (widget.d.scope, loadFrom, next),
      stream: () => repo.watchSpendingDetail(widget.d.scope, loadFrom, next),
      builder: (context, lines) {
        // Narrowed to a group: compare its categories.
        final focus = widget.d.focus;
        final rows = comparePeriods(
          widget.d.narrow(lines ?? const []),
          a,
          b,
          keyOf: focus == null ? null : (x) => x.categoryId ?? '',
        ).where((r) => r.$2 != 0 || r.$3 != 0).toList();
        final totalA = rows.fold(0, (s, r) => s + r.$2), totalB = rows.fold(0, (s, r) => s + r.$3);
        final maxDiff = rows.isEmpty ? 1 : rows.map((r) => (r.$2 - r.$3).abs()).reduce(max).clamp(1, 1 << 50);
        final small = Theme.of(context).textTheme.labelMedium;
        final currency = widget.d.currency;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => setState(() => _month = DateTime.utc(m.year, m.month - 1)),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    SizedBox(
                      width: 150,
                      child: Text(
                        monthLabel(context, m),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: m.isBefore(widget.month)
                          ? () => setState(() => _month = DateTime.utc(m.year, m.month + 1))
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                SegmentedButton<_Comparison>(
                  segments: [
                    ButtonSegment(value: _Comparison.previousMonth, label: Text(l.cmpPreviousMonth)),
                    ButtonSegment(value: _Comparison.sameMonthLastYear, label: Text(l.cmpSameMonthLastYear)),
                    ButtonSegment(value: _Comparison.yearToDate, label: Text(l.cmpYearToDate)),
                  ],
                  selected: {_mode},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() => _mode = s.first),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // A period missing a statement would look cheaper than it was.
            CoverageNotice(
              [
                ...monthStatuses(widget.coverage, monthsBetween(a.$1, a.$2)),
                ...monthStatuses(widget.coverage, monthsBetween(b.$1, b.$2)),
              ]..sort((x, y) => x.month.compareTo(y.month)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(child: SizedBox()),
                SizedBox(
                  width: 130,
                  child: Text(labelA, style: small, textAlign: TextAlign.right),
                ),
                SizedBox(
                  width: 130,
                  child: Text(labelB, style: small, textAlign: TextAlign.right),
                ),
                SizedBox(
                  width: 130,
                  child: Text(l.difference, style: small, textAlign: TextAlign.right),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 260,
                  child: Text('${l.lessSpent}  ←  →  ${l.moreSpent}', style: small, textAlign: TextAlign.center),
                ),
              ],
            ),
            const Divider(),
            for (final (g, x, y) in [...rows, ('total', totalA, totalB)])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    if (g != 'total') ...[
                      CircleAvatar(radius: 5, backgroundColor: groupColor(context, g.isEmpty ? null : g)),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        g == 'total' ? l.statTotal : index.name(context, g.isEmpty ? null : g),
                        style: g == 'total' ? const TextStyle(fontWeight: FontWeight.w700) : null,
                      ),
                    ),
                    SizedBox(width: 130, child: Text(money(context, x, currency), textAlign: TextAlign.right)),
                    SizedBox(width: 130, child: Text(money(context, y, currency), textAlign: TextAlign.right)),
                    SizedBox(
                      width: 130,
                      child: Text(
                        '${x - y >= 0 ? '+' : ''}${money(context, x - y, currency)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(width: 260, child: g == 'total' ? const SizedBox() : _DivergingBar((x - y) / maxDiff)),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Centered bar: right/red = spent more, left/blue = spent less.
class _DivergingBar extends StatelessWidget {
  const _DivergingBar(this.value);

  /// -1..1
  final double value;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final half = c.maxWidth / 2;
      final w = half * value.abs().clamp(0, 1);
      return SizedBox(
        height: 12,
        child: Stack(
          children: [
            Positioned(
              left: half - 0.5,
              top: 0,
              bottom: 0,
              child: Container(width: 1, color: Theme.of(context).colorScheme.outline),
            ),
            Positioned(
              left: value >= 0 ? half + 1 : half - w - 1,
              top: 1,
              bottom: 1,
              child: Container(
                width: w,
                decoration: BoxDecoration(
                  color: value >= 0 ? chartRed : chartBlue,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
