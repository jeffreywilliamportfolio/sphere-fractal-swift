import SwiftUI

struct BookmarksSheet: View {
    @ObservedObject var viewModel: ExplorerViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.explorerAppearance) private var appearance

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("Bookmarks")
                    .font(.system(size: 22, weight: .semibold, design: appearance.typography.fontDesign))

                Spacer()

                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }

            Text("Save interesting locations and jump back instantly.")
                .foregroundStyle(.secondary)

            saveRow

            Divider()

            if viewModel.bookmarks.isEmpty {
                emptyState
            } else {
                bookmarkList
            }
        }
        .padding(20)
        .frame(minWidth: 520, minHeight: 520)
    }

    private var saveRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                TextField("Bookmark name (optional)", text: $viewModel.bookmarkDraftName)
                    .textFieldStyle(.roundedBorder)

                Button {
                    viewModel.saveCurrentBookmark()
                } label: {
                    Label("Save", systemImage: "bookmark.fill")
                }
                .disabled(!viewModel.canSaveBookmark)
            }

            if !viewModel.canSaveBookmark {
                Text("You’ve reached the bookmark limit. Delete one to add another.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .center, spacing: 10) {
            Spacer()
            Image(systemName: "bookmark")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(.secondary)
            Text("No bookmarks yet")
                .font(.system(size: 16, weight: .semibold))
            Text("Enter the sphere, find a spot you like, then open this sheet to save it.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var bookmarkList: some View {
        List {
            ForEach(viewModel.bookmarks) { bookmark in
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(bookmark.name)
                            .font(.system(size: 13, weight: .semibold))

                        Text("Zoom: \(String(format: "%.2f", bookmark.logScale))  •  Offset: \(format(bookmark.offset.simd))")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Button("Jump") {
                        viewModel.loadBookmark(bookmark)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .contextMenu {
                    Button("Jump") {
                        viewModel.loadBookmark(bookmark)
                        dismiss()
                    }
                    Button(role: .destructive) {
                        viewModel.deleteBookmark(bookmark)
                    } label: {
                        Text("Delete")
                    }
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    guard viewModel.bookmarks.indices.contains(index) else { continue }
                    viewModel.deleteBookmark(viewModel.bookmarks[index])
                }
            }
        }
        .listStyle(.inset)
    }

    private func format(_ v: SIMD3<Float>) -> String {
        String(format: "%.2f, %.2f, %.2f", v.x, v.y, v.z)
    }
}

