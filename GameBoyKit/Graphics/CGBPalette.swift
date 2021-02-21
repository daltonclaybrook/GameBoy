/// An RGB color palette used by the Game Boy Color
public struct CGBPalette {
    public private(set) var allColors: [CGBPaletteColor] = [
        CGBPaletteColor(rawValue: 0x00),
        CGBPaletteColor(rawValue: 0x00),
        CGBPaletteColor(rawValue: 0x00),
        CGBPaletteColor(rawValue: 0x00)
    ]

    public func getByte(atByteOffset byteOffset: Int) -> Byte {
        precondition(byteOffset >= 0 && byteOffset < allColors.count * 2)
        let colorOffset = byteOffset / 2
        let offsetInColor = byteOffset % 2
        return allColors[colorOffset].getByte(atOffset: offsetInColor)
    }

    public mutating func setByte(_ byte: Byte, atByteOffset byteOffset: Int) {
        precondition(byteOffset >= 0 && byteOffset < allColors.count * 2)
        let colorOffset = byteOffset / 2
        let offsetInColor = byteOffset % 2
        allColors[colorOffset].setByte(byte, atOffset: offsetInColor)
    }
}

/// Represents one RGB color in a four-color palette on CGB
public struct CGBPaletteColor: RawRepresentable {
    public private(set) var rawValue: UInt16

    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }

    public func getByte(atOffset offset: Int) -> Byte {
        switch offset {
        case 0:
            return Byte(rawValue & 0xff)
        case 1:
            return Byte(rawValue >> 8)
        default:
            fatalError("Offset \(offset) outside of acceptable range")
        }
    }

    public mutating func setByte(_ byte: Byte, atOffset offset: Int) {
        switch offset {
        case 0:
            rawValue = (rawValue & 0xff00) | UInt16(byte)
        case 1:
            rawValue = (rawValue & 0x00ff) | (UInt16(byte) << 8)
        default:
            fatalError("Offset \(offset) outside of acceptable range")
        }
    }
}

public extension CGBPaletteColor {
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
