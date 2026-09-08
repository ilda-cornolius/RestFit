import SwiftUI

enum AppLayout {
    /// Icon row + labels + top padding, excluding the home-indicator spacer.
    static let tabBarCoreHeight: CGFloat = 48.0

    /// Padding below tab labels based on system navigation (gesture bar vs buttons).
    static func tabBarBottomPadding(homeIndicatorInset: CGFloat) -> CGFloat {
        guard homeIndicatorInset > 0 else { return 6.0 }
        // Gesture navigation (~20–36pt): tuck labels just above the swipe home bar.
        if homeIndicatorInset < 40.0 {
            return max(4.0, homeIndicatorInset - 2.0)
        }
        // Three-button navigation: keep taps clear of the nav buttons.
        return max(8.0, homeIndicatorInset - 8.0)
    }

    static func tabBarHeight(homeIndicatorInset: CGFloat) -> CGFloat {
        tabBarCoreHeight + tabBarBottomPadding(homeIndicatorInset: homeIndicatorInset)
    }

    static let scrollTailPadding: CGFloat = 12.0

    /// Soft crossfade — no slide/scale so tab changes feel transparent.
    static var tabScreenTransition: AnyTransition {
        AnyTransition.opacity
    }

    static var workoutSessionTransition: AnyTransition {
        AnyTransition.opacity
    }

    static let tabSwitchAnimation: Animation = .easeOut(duration: 0.34)

    static let workoutSessionAnimation: Animation = .easeOut(duration: 0.30)

    static var keyboardTransition: AnyTransition {
        AnyTransition.opacity
    }

    static let keyboardAnimation: Animation = .easeOut(duration: 0.28)
}
