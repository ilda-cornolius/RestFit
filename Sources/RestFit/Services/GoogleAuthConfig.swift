import Foundation

/// Fill `webClientID` from Google Cloud Console before Google Sign-In will work.
/// See `store/GOOGLE_SIGNIN_SETUP.md`.
enum GoogleAuthConfig {
    /// OAuth 2.0 **Web application** client ID (used as server client ID for Google ID tokens).
    /// Example: `123456789-abcdef.apps.googleusercontent.com`
    static let webClientID = "611638882841-d6jdj0ecjrhfg35gola6h74tep4psug0.apps.googleusercontent.com"

    static var isConfigured: Bool {
        !webClientID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static let androidPackageName = "com.restfit.app"

    /// Release upload keystore SHA-1 (register this on the Android OAuth client).
    static let releaseSha1 = "16:E9:B1:B4:B4:5D:BB:35:87:8F:21:65:D7:F8:72:FD:19:75:A1:63"

    /// Debug keystore SHA-1 (for emulator / local debug installs).
    static let debugSha1 = "44:73:49:9B:15:C4:A6:B6:7D:35:4A:4B:C3:4E:40:B4:D0:17:E8:8F"

    /// Play App signing SHA-1 (Play Store / closed testing installs). From the cert on a Play-installed APK
    /// (`apksigner verify --print-certs`). Must match Firebase + Google Cloud Android OAuth client.
    /// Note: Play may rotate this key; `CF:50:…` was an older signing cert.
    static let playStoreSha1 = "CF:E4:0A:CE:9F:05:76:81:1B:89:E8:CC:01:D2:C8:B5:14:25:04:FC"

    static let playStoreSignInHint =
        "Play Store installs use a different signing key than debug builds. In Play Console → App integrity, copy the App signing SHA-1 and add it in Firebase (Project settings → Android app → fingerprints) and Google Cloud (Credentials → Android OAuth client). Expected SHA-1: \(playStoreSha1)."

    static let debugSignInHint =
        "Debug / emulator installs use the debug keystore SHA-1, not the Play App signing key. Add SHA-1 \(debugSha1) in Firebase (Project settings → Android app → fingerprints) and create a matching Android OAuth client in Google Cloud → Credentials. Use a Google Play emulator image and sign in to a Google account on the device."

    /// Shown when logcat reports `[16] Account reauth failed` after picking an account.
    static let reauthFailedHint =
        "Google blocked Sign-In after you chose an account (not a cancel). On the emulator, a “Checking info…” spinner often means the device Google account is stale — remove it under Settings → Passwords & accounts, add it again, or cold-boot the AVD. Also verify: (1) Google Cloud Android OAuth client for \(androidPackageName) + debug SHA-1 \(debugSha1); (2) OAuth Data Access scopes openid, email, profile; (3) Firebase Google Web SDK uses \(webClientID) and the current Web client secret."

    static let emulatorAccountHint =
        "The emulator Google account session looks broken (Google logcat: “Long live credential not available”). Settings → Passwords & accounts → remove your Google account → add it again. If that fails, Android Studio → Device Manager → Wipe Data or Cold Boot on this AVD, then sign into Google before trying Stella Fit."

    static func shaConfigHint(isPlayInstall: Bool) -> String {
        isPlayInstall ? playStoreSignInHint : debugSignInHint
    }

    /// Only relevant when OAuth consent publishing status is Testing.
    static let testUserHint =
        "If OAuth consent is still in Testing, add this Gmail under Google Cloud → OAuth consent screen → Test users, wait a few minutes, then try again."

    static let afterAccountPickHint =
        "Google didn’t finish signing in after you chose an account. Update Stella Fit from Play to the latest build, then try again. If it still fails, use Sign in with Email, or confirm OAuth scopes include openid, email, and profile."
}

struct AuthUser: Codable, Hashable {
    var id: String
    var email: String
    var displayName: String
    var photoURL: String? = nil
}
