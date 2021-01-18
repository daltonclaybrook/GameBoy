import Foundation

public final class PPU {
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
            let pixelColorNumber = getPixelColorNumber(tileAddress: tileAddress, xOffsetInTile: UInt16(pixelXInTile), yOffsetInTile: UInt16(pixelYInTile))

            let pixelColor = io.palette.getMonochromeBGColor(for: UInt8(truncatingIfNeeded: pixelColorNumber))
            lineBuffer.append(contentsOf: pixelColor.rgbaBytes)
        }

        replaceDataInPixelBuffer(forLine: Int(io.lcdYCoordinate), with: lineBuffer)
    }

    private func getTileAddress(map: LCDControl.TileMapDisplay, tiles: LCDControl.TileData, pixelX: UInt16, pixelY: UInt16) -> Address {
        let tileX = pixelX / 8
        let tileY = pixelY / 8
        let tileOffsetInMap = tileY * mapWidthInTiles + tileX
        let tileAddressInMap = map.mapDataRange.lowerBound + tileOffsetInMap
        let tileIndex = vram.read(address: tileAddressInMap, privileged: true)
        return tiles.getTileAddress(atIndex: tileIndex)
    }

    private func getPixelColorNumber(tileAddress: Address, xOffsetInTile: UInt16, yOffsetInTile: UInt16) -> ColorNumber {
        let pixelWord = vram.readWord(address: tileAddress + yOffsetInTile * 2, privileged: true)
        let lowShift = 7 - xOffsetInTile
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
