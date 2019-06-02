public struct LCDStatus: RawRepresentable {
	enum Mode: UInt8 {
		case horizontalBlank
		case verticalBlank
		case searchingOAMRAM
		case transferingToLCD
	}

	public let rawValue: UInt8

	public init(rawValue: UInt8) {
		self.rawValue = rawValue
	}
}

extension LCDStatus {
	var mode: Mode {
		return Mode(rawValue: rawValue & 0x03)!
	}

	var isVRAMAccessible: Bool {
		switch mode {
		case .horizontalBlank, .verticalBlank, .searchingOAMRAM:
			return true
		case .transferingToLCD:
			return false
		}
	}
}
