import Foundation

public final class PPU {
    /// Represents information about a pixel that might be rendered to the
    /// screen or might be overridden by another pixel based on priority.
    fileprivate enum PixelInfo {
        case background(Color, colorNumber: ColorNumber)
        case sprite(Color)
    }

    private let renderer: Renderer
    let io: IO
    let vram: VRAM
    let oam: OAM

    private let oamSearchDuration: Cycles = 20
    private let lcdTransferDuration: Cycles = 43
    private let hBlankDuration: Cycles = 51
    private let vBlankLineCount = 10
    private let mapWidthInTiles: UInt16 = 32 // map is 32x32 tiles

    private let vBlankDuration: Cycles
    private let cyclesPerLine: Cycles
    private var isDisplayEnabled = false
    private var cyclesRemaining: Cycles
    private var pixelBuffer = [Byte](repeating: .max, count: Constants.screenWidth * Constants.screenHeight * 4)

    init(renderer: Renderer, io: IO, vram: VRAM, oam: OAM) {
        self.renderer = renderer
        self.io = io
        self.vram = vram
        self.oam = oam
        self.cyclesRemaining = oamSearchDuration
        io.lcdStatus.mode = .searchingOAMRAM

        cyclesPerLine = oamSearchDuration + lcdTransferDuration + hBlankDuration
        vBlankDuration = cyclesPerLine * UInt64(vBlankLineCount)
        clearPixelBuffer()
    }

    func emulate() {
        guard io.lcdControl.displayEnabled else {
            disableDisplayIfNecessary()
            return
        }

        cyclesRemaining -= 1
        if cyclesRemaining == 1 && io.lcdStatus.mode == .transferingToLCD && io.lcdStatus.hBlankInterruptEnabled {
            // Interrupt occurs 1 cycle before mode switch
            io.interruptFlags.formUnion(.lcdStat)
        }

        guard cyclesRemaining == 0 else { return }
        switch io.lcdStatus.mode {
        case .searchingOAMRAM:
            changeMode(next: .transferingToLCD)
        case .transferingToLCD:
            drawLine()
            changeMode(next: .horizontalBlank)
        case .horizontalBlank:
            io.lcdYCoordinate += 1
            if io.lcdYCoordinate < Constants.screenHeight {
                changeMode(next: .searchingOAMRAM)
            } else {
                changeMode(next: .verticalBlank)
            }
            checkAndHandleYCompare()
        case .verticalBlank:
            io.lcdYCoordinate += 1
            if io.lcdYCoordinate >= Constants.screenHeight + vBlankLineCount {
                io.lcdYCoordinate = 0
                changeMode(next: .searchingOAMRAM)
            } else {
                cyclesRemaining = getCycles(for: .verticalBlank)
            }
            checkAndHandleYCompare()
        }
    }

    // MARK: - Helpers

    private func disableDisplayIfNecessary() {
        guard isDisplayEnabled else { return }
        isDisplayEnabled = false
        clearPixelBuffer()
        io.lcdYCoordinate = 0
        io.lcdStatus.mode = .searchingOAMRAM
        oam.isBeingReadByPPU = false
        vram.isBeingReadByPPU = false
    }

    private func clearPixelBuffer() {
        pixelBuffer = [Byte](repeating: .max, count: pixelBuffer.count)
        renderPixelBuffer()
    }

    private func changeMode(next: LCDStatus.Mode) {
        io.lcdStatus.mode = next
        cyclesRemaining = getCycles(for: next)

        switch next {
        case .searchingOAMRAM:
            oam.isBeingReadByPPU = true
            if io.lcdStatus.oamInterruptEnabled {
                io.interruptFlags.formUnion(.lcdStat)
            }
        case .transferingToLCD:
            vram.isBeingReadByPPU = true
        case .horizontalBlank:
            oam.isBeingReadByPPU = false
            vram.isBeingReadByPPU = false
        case .verticalBlank:
            renderPixelBuffer()
            io.interruptFlags.formUnion(.vBlank)
            if io.lcdStatus.vBlankInterruptEnabled {
                io.interruptFlags.formUnion(.lcdStat)
            }
            if io.lcdStatus.oamInterruptEnabled {
                io.interruptFlags.formUnion(.lcdStat)
            }
        }
    }

    private func checkAndHandleYCompare() {
        io.lcdStatus.lcdYCompare = io.lcdYCoordinate == io.lcdYCoordinateCompare
        if io.lcdStatus.lcdYCompare && io.lcdStatus.lcdYCompareInterruptEnabled {
            io.interruptFlags.formUnion(.lcdStat)
        }
    }

    private func getCycles(for mode: LCDStatus.Mode) -> Cycles {
        // todo: account for variation in lcd-transfer durations
        switch mode {
        case .searchingOAMRAM:
            return oamSearchDuration
        case .transferingToLCD:
            return lcdTransferDuration
        case .horizontalBlank:
            return hBlankDuration
        case .verticalBlank:
            // This returns the cycles for one line of v-blank, not the full v-blank duration
            return cyclesPerLine
        }
    }

    /// Todo:
    /// - display window
    /// - display sprites
    private func drawLine() {
        let scrollX = io.scrollX
        let scrollY = io.scrollY
        let line = scrollY &+ io.lcdYCoordinate
        let pixelYInTile = line % 8 // tile height in pixels

        let lcdControl = io.lcdControl
        let map = lcdControl.backgroundTileMapDisplay
        let tiles = lcdControl.selectedTileDataRangeForBackgroundAndWindow

        var linePixels: [PixelInfo] = []
        linePixels.reserveCapacity(Constants.screenWidth)
        (0..<UInt8(truncatingIfNeeded: Constants.screenWidth)).forEach { screenX in
            let mapX = screenX &+ scrollX
            let pixelXInTile = mapX % 8 // tile width in pixels
            let tile = getTile(in: map, tileRange: tiles, pixelX: UInt16(mapX), pixelY: UInt16(line))
            let pixelColorNumber = tile.getColorNumber(in: vram, xOffset: pixelXInTile, yOffset: pixelYInTile)

            let pixelColor = io.palettes.getColor(for: pixelColorNumber, in: .monochromeBackground)
            linePixels.append(.background(pixelColor, colorNumber: pixelColorNumber))
        }

        updatePixelsWithSpriteInfo(forLine: line, pixels: &linePixels)
        let lineBuffer = getColorDataLineBuffer(for: linePixels)
        replaceDataInPixelBuffer(forLine: Int(io.lcdYCoordinate), with: lineBuffer)
    }

    /// Updates the provided array of pixels with pixels for sprites on the same line.
    private func updatePixelsWithSpriteInfo(forLine line: UInt8, pixels: inout [PixelInfo]) {
        let sprites = oam.findSortedSpriteAttributes(forLine: line, objectSize: io.lcdControl.objectSize)
        let objectSize = io.lcdControl.objectSize
        let screenXRange = 0..<Int16(Constants.screenWidth)

        // Since these sprites are ordered from highest to lowest priority, we reverse them so
        // that higher priority sprites will overwrite lower priority ones.
        sprites.reversed().forEach { sprite in
            let lineRange = sprite.getLineRangeRelativeToScreen(objectSize: objectSize)
            guard lineRange.contains(Int16(line)) else { return }

            let xRange = sprite.getXRangeRelativeToScreen(objectSize: objectSize)
            guard screenXRange.overlaps(xRange) else {
                // Sprite is off the left or right side of the screen
                return
            }

            (0..<objectSize.width).forEach { xOffsetInSprite in
                let xPositionInScreen = xRange.lowerBound + Int16(xOffsetInSprite)
                guard screenXRange.contains(xPositionInScreen) else { return }

                let yOffsetInSprite = UInt8(lineRange.lowerBound.distance(to: Int16(line)))
                let yOffsetInTile = yOffsetInSprite % 8
                let tileNumber = sprite.getTileNumber(yOffsetInSprite: yOffsetInSprite, objectSize: objectSize)
                let tile = io.lcdControl.tileDataRangeForObjects.getTile(for: tileNumber)
                let pixelColorNumber = tile.getColorNumber(in: vram, xOffset: xOffsetInSprite, xFlipped: sprite.isXFlipped, yOffset: yOffsetInTile, yFlipped: sprite.isYFlipped)
                guard pixelColorNumber != 0 else {
                    // Sprite color number 0 is always transparent
                    return
                }

                let pixelColor = io.palettes.getColor(for: pixelColorNumber, in: sprite.monochromePalette)
                mergeSpritePixel(color: pixelColor, priority: sprite.backgroundPriority, atIndex: Int(xPositionInScreen), with: &pixels)
            }
        }
    }

    private func mergeSpritePixel(color: Color, priority: SpriteAttributes.BackgroundPriority, atIndex: Int, with pixels: inout [PixelInfo]) {
        let existing = pixels[atIndex]
        switch existing {
        case .background(_, let colorNumber):
            // BG color number 0 is always behind the sprite
            if colorNumber == 0 || priority == .aboveBackground {
                pixels[atIndex] = .sprite(color)
            }
        case .sprite:
            pixels[atIndex] = .sprite(color)
        }
    }

    private func getColorDataLineBuffer(for pixels: [PixelInfo]) -> [Byte] {
        pixels.flatMap(\.color.rgbaBytes)
    }

    private func getTile(in mapRange: LCDControl.TileMapDisplayRange, tileRange: LCDControl.TileDataRange, pixelX: UInt16, pixelY: UInt16) -> Tile {
        let tileX = pixelX / 8
        let tileY = pixelY / 8
        let tileOffsetInMap = tileY * mapWidthInTiles + tileX
        let tileAddressInMap = mapRange.mapDataRange.lowerBound + tileOffsetInMap
        let tileNumber = vram.read(address: tileAddressInMap, privileged: true)
        return tileRange.getTile(for: tileNumber)
    }

    private func replaceDataInPixelBuffer(forLine line: Int, with bytes: [Byte]) {
        let offset = line * Constants.screenWidth * 4 // 4 bytes per pixel
        let range = (offset..<(offset + bytes.count))
        pixelBuffer.replaceSubrange(range, with: bytes)
    }

    private func renderPixelBuffer() {
        let region = PixelRegion(x: 0, y: 0, width: Constants.screenWidth, height: Constants.screenHeight)
        renderer.render(pixelData: pixelBuffer, at: region)
    }
}

extension Color {
    var rgbaBytes: [Byte] {
        return [red, green, blue, 255]
    }

    static var white: [Byte] {
        return [255, 255, 255, 255]
    }
}

extension PPU.PixelInfo {
    var color: Color {
        switch self {
        case .background(let color, _), .sprite(let color):
            return color
        }
    }
}
