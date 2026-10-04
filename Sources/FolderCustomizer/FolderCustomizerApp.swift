import SwiftUI
import Combine

@main
struct FolderCustomizerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("Tint") {
            ContentView()
        }
        .windowResizability(.contentSize)
    }
}

/// Finder / `open` 事件传来的文件夹，经此总线交给 ContentView。
enum OpenedFolderBus {
    static let opened = PassthroughSubject<[URL], Never>()
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        OpenedFolderBus.opened.send(urls)
    }
}
