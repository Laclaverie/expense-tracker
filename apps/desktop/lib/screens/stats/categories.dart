// Statistics → Categories tab: spending per group and category, with a share
// of the whole and, when some categories are hidden from shares (rent, taxes),
// a share of what remains.

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
  const CategoriesTab(this.d, {super.key, required this.onFocus, required this.onNarrow});

  final StatsData d;

  /// Narrows the page to a group or category and shows its trends.
  final ValueChanged<String> onFocus;

  /// Narrows the page to a group (null: everything), staying on this tab.
  final ValueChanged<String?> onNarrow;

  @override
  State<CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends State<CategoriesTab> {
  final _open = <String>{};
  _Sort _sort = _Sort.total;

  /// Row under the mouse: its buttons show.
  String? _hovered;

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

    // Hidden from the second share column and the bar (never from totals).
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
    // Hidden ids that have spending here, for the summary line.
    final hiddenNames = [
      for (final r in index.rows)
        if (r.excludedFromShare && hidden.any((c) => c.key == r.id || groupKey(c.key) == r.id))
          index.name(context, r.id),
    ];
    final split = hiddenNames.isNotEmpty;

    // The bar: groups, or the categories of the group the page is narrowed to.
    final focus = d.focus;
    final inGroup = focus != null && focus.isNotEmpty && !focus.contains('.');
    final List<_Part> parts;
    if (inGroup) {
      final base = groupColor(context, focus);
      final surface = Theme.of(context).colorScheme.surface;
      final mine = [
        for (final c in cats)
          if (groupKey(c.key) == focus && !isExcludedFromShare(c.key, excluded) && c.total > 0) c,
      ]..sort((a, b) => b.total.compareTo(a.total));
      parts = [
        for (final (i, c) in mine.indexed)
          _Part(
            c.key,
            c.key == focus ? '${index.name(context, c.key)} · ${l.unspecified}' : index.name(context, c.key),
            c.total,
            // One group, one hue: lighter for smaller categories.
            Color.lerp(base, surface, (i * 0.15).clamp(0, 0.6))!,
          ),
      ];
    } else {
      parts = [
        for (final MapEntry(:key, :value) in kept.entries)
          if (value > 0) _Part(key, index.name(context, key.isEmpty ? null : key), value, groupColor(context, key)),
      ]..sort((a, b) => b.cents.compareTo(a.cents));
    }

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
      // A category inside a hidden group follows its group.
      final byGroup = !isGroup && key != null && excluded.contains(groupKey(key)) && !excluded.contains(key);
      final keptTotal = isGroup ? (kept[b.key] ?? 0) : b.total;
      final name = index.name(context, key);
      final hovered = _hovered == '$isGroup${b.key}';
      final change = d.changeOf(b);
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
              width: 130,
              child: Text(out || keptGrand <= 0 ? '—' : percent(keptTotal / keptGrand), textAlign: TextAlign.right),
            ),
          SizedBox(
            width: 100,
            child: Align(
              alignment: Alignment.centerRight,
              child: change != null
                  ? ChangeBadge(change)
                  // No comparison while a month of either period lacks a statement.
                  : d.comparable
                  ? const Text('—')
                  : Tooltip(message: l.changeNeedsComplete, child: const Text('—')),
            ),
          ),
        ],
      );
      // Buttons show on hover; a hidden row keeps its eye, the way back.
      Widget onHover(Widget child, {bool always = false}) => Opacity(opacity: hovered || always ? 1 : 0, child: child);
      return MouseRegion(
        onEnter: (_) => setState(() => _hovered = '$isGroup${b.key}'),
        onExit: (_) => setState(() => _hovered = _hovered == '$isGroup${b.key}' ? null : _hovered),
        child: InkWell(
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
                      : onHover(
                          always: out,
                          IconButton(
                            tooltip: out ? l.includeInShare(name) : l.excludeFromShare(name),
                            icon: Icon(out ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                            onPressed: () => _setExcluded(b.key, !out),
                          ),
                        ),
                ),
                SizedBox(
                  width: 44,
                  child: b.key == d.focus
                      ? null
                      : onHover(
                          IconButton(
                            tooltip: l.analyzeOnly(name),
                            icon: const Icon(Icons.insights, size: 18),
                            onPressed: () => widget.onFocus(b.key),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        if (split)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.visibility_off_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.sharesWithout(hiddenNames.join(', '), money(context, d.averageOf(hiddenMonthly), d.currency)),
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
        if (parts.length > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 16, 8),
            child: Row(
              children: [
                if (inGroup) ...[
                  TextButton.icon(
                    onPressed: () => widget.onNarrow(null),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: Text(l.allGroups),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: _ShareBar(
                    parts,
                    currency: d.currency,
                    other: l.other,
                    otherColor: otherColor(context),
                    onTap: inGroup
                        ? null
                        : (group) {
                            setState(() => _open.add(group));
                            widget.onNarrow(group);
                          },
                  ),
                ),
              ],
            ),
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
              if (split) header(l.shareKept, width: 130),
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

/// One segment of the share bar.
class _Part {
  const _Part(this.key, this.label, this.cents, this.color);

  final String key;
  final String label;
  final int cents;
  final Color color;
}

/// One 100 % bar of [parts] (largest first). Parts under 3 % are merged into
/// one "Others" segment; names show inside wide segments, every part in its
/// tooltip. Tapping a segment calls [onTap] with its key.
class _ShareBar extends StatelessWidget {
  const _ShareBar(this.parts, {required this.currency, required this.other, required this.otherColor, this.onTap});

  final List<_Part> parts;
  final String currency;
  final String other;
  final Color otherColor;
  final ValueChanged<String>? onTap;

  static const _merge = 0.03;
  static const _label = 0.08;

  @override
  Widget build(BuildContext context) {
    final total = parts.fold(0, (s, p) => s + p.cents);
    if (total <= 0) return const SizedBox.shrink();
    String pct(int cents) => '${(cents / total * 100).toStringAsFixed(1)} %';
    final small = [
      for (final p in parts)
        if (p.cents / total < _merge) p,
    ];
    // Merging a single part would only rename it.
    final merged = small.length > 1;
    final segments = [
      for (final p in parts)
        if (!merged || !small.contains(p)) (p, '${p.label} · ${money(context, p.cents, currency)} · ${pct(p.cents)}'),
      if (merged)
        (
          _Part('', other, small.fold(0, (s, p) => s + p.cents), otherColor),
          [for (final p in small) '${p.label} · ${pct(p.cents)}'].join('\n'),
        ),
    ];
    final textStyle = Theme.of(context).textTheme.labelSmall;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 24,
        child: Row(
          children: [
            for (final (i, (p, tip)) in segments.indexed)
              Expanded(
                flex: p.cents,
                child: Tooltip(
                  message: tip,
                  child: MouseRegion(
                    cursor: onTap != null && p.key.isNotEmpty ? SystemMouseCursors.click : MouseCursor.defer,
                    child: GestureDetector(
                      onTap: onTap != null && p.key.isNotEmpty ? () => onTap!(p.key) : null,
                      child: Container(
                        // A thin gap tells apart neighbours sharing a palette slot.
                        margin: EdgeInsets.only(left: i == 0 ? 0 : 1),
                        color: p.color,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: p.cents / total < _label
                            ? null
                            : Text(
                                '${p.label} ${(p.cents / total * 100).round()} %',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textStyle?.copyWith(
                                  color: ThemeData.estimateBrightnessForColor(p.color) == Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
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
