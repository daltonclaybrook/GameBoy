public final class VRAM: MemoryAddressable {
	public let addressableRange: ClosedRange<Address> = (0x8000...0x9fff)

	private(set) var data: Data

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
