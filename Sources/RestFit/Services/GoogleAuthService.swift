import Foundation
import SwiftUI

enum GoogleAuthError: LocalizedError {
    case notConfigured
    case cancelled
    case failed(String)
    case unsupportedPlatform
    case noActivity

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Google Sign-In is not configured yet. Add your Web client ID in GoogleAuthConfig.swift."
        case .cancelled:
            return "Sign-in was cancelled."
        case .failed(let message):
            return message
        case .unsupportedPlatform:
            return "Google Sign-In is available on the Android build. Use the Android app for Play review."
        case .noActivity:
            return "Google Sign-In could not open. Close and reopen the app, then try again."
        }
    }
}

@MainActor
enum GoogleAuthService {
    static func signIn() async throws -> AuthUser {
        guard GoogleAuthConfig.isConfigured else {
            throw GoogleAuthError.notConfigured
        }

        #if SKIP
        return try await signInAndroid()
        #else
        throw GoogleAuthError.unsupportedPlatform
        #endif
    }

    #if SKIP
    private static func signInAndroid() async throws -> AuthUser {
        FirebaseAuthService.configureIfNeeded()

        guard let activity = UIApplication.shared.androidActivity else {
            throw GoogleAuthError.noActivity
        }
        let credentialManager = androidx.credentials.CredentialManager.create(activity)

        // Button tap → Sign in with Google only (avoid a second picker that shows a false "no account" error).
        let signInOption = com.google.android.libraries.identity.googleid.GetSignInWithGoogleOption.Builder(
            GoogleAuthConfig.webClientID
        ).build()

        do {
            return try await requestGoogleUser(
                credentialManager: credentialManager,
                activity: activity,
                option: signInOption
            )
        } catch let error as androidx.credentials.exceptions.GetCredentialCancellationException {
            android.util.Log.w("RestFitAuth", "SignInWithGoogle cancelled: \(error)")
            throw GoogleAuthError.failed(GoogleAuthConfig.afterAccountPickHint)
        } catch {
            if isNoCredential(error) {
                android.util.Log.w("RestFitAuth", "SignInWithGoogle no credential after account UI: \(error)")
                throw GoogleAuthError.failed(GoogleAuthConfig.afterAccountPickHint)
            }
            throw mappedFailure(error)
        }
    }

    private static func requestGoogleUser(
        credentialManager: androidx.credentials.CredentialManager,
        activity: android.app.Activity,
        option: androidx.credentials.CredentialOption
    ) async throws -> AuthUser {
        let request = androidx.credentials.GetCredentialRequest.Builder()
            .addCredentialOption(option)
            .build()
        let result = try await credentialManager.getCredential(
            context: activity,
            request: request
        )

        let googleId: com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
        do {
            googleId = com.google.android.libraries.identity.googleid.GoogleIdTokenCredential.createFrom(
                result.credential.data
            )
        } catch {
            android.util.Log.e("RestFitAuth", "GoogleIdTokenCredential.createFrom failed: \(error)")
            throw GoogleAuthError.failed(
                "Google returned an unexpected sign-in response. Update the app from Play and try again."
            )
        }

        let idToken = googleId.idToken
        guard !idToken.isEmpty else {
            throw GoogleAuthError.failed(
                "Google did not return a sign-in token. \(GoogleAuthConfig.afterAccountPickHint)"
            )
        }

        let given = (googleId.givenName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let full = (googleId.displayName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let emailFromToken = emailFromIdToken(idToken)
        let email = emailFromToken ?? normalizedEmail(googleId.id)
        let displayName = !full.isEmpty ? full : (!given.isEmpty ? given : email)
        let photoURL = googleId.profilePictureUri?.toString()

        do {
            return try await firebaseGoogleSignIn(idToken: idToken)
        } catch {
            android.util.Log.w("RestFitAuth", "Firebase Google sign-in failed, using local session: \(error)")
            if let firebaseError = error as? FirebaseAuthError,
               case .failed(let message) = firebaseError,
               message.contains("isn’t enabled in Firebase") {
                throw GoogleAuthError.failed(message)
            }

            let id = email.isEmpty ? UUID().uuidString : email
            return AuthUser(id: id, email: email, displayName: displayName, photoURL: photoURL)
        }
    }

    private static func firebaseGoogleSignIn(idToken: String) async throws -> AuthUser {
        try await withThrowingTaskGroup(of: AuthUser.self) { group in
            group.addTask {
                try await FirebaseAuthService.signInWithGoogle(idToken: idToken)
            }
            group.addTask {
                try await Task.sleep(for: .seconds(12))
                throw GoogleAuthError.failed("Firebase sign-in timed out")
            }
            guard let user = try await group.next() else {
                throw GoogleAuthError.failed("Google sign-in did not complete.")
            }
            group.cancelAll()
            return user
        }
    }

    private static func normalizedEmail(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.contains("@") {
            return trimmed.lowercased()
        }
        return trimmed
    }

    private static func emailFromIdToken(_ idToken: String) -> String? {
        let parts = idToken.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        var payload = String(parts[1])
        let remainder = payload.count % 4
        if remainder > 0 {
            payload += String(repeating: "=", count: 4 - remainder)
        }
        payload = payload
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        guard let data = Data(base64Encoded: payload),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let email = json["email"] as? String,
              email.contains("@") else {
            return nil
        }
        return email.lowercased()
    }

    private static func isNoCredential(_ error: Error) -> Bool {
        let text = String(describing: error).lowercased()
        return text.contains("nocredential")
            || text.contains("no credential")
            || text.contains("no credentials")
    }

    private static func mappedFailure(_ error: Error) -> GoogleAuthError {
        let text = String(describing: error)
        let lower = text.lowercased()
        android.util.Log.e("RestFitAuth", "Google credential request failed: \(text)")

        if lower.contains("access_denied") || lower.contains("access denied") {
            return .failed(GoogleAuthConfig.testUserHint)
        }
        if lower.contains("sha") || lower.contains("developer_error") || lower.contains("10:") {
            return .failed(GoogleAuthConfig.playStoreSignInHint)
        }
        if lower.contains("network") || lower.contains("unable to resolve") || lower.contains("timeout") {
            return .failed("Network error during Google sign-in. Check your connection and try again.")
        }
        if lower.contains("invalid credential") || lower.contains("invalid_credential") {
            return .failed(
                "Google rejected the sign-in. Confirm Google is enabled in Firebase Authentication and the Web client ID matches your Firebase project."
            )
        }
        return .failed(GoogleAuthConfig.afterAccountPickHint)
    }
    #endif
}
