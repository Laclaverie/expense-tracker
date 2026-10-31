# 09 — Tech choices

> Design document written before the code (October 2026). What is built: the [README](../README.md) and the
> [roadmap](08-roadmap-open-questions.md); where the plan changed, its decision log wins.
> Changed since: bank exports (CSV) read as well as PDFs (2026-10-31); database encryption with
> SQLite3MultipleCiphers (SQLCipher 4 mode) through `package:sqlite3` build hooks, password only (2026-10-31).

Status: **approved 2026-10-17**. Dart PDF check passed (see "Dart / PDFium check").

## Constraints (from decisions)

- **Everything runs locally.** No external API at runtime: no cloud parsing, no FX API, no aggregator, no hosted sync server.
- **Android = light**: quick entry (cash mostly), summaries, target progress, recent transactions.
- **Desktop = heavy**: PDF import, review, rules, merchants, analysis, targets management, export.
- Desjardins checking (EOP) + Odyssée Mastercard first; other Desjardins products later; LCL later.

## Spike result (2026-10-17)

Coordinate-based parsing tested with Python + pdfplumber on all real statements (5 account, 9 card):

| Statement | Lines | Validation |
|-----------|-------|-----------|
| Account (Apr–Sep 2026) | 97 lines, 4 sections each | every running balance matches (0 errors) |
| Card (Jan–Sep 2026) | 349 debits (purchases + fees), 23 credits (payments, refunds, rewards) | Σ = `TOTAL` per card, Σ debits = `Achats / débits`, Σ credits = `Paiements / crédits`, previous + debits − credits = new balance — **14/14 OK** |

Takeaways:
- Word coordinates are reliable; columns are at fixed x positions.
- Balance and total checks catch every parser bug found during the spike — validation is the safety net.
- Spike code kept as reference implementation in [`spikes/pdf-coordinates`](../spikes/pdf-coordinates/README.md).

## Proposed architecture

```mermaid
flowchart LR
    subgraph Desktop["Desktop app (Windows) — source of truth"]
        IMP[PDF import<br/>Desjardins parsers] --> CORE
        CORE[Core: domain, rules,<br/>categorization, targets, stats] --> DB[(SQLite<br/>encrypted)]
        UI[Rich UI: tables,<br/>charts, review] --> CORE
        SYNC[Local sync server<br/>LAN only]
    end
    subgraph Phone["Android app — light"]
        Q[Quick add] --> OUT[(Local SQLite:<br/>outbox + snapshot)]
        S[Summary, targets,<br/>recent tx] --> OUT
    end
    OUT <-- "same Wi-Fi,<br/>paired by QR code" --> SYNC
    SYNC --> CORE
```

### Data ownership & sync (local only)

- **Desktop owns the full database.** Single source of truth ⇒ no merge conflicts to solve.
- **Phone keeps**: an **outbox** of manual entries (cash + provisional card entries) and a **read-only snapshot**
  pushed by desktop: per-scope month totals by category, target progress, last ~200 transactions, merchant + category lists
  (for autocomplete).
- **Sync** = phone and desktop on the same Wi-Fi. Pairing once with a QR code shown by desktop (shared key).
  Phone sends outbox → desktop imports, recomputes → sends new snapshot. Encrypted with the pairing key. No internet.
- Phone works fully offline in between; entries wait in the outbox.
- Fallback when away for long (travel): export/import a sync file manually (e.g. via USB or any file transfer).

### PDF import location

- **MVP: desktop only.** Keeps the phone light and the parser in one runtime.
- Later option: phone receives a shared PDF and simply forwards the file to desktop at next sync (no parsing on phone).

### Stack (recommended): Flutter / Dart monorepo

| Layer | Choice | Why |
|-------|--------|-----|
| Language | **Dart** everywhere | One language, you already use it (app-comparer) |
| UI | **Flutter** — Android app + Windows desktop app | Two apps sharing the same core packages; each app has its own UI sized to its role |
| Repo tooling | melos workspace (as in app-comparer) | Known setup |
| Database | **SQLite + drift** (+ SQLCipher via `sqlcipher_flutter_libs`) | Local, encrypted, SQL for analytics, you know drift |
| PDF words + coordinates | **pdfium_dart** (PDFium FFI, open source); `pdfium_flutter` for app packaging | Verified: offline, char origin (baseline) + boxes, correct accents |
| Charts | fl_chart (or Syncfusion charts) | Local rendering, good on desktop |
| Tables (desktop) | data grid package (e.g. trina_grid / Syncfusion DataGrid) | Big sortable, editable tables |
| i18n | Flutter `intl` + ARB files (FR / EN) | Standard |
| Sync transport | Local HTTP or WebSocket server in desktop app (`shelf`), mDNS discovery, AES-GCM with pairing key | No cloud |
| Tests | Dart unit tests on anonymized word-dump fixtures | Parser = pure functions over words |

Repo layout (target):

```
apps/
  desktop/            Flutter Windows app (import, review, analysis)
  mobile/             Flutter Android app (quick add, summary)
packages/
  core/               domain model, money, categories, rules, targets, stats (pure Dart)
  storage/            drift schema + queries (desktop full DB, mobile outbox/snapshot)
  import_desjardins/  PDF word extraction adapter + account & card parsers + validation
  sync/               pairing, protocol, encryption
spikes/
  pdf-coordinates/    Python reference parser (spike, not shipped)
docs/
```

### Alternatives considered

| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| **Flutter both (Dart)** | One language, shared core, known to you, native Android + Windows | Desktop data grids/charts less mature than web | **Recommended** |
| Desktop Python (PySide6 + pdfplumber + pandas) + Android Flutter | Parser already works; strongest data tooling | Two languages, domain model duplicated, Python packaging pain | No |
| Tauri (Rust + web UI) desktop + Android Kotlin | Best desktop charts/tables (web libs), small binary | Three languages, two UIs, shared core needs Rust FFI | No (too much for a solo project) |
| Kotlin Multiplatform (Compose Android + Desktop, PDFBox) | Strong JVM PDF lib, shared core | New stack to learn, Compose Desktop smaller ecosystem | Viable fallback if Dart PDF lib fails |

## Dart / PDFium check (2026-10-17)

Flutter 3.47.7 / Dart 3.13.5 installed at `E:	oolslutter`. Spike in [`spikes/pdf_coordinates_dart`](../spikes/pdf_coordinates_dart/README.md).

| Check | Result |
|-------|--------|
| Word rows vs Python/pdfplumber, 14 statements | **All transaction rows, totals and summary rows identical.** Only differences: page-header boxes (address, folio, statement-date box) grouped differently — Dart groups by baseline, which splits those boxes more cleanly |
| Accents | Dart/PDFium decodes `Dépôt`, `à`, `Opérations` correctly (pdfplumber gives `�`) |
| Speed | 14 statements in 1.7 s (native exe) |
| Offline | PDFium binary fetched **at build time** by the package build hook and shipped next to the exe (`pdfium.dll`). Nothing downloaded at runtime |

Lessons:
- Use `FPDFText_GetCharOrigin` (baseline) for rows and `FPDFText_GetLooseCharBox` for x extents. Tight glyph boxes
  (pdfrx `loadText`) put `.`, `-`, `'` on different y and split numbers — don't use them.
- Split words on PDFium's generated spaces + gap > 1 pt.
- Plain `dart build cli` bundle did not find its `pdfium.dll` automatically (worked with the lib folder on PATH).
  Flutter app will use `pdfium_flutter` packaging; verify when the desktop app is created.
- Statement-date header fields must be read by label position (`Jour` / `Mois` / `Année`), not by row text.

## Status

- `packages/pdf_words`: PDFium word extraction + JSON word dumps.
- `packages/import_desjardins`: account + card parsers, validation, anonymizer, CLIs. 14 anonymized fixtures, all valid.
- Workspace: Dart pub workspace (root `pubspec.yaml`); melos can be added when Flutter apps arrive.
- Android SDK not installed yet — needed at M3 (Android app).
