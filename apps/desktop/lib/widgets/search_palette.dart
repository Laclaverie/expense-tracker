import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:storage/storage.dart';

import '../l10n/app_localizations.dart';
import '../screens/transactions.dart' show showTransactionDetails;
import '../search.dart';
import '../style.dart';

/// Ctrl+K: find any transaction of any bank or account by merchant, amount,
/// date or note ([SearchQuery]). ↑/↓ move, Enter opens the line.
Future<void> showSearchPalette(BuildContext context) => showDialog<void>(
  context: context,
  builder: (_) => _SearchPalette(host: context),
);

class _SearchPalette extends StatefulWidget {
  const _SearchPalette({required this.host});

  /// Where the chosen line opens once the palette is closed.
  final BuildContext host;

  @override
  State<_SearchPalette> createState() => _SearchPaletteState();
}

class _SearchPaletteState extends State<_SearchPalette> {
  static const _max = 50;

  /// Every transaction, newest first, read once when the palette opens.
  late final Future<List<TxnView>> _all = context.read<ExpenseRepository>().watchTransactions(const TxnFilter()).first;
  String _query = '';
  int _selected = 0;

  List<TxnView> _found(List<TxnView> all) {
    final q = SearchQuery.parse(_query);
    if (q.isEmpty) return const [];
    final out = <TxnView>[];
    for (final v in all) {
      final t = v.txn;
      if (q.matches(
        text: [v.merchant?.name, t.description, t.note, t.location, v.account.name],
        cents: t.amount,
        date: t.date,
      )) {
        out.add(v);
        if (out.length > _max) break;
      }
    }
    return out;
  }

  void _open(TxnView v) {
    Navigator.of(context).pop();
    showTransactionDetails(widget.host, v);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 80, left: 24, right: 24, bottom: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 560),
        child: FutureBuilder<List<TxnView>>(
          future: _all,
          builder: (context, snap) {
            final found = _found(snap.data ?? const []);
            final shown = found.take(_max).toList();
            final selected = shown.isEmpty ? 0 : _selected.clamp(0, shown.length - 1);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Focus(
                    onKeyEvent: (_, e) {
                      if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
                      if (e.logicalKey == LogicalKeyboardKey.arrowDown) {
                        setState(() => _selected = (selected + 1).clamp(0, shown.isEmpty ? 0 : shown.length - 1));
                        return KeyEventResult.handled;
                      }
                      if (e.logicalKey == LogicalKeyboardKey.arrowUp) {
                        setState(() => _selected = (selected - 1).clamp(0, shown.isEmpty ? 0 : shown.length - 1));
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: l.globalSearchHint,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (v) => setState(() {
                        _query = v;
                        _selected = 0;
                      }),
                      onSubmitted: (_) {
                        if (shown.isNotEmpty) _open(shown[selected]);
                      },
                    ),
                  ),
                ),
                if (_query.trim().isNotEmpty) ...[
                  const Divider(height: 1),
                  Flexible(
                    child: shown.isEmpty
                        ? Padding(padding: const EdgeInsets.all(24), child: Text(l.globalSearchNone))
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: shown.length,
                            itemBuilder: (context, i) {
                              final v = shown[i];
                              return ListTile(
                                dense: true,
                                selected: i == selected,
                                selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
                                onTap: () => _open(v),
                                leading: SizedBox(
                                  width: 90,
                                  child: Text('${shortDate(context, v.txn.date)} ${v.txn.date.year}'),
                                ),
                                title: Text(v.displayName, overflow: TextOverflow.ellipsis),
                                subtitle: Text(
                                  [
                                    v.txn.description,
                                    v.txn.note,
                                    accountName(v.account),
                                  ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
                                  overflow: TextOverflow.ellipsis,
                                  style: t.bodySmall?.copyWith(color: muted),
                                ),
                                trailing: Text(
                                  money(context, v.txn.amount, v.account.currency),
                                  style: t.bodyMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                                ),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      found.length > _max ? l.globalSearchMore(_max) : l.transactionCount(found.length),
                      style: t.bodySmall?.copyWith(color: muted),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
