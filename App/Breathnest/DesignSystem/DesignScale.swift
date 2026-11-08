import SwiftUI

/// The design draws every size at the default text size and at AX5 (phone-design.md, rule 8). A layout size at a
/// step in between is interpolated linearly by the step, so spacing and tap targets grow with the text and never
/// jump. Text itself follows the system's curve, see `designFont`.
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

/// Text in a text style, so it follows Dynamic Type the way the system does. The design draws its own sizes at AX5
/// (body 44, where iOS has 53), but the accessibility audit accepts only text styles, so the text takes the
/// style whose default size is nearest to the design's and scales on the system's curve. `designSize` is the
/// size drawn at the default text size, in points; it sets the letter spacing and the line height.
private struct DesignFont: ViewModifier {
    let style: Font.TextStyle
    let designSize: CGFloat
    let weight: Font.Weight
    let tracking: CGFloat
    let lineHeight: CGFloat?

    func body(content: Content) -> some View {
        content
            .font(.system(style, weight: weight))
            .tracking(tracking * designSize)
            .lineSpacing(lineHeight.map { max(0, ($0 - 1.19) * designSize) } ?? 0)
    }
}

extension View {
    /// `tracking` is in em, `lineHeight` a multiple of the size.
    func designFont(
        _ style: Font.TextStyle,
        _ designSize: CGFloat,
        weight: Font.Weight = .regular,
        tracking: CGFloat = 0,
        lineHeight: CGFloat? = nil
    ) -> some View {
        modifier(DesignFont(
            style: style,
            designSize: designSize,
            weight: weight,
            tracking: tracking,
            lineHeight: lineHeight
        ))
    }
}
