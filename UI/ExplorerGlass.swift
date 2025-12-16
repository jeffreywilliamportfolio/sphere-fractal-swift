import SwiftUI

struct GlassPanel<Content: View>: View {
    @Environment(\.explorerAppearance) private var appearance

    private let padding: CGFloat
    private let content: () -> Content

    init(padding: CGFloat = 10, @ViewBuilder content: @escaping () -> Content) {
        self.padding = padding
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .background { panelBackground }
            .shadow(color: .black.opacity(appearance.shadowOpacity), radius: 16, x: 0, y: 10)
    }

    @ViewBuilder
    private var panelBackground: some View {
        switch appearance.panelShape {
        case .rounded:
            panelBackground(for: RoundedRectangle(cornerRadius: appearance.panelCornerRadius, style: .circular))
        case .squircle:
            panelBackground(for: RoundedRectangle(cornerRadius: appearance.panelCornerRadius, style: .continuous))
        case .capsule:
            panelBackground(for: Capsule(style: .continuous))
        }
    }

    private func panelBackground<S: InsettableShape>(for shape: S) -> some View {
        shape
            .fill(appearance.material.material)
            .overlay {
                shape
                    .fill(appearance.panelTint)
                    .opacity(appearance.glassTintOpacity)
                    .blendMode(.plusLighter)
            }
            .overlay {
                shape
                    .strokeBorder(appearance.panelStroke, lineWidth: 1)
            }
    }
}

struct Keycap: View {
    @Environment(\.explorerAppearance) private var appearance

    private let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold, design: appearance.typography.fontDesign))
            .foregroundStyle(appearance.textPrimary)
            .padding(.vertical, 3)
            .padding(.horizontal, 7)
            .background {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(.thinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .strokeBorder(appearance.panelStroke.opacity(0.55), lineWidth: 1)
                    }
            }
    }
}
