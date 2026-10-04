import Foundation

/// 安装/卸载 Finder「快速操作」：往 ~/Library/Services 放一个 Automator workflow，
/// 内容是 `open -a Tint "$@"`。默认不安装，由用户在「选项」里开关。
enum QuickActionInstaller {
    static var workflowURL: URL {
        FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Services/Open in Tint.workflow", isDirectory: true)
    }

    static var isInstalled: Bool {
        FileManager.default.fileExists(atPath: workflowURL.path)
    }

    static func install() throws {
        let fm = FileManager.default
        let contents = workflowURL.appendingPathComponent("Contents", isDirectory: true)
        try? fm.removeItem(at: workflowURL)
        try fm.createDirectory(at: contents, withIntermediateDirectories: true)
        try bundleInfoPlist.write(to: contents.appendingPathComponent("Info.plist"), atomically: true, encoding: .utf8)
        try documentWflow.write(to: contents.appendingPathComponent("document.wflow"), atomically: true, encoding: .utf8)
        refreshServicesCache()
    }

    static func remove() {
        try? FileManager.default.removeItem(at: workflowURL)
        refreshServicesCache()
    }

    private static func refreshServicesCache() {
        let pbsPath = "/System/Library/CoreServices/pbs"
        guard FileManager.default.fileExists(atPath: pbsPath) else { return }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: pbsPath)
        p.arguments = ["-flush"]
        try? p.run()
    }

    // MARK: - Workflow bundle

    private static let bundleInfoPlist = """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>CFBundleName</key>
        <string>Open in Tint</string>
        <key>NSServices</key>
        <array>
            <dict>
                <key>NSBackgroundColorName</key>
                <string>background</string>
                <key>NSIconName</key>
                <string>NSActionTemplate</string>
                <key>NSMenuItem</key>
                <dict>
                    <key>default</key>
                    <string>Open in Tint</string>
                </dict>
                <key>NSMessage</key>
                <string>runWorkflowAsService</string>
                <key>NSRequiredContext</key>
                <dict>
                    <key>NSApplicationIdentifier</key>
                    <string>com.apple.finder</string>
                </dict>
            </dict>
        </array>
    </dict>
    </plist>
    """

    private static let documentWflow = """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>AMApplicationBuild</key>
        <string>528</string>
        <key>AMApplicationVersion</key>
        <string>2.10</string>
        <key>AMDocumentVersion</key>
        <string>2</string>
        <key>actions</key>
        <array>
            <dict>
                <key>action</key>
                <dict>
                    <key>AMAccepts</key>
                    <dict>
                        <key>Container</key>
                        <string>List</string>
                        <key>Optional</key>
                        <true/>
                        <key>Types</key>
                        <array>
                            <string>com.apple.cocoa.string</string>
                        </array>
                    </dict>
                    <key>AMActionVersion</key>
                    <string>2.0.3</string>
                    <key>AMApplication</key>
                    <array>
                        <string>Automator</string>
                    </array>
                    <key>AMParameterProperties</key>
                    <dict>
                        <key>COMMAND_STRING</key>
                        <dict/>
                        <key>CheckedForUserDefaultShell</key>
                        <dict/>
                        <key>inputMethod</key>
                        <dict/>
                        <key>shell</key>
                        <dict/>
                        <key>source</key>
                        <dict/>
                    </dict>
                    <key>AMProvides</key>
                    <dict>
                        <key>Container</key>
                        <string>List</string>
                        <key>Types</key>
                        <array>
                            <string>com.apple.cocoa.string</string>
                        </array>
                    </dict>
                    <key>ActionBundlePath</key>
                    <string>/System/Library/Automator/Run Shell Script.action</string>
                    <key>ActionName</key>
                    <string>Run Shell Script</string>
                    <key>ActionParameters</key>
                    <dict>
                        <key>COMMAND_STRING</key>
                        <string>open -a Tint "$@"</string>
                        <key>CheckedForUserDefaultShell</key>
                        <true/>
                        <key>inputMethod</key>
                        <integer>1</integer>
                        <key>shell</key>
                        <string>/bin/bash</string>
                        <key>source</key>
                        <string></string>
                    </dict>
                    <key>BundleIdentifier</key>
                    <string>com.apple.RunShellScript</string>
                    <key>CFBundleVersion</key>
                    <string>2.0.3</string>
                    <key>CanShowSelectedItemsWhenRun</key>
                    <false/>
                    <key>CanShowWhenRun</key>
                    <true/>
                    <key>Category</key>
                    <array>
                        <string>AMCategoryUtilities</string>
                    </array>
                    <key>Class Name</key>
                    <string>RunShellScriptAction</string>
                    <key>InputUUID</key>
                    <string>3A5B8C31-0001-4E5F-8A01-000000000001</string>
                    <key>Keywords</key>
                    <array>
                        <string>Shell</string>
                    </array>
                    <key>OutputUUID</key>
                    <string>3A5B8C31-0002-4E5F-8A01-000000000002</string>
                    <key>UUID</key>
                    <string>3A5B8C31-0003-4E5F-8A01-000000000003</string>
                    <key>UnlocalizedApplications</key>
                    <array>
                        <string>Automator</string>
                    </array>
                    <key>arguments</key>
                    <dict>
                        <key>0</key>
                        <dict>
                            <key>default value</key>
                            <integer>0</integer>
                            <key>name</key>
                            <string>inputMethod</string>
                            <key>required</key>
                            <string>0</string>
                            <key>type</key>
                            <string>0</string>
                            <key>uuid</key>
                            <string>0</string>
                        </dict>
                        <key>1</key>
                        <dict>
                            <key>default value</key>
                            <false/>
                            <key>name</key>
                            <string>CheckedForUserDefaultShell</string>
                            <key>required</key>
                            <string>0</string>
                            <key>type</key>
                            <string>0</string>
                            <key>uuid</key>
                            <string>1</string>
                        </dict>
                    </dict>
                    <key>isViewVisible</key>
                    <integer>1</integer>
                </dict>
            </dict>
        </array>
        <key>connectors</key>
        <dict/>
        <key>workflowMetaData</key>
        <dict>
            <key>inputTypeIdentifier</key>
            <string>com.apple.Automator.fileSystemObject</string>
            <key>outputTypeIdentifier</key>
            <string>com.apple.Automator.nothing</string>
            <key>serviceInputTypeIdentifier</key>
            <string>com.apple.Automator.fileSystemObject</string>
            <key>serviceOutputTypeIdentifier</key>
            <string>com.apple.Automator.nothing</string>
            <key>serviceProcessesInput</key>
            <integer>0</integer>
            <key>systemImageName</key>
            <string>NSActionTemplate</string>
            <key>workflowTypeIdentifier</key>
            <string>com.apple.Automator.servicesMenu</string>
        </dict>
    </dict>
    </plist>
    """
}
