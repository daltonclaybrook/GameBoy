typealias TileNumber = UInt8

struct Tile {
    /// The address of the tile in VRAM tile data. On CGB, this alone is not enough info to get the
    /// tile data because it may be stored in either bank zero or one.
    let dataAddress: Address
    /// The bank number of the to get tile data from. On DMG, this is always zero. It may be zero or
    /// one on CGB.
    let bankNumber: VRAM.BankNumber
    /// Whether the tile is flipped horizontally. This can be informed by the sprite attributes or the BG
    /// map attributes.
    let isXFlipped: Bool
    /// Whether the tile is flipped vertically. This can be informed by the sprite attributes or the BG
    /// map attributes.
    let isYFlipped: Bool
}

extension Tile {
    /// Get the color palette index (aka the "color number") at a given x/y offset
    /// inside the receiver tile. This color number can be combined with the data
    /// from a color palette to determine a pixel color.
    func getColorNumber(vramView: VRAMView, xOffset: UInt8, yOffset: UInt8) -> ColorNumber {
        let preFlippedX = isXFlipped ? 7 - xOffset : xOffset
        let preFlippedY = isYFlipped ? 7 - yOffset : yOffset
        return getColorNumber(vramView: vramView, preFlippedXOffset: preFlippedX, preFlippedYOffset: preFlippedY)
    }

    // MARK: - Helpers

    private func getColorNumber(vramView: VRAMView, preFlippedXOffset: UInt8, preFlippedYOffset: UInt8) -> ColorNumber {
        let pixelWord = vramView.readWord(address: dataAddress + Address(preFlippedYOffset) * 2)

        // Example:
        // xOffset == 2
        // pixelWord: 00100000_00100000
        //     high bit ^        ^ low bit
        //              >>>>>>_>>>>>>1
        //                       >>>>>1

        let lowShift = 7 - preFlippedXOffset
        let highShift = lowShift + 7
        let pixelColorNumber = (pixelWord >> highShift) & 0x02 | (pixelWord >> lowShift) & 0x01
        return ColorNumber(truncatingIfNeeded: pixelColorNumber)
    }
}
