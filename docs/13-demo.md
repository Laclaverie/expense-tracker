# 13 — Showing the app (demo)

How to show the app to someone, live or with pictures, on made-up data that is the same every time. Decided
2026-11-01 (B37). Design: `docs/superpowers/specs/2026-11-01-demo-showcase-design.md`.

---

## 1. Personas

Two made-up people (`packages/demo`), two years each (2024-10-21 → 2026-10-20), always the same data:

| Persona | Who | What it shows best |
|---------|-----|--------------------|
| `couple` (main) | Two adults renting in Montréal, no car, salaries, two cards, savings and a TFSA | The whole walkthrough below; the README images |
| `freelancer` | One person in a downtown apartment (Ville-Marie), no car, paid by clients at uneven times | Income that comes and goes, quarterly taxes, a yearly target |

Both bank at Desjardins (the only bank the app reads so far). Nothing in them is real: public chains with
invented store numbers, made-up shops and people.

## 2. Setting up

1. Close the app if it is open (the demo refuses to start otherwise: your own data must not be on screen).
2. Double-click `demo.bat` (or `demo.bat freelancer`). It builds a fresh demo database in
   `%LOCALAPPDATA%\expense-tracker\demo\<persona>` (never your own file), opens that folder and starts the app.
   It needs a built app: run `build-desktop.bat` once before.
3. Keep the folder window next to the app: it holds the card exports (`releve-carte-0011.csv`,
   `releve-carte-0022.csv`) you drop at the import stop.

The app starts on the demo database directly (its public password, `demo database password`, is given by
`demo.bat`) and believes today is **October 24, 2026**, four days after the last card statement (so the bell asks for it). Run
`demo.bat` again to start over.

## 3. The walkthrough (couple, ~5 minutes)

| # | Stop | Where | What to do | What to say |
|---|------|-------|------------|-------------|
| 1 | `dashboard` | Dashboard | Point at the three tiles, the targets, the bell | "Two years of a household, imported from bank files, nothing typed. September at a glance: spent, income, how the targets stand. The bell: a statement to download, an unusual bill." |
| 2 | `import` | Import | Drag both `releve-carte-*.csv` from the folder onto the page | "This is the bank's own export. Dropped: 24 new lines, already sorted, the card payment matched with the checking account, and the bell's reminder is gone. Drop them again: nothing is counted twice." |
| 3 | `review` | Review | Open the one line left (Kickstarter), pick a category, confirm | "Known shops were sorted by themselves; only a new one asks. One click and it is learned." |
| 4 | `categories` | Statistics → Categories | Click the Food bar, then the "analyze only" icon of Groceries | "Where the money goes, rent apart. Groceries alone: month by month, and a card per store, how often and how much." |
| 5 | `recurring` | Statistics → Recurring (clear the Groceries chip first) | Scroll the list | "Found by itself: rent, transit pass, Hydro every two months, the dentist twice a year, and Virgin's bill that went up in September." |
| 6 | `trends` | Statistics → Compare | Switch "vs same month last year" | "Month against month, group by group: where it went up, where it went down." |
| 7 | `search` | Ctrl+K anywhere | Type `costco` | "Any shop, any line, instantly." |

Everything stays on the computer, encrypted with a password: say it at the end, it is the first question people
ask.

## 4. Freelancer tour (~2 minutes)

`demo.bat freelancer`, then:

- **Dashboard**: the yearly target ("all spending, $45,000 a year") instead of monthly ones.
- **Statistics → Trends**: income is not a straight line. August 2025: no client paid. March 2026: four
  invoices at once.
- **Statistics → Balances**: checking goes up and down with the invoices; savings grow in steps (money moved to
  savings after good months).
- **Statistics → Recurring**: Revenu Québec and Revenu Canada every three months (tax installments), coworking
  every month.

## 5. README images

`tools\demo-shots.ps1` renders the walkthrough stops as `docs\images\demo-<n>-<stop>.png` from a widget test
(`apps/desktop/test/demo_shots_test.dart`, stops in `test/demo/stops.dart`): no window opens, the couple's
data, English (`-Locale fr` for French). Run it after a visible UI change, look at every image, commit them.
`demo_doc_test.dart` checks this page names every stop.
