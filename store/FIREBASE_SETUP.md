# Firebase setup (email / password auth)

Stella Fit uses **Firebase Authentication** for email + password sign-in and registration, plus Google Sign-In via Credential Manager → Firebase Auth credential.

## 1. Create a Firebase project

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Add project (e.g. **Stella Fit**; existing project id may still be `restfit-…`)
3. Add an **Android** app:
   - Package name: `com.restfit.app`
   - App nickname: Stella Fit
   - Download `google-services.json`
4. Replace this file:

`Android/app/google-services.json`

(The repo has a placeholder — overwrite it with your real download. If the download drops debug/upload OAuth clients or changes the Web client ID, merge carefully — see [`GOOGLE_SIGNIN_LESSONS_LEARNED.md`](./GOOGLE_SIGNIN_LESSONS_LEARNED.md) §8.)

## 2. Enable Email/Password

Firebase Console → **Authentication** → **Sign-in method** → enable **Email/Password**.

## 3. Google provider in Firebase

Enable **Google** under Sign-in method. Set **Web SDK configuration** to the same **Web** OAuth client ID/secret used in `GoogleAuthConfig.webClientID` (must match `google-services.json` type-3 client).

## 4. Gradle / SDK — already set up for Skip

Firebase’s “Add Firebase SDK” wizard shows project-level + `firebase-bom` steps for a normal Android app.

**Stella Fit already has this covered differently:**

| Firebase wizard step | Stella Fit |
|----------------------|------------|
| `google-services` Gradle plugin | `Android/app/build.gradle.kts` — `id("com.google.gms.google-services")` (currently **4.5.0**) |
| `google-services.json` | `Android/app/google-services.json` |
| `firebase-bom` + `firebase-auth` / Analytics | **SkipFirebaseAuth** / **SkipFirebaseCore** via `Package.swift` — do **not** also add BoM Auth deps in the app Gradle file (version conflicts) |
| `FirebaseApp.configure()` | `FirebaseAuthService.configureIfNeeded()` / app launch |

You only need to keep `google-services.json` current and the plugin applied. Re-running the full Firebase BoM snippet on top of Skip is usually unnecessary and can break the build.

## 5. Rebuild

```bash
cd /Users/ilda/restfit
swift build
skip export --release --android --no-ios
```

## Play Console app access

With email/password enabled, give reviewers:

| Field | Example |
|-------|---------|
| Email | `restfit.reviewer@gmail.com` (create this account in the app first) |
| Password | a strong password you set |
| Notes | Use email/password on the title screen, or Sign in with Google |

**Is any part of your app restricted?** → **Yes**
