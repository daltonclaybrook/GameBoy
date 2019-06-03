public final class OAM: MemoryAddressable {
	public let addressableRange: ClosedRange<Address> = (0xfe00...0xfe9f)

	private var data: Data
	private unowned let mmu: MMU

	public init(mmu: MMU) {
		let count = Int(addressableRange.upperBound + 1 - addressableRange.lowerBound)
		self.mmu = mmu
		data = Data(repeating: 0, count: count)
	}

	public func read(address: Address) -> Byte {
		return data[address.adjusted(for: self)]
	}

	public func write(byte: Byte, to address: Address) {
		data[address.adjusted(for: self)] = byte
	}

	public func dmaTransfer(byte: Byte) {
		let source = Address(byte) * 0x100
		let count = addressableRange.upperBound + 1 - addressableRange.lowerBound
		for offset in (0..<count) {
			let from = source + offset
			let to = addressableRange.lowerBound + offset
			mmu.write(byte: mmu.read(address: from), to: to)
		}
	}
}
