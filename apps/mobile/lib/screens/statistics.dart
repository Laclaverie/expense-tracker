import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Filled in by the statistics task: the tab exists so the bar is complete.
class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) => Center(child: Text(AppLocalizations.of(context).statsSoon));
}
