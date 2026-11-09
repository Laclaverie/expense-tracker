import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storage/storage.dart';

import '../keyed_stream.dart';
import '../l10n/app_localizations.dart';
import '../state.dart';
import '../style.dart';
import 'stats/balances.dart';
import 'stats/categories.dart';
import 'stats/merchants.dart';
import 'stats/recurring.dart';
import 'stats/trends.dart';
import 'stats/widgets.dart';

enum StatsView { categories, trends, merchants, recurring, balances }

/// Statistics of the scope, built like the desktop's (same lines, coverage rules and periods): ranges end with
/// the latest month with data; months missing a statement are marked, never counted as 0 in averages.
class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key, this.initialView = StatsView.categories});

  final StatsView initialView;

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late StatsView _view = widget.initialView;
  StatsRange _range = StatsRange.twelve;

  /// The group Categories is narrowed to ('' = uncategorized). Kept here so it survives a range change; another
  /// scope starts from every group.
  String? _focus;
  Scope? _focusScope;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scope = context.watch<PhoneState>().scope;
    if (scope != _focusScope) {
      _focus = null;
      _focusScope = scope;
    }
    if (scope == null) return Center(child: Text(l.noData));
    final repo = context.read<ExpenseRepository>();
    final labels = {
      StatsView.categories: l.tabCategories,
      StatsView.trends: l.tabTrends,
      StatsView.merchants: l.tabMerchants,
      StatsView.recurring: l.tabRecurring,
      StatsView.balances: l.tabBalances,
    };
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              for (final v in StatsView.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(labels[v]!),
                    selected: v == _view,
                    onSelected: (_) => setState(() => _view = v),
                  ),
                ),
            ],
          ),
        ),
        // Recurring payments look at the whole history: the range doesn't apply.
        if (_view != StatsView.recurring)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<StatsRange>(
                segments: [
                  ButtonSegment(value: StatsRange.six, label: Text(l.range6)),
                  ButtonSegment(value: StatsRange.twelve, label: Text(l.range12)),
                  ButtonSegment(value: StatsRange.thisYear, label: Text(l.rangeThisYear)),
                ],
                selected: {_range},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _range = s.first),
              ),
            ),
          ),
        Expanded(
          child: KeyedStreamBuilder<DateTime?>(
            streamKey: scope,
            stream: () => repo.watchLatestDate(scope),
            builder: (context, latest) {
              final now = appNow();
              final anchor = DateTime.utc((latest ?? now).year, (latest ?? now).month);
              final period = statsPeriod(_range, anchor);
              if (_view == StatsView.balances) return BalancesView(scope, period);
              return StatsDataBuilder(
                scope: scope,
                period: period,
                builder: (context, d, limitedFrom) {
                  final notices = [
                    if (limitedFrom != null) StatsNotice(Icons.filter_alt_outlined, l.globalSincePhone(limitedFrom)),
                    if (_view != StatsView.recurring && d.completeMonths < d.months.length)
                      StatsNotice(
                        Icons.warning_amber_rounded,
                        l.incompleteMonthsShort(d.months.length - d.completeMonths),
                      ),
                  ];
                  return switch (_view) {
                    StatsView.categories => CategoriesView(
                      d,
                      notices: notices,
                      focus: _focus,
                      onFocus: (key) {
                        if (mounted && key != _focus) setState(() => _focus = key);
                      },
                    ),
                    StatsView.trends => TrendsView(d, notices: notices),
                    StatsView.merchants => MerchantsView(d, notices: notices),
                    _ => RecurringView(d),
                  };
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Loads the spending lines of [period] and the period before, and the statement coverage, into a [StatsData]
/// exactly as the desktop's Statistics page does. [limitedFrom] names the month "all accounts" start from when a
/// statement type begins inside the range.
class StatsDataBuilder extends StatelessWidget {
  const StatsDataBuilder({super.key, required this.scope, required this.period, required this.builder});

  final Scope scope;
  final (DateTime, DateTime) period;
  final Widget Function(BuildContext context, StatsData d, String? limitedFrom) builder;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ExpenseRepository>();
    final (from, to) = period;
    final (loadFrom, _) = previousPeriod(from, to);
    return KeyedStreamBuilder<List<SpendLine>>(
      streamKey: (scope, loadFrom, to),
      stream: () => repo.watchSpendingDetail(scope, loadFrom, to),
      builder: (context, lines) => KeyedStreamBuilder<Map<String, List<DayRange>>>(
        streamKey: scope,
        stream: () => repo.watchCoverage(scope),
        builder: (context, coverage) {
          if (lines == null || coverage == null) return const Center(child: CircularProgressIndicator());
          final d = statsDataOf(scope, lines, coverage, period);
          final limited = d.from.isAfter(dataStart(from, to, lines.map((x) => x.date)));
          return builder(context, d, limited ? monthLabel(context, d.from) : null);
        },
      ),
    );
  }
}

/// The desktop's [StatsData] for [scope] over [period] (no focus): shared so tests can compare figures.
StatsData statsDataOf(
  Scope scope,
  List<SpendLine> lines,
  Map<String, List<DayRange>> coverage,
  (DateTime, DateTime) period,
) {
  final (from, to) = period;
  final rangeFrom = dataStart(from, to, lines.map((x) => x.date));
  final (start, _) = commonStart(coverage, rangeFrom, to, allAccounts: scope.accountId == null);
  final (pf, pt) = previousPeriod(start, to);
  return StatsData(
    scope,
    lines,
    start,
    to,
    monthStatuses(coverage, monthsBetween(start, to)),
    monthStatuses(coverage, monthsBetween(pf, pt)).every((m) => m.complete),
  );
}
