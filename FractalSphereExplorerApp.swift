import SwiftUI

/// Fractal Sphere Explorer
/// © 2025 Jeffrey William Shorthill
@main
struct FractalSphereExplorerApp: App {
    var body: some Scene {
        WindowGroup {
            ExplorerAppearanceHost { _ in
                ContentView()
            }
        }
        .defaultSize(width: 1280, height: 800)

        Settings {
            ExplorerAppearanceHost { _ in
                AppearanceSettingsView()
                    .padding(20)
                    .frame(minWidth: 560, minHeight: 640)
            }
        }
    }
}
