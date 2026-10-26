import AppKit

let appName = "Edit OSX"

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var controllers: [TerminalWindowController] = []
    private var launchedWithFiles = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = buildMenu()
        NSApp.activate(ignoringOtherApps: true)
        // Files delivered via application(_:open:) arrive before this returns.
        DispatchQueue.main.async { [self] in
            if controllers.isEmpty && !launchedWithFiles { openWindow(files: []) }
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        launchedWithFiles = true
        for url in urls { openWindow(files: [url.path]) }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func openWindow(files: [String]) {
        guard let editPath = EditLocator.findOrPrompt() else {
            if controllers.isEmpty { NSApp.terminate(nil) }
            return
        }
        let controller = TerminalWindowController(editPath: editPath, files: files)
        controller.onClose = { [weak self] c in self?.controllers.removeAll { $0 === c } }
        controllers.append(controller)
        controller.showWindow(nil)
    }

    @objc func newWindow(_ sender: Any?) { openWindow(files: []) }

    @objc func openDocument(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK else { return }
        for url in panel.urls { openWindow(files: [url.path]) }
    }

    @objc func chooseTheme(_ sender: NSMenuItem) {
        guard let theme = Theme.all.first(where: { $0.name == sender.title }) else { return }
        Theme.current = theme
    }

    @objc func chooseEdit(_ sender: Any?) { _ = EditLocator.chooseExecutable() }

    @objc func showAbout(_ sender: Any?) {
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: appName,
            .credits: NSAttributedString(string: "A native wrapper around the `edit` terminal editor."),
        ])
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        for item in menu.items { item.state = item.title == Theme.current.name ? .on : .off }
    }

    private func buildMenu() -> NSMenu {
        let main = NSMenu()

        func add(_ menu: NSMenu, _ title: String, _ action: Selector?, _ key: String = "",
                 _ mods: NSEvent.ModifierFlags = .command, target: AnyObject? = nil) {
            let item = menu.addItem(withTitle: title, action: action, keyEquivalent: key)
            item.keyEquivalentModifierMask = mods
            item.target = target
        }
        func submenu(_ title: String) -> NSMenu {
            let item = main.addItem(withTitle: title, action: nil, keyEquivalent: "")
            let m = NSMenu(title: title)
            item.submenu = m
            return m
        }

        let appMenu = submenu(appName)
        add(appMenu, "About \(appName)", #selector(showAbout(_:)), target: self)
        appMenu.addItem(.separator())
        add(appMenu, "Choose edit Executable…", #selector(chooseEdit(_:)), ",", target: self)
        appMenu.addItem(.separator())
        add(appMenu, "Hide \(appName)", #selector(NSApplication.hide(_:)), "h")
        add(appMenu, "Hide Others", #selector(NSApplication.hideOtherApplications(_:)), "h", [.command, .option])
        add(appMenu, "Show All", #selector(NSApplication.unhideAllApplications(_:)))
        appMenu.addItem(.separator())
        add(appMenu, "Quit \(appName)", #selector(NSApplication.terminate(_:)), "q")

        let file = submenu("File")
        add(file, "New Window", #selector(newWindow(_:)), "n", target: self)
        add(file, "Open…", #selector(openDocument(_:)), "o", target: self)
        file.addItem(.separator())
        add(file, "Close Window", #selector(NSWindow.performClose(_:)), "w")

        // Copy/Paste go to the terminal view; the editor inside handles everything else.
        let edit = submenu("Edit")
        add(edit, "Copy", NSSelectorFromString("copy:"), "c")
        add(edit, "Paste", NSSelectorFromString("paste:"), "v")
        add(edit, "Select All", #selector(NSText.selectAll(_:)), "a")

        let view = submenu("View")
        add(view, "Increase Font Size", #selector(TerminalWindowController.biggerFont(_:)), "+")
        add(view, "Decrease Font Size", #selector(TerminalWindowController.smallerFont(_:)), "-")
        add(view, "Actual Size", #selector(TerminalWindowController.resetFont(_:)), "0")
        view.addItem(.separator())
        let schemeItem = view.addItem(withTitle: "Color Scheme (New Windows)", action: nil, keyEquivalent: "")
        let schemeMenu = NSMenu(title: "Color Scheme")
        schemeMenu.delegate = self
        for theme in Theme.all {
            let item = schemeMenu.addItem(withTitle: theme.name, action: #selector(chooseTheme(_:)), keyEquivalent: "")
            item.target = self
        }
        schemeItem.submenu = schemeMenu
        view.addItem(.separator())
        add(view, "Enter Full Screen", #selector(NSWindow.toggleFullScreen(_:)), "f", [.command, .control])

        let window = submenu("Window")
        add(window, "Minimize", #selector(NSWindow.performMiniaturize(_:)), "m")
        add(window, "Zoom", #selector(NSWindow.performZoom(_:)))
        NSApp.windowsMenu = window

        return main
    }
}
