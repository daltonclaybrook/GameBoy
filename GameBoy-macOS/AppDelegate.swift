import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet var gameBoyItem: NSMenuItem!
    @IBOutlet var gameBoyColorItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        updateButtonsWithSystemSelection()
    }

    func applicationOpenUntitledFile(_ sender: NSApplication) -> Bool {
        NSDocumentController.shared.openDocument(self)
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    // MARK: - Actions

    @IBAction func gameBoyItemClicked(_ sender: Any) {
        SystemSelection.shared.updateSystem(.dmg)
        updateButtonsWithSystemSelection()
    }

    @IBAction func gameBoyColorItemClicked(_ sender: Any) {
        SystemSelection.shared.updateSystem(.cgb)
        updateButtonsWithSystemSelection()
    }

    // MARK: - Helpers

    private func updateButtonsWithSystemSelection() {
        switch SystemSelection.shared.system {
        case .dmg:
            gameBoyItem.state = .on
            gameBoyColorItem.state = .off
        case .cgb:
            gameBoyItem.state = .off
            gameBoyColorItem.state = .on
        }
    }
}
