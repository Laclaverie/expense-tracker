/// Transactions to a spreadsheet: Excel (.xlsx, real dates and numbers) or
/// CSV (separator and decimal mark of the language, UTF-8 with BOM so Excel
/// reads accents). One row per transaction, one per part of a split one.
library;

import 'dart:convert';

import 'package:excel/excel.dart' as xl;
import 'package:storage/storage.dart';

/// One exported line, already in words (names in the UI language).
class ExportRow {
  const ExportRow({
    required this.date,
    required this.bank,
    required this.account,
    required this.merchant,
    required this.description,
    required this.group,
    required this.category,
    required this.type,
    required this.cents,
    required this.currency,
    this.foreignCents,
    this.foreignCurrency,
    this.note = '',
    this.splitPart = false,
  });

  final DateTime date;
  final String bank;
  final String account;
  final String merchant;
  final String description;
  final String group;
  final String category;
  final String type;

  /// Signed: money out < 0.
  final int cents;
  final String currency;
  final int? foreignCents;
  final String? foreignCurrency;
  final String note;

  /// One part of a transaction split across categories.
  final bool splitPart;
}

/// Names the export needs, in the UI language.
class ExportNames {
  const ExportNames({
    required this.bank,
    required this.account,
    required this.group,
    required this.category,
    required this.type,
  });

  final String Function(String institution) bank;
  final String Function(Account account) account;

  /// Group and category of a category id ('' when uncategorized).
  final String Function(String? categoryId) group;
  final String Function(String? categoryId) category;
  final String Function(String kind) type;
}

List<ExportRow> exportRows(List<TxnView> views, ExportNames names) => [
  for (final v in views)
    for (final (categoryId, cents, part)
        in v.isSplit
            ? [for (final s in v.splits) (s.categoryId, s.amount, true)]
            : [(v.txn.categoryId, v.txn.amount, false)])
      ExportRow(
        date: v.txn.date,
        bank: names.bank(v.account.institution),
        account: names.account(v.account),
        merchant: v.merchant?.name ?? '',
        description: v.txn.description,
        group: names.group(categoryId),
        category: names.category(categoryId),
        type: names.type(v.txn.kind),
        cents: cents,
        currency: v.account.currency,
        foreignCents: part ? null : v.txn.foreignCents,
        foreignCurrency: part ? null : v.txn.foreignCurrency,
        note: v.txn.note ?? '',
        splitPart: part,
      ),
];

String _date(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// [headers]: 13 column titles (date, bank, account, merchant, description,
/// group, category, type, amount, currency, original amount, original currency,
/// note) plus the word for split parts.
String toCsv(List<ExportRow> rows, List<String> headers, {required String languageCode, required String splitWord}) {
  final fr = languageCode == 'fr';
  final sep = fr ? ';' : ',';
  String amount(int c) {
    final s = (c / 100).toStringAsFixed(2);
    return fr ? s.replaceAll('.', ',') : s;
  }

  String field(String s) =>
      s.contains(sep) || s.contains('"') || s.contains('\n') || s.contains('\r') ? '"${s.replaceAll('"', '""')}"' : s;
  final out =
      StringBuffer('﻿') // BOM: Excel then reads UTF-8 accents correctly
        ..write(headers.map(field).join(sep))
        ..write('\r\n');
  for (final r in rows) {
    out
      ..write(
        [
          _date(r.date),
          r.bank,
          r.account,
          r.merchant,
          r.description,
          r.group,
          r.splitPart ? '${r.category} ($splitWord)' : r.category,
          r.type,
          amount(r.cents),
          r.currency,
          r.foreignCents == null ? '' : amount(r.foreignCents!),
          r.foreignCurrency ?? '',
          r.note,
        ].map(field).join(sep),
      )
      ..write('\r\n');
  }
  return out.toString();
}

/// Same columns as [toCsv], as an Excel workbook (one sheet).
List<int> toXlsx(List<ExportRow> rows, List<String> headers, {required String sheetName, required String splitWord}) {
  final book = xl.Excel.createExcel();
  final sheet = book.getDefaultSheet()!;
  book.rename(sheet, sheetName);
  final s = book[sheetName];
  final bold = xl.CellStyle(bold: true);
  final money = xl.CellStyle(numberFormat: xl.NumFormat.standard_4);
  for (final (c, h) in headers.indexed) {
    s.updateCell(xl.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0), xl.TextCellValue(h), cellStyle: bold);
  }
  for (final (i, r) in rows.indexed) {
    final row = i + 1;
    void put(int col, xl.CellValue? v, [xl.CellStyle? style]) => s.updateCell(
      xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
      v,
      cellStyle: style,
    );
    put(0, xl.DateCellValue.fromDateTime(r.date));
    put(1, xl.TextCellValue(r.bank));
    put(2, xl.TextCellValue(r.account));
    put(3, xl.TextCellValue(r.merchant));
    put(4, xl.TextCellValue(r.description));
    put(5, xl.TextCellValue(r.group));
    put(6, xl.TextCellValue(r.splitPart ? '${r.category} ($splitWord)' : r.category));
    put(7, xl.TextCellValue(r.type));
    put(8, xl.DoubleCellValue(r.cents / 100), money);
    put(9, xl.TextCellValue(r.currency));
    if (r.foreignCents != null) put(10, xl.DoubleCellValue(r.foreignCents! / 100), money);
    if (r.foreignCurrency != null) put(11, xl.TextCellValue(r.foreignCurrency!));
    if (r.note.isNotEmpty) put(12, xl.TextCellValue(r.note));
  }
  for (final (c, width) in [12.0, 14.0, 26.0, 26.0, 48.0, 18.0, 26.0, 14.0, 14.0, 9.0, 14.0, 10.0, 30.0].indexed) {
    s.setColumnWidth(c, width);
  }
  return book.encode()!;
}

/// UTF-8 bytes of a CSV export (BOM included in the text).
List<int> csvBytes(String csv) => utf8.encode(csv);
