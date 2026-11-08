import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../phone_store.dart';
import '../session.dart';
import '../sync_banner.dart';

/// Placeholder until the real screens: the sync banner and the age of the data.
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.session, required this.check});

  final Session session;
  final Future<Offer?> Function() check;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final date = session.store.dataDate();
    return Scaffold(
      appBar: AppBar(title: Text(l.homeTitle)),
      body: ListView(
        children: [
          SyncBanner(session: session, check: check),
          if (date != null) Padding(padding: const EdgeInsets.all(16), child: Text(l.dataFrom(date.toLocal()))),
        ],
      ),
    );
  }
}
