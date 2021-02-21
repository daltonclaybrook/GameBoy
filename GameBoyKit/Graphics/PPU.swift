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

/// The pixel processing unit
public final class PPU {
    /// Represents information about a pixel that might be rendered to the
    /// screen or might be overridden by another pixel based on priority.
    fileprivate enum PixelInfo {
        case blank
        case background(Color, colorNumber: ColorNumber)
        case window(Color, colorNumber: ColorNumber)
        case sprite(Color)
    }

    private struct Constants {
        static let oamSearchDuration: Cycles = 20
        static let lcdTransferDuration: Cycles = 43
        static let hBlankDuration: Cycles = 51
        static let vBlankLineCount = 10
        static let mapWidthInTiles: UInt16 = 32 // map is 32x32 tiles
    }

    private let queue = DispatchQueue(
        label: "com.daltonclaybrook.GameBoy.PPU",
        qos: .userInteractive
    )

    let io: IO
    let vram: VRAM
    let oam: OAM
    let system: GameBoy.System

    private let renderer: Renderer
    private let vBlankDuration: Cycles
    private let cyclesPerLine: Cycles
    private var isDisplayEnabled = false
    private var cyclesRemaining: Cycles
    /// Each time a window line is drawn, this counter is incremented and used to
    /// calculate the next window line to draw. If window display is disabled, this
    /// will not be incremented.
    private var windowLineCounter: UInt8 = 0
    private var pixelBuffer = [Byte](repeating: .max, count: ScreenConstants.width * ScreenConstants.height * 4)

    init(renderer: Renderer, system: GameBoy.System, io: IO, vram: VRAM, oam: OAM) {
        self.renderer = renderer
        self.system = system
        self.io = io
        self.vram = vram
        self.oam = oam
        self.cyclesRemaining = Constants.oamSearchDuration
        io.lcdStatus.mode = .searchingOAMRAM

        cyclesPerLine = Constants.oamSearchDuration + Constants.lcdTransferDuration + Constants.hBlankDuration
        vBlankDuration = cyclesPerLine * UInt64(Constants.vBlankLineCount)
        clearPixelBuffer()
    }

    /// Called once per machine cycle
    func emulate() {
        guard io.lcdControl.displayEnabled else {
            disableDisplayIfNecessary()
            return
        }

        cyclesRemaining -= 1
        if cyclesRemaining == 1 && io.lcdStatus.mode == .transferringToLCD && io.lcdStatus.hBlankInterruptEnabled {
            // Interrupt occurs 1 cycle before mode switch
            io.interruptFlags.insert(.lcdStat)
        }

        guard cyclesRemaining == 0 else { return }
        switch io.lcdStatus.mode {
        case .searchingOAMRAM:
            changeMode(next: .transferringToLCD)
        case .transferringToLCD:
            drawLine()
            changeMode(next: .horizontalBlank)
        case .horizontalBlank:
            io.lcdYCoordinate += 1
            if io.lcdYCoordinate < ScreenConstants.height {
                changeMode(next: .searchingOAMRAM)
            } else {
                changeMode(next: .verticalBlank)
            }
            checkAndHandleYCompare()
        case .verticalBlank:
            io.lcdYCoordinate += 1
            if io.lcdYCoordinate >= ScreenConstants.height + Constants.vBlankLineCount {
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
        queue.async {
            self.pixelBuffer = [Byte](repeating: .max, count: self.pixelBuffer.count)
            self.queueRenderPixelBuffer()
        }
    }

    private func changeMode(next: LCDStatus.Mode) {
        io.lcdStatus.mode = next
        cyclesRemaining = getCycles(for: next)

        switch next {
        case .searchingOAMRAM:
            oam.isBeingReadByPPU = true
            if io.lcdStatus.oamInterruptEnabled {
                io.interruptFlags.insert(.lcdStat)
            }
        case .transferringToLCD:
            vram.isBeingReadByPPU = true
            io.palettes.colorPaletteMemoryIsAccessible = false
        case .horizontalBlank:
            oam.isBeingReadByPPU = false
            vram.isBeingReadByPPU = false
            io.palettes.colorPaletteMemoryIsAccessible = true
        case .verticalBlank:
            renderPixelBuffer()
            io.interruptFlags.insert(.vBlank)
            if io.lcdStatus.vBlankInterruptEnabled {
                io.interruptFlags.insert(.lcdStat)
            }
            if io.lcdStatus.oamInterruptEnabled {
                io.interruptFlags.insert(.lcdStat)
            }
        }
    }

    private func checkAndHandleYCompare() {
        io.lcdStatus.lcdYCompare = io.lcdYCoordinate == io.lcdYCoordinateCompare
        if io.lcdStatus.lcdYCompare && io.lcdStatus.lcdYCompareInterruptEnabled {
            io.interruptFlags.insert(.lcdStat)
        }
    }

    private func getCycles(for mode: LCDStatus.Mode) -> Cycles {
        // todo: account for variation in lcd-transfer durations
        switch mode {
        case .searchingOAMRAM:
            return Constants.oamSearchDuration
        case .transferringToLCD:
            return Constants.lcdTransferDuration
        case .horizontalBlank:
            return Constants.hBlankDuration
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
        var linePixels = [PixelInfo](repeating: .blank, count: ScreenConstants.width)

        if context.lcdControl.backgroundAndWindowDisplayPriority {
            updatePixelsWithBackground(with: context, pixels: &linePixels)

            if context.lcdControl.windowDisplayEnabled {
                updatePixelsWithWindow(context: context, pixels: &linePixels)
            }
        }

        if context.lcdControl.objectDisplayEnabled {
            updatePixelsWithSprites(context: context, pixels: &linePixels)
        }

        replaceDataInPixelBuffer(forLine: Int(context.line), with: linePixels)
    }

    /// Update the provided array of pixels with pixels for the background
    private func updatePixelsWithBackground(with context: LineDrawingContext, pixels: inout [PixelInfo]) {
        let map = context.lcdControl.backgroundTileMapDisplay
        let tiles = context.lcdControl.selectedTileDataRangeForBackgroundAndWindow
        let lineInMap = context.scrollY &+ context.line
        let pixelYInTile = lineInMap % 8 // tile height in pixels

        for screenX in 0..<UInt8(ScreenConstants.width) {
            let mapX = screenX &+ context.scrollX
            let pixelXInTile = mapX % 8 // tile width in pixels
            let (tile, attributes) = getTileAndAttributes(
                in: map,
                tileRange: tiles,
                vramView: context.vramView,
                pixelX: UInt16(mapX),
                pixelY: UInt16(lineInMap)
            )
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
        let screenWidth = UInt8(ScreenConstants.width)
        guard windowX < screenWidth else {
            // Window is off the right edge of the screen
            return
        }

        let yOffsetInWindow = windowLineCounter
        windowLineCounter += 1

        let yOffsetInTile = yOffsetInWindow % 8
        let mapRange = context.lcdControl.windowTileMapDisplay
        let tileRange = context.lcdControl.selectedTileDataRangeForBackgroundAndWindow

        for screenX in windowX..<screenWidth {
            let xOffsetInWindow = screenX - windowX
            let xOffsetInTile = xOffsetInWindow % 8
            let (tile, attributes) = getTileAndAttributes(
                in: mapRange,
                tileRange: tileRange,
                vramView: context.vramView,
                pixelX: UInt16(xOffsetInWindow),
                pixelY: UInt16(yOffsetInWindow)
            )
            let colorNumber = tile.getColorNumber(vramView: context.vramView, xOffset: xOffsetInTile, yOffset: yOffsetInTile)
            let pixelColor = context.paletteView.getColor(for: colorNumber, in: .monochromeBackgroundAndWindow)
            pixels[Int(screenX)] = .window(pixelColor, colorNumber: colorNumber)
        }
    }

    /// Updates the provided array of pixels with pixels for sprites on the same line.
    private func updatePixelsWithSprites(context: LineDrawingContext, pixels: inout [PixelInfo]) {
        let sprites = context.oamView.findSortedSpriteAttributes(forLine: context.line, objectSize: context.lcdControl.objectSize)
        let objectSize = context.lcdControl.objectSize
        let screenXRange = 0..<Int16(ScreenConstants.width)

        // Since these sprites are ordered from highest to lowest priority, we reverse them so
        // that higher priority sprites will overwrite lower priority ones.
        for sprite in sprites.reversed() {
            let lineRange = sprite.getLineRangeRelativeToScreen(objectSize: objectSize)
            guard lineRange.contains(Int16(context.line)) else { continue }

            let xRange = sprite.getXRangeRelativeToScreen(objectSize: objectSize)
            guard screenXRange.overlaps(xRange) else {
                // Sprite is off the left or right side of the screen
                continue
            }

            let spriteFlags = sprite.flags
            let tileBankNumber = spriteFlags.getBankNumber(for: system)
            for xOffsetInSprite in 0..<objectSize.width {
                let xPositionInScreen = xRange.lowerBound + Int16(xOffsetInSprite)
                guard screenXRange.contains(xPositionInScreen) else { continue }

                let yOffsetInSprite = UInt8(lineRange.lowerBound.distance(to: Int16(context.line)))
                let yOffsetInTile = yOffsetInSprite % 8
                let tileNumber = sprite.getTileNumber(yOffsetInSprite: yOffsetInSprite, objectSize: objectSize)
                let tileDataAddress = context.lcdControl.tileDataRangeForObjects.getTileDataAddress(for: tileNumber)
                let tile = Tile(dataAddress: tileDataAddress, bankNumber: tileBankNumber, isXFlipped: spriteFlags.isXFlipped, isYFlipped: spriteFlags.isYFlipped)
                let pixelColorNumber = tile.getColorNumber(
                    vramView: context.vramView,
                    xOffset: xOffsetInSprite,
                    yOffset: yOffsetInTile
                )
                guard pixelColorNumber != 0 else {
                    // Sprite color number 0 is always transparent
                    continue
                }

                let pixelColor = context.paletteView.getColor(for: pixelColorNumber, in: sprite.monochromePalette)
                mergeSpritePixel(color: pixelColor, priority: spriteFlags.backgroundPriority, atIndex: Int(xPositionInScreen), with: &pixels)
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

    private func getTileAndAttributes(
        in mapRange: LCDControl.TileMapDisplayRange,
        tileRange: LCDControl.TileDataRange,
        vramView: VRAMView,
        pixelX: UInt16,
        pixelY: UInt16
    ) -> (Tile, BGMapTileAttributes) {
        let tileX = pixelX / 8
        let tileY = pixelY / 8
        let tileOffsetInMap = tileY * Constants.mapWidthInTiles + tileX
        let tileAddressInMap = mapRange.addressRange.lowerBound + tileOffsetInMap
        let tileNumber = vramView.read(address: tileAddressInMap)
        let tileDataAddress = tileRange.getTileDataAddress(for: tileNumber)
        let attributes = vramView.getAttributesForTileAddressInMap(tileAddressInMap)
        let tile = Tile(
            dataAddress: tileDataAddress,
            bankNumber: attributes.tileVRAMBankNumber,
            isXFlipped: attributes.isXFlipped,
            isYFlipped: attributes.isYFlipped
        )
        return (tile, attributes)
    }

    private func replaceDataInPixelBuffer(forLine line: Int, with pixels: [PixelInfo]) {
        let lineOffset = line * ScreenConstants.width * 4 // 4 bytes per pixel
        for (xOffset, pixel) in pixels.enumerated() {
            let pixelOffset = lineOffset + xOffset * 4
            let rgbaBytes = pixel.color.rgbaBytes

            // Faster than calling `replaceSubrange`
            pixelBuffer[pixelOffset] = rgbaBytes[0]
            pixelBuffer[pixelOffset + 1] = rgbaBytes[1]
            pixelBuffer[pixelOffset + 2] = rgbaBytes[2]
            pixelBuffer[pixelOffset + 3] = rgbaBytes[3]
        }
    }

    private func renderPixelBuffer() {
        queue.async {
            self.queueRenderPixelBuffer()
        }
    }

    private func queueRenderPixelBuffer() {
        let region = PixelRegion(x: 0, y: 0, width: ScreenConstants.width, height: ScreenConstants.height)
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
