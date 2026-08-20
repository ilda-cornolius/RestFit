# Lessons learned: Google Sign-In on Play

Notes from Stella Fit closed testing (Play Store vs debug). Use this when Sign-In works in debug/`adb` but fails after choosing an account from a Play install.

## 1. ProGuard / R8 strips Credential Manager in release builds

### Symptom
- Debug APK: Google Sign-In works.
- Play Store / release AAB: account picker appears, user selects a Google account, then nothing (or a vague “no credential” / “did not finish” error).

### Cause
Release builds use minify (`isMinifyEnabled = true` in `Android/app/build.gradle.kts`). Without keep rules, R8 can strip or break:

- `androidx.credentials.**`
- `com.google.android.libraries.identity.googleid.**`
- related Play Services / Firebase Auth classes

Debug builds are not minified the same way, so the bug only shows up on Play.

### Fix
Keep rules in `Android/app/proguard-rules.pro` (do not remove them when editing ProGuard):

```proguard
-keep class androidx.credentials.** { *; }
-keep class androidx.credentials.playservices.** { *; }
-keep class com.google.android.libraries.identity.googleid.** { *; }
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-keep class com.google.firebase.auth.** { *; }
```

Ship a **new Play build** after changing ProGuard — SHA-1 registration alone does not fix this.

### How to tell SHA-1 vs ProGuard
| Check | SHA-1 missing | ProGuard stripping |
|--------|----------------|---------------------|
| Debug Sign-In | Often works | Works |
| Play Sign-In | Fails | Fails after account pick |
| Play App signing SHA-1 in Firebase + Android OAuth client | Missing / wrong | Already correct |
| New release with keep rules | Still fails if SHA wrong | Usually fixes |

Stella Fit Play App signing SHA-1 (already registered):

`CF:50:E6:E5:17:F3:0F:A3:B8:1E:CB:B1:23:91:77:2F:69:7A:39:57`

---

## 2. OAuth consent screen must list Sign-In scopes

### Symptom
- Publishing status can be **In production**.
- User picks a Gmail in the account UI.
- Sign-In still fails (cancel / no credential / misleading “no Google account” message).

### Cause
**Data Access** had **no scopes** configured (non-sensitive, sensitive, and restricted all empty).

Google Sign-In with ID tokens needs at least the standard non-sensitive scopes. An empty scope list can leave OAuth unable to complete after account selection.

### Fix
Google Cloud → **APIs & Services → OAuth consent screen → Data Access** → **Add or remove scopes**.

Add these **non-sensitive** scopes only:

| Scope | Purpose |
|--------|---------|
| `openid` | OpenID / ID token |
| `https://www.googleapis.com/auth/userinfo.email` | Email |
| `https://www.googleapis.com/auth/userinfo.profile` | Name / photo |

They must appear under **Your non-sensitive scopes**. Stella Fit does **not** need sensitive or restricted scopes for basic Sign-In.

Save, wait a few minutes, then retry on the device.

### Related Audience notes
- **In production** + **External**: Test users are not required for normal Sign-In scopes.
- **Testing** publishing status: only Gmails listed under Test users can complete consent.
- The **100 user cap** on the Audience page applies to unapproved sensitive/restricted scopes — not to approved non-sensitive Sign-In scopes above.

---

## 3. Misleading in-app errors (avoid repeating)

| Message shown | What it often really means |
|---------------|----------------------------|
| “No Google account is available…” | Credential Manager returned `NoCredential` **after** the user already picked an account (scopes / OAuth / minify) — not that the phone has zero Google accounts. |
| Long “add Play App signing SHA-1…” text | Only accurate if that SHA-1 is actually missing. If Firebase already has `CF:50:E6:…`, look at ProGuard and scopes first. |
| Silent return to login after account pick | Classic release minify or OAuth incomplete; check logcat tag `RestFitAuth`. |

Prefer errors that point to **Test users** (only when status is Testing), **scopes**, or **update Play build**, not a single always-SHA-1 message.

---

## Quick checklist (Play Sign-In broken, debug OK)

1. [ ] OAuth **Data Access** includes `openid`, `userinfo.email`, `userinfo.profile`.
2. [ ] ProGuard keep rules for Credential Manager / Google ID are present; **new AAB uploaded** after any ProGuard change.
3. [ ] Play **App signing** SHA-1 is in Firebase fingerprints and an Android OAuth client for `com.restfit.app`.
4. [ ] App `webClientID` is the **Web** client ID (not an Android client ID) — see `GoogleAuthConfig.swift`.
5. [ ] Firebase Authentication → Google provider **Enabled**.
6. [ ] Tester uses a Play-installed build only (uninstall debug/sideload copies first).

## Related docs

- [`PLAY_APP_SIGNING_SHA1.md`](./PLAY_APP_SIGNING_SHA1.md) — why Play uses a different SHA-1 than debug/upload
- [`GOOGLE_SIGNIN_SETUP.md`](./GOOGLE_SIGNIN_SETUP.md) — Web + Android client setup
- [`TEST_GOOGLE_SIGNIN_FROM_PLAY.md`](./TEST_GOOGLE_SIGNIN_FROM_PLAY.md) — testing Play vs local APK
