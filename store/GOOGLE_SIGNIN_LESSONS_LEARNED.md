# Lessons learned: Google Sign-In on Play

Living notes from Stella Fit closed testing. **Update this file whenever we debug a Sign-In issue** so the next pass does not repeat the same wrong diagnosis.

Use this when Sign-In works in debug/`adb` but fails after choosing an account from a Play install.

---

## 0. Mental model

| Install | Signing cert Google checks | Typical local path |
|---------|----------------------------|--------------------|
| Debug / emulator | Debug keystore SHA-1 | `44:73:49:9B:…` |
| Local release APK | Upload keystore SHA-1 | `16:E9:B1:B4:…` |
| Play Store / closed testing | **Play App signing** SHA-1 | `CF:50:E6:E5:…` |

Play re-signs your AAB. Upload-key SHA-1 is **not** enough for Play installs.

Stella Fit fingerprints (keep all three registered):

| Role | SHA-1 |
|------|--------|
| Upload | `16:E9:B1:B4:B4:5D:BB:35:87:8F:21:65:D7:F8:72:FD:19:75:A1:63` |
| Debug | `44:73:49:9B:15:C4:A6:B6:7D:35:4A:4B:C3:4E:40:B4:D0:17:E8:8F` |
| Play App signing | `CF:50:E6:E5:17:F3:0F:A3:B8:1E:CB:B1:23:91:77:2F:69:7A:39:57` |

Play SHA-256 (optional in Firebase):  
`C1:9E:2D:D4:B8:82:E4:A7:D6:4E:9B:DB:3C:3C:5F:B6:E2:EB:92:53:FF:40:D7:6A:5F:FC:DA:31:89:14:1F:C6`

**Post-quantum cryptography key** in Play Console: ignore for Sign-In / OAuth. Not used as a Firebase fingerprint today.

---

## 1. ProGuard / R8 breaks Credential Manager on Play

### Symptom
- Debug: Sign-In works.
- Play release: account picker → choose account → fail / return to login.

### Cause
Release minify (`isMinifyEnabled = true`) can strip or break Credential Manager / Google ID / Play Services Auth. Debug is not minified the same way.

### Fix tried
1. Keep rules in `Android/app/proguard-rules.pro`:

```proguard
-keep class androidx.credentials.** { *; }
-keep class androidx.credentials.playservices.** { *; }
-keep class com.google.android.libraries.identity.googleid.** { *; }
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-keep class com.google.firebase.auth.** { *; }
```

2. If Play still fails after keep rules + correct SHA + scopes, **disable release minify** (Stella Fit did this from v25):

```kotlin
// Android/app/build.gradle.kts — release
isMinifyEnabled = false
isShrinkResources = false
```

Ship a **new Play build** after any ProGuard/minify change.

### Lesson
Keep rules alone were **not enough** for Skip + Credential Manager on Play. Disabling minify made the release APK much larger (~20 MB → ~74 MB APK) but matched debug behavior for Sign-In experiments. Re-enable minify later only after verifying Sign-In still works.

---

## 2. OAuth Data Access must list Sign-In scopes

### Symptom
Account picker works; then cancel / no credential / stuck login. Audience can already be **In production**.

### Cause
**Data Access** had **zero scopes** (non-sensitive / sensitive / restricted all empty).

### Fix
Google Cloud → OAuth consent screen → **Data Access** → add **non-sensitive** only:

| Scope | Purpose |
|--------|---------|
| `openid` | ID token |
| `…/auth/userinfo.email` | Email |
| `…/auth/userinfo.profile` | Name / photo |

No sensitive or restricted scopes needed for Stella Fit Sign-In (no verification required for those three).

### Audience lessons
- **In production** + **External**: Test users are **not** required.
- **Testing**: only listed Test users can complete consent — wrong advice if status is already Production.
- **0 / 100 user cap**: applies to unapproved sensitive/restricted scopes, **not** these non-sensitive Sign-In scopes.
- Do not tell testers to “add Test users” when publishing status is **In production** (we shipped a misleading error once; fixed in later builds).

---

## 3. `GetCredentialCancellationException` often means config, not the user

### Symptom
User clearly picks a Gmail; app reports cancelled / “didn’t finish after you chose an account.”

### Cause (Google + Stack Overflow consensus)
Credential Manager frequently surfaces SHA-1 / Android OAuth / reauth failures as **user cancelled** (sometimes `[16] Account reauth failed` under the hood).

### Lessons
- Debug OK + Play fail after account pick ≈ Play App signing SHA / Android OAuth client problem **or** minify — not “user hit Back.”
- Firebase **SHA certificate fingerprints** can look complete while **Google Cloud → Credentials → Android OAuth client** for `com.restfit.app` + Play SHA-1 is missing, wrong, or stale. **Verify both.**
- App code must use the **Web** client ID as `serverClientId` / `webClientID` (`…ga71…`). Android clients are for package+SHA verification only — never paste an Android client ID into `GoogleAuthConfig.webClientID`.
- Firebase Authentication → Google → **Web SDK configuration** must use that same Web client ID + Web client secret from Google Cloud.
- Clearing credential state before Sign-In can help stale Play reauth (`clearCredentialState`).
- Prefer showing a short **Detail:** from the real exception on Play builds so we stop guessing.

### What to verify in Google Cloud
1. Credentials → Android OAuth client (e.g. “Stella Fit Android Play”)
2. Package: `com.restfit.app` (exact — no `.debug` suffix)
3. SHA-1: Play App signing `CF:50:E6:E5:…`
4. Separate Android clients for debug + upload SHA-1s (or one client with multiple fingerprints if the UI allows)
5. Web client exists and matches `GoogleAuthConfig.webClientID`

---

## 4. Misleading in-app errors (do not trust wording alone)

| Message shown | What it often really meant for us |
|---------------|-----------------------------------|
| “No Google account is available…” | `NoCredential` **after** the user already picked an account (second picker / scopes / OAuth). Phone **did** have Google accounts. Removed that false message. |
| “While the OAuth app is in Testing, add Test users…” | Wrong when Audience is **In production**. Caused confusion; error copy updated. |
| “Update from Play / confirm openid email profile…” | Generic after cancel; still check Android OAuth SHA on Play if debug works. |
| Silent return to login (no message) | Early bug: cancel treated as silent; also Firebase hang possible. Always surface an error or progress text. |
| Long SHA-1 dump only | Incomplete if scopes empty or minify broken; SHA can already be correct in Firebase. |

Logcat tag: `RestFitAuth`.

---

## 5. Firebase Users list interpretation

- Google Sign-In **auto-creates** a Firebase user on first successful Google Sign-In (no separate “Create account”).
- New row with today’s **Signed In** = Auth reached Firebase for that attempt.
- Typo emails (e.g. `ildacoran@…` vs `ildacorn@…`) create **separate** Firebase users — use one Gmail for testing.
- Dynamic Links deprecation banner: ignore for Stella Fit (we use Google / email+password, not email-link).

---

## 6. Things that were NOT the main Play Sign-In blocker

| Setting / topic | Verdict |
|-----------------|---------|
| Play **Installer check** / Automatic protection | Unlikely for normal Play installs; optional to disable when comparing builds. |
| **Post-quantum** key in App integrity | Irrelevant to OAuth/Firebase fingerprints. |
| Upload key SHA-1 alone | Needed for upload identity, **not** what Play-installed apps present to Google Sign-In. |
| Emulator “System UI isn’t responding” | Emulator ANR; can interrupt account picker. Prefer real phone + Play for Sign-In proof. |

---

## 7. Beta site / Groups (related ops, not OAuth)

- Placeholder Groups URL (`stella-fit-closed-beta`) → Google “Content unavailable.” Real group: `https://groups.google.com/g/stella-fit` / `stella-fit@googlegroups.com`.
- Put Group + Play URLs in HTML `href`, not only JS (mobile / in-app browsers).
- Don’t lock the Play button behind a checkbox on mobile.
- Fold narrow tab bar: `WORKOUT` wrapping → `lineLimit(1)` + `minimumScaleFactor`.

---

## Quick checklist (Play Sign-In broken, debug OK)

1. [ ] Confirm **versionCode** on the phone matches the AAB you just uploaded (uninstall + reinstall from Play).
2. [ ] OAuth **Data Access** has `openid`, email, profile (non-sensitive).
3. [ ] Audience **In production** → do **not** chase Test users; if **Testing** → add the Gmail as Test user.
4. [ ] Firebase fingerprints include Play App signing SHA-1 `CF:50:E6:E5:…`.
5. [ ] Google Cloud **Android** OAuth client for `com.restfit.app` has that **same** Play SHA-1 (not only Firebase UI).
6. [ ] App uses **Web** client ID in `GoogleAuthConfig.swift` + Firebase Google provider Web SDK fields.
7. [ ] Release minify: keep rules present; if still failing, minify off (current Stella Fit approach) and retest.
8. [ ] Only one install source: Play testing build (no leftover debug APK).
9. [ ] Read the on-screen **Detail:** / logcat `RestFitAuth` before changing the next random setting.
10. [ ] **Update this file** with what you learned.

---

## Code / config touchpoints

| Path | Role |
|------|------|
| `Sources/RestFit/Services/GoogleAuthConfig.swift` | Web client ID + user-facing hints |
| `Sources/RestFit/Services/GoogleAuthService.swift` | Credential Manager flow |
| `Android/app/proguard-rules.pro` | Keep rules |
| `Android/app/build.gradle.kts` | `isMinifyEnabled` / shrink |
| `Sources/RestFit/Skip/skip.yml` | credentials / googleid / play-services-auth deps |
| `Android/app/google-services.json` | Firebase clients (refresh after fingerprint changes) |

---

## Related docs

- [`PLAY_APP_SIGNING_SHA1.md`](./PLAY_APP_SIGNING_SHA1.md) — why Play uses a different SHA-1
- [`GOOGLE_SIGNIN_SETUP.md`](./GOOGLE_SIGNIN_SETUP.md) — Web + Android client setup
- [`TEST_GOOGLE_SIGNIN_FROM_PLAY.md`](./TEST_GOOGLE_SIGNIN_FROM_PLAY.md) — Play vs local APK testing
