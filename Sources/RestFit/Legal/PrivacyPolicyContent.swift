import Foundation

enum RestFitLegal {
    /// Public privacy policy URL for Play Console / App Store (GitHub Pages).
    static let privacyPolicyURL = "https://ilda-cornolius.github.io/RestFit/privacy/"

    static let appVersionLabel = "1.0.0"

    static let shortDisclaimer =
        "RestFit is a personal wellness tracker. It is not a medical device and does not provide medical advice, diagnosis, or treatment."

    static let privacyPolicyMarkdown: String = """
    # Privacy Policy for RestFit

    **Last updated:** August 13, 2026

    RestFit (“the App”) helps you track personal wellness habits such as intermittent fasting, sleep, weight, workouts, and reminders.

    ## Summary
    - RestFit stores your data **on your device**.
    - We do **not** operate a RestFit account server that collects your fasting, sleep, weight, or workout logs.
    - The App is **not** a medical device and does **not** diagnose, treat, cure, or prevent any disease.

    ## Information the App stores on your device
    Depending on how you use RestFit, the App may store locally:
    - Profile details you enter (such as name and target weight)
    - Fasting sessions and protocol preferences
    - Sleep and weight entries you log
    - Workout plans, exercise notes, and session history
    - Alarm and reminder preferences
    - App settings (for example unit preferences)

    This information stays on your device unless you choose to share it through your device’s own sharing or backup features.

    ## Health-related data
    RestFit may process health-related information that you enter (for example sleep duration/quality or body weight) to show progress and tips inside the App.

    On Apple platforms, if you choose to import data from Apple Health, that import happens only after you grant permission in the system Health permission sheet. RestFit does not force Health access.

    ## Notifications
    If you enable reminders, the App may schedule local notifications on your device (for example fasting or morning workout nudges). You can turn reminders off in Profile or system settings.

    ## Internet access
    The Android build may request internet permission for platform/runtime needs. RestFit does not use that access to upload your wellness logs to a RestFit backend.

    ## Data sharing
    RestFit does not sell your personal information.
    RestFit does not share your on-device wellness logs with advertisers or data brokers.

    ## Data retention and deletion
    Your data remains on your device until you clear app storage, uninstall the App, or delete entries inside the App (where available). Uninstalling removes the App’s local data, subject to your device’s backup behavior.

    ## Children’s privacy
    RestFit is intended for adults. It is not directed to children under 13.

    ## Medical disclaimer
    RestFit provides general wellness tracking and informational tips only. It is not medical advice. Always consult a qualified health professional for medical questions, fasting decisions if you have a medical condition, or before making significant changes to diet, sleep, or exercise.

    ## Changes to this policy
    We may update this Privacy Policy when the App changes. The “Last updated” date at the top will change when we do.

    ## Contact
    Questions about privacy: open an issue on the RestFit GitHub repository at https://github.com/ilda-cornolius/RestFit
    """
}
