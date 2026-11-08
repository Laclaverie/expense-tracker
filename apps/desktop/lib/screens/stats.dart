import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:storage/storage.dart';

import '../app_state.dart';
import '../coverage_view.dart';
import '../l10n/app_localizations.dart';
import '../style.dart';
import '../widgets/keyed_stream.dart';
import 'stats/widgets.dart';
import 'stats/trends.dart';
import 'stats/categories.dart';
import 'stats/merchants.dart';
import 'stats/compare.dart';
import 'stats/balances.dart';
import 'stats/recurring.dart';

/// Statistics and trends for the selected scope. Ranges end with the latest
/// month with data (the top bar's month is hidden here: it would silently cut
/// "this year" short); Compare has its own month.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
  // From the big picture to the detail: where the money goes, what comes back
  // every month, then one shop; then history (trends, comparisons, balances).
  late final _tabs = TabController(length: 6, vsync: this);
  static const _recurringTab = 1, _trendsTab = 3, _compareTab = 4, _balancesTab = 5;
  StatsRange _range = StatsRange.twelve;

  /// Compare and recurring payments have their own periods: the range buttons
  /// and the notices about the range don't apply there.
  bool get _usesRange => _tabs.index != _compareTab && _tabs.index != _recurringTab;

  /// Group or category the whole page is narrowed to ('' = uncategorized).
  String? _focus;

  void _focusOn(String key) {
    setState(() => _focus = key);
    _tabs.animateTo(_trendsTab);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final scope = state.scope;
    if (scope == null) return Center(child: Text(l.noData));
    if (state.takeRecurringRequest()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tabs.animateTo(_recurringTab);
      });
    }
    return KeyedStreamBuilder<DateTime?>(
      streamKey: scope,
      stream: () => context.read<ExpenseRepository>().watchLatestDate(scope),
      builder: (context, latest) {
        final now = appNow();
        final anchor = DateTime.utc((latest ?? now).year, (latest ?? now).month);
        return _page(context, scope, anchor);
      },
    );
  }

  /// [anchor]: last month of the ranges (latest month with data).
  Widget _page(BuildContext context, Scope scope, DateTime anchor) {
    final l = AppLocalizations.of(context);
    final repo = context.read<ExpenseRepository>();
    final period = statsPeriod(_range, anchor);
    final (from, to) = period;
    final (loadFrom, _) = previousPeriod(from, to);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Row(
            children: [
              Text(l.navStats, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(width: 24),
              ListenableBuilder(
                listenable: _tabs,
                builder: (context, _) => SegmentedButton<StatsRange>(
                  segments: [
                    ButtonSegment(value: StatsRange.six, label: Text(l.range6)),
                    ButtonSegment(value: StatsRange.twelve, label: Text(l.range12)),
                    ButtonSegment(value: StatsRange.thisYear, label: Text(l.rangeThisYear)),
                    ButtonSegment(value: StatsRange.lastYear, label: Text(l.rangeLastYear)),
                    ButtonSegment(value: StatsRange.all, label: Text(l.rangeAll)),
                  ],
                  selected: {_range},
                  showSelectedIcon: false,
                  onSelectionChanged: _usesRange ? (s) => setState(() => _range = s.first) : null,
                ),
              ),
              if (_focus != null) ...[
                const SizedBox(width: 16),
                InputChip(
                  avatar: CircleAvatar(backgroundColor: groupColor(context, _focus!.isEmpty ? null : _focus)),
                  label: Text(context.watch<CategoryIndex>().name(context, _focus!.isEmpty ? null : _focus)),
                  onDeleted: () => setState(() => _focus = null),
                  deleteButtonTooltipMessage: l.showEverything,
                ),
              ],
            ],
          ),
        ),
        TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: l.tabCategories),
            Tab(text: l.tabRecurring),
            Tab(text: l.tabMerchants),
            Tab(text: l.tabTrends),
            Tab(text: l.tabCompare),
            Tab(text: l.tabBalances),
          ],
        ),
        Expanded(
          child: KeyedStreamBuilder<List<SpendLine>>(
            streamKey: (scope, loadFrom, to),
            stream: () => repo.watchSpendingDetail(scope, loadFrom, to),
            builder: (context, lines) {
              if (lines == null) return const Center(child: CircularProgressIndicator());
              final rangeFrom = dataStart(from, to, lines.map((l) => l.date));
              return KeyedStreamBuilder<Map<String, List<DayRange>>>(
                streamKey: scope,
                stream: () => repo.watchCoverage(scope),
                builder: (context, coverage) {
                  final cov = coverage ?? const <String, List<DayRange>>{};
                  final (start, limitedBy) = commonStart(cov, rangeFrom, to, allAccounts: scope.accountId == null);
                  final (pf, pt) = previousPeriod(start, to);
                  final data = StatsData(
                    scope,
                    _focus == null
                        ? lines
                        : [
                            for (final x in lines)
                              if (inFocus(x.categoryId, _focus!)) x,
                          ],
                    start,
                    to,
                    monthStatuses(cov, monthsBetween(start, to)),
                    monthStatuses(cov, monthsBetween(pf, pt)).every((m) => m.complete),
                    focus: _focus,
                  );
                  return Column(
                    children: [
                      // Balances follow the range but not the spending coverage rules.
                      ListenableBuilder(
                        listenable: _tabs,
                        builder: (context, _) => !_usesRange || _tabs.index == _balancesTab
                            ? const SizedBox.shrink()
                            : Column(
                                children: [
                                  if (limitedBy != null)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                                      child: StatsNotice(
                                        Icons.filter_alt_outlined,
                                        l.globalSince(
                                          DateFormat.yMMMM(lang(context)).format(start),
                                          statementLabel(context, limitedBy),
                                        ),
                                      ),
                                    ),
                                  if (!data.complete.every((c) => c))
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                                      child: CoverageNotice(data.statuses),
                                    ),
                                ],
                              ),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabs,
                          children: [
                            CategoriesTab(data, onFocus: _focusOn, onNarrow: (key) => setState(() => _focus = key)),
                            RecurringTab(data),
                            MerchantsTab(data),
                            TrendsTab(data, onFocus: _focusOn),
                            CompareTab(data, month: anchor, coverage: cov),
                            BalancesTab(scope, period),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
