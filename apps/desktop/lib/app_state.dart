import 'package:flutter/material.dart';
import 'package:storage/storage.dart';

import 'clock.dart';

/// UI selections shared by every screen: statistics scope, month, language.
class AppState extends ChangeNotifier {
  Scope? _scope;
  DateTime _month = _firstOfMonth(appNow());
  Locale? _locale;

  /// Null until the first account exists. May be narrowed to one account
  /// ([Scope.accountId]); targets use [Scope.whole].
  Scope? get scope => _scope;

  /// First day of the selected month (UTC, like stored dates).
  DateTime get month => _month;
  DateTime get nextMonth => DateTime.utc(_month.year, _month.month + 1);

  /// The day whose periods targets show: today in the current month, else
  /// the last day of the selected month.
  DateTime get referenceDay {
    final now = appNow();
    final today = DateTime.utc(now.year, now.month, now.day);
    return today.isBefore(nextMonth) && !today.isBefore(_month) ? today : nextMonth.subtract(const Duration(days: 1));
  }

  /// Null = follow the system language.
  Locale? get locale => _locale;

  set scope(Scope? value) {
    if (value == _scope) return;
    _scope = value;
    notifyListeners();
  }

  void shiftMonth(int delta) {
    _month = DateTime.utc(_month.year, _month.month + delta);
    notifyListeners();
  }

  set month(DateTime value) {
    _month = _firstOfMonth(value);
    notifyListeners();
  }

  set locale(Locale? value) {
    _locale = value;
    notifyListeners();
  }

  /// Merchant whose regular payment an alert points to: Statistics opens on
  /// its Recurring tab with that series highlighted.
  int? get recurringFocus => _recurringFocus;
  int? _recurringFocus;

  /// Counts "open the recurring payments" requests (the shell switches page).
  int get recurringRequests => _recurringRequests;
  int _recurringRequests = 0;
  bool _recurringPending = false;

  void showRecurring(int? merchantId) {
    _recurringFocus = merchantId;
    _recurringRequests++;
    _recurringPending = true;
    notifyListeners();
  }

  /// True once after [showRecurring]: Statistics then switches to its tab.
  bool takeRecurringRequest() {
    final pending = _recurringPending;
    _recurringPending = false;
    return pending;
  }

  /// Keeps the selected scope valid when accounts change.
  void ensureScope(List<Scope> available) {
    if (available.isEmpty) return;
    if (_scope == null || !available.contains(_scope!.whole)) {
      _scope = available.firstWhere((s) => s.institution != 'cash', orElse: () => available.first);
      WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
    }
  }

  static DateTime _firstOfMonth(DateTime d) => DateTime.utc(d.year, d.month);
}
