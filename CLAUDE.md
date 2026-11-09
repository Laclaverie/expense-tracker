# Notes for coding agents

Project rules for any agent (Claude Code loads this file automatically; others: see `AGENTS.md`). Read this, then
`README.md`, `CONTRIBUTING.md` and `docs/` (01–13). A git-ignored `CLAUDE.local.md` may add the machine owner's
personal notes.

## Be grounded, push back

Don't accept an idea because the owner proposed it. If it's weak (speculative, too costly for its value, against
a decision already made, solves a problem nobody has yet), say so plainly with the reason and propose the simpler
path. Agreeing is fine only when you've checked it holds up against the code and the project's real users.

## What this is

Personal expense tracker: import bank statement PDFs, categorize fast, see statistics — almost no typing. Windows
desktop app (Flutter); Android app planned (must stay light). Bank support is **plug-ins**: one package per bank,
registered in `packages/banks`. Adding a bank: follow `docs/10-adding-a-bank.md`.

## Status

- Desktop app: import (drag & drop, duplicate detection, coverage grid, supported banks list, "my bank isn't
  listed" page writing a masked copy — `screens/add_bank.dart`), review (reason per line, sort,
  bulk category / confirm after a confirmation dialog, copy name to search, learned one-click suggestions),
  notification bell (due statements, spending anomalies), global search (Ctrl+K), transactions, splits, targets
  (week/month/year), dashboard, statistics (trends, categories, merchants, compare, balances, recurring
  payments; per account; narrowed to a category with per-store cards; category shares without
  excluded categories such as rent, B36), accounts, categories & rules (picker: keyboard,
  search aliases from `core/category_search.dart`, frequent categories), FR/EN.
- Banks: Desjardins — PDF (account statement, Odyssée Mastercard original and October 2026 layouts) and
  the AccèsD CSV export (account, card; preferred source, last 18 months). Same days from a PDF and a CSV
  count once (B30, schema v8). Export guide per bank (`exportGuide`), pointed to after PDF imports.
- Database encrypted with the owner's password (B11, `storage/encryption.dart`, `screens/unlock.dart`). Lock
  button and "Changer de fichier" on the password screen open other database files, each with its own password
  (`database_list.dart`: paths in `databases.json`, never a password; `widgets/database_chooser.dart`).
- Demo to show the app: two made-up personas (couple, freelancer), `demo.bat`, walkthrough and README images
  (`docs/13-demo.md`).
- Android app (`apps/mobile`, `docs/14-mobile.md`): **read-only** viewer — Home, Transactions, Statistics
  (categories, trends, merchants, recurring, balances), Settings, FR/EN. Desktop phone icon pairs it (QR) and
  sends the whole encrypted database over the home Wi-Fi (`packages/sync`, `phone_sync.dart`, offered after
  an import); the phone opens it read-only (`openReadOnlyDatabase`), password in memory only, locks on return
  after 5 minutes or more in the background. APK arm64 only (~28 MB). Not yet: quick add (outbox, B38), fingerprint unlock (B39).
- Roadmap and decision log:
  `docs/08-roadmap-open-questions.md` (backlog: work to do only) — keep it updated; finished items move to
  `docs/12-done.md` with their date.

## Privacy rules (hard)

- Never commit real statements or personal data. `.gitignore` blocks pdf/csv/ofx/zip, `dist/`, `CLAUDE.local.md`.
- `banks:dump` / `banks:parse -v` output contains personal data: read locally, never commit, paste or send it.
- Committed fixtures are synthetic: statements of a made-up household (`packages/demo`, `*.synthetic.json`,
  `dart run demo:fixtures`), read back by the real plug-in in `demo`'s tests. Anonymized copies of real statements
  (`*.anon.json`, `dart run banks:anonymize`, throws `AnonymizationLeak`) stay local; a new bank may start
  with them only after its owner reviewed them, until `packages/demo` writes that bank's layout.
- Cloud agents (you, unless you run on a local model) send what they read to their provider: never open a
  statement or `banks:dump` / `banks:parse -v` output unless its owner explicitly allows it; use `banks:shape` (masked
  layout) and `banks:check` (no data) instead — `docs/10-adding-a-bank.md` §0b.
- Comments, docs and tests use made-up examples (`PERSONNE01`, `ACME CORP`), never real values.
- The database and its copies are encrypted (B11): never weaken it (no plaintext copy, export of the key, key
  stored on disk or in an OS keyring, password in a tracked file or log). Agents never ask for or handle the
  owner's password. Every new file the app writes from the database must stay encrypted or be an explicit
  user export (Excel/CSV).
- The only database an agent may open with data shaped like the owner's is an **anonymized developer copy** the
  owner made (Sauvegardes → "Copie anonymisée pour un développeur", `storage/dev_copy.dart`; it has a `dev_copy`
  table) and handed over with its own password, usually in the git-ignored `dev-data/`. Open it with
  `EXPENSES_DB_DIR` + `EXPENSES_DB_PASSWORD`. Never commit it. Changes to the copy's rules must keep the allowlist
  (a word survives only from a public list) and the leak checks (`dev_copy_test.dart`).
- Never write to a user's real database (`%APPDATA%\dev.lasagna\expense-tracker\expenses.sqlite`): work on a copy
  by setting `EXPENSES_DB_DIR` to a scratch folder. No network calls, no external APIs: everything runs locally.

## Layout

| Path | What |
|------|------|
| `packages/pdf_words` | PDFium (FFI) → words with coordinates; `groupRows`, `mergeThousands` |
| `packages/banks` | Bank plug-ins: `lib/src/<bank>/` (Desjardins = reference: `pdf/` and `csv/` readers, 14 fixtures in `test/fixtures/desjardins`); contract `BankImporter` / `StatementFormat` / `ExportGuide` / `LineRule` tables + CSV and anonymization helpers (`lib/plugin.dart`); `testing.dart` (`testFixtures`); registry `lib/banks.dart`; CLIs `dump`, `parse`, `anonymize`, `shape` (`--facts`), `check`, `compare` (no data, for cloud agents) |
| `packages/core` | Domain: `ImportedStatement`, categories (`defaultCategories`, `retiredCategories`), merchants, categorizer, transfers, targets, analysis, coverage, balances, recurring |
| `packages/demo` | Made-up personas (`persona.dart`: shops and the `Persona` type; `couple.dart` — the fixtures' household —, `freelancer.dart`; seeded, no real data), lived by `household.dart`, written as Desjardins statements and card CSV exports (`desjardins/`): the banks' fixtures (`demo:fixtures`), the demo database (`demo:database`) and the showcase (`demo:showcase`, `demo.bat`) |
| `packages/storage` | drift/SQLite: `tables.dart`, `database.dart` (schema v10 + migrations; `openReadOnlyDatabase` for the phone), `import_service.dart`, `repository.dart`, `backup.dart` |
| `packages/sync` | Desktop → phone transfer: `PairingInfo` (QR payload), HMAC request signing, `Manifest` (size, SHA-256, schema), `SyncServer` (desktop, 10-minute window), `SyncClient` (phone: download, check, swap by two renames, ack), UDP discovery, `lanAddresses` |
| `apps/mobile` | Flutter Android app, read-only: `lib/session.dart` (open database + password in memory), `phone_store.dart` (pairing, copies), `shell.dart`, `screens/` (`stats.dart` + `stats/` one file per view), `lib/l10n/app_{en,fr}.arb`. Depends on `core`, `storage`, `sync` — never `banks` / `pdf_words` (`demo`: dev-only, tests) |
| `apps/desktop` | Flutter Windows app: `lib/screens/*` (a big screen keeps its entry file and puts its parts in a folder of the same name: `screens/stats.dart` + `screens/stats/` one file per tab, shared `charts.dart` / `widgets.dart`), `lib/widgets/*`, `lib/l10n/app_{en,fr}.arb` |
| `spikes/` | Early PDF extraction experiments (historical) |

## Tooling

- Flutter version pinned in `.flutter-version`; `setup.bat` / `tools\setup.ps1` install it (and Git, VS C++ tools,
  developer mode) for non-programmers, `tools\env.bat` finds it for the .bat files. Its own copy
  (`%LOCALAPPDATA%\expense-tracker\flutter`, only on machines without Flutter) follows `.flutter-version` when it
  changes; a Flutter already on PATH is left alone, with a warning if its version differs. Never hardcode a machine path
  in a tracked file. Dart pub **workspace** — `dart pub get` at the root.
- Tests: `test-all.bat` / `tools\test-all.ps1` runs format check, `analyze --fatal-infos` and every test; CI
  (`.github/workflows/ci.yml`) runs the same on pushes to `main` and pull requests (last commit only, older run cancelled, docs-only
  changes skipped). Desktop has a smoke test opening every
  page and Statistics tab on the fixtures (`test/screens_smoke_test.dart`, real Segoe UI font loaded) and unit
  tests for period rules (`core/stats_periods.dart`); the phone app has the same smoke test at two phone sizes on
  the demo database; storage has migration tests from older schemas. Some
  desktop tests need env `EXPENSES_STATEMENTS` pointing at real PDFs; they skip otherwise.
- Demo database: `cd packages/demo && dart run demo:database <folder>\expenses.sqlite` — two years of a made-up
  household (`packages/demo`, no real data) imported through the real Desjardins plug-in, then reviewed
  (encrypted with the public `demo database password`; the app takes `EXPENSES_DB_PASSWORD` only with
  `EXPENSES_DB_DIR`; `tools\ui-probe.ps1` sets it, `-Locked` shows the password screen).
- Showing the app: `demo.bat [couple|freelancer]` (`docs/13-demo.md`) — `demo:showcase` database without the last
  card statement plus its AccèsD card exports to drop, app clock fixed by `EXPENSES_TODAY` (only with
  `EXPENSES_DB_DIR`, `core/clock.dart`: use `appNow()`, never `DateTime.now()` for what the app shows). README
  images: `tools\demo-shots.ps1` (widget test, no window; look before committing).
- `build-desktop.bat` — installs tools if needed, closes the running app, builds release, starts it.
  `run-desktop.bat` — starts the last build (builds if none). `package-desktop.bat` — builds + zips
  `dist\Depenses-windows.zip` to share the app. `build-mobile.bat` — release APK to `dist\Depenses-android.apk`
  (runs `tools\setup.ps1 -Android` first: JDK 17 + Android SDK, opt-in; widget tests need neither).
  `deploy-mobile.bat [pair <addr> <code> | nobuild] [addr]` — builds, then `adb install -r` on every phone connected by USB or wireless debugging (keeps data; same build
  machine only: debug-key signed). `tools\env.bat` puts the Flutter matching `.flutter-version` first on PATH, even
  when an older one comes earlier (`tools\find-flutter.ps1`).
- `.claude/settings.json` denies agents reading statement files (pdf/csv/ofx/qfx/qif, `*.dump.txt`, `reveal.txt`) and
  running `banks:dump` / `banks:parse -v`; machine paths (statements folder, real database) go in the git-ignored
  `.claude/settings.local.json`. A future text-export fixture (`*.anon.csv`) needs a narrower csv rule first.
- l10n: edit both ARB files, then `flutter gen-l10n` (or any build). `nullable-getter: false`.
- drift codegen: `dart run build_runner build` in `packages/storage` after editing tables.
- Commit messages: conventional style (`feat(desktop): …`, `fix: …`, `feat(banks): …`).

## Gotchas learned the hard way

- **Always build with `--no-tree-shake-icons`** (the .bat files do). A stale icon-font subset cache made newly
  used icons render blank. `flutter clean` also fixes it.
- Dates are stored as ISO text (`store_date_time_values_as_text: true`); before that, dates showed one day early.
- drift class names clash with core → `@DataClassName('CategoryRow')`, `RuleRow`, `TargetRow`, `Txn`.
- Stored ids are forever: `institution`, statement format ids (`<institution>-<kind>`), account refs, category ids.
  Retire with a migration, never rename.
- Banks change layouts: keep the old parser, add one per layout (`cardLayouts` in `desjardins/pdf/detect.dart`,
  newest first, same model and ids). Detection must use text only that statement type prints (account
  statements also mention the card name) and read page 1 by rows, not PDF word order.
- Parsing is coordinate-based, not text-flow. Words use char **baseline**; rows grouped by baseline. Statements
  validate against their own balances/totals; a failed check refuses the import.
- Desjardins CSV: no header, unquoted descriptions (commas join back), days oldest first but a day's lines
  newest first (the reader picks the order whose balances all hold), `ET01` → ref `ET 1` like the PDF, card
  file names the card used (mapped to the PDF card account on import), no card balance → not verified.
  `banks:compare` on real files: PDF and CSV agree line for line on the same dates.
- Line kinds come from `LineRule` tables, never `switch`es. Unmatched lines fall back to expense / refund (a
  deposit would lower spending) and are reported as `ImportedStatement.warnings`: `banks:parse` prints them and
  `testFixtures` fails on them. Run `banks:parse` when a new period of statements arrives.
- Scopes are (institution, currency) or a cash wallet, optionally one account (`Scope.accountId`; `Scope.whole`
  for targets). Statistics never mix currencies.
- Coverage (`core/coverage.dart`): a month missing a statement is "missing", not "0 $"; averages skip it. A
  format with `coversSincePrevious` (card statements) covers the days since the previous statement. "All
  accounts" statistics start at the first month every statement format exists.
- `main.dart` awaits `ImportService.refreshAutomaticCategories()` **before** `runApp` (race showed stale counts).
- Encryption: SQLite3MultipleCiphers through `package:sqlite3` hooks (`hooks: user_defines: sqlite3: source:
  sqlite3mc` in the root `pubspec.yaml`, so tests use it too), SQLCipher 4 settings (`PRAGMA cipher`, `legacy = 4`)
  before `PRAGMA key`. `VACUUM INTO` and the WAL keep the cipher; `PRAGMA rekey` encrypts a plaintext file but not
  in WAL mode. A drift database creates its file only on the first query. Key derivation is slow on purpose:
  password checks run in an isolate (`prepareDatabase`).
- Backups (`storage/backup.dart`): before opening, `main.dart` applies a staged restore (a file copy), then the
  password screen; `Backups.prepare` checks the password, encrypts a plaintext database and copies, and copies the
  file when `ExpenseDatabase.currentSchemaVersion` will migrate it. Changes that rewrite data
  (imports) call `backupBefore(context, reason)` first and stop if it fails. A restore can't swap the open
  database: it is staged, then the app restarts. Tests pass no `Backups` (`appFor(db)`): no copies, no button.
- Categorizer order: rule > remembered merchant > bank hint > (refund: its purchase's category) > seed > keyword >
  reward-rate hint.
  The learned classifier (`core/classifier.dart`) only suggests chips in review; it never sets a category.
  "Toujours utiliser cette catégorie pour …" = remembered merchant.
- Adding default categories: add to `defaultCategories`; `seedCategories()` inserts missing ones on open.
  Renaming/removing a default id: add to `retiredCategories` and move references (see v4 migration).
- Recurring detection: per merchant, same-day lines summed; whole merchant first (amount ±35 %), else per amount
  cluster (±15 %). Up to 2 missed periods allowed, ≤ 25 % of payments may be left out.
- Charts follow the dataviz palette in `apps/desktop/lib/style.dart` (fixed categorical slots per group; status
  colors always with icon + label).
- Visual checks of the desktop app: start your own instance on a scratch/copy database; never drive a window the
  user opened. `tools\ui-probe.ps1 start|click|shot|stop -DbDir <scratch>` does it (demo database from the fixtures
  if none, refuses the real database folder, acts only on the process it started, clicks as window messages,
  screenshots cropped so pixels = click coordinates); build the release first. States behind a file dialog: render them from a throwaway widget test (`RepaintBoundary.toImage`,
  Segoe UI loaded as in the smoke test) on the fixtures, then delete the test.
- `Isolate.run` inside a `State` method captures `this` (unsendable: "object is unsendable … _CustomZone"): call it
  from a top-level function (`readStatementFile`, `add_bank.dart`'s `_readInBackground`).
- Scripted edits: write the script with the Write tool and run it (`python -I script.py`). Backslashes in
  heredocs and `python -c` got mangled (`\n` became a newline, `\b` a backspace) and broke ARB, Dart and regexes.
- ARB files: insert new keys as text before the closing brace. Re-dumping them with a JSON library reformats the
  whole file.
- Privacy defaults for people who never code are "hidden": the add-bank page reveals no word until the owner
  ticks it (their name and street are in every statement, so they are candidates too).
