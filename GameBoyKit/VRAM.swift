public final class VRAM: MemoryAddressable {
	public let addressableRange: ClosedRange<Address> = (0x8000...0x9fff)

	private unowned let ppu: PPU
	private var data: Data

	public init(ppu: PPU) {
		let count = Int(addressableRange.upperBound + 1 - addressableRange.lowerBound)
		data = Data(repeating: 0, count: count)
		self.ppu = ppu
	}

	public func read(address: Address) -> Byte {
		return data[address.adjusted(for: self)]
	}

	public func write(byte: Byte, to address: Address) {
		data[address.adjusted(for: self)] = byte
	}
}
