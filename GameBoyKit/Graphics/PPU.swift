import Foundation

private struct LineDrawingContext {
    let line: UInt8
    let lcdControl: LCDControl
    let vramView: VRAMView
    let paletteView: PaletteView
    let oamView: OAMView
    let scrollX: UInt8
    let scrollY: UInt8
    let windowX: UInt8
    let windowY: UInt8
}

public final class PPU {
    /// Represents information about a pixel that might be rendered to the
    /// screen or might be overridden by another pixel based on priority.
    fileprivate enum PixelInfo {
        case blank
        case background(Color, colorNumber: ColorNumber)
        case window(Color, colorNumber: ColorNumber)
        case sprite(Color)
    }

    private let queue = DispatchQueue(
        label: "com.daltonclaybrook.GameBoy.PPU",
        qos: .userInteractive
    )

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
    /// Each time a window line is drawn, this counter is incremented and used to
    /// calculate the next window line to draw. If window display is disabled, this
    /// will not be incremented.
    private var windowLineCounter: UInt8 = 0
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
                // Jump back to the top of the screen
                io.lcdYCoordinate = 0
                queue.async {
                    self.windowLineCounter = 0
                }
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
        cyclesRemaining = getCycles(for: .searchingOAMRAM)
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

    private func drawLine() {
        let context = LineDrawingContext(
            line: io.lcdYCoordinate,
            lcdControl: io.lcdControl,
            vramView: vram.currentView,
            paletteView: io.palettes.currentView,
            oamView: oam.currentView,
            scrollX: io.scrollX,
            scrollY: io.scrollY,
            windowX: io.windowX,
            windowY: io.windowY
        )
        queue.async {
            self.queueDrawScreenLine(with: context)
        }
    }

    private func queueDrawScreenLine(with context: LineDrawingContext) {
        var linePixels = [PixelInfo](repeating: .blank, count: Constants.screenWidth)

        if context.lcdControl.backgroundAndWindowDisplayPriority {
            updatePixelsWithBackground(with: context, pixels: &linePixels)

            if context.lcdControl.windowDisplayEnabled {
                updatePixelsWithWindow(context: context, pixels: &linePixels)
            }
        }

        if context.lcdControl.objectDisplayEnabled {
            updatePixelsWithSprites(context: context, pixels: &linePixels)
        }

        let lineBuffer = getColorDataLineBuffer(for: linePixels)
        replaceDataInPixelBuffer(forLine: Int(context.line), with: lineBuffer)
    }

    /// Update the provided array of pixels with pixels for the background
    private func updatePixelsWithBackground(with context: LineDrawingContext, pixels: inout [PixelInfo]) {
        let map = context.lcdControl.backgroundTileMapDisplay
        let tiles = context.lcdControl.selectedTileDataRangeForBackgroundAndWindow
        let lineInMap = context.scrollY &+ context.line
        let pixelYInTile = lineInMap % 8 // tile height in pixels

        (0..<UInt8(Constants.screenWidth)).forEach { screenX in
            let mapX = screenX &+ context.scrollX
            let pixelXInTile = mapX % 8 // tile width in pixels
            let tile = getTile(in: map, tileRange: tiles, vramView: context.vramView, pixelX: UInt16(mapX), pixelY: UInt16(lineInMap))
            let pixelColorNumber = tile.getColorNumber(vramView: context.vramView, xOffset: pixelXInTile, yOffset: pixelYInTile)

            let pixelColor = context.paletteView.getColor(for: pixelColorNumber, in: .monochromeBackgroundAndWindow)
            pixels[Int(screenX)] = .background(pixelColor, colorNumber: pixelColorNumber)
        }
    }

    private func updatePixelsWithWindow(context: LineDrawingContext, pixels: inout [PixelInfo]) {
        guard context.windowY <= context.line else {
            // This line is above where the window is rendered
            return
        }

        // A value of 0-7 positions the window at the left edge of the screen. Positions
        // less than 7 result in hardware glitches on the game boy, but those glitches are
        // not emulated here.
        let windowX = UInt8(max(Int(context.windowX) - 7, 0))
        let screenWidth = UInt8(Constants.screenWidth)
        guard windowX < screenWidth else {
            // Window is off the right edge of the screen
            return
        }

        let yOffsetInWindow = windowLineCounter
        windowLineCounter += 1

        let yOffsetInTile = yOffsetInWindow % 8
        let mapRange = context.lcdControl.windowTileMapDisplay
        let tileRange = context.lcdControl.selectedTileDataRangeForBackgroundAndWindow

        (windowX..<screenWidth).forEach { screenX in
            let xOffsetInWindow = screenX - windowX
            let xOffsetInTile = xOffsetInWindow % 8
            let tile = getTile(in: mapRange, tileRange: tileRange, vramView: context.vramView, pixelX: UInt16(xOffsetInWindow), pixelY: UInt16(yOffsetInWindow))
            let colorNumber = tile.getColorNumber(vramView: context.vramView, xOffset: xOffsetInTile, yOffset: yOffsetInTile)
            let pixelColor = context.paletteView.getColor(for: colorNumber, in: .monochromeBackgroundAndWindow)
            pixels[Int(screenX)] = .window(pixelColor, colorNumber: colorNumber)
        }
    }

    /// Updates the provided array of pixels with pixels for sprites on the same line.
    private func updatePixelsWithSprites(context: LineDrawingContext, pixels: inout [PixelInfo]) {
        let sprites = context.oamView.findSortedSpriteAttributes(forLine: context.line, objectSize: context.lcdControl.objectSize)
        let objectSize = context.lcdControl.objectSize
        let screenXRange = 0..<Int16(Constants.screenWidth)

        // Since these sprites are ordered from highest to lowest priority, we reverse them so
        // that higher priority sprites will overwrite lower priority ones.
        sprites.reversed().forEach { sprite in
            let lineRange = sprite.getLineRangeRelativeToScreen(objectSize: objectSize)
            guard lineRange.contains(Int16(context.line)) else { return }

            let xRange = sprite.getXRangeRelativeToScreen(objectSize: objectSize)
            guard screenXRange.overlaps(xRange) else {
                // Sprite is off the left or right side of the screen
                return
            }

            (0..<objectSize.width).forEach { xOffsetInSprite in
                let xPositionInScreen = xRange.lowerBound + Int16(xOffsetInSprite)
                guard screenXRange.contains(xPositionInScreen) else { return }

                let yOffsetInSprite = UInt8(lineRange.lowerBound.distance(to: Int16(context.line)))
                let yOffsetInTile = yOffsetInSprite % 8
                let tileNumber = sprite.getTileNumber(yOffsetInSprite: yOffsetInSprite, objectSize: objectSize)
                let tile = context.lcdControl.tileDataRangeForObjects.getTile(for: tileNumber)
                let pixelColorNumber = tile.getColorNumber(vramView: context.vramView, xOffset: xOffsetInSprite, xFlipped: sprite.isXFlipped, yOffset: yOffsetInTile, yFlipped: sprite.isYFlipped)
                guard pixelColorNumber != 0 else {
                    // Sprite color number 0 is always transparent
                    return
                }

                let pixelColor = context.paletteView.getColor(for: pixelColorNumber, in: sprite.monochromePalette)
                mergeSpritePixel(color: pixelColor, priority: sprite.backgroundPriority, atIndex: Int(xPositionInScreen), with: &pixels)
            }
        }
    }

    private func mergeSpritePixel(color: Color, priority: SpriteAttributes.BackgroundPriority, atIndex: Int, with pixels: inout [PixelInfo]) {
        let existing = pixels[atIndex]
        switch existing {
        case .background(_, let colorNumber), .window(_, let colorNumber):
            // BG color number 0 is always behind the sprite
            if colorNumber == 0 || priority == .aboveBackground {
                pixels[atIndex] = .sprite(color)
            }
        case .blank, .sprite:
            pixels[atIndex] = .sprite(color)
        }
    }

    private func getColorDataLineBuffer(for pixels: [PixelInfo]) -> [Byte] {
        pixels.flatMap(\.color.rgbaBytes)
    }

    private func getTile(in mapRange: LCDControl.TileMapDisplayRange, tileRange: LCDControl.TileDataRange, vramView: VRAMView, pixelX: UInt16, pixelY: UInt16) -> Tile {
        let tileX = pixelX / 8
        let tileY = pixelY / 8
        let tileOffsetInMap = tileY * mapWidthInTiles + tileX
        let tileAddressInMap = mapRange.mapDataRange.lowerBound + tileOffsetInMap
        let tileNumber = vramView.read(address: tileAddressInMap)
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

    static var white: Color {
        return Color(red: 255, green: 255, blue: 255)
    }
}

extension PPU.PixelInfo {
    var color: Color {
        switch self {
        case .blank:
            return .white
        case .background(let color, _),
             .window(let color, _),
             .sprite(let color):
            return color
        }
    }
}
