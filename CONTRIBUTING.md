# Contributing

Thanks for helping! The most useful contribution is **support for your bank**: every new bank or account type
makes the app usable by more people. The guide is [docs/10 — Adding a bank](docs/10-adding-a-bank.md); it is
written so that an AI coding agent can follow it with you, step by step. Ask first whether your bank lets you
download transactions (CSV, OFX): that reader is much simpler and more reliable than reading PDFs.

## Privacy first

- Your statements and exports never go in the repository, in an issue or in a pull request. Keep them outside
  the clone (`.gitignore` blocks PDF, CSV, OFX, but don't rely on it).
- Test fixtures are synthetic: statements of a made-up household (`packages/demo`, `dart run demo:fixtures`).
  Anonymized copies of real statements (`dart run banks:anonymize`) stay on the owner's machine.
- The app keeps everything on your computer; contributions must not add network calls or external services.
- An agent running in the cloud never reads statements: it works from masked views and data-free reports
  (below, and [doc 10 §0b](docs/10-adding-a-bank.md)).

## Setup

- Windows: double-click `setup.bat` (or `build-desktop.bat`): it installs Git, the Visual Studio C++ tools,
  developer mode and Flutter at the version in `.flutter-version`. The bank readers in `packages/banks` are
  pure Dart and their tests run on any OS with Flutter installed.
- `dart pub get` at the repository root (Dart pub workspace).
- Run the app: `build-desktop.bat` (build + start, `clean` for a clean build), `run-desktop.bat` (last build),
  or `flutter run -d windows` in `apps/desktop`.
- Try it without real data:
  `cd packages/demo && dart run demo:database <folder>\expenses.sqlite`, then start the app with
  `EXPENSES_DB_DIR=<folder>` and `EXPENSES_DB_PASSWORD=demo database password` (the demo database is encrypted
  like any other; the password variable is ignored without `EXPENSES_DB_DIR`). Work on a copy the same way, never on your real database.
- Share a build: `package-desktop.bat` writes `dist\Depenses-windows.zip` (no data inside).

## Bank tools (from `packages/banks`)

| Command | Shows statement data? | What it does |
|---------|-----------------------|--------------|
| `dart run banks:shape [--facts] <files or folders>` | no (masked) | the layout with letters → X, digits → 9; `--facts`: a CSV's columns, formats, order and running balance |
| `dart run banks:check <files or folders>` | no | which bank reads each file, VALID / INVALID, line counts, unknown line types |
| `dart run banks:compare <folders>` | no | the same accounts read from PDFs and from an export, line by line |
| `dart run banks:parse [-v] <files>` | **yes with `-v`** | every line as the app would import it |
| `dart run banks:dump <file>` | **yes** | the file as a reader sees it |
| `dart run banks:anonymize --out <dir> <files>` | writes fixtures | anonymized copies for tests; refuses if a secret slips through |

People who don't code don't need any of these: the app's **"Ma banque ou ma carte n'est pas dans la liste"**
page makes the masked copy (with the CSV facts and their notes) to send to whoever writes the reader.

## Workflow

1. Fork or branch: `bank/<institution>` for a bank, `feat/…` / `fix/…` otherwise.
2. Small commits, conventional messages: `feat(banks): parse MyBank savings statements`, `fix(desktop): …`.
3. Double-click `test-all.bat` (formatting, analysis, every test). GitHub runs the same checks
   (`.github/workflows/ci.yml`) on every pull request: it is merged only when they are green.
4. Open a pull request; the template lists what reviewers check.

## Layout

| Path | What |
|------|------|
| `packages/pdf_words` | PDF → words with coordinates (PDFium) |
| `packages/banks` | Bank plug-ins, one folder per bank in `lib/src/<bank>/` (`desjardins`: `pdf/` and `csv/` readers, the reference); contract, rules tables and helpers in `lib/plugin.dart`; registry `lib/banks.dart`; the tools above |
| `packages/core` | Domain: categories, merchants, categorizer, transfers, targets, statistics (pure Dart) |
| `packages/storage` | SQLite (drift): schema and migrations, import service, repository, backups |
| `apps/desktop` | Flutter Windows app (FR/EN) — [screens](apps/desktop/README.md) |
| `docs/` | Design documents (01–07, 09: the plan from the start), [08 roadmap and decision log](docs/08-roadmap-open-questions.md), [10 adding a bank](docs/10-adding-a-bank.md), [11 import sources](docs/11-import-sources-onboarding.md), [12 done](docs/12-done.md) |

## Rules that keep stored data valid

- Never rename an `institution`, a statement format id, an account `ref` scheme or a category id: they are
  stored in people's databases. Add new ones; retire old ones with a migration.
- Database schema changes go through `packages/storage/lib/src/database.dart` migrations, with a test.
- UI text lives in `apps/desktop/lib/l10n/app_fr.arb` and `app_en.arb` (both), then `flutter gen-l10n`.
