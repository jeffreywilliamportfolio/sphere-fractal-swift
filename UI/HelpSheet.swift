import SwiftUI

struct HelpSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.explorerAppearance) private var appearance

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Controls")
                            .font(.system(size: 20, weight: .semibold, design: appearance.typography.fontDesign))

                        Text("Mouse is captured while exploring. Click inside the view to capture; press ESC to release.")
                            .font(.system(size: 12, weight: .regular, design: appearance.typography.fontDesign))
                            .foregroundStyle(.secondary)
                    }

                    GroupBox("Keyboard & Mouse") {
                        VStack(alignment: .leading, spacing: 10) {
                            helpRow("Move", "W A S D")
                            helpRow("Up / Down", "E / Q")
                            helpRow("Look", "Mouse (click to capture)")
                            helpRow("Release mouse", "ESC")
                            helpRow("Sprint", "Shift")
                            helpRow("Toggle help", "H")
                            helpRow("Toggle stats", "I")
                        }
                        .padding(.vertical, 6)
                    }

                    GroupBox("Gamepad") {
                        VStack(alignment: .leading, spacing: 10) {
                            helpRow("Move", "Left stick")
                            helpRow("Look", "Right stick")
                            helpRow("Throttle", "RT / LT")
                            helpRow("Precision", "B (toggle)")
                            helpRow("Reset", "A (return to origin)")
                        }
                        .padding(.vertical, 6)
                    }

                    GroupBox("Tips") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("• If you feel “stuck”, open the menu and use Reset (A on gamepad).")
                            Text("• If you see “Renderer Error”, your Mac may not support the required Metal features.")
                        }
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 6)
                    }
                }
                .padding(20)
                .frame(maxWidth: 720, alignment: .leading)
            }
            .navigationTitle("Help")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .keyboardShortcut(.defaultAction)
                }
            }
        }
        .frame(minWidth: 560, minHeight: 620)
    }

    private func helpRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: appearance.typography.fontDesign))
                .frame(width: 120, alignment: .leading)

            Text(value)
                .font(.system(size: 12, weight: .regular, design: appearance.typography.fontDesign))
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)
        }
    }
}

