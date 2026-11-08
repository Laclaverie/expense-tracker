import 'package:flutter/widgets.dart';
import 'package:storage/storage.dart';

/// What every tab shares: the statistics scope (institution and currency, or one account).
class PhoneState extends ChangeNotifier {
  Scope? _scope;

  Scope? get scope => _scope;

  set scope(Scope? value) {
    if (value == _scope) return;
    _scope = value;
    notifyListeners();
  }

  /// Keeps the scope valid when the accounts change: the first bank scope, else the first one.
  void ensureScope(List<Scope> available) {
    if (available.isEmpty) return;
    final current = _scope;
    if (current == null || !available.contains(current.whole)) {
      _scope = available.firstWhere((s) => s.institution != 'cash', orElse: () => available.first);
      WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
    }
  }
}
