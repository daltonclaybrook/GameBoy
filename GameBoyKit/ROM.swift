public final class ROM: MemoryAddressable {
	public let addressableRange: ClosedRange<Address> = (0...0x7fff)
	private var data: Data

	init() {
		let count = Int(addressableRange.upperBound - addressableRange.lowerBound + 1)
		data = Data(repeating: 0, count: count)
	}

	func loadROM(data: Data) {
		self.data[0..<data.count] = data
	}

	public func read(address: Address) -> UInt8 {
		return data[address.adjusted(for: self)]
	}

	public func write(byte: Byte, to address: Address) {
		// no-op (at the moment)
	}
}
