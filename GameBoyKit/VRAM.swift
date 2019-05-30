public final class VRAM: MemoryAddressable {
	public let addressableRange: ClosedRange<Address> = (0x8000...0x9fff)

	private var data: Data

	public init() {
		let capacity = Int(addressableRange.upperBound + 1 - addressableRange.lowerBound)
		data = Data(capacity: capacity)
	}

	public func read(address: Address) -> Byte {
		return data[Int(address - addressableRange.lowerBound)]
	}

	public func write(byte: Byte, to address: Address) {

	}
}
