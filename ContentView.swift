import AppKit
import SwiftUI

/// © 2025 Jeffrey William Shorthill
struct ContentView: View {
    private enum Screen: Equatable {
        case splash
        case menu
        case engagement
    }

    @StateObject private var viewModel = ExplorerViewModel()
    @State private var isShowingAppearance: Bool = false
    @State private var isShowingBookmarks: Bool = false
    @State private var isShowingHelp: Bool = false
    @State private var screen: Screen = .splash
    @State private var didStartLaunchFlow: Bool = false

    var body: some View {
        ZStack {
            // Background Layer
            LiquidBackdrop(animate: true)
                .ignoresSafeArea()

            // Content Layer
            ZStack {
                if screen == .engagement {
                    EngagementScreen(
                        viewModel: viewModel,
                        showMenu: {
                            viewModel.setMouseCaptured(false)
                            screen = .menu
                        }
                    )
                    .transition(.opacity)
                }

                if screen == .menu {
                    MenuScreen(
                        viewModel: viewModel,
                        showAppearance: { isShowingAppearance = true },
                        showBookmarks: { isShowingBookmarks = true },
                        showHelp: { isShowingHelp = true },
                        engage: {
                            isShowingAppearance = false
                            isShowingBookmarks = false
                            isShowingHelp = false
                            withAnimation(.easeInOut(duration: 0.5)) {
                                screen = .engagement
                            }
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if screen == .splash {
                    SplashOverlay()
                        .transition(.opacity)
                }
            }
        }
        .sheet(isPresented: $isShowingAppearance) {
            AppearanceSettingsSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $isShowingBookmarks) {
            ExplorerAppearanceHost { _ in
                BookmarksSheet(viewModel: viewModel)
            }
        }
        .sheet(isPresented: $isShowingHelp) {
            ExplorerAppearanceHost { _ in
                HelpSheet()
            }
        }
        .background(Color.black)
        .onChange(of: screen) { _, newValue in
            if newValue != .menu {
                isShowingAppearance = false
                isShowingBookmarks = false
                isShowingHelp = false
            }
            if newValue != .engagement {
                viewModel.setMouseCaptured(false)
            }
        }
        .task {
            guard !didStartLaunchFlow else { return }
            didStartLaunchFlow = true

            try? await Task.sleep(for: .milliseconds(1800))
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.8)) {
                    screen = .menu
                }
            }
        }
    }
}

// MARK: - Screens

private struct MenuScreen: View {
    @ObservedObject var viewModel: ExplorerViewModel
    var showAppearance: () -> Void
    var showBookmarks: () -> Void
    var showHelp: () -> Void
    var engage: () -> Void

    @Environment(\.explorerAppearance) private var appearance

    var body: some View {
        VStack {
            Spacer()

            // Minimized Central Card
            VStack(spacing: 24) {
                Image("aeterna")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 400)
                    .shadow(color: appearance.accent.opacity(0.5), radius: 8)

                Button(action: engage) {
                    Label("Enter Sphere", systemImage: "infinity")
                        .font(.system(size: 16, weight: .semibold, design: appearance.typography.fontDesign))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Material.regular)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(LinearGradient(colors: [.white.opacity(0.5), .white.opacity(0.1)], startPoint: .top, endPoint: .bottom), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                .buttonStyle(.plain)

                HStack(spacing: 20) {
                    MenuIconButton(icon: "paintpalette", label: "Appearance", action: showAppearance)
                    MenuIconButton(icon: "bookmark", label: "Bookmarks", action: showBookmarks)
                    MenuIconButton(icon: "questionmark.circle", label: "Help", action: showHelp)
                }
            }
            .padding(40)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)

            Spacer()

            Text("© 2025 Jeffrey William Shorthill")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
                .padding(.bottom, 20)
        }
    }
}

private struct MenuIconButton: View {
    var icon: String
    var label: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .light))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .multilineTextAlignment(.center)
                    .opacity(0.8)
            }
            .frame(width: 74)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
    }
}

private struct EngagementScreen: View {
    @ObservedObject var viewModel: ExplorerViewModel
    var showMenu: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            MetalView(viewModel: viewModel)
                .ignoresSafeArea()

            // Minimal HUD overlays
            VStack(alignment: .leading, spacing: 10) {
                if viewModel.showStats {
                    StatsHUD(viewModel: viewModel)
                }
                if viewModel.showHelp {
                    HelpHUD()
                }
            }
            .padding(20)

            if let message = viewModel.rendererErrorMessage {
                VStack {
                    Spacer()
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Renderer Error")
                            .font(.system(size: 14, weight: .semibold))
                        Text(message)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        HStack {
                            Button("Back to Menu", action: showMenu)
                                .buttonStyle(.borderedProminent)
                            Spacer()
                        }
                    }
                    .padding(14)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                    )
                    .frame(maxWidth: 520)
                    .padding(20)
                }
                .transition(.opacity)
            }

            // "Back" button hint (only visible when mouse not captured or briefly)
            if !viewModel.isMouseCaptured {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        HStack(spacing: 10) {
                            Button(action: showMenu) {
                                HStack(spacing: 6) {
                                    Image(systemName: "line.3.horizontal")
                                    Text("Menu")
                                }
                                .font(.system(size: 13, weight: .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial, in: Capsule())
                            }
                            .buttonStyle(.plain)

                            Button(action: viewModel.resetToOrigin) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("Reset View")
                                }
                                .font(.system(size: 13, weight: .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial, in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(20)
                    }
                }
            }
        }
    }
}

private struct StatsHUD: View {
    @ObservedObject var viewModel: ExplorerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("FPS: \(Int(viewModel.fps))")
            Text("Zoom: \(String(format: "%.1f", viewModel.hudLogScale))")
            Text("Pos: \(formatVec3(viewModel.hudOffset))")
        }
        .font(.system(size: 10, design: .monospaced))
        .foregroundStyle(.white.opacity(0.8))
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }

    private func formatVec3(_ v: SIMD3<Float>) -> String {
        String(format: "%.2f, %.2f, %.2f", v.x, v.y, v.z)
    }
}

private struct HelpHUD: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("WASD to Move • Shift to Sprint")
            Text("Mouse to Look • Click to Capture")
            Text("ESC to Release • H for Help")
        }
        .font(.system(size: 10))
        .foregroundStyle(.white.opacity(0.7))
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
}

private struct SplashOverlay: View {
    @State private var opacity: Double = 0
    @State private var scale: Double = 0.8
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 140, height: 140)
                .shadow(color: .purple.opacity(0.5), radius: 20)
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                opacity = 1
                scale = 1
            }
            withAnimation(.easeIn(duration: 0.5).delay(1.3)) {
                opacity = 0
                scale = 1.1
            }
        }
    }
}
