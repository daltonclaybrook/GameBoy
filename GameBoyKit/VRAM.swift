public final class VRAM: MemoryAddressable {
	private(set) var bytes = [Byte](repeating: 0, count: MemoryMap.VRAM.count)

	public func read(address: Address) -> Byte {
		return bytes.read(address: address, in: .VRAM)
	}

	public func write(byte: Byte, to address: Address) {
		bytes.write(byte: byte, to: address, in: .VRAM)
	}
}
