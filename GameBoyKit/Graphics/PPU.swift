import Foundation

public final class PPU {
    /// Represents information about a pixel that might be rendered to the
    /// screen or might be overridden by another pixel based on priority.
    private enum PixelInfo {
        case unspecified
        case background(colorNumber: Int, Color)
        case sprite(Color, priority: SpriteAttributes.BackgroundPriority)
    }

    private let renderer: Renderer
    private let io: IO
    private let vram: VRAM
    private let oam: OAM

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
        let mapY = scrollY &+ io.lcdYCoordinate
        let pixelYInTile = mapY % 8 // tile height in pixels

        let lcdControl = io.lcdControl
        let map = lcdControl.backgroundTileMapDisplay
        let tiles = lcdControl.selectedTileDataForBackgroundAndWindow

        var lineBuffer = [Byte]()
        lineBuffer.reserveCapacity(Constants.screenWidth * 4) // each pixel RGBA
        (0..<UInt8(truncatingIfNeeded: Constants.screenWidth)).forEach { screenX in
            let mapX = screenX &+ scrollX
            let pixelXInTile = mapX % 8 // tile width in pixels
            let tileAddress = getTileAddress(map: map, tiles: tiles, pixelX: UInt16(mapX), pixelY: UInt16(mapY))
            let pixelColorNumber = getPixelColorNumber(tileAddress: tileAddress, xOffsetInTile: pixelXInTile, yOffsetInTile: pixelYInTile)

            let pixelColor = io.palette.getMonochromeBGColor(for: UInt8(truncatingIfNeeded: pixelColorNumber))
            lineBuffer.append(contentsOf: pixelColor.rgbaBytes)
        }

        replaceDataInPixelBuffer(forLine: Int(io.lcdYCoordinate), with: lineBuffer)
    }

    /// Updates the provided array of pixels with pixels for sprites on the same line.
    private func updatePixelsWithSpriteInfo(forLine line: UInt8, pixels: inout [PixelInfo]) {
        let sprites = oam.findSortedSpriteAttributes(forLine: line, objectSize: io.lcdControl.objectSize)
        let objectSize = io.lcdControl.objectSize
        let screenXRange = 0..<Int16(Constants.screenWidth)

        sprites.forEach { sprite in
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
                let tileNumber = sprite.getTileNumber(yOffsetInSprite: yOffsetInSprite, objectSize: objectSize)
                let tileAddress = io.lcdControl.tileDataForObjects.getTileAddress(atIndex: tileNumber)
                let pixelColorNumber = getPixelColorNumber(tileAddress: tileAddress, xOffsetInTile: xOffsetInSprite, xFlipped: sprite.isXFlipped, yOffsetInTile: yOffsetInSprite % 8, yFlipped: sprite.isYFlipped)
                guard pixelColorNumber != 0 else {
                    // Sprite color number 0 is always transparent
                    return
                }

                let color = io.palette.getMonochromeObjectColor(for: pixelColorNumber, paletteNumber: sprite.monochromePaletteNumber)
                pixels[Int(xPositionInScreen)] = .sprite(color, priority: sprite.backgroundPriority)
            }
        }
    }

    private func getTileAddress(map: LCDControl.TileMapDisplay, tiles: LCDControl.TileData, pixelX: UInt16, pixelY: UInt16) -> Address {
        let tileX = pixelX / 8
        let tileY = pixelY / 8
        let tileOffsetInMap = tileY * mapWidthInTiles + tileX
        let tileAddressInMap = map.mapDataRange.lowerBound + tileOffsetInMap
        let tileIndex = vram.read(address: tileAddressInMap, privileged: true)
        return tiles.getTileAddress(atIndex: tileIndex)
    }

    private func getPixelColorNumber(tileAddress: Address, xOffsetInTile: UInt8, xFlipped: Bool = false, yOffsetInTile: UInt8, yFlipped: Bool = false) -> ColorNumber {
        let xOffset = xFlipped ? 8 - xOffsetInTile : xOffsetInTile
        let yOffset = yFlipped ? 8 - yOffsetInTile : yOffsetInTile
        let pixelWord = vram.readWord(address: tileAddress + Address(yOffset) * 2, privileged: true)
        let lowShift = 7 - xOffset
        let highShift = lowShift + 8 - 1
        let pixelColorNumber = (pixelWord >> highShift) & 0x02 | (pixelWord >> lowShift) & 0x01
        return ColorNumber(truncatingIfNeeded: pixelColorNumber)
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
}
