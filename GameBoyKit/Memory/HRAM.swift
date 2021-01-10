public final class HRAM: MemoryAddressable {
    private var bytes = [Byte](repeating: 0, count: MemoryMap.HRAM.count)

    public func read(address: Address) -> Byte {
        return bytes.read(address: address, in: .HRAM)
    }

    public func write(byte: Byte, to address: Address) {
        bytes.write(byte: byte, to: address, in: .HRAM)
    }
}
