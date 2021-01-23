public struct CartridgeFactory {
    public static func makeCartridge(romBytes: [Byte]) -> CartridgeType {
        guard romBytes.count >= 0x0147 else {
            fatalError("ROM is too small")
        }

        let titleString = getCartridgeTitle(from: romBytes)

        let cartridgeType = romBytes[0x0147]
        switch cartridgeType {
        case 0x00, 0x08, 0x09:
            return ROM(title: titleString, bytes: romBytes)
        case 0x01...0x03:
            return MBC1(title: titleString, bytes: romBytes)
        case 0x05, 0x06:
            fatalError("MBC2 is currently unsupported")
        case 0x0b...0x0d:
            fatalError("MMM01 is currently unsupported")
        case 0x0f...0x13:
            fatalError("MBC3 is currently unsupported")
        case 0x19...0x1e:
            fatalError("MBC5 is currently unsupported")
        case 0x20:
            fatalError("MBC6 is currently unsupported")
        case 0x22:
            fatalError("MBC7 is currently unsupported")
        case 0xfc:
            fatalError("POCKET CAMERA is currently unsupported")
        case 0xfd:
            fatalError("BANDAI TAMA5 is currently unsupported")
        case 0xfe:
            fatalError("HuC3 is currently unsupported")
        case 0xff:
            fatalError("HuC1 is currently unsupported")
        default:
            fatalError("Unsupported cartridge type: \(String(format: "%02X", cartridgeType))")
        }
    }

    // MARK: - Helpers

    private static func getCartridgeTitle(from romBytes: [Byte]) -> String {
        var titleByteRegion = romBytes[0x0134...0x0143]
        var titleBytes: [Byte] = []
        while !titleByteRegion.isEmpty && titleByteRegion.first != 0x00 { // null terminator
            titleBytes.append(titleByteRegion.removeFirst())
        }
        return String(bytes: titleBytes, encoding: .ascii) ?? ""
    }
}
