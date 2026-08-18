import SwiftUI
import Foundation

struct WorkoutMonthDay: Identifiable, Hashable {
    let id: String
    let date: Date
    let dayNumber: Int
    let weekday: Weekday
    let inCurrentMonth: Bool
}

enum WorkoutCalendar {
    static func monthTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    static func dayTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }

    static func startOfMonth(_ date: Date) -> Date {
        let calendar = Calendar.current
        let parts = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: parts) ?? date
    }

    static func shiftMonth(_ date: Date, by months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: startOfMonth(date)) ?? date
    }

    static func daysInMonth(_ date: Date) -> Int {
        let calendar = Calendar.current
        let start = startOfMonth(date)
        guard let next = calendar.date(byAdding: .month, value: 1, to: start) else { return 30 }
        let span = calendar.dateComponents([.day], from: start, to: next)
        return max(28, span.day ?? 30)
    }

    static func isSameDay(_ lhs: Date, _ rhs: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.component(.year, from: lhs) == calendar.component(.year, from: rhs)
            && calendar.component(.month, from: lhs) == calendar.component(.month, from: rhs)
            && calendar.component(.day, from: lhs) == calendar.component(.day, from: rhs)
    }

    static func grid(for month: Date, weekStartsOn: Weekday) -> [WorkoutMonthDay] {
        let calendar = Calendar.current
        let start = startOfMonth(month)
        let firstWeekday = calendar.component(.weekday, from: start)
        var leading = firstWeekday - weekStartsOn.rawValue
        if leading < 0 { leading += 7 }

        var days: [WorkoutMonthDay] = []
        if leading > 0 {
            for index in 0..<leading {
                let date = calendar.date(byAdding: .day, value: index - leading, to: start) ?? start
                days.append(makeDay(id: "p-\(index)", date: date, inMonth: false))
            }
        }

        let count = daysInMonth(start)
        for day in 1...count {
            let date = calendar.date(byAdding: .day, value: day - 1, to: start) ?? start
            days.append(makeDay(id: "c-\(day)", date: date, inMonth: true))
        }

        var extra = 0
        while days.count < 42 {
            extra += 1
            let last = days.last?.date ?? start
            let date = calendar.date(byAdding: .day, value: 1, to: last) ?? last
            days.append(makeDay(id: "n-\(extra)", date: date, inMonth: false))
        }
        return days
    }

    private static func makeDay(id: String, date: Date, inMonth: Bool) -> WorkoutMonthDay {
        let calendar = Calendar.current
        let weekday = Weekday(rawValue: calendar.component(.weekday, from: date)) ?? .monday
        return WorkoutMonthDay(
            id: id,
            date: date,
            dayNumber: calendar.component(.day, from: date),
            weekday: weekday,
            inCurrentMonth: inMonth
        )
    }
}

struct AeroWorkoutCalendar: View {
    @Environment(WellnessStore.self) private var store
    @Binding var selectedDay: Weekday
    @Binding var visibleMonth: Date
    var onSelect: (WorkoutMonthDay) -> Void

    private var rowIds: [Int] { [0, 1, 2, 3, 4, 5] }
    private var columnIds: [Int] { [0, 1, 2, 3, 4, 5, 6] }

    var body: some View {
        VStack(alignment: .leading, spacing: 14.0) {
            monthHeader
            weekdayHeader
            monthGrid
            legendRow
                .padding(.top, 4.0)
        }
        .padding(18.0)
        .background(glassFill)
        .clipShape(RoundedRectangle(cornerRadius: 28.0, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28.0, style: .continuous)
                .stroke(glassStroke, lineWidth: 1.2)
        )
        .shadow(color: RestFitTheme.mint.opacity(0.16), radius: 24.0, x: 0.0, y: 8.0)
    }

    private var monthHeader: some View {
        HStack {
            monthNavButton("chevron.left") {
                visibleMonth = WorkoutCalendar.shiftMonth(visibleMonth, by: -1)
            }
            Spacer()
            Text(WorkoutCalendar.monthTitle(visibleMonth))
                .font(RestFitTheme.manrope(size: 20.0, bold: true))
                .foregroundStyle(.white)
            Spacer()
            monthNavButton("chevron.right") {
                visibleMonth = WorkoutCalendar.shiftMonth(visibleMonth, by: 1)
            }
        }
    }

    private var weekdayHeader: some View {
        HStack(spacing: 4.0) {
            ForEach(store.weekDayOrder) { day in
                Text(day.shortTitle)
                    .font(.system(size: 11.0, weight: .bold))
                    .foregroundStyle(RestFitTheme.muted)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var monthGrid: some View {
        VStack(spacing: 6.0) {
            ForEach(rowIds, id: \.self) { row in
                HStack(spacing: 6.0) {
                    ForEach(columnIds, id: \.self) { column in
                        calendarCell(row: row, column: column)
                    }
                }
            }
        }
    }

    private var legendRow: some View {
        HStack(spacing: 12.0) {
            legendDot(RestFitTheme.mint, "Workout")
            legendDot(RestFitTheme.coral, "Cardio")
            legendDot(RestFitTheme.faint, "Rest")
        }
    }

    private func calendarCell(row: Int, column: Int) -> some View {
        let days = WorkoutCalendar.grid(for: visibleMonth, weekStartsOn: store.workoutSettings.weekStartsOn)
        let index = row * 7 + column
        return dayCell(days[index])
    }

    private func dayCell(_ day: WorkoutMonthDay) -> some View {
        Button {
            if day.inCurrentMonth {
                onSelect(day)
            }
        } label: {
            VStack(spacing: 4.0) {
                Text("\(day.dayNumber)")
                    .font(.system(size: 13.0, weight: isSelected(day) ? .bold : .semibold))
                    .foregroundStyle(day.inCurrentMonth ? Color.white : Color.white.opacity(0.28))
                Circle()
                    .fill(dayMark(day))
                    .frame(width: 6.0, height: 6.0)
                    .opacity(day.inCurrentMonth ? 1.0 : 0.25)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52.0)
            .background(cellFill(day))
            .overlay(
                RoundedRectangle(cornerRadius: 12.0, style: .continuous)
                    .stroke(cellStroke(day), lineWidth: isToday(day) ? 1.4 : 1.0)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12.0, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func isSelected(_ day: WorkoutMonthDay) -> Bool {
        selectedDay == day.weekday && day.inCurrentMonth
    }

    private func isToday(_ day: WorkoutMonthDay) -> Bool {
        WorkoutCalendar.isSameDay(day.date, Date())
    }

    private func dayMark(_ day: WorkoutMonthDay) -> Color {
        let display = store.workoutDisplay(for: day.date)
        if display.isCardio { return RestFitTheme.coral }
        if display.isOff { return RestFitTheme.faint }
        return RestFitTheme.mint
    }

    private func cellFill(_ day: WorkoutMonthDay) -> Color {
        if isSelected(day) { return RestFitTheme.mint.opacity(0.22) }
        return Color.white.opacity(day.inCurrentMonth ? 0.07 : 0.03)
    }

    private func cellStroke(_ day: WorkoutMonthDay) -> Color {
        if isToday(day) { return RestFitTheme.mint.opacity(0.9) }
        return Color.white.opacity(isSelected(day) ? 0.28 : 0.08)
    }

    private func monthNavButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 36.0, height: 36.0)
                .background(Color.white.opacity(0.08))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private func legendDot(_ color: Color, _ title: String) -> some View {
        HStack(spacing: 6.0) {
            Circle().fill(color).frame(width: 7.0, height: 7.0)
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(RestFitTheme.muted)
        }
    }

    private var glassFill: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.16),
                RestFitTheme.surface.opacity(0.72),
                RestFitTheme.mint.opacity(0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var glassStroke: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.5),
                RestFitTheme.mint.opacity(0.38),
                Color.white.opacity(0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
