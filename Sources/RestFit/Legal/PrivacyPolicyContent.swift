import Foundation

enum RestFitLegal {
    /// User-facing app name (launcher / login / store listing).
    static let appDisplayName = "Stella Fit"

    /// Public privacy policy URL for Play Console / App Store (GitHub Pages).
    static let privacyPolicyURL = "https://ilda-cornolius.github.io/RestFit/privacy/"

    /// Public account deletion instructions (required by Google Play when accounts are supported).
    static let deleteAccountURL = "https://ilda-cornolius.github.io/RestFit/delete-account/"

    /// Public data deletion instructions (without deleting the account).
    static let deleteDataURL = "https://ilda-cornolius.github.io/RestFit/delete-data/"

    static let appVersionLabel = "1.0.0"

    static let shortDisclaimer =
        "Stella Fit is a personal wellness tracker. It is not a medical device and does not provide medical advice, diagnosis, or treatment."

    static let privacyPolicyMarkdown: String = """
    # Privacy Policy for Stella Fit

    **Last updated:** August 15, 2026

    Stella Fit (“the App”) helps you track personal wellness habits such as intermittent fasting, sleep, weight, workouts, and reminders.

    ## Summary
    - Stella Fit stores wellness logs **on your device**.
    - Account sign-in uses **email/password (Firebase Authentication)** and/or **Google Sign-In**.
    - We do **not** operate a separate Stella Fit server that stores your fasting, sleep, weight, or workout logs.
    - The App is **not** a medical device and does **not** diagnose, treat, cure, or prevent any disease.

    ## Information the App stores on your device
    Depending on how you use Stella Fit, the App may store locally:
    - Profile details you enter (such as name and target weight)
    - Fasting sessions and protocol preferences
    - Sleep and weight entries you log
    - Workout plans, exercise notes, and session history
    - Alarm and reminder preferences
    - App settings (for example unit preferences)

    This information stays on your device unless you choose to share it through your device’s own sharing or backup features.

    ## Account information sent off your device
    When you create or sign in to an account:
    - **Email/password:** your email and password are sent to **Firebase Authentication** (Google) to create and verify your account.
    - **Google Sign-In:** Google provides your account email / ID so you can sign in.
    Stella Fit does not use this to upload your wellness logs to a Stella Fit backend.

    ## Health-related data
    Stella Fit may process health-related information that you enter (for example sleep duration/quality or body weight) to show progress and tips inside the App.

    On Apple platforms, if you choose to import data from Apple Health, that import happens only after you grant permission in the system Health permission sheet. Stella Fit does not force Health access.

    ## Notifications
    If you enable reminders, the App may schedule local notifications on your device (for example fasting or morning workout nudges). You can turn reminders off in Profile or system settings.

    ## Internet access
    The Android build may request internet permission for sign-in and platform/runtime needs. Stella Fit does not use that access to upload your wellness logs to a Stella Fit backend.

    ## Data sharing
    Stella Fit does not sell your personal information.
    Stella Fit does not share your on-device wellness logs with advertisers or data brokers.

    ## Data retention and deletion
    - **On-device wellness data:** remains until you clear it in the App (**Profile → Clear on-device data**), clear app storage, or uninstall. You can clear this data **without** deleting your account. Steps: https://ilda-cornolius.github.io/RestFit/delete-data/
    - **Account deletion:** use **Profile → Delete account** in the App, or follow https://ilda-cornolius.github.io/RestFit/delete-account/
    - Deleting your account removes your Stella Fit Firebase Authentication account when one exists (email/password), signs you out, and clears on-device Stella Fit data on that device. We process in-app deletion promptly (typically immediately when the request succeeds). We do not keep a separate Stella Fit copy of your wellness logs on our servers.
    - If you signed in with Google, you may also revoke Stella Fit access in your Google Account settings.

    ## Children’s privacy
    Stella Fit is intended for adults. It is not directed to children under 13.

    ## Medical disclaimer
    Stella Fit provides general wellness tracking and informational tips only. It is not medical advice. Always consult a qualified health professional for medical questions, fasting decisions if you have a medical condition, or before making significant changes to diet, sleep, or exercise.

    ## Changes to this policy
    We may update this Privacy Policy when the App changes. The “Last updated” date at the top will change when we do.

    ## Contact
    Questions about privacy: open an issue on the Stella Fit GitHub repository at https://github.com/ilda-cornolius/RestFit
    """
}
