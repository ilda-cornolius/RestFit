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
        // Credential Manager requires an Activity context (not Application).
        guard let activity = UIApplication.shared.androidActivity else {
            throw GoogleAuthError.noActivity
        }
        let credentialManager = androidx.credentials.CredentialManager.create(activity)

        // Bottom-sheet for accounts already used with this app.
        let googleIdOption = com.google.android.libraries.identity.googleid.GetGoogleIdOption.Builder()
            .setFilterByAuthorizedAccounts(false)
            .setServerClientId(GoogleAuthConfig.webClientID)
            .setAutoSelectEnabled(false)
            .build()

        do {
            return try await requestGoogleUser(
                credentialManager: credentialManager,
                activity: activity,
                option: googleIdOption
            )
        } catch let error as androidx.credentials.exceptions.GetCredentialCancellationException {
            throw GoogleAuthError.cancelled
        } catch {
            if !isNoCredential(error) {
                throw mappedFailure(error)
            }
        }

        // No saved credentials → full "Sign in with Google" account picker.
        // This is Google's required fallback when GetGoogleIdOption throws NoCredentialException.
        let signInButtonOption = com.google.android.libraries.identity.googleid.GetSignInWithGoogleOption.Builder(
            GoogleAuthConfig.webClientID
        ).build()

        do {
            return try await requestGoogleUser(
                credentialManager: credentialManager,
                activity: activity,
                option: signInButtonOption
            )
        } catch let error as androidx.credentials.exceptions.GetCredentialCancellationException {
            throw GoogleAuthError.cancelled
        } catch {
            if isNoCredential(error) {
                throw GoogleAuthError.failed(
                    "No Google account is available. On this phone open Settings → Google and add or select an account, then try Sign in with Google again."
                )
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
        let googleId = com.google.android.libraries.identity.googleid.GoogleIdTokenCredential.createFrom(
            result.credential.data
        )
        let email = googleId.id
        let id = email.isEmpty ? UUID().uuidString : email
        let displayName = googleId.displayName ?? email
        return AuthUser(id: id, email: email, displayName: displayName)
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
        if lower.contains("sha") || lower.contains("developer_error") || lower.contains("10:") {
            return .failed(
                "Google Sign-In failed for this Play Store install. Add the Play Console App signing SHA-1 to Firebase and the Android OAuth client."
            )
        }
        return .failed(text)
    }
    #endif
}
