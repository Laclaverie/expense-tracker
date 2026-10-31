# 05 — Categorization

> Design document written before the code (October 2026). What is built: the [README](../README.md) and the
> [roadmap](08-roadmap-open-questions.md); where the plan changed, its decision log wins.

Goal: user categorizes a merchant once; app does the rest.

## Default category tree

Two levels. FR / EN names. Users add categories and groups, rename and archive them (archiving moves their
transactions to a chosen category; archived ones stay for history). New defaults shipped by app updates are added
at startup, and lines the app categorized by itself are re-evaluated (never the user's choices). Examples from real statements in parentheses.

| Group | Categories |
|-------|-----------|
| **Food** | Groceries (IGA, Maxi, Costco, Too Good To Go) · Restaurants (Bistro Exemple) · Fast food (McDonald's, A&W, Subway) · Coffee shops & bakeries (Tim Hortons, Café Exemple, a doughnut shop) · Bars (Bar Exemple) · Alcohol (SAQ) |
| **Housing** | Rent (Interac "Loyer") · Utilities · Insurance home · Household supplies · Furniture |
| **Transport** | Public transit (RTM abonnement) · Taxi / ride-hailing (Lyft, Uber) · Fuel (Shell) · Car rental · Parking · Car insurance |
| **Travel** | Flights (Air Canada) · Lodging (Airbnb, Booking) · Travel activities · Travel transport |
| **Leisure** | Entertainment & outings (Ping Pong Club) · Clubs & associations (Unity Club) · Games · Events · Concerts & shows (Ticketmaster) · Festivals |
| **Sport** | Gym & training (CrossFit) · Races & sport events (marathon Beneva) · Sports equipment (Decathlon, MEC) |
| **Subscriptions** | Streaming (YouTube) · Creators (Patreon) · Software · Donations (Wikipedia) · Other subscriptions |
| **Shopping** | Clothing (Roots) · Electronics · Gifts · Online (Amazon) |
| **Health** | Pharmacy · Dental · Medical · Insurance health |
| **Telecom** | Mobile (Virgin Plus) · Internet |
| **Finance** | Bank fees (Frais fixes, effet retourné) · Interest paid |
| **Government** | Taxes (Revenu Québec) · Registration & licences (SAAQ, droit d'immatriculation) · Fines (constat d'infraction) · Administrative fees (passport) |
| **People** | Sent to people (Interac out, rent to landlord excluded → Rent) — counted as spending |
| **Income** | Salary · Tax refund · Insurance refund · Interest earned · Reimbursements from friends · Rewards (Bonidollars credit) |
| **Excluded** | Internal transfer · Credit card payment · Cash withdrawal (moves to cash wallet) · Savings contribution · Transfer to/from another bank |

"Excluded" categories never count in spending stats.

## Merchant normalization

Raw description → merchant key, deterministic steps:

1. Uppercase, strip accents, collapse spaces.
2. Remove processor prefixes: `SQ *`, `GDP*`, `BKG*`, `PAYPAL *`, `GOOGLE *`, `AMZN MKTP`, `TGTG`, `CB ` (FR) …
   (keep the info: `GOOGLE *YouTube` ⇒ merchant YouTube, processor Google).
3. Remove store numbers / refs: `#8517`, `W515`, `8253`, booking refs `HMSXXK2NBM`, `0142336262728`.
4. Remove trailing city/province if parser didn't split it.
5. Look up alias table → `Merchant`. No hit ⇒ new merchant candidate shown in review ("new merchant: Café Le Falco — category?").

Merchant alias table seeded with common chains (CA + FR): Tim Hortons, Starbucks, IGA, Metro, Maxi, Provigo, Costco,
SAQ, Shell, Petro-Canada, Uber, Lyft, Airbnb, Booking, Air Canada, Carrefour, Monoprix, Franprix, SNCF, RATP, …

## Category assignment order

First hit wins; each result carries a confidence.

1. **User rule** (explicit) — highest.
2. **Merchant default category** (learned from user edits).
3. **Code rule** (`FIX` → Bank fees, `IET` → Interest earned, `VIW` → Internal transfer, `IRGA` → Cash withdrawal, Interac `Loyer` → Rent).
4. **Seed merchant table**.
5. **Bank hint** (Bonidollars 3 % ⇒ Food group; 2 % ⇒ Leisure/Transport/Travel) — narrows choices, low confidence.
6. **Keyword heuristics** (`CAFE`, `RESTAURANT`, `HOTEL`, `PHARM`, `BOULANGERIE`…).
7. *(later)* Local ML classifier trained on user's own history.
8. Else ⇒ "To categorize".

Low-confidence results land in review queue with suggested category pre-selected (one tap to confirm).

## Learning from edits

When user changes category of a transaction:
- Prompt (non-blocking): **"Always categorize *Tim Hortons* as Coffee shops?"** → Yes creates/updates merchant default.
- Option: apply to past transactions too.
- Same for merchant rename / merge ("Roots Corporation" + "ROOTS #123" ⇒ Roots).

## Tags & trips (orthogonal to category)

- Category = *what* (coffee). Tag = *context* (work, gift, shared). Trip = *when/where* (Gaspé, July).
- Trip auto-detection suggestion: ≥ 2 card lines with a city outside home region, or foreign currency, on consecutive days
  ⇒ "Looks like a trip to Gaspé 3–5 July. Create trip?"
