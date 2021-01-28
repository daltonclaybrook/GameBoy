typealias TileNumber = UInt8

struct Tile {
    /// The address of the tile in VRAM
    let address: Address
}

extension Tile {
    /// Get the color palette index (aka the "color number") at a given x/y offset
    /// inside the receiver tile. This color number can be combined with the data
    /// from a color palette to determine a pixel color.
    func getColorNumber(vramView: VRAMView, xOffset: UInt8, yOffset: UInt8) -> ColorNumber {
        let pixelWord = vramView.readWord(address: address + Address(yOffset) * 2)

        // Example:
        // xOffset == 2
        // pixelWord: 00100000_00100000
        //     high bit ^        ^ low bit
        //              >>>>>>_>>>>>>1
        //                       >>>>>1

        let lowShift = 7 - xOffset
        let highShift = lowShift + 7
        let pixelColorNumber = (pixelWord >> highShift) & 0x02 | (pixelWord >> lowShift) & 0x01
        return ColorNumber(truncatingIfNeeded: pixelColorNumber)
    }

    /// Get the color palette index (aka the "color number") at a given x/y offset
    /// inside the receiver tile. This color number can be combined with the data
    /// from a color palette to determine a pixel color.
    /// - Parameters:
    ///   - xFlipped: Whether or not to flip the tile along the x-axis before determining
    ///   the color number
    ///   - yFlipped: Whether or not to flip the tile along the y-axis before determining
    ///   the color number
    func getColorNumber(vramView: VRAMView, xOffset: UInt8, xFlipped: Bool, yOffset: UInt8, yFlipped: Bool) -> ColorNumber {
        let adjustedX = xFlipped ? 7 - xOffset : xOffset
        let adjustedY = yFlipped ? 7 - yOffset : yOffset
        return getColorNumber(vramView: vramView, xOffset: adjustedX, yOffset: adjustedY)
    }
}
