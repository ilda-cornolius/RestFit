# Test Google Sign-In from Play (not a local APK)

## Do I need to compile and upload a new Play Store build?

**For the SHA-1 / OAuth credentials you just added: no.**

Registering the Play App Signing SHA-1 in Firebase and creating the Android OAuth client happens **on Google’s servers**. The app already on Play can pick that up after a few minutes. You do **not** need to rebuild or upload a new `.aab` just because you added a fingerprint.

Then:

1. On your phone, open the **Play testing / opt-in link**
2. Install or **update** Stella Fit from Play (pull to refresh the store listing if it doesn’t show an update)
3. Open **that** Play-installed app
4. Tap **Sign in with Google**

---

## When you *do* need a new Play upload

Upload a new `.aab` only if you changed **app code** (for example Fold layout, Stella Fit title, Google Sign-In using Activity context). Those live in version **4** locally (`CURRENT_PROJECT_VERSION = 4`).

If Play still has an older bundle (version 1 / 2 / 3), you still need to upload version 4 for **those** fixes.  
Credential-only changes (SHA-1, OAuth clients) do **not** require that.

---

## Play install vs local debug APK

You can have two different copies of Stella Fit:

| Install | How you got it | Signed with | What it proves |
|---------|----------------|-------------|----------------|
| **Play testing link** | Opt-in → Play Store install/update | Play **App signing** key | Real-user Sign-In |
| **Local / emulator** | Xcode, Skip, `adb install` | **Debug** or **upload** key | Only local Sign-In |

Google Sign-In checks the **certificate of the installed APK**.  
A debug build can succeed even when Play fails. That’s why we said: test on the **Play** copy.

### How to test the Play copy

1. On the Fold (or any real device), sign in with a Google account that’s in `stella-fit@googlegroups.com` (and listed as an OAuth **Test user** if the consent screen is in Testing)
2. Open the **join test / opt-in** link from Play Console
3. Become a tester if you haven’t already
4. Install or update from Play Store
5. Confirm you’re not opening an old sideloaded icon (uninstall extra Stella Fit / RestFit copies if you have both)
6. Tap **Sign in with Google**

If it fails, note the **exact on-screen error** (or screenshot the text).

---

## Related

- [`PLAY_APP_SIGNING_SHA1.md`](./PLAY_APP_SIGNING_SHA1.md) — why Play SHA-1 is required  
- [`GOOGLE_SIGNIN_SETUP.md`](./GOOGLE_SIGNIN_SETUP.md) — Web vs Android clients  
