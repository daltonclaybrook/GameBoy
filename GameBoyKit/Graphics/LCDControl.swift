public struct LCDControl: RawRepresentable {
    public let rawValue: UInt8

    enum TileMapDisplay {
        case low // 0x9800-0x9Bff
        case high // 0x9c00-0x9fff
    }

    enum TileData {
        case low // 0x8000-0x8fff
        case high // 0x8800-97ff
    }

    public enum ObjectSize {
        case small // 8x8
        case large // 8x16
    }

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
}

extension LCDControl {
    var displayEnabled: Bool {
        rawValue & 0x80 != 0
    }

    var windowTileMapDisplay: TileMapDisplay {
        rawValue & 0x40 != 0 ? .high : .low
    }

    var windowDisplayEnabled: Bool {
        rawValue & 0x20 != 0
    }

    var selectedTileDataForBackgroundAndWindow: TileData {
        // this order is confusing, but if the bit is set high,
        // we use the lower address range
        rawValue & 0x10 != 0 ? .low : .high
    }

    var tileDataForObjects: TileData {
        // Objects are always stored in 0x8000-0x8fff
        .low
    }

    var backgroundTileMapDisplay: TileMapDisplay {
        rawValue & 0x08 != 0 ? .high : .low
    }

    var objectSize: ObjectSize {
        rawValue & 0x04 != 0 ? .large : .small
    }

    var objectDisplayEnabled: Bool {
        rawValue & 0x02 != 0
    }

    /// This flag has multiple meanings depending on CGB mode
    var backgroundDisplayFlag: Bool {
        rawValue & 0x01 != 0
    }
}

extension LCDControl.TileMapDisplay {
    var mapDataRange: ClosedRange<Address> {
        switch self {
        case .low:
            return (0x9800...0x9bff)
        case .high:
            return (0x9c00...0x9fff)
        }
    }
}

extension LCDControl.TileData {
    var tileDataRange: ClosedRange<Address> {
        switch self {
        case .low:
            return (0x8000...0x8fff)
        case .high:
            return (0x8800...0x97ff)
        }
    }

    func getAddressForTile(number: TileNumber) -> Address {
        switch self {
        case .low:
            return 0x8000 + Address(number) * 0x10 // each tile is 0x10 (16) bytes
        case .high:
            // Provided index is converted to a signed int so values over 127 result
            // in a negative offset from 0x9000
            let offset = Int16(Int8(bitPattern: number)) * 0x10
            return (0x9000 as Address).signedAdd(value: offset)
        }
    }
}

extension LCDControl.ObjectSize {
    var width: UInt8 {
        return 8
    }

    var height: UInt8 {
        switch self {
        case .small:
            return 8
        case .large:
            return 16
        }
    }

    /// Returns the height of a sprite in large mode. This value is always used to
    /// adjust the y-position of a sprite on screen.
    var maxHeight: UInt8 {
        16
    }
}
