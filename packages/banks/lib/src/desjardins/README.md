# Desjardins plug-in

Reads the AccèsD **CSV export** (`csv/`, preferred: last 18 months) and the monthly **statement PDFs** (`pdf/`,
older months), with the same format ids and account refs, so both land in the same accounts.

## CSV export (`csv/reader.dart`)

| File | Columns | Checks |
|------|---------|--------|
| Accounts (all of them, one block each) | 16: caisse, folio, account code (`EOP`, `ET01`…), date, sequence, description, cheque, withdrawal, deposit, 5 loan columns (empty), balance, Interac message | every running balance (days oldest first, a day's lines newest first) |
| Card | 13: card name + `**** <card used>`, date, sequence, description (merchant 25 + city 13 + province), purchase, credit | none: not verified |

Rules: `csvAccountRules`, `csvCardRules` (descriptions; the CSV has no codes). Anything outside this layout is
refused (a loan column with a value, two folios, both or no amounts).

## Statement PDFs

Parses Desjardins statement PDFs and checks each one against its own figures:

| Statement | Parsed | Checks |
|-----------|--------|--------|
| Account ("Relevé de compte") | period, sections (`EOP`, `ET 1`, `ET 2`, `CS`), lines with code, fee / withdrawal / deposit, running balance | every printed running balance |
| Odyssée World Elite Mastercard | statement date, summary, lines per card (dates, description, location, Bonidollars rate, amount, foreign amount), operations (payments, rewards, fees) | `TOTAL` per card, debits = *Achats / débits*, credits = *Paiements / crédits*, new balance |

The card statement has two layouts (`cardLayouts` in `detect.dart`), both read into the same `CardStatement`:
`card_parser.dart` (until September 2026) and `card_parser_2026.dart` (new card system, from October 2026: full
dates, merchant + city + province in one run of words split by `splitMerchant`, no Bonidollars rate per line,
foreign amount on two rows, payments and credits apart in the summary).

A statement that fails a check must not be imported silently.

It is a bank plug-in (`DesjardinsImporter`, registered in `lib/banks.dart`) and the reference implementation
for [adding a bank](../../../../../docs/10-adding-a-bank.md). Line kinds and category hints: the `accountRules`
and `cardRules` tables in `pdf/to_core.dart`.

## Command-line tools (from `packages/banks`, work for every registered bank)

```sh
# Summary per file (PDF or anonymized .json); -v prints every line (personal data!)
dart run banks:parse statements/*.pdf

# Build test fixtures from real PDFs
dart run banks:anonymize --out test/fixtures/desjardins --extra ../../../desjardin/anonymize-extra.txt statements/*.pdf
```

The Desjardins anonymizer replaces the holder name and address, account / folio / contract numbers, card digits, Interac
counterparties, booking references and every word in the `--extra` file (one per line: employer, policy number…;
keep that file **outside** the repository). It writes a fixture only if:

1. the original statement validates,
2. no personal string found in the document remains in the output,
3. the anonymized copy parses to exactly the same dates, amounts and check results.

Fixtures keep dates, amounts and merchant names (needed to test parsing and, later, categorization).
