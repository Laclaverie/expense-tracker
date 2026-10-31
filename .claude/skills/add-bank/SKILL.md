---
name: add-bank
description: Add a bank, a statement type or a new layout of one as a plug-in in packages/banks, without ever seeing statement data. Use when someone wants the app to read a bank or card it doesn't support yet, sends a masked copy made by the app ("My bank or card isn't listed"), or a known statement stops being recognized (new layout).
argument-hint: "<bank name> [statements folder or masked-copy folder]"
---

# Add a bank

The full playbook is `docs/10-adding-a-bank.md`; this is the checklist to run it. Read doc 10 §0, §0b and §1
first, then `packages/banks/lib/src/desjardins/` (reference plug-in). Arguments: `$ARGUMENTS`.

## 0. Privacy gate (stop if any answer is wrong)

- You are a cloud agent unless you run on a local model: **never** read a statement (`.pdf`, `.csv`, `.ofx`,
  `.qfx`, `.qif`), `*.dump.txt`, `reveal.txt`, an extra-words list, `banks:dump` or `banks:parse -v` output. Not
  with Read, not with `cat` / `type` / `Get-Content`, not through a script you write. `.claude/settings.json`
  blocks the obvious ways; the rest is on you.
- Statements stay **outside** the repository. Never copy one in, never commit one.
- What you may read: `*.shape.txt` / `*.shape.json` (masked by `banks:shape` or the app), `banks:check` output,
  anonymized fixtures (`*.anon.json`) after the owner looked at them.
- Examples in code, docs and tests are made up (`PERSONNE01`, `ACME CORP`, `1 234,56`).

## 1. Find out what you have

Ask (one short message) only what you can't tell from the arguments:

| Question | Why |
|----------|-----|
| Bank name, country | `institution` id (lower case, stored forever), `displayName`, `country` |
| Statement types (account, card…) and file types (PDF, CSV, OFX) | one `StatementFormat` per type: `<institution>-<kind>`, ids stored forever |
| Where the statements are | decides the loop below |
| Does the bank export transactions (CSV, OFX)? How far back? | an export is the preferred source: write that reader first, the PDF one for older months |

Then pick the loop:

- **A. Statements on this machine** (the owner runs you): the owner approves the readable words first, in
  the app (Import → "My bank or card isn't listed", save the copy) or with
  `dart run banks:shape --candidates <reveal.txt> <files>` (the owner edits it, you never read it before).
  You then run `dart run banks:shape --reveal <reveal.txt> <file>` and
  `dart run banks:check --reveal <reveal.txt> <files…>` yourself (paths as arguments, never opened).
- **B. Only a masked copy** (a friend's folder from the app: `statement-N.shape.txt`, `.shape.json`, README):
  read the shapes. Your parser **cannot run on them**: digits are `9`s (day `99` is no date) and unapproved
  words, month names included, are `X`s, so it fails before any check. Test it on made-up rows that copy the
  shape (unit tests), then hand the friend a build (`package-desktop.bat`): their import is the real check
  (accepted, or refused with the failed check names, which only they see). Say plainly that nothing was
  checked on real data until they report back.
- **New layout of a supported bank**: same loops; keep the old parser, add one per layout picked from page 1,
  newest first (`cardLayouts` in `desjardins/pdf/detect.dart`), same model and ids.

## 2. Read the layout (masked)

For a CSV, first `dart run banks:shape --facts <file or folder>` (or the `#` lines at the top of a shape from
the app): columns, formats, blocks per account, line order and the running-balance formula, computed on the
real file without values. Read `notes.txt` if the owner wrote one.

From the shapes, write down (doc 10 §2): detection words only this statement type prints on page 1; header
(period, account numbers to anonymize, currency); table columns and their x ranges (amounts right-aligned →
`x1`); date and amount formats; how descriptions wrap; page headers and footers; **every total the statement
prints** (opening / closing balance, running balance, debit / credit totals): they become the self-checks.
List the transaction codes or label prefixes and what each means.

## 3. Write the plug-in (doc 10 §3–§6)

1. `docs/04-statement-import.md`: a section like the Desjardins ones (structure, formats, codes → kind, checks,
   pitfalls), made-up examples only.
2. `packages/banks/lib/src/<bank>/`: `importer.dart`, `detect.dart`, one `<format>_parser.dart` per statement
   type and layout, `rules.dart` (`LineRule` tables, never `switch`es), `to_core.dart`, `anonymizer.dart`
   (ends with `verifyAnonymized` / `verifyTextAnonymized`), `README.md`.
3. One line in `packages/banks/lib/banks.dart` (alphabetical).
4. Rules that are not negotiable:
   - coordinates, not text flow; rows by baseline (`groupRows`), amounts by column `x1`;
   - integer cents, money out < 0, `DateTime.utc`;
   - `checkCount > 0`: a statement that fails a check is refused by the app (fail loud, never guess);
   - `detect` reads page 1 only, never throws, returns null for anything else;
   - unmatched lines become warnings; add a rule row, never leave one.

## 4. Check, then fixtures

- When the bank has both PDF and export readers: `dart run banks:compare <folders>` (data-free) shows every
  line paired or not, which export wording each PDF code becomes, and kind / merchant agreement. Use the same
  format ids and account refs in both readers.
- Write the bank's `exportGuide` (steps FR/EN; the owner provides screenshots with personal data hidden).

- Loop A: `dart run banks:check --reveal <reveal.txt> <all statements>` until every file says VALID with no
  warning. Loop B: unit tests on made-up rows pass, then a build for the friend.
- Fixtures (loop A only): the **owner** runs `dart run banks:anonymize --out
  packages/banks/test/fixtures/<bank> --extra <extra.txt> <statements>`, looks at one fixture for their name,
  street and account digits, and tells you it's clean. Only then read or commit it.
- Tests: `test/<bank>/importer_test.dart` with `testFixtures(...)`, parser unit tests on made-up rows.
- `test-all.bat` (format, `analyze --fatal-infos`, every test) must pass.

## 5. Finish

- `README.md` bank table, `CLAUDE.md` status ("Banks:" line), `docs/08-roadmap-open-questions.md` if it closes
  an item (move it to `docs/12-done.md` with the date), `docs/04` section done.
- Commit locally (`feat(banks): …`), push only when the owner asks.
- Tell the owner what is checked (which files VALID, which checks exist) and what isn't (loop B: nothing real
  until the friend imports).
