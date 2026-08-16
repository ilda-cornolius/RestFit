import Foundation
import SkipFirebaseAuth
import SkipFirebaseCore

enum FirebaseAuthError: LocalizedError {
    case invalidEmail
    case weakPassword
    case unrecognizedCredentials
    case emailAlreadyInUse
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Enter a valid email address."
        case .weakPassword:
            return "Password must be at least 6 characters."
        case .unrecognizedCredentials:
            return "Email or password not recognized. Try again."
        case .emailAlreadyInUse:
            return "An account with this email already exists. Sign in instead."
        case .failed(let message):
            return message
        }
    }

    static func userFacingMessage(from error: Error) -> String {
        if let authError = error as? FirebaseAuthError {
            return authError.errorDescription ?? "Something went wrong. Try again."
        }
        let text = "\(error)".lowercased()
        if looksLikeBadCredentials(text) {
            return unrecognizedCredentials.errorDescription!
        }
        if text.contains("email") && (text.contains("already") || text.contains("in use") || text.contains("exists")) {
            return emailAlreadyInUse.errorDescription!
        }
        return "Something went wrong. Try again."
    }

    fileprivate static func looksLikeBadCredentials(_ text: String) -> Bool {
        text.contains("wrong password")
            || text.contains("user-not-found")
            || text.contains("user_not_found")
            || text.contains("invalid-credential")
            || text.contains("invalid_credential")
            || text.contains("invalid-login")
            || text.contains("invalid_login")
            || text.contains("no user record")
            || text.contains("password is invalid")
            || text.contains("malformed")
            || text.contains("expired")
            || text.contains("credential is incorrect")
            || text.contains("auth credential")
    }
}

enum FirebaseAuthService {
    static func configureIfNeeded() {
        #if SKIP
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        #endif
    }

    static func restoreSession() -> AuthUser? {
        #if SKIP
        guard let user = Auth.auth().currentUser else { return nil }
        return authUser(from: user)
        #else
        return nil
        #endif
    }

    static func signIn(email: String, password: String) async throws -> AuthUser {
        let email = normalizedEmail(email)
        let password = password.trimmingCharacters(in: .whitespacesAndNewlines)
        try validate(email: email, password: password)
        #if SKIP
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            return authUser(from: result.user)
        } catch {
            throw mapSignInError(error)
        }
        #else
        throw FirebaseAuthError.failed("Email sign-in is available in the Android build.")
        #endif
    }

    static func register(email: String, password: String) async throws -> AuthUser {
        let email = normalizedEmail(email)
        let password = password.trimmingCharacters(in: .whitespacesAndNewlines)
        try validate(email: email, password: password)
        #if SKIP
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            return authUser(from: result.user)
        } catch {
            throw mapRegisterError(error)
        }
        #else
        throw FirebaseAuthError.failed("Email registration is available in the Android build.")
        #endif
    }

    static func signOut() {
        #if SKIP
        try? Auth.auth().signOut()
        #endif
    }

    /// Deletes the Firebase Auth user when one exists (email/password).
    /// Google-only local sessions have no Firebase user — callers still clear local auth/data.
    static func deleteAccount() async throws {
        #if SKIP
        guard let user = Auth.auth().currentUser else { return }
        do {
            try await user.delete()
        } catch {
            throw FirebaseAuthError.failed(error.localizedDescription)
        }
        #endif
    }

    #if SKIP
    private static func authUser(from user: User) -> AuthUser {
        let email = user.email ?? ""
        let name = user.displayName ?? email
        return AuthUser(
            id: user.uid,
            email: email,
            displayName: name.isEmpty ? "RestFit user" : name
        )
    }
    #endif

    private static func mapSignInError(_ error: Error) -> FirebaseAuthError {
        let text = authErrorText(error)
        #if SKIP
        android.util.Log.e("RestFitAuth", "signIn failed: \(text)")
        #endif
        return .unrecognizedCredentials
    }

    private static func mapRegisterError(_ error: Error) -> FirebaseAuthError {
        let text = authErrorText(error)
        #if SKIP
        android.util.Log.e("RestFitAuth", "register failed: \(text)")
        #endif

        if text.contains("email-already-in-use")
            || text.contains("email_already_in_use")
            || text.contains("email already in use")
            || (text.contains("email") && (text.contains("already") || text.contains("exists"))) {
            return .emailAlreadyInUse
        }
        if text.contains("weak-password")
            || text.contains("weak_password")
            || text.contains("password should be at least") {
            return .weakPassword
        }
        if text.contains("invalid-email") || text.contains("invalid_email") {
            return .invalidEmail
        }
        if text.contains("operation-not-allowed")
            || text.contains("operation_not_allowed")
            || text.contains("operation is not allowed") {
            return .failed("Email/password sign-up isn’t enabled in Firebase yet. Enable Email/Password under Authentication → Sign-in method.")
        }
        if text.contains("network") || text.contains("unable to resolve") || text.contains("timeout") {
            return .failed("Network error. Check your connection and try again.")
        }
        if text.contains("too-many-requests") || text.contains("too_many_requests") {
            return .failed("Too many attempts. Wait a moment and try again.")
        }
        if text.contains("app-not-authorized") || text.contains("app_not_authorized") || text.contains("api key") {
            return .failed("This Android app isn’t authorized for Firebase Auth. Check google-services.json and the package name.")
        }
        if text.contains("recaptcha") || text.contains("missing-client") || text.contains("captcha") {
            return .failed("Firebase blocked sign-up (verification). In Firebase Console, check Authentication settings / App Check.")
        }

        // Prefer Firebase’s own message when it’s readable; avoid dumping enum type names.
        let readable = readableFirebaseMessage(from: text)
        if let readable {
            return .failed(readable)
        }
        return .failed("Couldn’t create the account. Try again.")
    }

    private static func authErrorText(_ error: Error) -> String {
        #if SKIP
        if let fae = error as? com.google.firebase.auth.FirebaseAuthException {
            return "\(fae.errorCode) \(fae.localizedMessage ?? "") \(fae.message ?? "") \(error)".lowercased()
        }
        #endif
        return "\(error) \(error.localizedDescription)".lowercased()
    }

    private static func readableFirebaseMessage(from text: String) -> String? {
        // Typical Firebase messages are full sentences; skip Kotlin/Swift type dumps.
        guard text.count > 12,
              text.contains(" "),
              !text.contains("firebaseautherror"),
              !text.contains("exception$") else {
            return nil
        }
        if text.contains("an internal error has occurred") {
            return "Couldn’t create the account (Firebase internal error). Confirm Email/Password is enabled in Firebase Authentication."
        }
        return nil
    }

    private static func normalizedEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func validate(email: String, password: String) throws {
        guard email.contains("@"), email.contains(".") else {
            throw FirebaseAuthError.invalidEmail
        }
        guard password.count >= 6 else {
            throw FirebaseAuthError.weakPassword
        }
    }
}
