public struct CartridgeFactory {
    public static func makeCartridge(romBytes: [Byte]) -> CartridgeType {
        guard romBytes.count >= 0x0147 else {
            fatalError("ROM is too small")
        }

        var titleBytes = romBytes[0x0134...0x0143]
        while titleBytes.last == 0x00 {
            titleBytes.removeLast()
        }
        let titleData = Data(bytes: &titleBytes, count: titleBytes.count)
        let titleString = String(data: titleData, encoding: .ascii) ?? ""

        let cartridgeType = romBytes[0x0147]
        switch cartridgeType {
        case 0x00, 0x08, 0x09:
            return ROM(title: titleString, bytes: romBytes)
        case 0x01...0x03:
            return MBC1(title: titleString, bytes: romBytes)
        default:
            fatalError("Unsupported cartridge type: \(cartridgeType)")
        }
    }
}
