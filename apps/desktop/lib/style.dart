import 'package:banks/banks.dart';
import 'package:core/core.dart' as core;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:storage/storage.dart';

import 'l10n/app_localizations.dart';

/// Category groups with a fixed chart color (categorical palette, slots 1–7,
/// validated for color-vision deficiency in this order). Every other group is
/// shown as "Other"; uncategorized spending has its own (lighter) neutral.
/// Color follows the group, never its rank.
const chartGroups = ['food', 'housing', 'transport', 'travel', 'leisure', 'shopping', 'people'];

/// Chart series keys besides [chartGroups].
const otherSeries = 'other';
const uncategorizedSeries = 'none';

const _light = [0xFF2A78D6, 0xFFEB6834, 0xFF1BAF7A, 0xFFEDA100, 0xFFE87BA4, 0xFF008300, 0xFF6250D6];
const _dark = [0xFF3987E5, 0xFFD95926, 0xFF199E70, 0xFFC98500, 0xFFD55181, 0xFF008300, 0xFF9085E9];
const _otherLight = 0xFF9A9893;
const _otherDark = 0xFF6F6E69;
const _noneLight = 0xFFD3D1CA;
const _noneDark = 0xFFB4B2AB;

/// Group id of a category id: `food.coffee` -> `food`.
String groupOf(String? categoryId) =>
    categoryId == null || categoryId.isEmpty || categoryId == uncategorizedSeries ? '' : categoryId.split('.').first;

/// Chart series of a category or group id: a chart group, other, or none.
String seriesOf(String? categoryOrGroup) {
  final g = groupOf(categoryOrGroup);
  if (g.isEmpty) return uncategorizedSeries;
  return chartGroups.contains(g) ? g : otherSeries;
}

Color groupColor(BuildContext context, String? categoryOrGroup) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  final s = seriesOf(categoryOrGroup);
  if (s == uncategorizedSeries) return Color(dark ? _noneDark : _noneLight);
  if (s == otherSeries) return Color(dark ? _otherDark : _otherLight);
  return Color((dark ? _dark : _light)[chartGroups.indexOf(s)]);
}

/// Color of an "Others" series (parts too small to show on their own).
Color otherColor(BuildContext context) =>
    Color(Theme.of(context).brightness == Brightness.dark ? _otherDark : _otherLight);

/// Categorical palette slot [i] (cycles), for series that aren't category
/// groups, e.g. one line per account.
Color seriesColor(BuildContext context, int i) =>
    Color((Theme.of(context).brightness == Brightness.dark ? _dark : _light)[i % _light.length]);

IconData accountIcon(String type) => switch (type) {
  'creditCard' => Icons.credit_card,
  'cash' => Icons.payments_outlined,
  'savings' || 'registered' => Icons.savings_outlined,
  _ => Icons.account_balance_outlined,
};

/// Account name without the bank's details in parentheses (contract number).
String accountName(Account a) => a.name.replaceAll(RegExp(r'\s*\(.*\)\s*$'), '');

String lang(BuildContext context) => Localizations.localeOf(context).languageCode;

String money(BuildContext context, int cents, [String currency = 'CAD']) =>
    core.formatMoney(cents, currency, languageCode: lang(context));

String monthLabel(BuildContext context, DateTime month) =>
    toBeginningOfSentenceCase(DateFormat.yMMMM(lang(context)).format(month));

String shortDate(BuildContext context, DateTime d) => DateFormat.MMMd(lang(context)).format(d);

/// Bank name from its plug-in, or the cash wallet. [withCurrency] when the
/// bank has accounts in several currencies (one scope each).
String scopeLabel(BuildContext context, Scope scope, {bool withCurrency = false}) => scope.institution == 'cash'
    ? AppLocalizations.of(context).scopeCash(scope.currency ?? '')
    : '${bankFor(scope.institution)?.displayName ?? scope.institution}'
          '${withCurrency && scope.currency != null ? ' ${scope.currency}' : ''}';

/// Currency of a scope's amounts. Scopes from `watchScopes` always carry it.
String scopeCurrency(Scope scope) => scope.currency ?? 'CAD';

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

  /// The name in the other language than the UI's (shown next to search results).
  String otherName(BuildContext context, String id) {
    final row = this[id];
    if (row == null) return '';
    return lang(context) == 'fr' ? row.nameEn : row.nameFr;
  }

  /// Whether every word of [query] is in the French or English name of [id]
  /// (case- and accent-insensitive): "gift", "boutique souvenir" both work
  /// whatever the UI language. A word may also match one of the category's
  /// search aliases (`essence`, `costco`: [core.matchingAlias]).
  bool matches(String? id, String query) {
    final words = core.stripAccents(query).split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return true;
    final row = this[id];
    if (row == null) return false;
    final names = core.stripAccents('${row.nameFr} ${row.nameEn}');
    return words.every((w) => names.contains(w) || core.matchingAlias(row.id, w) != null);
  }

  /// The alias that made [id] match [query] when its names don't (shown next to
  /// the result: "Essence · ESSENCE" is obvious, "Fuel · GAS" explains itself).
  String? matchedAlias(String id, String query) {
    final row = this[id];
    if (row == null) return null;
    final names = core.stripAccents('${row.nameFr} ${row.nameEn}');
    for (final w in core.stripAccents(query).split(RegExp(r'\s+')).where((w) => w.isNotEmpty)) {
      if (!names.contains(w)) return core.matchingAlias(row.id, w);
    }
    return null;
  }

  /// Active groups (archived ones are hidden but keep their names for old data).
  List<CategoryRow> get groups => rows.where((r) => r.parentId == null && !r.archived).toList();

  List<CategoryRow> childrenOf(String groupId) => rows.where((r) => r.parentId == groupId && !r.archived).toList();
}
