import Foundation
import SwiftUI

enum GoogleAuthError: LocalizedError {
    case notConfigured
    case cancelled
    case failed(String)
    case unsupportedPlatform

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
        let context = ProcessInfo.processInfo.androidContext
        let credentialManager = androidx.credentials.CredentialManager.create(context)

        let googleIdOption = com.google.android.libraries.identity.googleid.GetGoogleIdOption.Builder()
            .setFilterByAuthorizedAccounts(false)
            .setServerClientId(GoogleAuthConfig.webClientID)
            .setAutoSelectEnabled(false)
            .build()

        let request = androidx.credentials.GetCredentialRequest.Builder()
            .addCredentialOption(googleIdOption)
            .build()

        do {
            let result = try await credentialManager.getCredential(
                context: context,
                request: request
            )
            let credential = result.credential
            let googleId = com.google.android.libraries.identity.googleid.GoogleIdTokenCredential.createFrom(credential.data)
            let id = googleId.id.isEmpty ? UUID().uuidString : googleId.id
            let email = googleId.id
            let displayName = googleId.displayName ?? email
            return AuthUser(id: id, email: email, displayName: displayName)
        } catch let error as androidx.credentials.exceptions.GetCredentialCancellationException {
            throw GoogleAuthError.cancelled
        } catch {
            throw GoogleAuthError.failed(String(describing: error))
        }
    }
    #endif
}
