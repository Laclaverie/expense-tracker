import 'package:banks/banks.dart' show BankImporter;
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../style.dart';

/// The steps to download [bank]'s export (`BankImporter.exportGuide`), with
/// its screenshots when the app ships them (`assets/guides/<institution>/`).
Future<void> showExportGuide(BuildContext context, BankImporter bank) {
  final l = AppLocalizations.of(context);
  final guide = bank.exportGuide!;
  final code = lang(context);
  final steps = guide.steps(code);
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l.guideTitle(bank.displayName, guide.fileType.toUpperCase())),
      content: SizedBox(
        width: 640,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, step) in steps.indexed) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(radius: 12, child: Text('${i + 1}', style: const TextStyle(fontSize: 12))),
                      const SizedBox(width: 12),
                      Expanded(child: Text(step)),
                    ],
                  ),
                ),
                if (guide.images[i + 1] case final image?)
                  Padding(
                    padding: const EdgeInsets.only(left: 36, bottom: 8),
                    child: Image.asset(
                      'assets/guides/${bank.institution}/$image',
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
              ],
              if (guide.notes(code).isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(guide.notes(code), style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l.close))],
    ),
  );
}
