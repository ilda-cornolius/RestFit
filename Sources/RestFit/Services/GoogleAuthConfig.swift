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

    /// Play App signing SHA-1 (Play Store / closed testing installs). From Play Console → App integrity.
    /// Must match Firebase + Google Cloud Android OAuth client for package `com.restfit.app`.
    static let playStoreSha1 = "CF:50:E6:E5:17:F3:0F:A3:B8:1E:CB:B1:23:91:77:2F:69:7A:39:57"

    static let playStoreSignInHint =
        "Play Store installs use a different signing key than debug builds. In Play Console → App integrity, copy the App signing SHA-1 and add it in Firebase (Project settings → Android app → fingerprints) and Google Cloud (Credentials → Android OAuth client). Expected SHA-1: \(playStoreSha1)."

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
