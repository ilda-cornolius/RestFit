# Google Sign-In setup for Stella Fit

Google Sign-In is required on the title screen. Until you add a Web client ID, the button stays disabled.

> **Play Store installs:** Google Sign-In fails unless the **Play App Signing SHA-1** is registered in Firebase and Google Cloud.  
> Read the full explanation: [`PLAY_APP_SIGNING_SHA1.md`](./PLAY_APP_SIGNING_SHA1.md).

## 1. Google Cloud Console

1. Open [Google Cloud Console](https://console.cloud.google.com/)
2. Create (or select) a project, e.g. **Stella Fit** (existing project id may still be `restfit-…`)
3. **APIs & Services → OAuth consent screen**
   - User type: External
   - App name: Stella Fit
   - Support email: your email
   - Add scopes: `email`, `profile`, `openid`
   - Add your Google account as a **Test user** while the app is in Testing
4. **APIs & Services → Credentials → Create credentials → OAuth client ID**

### A. Web client (required)

- Application type: **Web application**
- Name: Stella Fit Web
- Copy the **Client ID**
- Paste it into:

`Sources/RestFit/Services/GoogleAuthConfig.swift`

```swift
static let webClientID = "495023895655-17k5c9mpmm74mhd0rrvgpdrumjujbsk0.apps.googleusercontent.com"
```

> **Important:** `webClientID` must be a **Web application** client ID.
> The **Android** client (package + SHA-1) is separate and does not go in this field.
> If the ID above was from the Android client, create another client with type **Web application** and replace this value with that Web client ID.

### B. Android client (required for real devices / Play)

- Application type: **Android**
- Package name: `com.restfit.app`
- Add **every** SHA-1 below (create multiple Android clients or add fingerprints to the Firebase Android app):

**1. Play App Signing key (required for Play Store installs)**  
Play Console → your app → **Test and release** → **App integrity** / **Setup → App signing** → copy **App signing key certificate** SHA-1.

Without this SHA-1, Google Sign-In works in local/debug builds but **fails for users who install from Play**.

**2. Upload key (local release / bundle you upload):**
```
16:E9:B1:B4:B4:5D:BB:35:87:8F:21:65:D7:F8:72:FD:19:75:A1:63
```

**3. Debug (emulator):**
```
44:73:49:9B:15:C4:A6:B6:7D:35:4A:4B:C3:4E:40:B4:D0:17:E8:8F
```

Also paste those SHA-1 values into Firebase Console → Project settings → Your Android app (`com.restfit.app`) → **Add fingerprint**.

## 2. Rebuild

```bash
cd /Users/ilda/restfit
swift build
cd Android && gradle :app:bundleRelease
```

## 3. Play Console → App access

Because the title screen requires Google Sign-In, answer:

**Is any part of your app restricted?** → **Yes**

Provide a Google account reviewers can use:

| Field | Value |
|-------|--------|
| Email / username | a dedicated test Gmail you create |
| Password | that account’s password |
| Any other info | “Sign in with Google on the title screen using this account. All features unlock after sign-in.” |

Add that same Gmail as an OAuth **Test user** in Google Cloud while the consent screen is in Testing.
