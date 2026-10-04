import SwiftUI
import AppKit
import Combine
import UniformTypeIdentifiers

/// 系统取色面板（NSColorPanel）的回调桥。
final class ColorPanelCoordinator: NSObject {
    private let onChange: (NSColor) -> Void
    init(onChange: @escaping (NSColor) -> Void) {
        self.onChange = onChange
    }
    @objc func colorChanged(_ sender: NSColorPanel) {
        onChange(sender.color)
    }
}

struct ContentView: View {
    @State private var folders: [URL] = []
    @State private var themeColor: Color = Color(nsColor: .controlAccentColor)
    @State private var accentColor = Color(nsColor: .controlAccentColor)
    @State private var selectedPreset: Int? = -1
    @State private var emoji: String = ""
    @State private var emojiOpacity: Double = 1.0
    @State private var statusMessage: String = ""
    @State private var isTargeted = false
    @State private var colorCoordinator: ColorPanelCoordinator?
    @FocusState private var emojiFieldFocused: Bool

    private let paletteColors: [Color] = [
        .red, .orange, .yellow, .green, .teal, .blue, .purple, .pink, .gray
    ]

    private let quickEmojis = ["🎨", "⭐️", "🔥", "📷", "🎵", "💼"]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            preview

            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("Folders")
                dropZone
                if !folders.isEmpty {
                    folderChips
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                sectionLabel("Color")
                swatchRow
            }

            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("Emoji")
                emojiRow
            }
            optionsGroup

            applyButton

            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            }
        }
        .padding(24)
        .frame(width: 480)
        .animation(.easeInOut(duration: 0.15), value: statusMessage)
        .onReceive(
            DistributedNotificationCenter.default().publisher(
                for: NSNotification.Name("AppleColorPreferencesChangedNotification")
            ).receive(on: DispatchQueue.main)
        ) { _ in
            accentColor = Color(nsColor: .controlAccentColor)
            if selectedPreset == -1 {
                themeColor = accentColor
            }
        }
    }

    // MARK: - Preview

    private var preview: some View {
        HStack {
            Spacer()
            if let image = makePreview() {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 160, height: 160)
                    .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
            }
            Spacer()
        }
        .padding(.top, 4)
        .padding(.bottom, 4)
    }

    // MARK: - Folder

    private var dropZone: some View {
        RoundedRectangle(cornerRadius: 10)
            .strokeBorder(
                isTargeted ? Color.accentColor : Color.secondary.opacity(0.4),
                style: StrokeStyle(lineWidth: 1.5, dash: [6])
            )
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.accentColor.opacity(isTargeted ? 0.06 : 0))
            )
            .frame(height: 52)
            .overlay(
                HStack(spacing: 6) {
                    Image(systemName: "folder.badge.plus")
                        .foregroundColor(.secondary)
                    Text(isTargeted ? "Release to add" : "Drop folders here, or click to choose")
                        .foregroundColor(.secondary)
                }
            )
            .contentShape(RoundedRectangle(cornerRadius: 10))
            .onTapGesture { chooseFolders() }
            .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                addFolders(from: providers)
                return true
            }
    }

    private var folderChips: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 6)],
                  alignment: .leading, spacing: 6) {
            ForEach(folders, id: \.self) { url in
                folderChip(url)
            }
        }
    }

    private func folderChip(_ url: URL) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "folder.fill")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(url.lastPathComponent)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.middle)
            Button {
                folders.removeAll { $0 == url }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.gray.opacity(0.12)))
    }

    // MARK: - Color

    private var swatchRow: some View {
        HStack(spacing: 10) {
            accentSwatch

            ForEach(Array(paletteColors.enumerated()), id: \.offset) { idx, color in
                swatch(color, selected: selectedPreset == idx)
                    .onTapGesture {
                        themeColor = color
                        selectedPreset = idx
                    }
            }

            rainbowSwatch
        }
    }

    private var accentSwatch: some View {
        return swatch(accentColor, selected: selectedPreset == -1)
            .help(Text("System Accent"))
            .onTapGesture {
                themeColor = accentColor
                selectedPreset = -1
            }
    }

    private var rainbowSwatch: some View {
        Circle()
            .fill(
                AngularGradient(colors: [.red, .orange, .yellow, .green, .blue, .purple, .red],
                                center: .center)
            )
            .frame(width: 26, height: 26)
            .overlay(Circle().strokeBorder(.black.opacity(0.18), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.12), radius: 0.5, y: 0.5)
            .contentShape(Circle())
            .help(Text("Custom Color…"))
            .onTapGesture { openCustomColor() }
    }

    private func swatch(_ color: Color, selected: Bool) -> some View {
        Circle()
            .fill(color)
            .frame(width: 26, height: 26)
            .overlay(Circle().strokeBorder(.white.opacity(0.9), lineWidth: selected ? 3 : 1))
            .overlay(Circle().strokeBorder(.black.opacity(0.18), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.12), radius: 0.5, y: 0.5)
            .contentShape(Circle())
    }

    // MARK: - Emoji

    private var emojiRow: some View {
        HStack(spacing: 8) {
            ForEach(quickEmojis, id: \.self) { e in
                Button {
                    emoji = e
                } label: {
                    Text(e)
                        .font(.system(size: 20))
                        .frame(width: 34, height: 30)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(e == emoji ? Color.accentColor.opacity(0.18) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 4)

            TextField("Emoji", text: $emoji)
                .textFieldStyle(.roundedBorder)
                .frame(width: 80)
                .focused($emojiFieldFocused)

            Button {
                openAllEmoji()
            } label: {
                Label("All…", systemImage: "keyboard")
            }
            .help(Text("Open the system emoji panel"))
        }
    }

    // MARK: - Options

    private var optionsGroup: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Text("Emoji Opacity")
                    Slider(value: $emojiOpacity, in: 0...1)
                    Text("\(Int(emojiOpacity * 100))%")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.secondary)
                        .frame(width: 36, alignment: .trailing)
                }
                Divider()
                Button {
                    resetIcons()
                } label: {
                    Label("Reset to Default Icon", systemImage: "arrow.uturn.backward")
                }
                .disabled(folders.isEmpty)
            }
            .padding(.top, 10)
        } label: {
            sectionLabel("Options")
        }
    }

    // MARK: - Apply

    private var applyButton: some View {
        Button {
            applyIcons()
        } label: {
            Label {
                folders.isEmpty
                    ? Text("Apply")
                    : Text("Apply to \(folders.count) Folders")
            } icon: {
                Image(systemName: "checkmark.circle.fill")
            }
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(folders.isEmpty)
    }

    // MARK: - Helpers

    private func sectionLabel(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(.headline)
    }

    private var trimmedEmoji: String {
        emoji.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @MainActor
    private func makePreview() -> NSImage? {
        renderFolderIcon(color: NSColor(themeColor),
                         emoji: trimmedEmoji,
                         emojiOpacity: CGFloat(emojiOpacity),
                         size: 256)
    }

    private func chooseFolders() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.message = String(localized: "Choose one or more folders")
        if panel.runModal() == .OK {
            for url in panel.urls where !folders.contains(url) {
                folders.append(url)
            }
        }
    }

    private func addFolders(from providers: [NSItemProvider]) {
        for provider in providers {
            _ = provider.loadObject(ofClass: URL.self) { object, _ in
                guard let url = object, url.hasDirectoryPath else { return }
                DispatchQueue.main.async {
                    if !folders.contains(url) {
                        folders.append(url)
                    }
                }
            }
        }
    }

    private func openCustomColor() {
        let panel = NSColorPanel.shared
        panel.isContinuous = true
        panel.showsAlpha = false
        panel.color = NSColor(themeColor)

        let coordinator = ColorPanelCoordinator { color in
            themeColor = Color(nsColor: color)
            selectedPreset = nil
        }
        colorCoordinator = coordinator
        panel.setTarget(coordinator)
        panel.setAction(#selector(ColorPanelCoordinator.colorChanged(_:)))
        panel.orderFront(nil)
    }

    private func openAllEmoji() {
        emojiFieldFocused = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            NSApp.orderFrontCharacterPalette(nil)
        }
    }

    private func applyIcons() {
        guard !folders.isEmpty else {
            statusMessage = String(localized: "Select at least one folder first")
            return
        }
        let image = renderFolderIcon(color: NSColor(themeColor),
                                     emoji: trimmedEmoji,
                                     emojiOpacity: CGFloat(emojiOpacity),
                                     size: 512)
        for url in folders {
            NSWorkspace.shared.setIcon(image, forFile: url.path, options: [])
        }
        statusMessage = String(localized: "Applied to \(folders.count) folders")
    }

    private func resetIcons() {
        guard !folders.isEmpty else {
            statusMessage = String(localized: "Select at least one folder first")
            return
        }
        for url in folders {
            NSWorkspace.shared.setIcon(nil, forFile: url.path, options: [])
        }
        statusMessage = String(localized: "Default icon restored")
    }
}
