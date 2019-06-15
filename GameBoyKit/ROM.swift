public final class ROM: MemoryAddressable {
	private var bytes = [Byte](repeating: 0, count: MemoryMap.ROM.count)

	public func loadROM(data: Data) {
		// todo: rom banks
		if self.bytes.count > data.count {
			self.bytes[0..<data.count] = ArraySlice<Byte>(data)
		} else {
			self.bytes = [Byte](data)
		}
	}

	public func read(address: Address) -> UInt8 {
		return bytes.read(address: address, in: .ROM)
	}

	public func write(byte: Byte, to address: Address) {
		// no-op (at the moment)
	}
}
