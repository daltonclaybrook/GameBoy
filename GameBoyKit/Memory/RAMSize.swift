public struct RAMSize {
    /// Size in bytes
    public let size: UInt32
    /// Each bank is 8KB
    public let banks: UInt32
}

public extension RAMSize {
    init?(headerByte: Byte) {
        switch headerByte {
        case 0x00:
            self.init(size: 0, banks: 0)
        case 0x01:
            self.init(size: 2 * 1024, banks: 1)
        case 0x02:
            self.init(size: 8 * 1024, banks: 1)
        case 0x03:
            self.init(size: 32 * 1024, banks: 4)
        case 0x04:
            self.init(size: 128 * 1024, banks: 16)
        case 0x05:
            self.init(size: 64 * 1024, banks: 8)
        default:
            return nil
        }
    }
}
