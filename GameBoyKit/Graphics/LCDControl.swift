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

    enum ObjectSize {
        case small // 8x8
        case large // 8x16
    }

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
}

extension LCDControl {
    var displayEnabled: Bool {
        return rawValue & 0x80 != 0
    }

    var windowTileMapDisplay: TileMapDisplay {
        return rawValue & 0x40 != 0 ? .high : .low
    }

    var windowDisplayEnabled: Bool {
        return rawValue & 0x20 != 0
    }

    var selectedTileDataForBackgroundAndWindow: TileData {
        // this order is confusing, but if the bit is set high,
        // we use the lower address range
        return rawValue & 0x10 != 0 ? .low : .high
    }

    var backgroundTileMapDisplay: TileMapDisplay {
        return rawValue & 0x08 != 0 ? .high : .low
    }

    var objectSize: ObjectSize {
        return rawValue & 0x04 != 0 ? .large : .small
    }

    var objectDisplayEnabled: Bool {
        return rawValue & 0x02 != 0
    }

    /// This flag has multiple meanings depending on CGB mode
    var backgroundDisplayFlag: Bool {
        return rawValue & 0x01 != 0
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

    func getTileAddress(atIndex: UInt8) -> Address {
        switch self {
        case .low:
            return 0x8000 + Address(atIndex) * 0x10 // each tile is 0x10 (16) bytes
        case .high:
            // Provided index is converted to a signed int so values over 127 result
            // in a negative offset from 0x9000
            let offset = Int8(bitPattern: atIndex)
            return (0x9000 as Address) &+ offset
        }
    }
}
