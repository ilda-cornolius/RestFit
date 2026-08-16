# Emulator “Network error” with Firebase Auth — what happened & how we fixed it

RestFit email/password sign-in uses **Firebase Authentication**. On the Android emulator we saw:

> Network error. Check your connection and try again.

This note explains the real cause and the fix so you can recognize it next time.

---

## What the app showed

Firebase Auth error **code 17020**:

> A network error (such as timeout, interrupted connection or unreachable host) has occurred.

In logcat it looked like:

```text
E RecaptchaCallWrapper: Initial task failed for action RecaptchaAction(action=signUpPassword)
   with exception - A network error ... has occurred.
E RestFitAuth: register failed: ... code=17020 "a network error ..."
I FirebaseAuth: Creating user with ...@gmail.com with empty reCAPTCHA token
```

So Firebase was failing **before** it finished creating the account — during **reCAPTCHA / network** setup, not because the password was wrong.

---

## Symptom check: IP works, DNS does not

On the emulator:

```bash
adb shell ping -c 2 8.8.8.8
# SUCCESS — packets returned

adb shell ping -c 2 google.com
# FAIL — ping: unknown host google.com
```

That pattern means:

| Check | Result | Meaning |
|-------|--------|---------|
| Ping an **IP** (8.8.8.8) | Works | The virtual network / routing is fine |
| Ping a **hostname** (google.com) | Fails | **DNS lookup** is broken |

Apps almost never talk to raw IPs for Firebase. They need names like:

- `identitytoolkit.googleapis.com`
- `www.recaptcha.net` / Google reCAPTCHA endpoints

If DNS fails, Firebase reports a generic **network error**.

---

## Why Firebase needs the network (and DNS)

Email/password Auth on Android often goes through:

1. App → Firebase Auth SDK  
2. SDK may contact **reCAPTCHA** / Google APIs (bot protection)  
3. Then create/sign-in the user  

If reCAPTCHA or Identity Toolkit hosts cannot be resolved, you get 17020 even though Wi‑Fi “looks connected” in the emulator.

---

## Why live DNS property tweaks often fail

We tried setting DNS on a running emulator:

```bash
adb root
adb shell setprop net.dns1 8.8.8.8
```

On **Google Play / production** system images, `adbd cannot run as root`, and `setprop net.dns1` is blocked. So you usually **cannot** permanently fix DNS that way on those AVDs.

---

## The fix: start the emulator with public DNS servers

Kill the old emulator, clear stale AVD locks if needed, then start with explicit DNS:

```bash
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH"

# optional: clear locks if “multiple emulators with same AVD” error
find "$HOME/.android/avd/Pixel_9.avd" -name "*.lock" -delete

emulator -avd Pixel_9 -dns-server 8.8.8.8,1.1.1.1 -netdelay none -netspeed full
```

`-dns-server 8.8.8.8,1.1.1.1` tells QEMU to use Google/Cloudflare DNS instead of a broken emulator DNS path.

### Verify after boot

```bash
adb wait-for-device
adb shell getprop sys.boot_completed   # expect: 1
adb shell ping -c 1 google.com         # should resolve and reply
adb shell ping -c 1 identitytoolkit.googleapis.com
```

Then reinstall / launch RestFit and try **Create account** again.

---

## How we confirmed it in RestFit

We log raw Auth failures under tag `RestFitAuth`:

```bash
adb logcat -s RestFitAuth:E RecaptchaCallWrapper:E FirebaseAuth:I
```

Useful greps:

```bash
adb logcat -d | rg -i "RestFitAuth|RecaptchaCallWrapper|17020|network error"
```

After the DNS fix, hostname pings succeed and Auth can reach Firebase/reCAPTCHA.

---

## Other causes (if DNS is already fine)

If `google.com` resolves but Auth still fails, check:

1. **Email/Password enabled** — Firebase Console → Authentication → Sign-in method  
2. **Correct `google-services.json`** — package `com.restfit.app`, project `restfit-23f3f`  
3. **Real device / different network** — corporate VPN or captive portal can block Google APIs  
4. **App Check / reCAPTCHA** — unusual Console settings can block sign-up  

Those produce different messages (e.g. operation-not-allowed), not always 17020.

---

## Mental model (study summary)

```text
Emulator Wi‑Fi “Connected”
        │
        ├─ Can reach 8.8.8.8 by IP?  ──yes──► routing OK
        │
        └─ Can resolve google.com?  ──no───► DNS broken
                                              │
                                              ▼
                                    Firebase Auth / reCAPTCHA fail
                                              │
                                              ▼
                                    Error 17020 “network error”
```

**Fix DNS at emulator start** (`-dns-server ...`), don’t assume “connected Wi‑Fi” means hostnames work.

---

## Related RestFit docs

- `store/FIREBASE_SETUP.md` — enable Email/Password, place `google-services.json`  
- `store/GOOGLE_SIGNIN_SETUP.md` — Google Sign-In / OAuth clients  
