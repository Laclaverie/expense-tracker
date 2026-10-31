# 01 — Vision

> Design document written before the code (October 2026). What is built: the [README](../README.md) and the
> [roadmap](08-roadmap-open-questions.md); where the plan changed, its decision log wins.

## Problem

Tracking expenses fails for one reason: **data entry is tedious**, so it stops after two weeks.

Specific situation:

- Main bank: **Desjardins** (Canada) — checking account (EOP), savings (ET), TFSA (CELI), Odyssée World Elite Mastercard.
- Also a French bank account at **LCL** (EUR). Supported later; Desjardins is the focus for now.
- Travels often. Pays from Canadian or French account depending on where/what. Card purchases abroad come back converted to CAD.
- Banks give monthly **PDF statements**, LCL included. Their own categorization is weak and not unified across banks.
  (Found later: Desjardins also lets you download transactions as **CSV**, last 18 months — now the preferred
  source; PDFs for older months.)

## Scope decisions

- **Each account has one currency.** No conversion between currencies.
- **Stats per bank, never combined.** Desjardins (CAD) and LCL (EUR) have separate dashboards. There are no global
  CAD+EUR totals for now.
- **Known limitation, accepted:** money moved from one bank to the other is not reconciled. Leaving Desjardins it is tagged
  "Transfer to another bank" and excluded from spending. Arriving at LCL it is tagged the same way. The two sides are not linked.
- **Cash** is tracked, by manual entry only. One cash wallet per currency, with its own stats.
- **Targets, not envelope budgets.** You can set spending targets per category (or total) per week, month or year and
  see progress. No money assignment à la YNAB.

## Goal

Know where the money goes — per store, per category, per trip, per month — across all accounts and currencies,
with almost no manual work.

## Principles

1. **Import first, type second.** Most transactions come from statements. Manual entry is for cash and for
   "I want to log it now before I forget".
2. **Manual entry under 5 seconds.** Amount → category → done. Everything else defaults.
3. **Never double count.** A credit card payment from checking is not an expense; the card purchases are.
4. **Learn once, apply forever.** Categorizing "TIM HORTONS #8517" once categorizes every Tim Hortons.
5. **Validate imports.** A statement import is checked against the statement's own totals and running balances.
   If numbers do not match, the user is told.
6. **Private by default.** Financial data stays on the user's devices / user-controlled storage.
7. **Mobile captures, desktop analyzes.** Phone stays simple. Depth lives on desktop.

## Non-goals (for now)

- Direct bank connections (Plaid, Flinks, open banking aggregators). Fragile, costly, privacy cost. Revisit later.
- Budgeting envelopes à la YNAB. Targets only (see scope decisions).
- Combined statistics across banks / currencies, currency conversion.
- Linking transfers between two different banks.
- Investments / net worth tracking beyond account balances.
- Multi-user / household sharing.
- iOS.

## Inspirations — what to borrow

| App | Borrow | Avoid |
|-----|--------|-------|
| **Monarch / Copilot** | Clean review inbox ("to review" queue), merchant logos/names, rules auto-created from edits | Subscription + bank aggregator dependency |
| **YNAB** | Fast mobile entry, payee memory, transfers as first-class | Mandatory budgeting method |
| **Actual Budget** | Local-first, rules engine, import with dedup, open source | Desktop-centric mobile UX |
| **Firefly III** | Rich rules, multi-currency, tags, reports | Heavy, server setup, data entry slow |
| **Bankin' / Linxo** (FR) | Automatic categories, French bank support | Aggregator-only |
| **Spendee / Wallet (BudgetBakers)** | Multi-currency wallets, travel use case, pretty charts | Manual entry friction |
| **Splitwise** | (later) shared trip expenses | — |
| **Trail Wallet / TravelSpend** | Trips with date range, daily spend per trip, home currency conversion | — |

## Success criteria

- Importing a monthly Desjardins statement (account + card) takes < 2 minutes including review.
- After 3 months of use, > 90 % of imported transactions are auto-categorized correctly.
- Manual cash entry: median < 5 s.
- Answer in one click: "How much on coffee shops this year?", "What did the Gaspé trip cost?",
  "Top 10 stores last 6 months?", "Am I under my restaurant target this month?".
