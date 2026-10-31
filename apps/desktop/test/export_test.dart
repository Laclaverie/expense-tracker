import 'dart:io';

import 'package:banks/banks.dart';
import 'package:banks/testing.dart' show loadFixture;
import 'package:drift/native.dart';
import 'package:excel/excel.dart' as xl;
import 'package:expense_desktop/export.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage/storage.dart';

const headers = [
  'Date',
  'Bank',
  'Account',
  'Merchant',
  'Description',
  'Group',
  'Category',
  'Type',
  'Amount',
  'Currency',
  'Original amount',
  'Original currency',
  'Note',
];

final rows = [
  ExportRow(
    date: DateTime.utc(2026, 9, 3),
    bank: 'Desjardins',
    account: 'Mastercard',
    merchant: 'Café; "Le Coin"',
    description: 'CAFE LE COIN MONTREAL QC',
    group: 'Alimentation',
    category: 'Cafés',
    type: 'Dépense',
    cents: -123450,
    currency: 'CAD',
    foreignCents: -9000,
    foreignCurrency: 'USD',
    note: 'avec Léa',
  ),
  ExportRow(
    date: DateTime.utc(2026, 9, 4),
    bank: 'Desjardins',
    account: 'Compte',
    merchant: 'Costco',
    description: 'COSTCO',
    group: 'Achats',
    category: 'Maison',
    type: 'Dépense',
    cents: -500,
    currency: 'CAD',
    splitPart: true,
  ),
];

void main() {
  test('CSV in French: semicolons, decimal comma, quoting, UTF-8 BOM, split parts marked', () {
    final csv = toCsv(rows, headers, languageCode: 'fr', splitWord: 'partie');
    expect(csv, startsWith('﻿Date;Bank;'));
    final lines = csv.split('\r\n');
    expect(lines[1], contains('2026-09-03;Desjardins;Mastercard;"Café; ""Le Coin""";'));
    expect(lines[1], contains(';-1234,50;CAD;-90,00;USD;avec Léa'));
    expect(lines[2], contains(';Maison (partie);Dépense;-5,00;CAD;;;'));
    expect(csvBytes(csv).take(3), [0xEF, 0xBB, 0xBF], reason: 'UTF-8 byte-order mark for Excel');
  });

  test('CSV in English: commas and decimal point', () {
    final csv = toCsv(rows, headers, languageCode: 'en', splitWord: 'part');
    expect(csv.split('\r\n')[1], contains(',-1234.50,CAD,-90.00,USD,'));
  });

  test('Excel: real dates and numbers, header row, one sheet', () {
    final book = xl.Excel.decodeBytes(toXlsx(rows, headers, sheetName: 'Transactions', splitWord: 'partie'));
    expect(book.tables.keys, ['Transactions']);
    final sheet = book.tables['Transactions']!;
    expect(sheet.maxRows, 3);
    expect(sheet.rows[0].map((c) => c?.value.toString()), headers);
    final first = sheet.rows[1];
    expect(first[0]!.value, isA<xl.DateCellValue>());
    expect((first[8]!.value! as xl.DoubleCellValue).value, -1234.5);
    expect(first[3]!.value.toString(), 'Café; "Le Coin"');
    expect(sheet.rows[2][6]!.value.toString(), 'Maison (partie)');
  });

  test('rows from the database: one per transaction, one per part of a split one', () async {
    final db = ExpenseDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final importer = ImportService(db);
    final f = File('../../packages/banks/test/fixtures/desjardins/desjardins-card-2026-09.synthetic.json');
    await importer.importStatement(readStatement(loadFixture(f.path)), fileHash: 'x', fileName: 'x');
    final repo = ExpenseRepository(db);
    var views = await repo.watchTransactions(const TxnFilter()).first;
    final purchase = views.firstWhere((v) => v.txn.amount < -2000);
    // Parts are given as spending (positive); stored and exported with the transaction's sign.
    await repo.setSplits(purchase.txn.id, [('food.groceries', -purchase.txn.amount - 1000), ('shopping.gifts', 1000)]);
    views = await repo.watchTransactions(const TxnFilter()).first;

    final names = ExportNames(
      bank: (i) => i,
      account: (a) => a.name,
      group: (id) => id?.split('.').first ?? '',
      category: (id) => id ?? '',
      type: (k) => k,
    );
    final exported = exportRows(views, names);
    expect(exported, hasLength(views.length + 1));
    final parts = exported.where((r) => r.splitPart).toList();
    expect(parts.map((r) => (r.category, r.cents)), [
      ('food.groceries', purchase.txn.amount + 1000),
      ('shopping.gifts', -1000),
    ]);
    expect(
      exported.fold(0, (s, r) => s + r.cents),
      views.fold(0, (s, v) => s + v.txn.amount),
      reason: 'parts add up to their transaction',
    );
  });
}
