import AppKit
import SwiftUI

/// © 2025 Jeffrey William Shorthill
struct ContentView: View {
    @StateObject private var viewModel = ExplorerViewModel()
    @AppStorage("FractalSphereExplorer.hasSeenWelcome.v1") private var hasSeenWelcome: Bool = false
    @State private var isShowingWelcome: Bool = false
    @State private var isShowingAppearance: Bool = false
    @State private var isShowingSplash: Bool = true
    @State private var didStartLaunchFlow: Bool = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            MetalView(viewModel: viewModel)
                .ignoresSafeArea()

            HUDOverlay(
                viewModel: viewModel,
                showWelcome: { isShowingWelcome = true },
                showAppearance: { isShowingAppearance = true }
            )
                .padding(12)
        }
        .overlay {
            if isShowingSplash {
                SplashOverlay()
                    .transition(.opacity.combined(with: .scale(scale: 1.02)))
            }
        }
        .sheet(isPresented: $isShowingWelcome) {
            WelcomeSheet(
                viewModel: viewModel,
                hasSeenWelcome: $hasSeenWelcome,
                isPresented: $isShowingWelcome
            )
            .frame(minWidth: 520, minHeight: 520)
        }
        .sheet(isPresented: $isShowingAppearance) {
            AppearanceSettingsSheet()
        }
        .background(Color.black)
        .task {
            guard !didStartLaunchFlow else { return }
            didStartLaunchFlow = true

            // "Splash screen" for macOS: show a brief branded overlay, then fade out.
            try? await Task.sleep(for: .milliseconds(650))
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.45)) {
                    isShowingSplash = false
                }
            }

            if !hasSeenWelcome {
                try? await Task.sleep(for: .milliseconds(150))
                await MainActor.run {
                    isShowingWelcome = true
                }
            }
        }
    }
}

private struct HUDOverlay: View {
    @ObservedObject var viewModel: ExplorerViewModel
    var showWelcome: () -> Void
    var showAppearance: () -> Void

    @Environment(\.explorerAppearance) private var appearance

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            topRow

            if viewModel.showStats {
                statsPanel
            }

            if viewModel.showHelp {
                helpPanel
            }

            bookmarksPanel

            Spacer(minLength: 0)
        }
        .font(.system(size: 12, weight: .regular, design: appearance.typography.fontDesign))
        .foregroundStyle(appearance.textPrimary)
    }

    private var topRow: some View {
        GlassPanel(padding: 10) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Fractal Sphere Explorer")
                        .font(.system(size: 13, weight: .semibold, design: appearance.typography.fontDesign))
                    Text("Explore an infinite fractal field.")
                        .font(.system(size: 11, weight: .regular, design: appearance.typography.fontDesign))
                        .foregroundStyle(appearance.textSecondary)
                }

                Spacer()

                Button {
                    showAppearance()
                } label: {
                    Image(systemName: "paintpalette")
                }
                .buttonStyle(.plain)
                .help("Appearance")

                Button {
                    showWelcome()
                } label: {
                    Image(systemName: "info.circle")
                }
                .buttonStyle(.plain)
                .help("Welcome & Controls")

                if viewModel.isGamepadConnected {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(viewModel.isPrecisionMode ? Color.yellow : Color.green)
                            .frame(width: 8, height: 8)
                        Text(viewModel.isPrecisionMode ? "Gamepad • Precision" : "Gamepad")
                            .font(.system(size: 12, weight: .semibold, design: appearance.typography.fontDesign))
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(appearance.material.material)
                            .overlay {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(appearance.panelStroke, lineWidth: 1)
                            }
                    }
                }
            }
        }
    }

    private var statsPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Stats", systemImage: "waveform.path.ecg")
                        .labelStyle(.titleAndIcon)
                        .font(.system(size: 12, weight: .semibold, design: appearance.typography.fontDesign))
                    Spacer()
                    Button(viewModel.showStats ? "Hide" : "Show") { viewModel.toggleStats() }
                        .buttonStyle(.borderless)
                        .controlSize(.small)
                }

                Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 6) {
                    GridRow {
                        Text("FPS").foregroundStyle(appearance.textSecondary)
                        Text(String(format: "%.1f", viewModel.fps)).monospacedDigit()
                    }
                    GridRow {
                        Text("Depth").foregroundStyle(appearance.textSecondary)
                        Text(String(format: "%.3f", viewModel.hudLogScale)).monospacedDigit()
                    }
                    GridRow {
                        Text("Speed").foregroundStyle(appearance.textSecondary)
                        Text(String(format: "%.3f%@", viewModel.hudSpeed, viewModel.isPrecisionMode ? " (Precision)" : "")).monospacedDigit()
                    }
                    GridRow {
                        Text("Offset").foregroundStyle(appearance.textSecondary)
                        Text(formatVec3(viewModel.hudOffset)).monospacedDigit()
                    }
                }

                Divider().opacity(0.35)

                HStack(spacing: 8) {
                    Image(systemName: viewModel.isMouseCaptured ? "cursorarrow.rays" : "cursorarrow")
                        .foregroundStyle(viewModel.isMouseCaptured ? appearance.accent : appearance.textSecondary)
                    Text(viewModel.isMouseCaptured ? "Mouse captured (Esc to release)" : "Click the scene to capture mouse")
                        .foregroundStyle(appearance.textSecondary)
                }
                .font(.system(size: 11, weight: .regular, design: appearance.typography.fontDesign))
            }
        }
    }

    private var helpPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Controls", systemImage: "keyboard")
                        .font(.system(size: 12, weight: .semibold, design: appearance.typography.fontDesign))
                    Spacer()
                    Button(viewModel.showHelp ? "Hide" : "Show") { viewModel.toggleHelp() }
                        .buttonStyle(.borderless)
                        .controlSize(.small)
                }

                VStack(alignment: .leading, spacing: 8) {
                    LabeledContent("Mouse") {
                        Text("Look • Wheel zoom • Click capture • Esc release")
                            .foregroundStyle(appearance.textSecondary)
                    }
                    LabeledContent("Keyboard") {
                        HStack(spacing: 6) {
                            Keycap("W") ; Keycap("A") ; Keycap("S") ; Keycap("D")
                            Text("move").foregroundStyle(appearance.textSecondary)
                            Keycap("Q") ; Keycap("E")
                            Text("down/up").foregroundStyle(appearance.textSecondary)
                            Keycap("⇧")
                            Text("sprint").foregroundStyle(appearance.textSecondary)
                        }
                    }
                    LabeledContent("Toggles") {
                        HStack(spacing: 8) {
                            Keycap("H")
                            Text("help").foregroundStyle(appearance.textSecondary)
                            Keycap("I")
                            Text("stats").foregroundStyle(appearance.textSecondary)
                        }
                    }
                    LabeledContent("Gamepad") {
                        Text("LS move • RS look • RT/LT speed • A reset • B precision")
                            .foregroundStyle(appearance.textSecondary)
                    }
                }
                .font(.system(size: 11, weight: .regular, design: appearance.typography.fontDesign))
            }
        }
    }

    private var bookmarksPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Bookmarks", systemImage: "bookmark")
                        .font(.system(size: 12, weight: .semibold, design: appearance.typography.fontDesign))
                    Spacer()
                    Button("Reset") { viewModel.resetToOrigin() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }

                HStack(spacing: 8) {
                    TextField("Bookmark name", text: $viewModel.bookmarkDraftName)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 220)

                    Button("Save Current Location") { viewModel.saveCurrentBookmark() }
                        .disabled(!viewModel.canSaveBookmark)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }

                if viewModel.bookmarks.isEmpty {
                    Text("No bookmarks saved yet.")
                        .foregroundStyle(appearance.textSecondary)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(viewModel.bookmarks) { bm in
                                HStack(spacing: 10) {
                                    Button {
                                        viewModel.loadBookmark(bm)
                                    } label: {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(bm.name)
                                                .font(.system(size: 12, weight: .semibold, design: appearance.typography.fontDesign))
                                            Text(String(format: "Depth: %.3f", bm.logScale))
                                                .foregroundStyle(appearance.textSecondary)
                                        }
                                    }
                                    .buttonStyle(.plain)

                                    Spacer()

                                    Button(role: .destructive) {
                                        viewModel.deleteBookmark(bm)
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                    .buttonStyle(.borderless)
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(.thinMaterial)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .strokeBorder(appearance.panelStroke.opacity(0.6), lineWidth: 1)
                                        }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: 360, maxHeight: 220)
                }
            }
        }
    }

    private func formatVec3(_ v: SIMD3<Float>) -> String {
        String(format: "(%.3f, %.3f, %.3f)", v.x, v.y, v.z)
    }
}

// MARK: - Splash + Welcome

private struct SplashOverlay: View {
    @Environment(\.explorerAppearance) private var appearance
    @State private var animate: Bool = false

    var body: some View {
        ZStack {
            LiquidBackdrop(animate: true)
                .ignoresSafeArea()

            GlassPanel {
                VStack(spacing: 12) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 88, height: 88)
                        .shadow(color: .black.opacity(0.25), radius: 18, x: 0, y: 12)
                        .scaleEffect(animate ? 1.02 : 0.98)

                    Text("Fractal Sphere Explorer")
                        .font(.system(size: 18, weight: .semibold, design: appearance.typography.fontDesign))

                    Text("Initializing renderer…")
                        .font(.system(size: 12, weight: .regular, design: appearance.typography.fontDesign))
                        .foregroundStyle(appearance.textSecondary)

                    ProgressView()
                        .controlSize(.small)
                }
                .padding(.vertical, 6)
                .frame(maxWidth: 340)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

private struct WelcomeSheet: View {
    @ObservedObject var viewModel: ExplorerViewModel
    @Binding var hasSeenWelcome: Bool
    @Binding var isPresented: Bool

    @Environment(\.explorerAppearance) private var appearance
    @State private var isShowingAppearance: Bool = false

    var body: some View {
        ZStack {
            LiquidBackdrop(animate: true)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                header

                GlassPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Start")
                            .font(.system(size: 13, weight: .semibold, design: appearance.typography.fontDesign))

                        VStack(alignment: .leading, spacing: 10) {
                            bullet("Click the scene to capture the mouse for free-look.")
                            bullet("Press Esc to release the mouse and interact with UI.")
                            bullet("Use WASD + Q/E to move, Shift to sprint.")
                            bullet("Use the mouse wheel for zoom impulse / depth.")
                            bullet("Gamepad supported: LS move, RS look, RT/LT speed.")
                        }
                        .font(.system(size: 12, weight: .regular, design: appearance.typography.fontDesign))

                        Divider().opacity(0.35)

                        HStack(spacing: 14) {
                            Toggle("Show in-app controls", isOn: $viewModel.showHelp)
                            Toggle("Show stats overlay", isOn: $viewModel.showStats)
                        }
                        .toggleStyle(.switch)
                        .font(.system(size: 12, weight: .regular, design: appearance.typography.fontDesign))
                    }
                }

                GlassPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Controls")
                            .font(.system(size: 13, weight: .semibold, design: appearance.typography.fontDesign))

                        controlsGrid
                            .font(.system(size: 12, weight: .regular, design: appearance.typography.fontDesign))
                    }
                }

                footer
            }
            .padding(22)
            .frame(maxWidth: 680)
        }
        .sheet(isPresented: $isShowingAppearance) {
            AppearanceSettingsSheet()
        }
        .onAppear {
            // If the welcome is shown manually later, don't re-trigger first-run state.
            if !hasSeenWelcome {
                hasSeenWelcome = true
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .shadow(color: .black.opacity(0.25), radius: 18, x: 0, y: 12)

            Text("Welcome")
                .font(.system(size: 24, weight: .semibold, design: appearance.typography.fontDesign))

            Text("A glassy, high-performance fractal explorer powered by Metal.")
                .foregroundStyle(appearance.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var controlsGrid: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 10) {
            GridRow {
                Label("Mouse", systemImage: "cursorarrow.rays")
                    .foregroundStyle(appearance.textPrimary)
                Text("Look • Wheel zoom • Click capture • Esc release")
                    .foregroundStyle(appearance.textSecondary)
            }
            GridRow {
                Label("Move", systemImage: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left")
                    .foregroundStyle(appearance.textPrimary)
                HStack(spacing: 6) {
                    Keycap("W"); Keycap("A"); Keycap("S"); Keycap("D")
                    Text(" + ").foregroundStyle(appearance.textSecondary)
                    Keycap("Q"); Keycap("E")
                    Text(" + ").foregroundStyle(appearance.textSecondary)
                    Keycap("⇧")
                }
            }
            GridRow {
                Label("HUD", systemImage: "rectangle.stack")
                    .foregroundStyle(appearance.textPrimary)
                HStack(spacing: 8) {
                    Keycap("H"); Text("help").foregroundStyle(appearance.textSecondary)
                    Keycap("I"); Text("stats").foregroundStyle(appearance.textSecondary)
                }
            }
            GridRow {
                Label("Gamepad", systemImage: "gamecontroller")
                    .foregroundStyle(appearance.textPrimary)
                Text("LS move • RS look • RT/LT speed • A reset • B precision")
                    .foregroundStyle(appearance.textSecondary)
            }
        }
    }

    private var footer: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("© 2025 Jeffrey William Shorthill")
                    .font(.system(size: 11, weight: .regular, design: appearance.typography.fontDesign))
                    .foregroundStyle(appearance.textSecondary)
                Text("Tip: Press Esc any time to regain the cursor.")
                    .font(.system(size: 11, weight: .regular, design: appearance.typography.fontDesign))
                    .foregroundStyle(appearance.textSecondary)
            }

            Spacer()

            Button("Appearance…") {
                isShowingAppearance = true
            }
            .buttonStyle(.bordered)

            Button("Start Exploring") {
                isPresented = false
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "sparkle")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(appearance.accent)
            Text(text)
        }
    }
}
