import BreathnestKit
import SwiftUI

/// Screen 4 of the design: the Settings menu opened from the gear of the Session. Three rows, Sounds (the chosen
/// sound and a chevron, which swaps the rows for the single-choice list of five), Sound and Haptics. A change
/// is written to the saved settings at once, so the detail and the Quick Start card show it too.
struct SessionMenu: View {
    let settings: AppSettingsStore
    let scale: DesignScale

    @State private var isChoosingSound = false

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Caret()
                .fill(Color(.pop))
                .frame(width: 18, height: 9)
                .padding(.trailing, 14)
                .accessibilityHidden(true)
            Group {
                if isChoosingSound {
                    SoundsList(chosen: settings.settings.soundID, scale: scale) { sound in
                        settings.setSound(sound)
                        isChoosingSound = false
                    }
                } else {
                    rows
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Color(.line), lineWidth: 1))
            .shadow(color: .black.opacity(0.4), radius: 18, y: 8)
        }
        .frame(width: scale.isAccessibility ? nil : 280)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("session.menu")
    }

    private var rows: some View {
        VStack(spacing: 0) {
            soundsRow
            switchRow(
                "detail.sound", id: "session.menu.soundToggle",
                isOn: Binding(get: { settings.settings.isSoundOn }, set: { settings.setSound(isOn: $0) })
            )
            switchRow(
                "detail.haptics", id: "session.menu.hapticsToggle",
                isOn: Binding(get: { settings.settings.isHapticsOn }, set: { settings.setHaptics(isOn: $0) })
            )
        }
        .background(Color(.pop))
    }

    private var soundsRow: some View {
        Button {
            isChoosingSound = true
        } label: {
            HStack(spacing: 8) {
                Text("detail.sounds")
                    .designFont(.body, 17, weight: .medium)
                    .foregroundStyle(Color(.fg))
                Spacer(minLength: 8)
                Text(verbatim: ExerciseText.soundName(settings.settings.soundID))
                    .designFont(.body, 17, weight: .medium)
                    .foregroundStyle(Color(.fg2))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(.fg2))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: scale(48, 92))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("detail.sounds"))
        .accessibilityValue(ExerciseText.soundName(settings.settings.soundID))
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("session.menu.soundsRow")
    }

    private func switchRow(_ title: LocalizedStringKey, id: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(title)
                .designFont(.body, 17, weight: .medium)
                .foregroundStyle(Color(.fg))
        }
        .tint(Color(.ring))
        .padding(.horizontal, 16)
        .frame(minHeight: scale(48, 92))
        .accessibilityIdentifier(id)
    }
}

/// The small triangle that points the menu at the gear.
private struct Caret: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
