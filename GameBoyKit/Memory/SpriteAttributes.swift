public struct SpriteAttributes: RawRepresentable {
    public static let bytesPerSprite = 4
    public let rawValue: ArraySlice<Byte>

    public init(rawValue: ArraySlice<Byte>) {
        guard rawValue.count == Self.bytesPerSprite else {
            fatalError("Sprite attributes must be initialized with exactly 4 bytes")
        }
        self.rawValue = rawValue
    }
}

public extension SpriteAttributes {
    private enum Attributes {
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
        /// BG color 0 is always behind the object.
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

extension SpriteAttributes {
    var monochromePalette: ColorPalettes.Palette {
        switch monochromePaletteNumber {
        case 0:
            return .monochromeObject0
        case 1:
            return .monochromeObject1
        default:
            fatalError("Palette number is invalid")
        }
    }

    func getIsOnScreen(objectSize: LCDControl.ObjectSize) -> Bool {
        let xRange = (1..<UInt8(Constants.screenWidth) + objectSize.width)
        guard xRange.contains(position.x) else { return false }
        let minY = objectSize.maxHeight - objectSize.height + 1
        let yRange = (minY..<UInt8(Constants.screenHeight) + objectSize.maxHeight)
        guard yRange.contains(position.y) else { return false }
        return true
    }

    /// The y-position of a sprite in OAM is offset by 16 pixels. For example, if the
    /// y-position in OAM is 0, the real y-position of the sprite relative to the screen
    /// is -16. Since sprites have a max height of 16, the full sprite is off-screen and
    /// will not be rendered. This function applies this 16-pixel offset and returns a
    /// `Range` of screen lines where the sprite is rendered. A portion of this range
    /// may be negative.
    /// - Parameter objectSize: The size of all sprites
    func getLineRangeRelativeToScreen(objectSize: LCDControl.ObjectSize) -> Range<Int16> {
        let yPosition = Int16(position.y)
        let lineRange = yPosition..<(yPosition + Int16(objectSize.height))
        return lineRange.shifted(by: -Int16(objectSize.maxHeight))
    }

    func getXRangeRelativeToScreen(objectSize: LCDControl.ObjectSize) -> Range<Int16> {
        let xPosition = Int16(position.x)
        let xRange = xPosition..<(xPosition + Int16(objectSize.width))
        return xRange.shifted(by: -Int16(objectSize.width))
    }

    func getTileNumber(yOffsetInSprite: UInt8, objectSize: LCDControl.ObjectSize) -> UInt8 {
        switch objectSize {
        case .small:
            return tileNumber
        case .large where yOffsetInSprite < objectSize.maxHeight / 2:
            return tileNumber & 0xfe
        case .large:
            return tileNumber | 0x01
        }
    }
}
