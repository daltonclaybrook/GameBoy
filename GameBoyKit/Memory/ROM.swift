import Foundation

/// The most primitive ROM type. It contains no support for
/// bank switching and supports only 32KB of data.
public final class ROM: CartridgeType {
    public var ramBytes: [Byte] { [] }
    public weak var delegate: CartridgeDelegate?

    private var romBytes: [Byte]

    public init(romBytes: [Byte]) {
        self.romBytes = romBytes
    }

    public func read(address: Address) -> UInt8 {
        romBytes.read(address: address, in: .ROM)
    }

    public func write(byte: Byte, to address: Address) {
        // no-op
    }

    public func loadExternalRAM(bytes: [Byte]) {
        // no-op
    }
}
