/// An RGB color palette used by the Game Boy Color
public struct CGBPalette {
}

/// Represents one RGB color in a four-color palette on CGB
public struct CGBPaletteColor: RawRepresentable {
    public let rawValue: UInt16

    public init(rawValue: UInt16) {
        self.rawValue = rawValue
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
