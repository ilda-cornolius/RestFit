# Google Sign-In setup for RestFit

Google Sign-In is required on the title screen. Until you add a Web client ID, the button stays disabled.

## 1. Google Cloud Console

1. Open [Google Cloud Console](https://console.cloud.google.com/)
2. Create (or select) a project, e.g. **RestFit**
3. **APIs & Services → OAuth consent screen**
   - User type: External
   - App name: RestFit
   - Support email: your email
   - Add scopes: `email`, `profile`, `openid`
   - Add your Google account as a **Test user** while the app is in Testing
4. **APIs & Services → Credentials → Create credentials → OAuth client ID**

### A. Web client (required)

- Application type: **Web application**
- Name: RestFit Web
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
- SHA-1 fingerprints (add both):

**Release (Play upload key):**
```
16:E9:B1:B4:B4:5D:BB:35:87:8F:21:65:D7:F8:72:FD:19:75:A1:63
```

**Debug (emulator):**
```
44:73:49:9B:15:C4:A6:B6:7D:35:4A:4B:C3:4E:40:B4:D0:17:E8:8F
```

If you use Play App Signing, also add the **App signing key certificate SHA-1** from Play Console → Setup → App signing.

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
