import Foundation

/// The most primitive ROM type. It contains no support for
/// bank switching and supports only 32KB of data.
public final class ROM: CartridgeType {
    public var externalRAMBytes: [Byte] { [] }

    private var bytes: [Byte]

    public init(bytes: [Byte]) {
        self.bytes = bytes
    }

    public func read(address: Address) -> UInt8 {
        bytes.read(address: address, in: .ROM)
    }

    public func write(byte: Byte, to address: Address) {
        // no-op
    }

    public func loadExternalRAM(bytes: [Byte]) {
        // no-op
    }
}
