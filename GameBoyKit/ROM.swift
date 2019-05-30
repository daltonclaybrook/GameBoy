public final class ROM: MemoryAddressable {
	public let addressableRange: ClosedRange<Address> = (0...0x7fff)

	public func read(address: Address) -> UInt8 {
		// todo
		return 0
	}

	public func write(byte: Byte, to address: Address) {
		// todo
	}
}
