import SwiftUI

/// A rounded container that adopts the iOS 26 Liquid Glass material.
struct GlassCard<Content: View>: View {
    var tint: Color? = nil
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(
                tint.map { Glass.regular.tint($0.opacity(0.18)) } ?? Glass.regular,
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
