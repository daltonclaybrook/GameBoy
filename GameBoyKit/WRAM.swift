public final class WRAM: MemoryAddressable {
	public let addressableRange: ClosedRange<Address> = (0xc000...0xdfff)

	private var data: Data

	public init() {
		let count = Int(addressableRange.upperBound - addressableRange.lowerBound + 1)
		data = Data(repeating: 0, count: count)
	}

	public func read(address: Address) -> Byte {
		return data[address.adjusted(for: self)]
	}

	public func write(byte: Byte, to address: Address) {
		data[address.adjusted(for: self)] = byte
	}
}
