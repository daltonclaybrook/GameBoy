public final class WavePattern: MemoryAddressable {
    public private(set) var bytes: [Byte]

    private let memoryRange: ClosedRange<Address> = 0xff30...0xff3f

    public init() {
        bytes = [Byte](repeating: 0, count: memoryRange.count)
    }

    public func write(byte: Byte, to address: Address) {
        bytes.write(byte: byte, to: address, in: memoryRange)
    }

    public func read(address: Address) -> Byte {
        bytes.read(address: address, in: memoryRange)
    }
}
