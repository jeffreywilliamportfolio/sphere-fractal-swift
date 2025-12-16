import SwiftUI

enum ExplorerThemePreset: String, CaseIterable, Identifiable {
    case aurora
    case midnight
    case ocean
    case sunset
    case rose
    case graphite

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .aurora: "Aurora"
        case .midnight: "Midnight"
        case .ocean: "Ocean"
        case .sunset: "Sunset"
        case .rose: "Rose"
        case .graphite: "Graphite"
        }
    }

    var defaultAccent: Color {
        switch self {
        case .aurora: .mint
        case .midnight: .cyan
        case .ocean: .blue
        case .sunset: .orange
        case .rose: .pink
        case .graphite: .gray
        }
    }

    var liquidBlobPalettes: [[Color]] {
        switch self {
        case .aurora:
            [
                [.cyan.opacity(0.80), .blue.opacity(0.35)],
                [.purple.opacity(0.70), .pink.opacity(0.30)],
                [.mint.opacity(0.55), .cyan.opacity(0.18)],
            ]
        case .midnight:
            [
                [.blue.opacity(0.70), .cyan.opacity(0.25)],
                [.indigo.opacity(0.70), .purple.opacity(0.22)],
                [.cyan.opacity(0.55), .teal.opacity(0.20)],
            ]
        case .ocean:
            [
                [.cyan.opacity(0.75), .teal.opacity(0.30)],
                [.blue.opacity(0.70), .indigo.opacity(0.24)],
                [.mint.opacity(0.55), .blue.opacity(0.18)],
            ]
        case .sunset:
            [
                [.orange.opacity(0.72), .pink.opacity(0.28)],
                [.purple.opacity(0.62), .red.opacity(0.20)],
                [.yellow.opacity(0.55), .orange.opacity(0.18)],
            ]
        case .rose:
            [
                [.pink.opacity(0.72), .purple.opacity(0.26)],
                [.red.opacity(0.60), .pink.opacity(0.20)],
                [.purple.opacity(0.58), .indigo.opacity(0.18)],
            ]
        case .graphite:
            [
                [.white.opacity(0.25), .gray.opacity(0.12)],
                [.gray.opacity(0.22), .black.opacity(0.08)],
                [.white.opacity(0.18), .gray.opacity(0.10)],
            ]
        }
    }

    func panelTintGradient(accent: Color) -> LinearGradient {
        switch self {
        case .aurora, .midnight, .ocean:
            LinearGradient(
                colors: [accent.opacity(0.42), .purple.opacity(0.25), .mint.opacity(0.22)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .sunset:
            LinearGradient(
                colors: [.orange.opacity(0.40), .pink.opacity(0.26), .purple.opacity(0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .rose:
            LinearGradient(
                colors: [.pink.opacity(0.42), .purple.opacity(0.24), .red.opacity(0.16)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .graphite:
            LinearGradient(
                colors: [.white.opacity(0.18), .gray.opacity(0.10), .white.opacity(0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

enum ExplorerAccentOption: String, CaseIterable, Identifiable {
    case system
    case themeDefault
    case cyan
    case blue
    case purple
    case pink
    case red
    case orange
    case yellow
    case green
    case mint

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: "System"
        case .themeDefault: "Theme Default"
        case .cyan: "Cyan"
        case .blue: "Blue"
        case .purple: "Purple"
        case .pink: "Pink"
        case .red: "Red"
        case .orange: "Orange"
        case .yellow: "Yellow"
        case .green: "Green"
        case .mint: "Mint"
        }
    }

    func resolvedColor(theme: ExplorerThemePreset) -> Color {
        switch self {
        case .system:
            .accentColor
        case .themeDefault:
            theme.defaultAccent
        case .cyan:
            .cyan
        case .blue:
            .blue
        case .purple:
            .purple
        case .pink:
            .pink
        case .red:
            .red
        case .orange:
            .orange
        case .yellow:
            .yellow
        case .green:
            .green
        case .mint:
            .mint
        }
    }
}

enum ExplorerPanelShape: String, CaseIterable, Identifiable {
    case rounded
    case squircle
    case capsule

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rounded: "Rounded"
        case .squircle: "Squircle"
        case .capsule: "Capsule"
        }
    }
}

enum ExplorerMaterialStyle: String, CaseIterable, Identifiable {
    case ultraThin
    case thin
    case regular
    case thick
    case ultraThick

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ultraThin: "Ultra Thin"
        case .thin: "Thin"
        case .regular: "Regular"
        case .thick: "Thick"
        case .ultraThick: "Ultra Thick"
        }
    }

    var material: Material {
        switch self {
        case .ultraThin: .ultraThinMaterial
        case .thin: .thinMaterial
        case .regular: .regularMaterial
        case .thick: .thickMaterial
        case .ultraThick: .ultraThickMaterial
        }
    }
}

enum ExplorerTypography: String, CaseIterable, Identifiable {
    case rounded
    case monospaced

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rounded: "Rounded"
        case .monospaced: "Monospaced"
        }
    }

    var fontDesign: Font.Design {
        switch self {
        case .rounded: .rounded
        case .monospaced: .monospaced
        }
    }
}

struct ExplorerAppearance {
    var theme: ExplorerThemePreset
    var accentOption: ExplorerAccentOption
    var typography: ExplorerTypography

    var panelShape: ExplorerPanelShape
    var panelCornerRadius: Double
    var material: ExplorerMaterialStyle

    var glassTintOpacity: Double
    var strokeOpacity: Double
    var shadowOpacity: Double

    var liquidEnabled: Bool
    var liquidMotion: Bool
    var liquidBlur: Double
    var liquidSaturation: Double
    var liquidOpacity: Double

    var accent: Color {
        accentOption.resolvedColor(theme: theme)
    }

    var textPrimary: Color { .white }
    var textSecondary: Color { .white.opacity(0.75) }

    var panelStroke: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.36 * strokeOpacity),
                accent.opacity(0.14 * strokeOpacity),
                Color.white.opacity(0.18 * strokeOpacity),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var panelTint: LinearGradient {
        theme.panelTintGradient(accent: accent)
    }

    static let `default` = ExplorerAppearance(
        theme: .aurora,
        accentOption: .themeDefault,
        typography: .rounded,
        panelShape: .squircle,
        panelCornerRadius: 14,
        material: .ultraThin,
        glassTintOpacity: 0.12,
        strokeOpacity: 1.0,
        shadowOpacity: 0.35,
        liquidEnabled: true,
        liquidMotion: true,
        liquidBlur: 80,
        liquidSaturation: 1.35,
        liquidOpacity: 0.90
    )
}

private struct ExplorerAppearanceKey: EnvironmentKey {
    static let defaultValue: ExplorerAppearance = .default
}

extension EnvironmentValues {
    var explorerAppearance: ExplorerAppearance {
        get { self[ExplorerAppearanceKey.self] }
        set { self[ExplorerAppearanceKey.self] = newValue }
    }
}

enum ExplorerAppearanceKeys {
    static let theme = "FractalSphereExplorer.appearance.themePreset.v1"
    static let accent = "FractalSphereExplorer.appearance.accentOverride.v1"
    static let typography = "FractalSphereExplorer.appearance.typography.v1"

    static let panelShape = "FractalSphereExplorer.appearance.panelShape.v1"
    static let panelCornerRadius = "FractalSphereExplorer.appearance.panelCornerRadius.v1"
    static let material = "FractalSphereExplorer.appearance.material.v1"

    static let glassTintOpacity = "FractalSphereExplorer.appearance.glassTintOpacity.v1"
    static let strokeOpacity = "FractalSphereExplorer.appearance.strokeOpacity.v1"
    static let shadowOpacity = "FractalSphereExplorer.appearance.shadowOpacity.v1"

    static let liquidEnabled = "FractalSphereExplorer.appearance.liquidEnabled.v1"
    static let liquidMotion = "FractalSphereExplorer.appearance.liquidMotion.v1"
    static let liquidBlur = "FractalSphereExplorer.appearance.liquidBlur.v1"
    static let liquidSaturation = "FractalSphereExplorer.appearance.liquidSaturation.v1"
    static let liquidOpacity = "FractalSphereExplorer.appearance.liquidOpacity.v1"
}

struct ExplorerAppearanceHost<Content: View>: View {
    @AppStorage(ExplorerAppearanceKeys.theme) private var themeRaw: String = ExplorerAppearance.default.theme.rawValue
    @AppStorage(ExplorerAppearanceKeys.accent) private var accentRaw: String = ExplorerAppearance.default.accentOption.rawValue
    @AppStorage(ExplorerAppearanceKeys.typography) private var typographyRaw: String = ExplorerAppearance.default.typography.rawValue

    @AppStorage(ExplorerAppearanceKeys.panelShape) private var panelShapeRaw: String = ExplorerAppearance.default.panelShape.rawValue
    @AppStorage(ExplorerAppearanceKeys.panelCornerRadius) private var panelCornerRadius: Double = ExplorerAppearance.default.panelCornerRadius
    @AppStorage(ExplorerAppearanceKeys.material) private var materialRaw: String = ExplorerAppearance.default.material.rawValue

    @AppStorage(ExplorerAppearanceKeys.glassTintOpacity) private var glassTintOpacity: Double = ExplorerAppearance.default.glassTintOpacity
    @AppStorage(ExplorerAppearanceKeys.strokeOpacity) private var strokeOpacity: Double = ExplorerAppearance.default.strokeOpacity
    @AppStorage(ExplorerAppearanceKeys.shadowOpacity) private var shadowOpacity: Double = ExplorerAppearance.default.shadowOpacity

    @AppStorage(ExplorerAppearanceKeys.liquidEnabled) private var liquidEnabled: Bool = ExplorerAppearance.default.liquidEnabled
    @AppStorage(ExplorerAppearanceKeys.liquidMotion) private var liquidMotion: Bool = ExplorerAppearance.default.liquidMotion
    @AppStorage(ExplorerAppearanceKeys.liquidBlur) private var liquidBlur: Double = ExplorerAppearance.default.liquidBlur
    @AppStorage(ExplorerAppearanceKeys.liquidSaturation) private var liquidSaturation: Double = ExplorerAppearance.default.liquidSaturation
    @AppStorage(ExplorerAppearanceKeys.liquidOpacity) private var liquidOpacity: Double = ExplorerAppearance.default.liquidOpacity

    private let content: (ExplorerAppearance) -> Content

    init(@ViewBuilder content: @escaping (ExplorerAppearance) -> Content) {
        self.content = content
    }

    var body: some View {
        let theme = ExplorerThemePreset(rawValue: themeRaw) ?? .aurora
        let accent = ExplorerAccentOption(rawValue: accentRaw) ?? .themeDefault
        let typography = ExplorerTypography(rawValue: typographyRaw) ?? .rounded
        let panelShape = ExplorerPanelShape(rawValue: panelShapeRaw) ?? .squircle
        let material = ExplorerMaterialStyle(rawValue: materialRaw) ?? .ultraThin

        let appearance = ExplorerAppearance(
            theme: theme,
            accentOption: accent,
            typography: typography,
            panelShape: panelShape,
            panelCornerRadius: panelCornerRadius,
            material: material,
            glassTintOpacity: glassTintOpacity,
            strokeOpacity: strokeOpacity,
            shadowOpacity: shadowOpacity,
            liquidEnabled: liquidEnabled,
            liquidMotion: liquidMotion,
            liquidBlur: liquidBlur,
            liquidSaturation: liquidSaturation,
            liquidOpacity: liquidOpacity
        )

        content(appearance)
            .environment(\.explorerAppearance, appearance)
            .tint(appearance.accent)
    }
}
