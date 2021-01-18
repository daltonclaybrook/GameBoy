public struct Joypad: RawRepresentable {
    public private(set) var rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public init() {
        // Since a button is considered "selected" if its corresponding bit
        // is 0, setting all bits high means no buttons are selected.
        self.init(rawValue: 0xff)
    }

    public mutating func update(byte: Byte) {
        // set high nibble and preserve low nibble
        rawValue = (byte & 0xf0) | (rawValue & 0x0f)
    }
}
