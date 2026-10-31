## What

<!-- Bank / statement types added or what changed. For a bank: statement types and the period tested,
e.g. "checking + Visa, 2024-01 → 2026-09, 33 statements, all VALID". Never paste real statement content. -->

## Checklist

- [ ] No PDF, CSV, `banks:dump` / `banks:parse -v` output or real value in the diff; fixtures only from
      `dart run banks:anonymize`, searched for the holder's name, street and account digits
- [ ] No existing `institution`, format id, account ref scheme or category id renamed
- [ ] (bank) every code / label prefix is a `LineRule` row (no warning from `banks:parse`) and listed in `docs/04-statement-import.md`
- [ ] (bank) self-checks cover every amount; `dart run banks:check` VALID on all my files (and
      `dart run banks:compare` when the bank has both PDF and export readers)
- [ ] `test-all.bat` passes (GitHub's check on this pull request is green)
- [ ] Tried in the app on a scratch database (`EXPENSES_DB_DIR`)
- [ ] Docs updated (plug-in `README.md`, `docs/`)
