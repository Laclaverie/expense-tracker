import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:storage/storage.dart';

import '../app_state.dart';
import '../database_list.dart';
import '../l10n/app_localizations.dart';
import '../style.dart';
import 'accounts.dart';
import 'categories.dart';
import 'dashboard.dart';
import 'import_screen.dart';
import 'review.dart';
import 'stats.dart';
import 'targets.dart';
import 'transactions.dart';
import '../widgets/backup_dialog.dart';
import '../widgets/notifications.dart';
import '../widgets/search_palette.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _page = 0;

  /// Last [AppState.recurringRequests] handled (an alert opens Statistics).
  int _recurringRequests = 0;

  static const _importPage = 5;

  @override
  void initState() {
    super.initState();
    // Reminder at every start while a bank's next statement is out but not imported.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final due = await watchDueStatements(context.read<ExpenseRepository>()).first;
      if (!mounted || due.isEmpty) return;
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l.statementsDue(due.length)} — ${due.map((s) => dueTitle(context, s)).join(', ')}'),
          duration: const Duration(seconds: 12),
          showCloseIcon: true,
          action: SnackBarAction(label: l.goImport, onPressed: () => setState(() => _page = _importPage)),
        ),
      );
    });
    // Statements arrive after the month ends: open on the latest month with data.
    context.read<ExpenseRepository>().latestTransactionDate().then((latest) {
      if (!mounted || latest == null) return;
      final state = context.read<AppState>();
      if (latest.isBefore(state.month)) state.month = latest;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final repo = context.read<ExpenseRepository>();
    final requests = context.select<AppState, int>((s) => s.recurringRequests);
    if (requests != _recurringRequests) {
      _recurringRequests = requests;
      _page = 1;
    }
    final pages = [
      const DashboardScreen(),
      const StatsScreen(),
      const TransactionsScreen(),
      const ReviewScreen(),
      const TargetsScreen(),
      ImportScreen(onImported: () => setState(() => _page = 3)),
      const AccountsScreen(),
      const CategoriesScreen(),
    ];
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.keyK, control: true): () => showSearchPalette(context)},
      child: Focus(autofocus: true, child: _scaffold(context, l, repo, pages)),
    );
  }

  Widget _scaffold(BuildContext context, AppLocalizations l, ExpenseRepository repo, List<Widget> pages) {
    return Scaffold(
      body: Row(
        children: [
          StreamBuilder<int>(
            stream: repo.watchReviewCount(),
            builder: (context, snap) {
              final review = snap.data ?? 0;
              return NavigationRail(
                selectedIndex: _page,
                onDestinationSelected: (i) => setState(() => _page = i),
                labelType: NavigationRailLabelType.all,
                destinations: [
                  NavigationRailDestination(
                    icon: const Icon(Icons.insights_outlined),
                    selectedIcon: const Icon(Icons.insights),
                    label: Text(l.navDashboard),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.query_stats_outlined),
                    selectedIcon: const Icon(Icons.query_stats),
                    label: Text(l.navStats),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.receipt_long_outlined),
                    selectedIcon: const Icon(Icons.receipt_long),
                    label: Text(l.navTransactions),
                  ),
                  NavigationRailDestination(
                    icon: Badge(
                      isLabelVisible: review > 0,
                      label: Text('$review'),
                      child: const Icon(Icons.fact_check_outlined),
                    ),
                    selectedIcon: Badge(
                      isLabelVisible: review > 0,
                      label: Text('$review'),
                      child: const Icon(Icons.fact_check),
                    ),
                    label: Text(l.navReview),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.savings_outlined),
                    selectedIcon: const Icon(Icons.savings),
                    label: Text(l.navTargets),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.upload_file_outlined),
                    selectedIcon: const Icon(Icons.upload_file),
                    label: Text(l.navImport),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.account_balance_outlined),
                    selectedIcon: const Icon(Icons.account_balance),
                    label: Text(l.navAccounts),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.category_outlined),
                    selectedIcon: const Icon(Icons.category),
                    label: Text(l.navCategories),
                  ),
                ],
              );
            },
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                // Statistics have their own periods: no month there.
                _TopBar(showMonth: _page != 1, onImport: () => setState(() => _page = _importPage)),
                const Divider(height: 1),
                Expanded(child: pages[_page]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One account of the selected institution, or all of them. Hidden when the
/// institution has a single account.
class _AccountPicker extends StatelessWidget {
  const _AccountPicker();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scope = state.scope;
    if (scope == null || scope.institution == 'cash') return const SizedBox.shrink();
    return StreamBuilder<List<Account>>(
      stream: context.read<ExpenseRepository>().watchAccounts(),
      builder: (context, snap) {
        final accounts = [
          for (final a in snap.data ?? const <Account>[])
            if (a.institution == scope.institution && a.type != 'share') a,
        ];
        if (accounts.length < 2) return const SizedBox.shrink();
        final selected = accounts.any((a) => a.id == scope.accountId) ? scope.accountId : null;
        Widget item(IconData icon, String text) =>
            Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(text)]);
        return DropdownButtonHideUnderline(
          child: DropdownButton<int?>(
            value: selected,
            borderRadius: BorderRadius.circular(12),
            items: [
              DropdownMenuItem(
                value: null,
                child: item(Icons.layers_outlined, AppLocalizations.of(context).allAccounts),
              ),
              for (final a in accounts) DropdownMenuItem(value: a.id, child: item(accountIcon(a.type), accountName(a))),
            ],
            onChanged: (id) => state.scope = scope.withAccount(id),
          ),
        );
      },
    );
  }
}

/// Scope (one institution or cash wallet at a time — never mixed), month, language.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.showMonth, required this.onImport});

  final bool showMonth;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          StreamBuilder<List<Scope>>(
            stream: context.read<ExpenseRepository>().watchScopes(),
            builder: (context, snap) {
              final scopes = snap.data ?? const <Scope>[];
              state.ensureScope(scopes);
              if (scopes.isEmpty || state.scope == null) return const SizedBox.shrink();
              return SegmentedButton<Scope>(
                segments: [
                  for (final s in scopes)
                    ButtonSegment(
                      value: s,
                      label: Text(
                        scopeLabel(
                          context,
                          s,
                          withCurrency: scopes.where((o) => o.institution == s.institution).length > 1,
                        ),
                      ),
                    ),
                ],
                selected: {state.scope!.whole},
                onSelectionChanged: (s) => state.scope = s.first,
                showSelectedIcon: false,
              );
            },
          ),
          const SizedBox(width: 12),
          const _AccountPicker(),
          const Spacer(),
          if (showMonth) ...[
            IconButton(onPressed: () => state.shiftMonth(-1), icon: const Icon(Icons.chevron_left)),
            SizedBox(
              width: 160,
              child: Text(
                monthLabel(context, state.month),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(onPressed: () => state.shiftMonth(1), icon: const Icon(Icons.chevron_right)),
          ],
          const SizedBox(width: 8),
          IconButton(
            tooltip: l.globalSearchTooltip,
            icon: const Icon(Icons.search),
            onPressed: () => showSearchPalette(context),
          ),
          NotificationBell(onImport: onImport),
          if (context.read<Backups?>() case final backups?)
            IconButton(
              tooltip: l.backupTitle,
              icon: const Icon(Icons.settings_backup_restore),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => BackupDialog(backups: backups),
              ),
            ),
          if (context.read<DatabaseSession?>() case final session?) ...[
            // Another file than the app's own (a developer copy, a shared copy): always in sight.
            if (!session.isHome)
              Tooltip(
                message: session.file.path,
                child: Chip(
                  avatar: const Icon(Icons.description_outlined, size: 16),
                  label: Text(p.basenameWithoutExtension(session.file.path)),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            IconButton(
              tooltip: l.lockTooltip,
              icon: const Icon(Icons.lock_outline),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: Text(l.lockConfirmTitle),
                    content: Text(l.lockConfirm),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
                      FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.lockAction)),
                    ],
                  ),
                );
                if (ok == true) session.lock();
              },
            ),
          ],
          PopupMenuButton<String>(
            tooltip: l.language,
            icon: const Icon(Icons.translate),
            onSelected: (code) => state.locale = Locale(code),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'fr', child: Text('Français')),
              PopupMenuItem(value: 'en', child: Text('English')),
            ],
          ),
        ],
      ),
    );
  }
}
