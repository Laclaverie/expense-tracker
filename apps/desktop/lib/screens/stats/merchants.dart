// Statistics → Merchants tab: sortable merchant table and merchant detail.

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:storage/storage.dart';

import '../../l10n/app_localizations.dart';
import '../../style.dart';
import '../../widgets/sparkline.dart';
import '../../widgets/transactions_dialog.dart';
import 'charts.dart';
import 'data.dart';
import 'widgets.dart';

class MerchantsTab extends StatefulWidget {
  const MerchantsTab(this.d, {super.key});

  final StatsData d;

  @override
  State<MerchantsTab> createState() => _MerchantsTabState();
}

enum _MerchantSort { name, count, total, average, last }

class _MerchantsTabState extends State<MerchantsTab> {
  String _search = '';
  _MerchantSort _sort = _MerchantSort.total;
  bool _descending = true;

  int _compare(Breakdown a, Breakdown b) => switch (_sort) {
    _MerchantSort.name => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    _MerchantSort.count => a.count.compareTo(b.count),
    _MerchantSort.total => a.total.compareTo(b.total),
    _MerchantSort.average => a.averageTicket.compareTo(b.averageTicket),
    _MerchantSort.last => (a.last ?? DateTime.utc(0)).compareTo(b.last ?? DateTime.utc(0)),
  };

  void _sortBy(_MerchantSort s) => setState(() {
    _descending = s == _sort ? !_descending : s != _MerchantSort.name;
    _sort = s;
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = widget.d;
    final names = <String, String>{};
    final rows =
        breakdown(
              d.lines,
              d.from,
              d.to,
              keyOf: (x) {
                if (x.isPerson || x.merchantId == null) return null;
                names['${x.merchantId}'] = x.merchant;
                return '${x.merchantId}';
              },
              labelOf: (k) => names[k] ?? k,
            )
            .where((r) => r.total > 0 && (_search.isEmpty || r.label.toLowerCase().contains(_search.toLowerCase())))
            .toList()
          ..sort((a, b) => _descending ? _compare(b, a) : _compare(a, b));
    final small = Theme.of(context).textTheme.labelMedium;
    Widget header(String text, _MerchantSort sort, {double? width, TextAlign align = TextAlign.right}) => SortHeader(
      text,
      active: sort == _sort,
      descending: _descending,
      onTap: () => _sortBy(sort),
      width: width,
      align: align,
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.search, isDense: true),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(l.merchantsHint, style: Theme.of(context).textTheme.bodySmall)),
            ],
          ),
        ),
        Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              header(l.colMerchant, _MerchantSort.name, align: TextAlign.left),
              SizedBox(width: 112, child: Text(l.trend, style: small)),
              header(l.visits, _MerchantSort.count, width: 70),
              header(l.statTotal, _MerchantSort.total, width: 120),
              header(l.averageTicket, _MerchantSort.average, width: 120),
              header(l.lastVisit, _MerchantSort.last, width: 110),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final r = rows[i];
              return InkWell(
                onTap: () => showMerchant(context, d, r),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(r.label, overflow: TextOverflow.ellipsis)),
                      Sparkline(r.monthly, color: chartBlue),
                      const SizedBox(width: 16),
                      SizedBox(width: 70, child: Text('${r.count}', textAlign: TextAlign.right)),
                      SizedBox(
                        width: 120,
                        child: Text(money(context, r.total, d.currency), textAlign: TextAlign.right),
                      ),
                      SizedBox(
                        width: 120,
                        child: Text(money(context, r.averageTicket, d.currency), textAlign: TextAlign.right),
                      ),
                      SizedBox(
                        width: 110,
                        child: Text(r.last == null ? '' : shortDate(context, r.last!), textAlign: TextAlign.right),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Merchant detail: monthly spending and its transactions.
void showMerchant(BuildContext context, StatsData d, Breakdown r) {
  final l = AppLocalizations.of(context);
  showSpendingDialog(
    context,
    title: r.label,
    filter: TxnFilter(
      scope: d.scope,
      from: d.from,
      to: d.to,
      merchantId: int.parse(r.key),
      categoryId: d.focusCategory,
    ),
    header: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${l.visits} ${r.count} · ${l.averageTicket} ${money(context, r.averageTicket, d.currency)}'),
        const SizedBox(height: 8),
        SizedBox(
          height: 170,
          child: MonthlyBars(months: d.months, values: r.monthly, average: r.averagePerMonth, currency: d.currency),
        ),
        const SizedBox(height: 12),
      ],
    ),
  );
}
