import BreathnestKit
import SwiftUI

/// Screen 4 of the design: the Settings menu, shown as a native popover under the gear of the Session. Three rows,
/// Sounds (the chosen sound and a chevron, which opens the list of five as its own popover, screen 7), Sound and
/// Haptics, divided by a 1 pt `line`. A change is written to the saved settings at once, so the detail and the
/// Quick Start card show it too.
struct SessionMenu: View {
    let settings: AppSettingsStore
    let scale: DesignScale
    /// Goes through the Session, so switching Haptics off also silences the haptic that is playing.
    let setHaptics: (Bool) -> Void

    @State private var isSoundsOpen = false

    var body: some View {
        VStack(spacing: 0) {
            soundsRow
            divider
            switchRow(
                "detail.sound", id: "session.menu.soundToggle",
                isOn: Binding(get: { settings.settings.isSoundOn }, set: { settings.setSound(isOn: $0) })
            )
            divider
            switchRow(
                "detail.haptics", id: "session.menu.hapticsToggle",
                isOn: Binding(get: { settings.settings.isHapticsOn }, set: { setHaptics($0) })
            )
        }
        .frame(width: scale.isAccessibility ? nil : 280)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("session.menu")
    }

    private var divider: some View {
        Rectangle().fill(Color(.line)).frame(height: 1)
    }

    private var soundsRow: some View {
        let tint = Color(isSoundsOpen ? .ring : .fg)
        return Button {
            isSoundsOpen = true
        } label: {
            HStack(spacing: 8) {
                Text("detail.sounds")
                    .designFont(.body, 17, weight: .medium)
                    .foregroundStyle(tint)
                Spacer(minLength: 8)
                Text(verbatim: ExerciseText.soundName(settings.settings.soundID))
                    .designFont(.body, 17, weight: .medium)
                    .foregroundStyle(Color(isSoundsOpen ? .ring : .fg2))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(isSoundsOpen ? .ring : .fg2))
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
        .popover(isPresented: $isSoundsOpen, arrowEdge: .top) {
            SoundsList(chosen: settings.settings.soundID, scale: scale) { sound in
                settings.setSound(sound)
                isSoundsOpen = false
            }
            .frame(width: scale.isAccessibility ? nil : 260)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Color(.line), lineWidth: 1))
            .presentationCompactAdaptation(.popover)
            .presentationBackground(Color(.pop))
        }
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
