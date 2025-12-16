import SwiftUI

struct LiquidBackdrop: View {
    @Environment(\.explorerAppearance) private var appearance

    var animate: Bool = true

    @State private var isAnimating: Bool = false

    private var shouldAnimate: Bool {
        animate && appearance.liquidEnabled && appearance.liquidMotion
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let palettes = appearance.theme.liquidBlobPalettes

            ZStack {
                if appearance.liquidEnabled {
                    liquidBlob(
                        size: size,
                        colors: palettes[safe: 0] ?? [.cyan.opacity(0.75), .blue.opacity(0.35)],
                        base: CGPoint(x: size.width * 0.15, y: size.height * 0.20),
                        travel: CGSize(width: size.width * 0.20, height: size.height * 0.18),
                        phase: 0
                    )

                    liquidBlob(
                        size: size,
                        colors: palettes[safe: 1] ?? [.purple.opacity(0.65), .pink.opacity(0.30)],
                        base: CGPoint(x: size.width * 0.78, y: size.height * 0.25),
                        travel: CGSize(width: size.width * 0.16, height: size.height * 0.22),
                        phase: 1
                    )

                    liquidBlob(
                        size: size,
                        colors: palettes[safe: 2] ?? [.mint.opacity(0.55), .cyan.opacity(0.18)],
                        base: CGPoint(x: size.width * 0.55, y: size.height * 0.78),
                        travel: CGSize(width: size.width * 0.22, height: size.height * 0.16),
                        phase: 2
                    )
                }
            }
            .blur(radius: appearance.liquidBlur)
            .saturation(appearance.liquidSaturation)
            .opacity(appearance.liquidOpacity)
            .background(Color.black.opacity(0.65))
        }
        .onAppear {
            isAnimating = shouldAnimate
        }
        .onChange(of: shouldAnimate) { _, newValue in
            isAnimating = newValue
        }
        .animation(
            shouldAnimate ? .easeInOut(duration: 8).repeatForever(autoreverses: true) : .default,
            value: isAnimating
        )
    }

    @ViewBuilder
    private func liquidBlob(
        size: CGSize,
        colors: [Color],
        base: CGPoint,
        travel: CGSize,
        phase: Double
    ) -> some View {
        let t = isAnimating ? 1.0 : 0.0
        let x = base.x + travel.width * CGFloat(sin((t + phase) * .pi))
        let y = base.y + travel.height * CGFloat(cos((t + phase) * .pi))
        let diameter = max(size.width, size.height) * 0.75

        Circle()
            .fill(
                RadialGradient(
                    colors: colors,
                    center: .center,
                    startRadius: 10,
                    endRadius: diameter * 0.55
                )
            )
            .frame(width: diameter, height: diameter)
            .position(x: x, y: y)
            .blendMode(.plusLighter)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
