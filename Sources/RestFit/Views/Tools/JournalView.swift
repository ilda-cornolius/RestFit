import SwiftUI

/// Past feature (not shown in the current UI). See `PastFeatures`.
struct JournalView: View {
    @Environment(WellnessStore.self) private var store
    let onBack: () -> Void
    @State private var showComposer = false
    @State private var editingEntry: JournalEntry?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                BackHeader(title: "Journal", action: onBack)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(store.journalEntries.count) entries")
                            .font(.caption)
                            .foregroundStyle(RestFitTheme.muted)
                        Text("How are you feeling?")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    MintButton(title: "New Entry") {
                        editingEntry = nil
                        showComposer = true
                    }
                }
                .padding(.horizontal, 24)

                if store.journalEntries.isEmpty {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Start your journal")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.white)
                            Text("One honest line is enough. Capture mood, meals, energy, or whatever you noticed today.")
                                .font(.caption)
                                .foregroundStyle(RestFitTheme.muted)
                        }
                    }
                    .padding(.horizontal, 24)
                } else {
                    VStack(spacing: 12) {
                        ForEach(store.journalEntries.sorted { $0.date > $1.date }) { entry in
                            Button {
                                editingEntry = entry
                                showComposer = true
                            } label: {
                                journalCard(entry)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, AppLayout.scrollTailPadding)
        }
        .sheet(isPresented: $showComposer) {
            JournalComposerSheet(entry: editingEntry)
                .environment(store)
        }
    }

    private func journalCard(_ entry: JournalEntry) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: entry.mood.icon)
                    .foregroundStyle(moodColor(entry.mood))
                Text(entry.mood.rawValue)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(moodColor(entry.mood))
                Spacer()
                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(RestFitTheme.faint)
            }

            Text(entry.title.isEmpty ? "Untitled" : entry.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)

            Text(entry.preview)
                .font(.caption)
                .foregroundStyle(RestFitTheme.muted)
                .lineLimit(3)
        }
        .padding(16)
        .background(RestFitTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(RestFitTheme.line, lineWidth: 1)
        )
    }

    private func moodColor(_ mood: JournalMood) -> Color {
        switch mood {
        case .great: RestFitTheme.mint
        case .good: RestFitTheme.mint.opacity(0.8)
        case .okay: RestFitTheme.faint
        case .low: RestFitTheme.coral
        }
    }
}

struct JournalComposerSheet: View {
    @Environment(WellnessStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var entry: JournalEntry?
    @State private var title = ""
    @State private var bodyText = ""
    @State private var mood: JournalMood = .good

    var body: some View {
        NavigationStack {
            Form {
                Picker("Mood", selection: $mood) {
                    ForEach(JournalMood.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                TextField("Title", text: $title)
                TextEditor(text: $bodyText)
                    .frame(minHeight: 120)
            }
            .navigationTitle(entry == nil ? "New Entry" : "Edit Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if var existing = entry {
                            existing.title = title
                            existing.body = bodyText
                            existing.mood = mood
                            store.updateJournalEntry(existing)
                        } else {
                            store.addJournalEntry(title: title, body: bodyText, mood: mood)
                        }
                        dismiss()
                    }
                }
                if entry != nil {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Delete", role: .destructive) {
                            if let entry {
                                store.deleteJournalEntry(entry)
                            }
                            dismiss()
                        }
                    }
                }
            }
        }
        .onAppear {
            if let entry {
                title = entry.title
                bodyText = entry.body
                mood = entry.mood
            }
        }
    }
}
