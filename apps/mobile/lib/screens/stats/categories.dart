import 'dart:math';

import 'package:core/core.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storage/storage.dart';

import '../../keyed_stream.dart';
import '../../l10n/app_localizations.dart';
import '../../style.dart';
import '../transactions.dart';

/// Spending per group (donut) and per category (list), as the desktop's Categories tab: shares leave out the
/// categories hidden from shares (rent, taxes), totals never do. Tap a slice or a group to focus on it (its
/// categories), then a slice or a row for its merchants.
class CategoriesView extends StatefulWidget {
  const CategoriesView(this.d, {super.key, this.notices = const [], this.focus, required this.onFocus});

  final StatsData d;
  final List<Widget> notices;

  /// The group the view is narrowed to ('' = uncategorized), as the desktop's focus. Held by the page so it
  /// survives a range change.
  final String? focus;
  final ValueChanged<String?> onFocus;

  @override
  State<CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<CategoriesView> {
  /// Back to the top when the focus changes: the chip and the new donut are there.
  final _scroll = ScrollController();

  /// A post-frame "back to every group" is already queued.
  bool _clearing = false;

  @override
  void didUpdateWidget(CategoriesView old) {
    super.didUpdateWidget(old);
    if (old.focus != widget.focus) {
      _clearing = false;
      // Not during this build: moving the list notifies its scroll listeners.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final index = context.watch<CategoryIndex>();
    final all = widget.d;
    final focus = widget.focus;
    // A range without this group's spending: back to every group (once).
    if (focus != null && !_clearing && !all.inRange.any((x) => inFocus(x.categoryId, focus))) {
      _clearing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.focus == focus) widget.onFocus(null);
      });
    }
    final d = focus == null
        ? all
        : StatsData(
            all.scope,
            [
              for (final x in all.lines)
                if (inFocus(x.categoryId, focus)) x,
            ],
            all.from,
            all.to,
            all.statuses,
            all.previousComplete,
            focus: focus,
          );
    final cats = breakdown(
      d.lines,
      d.from,
      d.to,
      keyOf: (x) => x.categoryId ?? '',
      labelOf: (k) => k,
    ).where((c) => c.total != 0).toList();
    final rows = focus == null
        ? breakdown(
            d.lines,
            d.from,
            d.to,
            keyOf: (x) => groupKey(x.categoryId),
            labelOf: (k) => k,
          ).where((g) => g.total != 0).toList()
        : cats;
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

    String nameOf(String key, {required bool isGroup}) {
      final name = index.name(context, key.isEmpty ? null : key);
      // A line filed under the group itself (e.g. from a reward hint).
      return !isGroup && key.isNotEmpty && !key.contains('.') ? '$name · ${l.unspecified}' : name;
    }

    // The donut: groups, or the categories of the focused group (one hue, lighter for smaller ones).
    final List<DonutPart> parts;
    if (focus == null) {
      parts = [
        for (final MapEntry(:key, :value) in kept.entries)
          if (value > 0) DonutPart(key, nameOf(key, isGroup: true), value, groupColor(context, key)),
      ]..sort((a, b) => b.cents.compareTo(a.cents));
    } else {
      final base = groupColor(context, focus.isEmpty ? null : focus);
      final surface = Theme.of(context).colorScheme.surface;
      final mine = [
        for (final c in cats)
          if (!isExcludedFromShare(c.key, excluded) && c.total > 0) c,
      ]..sort((a, b) => b.total.compareTo(a.total));
      parts = [
        for (final (i, c) in mine.indexed)
          DonutPart(
            c.key,
            nameOf(c.key, isGroup: false),
            c.total,
            Color.lerp(base, surface, (i * 0.15).clamp(0, 0.6))!,
          ),
      ];
    }

    void open(String key) {
      if (focus == null) {
        widget.onFocus(key);
      } else {
        showMerchantsSheet(context, d, key, nameOf(key, isGroup: false));
      }
    }

    final muted = Theme.of(context).textTheme.bodySmall;

    Widget row(Breakdown b) {
      final isGroup = focus == null;
      final key = b.key.isEmpty ? null : b.key;
      final out = isExcludedFromShare(key, excluded);
      final keptTotal = isGroup ? (kept[b.key] ?? 0) : b.total;
      final share = out || keptGrand <= 0 ? '—' : '${(keptTotal / keptGrand * 100).toStringAsFixed(1)} %';
      final tile = ListTile(
        contentPadding: const EdgeInsets.only(left: 16, right: 8),
        leading: CircleAvatar(
          radius: 6,
          backgroundColor: parts.where((p) => p.key == b.key).firstOrNull?.color ?? groupColor(context, key),
        ),
        minLeadingWidth: 12,
        title: Text(
          nameOf(b.key, isGroup: isGroup),
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        // Short enough for 360 dp: monthly average, then the share.
        subtitle: Text(
          '${l.perMonthShort(money(context, d.averageOf(b.monthly), d.currency))} · $share',
          style: muted,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Text(money(context, b.total, d.currency)), const Icon(Icons.chevron_right)],
        ),
        onTap: () => open(b.key),
      );
      return out ? Opacity(opacity: 0.5, child: tile) : tile;
    }

    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      children: [
        ...widget.notices,
        if (focus != null)
          Align(
            alignment: Alignment.centerLeft,
            child: InputChip(
              avatar: CircleAvatar(backgroundColor: groupColor(context, focus.isEmpty ? null : focus)),
              label: Text(nameOf(focus, isGroup: true)),
              onDeleted: () => widget.onFocus(null),
              onPressed: () => widget.onFocus(null),
              deleteButtonTooltipMessage: l.allGroups,
            ),
          ),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l.noSpending, textAlign: TextAlign.center),
          )
        else ...[
          if (keptGrand > 0 && parts.isNotEmpty)
            CategoryDonut(
              parts: parts,
              total: parts.fold(0, (s, p) => s + p.cents),
              currency: d.currency,
              withoutHidden: hiddenNames.isNotEmpty,
              onTap: open,
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
          for (final r in rows) ...[row(r), const Divider(height: 1)],
        ],
      ],
    );
  }
}

/// One slice of the donut: a group or a category.
class DonutPart {
  const DonutPart(this.key, this.label, this.cents, this.color);

  final String key;
  final String label;
  final int cents;
  final Color color;
}

/// Donut of [parts] (largest first, clockwise from 3 o'clock); parts under 3 % merge into "Other". A slice's
/// name and share sit inside it when they fit whole, else in a column left or right of the ring with a leader
/// line. Tapping a slice calls [onTap] with its key ("Other" does nothing).
class CategoryDonut extends StatelessWidget {
  const CategoryDonut({
    super.key,
    required this.parts,
    required this.total,
    required this.currency,
    required this.withoutHidden,
    required this.onTap,
  });

  final List<DonutPart> parts;
  final int total;
  final String currency;

  /// Some categories are hidden from shares: the center total leaves them out.
  final bool withoutHidden;
  final ValueChanged<String> onTap;

  static const _merge = 0.03;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final small = parts.where((p) => p.cents / total < _merge).toList();
    final merged = small.length > 1;
    final shown = [
      for (final p in parts)
        if (!merged || !small.contains(p)) p,
      if (merged) DonutPart(otherKey, l.other, small.fold(0, (s, p) => s + p.cents), otherColor(context)),
    ];
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall!.copyWith(height: 1.15);
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        final g = DonutGeometry.compute(shown, total, box.maxWidth, style, scaler);
        final surface = theme.colorScheme.surface;
        return SizedBox(
          height: g.height,
          child: Stack(
            children: [
              Positioned(
                left: g.center.dx - g.radius,
                top: g.center.dy - g.radius,
                width: g.radius * 2,
                height: g.radius * 2,
                child: PieChart(
                  PieChartData(
                    startDegreeOffset: 0,
                    centerSpaceRadius: g.hole,
                    sectionsSpace: 1,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        if (event is! FlTapUpEvent) return;
                        final i = response?.touchedSection?.touchedSectionIndex ?? -1;
                        if (i < 0 || i >= shown.length || shown[i].key == otherKey) return;
                        onTap(shown[i].key);
                      },
                    ),
                    sections: [
                      for (final p in shown)
                        PieChartSectionData(
                          value: p.cents.toDouble(),
                          color: p.color,
                          radius: g.radius - g.hole,
                          showTitle: false,
                          borderSide: BorderSide(color: surface, width: 1),
                        ),
                    ],
                  ),
                ),
              ),
              // Labels and leaders never take a tap: it goes to the slice under them.
              Positioned.fill(
                child: IgnorePointer(child: CustomPaint(painter: _Leaders(g, theme.colorScheme.onSurfaceVariant))),
              ),
              for (final s in g.slices)
                if (s.inside)
                  Positioned.fromRect(
                    key: ValueKey('donut-in-${s.part.key}'),
                    rect: s.labelRect,
                    child: IgnorePointer(child: _InsideLabel(s.part.label, s.percent, style, _onColor(s.part.color))),
                  )
                else
                  Positioned.fromRect(
                    key: ValueKey('donut-out-${s.part.key}'),
                    rect: s.labelRect,
                    child: IgnorePointer(
                      child: _OutsideLabel(s.part.label, s.percent, style, oneLine: s.oneLine, right: s.right),
                    ),
                  ),
              Positioned(
                left: g.center.dx - g.hole * 0.85,
                top: g.center.dy - g.hole,
                width: g.hole * 1.7,
                height: g.hole * 2,
                child: IgnorePointer(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(money(context, total, currency), style: theme.textTheme.titleSmall),
                      ),
                      // The rows below count hidden categories; the center doesn't.
                      if (withoutHidden)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(l.withoutHidden, style: theme.textTheme.bodySmall),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Key of the merged "Other" slice (no group has it).
  static const otherKey = '\u0000other';

  static Color _onColor(Color c) =>
      ThemeData.estimateBrightnessForColor(c) == Brightness.dark ? Colors.white : Colors.black;
}

/// Where the ring and every label go, for a width. Angles in radians, clockwise from 3 o'clock (as the chart).
class DonutGeometry {
  DonutGeometry._(this.height, this.center, this.radius, this.hole, this.slices);

  final double height;
  final Offset center;
  final double radius;
  final double hole;
  final List<DonutSlice> slices;

  /// Space between two labels of a column, and around the whole.
  static const _gap = 4.0, _pad = 6.0;

  static DonutGeometry compute(List<DonutPart> parts, int total, double width, TextStyle style, TextScaler scaler) {
    // Two label columns (about a quarter of the width each), the ring as large as the rest allows; a thick ring
    // leaves room for labels inside.
    final column = (width * 0.23).clamp(64.0, 120.0);
    final radius = min((width - 2 * column) / 2 - 8, 170.0);
    final hole = radius * 0.42;
    double measure(String s) => (TextPainter(
      text: TextSpan(text: s, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout()).width;
    final line = (TextPainter(
      text: TextSpan(text: 'Ag', style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout()).height;

    var start = 0.0;
    final raw = <(DonutPart, double, double, String)>[];
    for (final p in parts) {
      final sweep = p.cents / total * 2 * pi;
      raw.add((p, start, sweep, '${(p.cents / total * 100).round()} %'));
      start += sweep;
    }

    // Inside: name and share on two lines, whole words only, every corner inside the slice.
    // The middle of the ring at angle [at]: where an inside label is centered.
    final r = (hole + radius) / 2;
    bool fitsAt(double at, double from, double sweep, double w, double h) {
      final c = Offset(r * cos(at), r * sin(at));
      for (final dx in [-w / 2, w / 2]) {
        for (final dy in [-h / 2, h / 2]) {
          final p = c + Offset(dx, dy);
          final d = p.distance;
          if (d < hole + 1 || d > radius - 1) return false;
          if (sweep < 2 * pi - 1e-6) {
            final a = (atan2(p.dy, p.dx) - from) % (2 * pi);
            if (a > sweep) return false;
          }
        }
      }
      return true;
    }

    // The slice's middle first, then other angles of a wide slice (nearest the middle first): a big slice may
    // only have room where the ring runs across the label's short side.
    double? insideAngle(double from, double sweep, double w, double h) {
      final mid = from + sweep / 2;
      final tries = [for (var k = 1; k < 12; k++) from + sweep * k / 12]
        ..sort((a, b) => (a - mid).abs().compareTo((b - mid).abs()));
      for (final at in [mid, ...tries]) {
        if (fitsAt(at, from, sweep, w, h)) return at;
      }
      return null;
    }

    final slices = <DonutSlice>[];
    final outside = <(DonutPart, double, String, bool, double, double)>[]; // part, mid, pct, oneLine, h, w
    for (final (p, from, sweep, pct) in raw) {
      final w = max(measure(p.label), measure(pct)) + 4;
      final h = line * 2;
      final mid = from + sweep / 2;
      final at = insideAngle(from, sweep, w, h);
      if (at != null) {
        slices.add(
          DonutSlice(
            p,
            pct,
            at,
            true,
            Rect.zero,
            oneLine: false,
            right: true,
            offset: Offset(r * cos(at), r * sin(at)),
            size: Size(w, h),
          ),
        );
      } else {
        final oneLine = measure('${p.label} $pct') <= column;
        outside.add((p, mid, pct, oneLine, oneLine ? line : line * 2, column));
      }
    }

    // Height: the ring, or the taller label column.
    double columnHeight(bool right) {
      final hs = [
        for (final o in outside)
          if ((cos(o.$2) >= 0) == right) o.$5,
      ];
      return hs.isEmpty ? 0 : hs.fold(0.0, (s, h) => s + h) + _gap * (hs.length - 1);
    }

    final height = max(2 * radius + 2 * _pad, max(columnHeight(true), columnHeight(false)) + 2 * _pad);
    final center = Offset(width / 2, height / 2);

    for (final right in [true, false]) {
      final mine = [
        for (final o in outside)
          if ((cos(o.$2) >= 0) == right) o,
      ];
      // Each label wants the height of its slice's middle; sorted, then pushed apart, then kept inside.
      final want = [for (final o in mine) center.dy + (radius + 6) * sin(o.$2) - o.$5 / 2];
      final order = List.generate(mine.length, (i) => i)..sort((a, b) => want[a].compareTo(want[b]));
      final top = List.filled(mine.length, 0.0);
      var next = _pad;
      for (final i in order) {
        top[i] = max(want[i], next);
        next = top[i] + mine[i].$5 + _gap;
      }
      var limit = height - _pad;
      for (final i in order.reversed) {
        top[i] = min(top[i], limit - mine[i].$5);
        limit = top[i] - _gap;
      }
      for (final (i, o) in mine.indexed) {
        final rect = Rect.fromLTWH(right ? width - column : 0, top[i], column, o.$5);
        slices.add(DonutSlice(o.$1, o.$3, o.$2, false, rect, oneLine: o.$4, right: right));
      }
    }
    // Inside labels: placed now that the center is known.
    final placed = [
      for (final s in slices)
        s.inside
            ? DonutSlice(
                s.part,
                s.percent,
                s.mid,
                true,
                Rect.fromCenter(center: center + s.offset!, width: s.size!.width, height: s.size!.height),
                oneLine: false,
                right: true,
              )
            : s,
    ];
    return DonutGeometry._(height, center, radius, hole, placed);
  }
}

/// One slice's label: inside the ring, or in a column with a leader line from the ring.
class DonutSlice {
  DonutSlice(
    this.part,
    this.percent,
    this.mid,
    this.inside,
    this.labelRect, {
    required this.oneLine,
    required this.right,
    this.offset,
    this.size,
  });

  final DonutPart part;
  final String percent;

  /// Middle angle of the slice.
  final double mid;
  final bool inside;
  final Rect labelRect;

  /// Outside: "Name 4 %" fits on one line.
  final bool oneLine;

  /// Outside: in the right column.
  final bool right;

  /// Inside, while placing: center offset from the ring's center, and size.
  final Offset? offset;
  final Size? size;
}

/// Leader lines from the ring to the labels outside it.
class _Leaders extends CustomPainter {
  _Leaders(this.g, this.color);

  final DonutGeometry g;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    for (final s in g.slices) {
      if (s.inside) continue;
      final dir = Offset(cos(s.mid), sin(s.mid));
      final from = g.center + dir * (g.radius - 2);
      final elbow = g.center + dir * (g.radius + 8);
      final end = Offset(s.right ? s.labelRect.left - 2 : s.labelRect.right + 2, s.labelRect.center.dy);
      final path = Path()..moveTo(from.dx, from.dy);
      // Bend only when the elbow is still on the ring's side of the label.
      if (s.right ? elbow.dx < end.dx : elbow.dx > end.dx) path.lineTo(elbow.dx, elbow.dy);
      path.lineTo(end.dx, end.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_Leaders old) => old.g != g || old.color != color;
}

/// Name and share inside a slice, whole words only (the slice was chosen because they fit).
class _InsideLabel extends StatelessWidget {
  const _InsideLabel(this.name, this.percent, this.style, this.color);

  final String name;
  final String percent;
  final TextStyle style;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(name, softWrap: false, maxLines: 1, style: style.copyWith(color: color)),
      Text(
        percent,
        softWrap: false,
        maxLines: 1,
        style: style.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    ],
  );
}

/// Name and share in a label column: "Name 4 %" on one line, or the name (shortened if it must) above the
/// share, which is never cut.
class _OutsideLabel extends StatelessWidget {
  const _OutsideLabel(this.name, this.percent, this.style, {required this.oneLine, required this.right});

  final String name;
  final String percent;
  final TextStyle style;
  final bool oneLine;
  final bool right;

  @override
  Widget build(BuildContext context) {
    final align = right ? TextAlign.left : TextAlign.right;
    final bold = style.copyWith(fontWeight: FontWeight.w600);
    if (oneLine) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$name ', style: style),
            TextSpan(text: percent, style: bold),
          ],
        ),
        textAlign: align,
        maxLines: 1,
        softWrap: false,
      );
    }
    return Column(
      crossAxisAlignment: right ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(name, style: style, textAlign: align, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis),
        Text(percent, style: bold, textAlign: align, maxLines: 1, softWrap: false),
      ],
    );
  }
}

/// Merchants of a category (exactly that key: a group-filed key leaves its children out) over the range, each
/// with its share of the category. People and lines without a merchant make the last row, so the shares add
/// up to 100 %. Tap a merchant for its transactions.
void showMerchantsSheet(BuildContext context, StatsData d, String key, String title) {
  final l = AppLocalizations.of(context);
  // The sheet lives above the page's providers: carry them over.
  final repo = context.read<ExpenseRepository>();
  final index = context.read<CategoryIndex>();
  final lines = [
    for (final x in d.inRange)
      if ((x.categoryId ?? '') == key) x,
  ];
  final whole = lines.fold<int>(0, (s, x) => s + x.cents);
  final names = <String, String>{};
  final rows = breakdown(
    lines,
    d.from,
    d.to,
    keyOf: (x) {
      if (x.isPerson || x.merchantId == null) return null;
      names['${x.merchantId}'] = x.merchant;
      return '${x.merchantId}';
    },
    labelOf: (k) => names[k] ?? k,
  ).where((r) => r.total > 0).toList();
  // Transfers to people, lines without a merchant, merchants with only refunds.
  final rest = whole - rows.fold<int>(0, (s, r) => s + r.total);
  String share(int cents) => whole <= 0 ? '—' : '${(cents / whole * 100).toStringAsFixed(1)} %';
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheet) => _Carry(
      repo: repo,
      index: index,
      child: DraggableScrollableSheet(
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
            if (rows.isEmpty && rest == 0) Padding(padding: const EdgeInsets.all(16), child: Text(l.noMerchants)),
            for (final r in rows)
              ListTile(
                title: Text(r.label, overflow: TextOverflow.ellipsis),
                subtitle: Text('${l.visits(r.count)} · ${share(r.total)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Text(money(context, r.total, d.currency)), const Icon(Icons.chevron_right)],
                ),
                onTap: () => _showBills(context, d, key, int.parse(r.key), r.label, repo, index),
              ),
            if (rest != 0)
              ListTile(
                key: const ValueKey('merchants-rest'),
                title: Text(l.peopleAndOther, overflow: TextOverflow.ellipsis),
                subtitle: Text(share(rest)),
                trailing: Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: Text(money(context, rest, d.currency)),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// The spending lines of [rows] filed exactly under [key] ('' = uncategorized), as statistics count them: a
/// split transaction gives the part filed under [key], with that part's amount.
List<(TxnView, (String, int)?)> billLines(Iterable<TxnView> rows, String key) => [
  for (final v in rows)
    if (TransactionKind.values.byName(v.txn.kind).countsAsSpending)
      if (v.isSplit)
        for (final s in v.splits)
          if (s.categoryId == key) (v, (s.categoryId, s.amount)) else ...const []
      else if ((v.txn.categoryId ?? '') == key)
        (v, null),
];

/// The transactions of one merchant in a category over the range, newest first; tap one for its details.
void _showBills(
  BuildContext context,
  StatsData d,
  String key,
  int merchantId,
  String merchant,
  ExpenseRepository repo,
  CategoryIndex index,
) {
  final l = AppLocalizations.of(context);
  final filter = TxnFilter(
    scope: d.scope,
    from: d.from,
    to: d.to,
    merchantId: merchantId,
    // Narrows the query (a group also matches its children): [billLines] keeps the exact category.
    categoryId: key.isEmpty ? null : key,
  );
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheet) => _Carry(
      repo: repo,
      index: index,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        builder: (context, controller) => KeyedStreamBuilder<List<TxnView>>(
          streamKey: filter,
          stream: () => repo.watchTransactions(filter),
          builder: (context, rows) {
            final list = billLines(rows ?? const <TxnView>[], key);
            return ListView(
              controller: controller,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(merchant, style: Theme.of(context).textTheme.titleMedium),
                ),
                if (rows != null && list.isEmpty) Padding(padding: const EdgeInsets.all(16), child: Text(l.noBills)),
                for (final (v, part) in list) TransactionTile(v, showDate: true, part: part),
              ],
            );
          },
        ),
      ),
    ),
  );
}

/// The page's providers inside a bottom sheet (sheets sit above them in the tree).
class _Carry extends StatelessWidget {
  const _Carry({required this.repo, required this.index, required this.child});

  final ExpenseRepository repo;
  final CategoryIndex index;
  final Widget child;

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider.value(value: repo),
      Provider.value(value: index),
    ],
    child: child,
  );
}
