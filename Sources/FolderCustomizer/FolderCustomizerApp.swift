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
        .commands {
            OptionsCommands()
        }
    }
}

/// Finder / `open` 事件传来的文件夹，经此总线交给 ContentView。
enum OpenedFolderBus {
    static let opened = PassthroughSubject<[URL], Never>()
}

/// 菜单栏触发的动作通过此总线把状态回显到窗口内 toast。
enum StatusBus {
    static func post(_ message: String, success: Bool) {
        NotificationCenter.default.post(
            name: .tintStatus,
            object: nil,
            userInfo: ["message": message, "success": success]
        )
    }
}

extension Notification.Name {
    static let tintStatus = Notification.Name("Tint.status")
}

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var editFromCurrentIcon = false

    /// 开关变化即同步安装/卸载 Quick Action；失败时回退并广播错误。
    @Published var finderQuickAction = false {
        didSet {
            guard finderQuickAction != QuickActionInstaller.isInstalled else { return }
            do {
                if finderQuickAction {
                    try QuickActionInstaller.install()
                } else {
                    QuickActionInstaller.remove()
                }
                StatusBus.post(String(localized: finderQuickAction
                                      ? "Quick Action installed"
                                      : "Quick Action removed"), success: true)
            } catch {
                finderQuickAction = QuickActionInstaller.isInstalled
                StatusBus.post(String(localized: "Failed to update Quick Action"), success: false)
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 让开关初始状态反映磁盘上的实际安装情况，不触发副作用
        AppSettings.shared.finderQuickAction = QuickActionInstaller.isInstalled
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        OpenedFolderBus.opened.send(urls)
    }
}

// MARK: - Menu bar

struct OptionsCommands: Commands {
    @ObservedObject private var settings = AppSettings.shared
    @FocusedValue(\.resetIconsAction) private var resetIconsAction

    var body: some Commands {
        CommandMenu("Options") {
            Toggle("Finder Quick Action", isOn: $settings.finderQuickAction)
            Toggle("Edit from current icon", isOn: $settings.editFromCurrentIcon)
            Divider()
            Button {
                resetIconsAction?()
            } label: {
                Text("Reset to Default Icon")
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])
            .disabled(resetIconsAction == nil)
        }
    }
}

struct ResetIconsActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

extension FocusedValues {
    var resetIconsAction: ResetIconsActionKey.Value? {
        get { self[ResetIconsActionKey.self] }
        set { self[ResetIconsActionKey.self] = newValue }
    }
}
