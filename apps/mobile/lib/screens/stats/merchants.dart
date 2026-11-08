import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:storage/storage.dart';

import '../../l10n/app_localizations.dart';
import '../../style.dart';

/// Businesses of the range by total (people left out), with a search box.
class MerchantsView extends StatefulWidget {
  const MerchantsView(this.d, {super.key, this.notices = const []});

  final StatsData d;
  final List<Widget> notices;

  @override
  State<MerchantsView> createState() => _MerchantsViewState();
}

class _MerchantsViewState extends State<MerchantsView> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final d = widget.d;
    final names = <String, String>{};
    final query = _search.toLowerCase();
    final rows = breakdown(
      d.lines,
      d.from,
      d.to,
      keyOf: (x) {
        if (x.isPerson || x.merchantId == null) return null;
        names['${x.merchantId}'] = x.merchant;
        return '${x.merchantId}';
      },
      labelOf: (k) => names[k] ?? k,
    ).where((r) => r.total > 0 && (query.isEmpty || r.label.toLowerCase().contains(query))).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      children: [
        ...widget.notices,
        TextField(
          decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.search, isDense: true),
          onChanged: (v) => setState(() => _search = v),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
          child: Text(l.merchantsHint, style: Theme.of(context).textTheme.bodySmall),
        ),
        if (rows.isEmpty) Padding(padding: const EdgeInsets.all(16), child: Text(l.noMerchants)),
        for (final r in rows) ...[
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            title: Text(r.label, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              [l.visits(r.count), if (r.last != null) l.lastOn(shortDate(context, r.last!))].join(' · '),
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(money(context, r.total, d.currency)),
          ),
          const Divider(height: 1),
        ],
      ],
    );
  }
}
