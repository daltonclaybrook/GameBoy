import Cocoa

protocol WindowControllerDelegate: AnyObject {
    func windowController(_ controller: WindowController, keyCodePressed keyCode: UInt16)
    func windowController(_ controller: WindowController, keyCodeReleased keyCode: UInt16)
}

final class WindowController: NSWindowController {
    weak var delegate: WindowControllerDelegate?

    override func keyDown(with event: NSEvent) {
        delegate?.windowController(self, keyCodePressed: event.keyCode)
    }

    override func keyUp(with event: NSEvent) {
        delegate?.windowController(self, keyCodeReleased: event.keyCode)
    }
}
