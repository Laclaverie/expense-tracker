# 07 — Desktop UX

> Design document written before the code (October 2026). What is built: the [README](../README.md) and the
> [roadmap](08-roadmap-open-questions.md); where the plan changed, its decision log wins.

Desktop = **review, clean, understand**. Keyboard-friendly, dense tables, drill-down everywhere.

## Layout

```
┌─────────────┬──────────────────────────────────────────────────────┐
│ Dashboard   │  [Desjardins ▾]  [Sep 2026 ▾] [All accounts ▾] [+]   │
│ Transactions│──────────────────────────────────────────────────────│
│ Review (12) │                                                      │
│ Analysis    │                 main view                            │
│  · Category │                                                      │
│  · Merchant │                                                      │
│  · Trends   │                                                      │
│  · Trips    │                                                      │
│  · Map      │                                                      │
│ Imports     │                                                      │
│ Targets     │                                                      │
│ Rules       │                                                      │
│ Accounts    │                                                      │
│ Settings    │                                                      │
└─────────────┴──────────────────────────────────────────────────────┘
```

Top-level **scope selector**: Desjardins | LCL | Cash CAD | Cash EUR. Every view shows one scope only, in its currency.
Filter bar inside scope: date range, accounts, categories, tags, trip, include/exclude transfers.

**Account picker** (next to the scope, built): *All accounts* or one account of the institution (checking,
savings, TFSA, card; the 5 $ qualifying share is hidden). Dashboard, statistics, transactions and review
follow it; targets stay per institution.

### Accounts with different histories

Accounts don't have the same history (for example: checking imported since 2021, savings since 2024, a card
opened last year). Mixing them over the full span would make older months look cheaper (no card statement ⇒ card
spending missing). Rules:
- **One account**: its whole history; coverage only counts that account's statement type.
- **All accounts**: statistics start at the first month **every** statement type exists. A notice says from
  when and why, and suggests picking an account for the full history.
- Months inside the range that miss a statement stay counted in totals but excluded from averages and
  comparisons (existing coverage rule).
- Balances and recurring payments always use the whole history (no spending-range notice on those tabs).

## Views

### Dashboard
- KPIs: spent this month, vs avg of last 6 months, income, savings rate (for the selected scope).
- Targets summary: on track / at risk / over.
- Stacked bars: monthly spend by category group, last 12 months. The window stays on the latest months with
  data (moves by whole years only when the selected month leaves it); the selected month is highlighted and a
  click on a bar selects its month.
- Top 10 merchants this period.
- Subscriptions detected and monthly total (built in Statistics → Recurring, not on the dashboard yet).
- Alerts: import mismatch, new fees, unusual amount.

### Transactions
Spreadsheet-like table. Columns: date, account, merchant, raw description, category, tags, trip, amount, original amount.
- Multi-select + bulk edit (category, tag, trip).
- Inline edit, keyboard shortcuts (`c` category, `t` tag, `↑↓`).
- Group by day / merchant / category.
- Show provenance (statement period + page + line). PDFs are not kept by the app.

**Export (built):** *Export…* saves exactly what the page shows (bank or account, month or all dates, category,
search) as Excel (`.xlsx`, real dates and numbers) or CSV (`;` and decimal comma in French, `,` and dot in English,
UTF-8 with BOM). One row per transaction, one per part of a split transaction; columns: date, bank, account,
merchant, description, group, category, type, amount, currency, original amount and currency, note.

### Review
Same as mobile queue, table form: new merchants, low-confidence categories, possible duplicates, unmatched transfers.

### Analysis — by category
Tree table (group → category → merchant) with amount, % of total, monthly average, trend sparkline.
Click any cell ⇒ filtered transactions.

### Analysis — by merchant

Merchants are businesses: transfers to or from people (Interac — rent paid to a landlord, money sent to
friends) count as spending in their category but never appear in merchant rankings.
- Ranking by total / count / average ticket.
- Merchant detail: monthly history, average ticket, locations, category.
- Merge / rename merchants here.

### Notifications (built)

Bell in the top bar with a badge; the list opens below it. Today one kind: **a statement to download**. For each
bank and statement type, the next statement should end one month after the latest imported one (a month end
stays a month end); 3 days after that date (banks publish a few days later) it becomes a notification, and a
message at every start says how many statements are waiting, with *Import*. Importing the statement clears it
(`core/reminders.dart`).

### Statistics periods (built)

Ranges (6 / 12 months, this year, last year, everything) end with the **latest month with data**, never with the
month selected in the top bar: that selector is hidden on Statistics (it silently cut "this year" short). Compare
has its own month arrows, starting on the latest month.

### Analysis — narrowing to a category (built)

Statistics can be narrowed to one group or category: click a group card in Trends, or the trend icon on a
row of Categories. A chip next to the range shows it (✕ = everything). Every tab follows:
- **Trends**: KPIs for that category only; *Spending by store* — monthly bars stacked by store (top 5 +
  Other, fixed palette order, average as a dashed line); for a group, one card per category (click =
  narrow further, e.g. Food → Groceries); one card per store: total, change vs previous period, per month,
  purchases per month, average basket and its change. Click a store ⇒ its transactions in that category.
  Income vs spending is not shown (no income in a category).
- **Categories / Merchants**: only that group's rows and its stores.
- **Compare**: per category instead of per group.
- **Recurring**: only payments in that category.

Why not one line per category or per store on the income/spending chart: more than 5–6 lines is unreadable
and income would flatten the small ones. Stacked bars show where the money goes; small multiples show each
store's own trend.

Costco and Costco Essence (fuel) are separate merchants, so the fuel stays out of Food.

### Analysis — trends
- Line chart per category over months; compare periods (this year vs last).
- Income vs expenses, cumulative net.
- Heatmap day-of-week × hour (manual entries only have time).

### Analysis — recurring payments (built)

Statistics → Recurring. Found automatically in all imported history, no setup:
- Same merchant, regular interval (weekly, every 2 weeks, monthly, quarterly, yearly), similar amount.
- The date may drift (a phone bill paid by hand between the 12th and the 18th) and some months may be missing
  (statement not imported): up to two missed periods in a row, a quarter of the payments may be left out.
- The amount may vary (extras on a bill, price change): typical amount = median of the last three payments;
  the min–max range is shown.
- Two series at one merchant (two insurance policies) are separated by amount.
- Columns: merchant + category, frequency + days of the month, amount, cost per month, payments, last,
  next expected. Click ⇒ the merchant's transactions. KPI: total per month of active ones.
- A series not seen for a while (more than half a period after its expected date) moves to
  *Not seen lately (probably stopped)* and leaves the monthly total.
- Rent to a person is included (person icon).

### Analysis — balances (built)

Statistics → Balances. For checking, savings and registered accounts (not cards or cash):
- Card per account: balance at the end of the range, change over the range, interest earned.
- Line chart: month-end balance, one line per account.
- Table per year: deposits, withdrawals, interest, change, balance at the end.
- Balances are rebuilt backwards from the latest statement balance; walking back stops at a month without
  statement (earlier balances would be wrong). Transfers between own accounts count as deposits/withdrawals.

### Analysis — trips
List of trips: dates, total per scope (e.g. Desjardins 1 240 $ · Cash EUR 180 €, never summed), per day. Trip detail: by category, by day, by city; flights/lodging separated
from on-site spending.

### Analysis — map (later)
Spend by city/province/country from card location fields.

### Imports
History of imported statements: institution, account, period, status (validated / mismatch), line counts.
Drag & drop zone. Gap detection: "Missing Desjardins account statement for June 2026".

### Targets
- List per scope: category (or total), period (week / month / year), target, spent, %, projected.
- Create / edit target; suggest a value from the average of last 3 periods.
- History grid: periods × targets, green = hit, red = missed.
- Targets are indicators only: nothing is blocked or moved.

### Rules
Table of rules: condition → actions, hit count, last hit. Test a rule against history before saving.

### Accounts
Balances per account (from last statement), grouped by institution. No converted grand total.

## Currency display

- One scope = one currency, so every total is in a single currency. No conversion, no reporting currency.
- Card lines bought abroad show the original amount as small secondary info (`79,97 USD @ 1.4222`).
