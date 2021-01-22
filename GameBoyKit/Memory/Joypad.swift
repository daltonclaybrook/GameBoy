public final class Joypad: RawRepresentable {
    public enum Button {
        case right
        case left
        case up
        case down
        case a
        case b
        case select
        case start
    }

    public private(set) var rawValue: UInt8
    private var pressedButtons: Set<Button> = []

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public convenience init() {
        // Since a button is considered "selected" if its corresponding bit
        // is 0, setting all bits high means no buttons are selected.
        self.init(rawValue: 0xff)
    }

    public func update(byte: Byte) {
        // set high nibble and preserve low nibble
        rawValue = (byte & 0xf0) | (rawValue & 0x0f)
    }

    public func buttonWasPressed(_ button: Button) {
        pressedButtons.insert(button)
    }

    public func buttonWasReleased(_ button: Button) {
        pressedButtons.remove(button)
    }
}
