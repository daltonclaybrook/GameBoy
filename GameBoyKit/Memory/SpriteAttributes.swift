public struct SpriteAttributes: RawRepresentable {
    public let rawValue: ArraySlice<Byte>

    public init(rawValue: ArraySlice<Byte>) {
        guard rawValue.count == 4 else {
            fatalError("Sprite attributes must be initialized with exactly 4 bytes")
        }
        self.rawValue = rawValue
    }
}

public extension SpriteAttributes {
    enum Attributes {
        static let yPosition = 0
        static let xPosition = 1
        static let tileNumber = 2
        static let flags = 3
    }

    struct Position {
        public let y: UInt8
        public let x: UInt8
    }

    enum BackgroundPriority: UInt8 {
        /// The sprite/object appears in front of the background and window
        case aboveBackground = 0
        /// The sprite/object appears behind the background and window, though,
        /// BG color 0 is always behind the object. I'm not sure if this makes any
        /// material difference since object color 0 is always transparent...
        case beneathBackground = 1
    }

    var position: Position {
        Position(
            y: getByteAtIndex(Attributes.yPosition),
            x: getByteAtIndex(Attributes.xPosition)
        )
    }

    var tileNumber: UInt8 {
        getByteAtIndex(Attributes.tileNumber)
    }

    /// Only lower 1 bit is used
    var monochromePaletteNumber: Byte {
        let flags = getByteAtIndex(Attributes.flags)
        return (flags >> 4) & 0x01
    }

    var isXFlipped: Bool {
        let flags = getByteAtIndex(Attributes.flags)
        return (flags >> 5) & 0x01 == 1
    }

    var isYFlipped: Bool {
        let flags = getByteAtIndex(Attributes.flags)
        return (flags >> 6) & 0x01 == 1
    }

    var backgroundPriority: BackgroundPriority {
        let flags = getByteAtIndex(Attributes.flags)
        let rawPriority = (flags >> 7) & 0x01
        return BackgroundPriority(rawValue: rawPriority)!
    }

    // MARK: - Helpers

    private func getByteAtIndex(_ index: Int) -> Byte {
        rawValue[rawValue.startIndex.advanced(by: index)]
    }
}
