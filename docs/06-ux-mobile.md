# 06 — Mobile UX (Android)

> Design document written before the code (October 2026). What is built: the [README](../README.md) and the
> [roadmap](08-roadmap-open-questions.md); where the plan changed, its decision log wins.
> **Changed 2026-11-08:** the first phone app is a **read-only viewer** of the desktop's data
> ([doc 14](14-mobile.md)): Home, Transactions, Statistics, Settings. The desktop sends its whole encrypted
> database file over the home Wi-Fi; there is no snapshot and no outbox. Quick add, share-to-import, the review
> queue and editing below are not built (quick add would come back as an outbox: backlog in doc 08).

Phone = **capture + glance**. Light app: no PDF engine. Built so far: the glance (read-only).
1. *(later)* Log an expense in seconds (mostly cash).
2. See this month and target progress at a glance — **built** (read-only).
3. *(later)* Confirm review items pushed by desktop; forward a shared PDF to desktop.

## Navigation

Bottom bar: **Home · Transactions · Statistics · Settings** (built, [doc 14](14-mobile.md)). Later, with quick
add (B38): a Review tab and a big `+` floating button.

## Quick add (the key screen)

Opens straight on the keypad. Amount first, everything else defaulted.

```
┌──────────────────────────────┐
│  ✕            Expense ▾   CAD│   ← currency = selected account's currency
│                              │
│            12.50             │
│                              │
│  ☕ Coffee  🛒 Groceries  🍽 Resto│   ← top 6 categories, ordered by
│  🚌 Transit 🍺 Bar      ⋯ More   │      time-of-day + location + frequency
│                              │
│  Merchant: Tim Hortons    ▾  │   ← suggested from history / nearby
│  Account: Cash CAD          ▾│   ← default: last used (cash most common)
│  Today 08:42 · Note · Tag    │
│  ┌───┬───┬───┐               │
│  │ 1 │ 2 │ 3 │               │
│  │ 4 │ 5 │ 6 │               │
│  │ 7 │ 8 │ 9 │               │
│  │ . │ 0 │ ⌫ │   [ ✓ Save ]  │
│  └───┴───┴───┘               │
└──────────────────────────────┘
```

Flow: type amount → tap category chip → saved (tapping a chip saves directly; long-press to keep editing).
Target: **3 taps + digits**.

Smart defaults:
- **Account**: last used; in France suggest Cash EUR / LCL card. Currency is never chosen separately — it comes from the account.
- **Cash** entries are final (no statement will come). Card/bank manual entries are provisional.
- **Category chips**: frequency × time of day (morning ⇒ coffee).
- **Merchant**: picking one fills its default category.
- Manual entries for card/bank accounts are marked "awaiting statement" and get merged when the PDF is imported.

Entry points: app `+`, home screen widget, app shortcut (long-press icon), optional persistent notification.

## Import statement (later — desktop does the import in MVP)

Phone receives the PDF via share and forwards it to desktop at next sync. Desktop parses and reports back:

```
Bank app / Files ──share──▶ Expense app
                               │
                    "Desjardins Mastercard — Sep 2026 detected"
                               │
                     parsing + validation (on device)
                               │
   ┌───────────────────────────────────────────────┐
   │ ✓ Totals match statement (3 184,47 $)         │
   │ 47 transactions                               │
   │   38 auto-categorized                         │
   │    4 merged with your manual entries          │
   │    1 card payment (transfer)                  │
   │    4 need a category        [Review now]      │
   └───────────────────────────────────────────────┘
```

Also: "Import" button in Settings → file picker, multi-select.
Validation failure ⇒ clear message, nothing saved, option to send anonymized debug info (local file) for parser fix.

## Review queue (swipe-to-confirm)

One card per uncertain transaction:

```
┌──────────────────────────────┐
│ 13 Sep · Mastercard          │
│ CAFE EXEMPLE  MONTREAL QC    │
│            −8.04 $           │
│ Suggested: ☕ Coffee & bakery │
│ [Bakery] [Resto] [Other…]    │
│  ← skip            confirm → │
└──────────────────────────────┘
```

After a correction: snackbar "Always use Coffee & bakery for Café Exemple? [Yes]".

## Home

- Scope switcher at top: **Desjardins · LCL · Cash CAD · Cash EUR** (swipe). Everything below is for that scope only.
- Month total spent vs last month.
- Targets: progress bars for this week / month / year (e.g. Restaurants 180 / 250 $, projected 290 $ ⚠).
- Donut or bar by category group (tap ⇒ list).
- Current trip card if active ("Gaspé — day 2 — 312 $").
- Last 5 transactions.
- Review badge.

## Transactions list

Search, filter chips (account, category, month), grouped by day. Tap ⇒ edit sheet (category, merchant, note, tags, trip, split).

## Settings

Accounts, categories, rules (read/edit basic), sync, export, language FR / EN (default = device language), app lock (biometric).
