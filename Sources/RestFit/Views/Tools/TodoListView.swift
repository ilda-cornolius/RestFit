import SwiftUI

/// Past feature (not shown in the current UI). See `PastFeatures`.
struct TodoListView: View {
    @Environment(WellnessStore.self) private var store
    let onBack: () -> Void
    @State private var newTitle = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                BackHeader(title: "To-Do", action: onBack)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(store.todoSummaryLabel)
                            .font(.caption)
                            .foregroundStyle(RestFitTheme.muted)
                        Text("Today's tasks")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    if store.todoItems.contains(where: { $0.isDone }) {
                        Button("Clear done") {
                            store.clearCompletedTodos()
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RestFitTheme.mint)
                    }
                }
                .padding(.horizontal, 24)

                HStack(spacing: 10) {
                    TextField("Add a task", text: $newTitle)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(RestFitTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(RestFitTheme.line, lineWidth: 1)
                        )
                        .foregroundStyle(.white)

                    Button {
                        store.addTodo(title: newTitle)
                        newTitle = ""
                    } label: {
                        Image(systemName: "plus")
                            .font(.body.weight(.bold))
                            .foregroundStyle(RestFitTheme.canvas)
                            .frame(width: 44, height: 44)
                            .background(RestFitTheme.mint)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)

                if store.todoItems.isEmpty {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nothing on the list")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.white)
                            Text("Add fasting, sleep, or daily habits you want to finish today.")
                                .font(.caption)
                                .foregroundStyle(RestFitTheme.muted)
                        }
                    }
                    .padding(.horizontal, 24)
                } else {
                    VStack(spacing: 10) {
                        ForEach(openItems) { item in
                            todoRow(item)
                        }
                        ForEach(doneItems) { item in
                            todoRow(item)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, AppLayout.scrollTailPadding)
        }
    }

    private var openItems: [TodoItem] {
        store.todoItems.filter { !$0.isDone }
    }

    private var doneItems: [TodoItem] {
        store.todoItems.filter { $0.isDone }
    }

    private func todoRow(_ item: TodoItem) -> some View {
        HStack(spacing: 12) {
            Button {
                store.toggleTodo(item)
            } label: {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isDone ? RestFitTheme.mint : RestFitTheme.faint)
            }
            .buttonStyle(.plain)

            Text(item.title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(item.isDone ? RestFitTheme.faint : .white)
                .strikethrough(item.isDone)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                store.deleteTodo(item)
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(RestFitTheme.coral.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(RestFitTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(RestFitTheme.line, lineWidth: 1)
        )
    }
}
