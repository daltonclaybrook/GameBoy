public final class WRAM: MemoryAddressable {
    private(set) var bytes = [Byte](repeating: 0, count: MemoryMap.WRAM.count)

    public func read(address: Address) -> Byte {
        return bytes.read(address: address, in: .WRAM)
    }

    public func write(byte: Byte, to address: Address) {
        bytes.write(byte: byte, to: address, in: .WRAM)
    }

    public func loadSavedBytes(_ bytes: [Byte]) {
        self.bytes = bytes
    }
}
