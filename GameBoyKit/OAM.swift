public final class OAM: MemoryAddressable {
	private var bytes = [Byte](repeating: 0, count: MemoryMap.OAM.count)

	public func read(address: Address) -> Byte {
		return bytes.read(address: address, in: .OAM)
	}

	public func write(byte: Byte, to address: Address) {
		bytes.write(byte: byte, to: address, in: .OAM)
	}

	public func dmaTransfer(byte: Byte, mmu: MMU) {
		let source = Address(byte) * 0x100
		for offset in (0..<UInt16(MemoryMap.OAM.count)) {
			let from = source + offset
			let to = MemoryMap.OAM.lowerBound + offset
			mmu.write(byte: mmu.read(address: from), to: to)
		}
	}
}
