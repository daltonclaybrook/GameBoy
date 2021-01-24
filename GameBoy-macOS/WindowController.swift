import Cocoa

protocol GameWindowControllerDelegate: AnyObject {
    func windowController(_ controller: GameWindowController, keyCodePressed keyCode: UInt16)
    func windowController(_ controller: GameWindowController, keyCodeReleased keyCode: UInt16)
}

final class GameWindowController: NSWindowController {
    weak var delegate: GameWindowControllerDelegate?

    override func keyDown(with event: NSEvent) {
        delegate?.windowController(self, keyCodePressed: event.keyCode)
    }

    override func keyUp(with event: NSEvent) {
        delegate?.windowController(self, keyCodeReleased: event.keyCode)
    }
}
