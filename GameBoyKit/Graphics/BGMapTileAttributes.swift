/// On the Game Boy Color, instead of containing additional BG maps, VRAM bank 1 contains
/// tile attributes in the range `0x9800...0x9fff`.
public struct BGMapTileAttributes: RawRepresentable {
    public let rawValue: Byte

    public init(rawValue: Byte) {
        self.rawValue = rawValue
    }
}

public extension BGMapTileAttributes {
    enum Priority: UInt8 {
        /// The priority is deferred to any overlapping sprites
        case useOAM
        /// This tile has priority over sprites, regardless of their priority
        case hasPriority
    }

    /// BG palette number 0-7 to use for the tile
    var backgroundPaletteNumber: UInt8 {
        rawValue & 0x07
    }

    /// The VRAM bank used to get the tile data for this tile
    var tileVRAMBankNumber: VRAM.BankNumber {
        VRAM.BankNumber(rawValue: (rawValue >> 3) & 0x01)!
    }

    /// Whether the tile is flipped horizontally
    var isXFlipped: Bool {
        (rawValue >> 5) & 0x01 == 1
    }

    /// Whether the tile is flipped vertically
    var isYFlipped: Bool {
        (rawValue >> 6) & 0x01 == 1
    }

    /// Whether this tile is displayed above sprites, or the sprite priority value is respected
    var priority: Priority {
        Priority(rawValue: rawValue >> 7 & 0x01)!
    }
}
