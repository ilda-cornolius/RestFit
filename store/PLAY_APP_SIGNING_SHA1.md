# Play App Signing SHA-1 and Google Sign-In

This explains **why** Google Sign-In can work on your emulator but fail when people install Stella Fit from the Play Store — and exactly what to register where.

## The idea in one sentence

Google only trusts Sign-In from app installs whose **signing certificate SHA-1** is registered for package `com.restfit.app`. Play Store installs are signed with a **different** certificate than the one on your Mac.

## Two keys, two SHA-1 fingerprints

When you use **Play App Signing** (default for new apps), there are two important certificates:

| Key | Who has it | When it’s used | SHA-1 nickname |
|-----|------------|----------------|----------------|
| **Upload key** | You (`Android/app/keystore.jks`) | You build + upload the `.aab` | Upload key certificate |
| **App signing key** | Google Play | Play re-signs the app before users install | App signing key certificate |

Flow:

```text
Your Mac                          Google Play                         User's phone
────────                          ───────────                         ───────────
Build app-release.aab
signed with UPLOAD key
        │
        ▼
   Upload to Play  ─────────────►  Re-sign with APP SIGNING key
                                          │
                                          ▼
                                   User installs from Play
                                   (signed with APP SIGNING key)
```

- Local debug / emulator installs → usually **debug** or **upload** SHA-1  
- Play Store / internal testing installs → **App signing** SHA-1  

If Firebase / Google Cloud only know your upload + debug SHA-1s, Play installs look “unknown” and Google Sign-In fails.

## What SHA-1 is

A **SHA-1** fingerprint is a short fingerprint of the certificate that signed the APK/AAB.  
Google uses it like a allowlist:

> “Only apps signed with these fingerprints may use Google Sign-In for `com.restfit.app`.”

You do **not** put the App signing SHA-1 into Swift code.  
You only register it in **Firebase** and **Google Cloud**.

The value in `GoogleAuthConfig.swift` is still the **Web client ID** (different thing).

## What to copy from Play Console

1. Open [Google Play Console](https://play.google.com/console)
2. Select **Stella Fit**
3. Go to **Test and release → App integrity**  
   (sometimes under **Setup → App signing**)
4. Find **App signing key certificate**
5. Copy **SHA-1** (looks like `AB:CD:EF:…`)

Also note **Upload key certificate** SHA-1 there — it should match your local release keystore:

```text
16:E9:B1:B4:B4:5D:BB:35:87:8F:21:65:D7:F8:72:FD:19:75:A1:63
```

## Where to paste the App signing SHA-1

Do **both** places (same SHA-1):

### 1. Firebase

1. [Firebase Console](https://console.firebase.google.com/) → your project  
2. ⚙️ **Project settings**  
3. Your Android app: `com.restfit.app`  
4. **Add fingerprint** → paste Play **App signing** SHA-1 → Save  

Optional: download a fresh `google-services.json` and replace:

`Android/app/google-services.json`

### 2. Google Cloud (Android OAuth client)

1. [Google Cloud Console](https://console.cloud.google.com/) → same Google project as Firebase  
2. **APIs & Services → Credentials**  
3. Open (or create) an OAuth client of type **Android**  
   - Package name: `com.restfit.app`  
   - SHA-1: the Play **App signing** SHA-1  
4. Save  

You can keep separate Android clients per SHA-1, or multiple fingerprints depending on how your console UI is set up — what matters is that the Play signing SHA-1 is registered for `com.restfit.app`.

## SHA-1s Stella Fit should have registered

| Source | Purpose |
|--------|---------|
| Play **App signing** SHA-1 | Play Store / closed testing installs |
| Upload key `16:E9:B1:…` | Local release builds / what you upload |
| Debug `44:73:49:…` | Emulator / debug APK |

## How to verify it worked

1. Wait a few minutes after saving fingerprints  
2. Install Stella Fit from the **Play testing link** (not a local `adb install` of a debug APK)  
3. Tap **Sign in with Google**  
4. Account picker / sign-in should complete instead of failing immediately  

If it still fails:

- Confirm you copied **App signing** SHA-1, not only Upload key  
- Confirm package is exactly `com.restfit.app`  
- Confirm OAuth consent screen has your test Gmail as a **Test user** while the app is in Testing  
- Confirm Web client ID in `GoogleAuthConfig.swift` is a **Web application** client ID  

## Related docs

- How to test from Play vs local APK (and whether you must recompile): [`TEST_GOOGLE_SIGNIN_FROM_PLAY.md`](./TEST_GOOGLE_SIGNIN_FROM_PLAY.md)  
- Step-by-step Sign-In setup: [`GOOGLE_SIGNIN_SETUP.md`](./GOOGLE_SIGNIN_SETUP.md)  
- Package / listing notes: [`PLAY_CONSOLE.md`](./PLAY_CONSOLE.md)
