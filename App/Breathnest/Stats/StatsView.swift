import BreathnestKit
import SwiftUI

/// The sections of the second tab. Reminder is built in #59.
enum StatsSection: Hashable {
    case stats, reminder
}

/// Screen 10 of the design: the segmented control, This week and the Log.
struct StatsView: View {
    let viewModel: StatsViewModel
    @State private var section = StatsSection.stats
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let scale = DesignScale(typeSize: typeSize)
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SectionPicker(selection: $section, scale: scale)
                        .padding(.bottom, 24)
                    switch section {
                    case .stats: StatsSectionView(viewModel: viewModel, scale: scale)
                    case .reminder: EmptyView() // The Reminders list arrives with #59.
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, max(0, 64 - proxy.safeAreaInsets.top))
                .padding(.bottom, 24)
            }
        }
        .background(Color(.bg))
    }
}

private struct StatsSectionView: View {
    let viewModel: StatsViewModel
    let scale: DesignScale

    var body: some View {
        let week = viewModel.week
        let now = Date()
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("stats.thisWeek")
                    .designFont(.title2, 22, weight: .bold, lineHeight: 1.2)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 12)
                Text(verbatim: StatsText.total(week.totalMinutes))
                    .designFont(.body, 17, weight: .semibold, lineHeight: 1.2)
                    .monospacedDigit()
                    .foregroundStyle(Color(.fg2))
                    .accessibilityIdentifier("stats.total")
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 10)
            WeekCard(week: week, scale: scale)
                .padding(.bottom, 24)
            Text("stats.log")
                .designFont(.title2, 22, weight: .bold, lineHeight: 1.2)
                .padding(.horizontal, 4)
                .padding(.bottom, 10)
                .accessibilityAddTraits(.isHeader)
            LogList(rows: viewModel.rows, now: now, scale: scale)
        }
    }
}

/// A `surface` pill with two segments. The selected one is `fg` with `bg` text.
private struct SectionPicker: View {
    @Binding var selection: StatsSection
    let scale: DesignScale

    var body: some View {
        HStack(spacing: 4) {
            segment(.stats, "stats.segment.stats", id: "stats")
            segment(.reminder, "stats.segment.reminder", id: "reminder")
        }
        .padding(4)
        .background(Color(.surface), in: Capsule())
    }

    private func segment(_ value: StatsSection, _ title: LocalizedStringKey, id: String) -> some View {
        let isSelected = selection == value
        return Button { selection = value } label: {
            Text(title)
                .designFont(.subheadline, 15, weight: isSelected ? .semibold : .medium)
                .foregroundStyle(Color(isSelected ? .bg : .fg))
                .frame(maxWidth: .infinity, minHeight: scale(40, 84))
                .background(isSelected ? Color(.fg) : .clear, in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("stats.segment.\(id)")
    }
}

/// Seven equal columns: the day letter, a circle and the minutes.
private struct WeekCard: View {
    let week: WeekSummary
    let scale: DesignScale

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(week.days, id: \.date) { day in
                DayColumn(day: day, scale: scale)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(Color(.surface), in: RoundedRectangle(cornerRadius: 20))
        .accessibilityIdentifier("stats.week")
    }
}

private struct DayColumn: View {
    let day: WeekSummary.Day
    let scale: DesignScale

    var body: some View {
        VStack(spacing: 8) {
            Text(verbatim: StatsText.letter(of: day.date, calendar: .autoupdatingCurrent))
                .designFont(.footnote, 13, weight: day.isToday ? .bold : .medium, lineHeight: 1.2)
                .foregroundStyle(Color(day.isToday ? .fg : .fg2))
            DayCircle(state: day.state, isToday: day.isToday)
                .frame(width: scale(38, 44), height: scale(38, 44))
            Text(verbatim: day.state == .upcoming ? "\u{00A0}" : StatsText.dayMinutes(day.minutes))
                .designFont(.footnote, 13, lineHeight: 1.2)
                .monospacedDigit()
                .foregroundStyle(Color(.fg2))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(StatsText.spokenDay(day, calendar: .autoupdatingCurrent))
    }
}

/// A filled `ring` disc with a check for a day with practice, an empty `outline` ring for a past day without, a
/// dashed ring for a future day. Today also has a thin outer `fg` ring.
private struct DayCircle: View {
    let state: WeekSummary.DayState
    let isToday: Bool

    var body: some View {
        Canvas { context, size in
            let unit = size.width / 40
            let center = CGPoint(x: 20 * unit, y: 20 * unit)
            func circle(_ radius: CGFloat) -> Path {
                Path(ellipseIn: CGRect(
                    x: center.x - radius * unit, y: center.y - radius * unit,
                    width: 2 * radius * unit, height: 2 * radius * unit
                ))
            }
            if isToday {
                context.stroke(circle(19), with: .color(Color(.fg)), lineWidth: 1.5 * unit)
            }
            switch state {
            case .practiced:
                context.fill(circle(15), with: .color(Color(.ring)))
                var check = Path()
                check.move(to: CGPoint(x: 13.5 * unit, y: 20.5 * unit))
                check.addLine(to: CGPoint(x: 18 * unit, y: 25 * unit))
                check.addLine(to: CGPoint(x: 26.5 * unit, y: 15.5 * unit))
                context.stroke(
                    check, with: .color(Color(.bg)),
                    style: StrokeStyle(lineWidth: 3 * unit, lineCap: .round, lineJoin: .round)
                )
            case .missed:
                context.stroke(circle(15), with: .color(Color(.outline)), lineWidth: 2.5 * unit)
            case .upcoming:
                context.stroke(
                    circle(15), with: .color(Color(.outline)),
                    style: StrokeStyle(lineWidth: 2 * unit, lineCap: .round, dash: [3 * unit, 4 * unit])
                )
            }
        }
        .accessibilityHidden(true)
    }
}

private struct LogList: View {
    let rows: [LogEntry]
    let now: Date
    let scale: DesignScale

    var body: some View {
        VStack(spacing: 0) {
            if rows.isEmpty {
                Text("stats.log.empty")
                    .designFont(.subheadline, 15, lineHeight: 1.25)
                    .foregroundStyle(Color(.fg2))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, scale(14, 22))
                    .padding(.horizontal, 16)
                    .accessibilityIdentifier("stats.log.empty")
            }
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, entry in
                if index > 0 { Rectangle().fill(Color(.line)).frame(height: 1) }
                LogRow(entry: entry, now: now, scale: scale)
            }
        }
        .background(Color(.surface), in: RoundedRectangle(cornerRadius: 20))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

private struct LogRow: View {
    let entry: LogEntry
    let now: Date
    let scale: DesignScale

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: StatsText.name(of: entry))
                    .designFont(.body, 17, weight: .semibold, lineHeight: 1.25)
                Text(verbatim: StatsText.when(entry.finishedAt, now: now, calendar: .autoupdatingCurrent))
                    .designFont(.subheadline, 15, lineHeight: 1.25)
                    .foregroundStyle(Color(.fg2))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(verbatim: StatsText.length(of: entry))
                .designFont(.body, 17, weight: .semibold, lineHeight: 1.25)
                .monospacedDigit()
        }
        .foregroundStyle(Color(.fg))
        .padding(.vertical, scale(14, 22))
        .padding(.horizontal, 16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(StatsText.spokenRow(entry, now: now, calendar: .autoupdatingCurrent))
        .accessibilityIdentifier("stats.log.row")
    }
}
