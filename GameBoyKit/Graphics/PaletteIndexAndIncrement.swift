/// Registers `0xff68` and `0xff6a` contain values of this type used to indicate which CGB color
/// byte can currently be read/written, and whether that index should increment on write.
public struct PaletteIndexAndIncrement: RawRepresentable {
    public var rawValue: Byte

    public init(rawValue: Byte) {
        self.rawValue = rawValue
    }
}

public extension PaletteIndexAndIncrement {
    /// The index of the current color palette that can be read/written. Values in the range `0x00...0x3f`.
    var index: UInt8 {
        rawValue & 0x3f
    }

    /// Whether the current index should be auto-incremented after writing a new value to the palette data register
    var autoIncrementOnWrite: Bool {
        (rawValue >> 7) & 0x01 == 1
    }

    mutating func incrementIndex() {
        guard index < 0x3f else { return }
        rawValue += 1
    }
}
