import 'package:core/core.dart';
import 'package:drift/drift.dart';

import 'database.dart';

/// What the [CategoryClassifier] learns from: spending lines with a precise
/// category that are out of the review queue (chosen or accepted by the user,
/// or categorized by a rule, merchant, keyword…), never its own unaccepted
/// guesses. As `(description, location, categoryId)`.
Selectable<(String, String?, String)> reviewedLines(ExpenseDatabase db) =>
    (db.select(db.transactions)..where(
          (t) =>
              t.needsReview.equals(false) &
              t.categoryId.like('%.%') &
              t.kind.isIn([TransactionKind.expense.name, TransactionKind.refund.name]),
        ))
        .map((t) => (t.description, t.location, t.categoryId!));

/// A classifier retrained whenever the reviewed lines change (a choice in the
/// review queue is learned at once).
Stream<CategoryClassifier> watchClassifier(ExpenseDatabase db) =>
    reviewedLines(db).watch().map(CategoryClassifier.train);
