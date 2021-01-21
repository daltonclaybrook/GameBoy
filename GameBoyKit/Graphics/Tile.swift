typealias TileNumber = UInt8

struct Tile {
    /// The address of the tile in VRAM
    let address: Address

    init(address: Address) {
        self.address = address
    }

    init(tileNumber: TileNumber, in data: LCDControl.TileDataRange) {
        self.address = data.getAddressForTile(number: tileNumber)
    }
}

extension Tile {
    /// Get the color palette index (aka the "color number") at a given x/y offset
    /// inside the receiver tile. This color number can be combined with the data
    /// from a color palette to determine a pixel color.
    func getColorNumber(in vram: VRAM, xOffset: UInt8, yOffset: UInt8) -> ColorNumber {
        let pixelWord = vram.readWord(address: address + Address(yOffset) * 2, privileged: true)

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
    func getColorNumber(in vram: VRAM, xOffset: UInt8, xFlipped: Bool, yOffset: UInt8, yFlipped: Bool) -> ColorNumber {
        let adjustedX = xFlipped ? 7 - xOffset : xOffset
        let adjustedY = yFlipped ? 7 - yOffset : yOffset
        return getColorNumber(in: vram, xOffset: adjustedX, yOffset: adjustedY)
    }
}
