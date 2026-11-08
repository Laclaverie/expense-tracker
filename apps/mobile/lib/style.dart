import 'package:core/core.dart' as core;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:storage/storage.dart';

import 'l10n/app_localizations.dart';

/// Category group color from the shared dataviz palette (same slot as the desktop for each group).
Color groupColor(BuildContext context, String? categoryOrGroup) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  final s = core.seriesOf(categoryOrGroup);
  if (s == core.uncategorizedSeries) return Color(dark ? core.noneDark : core.noneLight);
  if (s == core.otherSeries) return Color(dark ? core.otherDark : core.otherLight);
  return Color((dark ? core.darkPalette : core.lightPalette)[core.chartGroups.indexOf(s)]);
}

/// Color of the [i]-th series that is not a category group (accounts on the balances chart).
Color seriesColor(BuildContext context, int i) => Color(
  (Theme.of(context).brightness == Brightness.dark ? core.darkPalette : core.lightPalette)[i %
      core.lightPalette.length],
);

/// Color of an "Others" series.
Color otherColor(BuildContext context) =>
    Color(Theme.of(context).brightness == Brightness.dark ? core.otherDark : core.otherLight);

/// Reserved status colors (never reused for categories), always shown with an icon and a label.
const _good = Color(0xFF0CA30C), _warning = Color(0xFFFAB219), _critical = Color(0xFFD03B3B);

Color statusColor(core.TargetStatus s) => switch (s) {
  core.TargetStatus.onTrack => _good,
  core.TargetStatus.atRisk => _warning,
  core.TargetStatus.over => _critical,
};

IconData statusIcon(core.TargetStatus s) => switch (s) {
  core.TargetStatus.onTrack => Icons.check_circle,
  core.TargetStatus.atRisk => Icons.warning_amber_rounded,
  core.TargetStatus.over => Icons.error,
};

String statusLabel(AppLocalizations l, core.TargetStatus s) => switch (s) {
  core.TargetStatus.onTrack => l.status_onTrack,
  core.TargetStatus.atRisk => l.status_atRisk,
  core.TargetStatus.over => l.status_over,
};

String periodLabel(AppLocalizations l, core.TargetPeriod p) => switch (p) {
  core.TargetPeriod.week => l.period_week,
  core.TargetPeriod.month => l.period_month,
  core.TargetPeriod.year => l.period_year,
};

String lang(BuildContext context) => Localizations.localeOf(context).languageCode;

String money(BuildContext context, int cents, [String currency = 'CAD']) =>
    core.formatMoney(cents, currency, languageCode: lang(context));

String monthLabel(BuildContext context, DateTime month) =>
    toBeginningOfSentenceCase(DateFormat.yMMMM(lang(context)).format(month));

String shortDate(BuildContext context, DateTime d) => DateFormat.MMMd(lang(context)).format(d);

String longDate(BuildContext context, DateTime d) => DateFormat.yMMMEd(lang(context)).format(d);

/// Account name without the bank's details in parentheses (contract number).
String accountName(Account a) => a.name.replaceAll(RegExp(r'\s*\(.*\)\s*$'), '');

IconData accountIcon(String type) => switch (type) {
  'creditCard' => Icons.credit_card,
  'cash' => Icons.payments_outlined,
  'savings' || 'registered' => Icons.savings_outlined,
  _ => Icons.account_balance_outlined,
};

/// Institution id as a name ("desjardins" -> "Desjardins"; the phone has no bank plug-ins), or the cash
/// wallet. [withCurrency] when the institution has accounts in several currencies (one scope each).
String scopeLabel(BuildContext context, Scope scope, {bool withCurrency = false}) {
  if (scope.institution == 'cash') return AppLocalizations.of(context).scopeCash(scope.currency ?? '');
  final id = scope.institution;
  final name = id.length <= 3 ? id.toUpperCase() : '${id[0].toUpperCase()}${id.substring(1)}';
  return '$name${withCurrency && scope.currency != null ? ' ${scope.currency}' : ''}';
}

String kindLabel(AppLocalizations l, String kind) => switch (kind) {
  'income' => l.kind_income,
  'refund' => l.kind_refund,
  'fee' => l.kind_fee,
  'interest' => l.kind_interest,
  'transfer' => l.kind_transfer,
  'externalTransfer' => l.kind_externalTransfer,
  _ => l.kind_expense,
};

/// Category id -> row, with localized names.
class CategoryIndex {
  CategoryIndex(List<CategoryRow> rows) : rows = rows, _byId = {for (final r in rows) r.id: r};

  final List<CategoryRow> rows;
  final Map<String, CategoryRow> _byId;

  CategoryRow? operator [](String? id) => id == null ? null : _byId[id];

  String name(BuildContext context, String? id) {
    final row = this[id];
    if (row == null) return AppLocalizations.of(context).uncategorized;
    return lang(context) == 'fr' ? row.nameFr : row.nameEn;
  }

  /// Active groups (archived ones are hidden but keep their names for old data).
  List<CategoryRow> get groups => rows.where((r) => r.parentId == null && !r.archived).toList();

  List<CategoryRow> childrenOf(String groupId) => rows.where((r) => r.parentId == groupId && !r.archived).toList();
}
