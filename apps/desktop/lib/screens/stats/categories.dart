// Statistics → Categories tab: spending per group and category, with a share
// of the whole and, when some categories are left out (rent, taxes), a share
// of what remains.

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storage/storage.dart';

import '../../l10n/app_localizations.dart';
import '../../style.dart';
import '../../widgets/sparkline.dart';
import 'charts.dart';
import 'data.dart';
import 'widgets.dart';

enum _Sort { total, change, average }

class CategoriesTab extends StatefulWidget {
  const CategoriesTab(this.d, {super.key, required this.onFocus});

  final StatsData d;

  /// Narrows the page to a group or category.
  final ValueChanged<String> onFocus;

  @override
  State<CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends State<CategoriesTab> {
  final _open = <String>{};
  _Sort _sort = _Sort.total;

  List<Breakdown> _sorted(List<Breakdown> rows) => [...rows]
    ..sort(
      (a, b) => switch (_sort) {
        _Sort.total => b.total.compareTo(a.total),
        _Sort.average => widget.d.averageOf(b.monthly).compareTo(widget.d.averageOf(a.monthly)),
        _Sort.change => (widget.d.changeOf(b) ?? -1).compareTo(widget.d.changeOf(a) ?? -1),
      },
    );

  void _setExcluded(String id, bool excluded) => context.read<ExpenseRepository>().setExcludedFromShare(id, excluded);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final index = context.watch<CategoryIndex>();
    final d = widget.d;
    final groups = breakdown(d.lines, d.from, d.to, keyOf: (x) => groupKey(x.categoryId), labelOf: (k) => k);
    final cats = breakdown(d.lines, d.from, d.to, keyOf: (x) => x.categoryId ?? '', labelOf: (k) => k);
    final grand = groups.fold(0, (s, g) => s + g.total);

    // Left out of the second share column and the bar (never of totals).
    final excluded = {
      for (final r in index.rows)
        if (r.excludedFromShare) r.id,
    };
    final kept = keptByGroup(cats, excluded);
    final keptGrand = kept.values.fold(0, (s, v) => s + v);
    final shown = [
      for (final c in cats)
        if (isExcludedFromShare(c.key, excluded)) c,
    ];
    final excludedMonthly = List.filled(d.months.length, 0);
    for (final c in shown) {
      for (final (i, v) in c.monthly.indexed) {
        excludedMonthly[i] += v;
      }
    }
    // Excluded ids that have spending here, groups first, for the summary line.
    final excludedNames = [
      for (final r in index.rows)
        if (r.excludedFromShare && shown.any((c) => c.key == r.id || groupKey(c.key) == r.id))
          index.name(context, r.id),
    ];
    final split = excludedNames.isNotEmpty;

    String percent(double share) => '${(share * 100).toStringAsFixed(1)} %';

    Widget header(String text, {_Sort? sort, double? width, TextAlign align = TextAlign.right}) {
      final label = Text(
        text + (sort != null && sort == _sort ? ' ↓' : ''),
        style: Theme.of(context).textTheme.labelMedium,
        textAlign: align,
      );
      final child = sort == null ? label : InkWell(onTap: () => setState(() => _sort = sort), child: label);
      return width == null ? Expanded(child: child) : SizedBox(width: width, child: child);
    }

    Widget row(Breakdown b, {required bool isGroup}) {
      final key = b.key.isEmpty ? null : b.key;
      final open = _open.contains(b.key);
      final out = isExcludedFromShare(key, excluded);
      // A category inside an excluded group follows its group.
      final byGroup = !isGroup && key != null && excluded.contains(groupKey(key)) && !excluded.contains(key);
      final keptTotal = isGroup ? (kept[b.key] ?? 0) : b.total;
      final name = index.name(context, key);
      final content = Row(
        children: [
          if (isGroup) Icon(open ? Icons.expand_more : Icons.chevron_right, size: 18) else const SizedBox(width: 18),
          CircleAvatar(radius: 5, backgroundColor: groupColor(context, key)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              // A line filed under the group itself (e.g. from a Bonidollars hint).
              !isGroup && key != null && !key.contains('.') ? '$name · ${l.unspecified}' : name,
              style: isGroup ? const TextStyle(fontWeight: FontWeight.w600) : null,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Sparkline(b.monthly, color: groupColor(context, key)),
          const SizedBox(width: 16),
          SizedBox(width: 120, child: Text(money(context, b.total, d.currency), textAlign: TextAlign.right)),
          SizedBox(
            width: 120,
            child: Text(money(context, d.averageOf(b.monthly), d.currency), textAlign: TextAlign.right),
          ),
          SizedBox(width: 70, child: Text(percent(b.shareOf(grand)), textAlign: TextAlign.right)),
          if (split)
            SizedBox(
              width: 100,
              child: Text(out || keptGrand <= 0 ? '—' : percent(keptTotal / keptGrand), textAlign: TextAlign.right),
            ),
          SizedBox(
            width: 100,
            child: Align(alignment: Alignment.centerRight, child: ChangeBadge(d.changeOf(b))),
          ),
        ],
      );
      return InkWell(
        onTap: isGroup
            ? () => setState(() => open ? _open.remove(b.key) : _open.add(b.key))
            : () => showCategoryLines(context, d, categoryId: b.key, title: name),
        child: Padding(
          padding: EdgeInsets.fromLTRB(isGroup ? 16 : 48, 6, 16, 6),
          child: Row(
            children: [
              Expanded(child: out ? Opacity(opacity: 0.45, child: content) : content),
              SizedBox(
                width: 40,
                child: key == null || byGroup
                    ? null
                    : IconButton(
                        tooltip: out ? l.includeInShare(name) : l.excludeFromShare(name),
                        icon: Icon(out ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                        onPressed: () => _setExcluded(b.key, !out),
                      ),
              ),
              SizedBox(
                width: 44,
                child: b.key == d.focus
                    ? null
                    : IconButton(
                        tooltip: l.analyzeOnly(name),
                        icon: const Icon(Icons.insights, size: 18),
                        onPressed: () => widget.onFocus(b.key),
                      ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (split)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.visibility_off_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.sharesWithout(excludedNames.join(', '), money(context, d.averageOf(excludedMonthly), d.currency)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    for (final id in excluded) {
                      _setExcluded(id, false);
                    }
                  },
                  child: Text(l.includeAllInShare),
                ),
              ],
            ),
          ),
        if (kept.length > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: _ShareBar(kept, currency: d.currency),
          ),
        Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          padding: const EdgeInsets.fromLTRB(42, 8, 16, 8),
          child: Row(
            children: [
              header(l.colCategory, align: TextAlign.left),
              SizedBox(width: 112, child: Text(l.trend, style: Theme.of(context).textTheme.labelMedium)),
              header(l.statTotal, sort: _Sort.total, width: 120),
              header(l.statAverage, sort: _Sort.average, width: 120),
              header(l.share, width: 70),
              if (split) header(l.shareKept, width: 100),
              header(l.statVsPrevious, sort: _Sort.change, width: 100),
              const SizedBox(width: 84),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              for (final g in _sorted(groups)) ...[
                row(g, isGroup: true),
                if (_open.contains(g.key))
                  for (final c in _sorted(cats.where((c) => groupKey(c.key) == g.key).toList())) row(c, isGroup: false),
                const Divider(height: 1),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One 100 % bar: each group's part of the spending left after exclusions,
/// largest first. Names inside wide parts, every part in its tooltip.
class _ShareBar extends StatelessWidget {
  const _ShareBar(this.kept, {required this.currency});

  /// Spending per group (excluded categories already left out).
  final Map<String, int> kept;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final index = context.watch<CategoryIndex>();
    final parts = kept.entries.where((e) => e.value > 0).toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = parts.fold(0, (s, e) => s + e.value);
    if (total <= 0) return const SizedBox.shrink();
    final small = Theme.of(context).textTheme.labelSmall;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 24,
        child: Row(
          children: [
            for (final (i, e) in parts.indexed)
              Expanded(
                flex: e.value,
                child: Tooltip(
                  message:
                      '${index.name(context, e.key.isEmpty ? null : e.key)} · ${money(context, e.value, currency)}'
                      ' · ${(e.value / total * 100).toStringAsFixed(1)} %',
                  child: Container(
                    // A thin gap tells apart neighbours sharing a palette slot.
                    margin: EdgeInsets.only(left: i == 0 ? 0 : 1),
                    color: groupColor(context, e.key.isEmpty ? null : e.key),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: e.value / total < 0.08
                        ? null
                        : Text(
                            '${index.name(context, e.key.isEmpty ? null : e.key)} '
                            '${(e.value / total * 100).round()} %',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: small?.copyWith(
                              color:
                                  ThemeData.estimateBrightnessForColor(
                                        groupColor(context, e.key.isEmpty ? null : e.key),
                                      ) ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
