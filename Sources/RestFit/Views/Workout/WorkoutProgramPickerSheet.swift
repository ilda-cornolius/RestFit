import SwiftUI

/// Lets the user pick a curated strength program and load it onto the week plan.
struct WorkoutProgramPickerSheet: View {
    var onSelect: (WorkoutProgram) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Popular programs")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)

                    Text("These fill Mon–Sun with days, lifts, sets, and reps. Starting weights are placeholders — adjust them, then add load each session. Matching lift names stay linked across days.")
                        .font(.caption)
                        .foregroundStyle(RestFitTheme.muted)

                    ForEach(WorkoutProgramCatalog.all) { program in
                        Button {
                            onSelect(program)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(program.name)
                                    .font(.body.weight(.bold))
                                    .foregroundStyle(.white)
                                Text(program.summary)
                                    .font(.caption)
                                    .foregroundStyle(RestFitTheme.muted)
                                    .multilineTextAlignment(.leading)
                                Text(program.schedule)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(RestFitTheme.mint)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(RestFitTheme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }

                    Text("Programs are built into Stella Fit from well-known public routines (not downloaded live). Always train with good form and rest between heavy sets.")
                        .font(.caption2)
                        .foregroundStyle(RestFitTheme.faint)
                        .padding(.top, 4)
                }
                .padding(24)
                .padding(.bottom, 40)
            }
            .background(RestFitTheme.canvas.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}
