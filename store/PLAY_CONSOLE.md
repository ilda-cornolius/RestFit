# RestFit Play Console checklist

Use this while filling out Google Play Console. Package name: `com.restfit.app`

## App access (Play Console)

RestFit requires sign-in (email/password via Firebase, or Google).

- **Is any part of your app restricted?** → **Yes**
- Easiest for reviewers: create an email/password test account in the app, then share that email + password
- See `FIREBASE_SETUP.md` and `GOOGLE_SIGNIN_SETUP.md`

## Privacy policy URL


After enabling GitHub Pages (Settings → Pages → Deploy from branch `main` / folder `/docs`):

`https://ilda-cornolius.github.io/RestFit/privacy/`

Also available in-app under **Profile → Privacy Policy**.

## Store listing copy

### App name
RestFit

### Short description (≤ 80 characters)
Track fasting, sleep, weight, and workouts — all on your device.

### Full description
RestFit is a simple wellness companion for everyday habits.

Track intermittent fasting with a clear timer and common protocols (16:8, 18:6, 20:4). Log sleep and weight, plan Rest / Cardio / Workout days, and set wake or reminder alarms. Personalized tips are based on what you track in the app — not medical diagnosis.

Everything stays on your device. No RestFit account required.

RestFit is for general wellness tracking only. It is not a medical device and does not provide medical advice, diagnosis, or treatment.

### What’s new (1.0.0)
First Play Store release: fasting timer, sleep and weight logging, weekly workout planning, alarms, and on-device privacy.

## Assets in this folder

- `listing/icon-512.png` — high-res icon (512×512)
- `listing/feature-graphic.png` — feature graphic (1024×500)
- Screenshots: capture 2–8 phone screenshots from the emulator (Home, Fast, Sleep, Workout, Profile)

## Data safety (suggested answers)

Assumes current RestFit behavior: on-device storage, no RestFit backend, no ads SDK, no analytics SDK.

| Question | Suggested answer |
|----------|------------------|
| Does your app collect or share user data? | **Yes** (collected on device / processed in-app) — declare categories below |
| Is all user data encrypted in transit? | **No** user data is sent to RestFit servers. If asked and no network transmission of user data: mark that data is not collected for transfer, or follow Play’s current wording for “not collected” vs on-device only carefully |
| Do you provide a way for users to request deletion? | Users can clear app data / uninstall. Document that in the form |
| Health and fitness | **Collected**: yes (sleep, weight, fasting/workout-related entries you log) — purpose: App functionality |
| Personal info (name) | **Collected**: optional name you enter — purpose: App functionality |
| Shared with third parties? | **No** |
| Sold? | **No** |
| Used for ads / fraud / personalization beyond app features? | **No** |
| Ephemeral? | No (persisted on device until deleted/uninstall) |

Be consistent with the live Privacy Policy. If Play’s form distinguishes “collected” as “transmitted off device,” choose the option that matches **on-device only / not transmitted to developer**.

## Content rating (IARC questionnaire tips)

Answer honestly. Typical for RestFit:

- No violence, sexual content, or hate
- No user-to-user chat / social
- No location sharing
- Mild health/wellness themes only (tracking habits)
- Not primarily for children → target age **18+** or **Teen** depending on questionnaire options; RestFit is intended for adults

Expected outcome is usually a low maturity rating (Everyone / PEGI 3 style), but follow the questionnaire exactly.

## Medical / claims reminder

Do **not** use store text like: cure, treat, diagnose, reverse disease, guaranteed weight loss, clinically proven (unless you have evidence and regulatory clearance).

Safe phrasing: track, log, plan, reminders, tips based on your entries.
