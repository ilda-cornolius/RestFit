# Firebase setup (email / password auth)

RestFit uses **Firebase Authentication** for email + password sign-in and registration.

## 1. Create a Firebase project

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Add project (e.g. **RestFit**)
3. Add an **Android** app:
   - Package name: `com.restfit.app`
   - Download `google-services.json`
4. Replace this file:

`Android/app/google-services.json`

(The repo has a placeholder — overwrite it with your real download.)

## 2. Enable Email/Password

Firebase Console → **Authentication** → **Sign-in method** → enable **Email/Password**.

## 3. Optional: Google provider in Firebase

You can also enable **Google** under Sign-in method. The app’s Google button currently uses Google Identity / Credential Manager; email accounts always go through Firebase.

## 4. Rebuild

```bash
cd /Users/ilda/restfit
swift build
cd Android && gradle :app:assembleDebug
```

## Play Console app access

With email/password enabled, give reviewers:

| Field | Example |
|-------|---------|
| Email | `restfit.reviewer@gmail.com` (create this account in the app first) |
| Password | a strong password you set |
| Notes | Use email/password on the title screen, or Sign in with Google |

**Is any part of your app restricted?** → **Yes**
