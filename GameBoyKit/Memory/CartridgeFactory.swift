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
