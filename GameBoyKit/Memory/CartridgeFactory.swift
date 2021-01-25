public struct CartridgeFactory {
    public enum Error: Swift.Error {
        case romIncorrectSize
        case ramIncorrectSize
        case invalidCartridgeHeader
    }

    public static func makeCartridge(romBytes: [Byte], externalRAMBytes: [Byte]?) throws -> (CartridgeType, CartridgeHeader) {
        guard romBytes.count >= 0x014f else {
            throw Error.romIncorrectSize
        }

        let title = getCartridgeTitle(from: romBytes)
        guard let romSize = ROMSize(headerByte: romBytes[0x0148]),
              let ramSize = RAMSize(headerByte: romBytes[0x0149])
        else { throw Error.invalidCartridgeHeader }

        if romBytes.count != romSize.size {
            throw Error.romIncorrectSize
        }
        if let ramBytes = externalRAMBytes, ramBytes.count != ramSize.size {
            throw Error.ramIncorrectSize
        }

        let header = CartridgeHeader(title: title, romSize: romSize, ramSize: ramSize)
        let cartridgeType = romBytes[0x0147]
        let cartridge: CartridgeType
        switch cartridgeType {
        case 0x00, 0x08, 0x09:
            cartridge = ROM(romBytes: romBytes)
        case 0x01...0x03:
            cartridge = MBC1(romBytes: romBytes, ramBytes: externalRAMBytes, romSize: romSize, ramSize: ramSize)
        case 0x05, 0x06:
            fatalError("MBC2 is currently unsupported")
        case 0x0b...0x0d:
            fatalError("MMM01 is currently unsupported")
        case 0x0f...0x13:
            cartridge = MBC3(romBytes: romBytes, ramBytes: externalRAMBytes, romSize: romSize, ramSize: ramSize)
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
        return (cartridge, header)
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
