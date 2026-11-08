# Read-only Android app with desktop → phone sync — design

Date: 2026-11-08. Status: approved in conversation, spec awaiting owner review.

## Goal

See on the phone the same information the desktop app shows (month spending, targets, transactions, statistics,
balances) without opening the desktop. The phone never changes data.

Success: after an import on desktop, one tap sends the data; the phone shows the same figures as desktop for the
same scope and period, and both sides confirm the phone holds exactly the desktop's file.

## Decisions

| Topic | Decision | Why |
|-------|----------|-----|
| Phone role | **Read-only** viewer. No quick add, no recategorizing, no review | One-way sync: no outbox, no merge rules. Quick add can come later as an outbox |
| What is sent | The **whole encrypted database file** (`VACUUM INTO` copy), opened read-only on the phone | Phone reuses `core` + `storage` as they are: same stats, same rules, nothing to keep in step. Replaces the "snapshot" plan of docs 06/09 |
| Transport | Same Wi-Fi only. Desktop serves the file for 10 minutes after "Send to phone"; phone fetches when opened | Android can't keep a listening server alive. No cloud, no internet (doc 09) |
| Trigger | Manual button on desktop; after an import, a dialog offers to send when a phone is paired to this database | Owner's request |
| Verification | SHA-256 of the file, signed by desktop, checked by phone; phone sends a signed ack, desktop shows "Phone up to date · <date time>" | Byte-identical file = nothing forgotten |
| Unlock | Same database password typed on each open, kept in memory only, locks after 5 min in background | Respects the "no key on disk / in OS keyring" rule (B11) |
| Later | Fingerprint unlock (key wrapped in Android Keystore) — needs a written exception to the key rule; backlog item | Owner wants it eventually, not now |

## Architecture

```
packages/sync      new, pure Dart: pairing, discovery, signing, server (desktop), client (phone)
apps/mobile        new Flutter Android app: depends on core, storage, sync (never banks / pdf_words)
packages/core      gains stats_periods.dart (moved from apps/desktop, Flutter-free)
packages/storage   schema v10: paired_phone table; read-only open
apps/desktop       pairing screen, "Send to phone", post-import dialog, sync status
```

Chart palette (`apps/desktop/lib/style.dart`) is needed by both apps: the plan picks a shared home (small
`packages/ui_shared` or a Flutter-free color table in `core`) — no copy-paste of colors.

### Pairing (once per database)

- Desktop: Settings → "Pair a phone" shows a QR code: database id, desktop IPv4 addresses on the LAN, port, a
  32-byte random secret, protocol version.
- The secret is stored in a `paired_phone` table **inside the encrypted database** (schema v10): pairing belongs to
  that database instance; another database file has its own (or none). One phone per database in v1.
- Phone stores secret + database id + last known address in app-private storage. The secret is not the database
  key: whoever steals it can download the encrypted file, nothing more.
- "Forget phone" on desktop deletes the row: the old phone is refused from then on.

### Sync

1. Desktop "Send to phone" (Settings, or the post-import dialog): `VACUUM INTO` a temp copy (keeps the cipher,
   same as `backup.dart`), compute SHA-256, open an HTTP server (`dart:io`) on the LAN for 10 minutes.
2. Phone on open: UDP broadcast "database <id>?" on the local network (pure `dart:io`); desktop answers with its
   address and port. Fallback: last known address.
3. Phone `GET /manifest` → {database id, schema version, size, sha256, created at}, signed with HMAC-SHA256(secret).
   Phone shows "New data from Nov 8 (4.2 MB) — Download?" when the hash differs from its file.
4. `GET /database` (request signed with HMAC over a timestamp + nonce; desktop refuses stale or replayed requests).
   Phone streams to a temp file, checks size and SHA-256 against the signed manifest, then swaps atomically.
   The previous file is kept until the new one opens with the password, then deleted.
5. Phone `POST /ack` {sha256}, signed. Desktop records the time and hash in `paired_phone`, shows
   "Phone up to date · Nov 8 14:02", deletes the temp copy and closes the server.

Data on the wire: the file is encrypted by the database password; the manifest leaks only size and dates on the
LAN. No TLS in v1 (HMAC gives authenticity and integrity; the payload is already encrypted).

### Guards

- Schema version in the manifest must equal the phone app's `currentSchemaVersion`; otherwise the phone refuses
  and says which app to update.
- The phone opens the database **read-only** (SQLite read-only open): no migration, no write, no
  `refreshAutomaticCategories`.
- Desktop password changed: the new file fails to open with the remembered-in-memory password → phone asks for it.

## Phone app

### Start flow

- No file → "Pair with desktop": scan the QR (`mobile_scanner`), then first download.
- File present → password screen; key derivation in an isolate (as desktop `prepareDatabase`).
- On each open, if the desktop is reachable with a different hash: banner "New data from <date> — Download".
  Otherwise "Data from <date>" in Settings; the app works fully offline.

### Screens

Bottom bar: **Home · Transactions · Statistics · Settings**. Scope switcher on top (institution + currency, cash
wallet, or one account — `Scope` from `core`; currencies never mixed).

- **Home**: this month's spending vs last month, target progress (week / month / year), last 10 transactions,
  "data from <date>", coverage warning when a statement is missing.
- **Transactions**: grouped by day, search, filters (account, category, month); tap → read-only details.
- **Statistics**: categories (donut + list, tap → merchants), trends (12 months), merchants, recurring payments,
  balances. Same rules as desktop (coverage: a missing month is "missing", not 0 $; excluded categories).
- **Settings**: paired desktop, sync now, data date, language FR / EN (default: device language), lock.

Not in v1: compare, splits view, notification bell / anomalies, per-store cards, any editing.

Charts: `fl_chart` (as desktop), dataviz palette shared with desktop. "Today" comes from an `appNow()`-style clock
so tests and demos can fix it. Strings: `apps/mobile/lib/l10n/app_{en,fr}.arb`.

Size target: release APK under 25 MB (no PDFium, no bank code).

## Errors (fail loud, never partial)

| Case | Behavior |
|------|----------|
| Hash or size mismatch, interrupted download | Temp file deleted, old file kept, "Transfer incomplete, try again" |
| Bad signature / unknown database id | Refused on both sides: "Phone not paired with this database" |
| Desktop not found | "Desktop not reachable on this Wi-Fi. On the desktop: Send to phone" |
| Port busy | Desktop takes another port, gives it in the broadcast reply |
| Nobody connects within the window | Desktop hint: same Wi-Fi? Windows firewall allowed? |
| Schema mismatch | Phone refuses, names the app to update |

## Testing

- `packages/sync`: pairing round trip, signature rejected, replayed request rejected, truncated / altered file
  rejected, ack recorded, server closes after timeout and after ack — server and client in one `dart test` on
  loopback sockets.
- `packages/storage`: migration v9 → v10 test; read-only open refuses writes.
- `apps/mobile`: smoke test opening every tab and Statistics view on the demo database (as desktop
  `screens_smoke_test.dart`, with a real font loaded the same way); figures equal desktop's for one scope.
- `apps/desktop`: post-import dialog shown only when a phone is paired; pairing screen in the smoke test.
- `test-all` and CI include the new packages; widget tests need no Android SDK.

## Tooling and docs

- `tools\setup.ps1 -Android`: installs JDK + Android SDK command-line tools (opt-in, not for every machine).
- `build-mobile.bat`: release APK to `dist\`; install by USB (`adb install`) or copying the APK. No Play Store.
- New `docs/14-mobile.md`: pairing, sync, firewall prompt, install. Docs 06 and 09 updated (snapshot plan replaced
  by the whole-file copy), decision logged in doc 08, M3/M4 rewritten, fingerprint unlock added to the backlog.
- Windows firewall: first serve triggers the Windows prompt for private networks; documented.

## Out of scope

Editing on the phone, quick add, several phones per database, sync over the internet, iOS, Play Store,
share-to-import.
