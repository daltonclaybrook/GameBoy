public struct CartridgeHeader {
    public enum CGBFlag {
        case nonColorGame
        case colorGameWithBackwardsCompatibility
        case colorGameWithoutBackwardsCompatibility
    }

    public let title: String
    public let romSize: ROMSize
    public let ramSize: RAMSize
    public let cgbFlag: CGBFlag
}

public extension CartridgeHeader.CGBFlag {
    init(byte: Byte) {
        switch byte {
        case 0x80:
            self = .colorGameWithBackwardsCompatibility
        case 0xC0:
            self = .colorGameWithoutBackwardsCompatibility
        default:
            self = .nonColorGame
        }
    }
}
