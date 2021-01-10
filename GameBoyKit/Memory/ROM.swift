import Foundation

/// The most primitive ROM type. It contains no support for
/// bank switching and supports only 32KB of data.
public final class ROM: CartridgeType {
    public let title: String
    private var bytes: [Byte]

    public init(title: String, bytes: [Byte]) {
        self.title = title
        self.bytes = bytes
    }

	public func read(address: Address) -> UInt8 {
		bytes.read(address: address, in: .ROM)
	}

	public func write(byte: Byte, to address: Address) {
		// no-op
	}
}
