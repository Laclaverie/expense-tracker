# 08 — Roadmap & open questions

## Milestones

| # | Milestone | Content | Done when |
|---|-----------|---------|-----------|
| M0 | Design | These docs reviewed, open questions answered | Docs approved |
| M1 | Parser core | Desjardins account + card parsers, validation, anonymized fixtures, CLI to dump result | All 2026 statements parse and validate — **done 2026-10-17** (`packages/import_desjardins`, 14 anonymized fixtures) |
| M2 | Desktop MVP | Import, transactions table, categories, merchants, rules, transfers, dashboard by category/merchant | Jan–Sep 2026 imported and categorized — **done 2026-10-17** (`apps/desktop`: import, review, transactions, splits, targets, dashboard, rules, FR/EN). Deferred: DB encryption |
| M3 | Android MVP | Quick add, share-to-import, review queue, month view | Daily use for 2 weeks |
| M4 | Sync | Phone ↔ desktop | Entry on phone visible on desktop, no duplicates |
| M5 | LCL | LCL PDF parser, EUR scope, trips across scopes | One LCL month imported and validated |
| M6 | Insights | Subscriptions, trends, anomalies, target history, trip reports, export | — (recurring payments done 2026-10-18: Statistics → Recurring, `core/recurring.dart`) |

## Backlog (to do)

Work still to do, in suggested order inside each group. IDs refer to [doc 02](02-requirements.md). Finished
items move to [12 — Done](12-done.md) with their date; the reasons behind choices stay in the decision log
below.

| # | Feature | Req | Notes |
|---|---------|-----|-------|
| **Medium** | | | |
| B6 | Tags | CAT-6 | Free multi tags, filter in Transactions and Statistics; new table + schema migration |
| B7 | Trips + trip report | CAT-7, ANA-6 | Name + date range, auto-assigned by date; report total / per day / per category, with a day-by-day timeline (date, town, spending). Before M5 (trips across banks); base for B8b |
| B8a | Places table | ANA-9 | Spending per province and per city from the statements' location (card lines only), sortable, with an honest "no place" line (account debits, online shops, phone numbers). No map, no extra data |
| B8b | Offline map | ANA-9 | Desktop only (Android stays light). No tiles or geocoding API (local only): bundled simplified province/country shapes (~1–2 MB) drawn by the app, city coordinates from a trimmed GeoNames list (Canada, later France). City dots sized by spending; a trip's route in date order. Cities cut at 13 characters and `CA` (California / Canada) need care. After B7 + B20, which give the day-by-day timeline |
| B9 | Generic CSV layout | IMP-10 | A `CsvLayout` described as data, once a second bank with a CSV export exists (extract the common part from real cases; the Desjardins reader is in [12](12-done.md)). Banks without a balance column: "not verified" (`StatementFormat.uncheckedFileTypes`) |
| B28 | Real checks on a friend's files | — | A friend's masked copy can't be parsed (dates and words masked), so their import is the only real check: a data-free report they can run from the app and send back (like `banks:check`). Tools done so far: [12](12-done.md) |
| B29 | Generic OFX / QFX importer | IMP-10 | One reader for 1.x (SGML) and 2.x (XML); per-bank quirk list (merchant in `NAME` / `MEMO`, card sign, `FITID` trusted or not); institution id from the OFX bank name, reused by a later PDF plug-in. Check: previous closing balance + lines = closing balance |
| B32 | Declarative bank formats (later, not planned) | — | Runtime-loaded format files, no rebuild. Only after LCL is written in Dart and with demand from outside the repository. [Doc 11](11-import-sources-onboarding.md) §3 |
| B10 | Recurring templates + upcoming payments | CAP-9, ANA-15 | Expected payments shown ahead on the dashboard, next-month cash-flow forecast |
| **Found while parsing** | | | |
| B13 | Check the November 2026 card statement | IMP-2 | October 2026 layout dropped the Bonidollars rate per line ("back on the next statement"): the categorizer's reward-rate hint is missing for October. The 2026-10 parser reads the column if it returns; run `banks:parse` on it and add a fixture |
| B14 | Clear message for an unknown layout | IMP-5 | Import screen: "this statement looks like Desjardins but its layout is new" (first-page bank name found, no layout matched) instead of "not recognized", with the steps to report it |
| B15 | Financing plans on card statements | IMP-2 | New layout shows "plans de financement" (installments) in the summary and minimum payment; not modeled yet — a statement with one would fail the new-balance check (refused, not wrong) |
| B33 | Desjardins CSV: last unknown line types | IMP-10 | Wording of the PDF codes RA (pre-authorized debits, 34 lines), some DI deposits (3, counted as refunds) and DT (1, a fee counted as expense): rules once the owner gives the first words |
| B34 | Desjardins export guide: step 4 | — | What AccèsD asks after "téléchargez la liste des transactions" (accounts, period, format): confirm the wording, third screenshot |
| **Faster review ("À vérifier")** | | | |
| B16 | Group the review queue by merchant | CAT-4 | One card per merchant (count, total), decided once for all its lines |
| B19 | Keyboard review | — | Enter confirm, 1–3 pick a suggestion, ↑/↓ move, C copy name for search |
| B20 | Trip detection in review | CAT-7 | Run of lines away from home over a few days → "assign N lines to Travel / a trip?" (with B7) |
| **Finding a category (picker)** | | | |
| B25 | Search by merchant | CAT-2 | Typing `Costco` ranks the categories used for that merchant before |
| B26 | Example merchants per category | — | Tooltip with the user's own top merchants of that category, to tell close categories apart |
| B27 | Typo-tolerant, word-start matching | — | `restau`, `epicrie` still match; small local scoring, no library |

## Open questions (need answers)

### Product
_None open right now._

### Decided

| Date | Decision |
|------|----------|
| 2026-10-17 | Focus on Desjardins; LCL (PDF statements) later |
| 2026-10-17 | One currency per account, no currency conversion |
| 2026-10-17 | Stats per institution only (Desjardins, LCL, Cash); no combined stats for now |
| 2026-10-17 | Transfers between banks not reconciled — accepted limitation; tagged and excluded from spending |
| 2026-10-17 | Cash tracked, manual entry only |
| 2026-10-17 | Analysis + targets per week / month / year; no envelope budgeting |
| 2026-10-17 | Weeks start Monday |
| 2026-10-17 | ATM withdrawal automatically credits the Cash wallet of that currency |
| 2026-10-17 | UI in French and English from the start |
| 2026-10-17 | Interac transfers to people count as spending (category People) |
| 2026-10-17 | PDFs are not kept by the app (only hash + metadata) |
| 2026-10-17 | Private GitHub repo `expense-tracker` |
| 2026-10-17 | Other Desjardins products supported later; first: checking (EOP) + Odyssée Mastercard |
| 2026-10-17 | Android app light (capture + summary); desktop app carries the heavy features |
| 2026-10-17 | Everything runs locally — no external API at runtime |
| 2026-10-18 | Banks are plug-ins: one folder per bank in `packages/banks` (contract, `LineRule` tables, registry) so friends can add theirs by pull request; playbook for agents in doc 10. Scopes are per institution **and currency**. Personal agent notes moved to a git-ignored `CLAUDE.local.md` |
| 2026-10-18 | Stats per account as well as per institution (account picker in the top bar). "All accounts" statistics start when every statement type exists (first card statement), so missing card history doesn't lower spending; one account shows its whole history. Targets stay per institution |
| 2026-10-18 | Balances tab: month-end balance per account rebuilt backwards from the latest statement balance; deposits / withdrawals / interest per year |
| 2026-10-24 | Learned classifier (B12) only suggests (one-click chips in review), never sets a category: measured on the owner's data, never-seen shops got the right top guess ~33 % of the time, right category among the chips ~47 %. A suggestion needs a shared word of the shop name; the city alone is not enough. Revisit when there is more history |
| 2026-10-24 | Desjardins changed the card statement layout (October 2026, new card system). Parsers are kept per layout (`cardLayouts`), newest first, same format id and account; a statement no layout recognizes is refused, never guessed |
| 2026-10-25 | Onboarding someone with another bank: they ask a coding agent to write the plug-in. A cloud agent never sees statement data: it works from `banks:shape` (masked layout) and `banks:check` (data-free report) — doc 10 §0b. Export formats (CSV, OFX) are not normalized between banks or countries, so the same loop applies to every file type. `ImportedStatement` stays the one bank-neutral format; order: shape/check (B28), OFX (B29), CSV layout (B9). Friends work in a fork; PRs touch only their bank's folder |
| 2026-10-31 | Desjardins exports transactions as CSV (AccèsD, last 18 months, custom range): CSV is the preferred source, PDF readers stay for older months and as a fallback. Each bank keeps its own CSV reader (no shared layout yet). Measured with `banks:compare` on 18 months: every CSV line of the checking and savings accounts found in the PDFs on the same date and amount, card 465 of 467 (2 lines after or between the statements held): the PDF readers are reliable. A card CSV has no balance: imported as "not verified" rather than refused |
| 2026-10-31 | Same days from a PDF and a CSV count once (B30): match on account + date + amount, the stored line wins; unmatched lines are imported and reported, never dropped or added silently. During the transition the owner compares a CSV-only database (`EXPENSES_DB_DIR`) with the PDF one |
| 2026-10-31 | Each bank documents how to download its export (`BankImporter.exportGuide`: steps FR/EN + screenshots with personal data hidden); a PDF import of such a bank points to it |
| 2026-10-31 | Database encryption (B11): the whole file encrypted (SQLite3MultipleCiphers in SQLCipher 4 mode), key derived from a password typed at every start (more than 16 characters, typed twice when chosen). No key stored anywhere: no Windows DPAPI or OS keyring (the owner may move to Linux; a key tied to the system can be read by any program running as the user, and is lost with the computer). Mandatory for everyone; an existing plaintext database and the automatic copies are encrypted at the first start. Password only, no recovery key (a recovery key = a second file to carry, raw-key access for outside tools; writing the password down is equivalent): forgotten = data lost, the setup screen says so. Moving computer or system = one file + its password; the file also opens in DB Browser for SQLite (SQLCipher) or `sqlcipher`. Supersedes the 2026-10-25 entry |
| 2026-10-25 | Database encryption (B11) deferred: the owner and the first friend change laptops soon, and a key tied to the Windows account (DPAPI) would lock them out of their data and copies on the new machine. When done, it must come with a tested path to a new computer (e.g. password-protected manual copy). Until then: full-disk encryption (Windows Device encryption / BitLocker); moving computer = manual copy + restore (B1) |
| 2026-10-18 | Recurring payments detected automatically (no confirmation step): same merchant, regular interval, similar amount; the date may drift (bills paid by hand). Rent to a person is included |
| 2026-10-17 | Tech approved: Flutter/Dart both apps, PDFium for PDF text, desktop-only import, LAN sync with desktop as source of truth (doc 09) |

Technical choices: decided 2026-10-17, see [doc 09](09-tech-choices.md).

## Risks

| Risk | Mitigation |
|------|-----------|
| Bank changes PDF layout | Parser versioning, strict validation (fails loudly), fixture per layout version |
| Text extraction misalignment (observed) | Coordinate-based parsing + balance validation |
| Double counting (card payment, transfers) | Transfer detection + "Excluded" categories + review |
| Bank-to-bank moves look like spending | `external_transfer` kind + rule for known destinations (Wise, own LCL account) |
| Duplicates manual vs import | Matching step with user confirmation |
| Sensitive data leak | Local-first, encrypted DB, `.gitignore`, synthetic fixtures and demo (`packages/demo`), public repo published from a fresh history |
| Motivation drop | MVP desktop import first — gives value from existing PDFs without any daily habit |
