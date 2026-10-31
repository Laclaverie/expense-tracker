# 02 — Requirements

> Design document written before the code (October 2026). What is built: the [README](../README.md) and the
> [roadmap](08-roadmap-open-questions.md); where the plan changed, its decision log wins.

Priority: **M** = MVP, **S** = soon after, **L** = later.

## Functional

### Accounts

| ID | Requirement | Prio |
|----|-------------|------|
| ACC-1 | Multiple institutions: Desjardins (M), LCL (L), Cash (M) | M |
| ACC-2 | Account types: checking, savings, credit card, cash, TFSA/registered | M |
| ACC-3 | Each account has exactly one currency (CAD, EUR, …). No conversion anywhere | M |
| ACC-4 | Cash wallets per currency (CAD cash, EUR cash). Manual entries only, never imported | M |
| ACC-5 | Account balance tracked from statements (statement balance = source of truth); month-end balance history rebuilt backwards from it — **done** (Statistics → Balances) | S |
| ACC-7 | Other Desjardins products (other cards, line of credit) | L |
| ACC-6 | One physical credit card account may have several card numbers over time (replacements) | M |

### Capture — manual entry (mobile + desktop)

| ID | Requirement | Prio |
|----|-------------|------|
| CAP-1 | Quick entry: amount, category; defaults for date (now), account (last used / context), currency (account's) | M |
| CAP-2 | Optional: merchant, note, tags, trip, location | M |
| CAP-3 | Merchant autocomplete from history; picking a merchant pre-fills its usual category | M |
| CAP-4 | Works offline | M |
| CAP-5 | Manual entry later matched to the imported statement line (same amount ± date window) → merged, not duplicated | M |
| CAP-6 | Home screen widget / quick action "add expense" | S |
| CAP-7 | Split one transaction into several categories (e.g. Costco: groceries + household) | S |
| CAP-9 | Recurring templates (rent, subscriptions) | S |

### Import — statements

| ID | Requirement | Prio |
|----|-------------|------|
| IMP-1 | Import Desjardins **account statement PDF** (EOP first; ET / CELI sections parsed for transfers) | M |
| IMP-2 | Import Desjardins **credit card statement PDF** (Odyssée Mastercard) | M |
| IMP-3 | Android: share PDF to the app ⇒ forwarded to desktop at next sync (no parsing on phone) | L |
| IMP-4 | Import on desktop: drag & drop one or many files (PDF statements, CSV exports) | M |
| IMP-5 | Validate import against statement totals / running balances; show mismatch | M |
| IMP-6 | Detect already-imported statements and duplicate lines (idempotent re-import) | M |
| IMP-7 | Import review screen before commit: new / duplicate / matched-to-manual / transfer | M |
| IMP-8 | Keep original foreign amount + rate when present (e.g. `79,97 DOLLAR AMERICAIN TX: 1.422158`) | M |
| IMP-9 | LCL PDF statement import (after Desjardins is solid) | L |
| IMP-10 | CSV / OFX exports: per-bank readers (Desjardins done 2026-10-31); generic column mapping later | L |
| IMP-11 | Parser plug-in design: one parser per institution/format, versioned | M |
| IMP-12 | Original PDF is **not** kept by the app: parsed, then discarded. Only file hash + statement metadata stored (re-import detection) | M |

### Transfers & double counting

| ID | Requirement | Prio |
|----|-------------|------|
| TRF-1 | Detect internal transfers within the same bank: EOP ↔ ET, checking → credit card payment (`PWW … Mastercard` ↔ `PAIEMENT CAISSE`) | M |
| TRF-1b | ATM withdrawal (`IRGA`) = transfer bank → cash wallet: the same amount is **automatically added** to the Cash wallet of that currency; cash spending then entered manually | M |
| TRF-2 | Transfers excluded from spending stats | M |
| TRF-3 | Transfer to/from another bank (e.g. Desjardins → LCL via Wise): tagged "Transfer to another bank", excluded from spending, **not linked** to the other side (accepted limitation) | M |
| TRF-4 | Refunds / cancellations (`Annulation`, `CR` lines) linked to original when possible | S |
| TRF-5 | Interac transfers to people = **expense**, category People (no reconciliation with shared costs). Interac received from people = income "Reimbursements from friends" | M |

### Categorization

| ID | Requirement | Prio |
|----|-------------|------|
| CAT-1 | Two-level category tree, editable (see doc 05) | M |
| CAT-2 | Merchant normalization: `TIM HORTONS #8517` → merchant "Tim Hortons" | M |
| CAT-3 | Rules: merchant/description pattern → category, tags | M |
| CAT-4 | Rule auto-proposed when user re-categorizes ("apply to all Tim Hortons?") | M |
| CAT-5 | Use bank hints (Bonidollars rate, transaction code) as weak signal | S |
| CAT-6 | Tags (free, multi): `work`, `gift`, `shared`, … | M |
| CAT-7 | Trips: name + date range (+ countries); transactions auto-assigned by date, editable | S |
| CAT-8 | Local classifier (naive Bayes / TF-IDF on description) trained on own categorized lines; weak signal before keywords | L |

### Targets

| ID | Requirement | Prio |
|----|-------------|------|
| TGT-1 | Spending target per category (or category group, or total) with period **week (Monday–Sunday), month or year** | M |
| TGT-2 | Target belongs to one scope (institution or cash wallet) and is in that scope's currency | M |
| TGT-3 | Progress shown: spent / target, % used, projected end-of-period at current pace | M |
| TGT-4 | History: hit / missed per past period | S |
| TGT-5 | Optional alert at 80 % / 100 % (mobile notification) | S |
| TGT-6 | Targets are analysis only — no money allocation, no rollover | M |

### Analysis (desktop mostly)

| ID | Requirement | Prio |
|----|-------------|------|
| ANA-1 | Spending by category over time (month / quarter / year) | M |
| ANA-2 | Spending by merchant: top N, history of one merchant; stores inside one category (purchases per month, average basket) — **done** | M |
| ANA-3 | Every view is scoped to **one institution** (Desjardins, LCL, or Cash-CAD / Cash-EUR); inside it, filter by account, category, tag, trip, date range. Account filter **done** (top bar) | M |
| ANA-4 | No combined cross-bank / cross-currency stats (explicit non-goal for now) | — |
| ANA-5 | Income vs expenses, savings rate per month | S |
| ANA-6 | Trip report: total, per day, per category, per country — per institution, no currency mix | S |
| ANA-7 | Recurring / subscription detection (YouTube, Patreon, phone…), including bills paid by hand on a drifting date — **done** (Statistics → Recurring) | S |
| ANA-8 | Anomalies: unusual amount for a merchant, new fees (e.g. `Frais effet retourné`), price change of a recurring payment | S |
| ANA-9 | Location view: spend per city/province/country (card lines carry city + province) | L |
| ANA-10 | Export CSV / Excel | S |
| ANA-11 | Mobile: simple month view per institution — total, by category, targets, last transactions | M |
| ANA-12 | Accounts with different history lengths must not bias stats: all accounts together only over the period every statement type covers; one account over its whole history — **done** | M |
| ANA-13 | Savings follow-up per account: balance over time, deposits / withdrawals / interest per year — **done** | S |
| ANA-14 | Global search (Ctrl+K): find any transaction by merchant, amount, date or note | S |
| ANA-15 | Upcoming payments: expected recurring payments and templates shown ahead, with a cash-flow forecast for the next month | S |

## Non-functional

| ID | Requirement |
|----|-------------|
| NFR-0 | **Local only**: no external API or service at runtime (no cloud, no FX API, no aggregator) |
| NFR-1 | **Privacy**: data stored locally, encrypted at rest on mobile; no third-party analytics; sync only through user-controlled channel |
| NFR-2 | **Offline-first**: both apps fully usable offline |
| NFR-3 | **Sync** phone ↔ desktop over local network only; desktop is source of truth (doc 09) |
| NFR-4 | **Bilingual UI** FR / EN from day one (all strings localized, language switch in settings, default = device language); parsers handle FR bank formats (`1 234,56`, `1 234.56`, `MAI`, `AOÛT`, trailing `-`, `CR`) |
| NFR-5 | Money stored as integer minor units + currency code. Never floats |
| NFR-6 | Import of one monthly statement < 3 s on desktop. Android app stays small and fast (no PDF engine) |
| NFR-7 | Parsers covered by tests on synthetic fixtures (a made-up household written in each bank's layout); validation failure never silently commits wrong data |
| NFR-8 | Backup / export of the whole database in an open format |
