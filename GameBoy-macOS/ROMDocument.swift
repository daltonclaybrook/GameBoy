import Cocoa
import GameBoyKit

final class ROMDocument: NSDocument {
    private let storyboardID: NSString = "GameWindowController"

    private var viewController: GameViewController?
    private var cartridge: CartridgeType? = nil
    private var saveData: SaveData? = nil

    override func read(from data: Data, ofType typeName: String) throws {
        let (cartridge, header) = try CartridgeFactory.makeCartridge(romBytes: [Byte](data))
        self.cartridge = cartridge
        self.saveData = loadSaveData(ramSize: header.ramSize)
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
        viewController.loadCartridge(cartridge, saveData: saveData)
    }

    override func save(_ sender: Any?) {
        Swift.print("requested save")
        do {
            try saveLatestGameData()
        } catch let error {
            Swift.print("Error saving file: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    private func loadSaveData(ramSize: RAMSize) -> SaveData? {
        guard let saveFileURL = getSaveFileURL() else { return nil }
        guard FileManager.default.fileExists(atPath: saveFileURL.path) else {
            return nil
        }
        guard let saveData = try? Data(contentsOf: saveFileURL) else {
            assertionFailure("Unable to read save data at path: \(saveFileURL.path)")
            return nil
        }
        return try? SaveData(bytes: [Byte](saveData), ramSize: ramSize)
    }

    private func saveLatestGameData() throws {
        guard let saveFileURL = getSaveFileURL(),
              let saveData = viewController?.getCurrentSaveData() else { return }
        let data = Data(saveData.allBytes)
        try data.write(to: saveFileURL, options: .atomic)
    }

    private func getSaveFileURL() -> URL? {
        guard let fileURL = fileURL else { return nil }
        return fileURL.deletingPathExtension().appendingPathExtension("sav")
    }
}
