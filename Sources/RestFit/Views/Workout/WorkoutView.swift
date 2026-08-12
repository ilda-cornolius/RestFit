import SwiftUI

struct WorkoutView: View {
    var onProfile: () -> Void = {}

    var body: some View {
        StrengthPlanView(onProfile: onProfile)
    }
}
