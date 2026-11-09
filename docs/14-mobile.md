# 14 — Phone app (Android, read-only)

The phone shows what the desktop shows — this month's spending, targets, transactions, statistics, balances —
without opening the computer. It **never changes data**: categorizing, imports and targets stay on the desktop.
Design: [spec](superpowers/specs/2026-11-08-mobile-readonly-design.md); decision log in
[doc 08](08-roadmap-open-questions.md).

## How it works

The desktop sends the phone **its whole database file**, still encrypted with the database password, over the
home Wi-Fi. The phone opens it read-only with the same code as the desktop (`core` + `storage`), so the figures
are the same for the same account and period. No internet, no cloud, no account.

```
Desktop                                   Phone (same Wi-Fi)
"Send to phone" ──▶ VACUUM INTO copy      opens the app
                    (still encrypted)        │ UDP broadcast "find" (port 47821), else the QR's addresses
                    serves it 10 min ◀───────┤ GET /manifest  (size, SHA-256, schema, date)
                    on port 47820 (next      │ GET /database  → <file>.download
                    free one if busy)        │ size + SHA-256 checked, then two renames:
                                             │   current → .previous, download → current
                    "Phone up to date" ◀─────┘ POST /ack
                    copy deleted
```

- Every request is signed with the pairing secret (HMAC-SHA256, timestamp + one-time nonce). A request that
  isn't from the paired phone gets nothing. Of the answers, only the manifest is signed; the download is checked
  against the manifest's size and SHA-256.
- If the app stops between the two renames, the next start opens `.previous` (nothing is lost).
- The serve window closes after 10 minutes, or as soon as the phone confirms. The desktop's temporary copy is
  deleted when the window ends. A download still running at that moment is cut: send again.
- A cut Wi-Fi, a wrong size or hash: the download is thrown away and the data already on the phone stays as it
  was ("Transfer incomplete, try again").
- Same copy as last time: the phone says it is up to date and downloads nothing. An older copy than the one it
  holds is ignored (no going back).
- The phone app and the desktop must use the same database schema. If not, nothing is replaced and the phone
  names the app to update ("Update the phone app" / "Update the desktop app").

## Install

1. On the computer: **`build-mobile.bat`**. The first time it installs the Android tools
   (`tools\setup.ps1 -Android`: Java 17 and the Android SDK, several GB), then builds
   `dist\Depenses-android.apk`. Your data is never inside the APK.
2. Put the APK on the phone: `adb install dist\Depenses-android.apk` with a USB cable, or copy the file and open
   it on the phone (allow installing from that source). No Play Store.

The APK is built for **arm64** phones only (every recent phone; about 28 MB). It is signed with the build
computer's own debug key: an update must be built on the same computer, otherwise Android refuses it — uninstall
the app and pair again.

**Update the app:** `deploy-mobile.bat` builds the APK and installs it with adb on every connected phone (USB
debugging, or a phone already connected over Wi-Fi), then starts it. `install -r` keeps the phone's data and
pairing. The installed app must have been built on the same computer; otherwise the script says so (uninstall
it on the phone and pair again).

- `deploy-mobile.bat` — build, then install on every connected phone.
- `deploy-mobile.bat 192.168.1.20:41234` — `adb connect` to the address shown under Developer options →
  Wireless debugging first, then build and install.
- `deploy-mobile.bat pair 192.168.1.20:37000 123456` — once per phone (Android 11+): Wireless debugging →
  **Pair device with pairing code**, give its address and code, then stop.
- `deploy-mobile.bat nobuild [address]` — skip the build and install the existing `dist\Depenses-android.apk`.

## Pair (once)

1. Desktop: phone icon in the top bar → **Pair a phone**. The desktop prepares the copy and starts waiting for
   the phone (10 minutes, as for **Send to phone**), then shows a QR code with its private addresses, the port it
   actually listens on (47820, or the next free one up to 47830) and a new pairing secret (one phone per
   database). **Show QR again** on a paired phone does the same. Without a network there is no QR code and no
   wait ("No network found"); if the wait can't start, its error shows instead of the QR code.
   Closing the dialog doesn't stop the wait: **Stop**, the phone's confirmation or the end of the 10 minutes
   does.
2. Phone: **Scan** the QR code. A QR from anything else: "This QR code is not from Dépenses".
3. The phone downloads the data, then asks for the **database password** (the desktop's one).

The pairing secret is kept in the desktop's encrypted database and in the phone app's private folder. It is not
the database key: it only lets the phone ask for copies. **Forget phone** on the desktop stops sending; on the phone, Settings → **Forget this desktop** deletes the
pairing and every copy of the data.

## Send new data

- After an import that added lines, the desktop asks "Send the new data to your phone?". Or: phone icon →
  **Send to phone** at any time.
- Open the app on the phone (same Wi-Fi) while the desktop waits: Home shows "New data from <date> —
  Download". Settings → **Check for new data** asks again.
- Desktop shows "Phone up to date" once the phone confirms.

**Windows firewall:** the first pairing or **Send to phone** makes Windows ask whether Dépenses may use the network. Allow
**private networks** (home Wi-Fi). If nothing arrives after two minutes, the desktop reminds you to check the
Wi-Fi and this permission.

## Password and lock

- The password is typed on the phone and kept in memory only: never on disk, never in the phone's keystore.
- The app locks when you come back after **5 minutes or more** in the background (and with Settings →
  **Lock**): the database closes and the password is then forgotten.
- Password changed on the desktop since the last copy: the new copy doesn't open with the old password. The
  phone asks for the new one and keeps showing the previous copy until it is typed.

## Screens

Bottom bar: **Home · Transactions · Statistics · Settings**. On top, the scope: a bank and currency, the cash
wallet, or one account (currencies are never mixed).

- **Home**: spent this month vs last month (a month missing a statement says so instead of 0 $, and names the
  account), targets per week / month / year, the ten latest transactions, the date of the data.
- **Transactions**: grouped by day; search; filters by account, category and month; tap a line for its details.
- **Statistics** (6 months, 12 months or this year, like the desktop): categories (donut and list, tap for its
  merchants; categories hidden from shares on the desktop stay hidden), trends (bars per group, months missing a
  statement faded), merchants, recurring payments (with the next expected date), balances per account.
- **Settings**: paired desktop, check for new data, date of the data, language (device / French / English),
  lock, forget this desktop.

Not in this version: entering an expense, recategorizing, review, compare, splits, notifications, fingerprint
unlock (see the backlog in [doc 08](08-roadmap-open-questions.md)).

## Troubleshooting

- The phone says the desktop is not reachable although both are on the same Wi-Fi (the most common cause):
  Windows marked the home Wi-Fi as **Public**, so the firewall prompt at the first pairing or **Send to phone** created
  Block rules for the app on public networks. Switch the network to Private: Settings → Network & internet →
  Wi-Fi → your network → Network profile type → **Private** (only for your own home network; cafés and other
  shared networks stay Public). Rules for the app already exist, so Windows won't ask again: in an
  administrator PowerShell, allow it on private networks (keep the Public block rules):

  ```powershell
  New-NetFirewallRule -DisplayName 'Expense tracker (private)' -Direction Inbound -Action Allow -Profile Private -Program '<folder of the app>\expense_desktop.exe'
  ```

  The rule follows the program's path: a copy unzipped elsewhere is a new program, and Windows asks again.
  What Private changes: network discovery is turned on; file sharing stays off unless you enable it. That is
  fine for a home network with your own devices; put devices you don't trust on a guest network.
- "Phone not paired with this database" although it is: the phone's clock may be more than 5 minutes off
  (signed requests carry the time). Set the phone to automatic time.
- Nothing found: same Wi-Fi? Windows firewall allowed on private networks (above)?

## For developers

- `apps/mobile` (Flutter, Android) depends on `core`, `storage` and `sync`, never on `banks` or `pdf_words`
  (`demo` is a dev-only test dependency: the demo database; it is not in the APK).
  The database is opened read-only (`openReadOnlyDatabase`): no migration, no write.
- `packages/sync`: pairing payload (`PairingInfo`), request signing, manifest, server (desktop), client
  (phone), UDP discovery, `lanAddresses` (private IPv4 only: a VPN or Hyper-V adapter adds addresses to the QR,
  the phone tries each).
- Tests: `test-all` runs `sync` and the phone app's widget tests (no Android SDK needed). The phone smoke test
  opens every screen and Statistics view on the demo database at 412×915 and 360×640.
- Release APK: arm64 only, about 28 MB (Flutter engine, app code, bundled QR scanner, sqlite3mc). See the
  2026-11-08 size decision in [doc 08](08-roadmap-open-questions.md).
