import SwiftUI

/// The design draws every size at the default text size and at AX5 (phone-design.md, rule 8). A size at a step
/// in between is interpolated linearly by the step, so text and layout grow together and never jump.
struct DesignScale {
    let typeSize: DynamicTypeSize

    /// 0 up to the default size, 1 at AX5.
    private var progress: CGFloat {
        let all = DynamicTypeSize.allCases
        guard let index = all.firstIndex(of: typeSize), let base = all.firstIndex(of: .large) else { return 0 }
        return CGFloat(max(0, index - base)) / CGFloat(all.count - 1 - base)
    }

    func callAsFunction(_ regular: CGFloat, _ ax5: CGFloat) -> CGFloat {
        regular + (ax5 - regular) * progress
    }

    /// The design hides the row glyph from the first accessibility size on.
    var isAccessibility: Bool {
        typeSize.isAccessibilitySize
    }
}

private struct DesignFont: ViewModifier {
    @Environment(\.dynamicTypeSize) private var typeSize
    let regular: CGFloat
    let ax5: CGFloat
    let weight: Font.Weight
    let tracking: CGFloat
    let lineHeight: CGFloat?

    func body(content: Content) -> some View {
        let size = DesignScale(typeSize: typeSize)(regular, ax5)
        content
            .font(.system(size: size, weight: weight))
            .tracking(tracking * size)
            .lineSpacing(lineHeight.map { max(0, ($0 - 1.19) * size) } ?? 0)
    }
}

extension View {
    /// The system font at the design's size: `regular` at the default text size, `ax5` at AX5. `tracking` is in em.
    func designFont(
        _ regular: CGFloat,
        ax5: CGFloat,
        weight: Font.Weight = .regular,
        tracking: CGFloat = 0,
        lineHeight: CGFloat? = nil
    ) -> some View {
        modifier(DesignFont(regular: regular, ax5: ax5, weight: weight, tracking: tracking, lineHeight: lineHeight))
    }
}
