# Read-only Android app + desktop → phone sync — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** An Android app that shows the desktop's data read-only, fed by a signed, hash-checked copy of the encrypted database sent over the local Wi-Fi.

**Architecture:** Desktop makes a `VACUUM INTO` copy (still encrypted) and serves it for 10 minutes with a small `dart:io` HTTP server; the phone finds it by UDP broadcast, downloads, checks the signed SHA-256, swaps the file atomically and acks. The phone opens the file read-only with the database password and reuses `core` + `storage` queries for every screen.

**Tech Stack:** Dart 3.13 / Flutter 3.47.9 (pinned `.flutter-version`), drift + `sqlite3` (sqlite3mc hooks), `crypto` (HMAC-SHA256, SHA-256), `dart:io` (HttpServer, RawDatagramSocket), `fl_chart`, `qr_flutter` (desktop), `mobile_scanner` (phone), `path_provider`, `provider`.

**Spec:** `docs/superpowers/specs/2026-11-08-mobile-readonly-design.md`

## Global Constraints

- Phone is **read-only**: never writes to its database, never migrates it, never calls `refreshAutomaticCategories`.
- Everything local: no internet, no cloud, no external API. Same Wi-Fi only.
- Database file always stays encrypted (B11); no key/password on disk or in an OS keyring; the password lives in memory only. Agents never ask for or handle the owner's password.
- The pairing secret is stored inside the encrypted database (desktop) and in app-private storage (phone); it is not the database key.
- Serve window: **10 minutes**, closed early after a valid ack.
- Phone locks after **5 minutes** in background.
- Schema version in the manifest must equal the phone's `ExpenseDatabase.currentSchemaVersion`, else refuse and name the app to update.
- One phone per database (v1).
- `apps/mobile` never depends on `banks` or `pdf_words`.
- Release APK under **25 MB**.
- Strings in both `app_en.arb` and `app_fr.arb` (insert keys as text before the closing brace; never re-dump with a JSON library). Made-up examples only in docs/tests.
- Use `appNow()` (never `DateTime.now()`) for what an app shows.
- Commit messages: conventional style, end with the `Co-Authored-By` line. Commit locally, never push.
- Format width 120 (`dart format -l 120`), `analyze --fatal-infos` clean.

## Review Focus

1. **Wi-Fi drops mid-download** → old database still opens, temp file gone, clear message. Test in Task 4 (`client keeps old file when the stream is cut`).
2. **Desktop sends again while phone holds the same file** → phone says "up to date", no download. Test in Task 4 (`manifest with same hash needs no download`).
3. **Owner changed desktop password since last sync** → new file doesn't open with typed password; phone asks again and the previous file is still usable with the old one until the new opens. Test in Task 7 (`new file with other password keeps previous until unlocked`).
4. **Phone app older/newer than desktop (schema mismatch)** → nothing replaced, message names the app to update. Test in Task 4 (`schema mismatch refuses before download`).
5. **Desktop has two network interfaces (VPN, Hyper-V)** → QR lists every private IPv4; phone tries broadcast then each address. Test in Task 3 (`lanAddresses skips loopback and link-local`).

---

## File Structure

```
packages/core/lib/src/stats_periods.dart        moved from apps/desktop/lib (Flutter-free)
packages/core/lib/src/clock.dart                moved from apps/desktop/lib/clock.dart
packages/core/lib/src/chart_palette.dart        Flutter-free palette ints + groupOf/seriesOf (from style.dart)
packages/storage/lib/src/stats_views.dart       Flutter-free parts of targets_view.dart, coverage_view.dart, stats/data.dart
packages/storage/lib/src/tables.dart            + PairedPhones table
packages/storage/lib/src/database.dart          schema v10, readOnly flag
packages/storage/lib/src/encryption.dart        + openReadOnlyDatabase
packages/storage/lib/src/pairing_store.dart     read/write PairedPhones
packages/sync/lib/sync.dart                     exports
packages/sync/lib/src/pairing.dart              PairingInfo (QR payload)
packages/sync/lib/src/signing.dart              HMAC sign/verify, replay guard
packages/sync/lib/src/manifest.dart             Manifest
packages/sync/lib/src/server.dart               SyncServer (desktop)
packages/sync/lib/src/client.dart               SyncClient (phone)
packages/sync/lib/src/discovery.dart            UDP broadcast find/answer
packages/sync/lib/src/network.dart              lanAddresses
apps/desktop/lib/widgets/phone_dialog.dart      pair / send / status / forget
apps/desktop/lib/phone_sync.dart                PhoneSync: copy + server lifecycle
apps/mobile/                                    new Flutter Android app
tools/setup.ps1, build-mobile.bat, tools/test-all.ps1, .github/workflows/ci.yml
docs/14-mobile.md, docs/06, 08, 09, 12, README.md, CLAUDE.md
```

---

### Task 1: Android toolchain, mobile scaffold, encrypted SQLite in the APK

Proves the risky part first: sqlite3mc built for Android by the `sqlite3` hooks.

**Files:**
- Modify: `tools/setup.ps1` (new `-Android` switch), `pubspec.yaml` (workspace += `apps/mobile`)
- Create: `apps/mobile/` via `flutter create`, `apps/mobile/test/encryption_test.dart`
- Create: `build-mobile.bat`

**Interfaces:**
- Produces: workspace member `apps/mobile` (package `expense_mobile`, org `dev.lasagna`), `build-mobile.bat` → `dist\Depenses-android.apk`.

- [ ] **Step 1:** Add `-Android` to `tools/setup.ps1`: installs a JDK 17 (winget `Microsoft.OpenJDK.17`) and Android command-line tools into `%LOCALAPPDATA%\Android\Sdk` (platform-tools, `platforms;android-35`, `build-tools;35.0.0`, NDK version Flutter asks for), runs `flutter config --android-sdk`, accepts licenses. Off by default; no machine path in tracked files.
- [ ] **Step 2:** Run `powershell -ExecutionPolicy Bypass -File tools\setup.ps1 -Android`, then `flutter doctor`. Expected: "Android toolchain" ✓. (Owner may need to run it: installers prompt.)
- [ ] **Step 3:** `flutter create --platforms=android --org dev.lasagna --project-name expense_mobile apps/mobile`; add `resolution: workspace`, `sdk: ^3.13.0`, deps `core`, `storage`, `drift`, `sqlite3`; add `apps/mobile` to root `workspace:`; `dart pub get` at root. Add `<uses-permission android:name="android.permission.INTERNET"/>` to `AndroidManifest.xml`. App label "Dépenses".
- [ ] **Step 4: Failing test** `apps/mobile/test/encryption_test.dart`:

```dart
test('sqlite3mc encrypts in the mobile package build', () async {
  // temp dir; create with openEncryptedDatabase(file, 'pw-test'), run one query, close
  expect(databaseFileState(file), DatabaseFileState.encrypted);
  expect(passwordOpens(file, 'pw-test'), isTrue);
  expect(passwordOpens(file, 'wrong'), isFalse);
});
```
Run: `cd apps/mobile && flutter test test/encryption_test.dart` → PASS for the `passwordOpens` part (host build of sqlite3mc).
- [ ] **Step 5:** `build-mobile.bat` (like `build-desktop.bat`: `tools\env.bat`, `flutter build apk --release --no-tree-shake-icons`, copy `build\app\outputs\flutter-apk\app-release.apk` to `dist\Depenses-android.apk`). Run it.
- [ ] **Step 6: Verify native lib in APK:** `tar -tf dist\Depenses-android.apk | findstr sqlite` → lists `lib/arm64-v8a/libsqlite3*.so` (and armeabi-v7a, x86_64). If missing: stop and report — the whole plan depends on it.
- [ ] **Step 7:** Commit `feat(mobile): Android toolchain and app scaffold with encrypted SQLite`.

---

### Task 2: Storage — schema v10 pairing table, read-only open, shared view logic

**Files:**
- Modify: `packages/storage/lib/src/tables.dart`, `database.dart`, `encryption.dart`, `storage.dart`
- Create: `packages/storage/lib/src/pairing_store.dart`, `packages/storage/lib/src/stats_views.dart`
- Create: `packages/core/lib/src/stats_periods.dart`, `clock.dart`, `chart_palette.dart` (moved), export from `core.dart`
- Modify: `apps/desktop/lib/stats_periods.dart`, `clock.dart` (deleted, imports point to core), `style.dart`, `targets_view.dart`, `coverage_view.dart`, `screens/stats/data.dart` (keep only Flutter parts, import the moved code)
- Move test: `apps/desktop/test/stats_periods_test.dart` → `packages/core/test/`, `clock_test.dart` → `packages/core/test/`
- Test: `packages/storage/test/migration_test.dart`, `packages/storage/test/pairing_store_test.dart`, `packages/storage/test/encryption_test.dart`

**Interfaces:**
- Produces:
  - Table `PairedPhones` (`@DataClassName('PairedPhoneRow')`): `id INTEGER PK` (always 1), `databaseId TEXT` (uuid v4), `secret BLOB` (32 bytes), `pairedAt DATETIME`, `lastSyncAt DATETIME?`, `lastSyncHash TEXT?`.
  - `ExpenseDatabase.currentSchemaVersion = 10`; `ExpenseDatabase(QueryExecutor e, {bool readOnly = false})` — when `readOnly`, `beforeOpen` skips `seedCategories()` and the migration callbacks throw `StateError('read-only database needs migration')`.
  - `ExpenseDatabase openReadOnlyDatabase(File file, String password)` — background isolate, key applied, then `PRAGMA query_only = ON`.
  - `class PairingStore { PairingStore(ExpenseDatabase db); Future<PairedPhoneRow?> current(); Future<PairedPhoneRow> pairNew(); Future<void> forget(); Future<void> recordSync(String sha256, DateTime at); }` — `pairNew` replaces any existing row with a fresh uuid + `Random.secure()` 32-byte secret.
  - Moved, same names: `dataStart`, everything in `stats_periods.dart`; `appNow`, `appClock`, `clockFromEnvironment`; `chartGroups`, `otherSeries`, `uncategorizedSeries`, `groupOf`, `seriesOf`, `lightPalette`, `darkPalette`, `otherLight`, `otherDark`, `noneLight`, `noneDark` (public `int` constants, were `_light` etc.); `MonthStatus`, `monthStatuses`, `TargetView`, `historyLength`, `linesWindow`, `spentIn`, `computeTargets`, `StatsData`, `scopeCurrency`. Rule: a declaration moves when it uses no Flutter type; colors stay in `style.dart` as `Color(lightPalette[i])`.

- [ ] **Step 1: Failing tests:**
  - `migration_test.dart`: `'v9 → v10 adds paired_phones, keeps data'` (follow the file's existing pattern of older-schema fixtures).
  - `pairing_store_test.dart`: `'pairNew makes a 32-byte secret and a uuid; a second pairNew replaces it'`, `'forget removes the pairing'`, `'recordSync stores hash and time'`.
  - `encryption_test.dart`: `'openReadOnlyDatabase reads but refuses writes'` — insert via read-only db throws `SqliteException` (`attempt to write a readonly database` / query_only); `'openReadOnlyDatabase does not seed categories'` (delete one default category in a writable open first, reopen read-only, still missing).
- [ ] **Step 2:** Run `cd packages/storage && dart test` → the new tests FAIL.
- [ ] **Step 3:** Implement table, migration (`if (from < 10) await m.createTable(pairedPhones);`), `readOnly` flag, `openReadOnlyDatabase`, `PairingStore`; `dart run build_runner build` in `packages/storage`.
- [ ] **Step 4:** Move the Flutter-free code to `core` / `storage` as listed; desktop imports them. Move the two tests.
- [ ] **Step 5:** Run `tools\test-all.ps1` → all green (desktop smoke test included).
- [ ] **Step 6:** Commit `feat(storage): schema v10 phone pairing, read-only open; share view logic`.

---

### Task 3: `packages/sync` — pairing payload, signing, manifest, LAN addresses

**Files:**
- Create: `packages/sync/pubspec.yaml` (deps `crypto`, `test` dev; `resolution: workspace`), add to root workspace
- Create: `lib/sync.dart`, `lib/src/pairing.dart`, `signing.dart`, `manifest.dart`, `network.dart`
- Test: `packages/sync/test/pairing_test.dart`, `signing_test.dart`, `manifest_test.dart`, `network_test.dart`

**Interfaces:**
- Produces:
  - `const protocolVersion = 1; const defaultPort = 47820; const discoveryPort = 47821;`
  - `class PairingInfo { final String databaseId; final List<String> hosts; final int port; final List<int> secret; String encode(); static PairingInfo decode(String qr); }` — QR text = `expsync:` + base64url(JSON `{"v":1,"db":…,"hosts":[…],"port":…,"secret":"<base64url>"}`). `decode` throws `FormatException` on another prefix, version, or a secret ≠ 32 bytes.
  - `String signRequest(List<int> secret, String method, String path, {required DateTime at, required String nonce})` → header value `"<millis>.<nonce>.<hmacHex>"`, HMAC-SHA256 over `"$method $path $millis $nonce"`.
  - `class RequestVerifier { RequestVerifier(List<int> secret, {DateTime Function()? clock}); bool verify(String method, String path, String? header); }` — false when malformed, bad HMAC, `|now − millis| > 5 min`, or nonce already seen (nonces remembered 10 min).
  - `String signBody(List<int> secret, List<int> body)` / `bool verifyBody(List<int> secret, List<int> body, String? sig)` — hex HMAC, constant-time compare.
  - `class Manifest { final String databaseId; final int schemaVersion; final int size; final String sha256; final DateTime createdAt; Map<String,Object?> toJson(); static Manifest fromJson(Map<String,Object?>); }`
  - `Future<List<String>> lanAddresses()` — private IPv4 of up interfaces; skips loopback and `169.254.*`. Pure filter `List<String> privateIPv4(Iterable<InternetAddress>)` tested directly.
  - Header names: `X-Sync-Auth` (request), `X-Sync-Sig` (response body signature).

- [ ] **Step 1: Failing tests:**
  - `pairing_test`: round trip; `decode('otherapp:…')` throws; 31-byte secret throws; version 2 throws.
  - `signing_test`: valid passes; altered path fails; other secret fails; 6-minute-old fails; same header twice → second fails; body sig round trip; flipped byte fails.
  - `manifest_test`: JSON round trip keeps all fields (UTC date).
  - `network_test`: `'lanAddresses skips loopback and link-local'` — `privateIPv4([127.0.0.1, 169.254.3.4, 192.168.1.20, 10.0.0.5, ::1])` → `['192.168.1.20', '10.0.0.5']`.
- [ ] **Step 2:** `cd packages/sync && dart test` → FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** `dart test` → PASS; `dart analyze --fatal-infos` clean.
- [ ] **Step 5:** Commit `feat(sync): pairing payload, request signing, manifest`.

---

### Task 4: `packages/sync` — server, client, discovery

**Files:**
- Create: `lib/src/server.dart`, `client.dart`, `discovery.dart`
- Test: `packages/sync/test/transfer_test.dart`, `discovery_test.dart`

**Interfaces:**
- Consumes: Task 3 types.
- Produces:
  - `class SyncServer { static Future<SyncServer> start({required File file, required Manifest manifest, required List<int> secret, int port = defaultPort, Duration window = const Duration(minutes: 10), InternetAddress? address}); int get port; Future<SyncAck?> get done; Future<void> close(); }` — binds `anyIPv4` (tests: loopback), tries `port … port+10` when busy. Routes: `GET /manifest` (signed request → JSON + `X-Sync-Sig`), `GET /database` (signed → file bytes, `content-length`), `POST /ack` body `{"sha256":…}` (signed; hash must equal manifest → 204, completes `done`, closes). Unsigned/bad → 401, unknown → 404. `done` completes `null` on window timeout.
  - `class SyncAck { final String sha256; final DateTime at; }`
  - `class SyncClient { SyncClient(PairingInfo pairing, {HttpClient? http}); Future<Manifest> manifest(String host, int port); Future<void> download(String host, int port, Manifest m, File target, {void Function(int received, int total)? progress}); Future<void> ack(String host, int port, String sha256); }`
  - `download` writes to `'${target.path}.download'`, checks size + SHA-256 vs `m`, then renames: the previous `target` becomes `'${target.path}.previous'` (an existing `.previous` is overwritten), `.download` becomes `target`. On any failure the `.download` file is deleted, `target` untouched, throws `SyncException(SyncProblem.incomplete)`.
  - `enum SyncProblem { unreachable, notPaired, incomplete, schemaMismatch }`, `class SyncException implements Exception { final SyncProblem problem; }`. `manifest()` throws `notPaired` on 401 or a bad `X-Sync-Sig` or other `databaseId`; `unreachable` on socket errors/timeouts (5 s connect).
  - `bool needsDownload(Manifest m, String? localSha256)` and `void checkSchema(Manifest m, int appSchemaVersion)` (throws `schemaMismatch`).
  - Discovery: `class DiscoveryResponder { static Future<DiscoveryResponder> start(String databaseId, List<int> secret, int serverPort); void close(); }` listens UDP `discoveryPort`, answers `{"v":1,"db":…,"port":…}` + HMAC field `"sig"` unicast to the sender. `Future<(String host, int port)?> findDesktop(PairingInfo p, {Duration timeout = const Duration(seconds: 2), InternetAddress? broadcast})` sends `{"v":1,"find":<databaseId>}` to `255.255.255.255` (tests: loopback), returns the first answer with a valid sig, else null.

- [ ] **Step 1: Failing tests** (`transfer_test.dart`, real sockets on loopback, temp files of random bytes):
  - `'downloads, verifies and acks; server closes after ack'` — `done` completes with hash; new port refused afterwards.
  - `'client keeps old file when the stream is cut'` — test server variant (`HttpServer` in the test) sends half the bytes then closes; `target` unchanged, no `.download` left, `SyncProblem.incomplete`.
  - `'altered byte is refused'` — server manifest hash of other content → `incomplete`.
  - `'wrong secret is refused'` → `notPaired`; server answered 401.
  - `'manifest with same hash needs no download'` → `needsDownload(m, m.sha256)` false.
  - `'schema mismatch refuses before download'` → `checkSchema(<Manifest with schemaVersion 11>, 10)` throws `schemaMismatch`; no request to `/database` made.
  - `'window timeout closes the server and done is null'` (window 200 ms).
  - `'busy port moves to the next one'`.
  - `discovery_test`: `'finds the desktop on loopback'`, `'ignores an answer signed with another secret'` (returns null).
- [ ] **Step 2:** `dart test` → FAIL.
- [ ] **Step 3:** Implement (`HttpServer` + `dart:io` `HttpClient`, `crypto` `sha256` streaming via `sha256.bind`).
- [ ] **Step 4:** `dart test` → PASS; analyze clean.
- [ ] **Step 5:** Commit `feat(sync): LAN server, client and discovery`.

---

### Task 5: Desktop — pair a phone, send, status, forget

**Files:**
- Create: `apps/desktop/lib/phone_sync.dart`, `apps/desktop/lib/widgets/phone_dialog.dart`
- Modify: `apps/desktop/lib/screens/shell.dart` (phone icon button next to backups, `Icons.phone_android`), `apps/desktop/pubspec.yaml` (`sync`, `qr_flutter`), ARB files
- Test: `apps/desktop/test/phone_dialog_test.dart`

**Interfaces:**
- Consumes: `PairingStore`, `SyncServer`, `DiscoveryResponder`, `PairingInfo`, `Manifest`, `lanAddresses`.
- Produces:
  - `class PhoneSync extends ChangeNotifier { PhoneSync(ExpenseDatabase db, Directory scratch); PairingStore get store; bool get serving; Future<void> send(); Future<void> stop(); PairedPhoneRow? get phone; }` — provided in `appFor` as `ChangeNotifierProvider`. `send()`: `VACUUM INTO` `<scratch>/phone-copy.sqlite` (scratch = app data folder `sync/`, never next to backups), SHA-256, `Manifest(schemaVersion: ExpenseDatabase.currentSchemaVersion)`, starts `SyncServer` + `DiscoveryResponder`; on `done` → `store.recordSync`, deletes the copy, notifies. Timeout → deletes the copy. Only one session at a time.
  - `Future<void> showPhoneDialog(BuildContext context)`.

Dialog states:
- Not paired: text + "Pair a phone" → QR (`QrImageView`, `PairingInfo(...).encode()`, hosts from `lanAddresses()`, port `defaultPort`) + "Scan with the Dépenses app on your phone".
- Paired: "Phone paired on <date>", "Last sync: <date time> " or "Never", buttons **Send to phone**, **Forget phone** (confirm dialog), **Show QR again**.
- Serving: progress text "Waiting for the phone… open the app on your phone (same Wi-Fi). <mm:ss> left" + Stop; after 2 minutes with no request, hint "Nothing yet? Check the phone is on the same Wi-Fi and that Windows allowed Dépenses on private networks."
- Done: "Phone up to date · <date time>".

- [ ] **Step 1: Failing widget tests** (`appFor(db)` on an in-memory/temp db, `tester.runAsync` for real sockets):
  - `'not paired shows the pair button, pairing shows a QR'`
  - `'send then a client download records the sync'` — run a `SyncClient` against `127.0.0.1` with the pairing from the store; dialog shows "up to date".
  - `'forget asks for confirmation then removes the pairing'`
- [ ] **Step 2:** `cd apps/desktop && flutter test test/phone_dialog_test.dart` → FAIL.
- [ ] **Step 3:** Implement + strings (FR/EN). Add the dialog to `screens_smoke_test.dart`'s list of things it opens.
- [ ] **Step 4:** `flutter test` → PASS.
- [ ] **Step 5:** Commit `feat(desktop): pair a phone and send it the database`.

---

### Task 6: Desktop — offer to send after an import

**Files:**
- Modify: `apps/desktop/lib/screens/import_screen.dart` (end of `importPaths`), ARB files
- Test: `apps/desktop/test/phone_after_import_test.dart`

**Interfaces:**
- Consumes: `PhoneSync` (`phone`, `send()`), `showPhoneDialog`.

After the import loop: if at least one result has status `imported` and `context.read<PhoneSync?>()?.phone != null` → `AlertDialog` "Send the new data to your phone?" [Not now] [Send] — Send calls `send()` then `showPhoneDialog`.

- [ ] **Step 1: Failing tests:** `'paired + new lines → dialog shown'`, `'not paired → no dialog'`, `'only already-imported files → no dialog'` (import the demo fixture CSV via `importPaths`, like `duplicate_import_test.dart`).
- [ ] **Step 2:** Run → FAIL. **Step 3:** Implement. **Step 4:** Run → PASS.
- [ ] **Step 5:** Commit `feat(desktop): offer to update the phone after an import`.

---

### Task 7: Mobile — pairing, download, unlock

**Files:**
- Create: `apps/mobile/lib/main.dart`, `lib/phone_store.dart`, `lib/screens/pair.dart`, `lib/screens/unlock.dart`, `lib/sync_banner.dart`, `lib/lock.dart`, `lib/l10n/app_{en,fr}.arb`, `l10n.yaml` (as desktop, `nullable-getter: false`)
- Modify: `apps/mobile/pubspec.yaml` (`sync`, `mobile_scanner`, `path_provider`, `provider`, `intl`, `flutter_localizations`), `AndroidManifest.xml` (CAMERA permission)
- Test: `apps/mobile/test/phone_store_test.dart`, `apps/mobile/test/unlock_test.dart`

**Interfaces:**
- Consumes: `SyncClient`, `findDesktop`, `needsDownload`, `checkSchema`, `PairingInfo`, `openReadOnlyDatabase`, `passwordOpens` (in an isolate, top-level function), `ExpenseDatabase.currentSchemaVersion`.
- Produces:
  - `class PhoneStore { PhoneStore(Directory dir); File get database; File get previous; PairingInfo? readPairing(); void savePairing(PairingInfo p); String? localSha256(); Future<UpdateResult> update({SyncClient? client}); void dropPrevious(); }` — files `pairing.json`, `expenses.sqlite`, `expenses.sqlite.previous`, `expenses.sqlite.sha256` in `getApplicationSupportDirectory()`. `update`: `findDesktop` → else each `pairing.hosts` → `manifest` → `checkSchema` → `needsDownload` → `download` → `ack` → write `.sha256`.
  - `enum UpdateResult { upToDate, updated }` (errors are `SyncException`).
  - Unlock: password checked on `database`; if it fails and `previous` exists and opens → open `previous`, banner "New data is locked with another password — enter it to switch". Opened `database` → `dropPrevious()`.
  - `class AppLock` — `WidgetsBindingObserver`; paused > 5 min → close db, back to unlock.
- [ ] **Step 1: Failing tests:**
  - `phone_store_test`: `'pairing survives a restart'`, `'update with the loopback desktop downloads then reports upToDate'` (real `SyncServer` on loopback), `'new file with other password keeps previous until unlocked'` (pure `PhoneStore` + `passwordOpens`: previous still opens with old password).
  - `unlock_test`: `'wrong password shows an error, right one opens Home'`, `'locks after 5 minutes in background'` (fake clock via `appClock`).
- [ ] **Step 2:** Run → FAIL. **Step 3:** Implement screens: pair (scanner full screen, `PairingInfo.decode`, FormatException → "This QR code is not from Dépenses"), first download with progress, unlock (isolate check), sync banner on Home ("New data from <date> — Download" / errors mapped to the spec's messages). **Step 4:** Run → PASS.
- [ ] **Step 5:** Commit `feat(mobile): pair with the desktop, download and unlock`.

---

### Task 8: Mobile — Home, Transactions, Settings

**Files:**
- Create: `apps/mobile/lib/shell.dart` (bottom bar + scope switcher), `lib/screens/home.dart`, `lib/screens/transactions.dart`, `lib/screens/settings.dart`, `lib/style.dart` (`Color` wrappers over `core` palette)
- Test: `apps/mobile/test/screens_smoke_test.dart` (started here, extended in Task 9)

**Interfaces:**
- Consumes: `ExpenseRepository` read methods only — `watchScopes`, `watchTransactions(TxnFilter)`, `watchTargets`, `watchSpendingLines`, `watchMonthlyTotals`, `watchCoverage`, `watchLatestDate`, `watchCategories`, `watchAccounts`; `computeTargets`, `monthStatuses`, `appNow`.
- Produces: `Widget mobileAppFor(ExpenseDatabase db, {PhoneStore? store})` (providers like desktop `appFor`).

Home: month spent vs last month (coverage-aware: missing month shows "statement missing", not 0 $), target bars (week/month/year), last 10 transactions, "Data from <date>". Coverage warning names the **account** (no `banks` labels on the phone). Transactions: grouped by day, search box, filter chips account / category / month, tap → read-only bottom sheet. Settings: paired desktop, "Check for new data", data date, language (device / FR / EN), Lock.

- [ ] **Step 1: Failing smoke test** — demo database (`packages/demo` `demo:database` helper as desktop tests use), phone size `Size(412, 915)` and `Size(360, 640)`, real font loaded as desktop smoke test: opens Home, Transactions (search "costco"), Settings; no exceptions, no overflow. Plus `'home month total equals repository total for the demo scope'`.
- [ ] **Step 2:** Run → FAIL. **Step 3:** Implement. **Step 4:** Run → PASS.
- [ ] **Step 5:** Commit `feat(mobile): home, transactions and settings`.

---

### Task 9: Mobile — Statistics (categories, trends, merchants, recurring, balances)

**Files:**
- Create: `apps/mobile/lib/screens/stats.dart` + `lib/screens/stats/{categories,trends,merchants,recurring,balances}.dart`
- Modify: `apps/mobile/pubspec.yaml` (`fl_chart`), `test/screens_smoke_test.dart`

**Interfaces:**
- Consumes: `StatsData`, `watchSpendingDetail`, `watchSpendingByCategory`, `watchMonthlyByGroup`, `watchTopMerchants`, `watchBalanceHistory`, core recurring detection (same call as desktop `screens/stats/recurring.dart`), palette.

Segmented control at top; period: this month / 3 / 12 months. Categories: donut + list, tap → merchants of that category. Trends: 12-month bars, missing months marked. Merchants: top list. Recurring: list with amount + next expected date. Balances: line per account. Excluded categories (B36) left out of shares as on desktop.

- [ ] **Step 1: Failing tests:** smoke test opens each of the 5 views at both sizes; `'categories figures equal desktop StatsData for the same scope and range'`.
- [ ] **Step 2:** Run → FAIL. **Step 3:** Implement. **Step 4:** Run → PASS.
- [ ] **Step 5:** Commit `feat(mobile): statistics views`.

---

### Task 10: Checks, CI, docs, end-to-end on a phone

**Files:**
- Modify: `tools/test-all.ps1` (format paths + `sync` package loop + `mobile analyze` / `mobile test`), `.github/workflows/ci.yml` comment, `.gitignore` (`apps/mobile/android/local.properties`, `*.apk`)
- Create: `docs/14-mobile.md`
- Modify: `docs/06-ux-mobile.md`, `docs/09-tech-choices.md` (whole-file copy replaces snapshot), `docs/08-roadmap-open-questions.md` (decision log 2026-11-08; M3/M4 rewritten; backlog: fingerprint unlock with key-rule exception, quick add outbox), `docs/12-done.md`, `README.md`, `CLAUDE.md` (Status, Layout rows for `packages/sync` and `apps/mobile`, Tooling `build-mobile.bat` / `setup.ps1 -Android`)

- [ ] **Step 1:** Update `test-all.ps1`; run it → "All checks passed."
- [ ] **Step 2:** Write docs (made-up examples only).
- [ ] **Step 3:** `build-mobile.bat`; check APK size `< 25 MB` (`(Get-Item dist\Depenses-android.apk).Length`).
- [ ] **Step 4: End-to-end (owner, real phone, demo database):** desktop on a scratch demo database (`tools\ui-probe.ps1 start -DbDir <scratch>` or `demo.bat`) → pair → install APK (`adb install` or copy) → scan → download → unlock with the demo password → figures match desktop for one month. Then import a demo CSV on desktop → dialog → Send → phone banner → download → "Phone up to date" on desktop. Then cut Wi-Fi mid-download → old data still opens.
- [ ] **Step 5:** Commit `docs: mobile app, pairing and sync`; rebuild `package-desktop.bat` zip.

---

## Self-review notes

- Spec coverage: pairing (T3, T5, T7), sync steps 1–5 (T4–T7), guards (T2 read-only, T4 schema, T7 password change), screens (T8, T9 incl. balances), errors table (T4, T5 hint, T7 messages), tests (each task), tooling/docs (T1, T10), fingerprint backlog (T10).
- Firewall: Windows prompts on first `HttpServer.bind` to `anyIPv4`; the hint lives in T5 and `docs/14-mobile.md`.
