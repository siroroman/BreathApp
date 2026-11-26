import SwiftUI
import UIKit

/// Gives the native Slider the design's colours (screen 6): a 28 pt `ring` thumb, `ring` for the filled track and
/// `outline` for the rest. UIKit exposes no track thickness, so the track keeps the system thickness. The
/// appearance proxy applies to every UISlider in the app, and the Duration slider is the only one.
enum SliderStyle {
    @MainActor private static var isApplied = false

    @MainActor static func apply() {
        guard !isApplied else { return }
        isApplied = true
        let proxy = UISlider.appearance()
        proxy.minimumTrackTintColor = UIColor(resource: .ring)
        proxy.maximumTrackTintColor = UIColor(resource: .outline)
        let thumbSize = CGSize(width: 28, height: 28)
        let thumb = UIGraphicsImageRenderer(size: thumbSize).image { _ in
            UIColor(resource: .ring).setFill()
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: thumbSize)).fill()
        }
        proxy.setThumbImage(thumb, for: .normal)
        proxy.setThumbImage(thumb, for: .highlighted)
    }
}
