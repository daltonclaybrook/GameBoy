public struct LCDStatus: RawRepresentable {
	enum Mode: UInt8 {
		case horizontalBlank
		case verticalBlank
		case searchingOAMRAM
		case transferingToLCD
	}

	private(set) public var rawValue: UInt8

	public init(rawValue: UInt8) {
		self.rawValue = rawValue
	}
}

extension LCDStatus {
	var mode: Mode {
		get { return Mode(rawValue: rawValue & 0x03)! }
		set { rawValue = (rawValue & 0xfc) | newValue.rawValue }
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
