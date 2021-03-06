import Cocoa
import GameBoyKit

final class CartridgeDocument: NSDocument {
    private let storyboardID = "GameWindowController"
    private let saveQueue = DispatchQueue(
        label: "com.daltonclaybrook.GameBoy.CartridgeDocument.SaveQueue",
        qos: .userInitiated
    )

    private var viewController: GameViewController?
    private var cartridgeInfo: CartridgeInfo? = nil
    private var queuedSaveExternalRAMBytes: [Byte]? = nil
    private var latestSavedExternalRAMBytes: [Byte]? = nil
    private var timer: Foundation.Timer?

    override func read(from data: Data, ofType typeName: String) throws {
        self.latestSavedExternalRAMBytes = loadSaveFileBytes()
        let romBytes = [Byte](data)
        let cartridgeInfo = try CartridgeFactory.makeCartridge(
            romBytes: romBytes,
            externalRAMBytes: latestSavedExternalRAMBytes
        )
        self.cartridgeInfo = cartridgeInfo
        self.cartridgeInfo?.cartridge.delegate = self

        timer?.invalidate()
        timer = .scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.saveQueue.async {
                self?.attemptSaveLatestGameData()
            }
        }
    }

    override func makeWindowControllers() {
        guard let cartridgeInfo = cartridgeInfo else {
            // I don't think this should happen in prod
            return assertionFailure("No cartridge is available.")
        }

        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        guard let windowController = storyboard.instantiateController(withIdentifier: storyboardID) as? GameWindowController else {
            fatalError("Could not instantiate game window controller")
        }
        guard let viewController = windowController.contentViewController as? GameViewController else {
            fatalError("Game window controller did not contain a game view controller")
        }
        addWindowController(windowController)
        self.viewController = viewController
        windowController.delegate = viewController
        viewController.loadCartridge(cartridgeInfo)
    }

    // MARK: - Helpers

    private func loadSaveFileBytes() -> [Byte]? {
        guard let saveFileURL = getSaveFileURL() else { return nil }
        guard FileManager.default.fileExists(atPath: saveFileURL.path) else {
            return nil
        }
        guard let saveData = try? Data(contentsOf: saveFileURL) else {
            assertionFailure("Unable to read save data at path: \(saveFileURL.path)")
            return nil
        }
        return [Byte](saveData)
    }

    private func attemptSaveLatestGameData() {
        guard let saveFileURL = getSaveFileURL(),
              let queuedSaveExternalRAMBytes = queuedSaveExternalRAMBytes,
              queuedSaveExternalRAMBytes != latestSavedExternalRAMBytes
        else { return }

        self.queuedSaveExternalRAMBytes = nil
        self.latestSavedExternalRAMBytes = queuedSaveExternalRAMBytes

        let data = Data(queuedSaveExternalRAMBytes)
        do {
            try data.write(to: saveFileURL, options: .atomic)
        } catch let error {
            Swift.print("Failed to save data with error: \(error.localizedDescription)")
        }
    }

    private func getSaveFileURL() -> URL? {
        guard let fileURL = fileURL else { return nil }
        return fileURL.deletingPathExtension().appendingPathExtension("sav")
    }
}

extension CartridgeDocument: CartridgeDelegate {
    func cartridge(_ cartridge: CartridgeType, didSaveExternalRAM bytes: [Byte]) {
        saveQueue.async { [weak self] in
            self?.queuedSaveExternalRAMBytes = bytes
        }
    }
}
