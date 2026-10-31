// Statistics → Categories tab: spending per group and category.

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final index = context.watch<CategoryIndex>();
    final d = widget.d;
    final groups = breakdown(d.lines, d.from, d.to, keyOf: (x) => groupKey(x.categoryId), labelOf: (k) => k);
    final cats = breakdown(d.lines, d.from, d.to, keyOf: (x) => x.categoryId ?? '', labelOf: (k) => k);
    final grand = groups.fold(0, (s, g) => s + g.total);
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
      return InkWell(
        onTap: isGroup
            ? () => setState(() => open ? _open.remove(b.key) : _open.add(b.key))
            : () => showCategoryLines(context, d, categoryId: b.key, title: index.name(context, key)),
        child: Padding(
          padding: EdgeInsets.fromLTRB(isGroup ? 16 : 48, 6, 16, 6),
          child: Row(
            children: [
              if (isGroup)
                Icon(open ? Icons.expand_more : Icons.chevron_right, size: 18)
              else
                const SizedBox(width: 18),
              CircleAvatar(radius: 5, backgroundColor: groupColor(context, key)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  // A line filed under the group itself (e.g. from a Bonidollars hint).
                  !isGroup && key != null && !key.contains('.')
                      ? '${index.name(context, key)} · ${l.unspecified}'
                      : index.name(context, key),
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
              SizedBox(
                width: 70,
                child: Text('${(b.shareOf(grand) * 100).toStringAsFixed(1)} %', textAlign: TextAlign.right),
              ),
              SizedBox(
                width: 100,
                child: Align(alignment: Alignment.centerRight, child: ChangeBadge(d.changeOf(b))),
              ),
              SizedBox(
                width: 44,
                child: b.key == d.focus
                    ? null
                    : IconButton(
                        tooltip: l.analyzeOnly(index.name(context, key)),
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
              header(l.statVsPrevious, sort: _Sort.change, width: 100),
              const SizedBox(width: 44),
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
