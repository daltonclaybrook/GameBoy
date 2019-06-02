public struct IORegisters {
	public static let lcdControl: Address = 0xff40
	public static let lcdStatus: Address = 0xff41
}

public final class IO: MemoryAddressable {
	public let addressableRange: ClosedRange<Address> = (0xff00...0xff7f)
	private var data: Data

	init() {
		let capacity = Int(addressableRange.upperBound + 1 - addressableRange.lowerBound)
		data = Data(capacity: capacity)
	}

	public func read(address: Address) -> Byte {
		return data[address.adjusted(for: self)]
	}

	public func write(byte: Byte, to address: Address) {
		data[address.adjusted(for: self)] = byte
	}
}

extension IO {
	var lcdControl: LCDControl {
		return LCDControl(rawValue: read(address: IORegisters.lcdControl))
	}

	var lcdStatus: LCDStatus {
		return LCDStatus(rawValue: read(address: IORegisters.lcdStatus))
	}
}
