public final class PPU {
	private let io: IO
	private let vram: VRAM
	private var clock: Cycles = 0

	private let oamSearchDuration: Cycles = 20
	private let lcdTransferDuration: Cycles = 43
	private let hBlankDuration: Cycles = 51
	private let screenPixelWidth: UInt64 = 160
	private let screenLineCount: UInt64 = 144
	private let vBlankLineCount: UInt64 = 10
	private let mapWidthInTiles: UInt16 = 32 // map is 32x32 tiles

	private let vBlankDuration: Cycles
	private let cyclesPerLine: Cycles
	private let cyclesPerFrame: Cycles

	private var pixelBuffer = Data()

	private var currentLine: UInt64 {
		return (clock % cyclesPerFrame) / cyclesPerLine
	}

	private var currentMode: LCDStatus.Mode {
		guard currentLine < screenLineCount else {
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

	init(io: IO, vram: VRAM) {
		self.io = io
		self.vram = vram
		cyclesPerLine = oamSearchDuration + lcdTransferDuration + hBlankDuration
		vBlankDuration = cyclesPerLine * vBlankLineCount
		cyclesPerFrame = cyclesPerLine * (screenLineCount + vBlankLineCount)
		clearPixelBuffer()
	}

	func step(cycles: UInt64) {
		guard io.lcdControl.displayEnabled else {
			if clock != 0 {
				clock = 0
				clearPixelBuffer()
			}
			return
		}

		clock &+= cycles
		let previousMode = io.lcdStatus.mode
		let nextMode = currentMode
		io.lcdStatus.mode = nextMode
		io.lcdYCoordinate = UInt8(truncatingIfNeeded: currentLine)

		if previousMode == .transferingToLCD && nextMode != .horizontalBlank {
			renderLine()
		}
	}

	// MARK: - Helpers

	private func clearPixelBuffer() {
		let pixelBytesCount = screenLineCount * screenPixelWidth * 4 // 4 bytes per pixel
		pixelBuffer = Data(repeating: .max, count: Int(truncatingIfNeeded: pixelBytesCount))
	}

	/// Tasks:
	/// - get line number
	/// - get x and y scroll offset
	/// - get current selected tile data range for BG and window
	/// - get current selected tile map range for BG
	/// - get current selected tile map range for window (todo)
	/// - get BG map index for pixel
	/// - get tile ID for map index
	/// - get pixel offset within tile
	/// - get palette for tile from BG attributes map (todo)
	/// - get color for tile pixel index
	/// - convert 15-bit color to 4-byte RGBA
	/// - determine offset in pixel buffer and write pixel
	/// - loop

	/// Todo:
	/// - display window
	/// - display sprites
	private func renderLine() {
		let scrollX = io.scrollX
		let scrollY = io.scrollY
		let screenLine = UInt8(truncatingIfNeeded: currentLine)
		let mapY = scrollY &+ screenLine
		let yOffsetInTile = mapY % 8 // tile height in pixels

		let lcdControl = io.lcdControl
		let mapDataRange = lcdControl.backgroundTileMapDisplay.mapDataRange
		let tileDataRange = lcdControl.selectedTileDataForBackgroundAndWindow.tileDataRange

		for screenX in (0..<screenPixelWidth) {
			let mapX = UInt8(truncatingIfNeeded: screenX) &+ scrollX
			let xOffsetInTile = mapX % 8 // tile width in pixels
			let tileOffsetInMap = (Address(mapY) / 8) * mapWidthInTiles + UInt16(mapX)
			let tileAddressInMap = mapDataRange.lowerBound + tileOffsetInMap
			let tileIndex = vram.read(address: tileAddressInMap)
			let tileDataOffset = Address(tileIndex) * 0x10 // each tile is 0x10 bytes in the tile data
			// tiles are 2 bits-per-pixel. One line of 8 pixels is 2 bytes.
			let byteOffsetInTileForPixel = Address(yOffsetInTile * 2 + xOffsetInTile / 4)
			let pixelAddress = tileDataRange.lowerBound + tileDataOffset + byteOffsetInTileForPixel
			// this byte contains 4 pixels
			let pixelData = vram.read(address: pixelAddress)
			let pixelBitOffset = (xOffsetInTile % 4) * 2 // 2 bits per pixel
			let pixel = (pixelData >> pixelBitOffset) & 0x03
		}
	}
}
