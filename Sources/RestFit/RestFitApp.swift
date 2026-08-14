import Foundation
import OSLog
import SwiftUI
import SkipFirebaseCore

/// A logger for the RestFit module.
let logger: Logger = Logger(subsystem: "com.restfit.app", category: "RestFit")

/// The shared top-level view for the app, loaded from the platform-specific App delegates below.
///
/// The default implementation merely loads the `ContentView` for the app and logs a message.
public struct RestFitRootView : View {
    public init() {
    }

    public var body: some View {
        ContentView()
            .task {
                logger.info("Skip app logs are viewable in the Xcode console for iOS; Android logs can be viewed in Studio or using adb logcat")
            }
    }
}

/// Global application delegate functions.
///
/// These functions can update a shared observable object to communicate app state changes to interested views.
public final class RestFitAppDelegate : Sendable {
    public static let shared = RestFitAppDelegate()

    private init() {
    }

    public func onInit() {
        logger.debug("onInit")
        #if SKIP
        FirebaseAuthService.configureIfNeeded()
        #endif
    }

    public func onLaunch() {
        logger.debug("onLaunch")
    }

    public func onResume() {
        logger.debug("onResume")
    }

    public func onPause() {
        logger.debug("onPause")
    }

    public func onStop() {
        logger.debug("onStop")
    }

    public func onDestroy() {
        logger.debug("onDestroy")
    }

    public func onLowMemory() {
        logger.debug("onLowMemory")
    }
}
