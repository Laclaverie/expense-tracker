import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:banks/banks.dart' show PdfInput, StatementInput, statementFileTypes;
import 'package:banks/files.dart';
import 'package:banks/shape.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../l10n/app_localizations.dart';

/// Reads statements in a background isolate (PDFium is slow on many pages):
/// inputs, one message per unreadable file, reveal candidates. Top-level so
/// the isolate's closure doesn't capture a widget.
Future<(List<StatementInput>, List<String>, List<(String, int)>)> _readInBackground(List<String> paths) =>
    Isolate.run(() {
      final inputs = <StatementInput>[], errors = <String>[];
      for (final f in paths) {
        try {
          inputs.add(loadStatementInput(f));
        } on Object catch (e) {
          errors.add('${p.basename(f)}: $e');
        }
      }
      return (inputs, errors, revealCandidates(inputs, minFiles: inputs.length >= 2 ? 2 : 1));
    });

/// Writes the masked copy of [inputs] to [folder]: `statement-N.shape.txt`
/// (and `.shape.json` for PDFs), `reveal.txt` ([kept] words) and
/// `README.txt`, plus `notes.txt` when the owner wrote [notes]. Returns the
/// number of files written.
int saveMaskedCopy(
  String folder,
  List<StatementInput> inputs,
  Set<String> kept, {
  required String readme,
  String notes = '',
}) {
  final reveal = Reveal(kept);
  var count = 0;
  void write(String name, String content) {
    File(p.join(folder, name)).writeAsStringSync(content);
    count++;
  }

  // Numbered names: a file name can hold the owner's name or account number.
  for (final (i, input) in inputs.indexed) {
    final name = 'statement-${i + 1}';
    write('$name.shape.txt', shapeText(input, reveal, heading: '[${i + 1}] '));
    if (input case PdfInput(:final words)) {
      write('$name.shape.json', jsonEncode({...maskWords(words, reveal).toJson(), 'masked': true}));
    }
  }
  write('reveal.txt', '${(kept.toList()..sort()).join('\n')}\n');
  write('README.txt', '$readme\n');
  if (notes.trim().isNotEmpty) write('notes.txt', '${notes.trim()}\n');
  return count;
}

/// "My bank isn't listed": the statement owner approves which words may stay
/// readable and saves a masked copy of their statements for whoever writes the
/// plug-in (`docs/10-adding-a-bank.md` §0b, `docs/11-import-sources-onboarding.md`
/// §3). Same masking as `banks:shape`; nothing leaves the computer.
class AddBankScreen extends StatefulWidget {
  const AddBankScreen({super.key, this.initialPaths = const []});

  /// Statements read on open (tests).
  final List<String> initialPaths;

  @override
  State<AddBankScreen> createState() => _AddBankScreenState();
}

class _AddBankScreenState extends State<AddBankScreen> {
  List<StatementInput> _inputs = const [];
  List<(String, int)> _candidates = const [];
  final _kept = <String>{};
  final _errors = <String>[];
  int _reading = 0;
  bool _hovering = false;
  String _filter = '';
  final _notes = TextEditingController();
  String? _saved;

  @override
  void initState() {
    super.initState();
    if (widget.initialPaths.isNotEmpty) _read(widget.initialPaths);
  }

  /// Reads [paths] (sorted) and lists the words that could stay readable.
  Future<void> _read(List<String> paths) async {
    paths = [...paths]..sort();
    if (paths.isEmpty) return;
    setState(() {
      _reading = paths.length;
      _errors.clear();
      _saved = null;
    });
    final read = await _readInBackground(paths);
    if (!mounted) return;
    setState(() {
      _reading = 0;
      _inputs = read.$1;
      _errors.addAll(read.$2);
      _candidates = read.$3;
      // Everything hidden until the owner ticks a word: their name and street
      // are in every statement, so they are candidates too.
      _kept.clear();
    });
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  static String _type(String path) => p.extension(path).replaceFirst('.', '').toLowerCase();

  Future<void> _choose() async {
    final files = await openFiles(
      acceptedTypeGroups: [
        XTypeGroup(label: 'PDF, CSV, OFX…', extensions: [...statementFileTypes]),
      ],
    );
    if (files.isNotEmpty) await _read([for (final f in files) f.path]);
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final folder = await getDirectoryPath();
    if (folder == null) return;
    final count = saveMaskedCopy(folder, _inputs, _kept, readme: l.addBankReadme, notes: _notes.text);
    setState(() => _saved = l.addBankSaved(folder, count));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shown = [
      for (final c in _candidates)
        if (_filter.isEmpty || c.$1.contains(_filter.toUpperCase())) c,
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.addBankTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(l.addBankIntro),
          const SizedBox(height: 24),
          Text(l.addBankStep1, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          DropTarget(
            onDragEntered: (_) => setState(() => _hovering = true),
            onDragExited: (_) => setState(() => _hovering = false),
            onDragDone: (d) {
              setState(() => _hovering = false);
              // Files of a type no plug-in could read (photos, Word documents…) are skipped.
              _read([
                for (final f in d.files)
                  if (statementFileTypes.contains(_type(f.path))) f.path,
              ]);
            },
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: _hovering ? scheme.primaryContainer : scheme.surfaceContainerLow,
                border: Border.all(color: _hovering ? scheme.primary : scheme.outlineVariant, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _reading > 0
                          ? l.addBankReading(_reading)
                          : _inputs.isEmpty
                          ? l.addBankDrop
                          : l.addBankFiles(_inputs.length),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: _reading > 0 ? null : _choose,
                      icon: const Icon(Icons.folder_open),
                      label: Text(l.importChoose),
                    ),
                  ],
                ),
              ),
            ),
          ),
          for (final e in _errors)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(e, style: TextStyle(color: scheme.error)),
            ),
          if (_inputs.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(l.addBankStep2, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_candidates.isEmpty)
              Text(l.addBankNoWords)
            else ...[
              Row(
                children: [
                  SizedBox(
                    width: 240,
                    child: TextField(
                      decoration: InputDecoration(
                        isDense: true,
                        prefixIcon: const Icon(Icons.search),
                        hintText: l.addBankSearch,
                      ),
                      onChanged: (v) => setState(() => _filter = v.trim()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(l.addBankKept(_kept.length, _candidates.length)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => _kept.addAll([for (final (w, _) in shown) w])),
                    child: Text(l.addBankKeepAll),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _kept.removeAll([for (final (w, _) in shown) w])),
                    child: Text(l.addBankHideAll),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final (w, n) in shown)
                    Tooltip(
                      message: l.addBankInFiles(n),
                      child: FilterChip(
                        label: Text(w),
                        selected: _kept.contains(w),
                        onSelected: (on) => setState(() => on ? _kept.add(w) : _kept.remove(w)),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Text(l.addBankStep3, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              height: 320,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                border: Border.all(color: scheme.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    shapePreview(_inputs.first, Reveal(_kept)).join('\n'),
                    style: const TextStyle(fontFamily: 'Consolas', fontSize: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _notes,
              minLines: 3,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: l.addBankNotesLabel,
                hintText: l.addBankNotesHint,
                hintMaxLines: 4,
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Text(l.addBankStep4, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_alt), label: Text(l.addBankSave)),
            ),
            if (_saved != null) Padding(padding: const EdgeInsets.only(top: 8), child: SelectableText(_saved!)),
          ],
        ],
      ),
    );
  }
}
