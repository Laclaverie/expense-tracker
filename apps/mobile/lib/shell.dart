import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storage/storage.dart';

import 'l10n/app_localizations.dart';
import 'phone_store.dart';
import 'screens/home.dart';
import 'screens/settings.dart';
import 'screens/statistics.dart';
import 'screens/transactions.dart';
import 'session.dart';
import 'state.dart';
import 'style.dart';

/// Bottom bar (Home, Transactions, Statistics, Settings) and the scope switcher on top.
class Shell extends StatefulWidget {
  const Shell({super.key, required this.session, required this.check, this.initialTab = 0});

  final Session session;

  /// Asks the desktop for a newer copy (the Home banner).
  final Future<Offer?> Function() check;
  final int initialTab;

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  late int _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final repo = context.read<ExpenseRepository>();
    final state = context.watch<PhoneState>();
    return StreamBuilder<List<Scope>>(
      stream: repo.watchScopes(),
      builder: (context, snap) {
        final scopes = snap.data ?? const <Scope>[];
        state.ensureScope(scopes);
        final scope = state.scope;
        final page = switch (_tab) {
          0 => HomePage(session: widget.session, check: widget.check, onSeeAll: () => setState(() => _tab = 1)),
          1 => const TransactionsPage(),
          2 => const StatisticsPage(),
          _ => SettingsPage(session: widget.session),
        };
        return Scaffold(
          appBar: AppBar(
            title: _tab == 3 || scope == null ? Text(_tab == 3 ? l.settingsTitle : l.appTitle) : ScopeSwitcher(scopes),
          ),
          body: page,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: [
              NavigationDestination(icon: const Icon(Icons.home_outlined), label: l.navHome),
              NavigationDestination(icon: const Icon(Icons.receipt_long_outlined), label: l.navTransactions),
              NavigationDestination(icon: const Icon(Icons.bar_chart_outlined), label: l.navStatistics),
              NavigationDestination(icon: const Icon(Icons.settings_outlined), label: l.navSettings),
            ],
          ),
        );
      },
    );
  }
}

/// Institution and currency (or a cash wallet), then one account of it: currencies are never mixed.
class ScopeSwitcher extends StatelessWidget {
  const ScopeSwitcher(this.scopes, {super.key});

  final List<Scope> scopes;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = context.watch<PhoneState>();
    final scope = state.scope;
    if (scope == null) return const SizedBox.shrink();
    final repo = context.read<ExpenseRepository>();
    return StreamBuilder<List<Account>>(
      stream: repo.watchAccounts(),
      builder: (context, snap) {
        final accounts = [
          for (final a in snap.data ?? const <Account>[])
            if (a.institution == scope.institution && a.currency == scope.currency) a,
        ];
        final several =
            {for (final s in scopes.where((s) => s.institution == scope.institution)) s.currency}.length > 1;
        final account = accounts.where((a) => a.id == scope.accountId).firstOrNull;
        final label = account != null ? accountName(account) : scopeLabel(context, scope, withCurrency: several);
        return PopupMenuButton<Scope>(
          tooltip: l.chooseScope,
          onSelected: (s) => state.scope = s,
          itemBuilder: (context) => [
            for (final s in scopes) ...[
              CheckedPopupMenuItem(
                value: s,
                checked: s == scope.whole && scope.accountId == null,
                child: Text(
                  scopeLabel(context, s, withCurrency: scopes.where((x) => x.institution == s.institution).length > 1),
                ),
              ),
              if (s == scope.whole && accounts.length > 1)
                for (final a in accounts)
                  CheckedPopupMenuItem(
                    value: s.withAccount(a.id),
                    checked: scope.accountId == a.id,
                    child: Padding(padding: const EdgeInsets.only(left: 16), child: Text(accountName(a))),
                  ),
            ],
          ],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(label, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleLarge),
              ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        );
      },
    );
  }
}
