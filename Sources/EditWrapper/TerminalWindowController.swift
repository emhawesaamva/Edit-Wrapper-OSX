import AppKit
import SwiftTerm

final class TerminalWindowController: NSWindowController, NSWindowDelegate, LocalProcessTerminalViewDelegate {
    private let terminal: LocalProcessTerminalView
    private var fontSize: CGFloat
    private static let defaultFontSize: CGFloat = 13
    var onClose: ((TerminalWindowController) -> Void)?

    init(editPath: String, files: [String]) {
        fontSize = Self.defaultFontSize
        terminal = LocalProcessTerminalView(frame: NSRect(x: 0, y: 0, width: 900, height: 600))
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false)
        window.title = appName
        window.contentView = terminal
        window.center()
        super.init(window: window)
        window.delegate = self
        terminal.processDelegate = self
        terminal.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        startEdit(editPath: editPath, files: files)
        window.makeFirstResponder(terminal)
    }

    required init?(coder: NSCoder) { fatalError("unsupported") }

    private func startEdit(editPath: String, files: [String]) {
        var env = ProcessInfo.processInfo.environment
        env["TERM"] = "xterm-256color"
        env["COLORTERM"] = "truecolor"
        env["LANG"] = env["LANG"] ?? "en_US.UTF-8"
        let envList = env.map { "\($0.key)=\($0.value)" }
        terminal.startProcess(
            executable: editPath,
            args: files,
            environment: envList,
            execName: nil)
    }

    // MARK: View menu

    @objc func biggerFont(_ sender: Any?) { setFontSize(fontSize + 1) }
    @objc func smallerFont(_ sender: Any?) { setFontSize(max(6, fontSize - 1)) }
    @objc func resetFont(_ sender: Any?) { setFontSize(Self.defaultFontSize) }

    private func setFontSize(_ size: CGFloat) {
        fontSize = size
        terminal.font = NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
    }

    // MARK: NSWindowDelegate

    func windowWillClose(_ notification: Notification) { onClose?(self) }

    // MARK: LocalProcessTerminalViewDelegate

    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}
    func setTerminalTitle(source: LocalProcessTerminalView, title: String) {}
    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}

    func processTerminated(source: TerminalView, exitCode: Int32?) {
        DispatchQueue.main.async { [weak self] in self?.window?.close() }
    }
}
