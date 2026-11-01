# Demo Showcase Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show the app to people with two reproducible made-up personas: a `demo.bat` reset with a card CSV to drop live, a documented 7-stop walkthrough and README images rendered by a widget test.

**Architecture:** `packages/demo` turns its one hard-coded persona into a `Persona` value (couple, freelancer), adds an AccèsD card CSV writer and a "show state" database filler. The desktop app gets one clock (`appNow()`) that a demo run can fix. A skipped-by-default widget test walks the stops and writes PNGs.

**Tech Stack:** Dart 3.13 pub workspace, drift/SQLite (SQLite3MultipleCiphers), Flutter 3.47 Windows, `flutter_test`, Windows batch + PowerShell.

**Spec:** `docs/superpowers/specs/2026-11-01-demo-showcase-design.md`

## Global Constraints

- Synthetic data only; comments/tests use made-up values. Never touch `%APPDATA%\dev.lasagna\expense-tracker`.
- Bank fixtures in `packages/banks/test/fixtures/desjardins/*.synthetic.json` stay byte-identical (they come from the couple).
- Demo date span: `lifeStart` 2024-10-21 → `lifeEnd` 2026-10-20, both personas. Demo clock: **2026-10-22**.
- Demo password: `demo database password` (`demoPassword`, `packages/demo/bin/database.dart`).
- `EXPENSES_TODAY` is read only together with `EXPENSES_DB_DIR` (same rule as `scratchPassword()`).
- CSV file name: `releve-carte.csv`. Demo folders: `%LOCALAPPDATA%\expense-tracker\demo\<persona>`.
- Persona ids: `couple`, `freelancer`. Stop ids, in order: `dashboard`, `import`, `review`, `categories`, `recurring`, `trends`, `search`.
- Category ids must already exist in `core/lib/src/category.dart` (no new categories).
- Line kinds come from the Desjardins `LineRule` tables: every written line must match a rule (`read.warnings` empty).
- Run Dart with `E:\tools\flutter\bin\dart.bat` / `flutter.bat` on this machine. `test-all.bat` must pass at the end of every task.
- Commits: conventional style, ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. No push.

## Review Focus

1. **Refactor changes the dice sequence** → every fixture silently changes. Expect: fixtures byte-identical. Test `fixtures are up to date` (Task 1).
2. **`demo.bat` while the owner's app is open** → `run-desktop.bat` style "already running" would leave the *real* app on screen as if it were the demo. Expect: demo.bat refuses and says to close the app (Task 6, manual check).
3. **Dropping the CSV twice in a live demo** → expect "duplicates", no new lines, no new account. Test `importing the CSV again adds nothing` (Task 4).
4. **Malformed or out-of-scope `EXPENSES_TODAY`** (`2026-13-01`, set without `EXPENSES_DB_DIR`) → expect the real clock, no crash. Tests in Task 5.
5. **The CSV lands on a new account** instead of the card already imported from PDFs (card number mapping) → review shows a second card. Test `CSV lines join the PDF card account` (Task 4).

---

### Task 1: `Persona` value, couple unchanged

**Files:**
- Modify: `packages/demo/lib/src/persona.dart` (top-level constants → `Persona` fields; shop constants stay top-level)
- Modify: `packages/demo/lib/src/household.dart`, `life.dart`, `desjardins/statements.dart`, `desjardins/account_statement.dart`, `desjardins/card_statement.dart`, `database.dart`, `lib/demo.dart`
- Test: `packages/demo/test/fixtures_test.dart` (new), existing `statements_test.dart`, `database_test.dart`

**Interfaces:**
- Produces:
  - `class Persona` with fields: `String id`, `int seed`, `List<Habit> habits` (Costco run last, so dice order is unchanged), `List<Bill> bills`, `List<Trip> trips`, `List<OneOff> oneOffs`, `Income income`, `List<(DateTime, int)> rent`, `String landlord`, `List<String> friends`, `String? insurer`, `List<(DateTime, int)> insurance`, `int toSavings`, `int toTfsa`, `DateTime? tfsaOpened`, `double savingsRate`, `double tfsaRate`, `Map<String, int> openings`, `String cardAccount`, `String holderCard`, `String? partnerCard`, `String holder`, `String? partner`, `int cardAnnualFee`, `String atmCaisse`, `Map<String, String> accountCategories`, `ShowState show`.
  - `sealed class Income`; `class Salary extends Income { DateTime firstPayday; List<(DateTime, int)> pay; String employer; }` (`Clients` comes in Task 2).
  - `class ShowState { Set<String> leftToReview; DateTime? missingAccountStatement; List<(String? category, TargetPeriod period, int cents)> targets; }` (couple: the two merchants, 2026-06-30, the three targets now in `database.dart`).
  - `final Persona couple`; `final Map<String, Persona> personas = {'couple': couple}`.
  - `Life liveHousehold({Persona? persona, int? seed})` (defaults: `couple`, `persona.seed`); `Life.persona` field.
  - `lifeStart`, `lifeEnd` stay top-level.
- Consumers: writers read `life.persona.holder`, `.partner`, `.cardAccount`, `.holderCard`, `.partnerCard`, `.tfsaOpened`; `fillDemoDatabase` reads `couple.show`.

- [ ] **Step 1: Write the failing guard test** `fixtures_test.dart` → `test('fixtures are up to date', …)`: for each committed `../banks/test/fixtures/desjardins/*.synthetic.json`, find the statement of the same name in `desjardinsStatements(liveHousehold())` and expect `'${jsonEncode({'format': …, 'synthetic': true, ...s.words.toJson()})}\n'` (same expression as `bin/fixtures.dart`; extract it to `String fixtureJson(SyntheticStatement s)` in `statements.dart` and use it in both) equals the file text.
- [ ] **Step 2: Run** `dart test test/fixtures_test.dart` in `packages/demo`. Expected: FAIL (`fixtureJson` undefined).
- [ ] **Step 3: Add `fixtureJson`, run again.** Expected: PASS — the guard holds before the refactor.
- [ ] **Step 4: Refactor** to the interfaces above. `household.dart` reads every value from `persona`; card picks `partnerCard ?? holderCard`; the dice must be called exactly as before for the couple (no new `dice` calls on paths the couple takes). `account_statement.dart` skips `ET 2` when `tfsaOpened` is null.
- [ ] **Step 5: Run** `dart test` in `packages/demo`, then `dart run demo:fixtures` and `git diff --exit-code packages/banks/test/fixtures`. Expected: all pass, no diff.
- [ ] **Step 6: Commit** `refactor(demo): persona as a value`.

### Task 2: Freelancer persona

**Files:**
- Modify: `packages/demo/lib/src/persona.dart` (add `Clients`, `TaxInstallment`, `freelancer`), `household.dart`
- Test: `packages/demo/test/freelancer_test.dart` (new); `statements_test.dart` runs its read-back group for every persona

**Interfaces:**
- Consumes: Task 1 `Persona`, `Income`, `liveHousehold`.
- Produces:
  - `class Clients extends Income { List<String> names; int typical; double spread; Map<DateTime, int> invoicesInMonth; }` — invoices per month from the dice (0–3, average 1.5), overridden by `invoicesInMonth` for planted months (first of month as key). Each invoice: account line `DI`, `'Dépôt direct / <client>'`, `dice.around(typical, spread)`, on a weekday.
  - `class TaxInstallment { String payee; int cents; }`; `Persona.taxInstallments` (`const []` for the couple): `PWW`, `'Paiement facture - AccèsD Internet / <payee>'`, on Mar/Jun/Sep/Dec 15.
  - `Persona.sweepAbove` (`int?`, null for the couple): at month end, checking above it moves the excess to `ET 1` (`VIW` pair like the couple's monthly transfer).
  - `final Persona freelancer`; added to `personas`.
- Freelancer values (cents): id `freelancer`, seed `3141`; holder `CAMILLE EXEMPLE`, card `0033`, account `0003`, no partner, no TFSA, no insurer; rent `[(2024-01-01, 135000), (2026-07-01, 139000)]` to `Nadia Bouchard`; clients `STUDIO ACME`, `AGENCE EXEMPLE`, `EDITIONS DU QUAI`, typical `240000`, spread `.5`, planted `2025-08 → 0`, `2026-03 → 3`; installments `Revenu Québec 90000`, `ARC 70000`; `sweepAbove: 600000`, `toSavings: 0`; openings `{'EOP': 400000, 'ET 1': 1200000, 'CS': 500}`; ATM caisse `CAISSE DE VILLE-MARIE`; `accountCategories: {'Revenu Québec': 'government.taxes', 'ARC': 'government.taxes'}`. Shops (new, made up): `ESPACE COWORK MTL` (bill, `subscriptions.other`, 22500), `BIXI MONTREAL` (habit, `transport.transit`), software bill `FIGMA` (`subscriptions.software`, 2000, CAD), plus reused `stm` (bill), `metro`, `fruiterie`, `cafe` (≈10/month), `boulangerie`, restaurants, `communauto` (.4/month), `saq`, `pharmacie`, `amazon`, `netflix`, `virgin`, `videotron`. Show state: left to review `{'BIXI MONTREAL'}`, no missing statement, targets: `food.restaurants` month 20000, whole year 4500000.

- [ ] **Step 1: Write failing tests** in `freelancer_test.dart` on `liveHousehold(persona: freelancer)`:
  - `uneven income`: monthly sum of `DI` lines: August 2025 = 0, March 2026 ≥ 3 × median month.
  - `quarterly taxes found`: `detectRecurring` on the spend lines of an in-memory DB filled by `fillDemoDatabase(db, persona: freelancer)` (add the `persona` parameter, default `couple`) has `Revenu Québec` and `ARC` with `Cadence.quarterly`.
  - `one card, no TFSA`: every `CardEntry.card` is `0033` or the account `0003`; no `ET 2` account entry.
  - `same seed, same life` for the freelancer.
- [ ] **Step 2: Run** `dart test test/freelancer_test.dart`. Expected: FAIL (`freelancer` undefined).
- [ ] **Step 3: Implement** the interfaces and values above.
- [ ] **Step 4: Run** `dart test` in `packages/demo` (includes every freelancer statement read back with no warnings and the fixtures guard). Expected: PASS.
- [ ] **Step 5: Commit** `feat(demo): freelancer persona`.

### Task 3: AccèsD card CSV writer

**Files:**
- Create: `packages/demo/lib/src/desjardins/card_csv.dart`
- Modify: `packages/demo/lib/demo.dart` (export)
- Test: `packages/demo/test/card_csv_test.dart`

**Interfaces:**
- Consumes: `Life`, `CardEntry`.
- Produces: `String writeCardCsv(Life life, DateTime closing)` — the card lines of the statement period ending `closing` (posted after the previous closing, up to `closing`) as a Desjardins card export (13 columns, layout table in `packages/banks/lib/src/desjardins/csv/reader.dart`): column 1 `ODYSSEE WORLD ELITE MASTERCARD **** <card>` (the card used per line), date = `posted` as `YYYY/MM/DD`, sequence numbers, merchant padded to 25 + city to 13 + province, purchase / credit columns, no quotes; days oldest first, a day's lines newest first; `\n` line ends, final newline.

- [ ] **Step 1: Write failing tests:** for both personas and the last closing date: `detectCsv(TextInput('releve-carte.csv', text))` is `DesjardinsCsv.card`; `readStatement` of it has no warnings; its lines as `(date, amount, description)` equal the period's `CardEntry`s (the CSV has one date per line: compare with what the reader returns, `date` or `posted`, and write that one); lines are in the order the reader expects (days oldest first, a day's lines newest first).
- [ ] **Step 2: Run** `dart test test/card_csv_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** `writeCardCsv`.
- [ ] **Step 4: Run** `dart test`. Expected: PASS.
- [ ] **Step 5: Commit** `feat(demo): Desjardins card CSV writer`.

### Task 4: Show-state database and `demo:showcase`

**Files:**
- Create: `packages/demo/lib/src/showcase.dart`, `packages/demo/bin/showcase.dart`
- Modify: `packages/demo/lib/src/database.dart` (share the import/review loop), `packages/demo/lib/demo.dart`
- Test: `packages/demo/test/showcase_test.dart`

**Interfaces:**
- Consumes: Tasks 1–3.
- Produces:
  - `const showcaseCsvName = 'releve-carte.csv';`
  - `Future<String> fillShowcaseDatabase(ExpenseDatabase db, Persona persona)` — as `fillDemoDatabase(db, persona: persona)` but without the last card statement (`life.cardStatementDates.last`), reviewed up to that statement's previous closing; returns `writeCardCsv(life, last)`. Import clock: `lifeEnd + 2 days` as today.
  - CLI `dart run demo:showcase <folder> [--persona couple|freelancer]`: writes `<folder>\expenses.sqlite` (encrypted, `EXPENSES_DB_PASSWORD` or `demoPassword`; move `demoPassword` to `lib/src/showcase.dart` and import it in `bin/database.dart`) and `<folder>\releve-carte.csv`. Refuses an existing database (exit 73), unknown persona (exit 64, lists `personas.keys`).

- [ ] **Step 1: Write failing tests** (in-memory DB, both personas):
  - `nothing to review before the drop` except `show.leftToReview` merchants; `the CSV period is not imported` (no transaction posted after the previous closing on the card).
  - `CSV lines join the PDF card account`: import the CSV through `ImportService.importStatement(readStatement(TextInput(showcaseCsvName, csv)), fileHash: 'csv', fileName: showcaseCsvName, fileType: 'csv')` → `ImportStatus.imported`, account count unchanged, new lines > 0, most of them with a suggested or remembered category (≥ 80 % `categoryId != null`).
  - `importing the CSV again adds nothing`: second import with another `fileHash` → 0 new lines.
- [ ] **Step 2: Run** `dart test test/showcase_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** `showcase.dart` and the CLI.
- [ ] **Step 4: Run** `dart test`; then `dart run demo:showcase <scratchpad>\s1` and again on the same folder. Expected: PASS; CLI writes both files, second run exits 73.
- [ ] **Step 5: Commit** `feat(demo): showcase database with a card CSV to drop`.

### Task 5: App clock

**Files:**
- Create: `apps/desktop/lib/clock.dart`
- Modify: `app_state.dart`, `screens/accounts.dart` (both), `screens/dashboard.dart:586`, `screens/stats.dart:66`, `screens/targets.dart:36`, `widgets/notifications.dart:19` (not `widgets/dev_copy_dialog.dart`: a file name timestamp)
- Test: `apps/desktop/test/clock_test.dart`

**Interfaces:**
- Produces:
  - `DateTime Function() clockFromEnvironment(Map<String, String> env)` — with `EXPENSES_DB_DIR` and a valid `EXPENSES_TODAY=YYYY-MM-DD`: that day at 12:00 local, fixed; otherwise `DateTime.now`.
  - `DateTime Function() appClock = clockFromEnvironment(Platform.environment);` (tests assign it), `DateTime appNow() => appClock();`

- [ ] **Step 1: Write failing tests:** override used with both vars (`2026-10-22` → `DateTime(2026, 10, 22, 12)`); ignored without `EXPENSES_DB_DIR`; `2026-13-01` and `hier` → real clock (result within a second of `DateTime.now()`).
- [ ] **Step 2: Run** `flutter test test/clock_test.dart` in `apps/desktop`. Expected: FAIL.
- [ ] **Step 3: Implement**, replace the 8 call sites, `grep -rn "DateTime.now()" lib` leaves only `dev_copy_dialog.dart`.
- [ ] **Step 4: Run** `test-all.bat`. Expected: PASS.
- [ ] **Step 5: Commit** `feat(desktop): one clock, fixed for demos`.

### Task 6: `demo.bat`

**Files:**
- Create: `demo.bat` (root)

- [ ] **Step 1: Write** `demo.bat [couple|freelancer]` (default `couple`):
  1. If `expense_desktop.exe` is running: print `Close the app first: the demo opens its own copy.` and exit 1 (never reuse the running app).
  2. If the release exe is missing: print `Run build-desktop.bat once first.` and exit 1.
  3. `call tools\env.bat`; `DIR=%LOCALAPPDATA%\expense-tracker\demo\<persona>`; `rmdir /s /q` it only when the path ends with `\demo\<persona>`; recreate.
  4. `pushd packages\demo` → `dart run demo:showcase "%DIR%" --persona <persona>`; stop on error.
  5. `start "" explorer "%DIR%"`; set `EXPENSES_DB_DIR=%DIR%`, `EXPENSES_DB_PASSWORD=demo database password`, `EXPENSES_TODAY=2026-10-22`; `start "" "%EXE%"`.
- [ ] **Step 2: Check by hand** (owner's app closed): `demo.bat`, `demo.bat freelancer`, `demo.bat nobody` (CLI error, nothing started), and with a running app (refused). Expected as listed.
- [ ] **Step 3: Commit** `feat: demo.bat starts the app on a fresh showcase database`.

### Task 7: Screenshot generator

**Files:**
- Modify: `apps/desktop/lib/screens/import_screen.dart` (`_ImportScreenState` → `ImportScreenState`, `_import` → `@visibleForTesting Future<void> importPaths(List<String> paths)`, drop handler calls it), `apps/desktop/pubspec.yaml` (dev dependency `demo: any`)
- Create: `apps/desktop/test/demo/stops.dart`, `apps/desktop/test/demo_shots_test.dart`, `tools/demo-shots.ps1`

**Interfaces:**
- Consumes: Task 4 `fillShowcaseDatabase`, `couple`, `showcaseCsvName`; Task 5 `appClock`; `appFor(db)` (`lib/main.dart`).
- Produces:
  - `class DemoStop { final String id; final Future<void> Function(WidgetTester tester, Future<void> Function() settle, String csvPath) reach; }`
  - `final List<DemoStop> demoStops` with the 7 ids in order. Reach: `dashboard` → tap `Dashboard`; `import` → `Import`, then `tester.state<ImportScreenState>(find.byType(ImportScreen)).importPaths([csvPath])` inside `runAsync`; `review` → `Review` (queue of the dropped lines with their suggestion chips; nothing selected); `categories` → `Statistics` → `Categories` → tap the `Food` bar segment; `recurring` → `Recurring`; `trends` → `Compare`; `search` → Ctrl+K, type `costco`.

- [ ] **Step 1: Write** `demo_shots_test.dart`: `skip: Platform.environment['DEMO_SHOTS_OUT'] == null`; Segoe UI loaded as in `screens_smoke_test.dart`; 1440×900, dpr 1; `appClock = () => DateTime(2026, 10, 22, 12)`; showcase DB (couple) in memory, CSV written to a temp folder as `releve-carte.csv`; locale from `DEMO_SHOTS_LOCALE` (default `en`); app wrapped in a keyed `RepaintBoundary`; for each stop: reach, settle, expect no exception, write `demo-<n>-<id>.png` (`toImage` + `toByteData(format: png)` inside `runAsync`).
- [ ] **Step 2: Write** `tools/demo-shots.ps1 [-Out <folder>] [-Locale en|fr]`: `-Out` defaults to `docs\images` (created if missing), sets `DEMO_SHOTS_OUT` / `DEMO_SHOTS_LOCALE`, runs `flutter test test/demo_shots_test.dart` in `apps/desktop`.
- [ ] **Step 3: Run** `tools\demo-shots.ps1 -Out <scratchpad>\shots`. Expected: 7 PNGs; open each, check the stop shows its point (spec table). Fix reach steps until they do.
- [ ] **Step 4: Run** `test-all.bat`. Expected: PASS, shots test reported skipped.
- [ ] **Step 5: Commit** `feat(desktop): demo screenshots from a widget test`.

### Task 8: Walkthrough doc, README, status

**Files:**
- Create: `docs/13-demo.md`, `apps/desktop/test/demo_doc_test.dart`, `docs/images/demo-*.png` (generated)
- Modify: `README.md`, `CLAUDE.md` (Status, Layout `packages/demo`, Tooling `demo.bat` / `demo-shots.ps1`, `EXPENSES_TODAY`), `docs/08-roadmap-open-questions.md` (remove B37), `docs/12-done.md` (B37 row dated)

- [ ] **Step 1: Write the failing guard** `demo_doc_test.dart`: `docs/13-demo.md` contains `` `<id>` `` for every `demoStops` id. Run `flutter test test/demo_doc_test.dart`. Expected: FAIL (no file).
- [ ] **Step 2: Write** `docs/13-demo.md`: who it's for; setup (`demo.bat [couple|freelancer]`, close your own app first, the CSV in the Explorer window); the 7 stops — table: stop id, what to click, what to say (spec walkthrough table); freelancer tour (balances, trends with August 2025 and March 2026, yearly target, quarterly taxes in Recurring); regenerating images (`tools\demo-shots.ps1`, look before committing). Run the guard. Expected: PASS.
- [ ] **Step 3: Generate images** `tools\demo-shots.ps1`; look at each.
- [ ] **Step 4: README** — "See it first" after the intro list: 4 images (`dashboard`, `review`, `categories`, `recurring`) + one line: `demo.bat` tries the app on made-up data, without your statements.
- [ ] **Step 5: Status docs** as listed in Files.
- [ ] **Step 6: Run** `test-all.bat`; build release (`flutter build windows --release --no-tree-shake-icons` in `apps/desktop`, owner's app closed); run `demo.bat` and walk the 7 stops. Expected: PASS, every stop as in the doc.
- [ ] **Step 7: Commit** `docs: demo walkthrough and README images`; then `package-desktop.bat` (shared app changed).
