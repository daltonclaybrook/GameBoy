public final class PPU {
	private let io: IO
	private var clock: Cycles = 0

	private let oamSearchDuration: Cycles = 20
	private let lcdTransferDuration: Cycles = 43
	private let hBlankDuration: Cycles = 51
	private let screenPixelWidth: UInt64 = 160
	private let screenLineCount: UInt64 = 144
	private let vBlankLineCount: UInt64 = 10

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

	init(io: IO) {
		self.io = io
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
		switch currentMode {
		case .searchingOAMRAM:
			break
		case .transferingToLCD:
			break
		case .horizontalBlank:
			break
		case .verticalBlank:
			break
		}
	}

	// MARK: - Helpers

	private func clearPixelBuffer() {
		let pixelBytesCount = screenLineCount * screenPixelWidth * 4 // 4 bytes per pixel
		pixelBuffer = Data(repeating: .max, count: Int(truncatingIfNeeded: pixelBytesCount))
	}
}
