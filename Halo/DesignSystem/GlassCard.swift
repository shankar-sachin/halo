import SwiftUI

/// A rounded container that adopts the iOS 26 Liquid Glass material.
struct GlassCard<Content: View>: View {
    var tint: Color? = nil
    /// When `true`, the glass reacts to touch with the interactive Liquid Glass animation —
    /// use it for whole-card tappable rows (e.g. category hub links).
    var interactive: Bool = false
    @ViewBuilder var content: Content

    var body: some View {
        let glass = tint.map { Glass.regular.tint($0.opacity(0.18)) } ?? Glass.regular
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(
                interactive ? glass.interactive() : glass,
                in: .rect(cornerRadius: 22)
            )
    }
}

extension View {
    /// Wraps a view in a tappable interactive glass capsule (used for accents/buttons).
    func glassCapsule(tint: Color? = nil) -> some View {
        self
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .glassEffect(
                (tint.map { Glass.regular.tint($0.opacity(0.25)) } ?? Glass.regular).interactive(),
                in: .capsule
            )
    }
}
