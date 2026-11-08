import 'package:core/core.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storage/storage.dart';

import '../../l10n/app_localizations.dart';
import '../../style.dart';

/// Spending per group (donut) and per category (list), as the desktop's Categories tab: shares leave out the
/// categories hidden from shares (rent, taxes), totals never do. Tap a row for its merchants.
class CategoriesView extends StatefulWidget {
  const CategoriesView(this.d, {super.key, this.notices = const []});

  final StatsData d;
  final List<Widget> notices;

  @override
  State<CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<CategoriesView> {
  final _open = <String>{};

  static const _merge = 0.03;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final index = context.watch<CategoryIndex>();
    final d = widget.d;
    final groups = breakdown(
      d.lines,
      d.from,
      d.to,
      keyOf: (x) => groupKey(x.categoryId),
      labelOf: (k) => k,
    ).where((g) => g.total != 0).toList();
    final cats = breakdown(d.lines, d.from, d.to, keyOf: (x) => x.categoryId ?? '', labelOf: (k) => k);
    final excluded = {
      for (final r in index.rows)
        if (r.excludedFromShare) r.id,
    };
    final kept = keptByGroup(cats, excluded);
    final keptGrand = kept.values.fold(0, (s, v) => s + v);
    final hidden = [
      for (final c in cats)
        if (isExcludedFromShare(c.key, excluded)) c,
    ];
    final hiddenMonthly = List.filled(d.months.length, 0);
    for (final c in hidden) {
      for (final (i, v) in c.monthly.indexed) {
        hiddenMonthly[i] += v;
      }
    }
    final hiddenNames = [
      for (final r in index.rows)
        if (r.excludedFromShare && hidden.any((c) => c.key == r.id || groupKey(c.key) == r.id))
          index.name(context, r.id),
    ];

    String percent(double share) => '${(share * 100).toStringAsFixed(1)} %';
    final muted = Theme.of(context).textTheme.bodySmall;

    Widget row(Breakdown b, {required bool isGroup}) {
      final key = b.key.isEmpty ? null : b.key;
      final out = isExcludedFromShare(key, excluded);
      final keptTotal = isGroup ? (kept[b.key] ?? 0) : b.total;
      final name = index.name(context, key);
      final label = !isGroup && key != null && !key.contains('.') ? '$name · ${l.unspecified}' : name;
      final open = _open.contains(b.key);
      final tile = ListTile(
        dense: !isGroup,
        contentPadding: EdgeInsets.only(left: isGroup ? 16 : 40, right: 8),
        leading: CircleAvatar(radius: 6, backgroundColor: groupColor(context, key)),
        minLeadingWidth: 12,
        title: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: isGroup ? const TextStyle(fontWeight: FontWeight.w600) : null,
        ),
        subtitle: Text(
          '${l.perMonth(money(context, d.averageOf(b.monthly), d.currency))} · '
          '${l.share} ${out || keptGrand <= 0 ? '—' : percent(keptTotal / keptGrand)}',
          style: muted,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(money(context, b.total, d.currency)),
            if (isGroup)
              IconButton(
                icon: Icon(open ? Icons.expand_less : Icons.expand_more),
                onPressed: () => setState(() => open ? _open.remove(b.key) : _open.add(b.key)),
              ),
          ],
        ),
        onTap: () => showMerchantsSheet(context, d, b.key, label),
      );
      return out ? Opacity(opacity: 0.5, child: tile) : tile;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      children: [
        ...widget.notices,
        if (groups.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l.noSpending, textAlign: TextAlign.center),
          )
        else ...[
          if (keptGrand > 0)
            _Donut(
              kept: kept,
              index: index,
              total: keptGrand,
              currency: d.currency,
              withoutHidden: hiddenNames.isNotEmpty,
            ),
          if (hiddenNames.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Row(
                children: [
                  const Icon(Icons.visibility_off_outlined, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.sharesWithout(hiddenNames.join(', '), money(context, d.averageOf(hiddenMonthly), d.currency)),
                      style: muted,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          for (final g in groups) ...[
            row(g, isGroup: true),
            if (_open.contains(g.key))
              for (final c in cats.where((c) => groupKey(c.key) == g.key && c.total != 0)) row(c, isGroup: false),
            const Divider(height: 1),
          ],
        ],
      ],
    );
  }
}

/// Donut of the groups' kept spending; parts under 3 % merge into "Other".
class _Donut extends StatelessWidget {
  const _Donut({
    required this.kept,
    required this.index,
    required this.total,
    required this.currency,
    required this.withoutHidden,
  });

  /// Some categories are hidden from shares: the center total leaves them out.
  final bool withoutHidden;
  final Map<String, int> kept;
  final CategoryIndex index;
  final int total;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final parts = kept.entries.where((e) => e.value > 0).toList()..sort((a, b) => b.value.compareTo(a.value));
    final small = parts.where((e) => e.value / total < _CategoriesViewState._merge).toList();
    final merged = small.length > 1;
    final shown = [
      for (final e in parts)
        if (!merged || !small.contains(e))
          (
            index.name(context, e.key.isEmpty ? null : e.key),
            e.value,
            groupColor(context, e.key.isEmpty ? null : e.key),
          ),
      if (merged) (l.other, small.fold(0, (s, e) => s + e.value), otherColor(context)),
    ];
    final surface = Theme.of(context).colorScheme.surface;
    final t = Theme.of(context).textTheme;
    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              centerSpaceRadius: 62,
              sectionsSpace: 1,
              sections: [
                for (final (_, cents, color) in shown)
                  PieChartSectionData(
                    value: cents.toDouble(),
                    color: color,
                    radius: 30,
                    showTitle: false,
                    borderSide: BorderSide(color: surface, width: 1),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 110,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(money(context, total, currency), style: t.titleMedium),
                ),
                // The rows below count hidden categories; the center doesn't.
                if (withoutHidden) Text(l.withoutHidden, style: t.bodySmall, textAlign: TextAlign.center, maxLines: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Merchants of a group or category over the range (people left out, as on the desktop).
void showMerchantsSheet(BuildContext context, StatsData d, String key, String title) {
  final l = AppLocalizations.of(context);
  final names = <String, String>{};
  final rows = breakdown(
    [
      for (final x in d.lines)
        if (inFocus(x.categoryId, key)) x,
    ],
    d.from,
    d.to,
    keyOf: (x) {
      if (x.isPerson || x.merchantId == null) return null;
      names['${x.merchantId}'] = x.merchant;
      return '${x.merchantId}';
    },
    labelOf: (k) => names[k] ?? k,
  ).where((r) => r.total > 0).toList();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(l.merchantsOf(title), style: Theme.of(context).textTheme.titleMedium),
          ),
          if (rows.isEmpty) Padding(padding: const EdgeInsets.all(16), child: Text(l.noMerchants)),
          for (final r in rows)
            ListTile(
              title: Text(r.label, overflow: TextOverflow.ellipsis),
              subtitle: Text(l.visits(r.count)),
              trailing: Text(money(context, r.total, d.currency)),
            ),
        ],
      ),
    ),
  );
}
