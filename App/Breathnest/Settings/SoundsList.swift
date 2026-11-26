import BreathnestKit
import SwiftUI

/// The single-choice list of the five sounds (design screen 7), shared by the detail sheet and the Session menu.
/// The chosen row is `ring` with a check mark, the others `fg`. Nothing plays yet: the sounds are placeholders (#49).
struct SoundsList: View {
    let chosen: SoundID
    let scale: DesignScale
    let onChoose: (SoundID) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(SoundID.allCases, id: \.self) { sound in
                let isChosen = sound == chosen
                Button {
                    onChoose(sound)
                } label: {
                    HStack {
                        Text(verbatim: ExerciseText.soundName(sound))
                            .designFont(.body, 17, weight: .medium)
                        Spacer(minLength: 8)
                        if isChosen {
                            Image(systemName: "checkmark")
                                .font(.system(size: 20, weight: .semibold))
                                .accessibilityHidden(true)
                        }
                    }
                    .foregroundStyle(Color(isChosen ? .ring : .fg))
                    .padding(.horizontal, 16)
                    .frame(minHeight: scale(48, 92))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isChosen ? .isSelected : [])
                .accessibilityIdentifier("sounds.option.\(sound.rawValue)")
            }
        }
        .background(Color(.pop))
    }
}
