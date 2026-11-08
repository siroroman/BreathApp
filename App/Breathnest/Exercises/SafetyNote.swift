import SwiftUI

/// The Safety note of the detail sheet: shown with every Exercise, non-blocking, no acknowledgement. It sits
/// between the result line and the Haptics group, so it comes before Start in the reading order. Its text is in
/// `Safety.xcstrings`, English only until the reviewed translations exist (#34). The look is the proposal of
/// phone-design.md (Not in the design, point 1): `surface`, radius 16, `fg2` text at 15.
struct SafetyNote: View {
    let showsHoldLine: Bool

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let scale = DesignScale(typeSize: typeSize)
        VStack(alignment: .leading, spacing: scale(8, 16)) {
            Text("safety.dizzy", tableName: "Safety")
            Text("safety.doctor", tableName: "Safety")
            Text("safety.places", tableName: "Safety")
            if showsHoldLine {
                Text("safety.hold", tableName: "Safety")
            }
            Text("safety.notAdvice", tableName: "Safety")
        }
        .designFont(15, ax5: 34, lineHeight: 1.4)
        .foregroundStyle(Color(.fg2))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, scale(14, 22))
        .background(Color(.surface))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("detail.safetyNote")
    }
}
