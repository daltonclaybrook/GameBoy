import Cocoa
import GameBoyKit

final class ROMDocument: NSDocument {
    private let storyboardID: NSString = "GameWindowController"

    var cartridge: CartridgeType? = nil

    override func read(from data: Data, ofType typeName: String) throws {
        self.cartridge = CartridgeFactory.makeCartridge(romBytes: [Byte](data))
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
        windowController.delegate = viewController
        viewController.loadCartridge(cartridge)
    }
}
