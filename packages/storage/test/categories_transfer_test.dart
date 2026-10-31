import 'dart:convert';
import 'dart:io';

import 'package:core/core.dart';
import 'package:drift/drift.dart' show StringExpressionOperators;
import 'package:drift/native.dart';
import 'package:banks/desjardins.dart';
import 'package:pdf_words/pdf_words.dart';
import 'package:storage/storage.dart';
import 'package:test/test.dart';

const fixtures = '../banks/test/fixtures/desjardins';

Future<void> load(ExpenseDatabase db, String name) => ImportService(db).importStatement(
  toImported(
    parseStatement(
      DocumentWords.fromJson(jsonDecode(File('$fixtures/$name').readAsStringSync()) as Map<String, dynamic>),
    ),
  ),
  fileHash: name,
  fileName: name,
);

void main() {
  test('export my setup, import it in a friend\'s app', () async {
    final mine = ExpenseDatabase(NativeDatabase.memory());
    final repo = ExpenseRepository(mine);
    await load(mine, 'desjardins-account-2026-09.synthetic.json');
    await load(mine, 'desjardins-card-2026-09.synthetic.json');

    final pets = await repo.addCategory(nameFr: 'Animaux', nameEn: 'Pets');
    final vet = await repo.addCategory(parentId: pets, nameFr: 'Vétérinaire', nameEn: 'Vet');
    final climbing = await repo.addCategory(parentId: 'sport', nameFr: 'Escalade', nameEn: 'Climbing');
    await repo.renameCategory('food.coffee', nameFr: 'Cafés', nameEn: 'Coffee');
    await repo.addRule(categoryId: vet, descriptionContains: 'VETERINAIRE');
    final txns = await mine.select(mine.transactions).get();
    final roots = txns.firstWhere((t) => t.description.startsWith('NETFLIX'));
    await repo.setCategory(roots.id, 'shopping.gifts', rememberForMerchant: true);
    final friend = txns.firstWhere((t) => t.isPerson && t.amount < 0); // a person paid by Interac
    await repo.setCategory(friend.id, 'leisure.outings', rememberForMerchant: true);

    final json = jsonDecode(jsonEncode(await CategoriesTransfer(mine).export())) as Map<String, dynamic>;
    final ids = [for (final c in json['categories'] as List) c['id']];
    expect(ids, containsAll([pets, vet, climbing, 'sport', 'food.coffee']));
    expect(ids, isNot(contains('food.groceries'))); // unchanged defaults stay out
    expect((json['rules'] as List).single['descriptionContains'], 'VETERINAIRE');
    final merchantNames = [for (final m in json['merchants'] as List) m['name']];
    expect(merchantNames, contains('Netflix'));
    expect(merchantNames.where((n) => (n as String).startsWith('PERSONNE') || n.startsWith('Personne')), isEmpty);
    expect(jsonEncode(json), isNot(contains('amount'))); // no transactions

    // Friend's app: own data, imports my setup.
    final theirs = ExpenseDatabase(NativeDatabase.memory());
    await load(theirs, 'desjardins-card-2026-08.synthetic.json');
    final result = await CategoriesTransfer(theirs).import(json);
    expect((result.categories, result.renamed, result.rules), (3, 1, 1));
    expect(result.merchants, greaterThanOrEqualTo(1));
    final cats = {for (final c in await theirs.select(theirs.categories).get()) c.id: c};
    expect(cats[climbing]!.parentId, 'sport');
    expect(cats['food.coffee']!.nameFr, 'Cafés');
    final rootsThere = await (theirs.select(theirs.transactions)..where((t) => t.description.like('NETFLIX%'))).get();
    if (rootsThere.isNotEmpty) expect(rootsThere.every((t) => t.categoryId == 'shopping.gifts'), isTrue);

    // Importing twice adds nothing.
    final again = await CategoriesTransfer(theirs).import(json);
    expect((again.categories, again.renamed, again.rules, again.merchants), (0, 0, 0, 0));

    // Not a categories file.
    expect(() => CategoriesTransfer(theirs).import({'format': 'other'}), throwsFormatException);
    await mine.close();
    await theirs.close();
  });

  test('a renamed default on the receiving side is kept', () async {
    final a = ExpenseDatabase(NativeDatabase.memory()), b = ExpenseDatabase(NativeDatabase.memory());
    await ExpenseRepository(a).renameCategory('food.bars', nameFr: 'Bars et pubs', nameEn: 'Bars & pubs');
    await ExpenseRepository(b).renameCategory('food.bars', nameFr: 'Mes bars', nameEn: 'My bars');
    await CategoriesTransfer(b).import(await CategoriesTransfer(a).export());
    final bars = await (b.select(b.categories)..where((c) => c.id.equals('food.bars'))).getSingle();
    expect(bars.nameFr, 'Mes bars');
    expect(defaultCategories.any((c) => c.id == 'food.bars'), isTrue);
    await a.close();
    await b.close();
  });
}
