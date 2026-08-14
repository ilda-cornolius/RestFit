import Foundation
import SkipFirebaseAuth
import SkipFirebaseCore

enum FirebaseAuthError: LocalizedError {
    case invalidEmail
    case weakPassword
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Enter a valid email address."
        case .weakPassword:
            return "Password must be at least 6 characters."
        case .failed(let message):
            return message
        }
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
            throw FirebaseAuthError.failed(error.localizedDescription)
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
            throw FirebaseAuthError.failed(error.localizedDescription)
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
