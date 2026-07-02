import SwiftUI

/// The "Halo is listening" glyph: symmetric rounded waveform bars, like the system
/// sound-recorder icon. Takes its color from `foregroundStyle` and its size from `frame`;
/// set `animating` to make the bars gently bounce while listening.
struct HaloWaveform: View {
    var animating: Bool = false
    @State private var wave = false

    /// Relative bar heights, tallest in the middle.
    private static let heights: [CGFloat] = [0.30, 0.55, 0.78, 1.0, 0.78, 0.55, 0.30]

    var body: some View {
        GeometryReader { geo in
            let count = CGFloat(Self.heights.count)
            let barWidth = geo.size.width / (count * 2 - 1)
            HStack(alignment: .center, spacing: barWidth) {
                ForEach(Self.heights.indices, id: \.self) { i in
                    Capsule()
                        .frame(
                            width: barWidth,
                            height: max(barWidth, geo.size.height * Self.heights[i])
                        )
                        .scaleEffect(y: wave ? 0.55 : 1, anchor: .center)
                        .animation(
                            animating
                                ? .easeInOut(duration: 0.55)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.1)
                                : .default,
                            value: wave
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear { wave = animating }
        .onChange(of: animating) { _, on in wave = on }
    }
}

#Preview {
    VStack(spacing: 40) {
        HaloWaveform()
            .foregroundStyle(.purple)
            .frame(width: 60, height: 50)
        HaloWaveform(animating: true)
            .foregroundStyle(
                LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
            )
            .frame(width: 60, height: 50)
    }
    .padding(60)
}
