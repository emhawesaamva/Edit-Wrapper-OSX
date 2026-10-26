import AppKit

/// Finds the `edit` executable this app wraps.
enum EditLocator {
    static let overrideDefaultsKey = "editPath"
    static let overrideEnvVar = "EDIT_OSX_EDIT_PATH"

    private static var homeDirectory: String {
        ProcessInfo.processInfo.environment["HOME"] ?? NSHomeDirectory()
    }

    /// Fixed install locations. Checked ahead of PATH because GUI apps launched
    /// from Finder/Dock don't inherit the shell PATH.
    static var searchDirectories: [String] {
        let home = homeDirectory
        return [
            home + "/.cargo/bin",
            home + "/.local/bin",
            home + "/bin",
            "/opt/homebrew/bin",
            "/usr/local/bin",
            "/opt/local/bin",
        ]
    }

    /// The override, if any: env var first, then the saved "Choose edit Executable…" setting.
    private static var override: String? {
        let env = ProcessInfo.processInfo.environment[overrideEnvVar]
        let saved = UserDefaults.standard.string(forKey: overrideDefaultsKey)
        return [env, saved].compactMap { $0 }.first { !$0.isEmpty }
    }

    static func find() -> String? {
        let fm = FileManager.default
        if let path = override, fm.isExecutableFile(atPath: (path as NSString).expandingTildeInPath) {
            return (path as NSString).expandingTildeInPath
        }
        let pathDirs = (ProcessInfo.processInfo.environment["PATH"] ?? "")
            .split(separator: ":").map(String.init)
        for dir in searchDirectories + pathDirs {
            let candidate = dir + "/edit"
            if fm.isExecutableFile(atPath: candidate) { return candidate }
        }
        return nil
    }

    /// Lets the user pick the executable; saved for future launches.
    static func chooseExecutable() -> String? {
        let panel = NSOpenPanel()
        panel.message = "Choose the `edit` executable"
        panel.prompt = "Choose"
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.showsHiddenFiles = true
        panel.directoryURL = URL(fileURLWithPath: homeDirectory + "/.cargo/bin")
        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        guard FileManager.default.isExecutableFile(atPath: url.path) else {
            let alert = NSAlert()
            alert.messageText = "That file isn't executable."
            alert.runModal()
            return nil
        }
        UserDefaults.standard.set(url.path, forKey: overrideDefaultsKey)
        return url.path
    }

    /// Returns the executable path, or shows the "edit is required" dialog until the
    /// user picks one or quits. Returns nil only if the user chooses to quit.
    static func findOrPrompt() -> String? {
        while true {
            if let path = find() { return path }
            let alert = NSAlert()
            alert.alertStyle = .critical
            alert.messageText = "\(appName) needs the “edit” editor, which isn’t installed."
            alert.informativeText = """
                \(appName) is a wrapper around the `edit` terminal editor and can’t run without it.

                Install `edit` (https://github.com/microsoft/edit), or choose where it is installed.

                Searched: \(searchDirectories.map { ($0 as NSString).abbreviatingWithTildeInPath }.joined(separator: ", ")) and your PATH.
                """
            alert.addButton(withTitle: "Choose Location…")
            alert.addButton(withTitle: "Quit")
            if alert.runModal() == .alertSecondButtonReturn { return nil }
            _ = chooseExecutable()
        }
    }
}
