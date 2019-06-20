public struct LCDStatus: RawRepresentable {
	enum Mode: Byte {
		case horizontalBlank
		case verticalBlank
		case searchingOAMRAM
		case transferingToLCD
	}

	private(set) public var rawValue: Byte

	public init(rawValue: Byte) {
		self.rawValue = rawValue
	}
}

extension LCDStatus {
	var lcdYCoincidence: Bool {
		get { return rawValue & 0x04 != 0 }
		set { rawValue = newValue ? rawValue | 0x04 : rawValue & 0xfb }
	}

	var hBlankInterruptEnabled: Bool {
		get { return rawValue & 0x08 != 0 }
		set { rawValue = newValue ? rawValue | 0x08 : rawValue & 0xf7 }
	}

	var vBlankInterruptEnabled: Bool {
		get { return rawValue & 0x10 != 0 }
		set { rawValue = newValue ? rawValue | 0x10 : rawValue & 0xef }
	}

	var oamInterruptEnabled: Bool {
		get { return rawValue & 0x20 != 0 }
		set { rawValue = newValue ? rawValue | 0x20 : rawValue & 0xdf }
	}

	var lcdYCoincidenceInterruptEnabled: Bool {
		get { return rawValue & 0x40 != 0 }
		set { rawValue = newValue ? rawValue | 0x40 : rawValue & 0xbf }
	}

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
