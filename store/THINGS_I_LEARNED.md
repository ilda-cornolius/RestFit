# Things I learned

Living notes from debugging Stella Fit. **Add a dated entry under [Solved issues](#solved-issues-log) every time we fix something.**

Related deep dives: [`GOOGLE_SIGNIN_LESSONS_LEARNED.md`](./GOOGLE_SIGNIN_LESSONS_LEARNED.md), [`PLAY_SIGNIN_FIXED.md`](./PLAY_SIGNIN_FIXED.md), [`EMULATOR_DNS_FIREBASE.md`](./EMULATOR_DNS_FIREBASE.md).

---

## Solved issues log

### Aug 29, 2026 — Debug Google Sign-In: “Checking info…” loop → “Google blocked debug Sign-In”

**Symptoms**

- Pick Google account → **Checking info…** spinner → fail  
- App: **Google blocked debug Sign-In**  
- logcat `RestFitAuth`: `[16] Account reauth failed`  
- Sometimes also: **no internet connection** when adding Google account on emulator  

**What we thought was wrong**

- Missing debug SHA / Android OAuth client / wrong Web client ID  

**What was actually wrong**

OAuth config was **already correct** (SHA, Android client `…5kbs8…`, Web client `…d6jdj…`, scopes, In production). The emulator was broken:

1. **DNS dead** — Wi‑Fi looked connected but hostnames failed → Google/Firebase report “no internet”  
2. **Stale Google account** — after `pm clear com.google.android.gms`, logcat showed `Long live credential not available`  
3. **Emulator crash** — Pixel 9 AVD segfaulted (exit 139); adb went offline  

**Fix that worked**

```bash
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH"

find "$HOME/.android/avd/Pixel_9.avd" -name "*.lock" -delete 2>/dev/null
pkill -f "emulator.*Pixel_9" 2>/dev/null

emulator -avd Pixel_9 -dns-server 8.8.8.8,1.1.1.1 -netdelay none -netspeed full -no-snapshot-load
```

Then verify:

```bash
adb wait-for-device
adb shell getprop sys.boot_completed   # expect 1
adb shell ping -c 1 google.com         # must succeed
```

On the emulator: **Settings → Passwords & accounts** → add Google account → launch Stella Fit → Sign in with Google ✅

**Lesson:** When SHA + OAuth clients are verified, check **emulator DNS + Google account** before changing Google Cloud again.

**Code change:** `clearCredentialState` runs on **Play installs only** (not debug/emulator) — see `GoogleAuthService.swift`.

---

### Aug 29, 2026 — Two Web client secrets in Google Cloud

**Symptom:** Sign-In still failing after OAuth edits.

**Cause:** Rotated Web client secret in Google Cloud (`****WwSc` new, `****kRya` old) but Firebase Web SDK may still have the old secret.

**Fix:** Firebase → Authentication → Sign-in method → Google → Web SDK → paste **current** secret from Google Cloud **Web application** client `…d6jdj…` → Save. Delete/disable old secret in Google Cloud once verified.

---

### Aug 29, 2026 — Confused Android OAuth client ID with Web client ID

**Symptom:** “Is `…5kbs8…` the right client ID?”

**Answer:** Yes for **Google Cloud → Android OAuth client** (package + SHA). **No** for app code or Firebase Web SDK — those use **Web** client `…d6jdj…` only.

---

## Emulator ↔ command prompt (ADB)

The emulator is **not** connected to the project folder directly. **ADB** (Android Debug Bridge) sits in the middle:

```text
Mac (terminal)  →  adb  →  emulator-5554 (virtual phone)
                         →  or physical phone via USB
```

### Setup

```bash
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$ANDROID_HOME/platform-tools:$PATH
```

### See what’s connected

```bash
adb devices
```

Example:

```text
emulator-5554   device
```

### Start emulator with working DNS (do this by default)

```bash
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH"

emulator -avd Pixel_9 -dns-server 8.8.8.8,1.1.1.1 -netdelay none -netspeed full
```

Without `-dns-server`, hostname lookups often fail even when “Wi‑Fi connected” — see [`EMULATOR_DNS_FIREBASE.md`](./EMULATOR_DNS_FIREBASE.md).

### Install and launch Stella Fit

```bash
cd /Users/ilda/restfit
skip export --debug --android --no-ios

adb install -r .build/skip-export/RestFit-debug.apk
adb shell am start -n com.restfit.app/rest.fit.MainActivity
```

Or after a Gradle debug build:

```bash
cd Android && gradle :app:assembleDebug
adb install -r ../.build/Android/app/outputs/apk/debug/app-debug.apk
adb shell am start -n com.restfit.app/rest.fit.MainActivity
```

### Useful commands

| Command | Purpose |
|---------|---------|
| `adb devices` | List emulators / phones |
| `adb -s emulator-5554 install -r app.apk` | Install on a specific device |
| `adb shell am start -n com.restfit.app/rest.fit.MainActivity` | Launch the app |
| `adb logcat \| rg RestFitAuth` | Sign-In debug logs |
| `adb shell pm path com.restfit.app` | Path to installed APK |
| `adb pull <apk-path> /tmp/app.apk` | Pull APK for cert inspection |

Verify signing cert on a **running** install:

```bash
adb shell pm path com.restfit.app
adb pull "<path-from-above>" /tmp/stellafit.apk
$ANDROID_HOME/build-tools/34.0.0/apksigner verify --print-certs /tmp/stellafit.apk
```

### If `adb devices` is empty or offline

1. Emulator crashed or not running → restart with `-dns-server` (see above).  
2. `adb kill-server && adb start-server`  
3. Stale AVD lock → `find "$HOME/.android/avd/Pixel_9.avd" -name "*.lock" -delete`  
4. Multiple devices → add `-s emulator-5554` to target the emulator.

---

## Google Sign-In: two OAuth clients (don’t mix them up)

Stella Fit needs **two** OAuth clients in the same Google Cloud project (`restfit-23f3f` / `611638882841`):

| Type | Client ID (suffix) | Where it goes | Purpose |
|------|-------------------|---------------|---------|
| **Android** | `…5kbs8…` | Google Cloud only (auto-created) | Proves package `com.restfit.app` + signing SHA-1 |
| **Web** | `…d6jdj…` | `GoogleAuthConfig.swift`, Firebase Google Web SDK | ID tokens (`serverClientId`) |

**Never** put the Android client ID (`…5kbs8…`) in Firebase Web SDK or app code.

**Never** delete the Android client — Google uses it automatically when the app matches package + cert.

Current Web client ID (app + Firebase):

```text
611638882841-d6jdj0ecjrhfg35gola6h74tep4psug0.apps.googleusercontent.com
```

Debug Android client (emulator / local debug APK):

```text
611638882841-5kbs8fr6esesigddt8goh7ihg43s0lj6.apps.googleusercontent.com
Package: com.restfit.app
SHA-1: 44:73:49:9B:15:C4:A6:B6:7D:35:4A:4B:C3:4E:40:B4:D0:17:E8:8F
```

---

## “Google blocked debug Sign-In” = `[16] Account reauth failed`

When the app shows **Google blocked debug Sign-In**, logcat (`RestFitAuth`) usually has:

```text
SignInWithGoogle cancelled: [16] Account reauth failed
```

This is **not** the user cancelling. Google Play Services rejected Sign-In **after** picking an account.

### Debug order (after Aug 29 fix)

1. **Emulator DNS** — `ping google.com` must work (see [Solved issues](#aug-29-2026--debug-google-sign-in-checking-info-loop--google-blocked-debug-sign-in))  
2. **Emulator Google account** — remove + re-add if Play Services cache was cleared  
3. **OAuth config** — only if 1–2 are fine (SHA, clients, scopes, Web secret)  

### Where to look in Firebase vs Google Cloud

| What | Firebase Console | Google Cloud Console |
|------|------------------|----------------------|
| SHA-1 fingerprints | Project settings → Android app | (Firebase syncs; also verify Android OAuth client) |
| Web client ID + secret | Authentication → Sign-in method → **Google** → Web SDK | Credentials → **Web application** client |
| OAuth scopes | — | OAuth consent screen → **Data Access** |
| Publishing / test users | — | OAuth consent screen → **Publishing status** |
| Authorized domains | Authentication → **Settings** | Web client redirect URIs (web only; not Android Sign-In) |

**Web SDK is not** under Authentication → Settings → Authorized domains. It’s under **Sign-in method → Google** (click the Google row).

### Config checklist (debug emulator)

- [ ] `adb shell ping -c 1 google.com` succeeds  
- [ ] Google account signed in on emulator  
- [ ] Firebase SHA includes debug `44:73:49:9B:…`  
- [ ] Google Cloud **Android** OAuth client: `com.restfit.app` + same debug SHA  
- [ ] App + Firebase Web SDK use **Web** client `…d6jdj…` (not `…5kbs8…`)  
- [ ] Firebase Web SDK **secret** matches current Google Cloud Web client secret  
- [ ] OAuth **Data Access**: `openid`, `userinfo.email`, `userinfo.profile`  
- [ ] OAuth **In production** → no test users required; if **Testing** → add Gmail under Test users  
- [ ] Wait ~10 minutes after Google Cloud / Firebase changes  

### Emulator gotcha

Clearing Play Services cache (`adb shell pm clear com.google.android.gms`) can break the device Google account. Logcat shows:

```text
BAD_AUTHENTICATION … accounts.reauth
Long live credential not available
[16] Account reauth failed
```

**Symptom:** Google UI spins on **“Checking info…”**, then Stella Fit shows **Google blocked debug Sign-In**.

**Fix:**

1. Restart emulator with `-dns-server 8.8.8.8,1.1.1.1`  
2. **Settings → Passwords & accounts** → remove Google account → add it again  
3. If still broken: Android Studio → **Device Manager** → **Wipe Data** or **Cold Boot** on the AVD  
4. Do **not** run `pm clear com.google.android.gms` on the emulator unless you plan to re-add the Google account  

Stella Fit skips `clearCredentialState` on debug builds (Play-only) so the app doesn’t make emulator reauth worse.

### Workaround

**Sign in with Email** uses Firebase email/password only — no Android OAuth SHA. If email works but Google doesn’t, the problem is Google OAuth / emulator, not Firebase core.

---

## Firebase Android app fingerprints (verified Aug 2026)

All registered for `com.restfit.app`:

| Role | SHA-1 |
|------|--------|
| Debug / emulator | `44:73:49:9B:15:C4:A6:B6:7D:35:4A:4B:C3:4E:40:B4:D0:17:E8:8F` |
| Upload keystore | `16:E9:B1:B4:B4:5D:BB:35:87:8F:21:65:D7:F8:72:FD:19:75:A1:63` |
| Play App signing (current) | `CF:E4:0A:CE:9F:05:76:81:1B:89:E8:CC:01:D2:C8:B5:14:25:04:FC` |
| Play App signing (older) | `CF:50:E6:E5:17:F3:0F:A3:B8:1E:CB:B1:23:91:77:2F:69:7A:39:57` |

Trust **`apksigner verify --print-certs`** on the installed APK over stale Play Console labels.

---

## Code touchpoints

| Path | Role |
|------|------|
| `Sources/RestFit/Services/GoogleAuthConfig.swift` | Web client ID, SHA hints, error copy |
| `Sources/RestFit/Services/GoogleAuthService.swift` | Credential Manager Sign-In flow |
| `Android/app/google-services.json` | Firebase OAuth clients (refresh after fingerprint changes) |

Logcat tag for Sign-In: **`RestFitAuth`**.
