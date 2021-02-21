/// Represents a color palette on
public protocol PaletteType {
    func getColor(for number: ColorNumber) -> Color
}

/// An monochrome color palette used by the Game Boy (DMG)
public struct MonochromePalette: RawRepresentable, PaletteType {
    public var rawValue: Byte

    public init(rawValue: Byte) {
        self.rawValue = rawValue
    }

    public init() {
        self.init(rawValue: 0)
    }

    /// Returns a monochrome color for a given color number
    public func getColor(for number: ColorNumber) -> Color {
        let shift = (number & 0x03) * 2
        let colorShadeIndex = (rawValue >> shift) & 0x03
        // Possible values are:
        // 0 => 255 (white)
        // 1 => 170 (light gray)
        // 2 => 85 (dark gray)
        // 3 => 0 (black)
        let grayValue = 255 - colorShadeIndex * 85
        return Color(red: grayValue, green: grayValue, blue: grayValue)
    }
}

/// An RGB color palette used by the Game Boy Color
public struct ColorPalette: RawRepresentable, PaletteType {
    public var rawValue: UInt64

    public init(rawValue: UInt64) {
        self.rawValue = rawValue
    }

    public init() {
        self.init(rawValue: 0)
    }

    public func getColor(for number: ColorNumber) -> Color {
        let shift = (number & 0x03) * 16
        let colorRawValue = (rawValue >> shift) & 0xffff
        let paletteColor = PaletteColor(rawValue: UInt16(colorRawValue))
        return paletteColor.color
    }

    public func getByte(atOffset offset: Int) -> Byte {
        precondition(offset >= 0 && offset < 8)
        let shift = offset * 8
        return Byte((rawValue >> shift) & 0xff)
    }

    public mutating func setByte(_ byte: Byte, atOffset offset: Int) {
        precondition(offset >= 0 && offset < 8)
        let shift = offset * 8
        let rawValueWithZeroedByte = rawValue & ~(0xff << shift)
        rawValue = rawValueWithZeroedByte | (UInt64(byte) << shift)
    }
}

/// Represents one RGB color in a four-color palette on CGB
public struct PaletteColor: RawRepresentable {
    public var rawValue: UInt16

    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }
}

public extension PaletteColor {
    var color: Color {
        Color(red: redByte, green: greenByte, blue: blueByte)
    }

    var redByte: Byte {
        getEightBitsScaledFromFiveBits(bits: rawValue & 0x1f)
    }

    var greenByte: Byte {
        getEightBitsScaledFromFiveBits(bits: (rawValue >> 5) & 0x1f)
    }

    var blueByte: Byte {
        getEightBitsScaledFromFiveBits(bits: (rawValue >> 10) & 0x1f)
    }

    // MARK: - Helpers

    /// Each color is five bits. This function takes a 5-bit color and scales it up to a full eight bits.
    /// e.g. if the provided color is `0x1f` (all bits set), it will be scaled up to `0xff`.
    private func getEightBitsScaledFromFiveBits(bits: UInt16) -> Byte {
        let normalized = Double(bits) / 0x1f
        return Byte(normalized * Double(Byte.max))
    }
}
