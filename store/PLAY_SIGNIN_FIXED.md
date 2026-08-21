# What fixed Play Google Sign-In (Aug 21, 2026)

## Short answer

Play Store installs were signed with a **different App signing certificate** than the SHA-1 we had registered in Firebase / Google Cloud.

| | SHA-1 |
|--|--------|
| **What we had registered** (old / previous Play key) | `CF:50:E6:E5:17:F3:0F:A3:B8:1E:CB:B1:23:91:77:2F:69:7A:39:57` |
| **What was actually on the phone** (Play-installed v27) | `CF:E4:0A:CE:9F:05:76:81:1B:89:E8:CC:01:D2:C8:B5:14:25:04:FC` |

Google Credential Manager checked the real cert, did not find a matching Android OAuth client, and failed with a misleading error:

```text
GetCredentialCancellationException: [16] Account reauth failed
```

That looks like “user cancelled” or “reauth,” but it was **OAuth config / SHA mismatch**.

## Symptoms

- Debug / emulator Google Sign-In: **worked**
- Play closed testing: account picker appeared → choose Gmail → **failed**, back to login
- On-screen hint talked about Play SHA / config
- logcat `RestFitAuth`:
  - `GetGoogleId no credential: NoCredentialException`
  - `SignInWithGoogle cancelled: [16] Account reauth failed`

## What was *not* the remaining blocker

These were real issues earlier, but by the final failure they were already addressed:

- Release ProGuard/R8 (minify disabled for release)
- OAuth scopes (`openid`, email, profile)
- Web client ID swap (`…ga71…` → `…d6jd…`) + Firebase Web client secret
- Phone still on an old build (v26 had old Web client; v27 had `…d6jd…`)
- Digital Asset Links JSON (App Links only — not Sign-In)
- Play Installer check / Automatic protection
- Testing track (closed vs internal) — same signing key

## How we proved it

1. Confirmed phone install: `installerPackageName=com.android.vending`, `versionCode=27`.
2. Pulled the Play-installed APK via `adb`.
3. Ran:

```bash
apksigner verify --print-certs base.apk
```

4. Result (Play App signing cert on device):

```text
SHA-1:   CF:E4:0A:CE:9F:05:76:81:1B:89:E8:CC:01:D2:C8:B5:14:25:04:FC
SHA-256: 8E:C1:75:1B:E9:4E:A5:70:EE:FC:7B:47:59:A5:E8:8E:09:4B:95:AD:10:4F:AA:7E:16:C6:B2:9A:5C:00:17:25
```

5. That SHA-256 matched Play Console’s Digital Asset Links snippet — while Firebase still only had `CF:50:…`.

Play Console had shown **quantum-ready / previous app signing keys**. The UI “classical” SHA we copied earlier was **stale relative to what devices actually get**. Trust **`apksigner` on the installed APK**, not the console label alone.

## What we fixed

1. Added SHA-1 `CF:E4:0A:CE:9F:05:76:81:1B:89:E8:CC:01:D2:C8:B5:14:25:04:FC` to **Firebase** → Project settings → Android app fingerprints.
2. Google auto-created Android OAuth client  
   `611638882841-a4lva203dngshibqiuev47nidl4tg38g…` for `com.restfit.app` + that SHA.
3. Kept older fingerprints too (upload `16:E9:…`, debug `44:73:…`, previous Play `CF:50:…`).
4. Kept Web client `…d6jd…` in the app + Firebase Google provider.
5. Documented current Play SHA in `GoogleAuthConfig.playStoreSha1` and `google-services.json`.

**No new AAB was strictly required for the SHA fix** (server-side OAuth). Rebuilding (e.g. v28) is still fine for shipping updated hints / config.

## Lesson for next time

When Play Sign-In fails with `[16] Account reauth failed` after the account picker:

```bash
adb shell pm path com.restfit.app
adb pull <base.apk path> /tmp/base.apk
apksigner verify --print-certs /tmp/base.apk
```

Register **that** SHA-1 in Firebase + Google Cloud Android OAuth. Do not assume the Play Console App signing SHA you copied weeks ago is still what devices use.

## Related

- [`GOOGLE_SIGNIN_LESSONS_LEARNED.md`](./GOOGLE_SIGNIN_LESSONS_LEARNED.md) — full living checklist
- [`PLAY_APP_SIGNING_SHA1.md`](./PLAY_APP_SIGNING_SHA1.md) — why Play uses a different key than upload
- [`TEST_GOOGLE_SIGNIN_FROM_PLAY.md`](./TEST_GOOGLE_SIGNIN_FROM_PLAY.md) — how to test the Play install
