public struct ROMSize {
    /// Size in bytes
    public let size: UInt32
    /// Each bank is 16KB
    public let banks: UInt32
}

public extension ROMSize {
    init?(headerByte: Byte) {
        switch headerByte {
        case 0x00:
            self.init(size: 32 * 1024, banks: 2)
        case 0x01:
            self.init(size: 64 * 1024, banks: 4)
        case 0x02:
            self.init(size: 128 * 1024, banks: 8)
        case 0x03:
            self.init(size: 256 * 1024, banks: 16)
        case 0x04:
            self.init(size: 512 * 1024, banks: 32)
        case 0x05:
            self.init(size: 1 * 1024 * 1024, banks: 64)
        case 0x06:
            self.init(size: 2 * 1024 * 1024, banks: 128)
        case 0x07:
            self.init(size: 4 * 1024 * 1024, banks: 256)
        case 0x08:
            self.init(size: 8 * 1024 * 1024, banks: 512)
        default:
            assertionFailure("Unsupported RAM size header byte: \(headerByte.hexString)")
            return nil
        }
    }
}
