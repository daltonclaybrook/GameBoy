import Cocoa
import GameBoyKit

final class CartridgeDocument: NSDocument {
    private let storyboardID: NSString = "GameWindowController"
    private let saveQueue = DispatchQueue(
        label: "com.daltonclaybrook.GameBoy.CartridgeDocument.SaveQueue",
        qos: .userInitiated
    )

    private var viewController: GameViewController?
    private var cartridge: CartridgeType? = nil
    private var header: CartridgeHeader?
    private var queuedSaveExternalRAMBytes: [Byte]? = nil
    private var latestSavedExternalRAMBytes: [Byte]? = nil
    private var timer: Foundation.Timer?

    override func read(from data: Data, ofType typeName: String) throws {
        self.latestSavedExternalRAMBytes = loadSaveFileBytes()
        let romBytes = [Byte](data)
        let (cartridge, header) = try CartridgeFactory.makeCartridge(
            romBytes: romBytes,
            externalRAMBytes: latestSavedExternalRAMBytes
        )
        self.cartridge = cartridge
        self.cartridge?.delegate = self
        self.header = header

        timer?.invalidate()
        timer = .scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.saveQueue.async {
                self?.attemptSaveLatestGameData()
            }
        }
    }

    override func makeWindowControllers() {
        guard let cartridge = cartridge else {
            // I don't think this should happen in prod
            return assertionFailure("No cartridge is available.")
        }

        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        guard let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(storyboardID)) as? GameWindowController else {
            fatalError("Could not instantiate game window controller")
        }
        guard let viewController = windowController.contentViewController as? GameViewController else {
            fatalError("Game window controller did not contain a game view controller")
        }
        addWindowController(windowController)
        self.viewController = viewController
        windowController.delegate = viewController
        viewController.loadCartridge(cartridge)
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
