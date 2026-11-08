import 'package:core/core.dart';
import 'package:flutter/widgets.dart';

/// Locks after [after] in the background: remembers when the app was paused and, on resume, calls [onLock]
/// when that was long enough ago. The clock is [appNow], so tests can fake it.
class AppLock with WidgetsBindingObserver {
  AppLock({required this.onLock, this.after = const Duration(minutes: 5)});

  final VoidCallback onLock;
  final Duration after;
  DateTime? _pausedAt;

  void attach() => WidgetsBinding.instance.addObserver(this);
  void detach() => WidgetsBinding.instance.removeObserver(this);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt ??= appNow();
    } else if (state == AppLifecycleState.resumed) {
      final at = _pausedAt;
      _pausedAt = null;
      if (at != null && appNow().difference(at) >= after) onLock();
    }
  }
}
