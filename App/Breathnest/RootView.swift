import SwiftUI

/// The two tabs of the iPhone app: Exercises and Stats (screens 5 and 10 of the design).
enum AppTab: Hashable {
    case exercises, stats
}

/// The tab bar and the screen it selects. The bar is drawn as in the design, not the system's.
struct RootView: View {
    let navigation: AppNavigation
    let dependencies: AppDependencies

    var body: some View {
        Group {
            switch navigation.tab {
            case .exercises: ExercisesView(navigation: navigation, dependencies: dependencies)
            case .stats: StatsView(viewModel: StatsViewModel(log: dependencies.log))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            TabBar(selection: Binding(get: { navigation.tab }, set: { navigation.select($0) }))
        }
    }
}

/// Height 88 (AX5 150), 8 / 16 / 34 padding, a 1 pt `line` border on top. Two equal tabs, the current one in `ring`.
private struct TabBar: View {
    @Binding var selection: AppTab
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let scale = DesignScale(typeSize: typeSize)
        HStack(spacing: 0) {
            item(.exercises, title: "tab.exercises", scale: scale)
            item(.stats, title: "tab.stats", scale: scale)
        }
        .padding(.horizontal, 16)
        // The 34 pt at the bottom is the home indicator's safe area, which the background fills.
        .frame(height: scale(88, 150) - 34)
        .background(Color(.bg).ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { Rectangle().fill(Color(.line)).frame(height: 1) }
    }

    private func item(_ tab: AppTab, title: LocalizedStringKey, scale: DesignScale) -> some View {
        let isCurrent = selection == tab
        return Button { selection = tab } label: {
            VStack(spacing: 2) {
                TabIcon(tab: tab, lineWidth: isCurrent ? 2.4 : 1.8)
                    .frame(width: scale(26, 40), height: scale(26, 40))
                Text(title)
                    .designFont(.caption2, 11, weight: isCurrent ? .bold : .medium)
            }
            .foregroundStyle(Color(isCurrent ? .ring : .fg2))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isCurrent ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("tab.\(tab == .exercises ? "exercises" : "stats")")
    }
}

/// A ring (Exercises) or three bars (Stats), drawn on the 24 point grid of the design.
private struct TabIcon: View {
    let tab: AppTab
    let lineWidth: CGFloat

    var body: some View {
        Canvas { context, size in
            let unit = size.width / 24
            var path = Path()
            switch tab {
            case .exercises:
                path.addEllipse(in: CGRect(x: 3 * unit, y: 3 * unit, width: 18 * unit, height: 18 * unit))
                path.addEllipse(in: CGRect(x: 9.5 * unit, y: 9.5 * unit, width: 5 * unit, height: 5 * unit))
            case .stats:
                for (x, top) in [(5.0, 12.0), (12, 5), (19, 9)] {
                    path.move(to: CGPoint(x: x * unit, y: 20 * unit))
                    path.addLine(to: CGPoint(x: x * unit, y: top * unit))
                }
            }
            context.stroke(
                path, with: .foreground,
                style: StrokeStyle(lineWidth: lineWidth * unit, lineCap: .round, lineJoin: .round)
            )
        }
        .accessibilityHidden(true)
    }
}
