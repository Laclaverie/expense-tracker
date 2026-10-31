# expense_desktop

Windows desktop app: import bank transactions (CSV exports or PDF statements), review categories, analyze
spending.

| Screen | What it does |
|--------|--------------|
| Dashboard | Month spent / 6-month average / income, 12-month spending by category group, ranking by category and merchant |
| Statistics | Over 6 / 12 months, this or last year, or everything: trends (monthly spending vs average, income vs spending, per-group trend cards), categories table (total, monthly average, share, change vs previous period), merchant ranking with detail, period comparison, account balances over time (deposits / withdrawals / interest per year), recurring payments found automatically (subscriptions, bills paid by hand, rent) |
| Transactions | All lines of the selected scope and month (or all dates), search, filters, details, change category or type, split across categories, export to Excel or CSV |
| Review | Lines the app wasn't sure about. Confirm, or pick a category and remember it for the merchant |
| Targets | Limits per week (Mon–Sun), month or year for all spending, a group or a category: progress, end-of-period projection, history |
| Import | Drop CSV exports or statement PDFs (or choose files). Each is checked against its own balances or totals when it has some; the same days from a PDF and a CSV count once. Per bank: how to download its export. Statement coverage per month. "My bank isn't listed": masked copy to send |
| Accounts | Balances from the latest statements; cash wallets; add a cash expense |
| Categories & rules | Category tree, description rules, remembered merchants |

Statistics are always for **one scope**: Desjardins, LCL (later), or one cash wallet. Nothing mixes currencies.
The account menu next to the scope narrows every screen to one account (targets stay per institution).
Statistics can also be narrowed to one category (click a group card in Trends or the trend icon in
Categories): spending stacked by store, one card per store (purchases per month, average basket).
All accounts together are analyzed only from the first month every statement type exists (e.g. the first card
statement), so a shorter card history doesn't make older months look cheaper; one account shows its whole history.
Transfers between your own accounts, card payments and ATM withdrawals are not counted as spending.

## Run

Double-click `build-desktop.bat` at the repository root (builds the release, then starts the app).
`build-desktop.bat clean` does a clean build first. `run-desktop.bat` only starts the last build.

```sh
flutter run -d windows                      # from apps/desktop
flutter build windows --release             # build/windows/x64/runner/Release/expense_desktop.exe
```

Data: `%APPDATA%\dev.lasagna\expense-tracker\expenses.sqlite`. Imported files are not kept.

## Share with someone

Double-click `package-desktop.bat` at the repository root: it builds the app and writes
`dist\Depenses-windows.zip` (program + Visual C++ runtime + `LISEZMOI.txt`). Your data is never included.
To share your categories too: Categories & rules → Export… (categories, optionally rules and remembered
businesses; never transactions, amounts or people) and send the `.json`; they use Import….

## Demo / testing without real data

```sh
cd packages/demo
dart run demo:database C:\temp\demo\expenses.sqlite   # a made-up household, demo password
set EXPENSES_DB_DIR=C:\temp\demo
set EXPENSES_DB_PASSWORD=demo database password
expense_desktop.exe
```

If a newly added icon shows blank in a release build, run `flutter clean` (stale icon-font subset).

Real-PDF check (local only): `EXPENSES_STATEMENTS=<folder of PDFs> flutter test test/statement_reader_test.dart`.
