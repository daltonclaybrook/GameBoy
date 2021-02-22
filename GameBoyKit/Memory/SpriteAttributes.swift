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

    struct Flags: RawRepresentable {
        public let rawValue: Byte

        public init(rawValue: Byte) {
            self.rawValue = rawValue
        }
    }

    enum BackgroundPriority: UInt8 {
        /// The sprite/object appears in front of the background and window
        case aboveBackground
        /// The sprite/object appears behind the background and window, though,
        /// BG color 0 is always behind the object.
        case beneathBackground
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

    var flags: Flags {
        Flags(rawValue: getByteAtIndex(Attributes.flags))
    }

    // MARK: - Helpers

    private func getByteAtIndex(_ index: Int) -> Byte {
        rawValue[rawValue.startIndex.advanced(by: index)]
    }
}

public extension SpriteAttributes.Flags {
    /// CGB color palette index 0-7
    var cgbPaletteNumber: UInt8 {
        rawValue & 0x07
    }

    /// The VRAM bank used to get the tile data for this sprite. Only available in CGB.
    var tileVRAMBankNumber: VRAM.BankNumber {
        VRAM.BankNumber(rawValue: (rawValue >> 3) & 0x01)!
    }

    /// DMG has only two color palettes for sprites, so this value is either 0 or 1
    var monochromePaletteNumber: UInt8 {
        (rawValue >> 4) & 0x01
    }

    /// Whether the sprite is flipped horizontally
    var isXFlipped: Bool {
        (rawValue >> 5) & 0x01 == 1
    }

    /// Whether the sprite is flipped vertically
    var isYFlipped: Bool {
        (rawValue >> 6) & 0x01 == 1
    }

    /// Whether this sprite is displayed above or below the background
    var backgroundPriority: SpriteAttributes.BackgroundPriority {
        SpriteAttributes.BackgroundPriority(rawValue: (rawValue >> 7) & 0x01)!
    }

    func getBankNumber(for system: GameBoy.System) -> VRAM.BankNumber {
        switch system {
        case .dmg:
            return .zero
        case .cgb:
            return tileVRAMBankNumber
        }
    }
}

extension SpriteAttributes {
    var largeTopAndBottomTileNumbers: [UInt8] {
        let tileNumbers = [
            tileNumber & 0xfe,
            tileNumber | 0x01
        ]
        return flags.isYFlipped ? tileNumbers.reversed() : tileNumbers
    }

    func getIsOnScreen(objectSize: LCDControl.ObjectSize) -> Bool {
        let xRange = (1..<UInt8(ScreenConstants.width) + objectSize.width)
        guard xRange.contains(position.x) else { return false }
        let minY = objectSize.maxHeight - objectSize.height + 1
        let yRange = (minY..<UInt8(ScreenConstants.height) + objectSize.maxHeight)
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
        case .large:
            let index = Int(yOffsetInSprite / objectSize.minHeight)
            return largeTopAndBottomTileNumbers[index]
        }
    }
}
