import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(RestFitLegal.shortDisclaimer)
                        .font(.caption)
                        .foregroundStyle(RestFitTheme.coral)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RestFitTheme.coral.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    Text(RestFitLegal.privacyPolicyMarkdown)
                        .font(.body)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let url = URL(string: RestFitLegal.privacyPolicyURL) {
                        Link("Open web version", destination: url)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RestFitTheme.mint)
                    }
                }
                .padding(24)
                .padding(.bottom, 40)
            }
            .background(RestFitTheme.canvas.ignoresSafeArea())
            .navigationTitle("Privacy Policy")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
