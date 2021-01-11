import Foundation

public final class PPU {
    private let renderer: Renderer
    private let io: IO
    private let vram: VRAM

    private let oamSearchDuration: Cycles = 20
    private let lcdTransferDuration: Cycles = 43
    private let hBlankDuration: Cycles = 51
    private let vBlankLineCount: UInt64 = 10
    private let mapWidthInTiles: UInt16 = 32 // map is 32x32 tiles

    private let vBlankDuration: Cycles
    private let cyclesPerLine: Cycles
    private let cyclesPerFrame: Cycles
    private var isDisplayEnabled = true

    init(renderer: Renderer, io: IO, vram: VRAM) {
        self.renderer = renderer
        self.io = io
        self.vram = vram

        cyclesPerLine = oamSearchDuration + lcdTransferDuration + hBlankDuration
        vBlankDuration = cyclesPerLine * vBlankLineCount
        cyclesPerFrame = cyclesPerLine * (UInt64(Constants.screenHeight) + vBlankLineCount)
        clearPixelBuffer()
    }

    func step(clock: Cycles) {
        guard io.lcdControl.displayEnabled else {
            if isDisplayEnabled {
                disableDisplay()
            }
            return
        }

        isDisplayEnabled = true
        let previousMode = io.lcdStatus.mode
        let nextMode = currentMode(clock: clock)
        let line = currentLine(clock: clock)
        isDisplayEnabled = io.lcdControl.displayEnabled
        io.lcdStatus.mode = nextMode
        io.lcdYCoordinate = UInt8(truncatingIfNeeded: line)
        io.lcdStatus.lcdYCoincidence = io.lcdYCoordinate == io.lcdYCoordinateCompare

        if io.lcdStatus.lcdYCoincidenceInterruptEnabled && io.lcdStatus.lcdYCoincidence {
            io.interruptFlags.formUnion(.lcdStat)
        }

        switch (previousMode, nextMode) {
        case (.searchingOAMRAM, .transferingToLCD):
            vram.isLocked = true
            render(line: line)
        case (.transferingToLCD, .horizontalBlank):
            vram.isLocked = false
            if io.lcdStatus.hBlankInterruptEnabled {
                io.interruptFlags.formUnion(.lcdStat)
            }
        case (.horizontalBlank, .verticalBlank):
            io.interruptFlags.formUnion(.vBlank)
            if io.lcdStatus.vBlankInterruptEnabled {
                io.interruptFlags.formUnion(.lcdStat)
            }
        default:
            break
        }
    }

    // MARK: - Helpers

    private func currentLine(clock: Cycles) -> UInt64 {
        return (clock % cyclesPerFrame) / cyclesPerLine
    }

    private func currentMode(clock: Cycles) -> LCDStatus.Mode {
        guard currentLine(clock: clock) < UInt64(Constants.screenHeight) else {
            return .verticalBlank
        }
        switch clock % cyclesPerLine {
        case (0..<oamSearchDuration):
            return .searchingOAMRAM
        case (oamSearchDuration..<(oamSearchDuration + lcdTransferDuration)):
            return .transferingToLCD
        default:
            return .horizontalBlank
        }
    }

    private func disableDisplay() {
        isDisplayEnabled = false
        clearPixelBuffer()
        io.lcdYCoordinate = 0
        io.lcdStatus.mode = .searchingOAMRAM
        vram.isLocked = false
    }

    private func clearPixelBuffer() {
        let pixelBytesCount = Constants.screenHeight * Constants.screenWidth * 4 // 4 bytes per pixel
        let region = PixelRegion(x: 0, y: 0, width: Constants.screenWidth, height: Constants.screenHeight)
        let pixelData = [Byte](repeating: .max, count: pixelBytesCount)
        renderer.render(pixelData: pixelData, at: region)
    }

    /// Todo:
    /// - display window
    /// - display sprites
    private func render(line: UInt64) {
        let scrollX = io.scrollX
        let scrollY = io.scrollY
        let currentLine = Int(truncatingIfNeeded: line)
        let mapY = scrollY &+ UInt8(truncatingIfNeeded: currentLine)
        let pixelYInTile = mapY % 8 // tile height in pixels

        let lcdControl = io.lcdControl
        let map = lcdControl.backgroundTileMapDisplay
        let tiles = lcdControl.selectedTileDataForBackgroundAndWindow

        var lineBuffer = [Byte]()
        lineBuffer.reserveCapacity(Constants.screenWidth * 4) // each pixel RGBA
        (0..<Constants.screenWidth).forEach { screenX in
            let mapX = UInt8(truncatingIfNeeded: screenX) &+ scrollX
            let pixelXInTile = mapX % 8 // tile width in pixels
            let tileAddress = getTileAddress(map: map, tiles: tiles, pixelX: UInt16(mapX), pixelY: UInt16(mapY))
            let pixelColorNumber = getPixelColorNumber(tileAddress: tileAddress, xOffsetInTile: UInt16(pixelXInTile), yOffsetInTile: UInt16(pixelYInTile))

            let pixelColor = io.palette.monochromeBGColor(for: UInt8(truncatingIfNeeded: pixelColorNumber))
            lineBuffer.append(contentsOf: pixelColor.rgbaBytes)
        }

        let region = PixelRegion(x: 0, y: currentLine, width: Constants.screenWidth, height: 1)
        renderer.render(pixelData: lineBuffer, at: region)
    }

    private func getTileAddress(map: LCDControl.TileMapDisplay, tiles: LCDControl.TileData, pixelX: UInt16, pixelY: UInt16) -> Address {
        let tileX = pixelX / 8
        let tileY = pixelY / 8
        let tileOffsetInMap = tileY * mapWidthInTiles + tileX
        let tileAddressInMap = map.mapDataRange.lowerBound + tileOffsetInMap
        let tileIndex = vram.read(address: tileAddressInMap, privileged: true)
        return tiles.tileAddress(atIndex: tileIndex)
    }

    private func getPixelColorNumber(tileAddress: Address, xOffsetInTile: UInt16, yOffsetInTile: UInt16) -> UInt8 {
        let pixelWord = vram.readWord(address: tileAddress + yOffsetInTile * 2, privileged: true)
        let lowShift = 7 - xOffsetInTile
        let highShift = lowShift + 8 - 1
        let pixelColorNumber = (pixelWord >> highShift) & 0x02 | (pixelWord >> lowShift) & 0x01
        return UInt8(pixelColorNumber)
    }
}

extension Color {
    var rgbaBytes: [Byte] {
        return [red, green, blue, 255]
    }
}
