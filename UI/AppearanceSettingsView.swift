import SwiftUI

struct AppearanceSettingsView: View {
    fileprivate enum Layout {
        static let rowVerticalPadding: CGFloat = 4
        static let labelColumnWidth: CGFloat = 115
        static let valueColumnWidth: CGFloat = 52
    }

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

    @Environment(\.explorerAppearance) private var appearance
    
    // Optional ViewModel for Fractal Settings
    var viewModel: ExplorerViewModel?

    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer(minLength: 0)
                    preview
                        .frame(maxWidth: 520)
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 8)
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            } header: {
                Text("Preview")
            }
            
            if let vm = viewModel {
                Section("Fractal Appearance") {
                    FormRow("Base Color") {
                        ColorPicker("", selection: Binding(
                            get: { vm.baseColor },
                            set: { vm.baseColor = $0 }
                        ))
                        .labelsHidden()
                    }
                    
                    FormRow("Trap Glow") {
                        ColorPicker("", selection: Binding(
                           get: { vm.trapColor },
                           set: { vm.trapColor = $0 }
                        ))
                        .labelsHidden()
                    }
                    
                    FormRow("Ambient Light") {
                        let ambient = Binding<Double>(
                            get: { Double(vm.ambientIntensity) },
                            set: { vm.ambientIntensity = Float($0) }
                        )
                        HStack(spacing: 12) {
                            Slider(value: ambient, in: 0.0...0.6, step: 0.02)
                            Text(ambient.wrappedValue, format: .number.precision(.fractionLength(2)))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                                .frame(width: Layout.valueColumnWidth, alignment: .trailing)
                        }
                    }
                }
            }

            Section("Theme") {
                FormRow("Preset") {
                    Picker("", selection: $themeRaw) {
                        ForEach(ExplorerThemePreset.allCases) { preset in
                            Text(preset.displayName).tag(preset.rawValue)
                        }
                    }
                    .labelsHidden()
                }

                FormRow("Accent") {
                    Picker("", selection: $accentRaw) {
                        ForEach(ExplorerAccentOption.allCases) { accent in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(accent.resolvedColor(theme: appearance.theme))
                                    .frame(width: 10, height: 10)
                                Text(accent.displayName)
                            }
                            .tag(accent.rawValue)
                        }
                    }
                    .labelsHidden()
                }

                FormRow("Typography") {
                    Picker("", selection: $typographyRaw) {
                        ForEach(ExplorerTypography.allCases) { t in
                            Text(t.displayName).tag(t.rawValue)
                        }
                    }
                    .labelsHidden()
                }
            }

            Section("Glass") {
                FormRow("Material") {
                    Picker("", selection: $materialRaw) {
                        ForEach(ExplorerMaterialStyle.allCases) { m in
                            Text(m.displayName).tag(m.rawValue)
                        }
                    }
                    .labelsHidden()
                }

                FormRow("Tint") {
                    HStack(spacing: 12) {
                        Slider(value: $glassTintOpacity, in: 0...0.30, step: 0.01)
                        Text(glassTintOpacity, format: .number.precision(.fractionLength(2)))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                            .frame(width: Layout.valueColumnWidth, alignment: .trailing)
                    }
                }

                FormRow("Stroke") {
                    HStack(spacing: 12) {
                        Slider(value: $strokeOpacity, in: 0...1.25, step: 0.05)
                        Text(strokeOpacity, format: .number.precision(.fractionLength(2)))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                            .frame(width: Layout.valueColumnWidth, alignment: .trailing)
                    }
                }

                FormRow("Shadow") {
                    HStack(spacing: 12) {
                        Slider(value: $shadowOpacity, in: 0...0.75, step: 0.05)
                        Text(shadowOpacity, format: .number.precision(.fractionLength(2)))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                            .frame(width: Layout.valueColumnWidth, alignment: .trailing)
                    }
                }
            }

            Section("Shape") {
                FormRow("Panels") {
                    Picker("", selection: $panelShapeRaw) {
                        ForEach(ExplorerPanelShape.allCases) { shape in
                            Text(shape.displayName).tag(shape.rawValue)
                        }
                    }
                    .labelsHidden()
                }

                FormRow("Corner Radius") {
                    HStack(spacing: 12) {
                        Slider(value: $panelCornerRadius, in: 6...28, step: 1)
                            .disabled(currentPanelShape == .capsule)
                        Text(panelCornerRadius, format: .number.precision(.fractionLength(0)))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                            .frame(width: Layout.valueColumnWidth, alignment: .trailing)
                    }
                }
                .help(currentPanelShape == .capsule ? "Capsule ignores corner radius." : "")
            }

            Section("Liquid Backdrop") {
                FormRow("Enable") {
                    Toggle("", isOn: $liquidEnabled)
                        .labelsHidden()
                }
                
                FormRow("Animate") {
                    Toggle("", isOn: $liquidMotion)
                        .disabled(!liquidEnabled)
                        .labelsHidden()
                }

                FormRow("Blur") {
                    HStack(spacing: 12) {
                        Slider(value: $liquidBlur, in: 0...140, step: 5)
                            .disabled(!liquidEnabled)
                        Text(liquidBlur, format: .number.precision(.fractionLength(0)))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                            .frame(width: Layout.valueColumnWidth, alignment: .trailing)
                    }
                }

                FormRow("Saturation") {
                    HStack(spacing: 12) {
                        Slider(value: $liquidSaturation, in: 1.0...1.8, step: 0.05)
                            .disabled(!liquidEnabled)
                        Text(liquidSaturation, format: .number.precision(.fractionLength(2)))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                            .frame(width: Layout.valueColumnWidth, alignment: .trailing)
                    }
                }

                FormRow("Opacity") {
                    HStack(spacing: 12) {
                        Slider(value: $liquidOpacity, in: 0...1.0, step: 0.05)
                            .disabled(!liquidEnabled)
                        Text(liquidOpacity, format: .number.precision(.fractionLength(2)))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                            .frame(width: Layout.valueColumnWidth, alignment: .trailing)
                    }
                }
            }

            Section {
                HStack {
                    Spacer(minLength: 0)
                    Button("Reset to Defaults") {
                        resetToDefaults()
                    }
                    .buttonStyle(.bordered)
                    Spacer(minLength: 0)
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 8, trailing: 0))
                .listRowSeparator(.hidden)
            }

            if viewModel != nil {
                Color.clear
                    .frame(height: 64)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
        }
    }

    private var currentPanelShape: ExplorerPanelShape {
        ExplorerPanelShape(rawValue: panelShapeRaw) ?? .squircle
    }

    private var preview: some View {
        ZStack {
            LiquidBackdrop(animate: false)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 10) {
                GlassPanel {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(appearance.accent)
                            .frame(width: 10, height: 10)
                        Text("Glass Panel Preview")
                            .font(.system(size: 13, weight: .semibold, design: appearance.typography.fontDesign))
                        Spacer()
                        HStack(spacing: 6) {
                            Keycap("H")
                            Keycap("I")
                        }
                    }
                    Text("Adjust theme, material, and shape — changes apply instantly.")
                        .font(.system(size: 11, weight: .regular, design: appearance.typography.fontDesign))
                        .foregroundStyle(appearance.textSecondary)
                }
            }
            .padding(12)
        }
        .frame(height: 160)
    }

    private func resetToDefaults() {
        let d = ExplorerAppearance.default
        themeRaw = d.theme.rawValue
        accentRaw = d.accentOption.rawValue
        typographyRaw = d.typography.rawValue
        panelShapeRaw = d.panelShape.rawValue
        panelCornerRadius = d.panelCornerRadius
        materialRaw = d.material.rawValue
        glassTintOpacity = d.glassTintOpacity
        strokeOpacity = d.strokeOpacity
        shadowOpacity = d.shadowOpacity
        liquidEnabled = d.liquidEnabled
        liquidMotion = d.liquidMotion
        liquidBlur = d.liquidBlur
        liquidSaturation = d.liquidSaturation
        liquidOpacity = d.liquidOpacity
        
        if let vm = viewModel {
            vm.baseColor = .cyan
            vm.trapColor = .purple
        }
    }
}

struct AppearanceSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: ExplorerViewModel?

    var body: some View {
        NavigationStack {
            AppearanceSettingsView(viewModel: viewModel)
                .padding(20)
                .navigationTitle("Appearance Settings")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
        .frame(minWidth: 560, minHeight: 620)
    }
}

// MARK: - Local Components

private struct Keycap: View {
    @Environment(\.explorerAppearance) private var appearance
    let title: String

    init(_ title: String) { self.title = title }

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

private struct GlassPanel<Content: View>: View {
    @Environment(\.explorerAppearance) private var appearance
    private let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(10)
            .background {
                switch appearance.panelShape {
                case .rounded:
                    panelBackground(for: RoundedRectangle(cornerRadius: appearance.panelCornerRadius, style: .circular))
                case .squircle:
                    panelBackground(for: RoundedRectangle(cornerRadius: appearance.panelCornerRadius, style: .continuous))
                case .capsule:
                    panelBackground(for: Capsule(style: .continuous))
                }
            }
            .shadow(color: .black.opacity(appearance.shadowOpacity), radius: 16, x: 0, y: 10)
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

private struct FormRow<Content: View>: View {
    let label: String
    let content: () -> Content
    
    init(_ label: String, @ViewBuilder content: @escaping () -> Content) {
        self.label = label
        self.content = content
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(label)
                .frame(width: AppearanceSettingsView.Layout.labelColumnWidth, alignment: .leading)
                .fixedSize()
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, AppearanceSettingsView.Layout.rowVerticalPadding)
    }
}
