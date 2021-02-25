public struct CartridgeInfo {
    public let header: CartridgeHeader
    public let cartridge: CartridgeType
}

public struct CartridgeFactory {
    public struct Registers {
        static let titleRange: ClosedRange<Address> = 0x0134...0x0143
        static let cartridgeType: Address = 0x0147
        static let romSize: Address = 0x0148
        static let ramSize: Address = 0x0149
        /// Game Boy Color flag
        static let cgbFlag: Address = 0x0143
        static let fullHeaderRange: ClosedRange<Address> = 0x0100...0x014f
    }

    public enum Error: Swift.Error {
        case romIncorrectSize
        case ramIncorrectSize
        case invalidCartridgeHeader
        case unsupportedCartridgeType(name: String)
    }

    public static func makeCartridge(romBytes: [Byte], externalRAMBytes: [Byte]?) throws -> CartridgeInfo {
        guard romBytes.count >= Registers.fullHeaderRange.upperBound else {
            throw Error.romIncorrectSize
        }

        let title = getCartridgeTitle(from: romBytes)
        guard let romSize = ROMSize(headerByte: romBytes.read(address: Registers.romSize)),
              let ramSize = RAMSize(headerByte: romBytes.read(address: Registers.ramSize))
        else { throw Error.invalidCartridgeHeader }

        if romBytes.count != romSize.size {
            throw Error.romIncorrectSize
        }
        if let ramBytes = externalRAMBytes, ramBytes.count != ramSize.size {
            throw Error.ramIncorrectSize
        }

        let cgbFlag = CartridgeHeader.CGBFlag(byte: romBytes.read(address: Registers.cgbFlag))

        let header = CartridgeHeader(
            title: title,
            romSize: romSize,
            ramSize: ramSize,
            cgbFlag: cgbFlag
        )

        let cartridgeTypeByte = romBytes.read(address: Registers.cartridgeType)
        let cartridgeType: CartridgeType
        switch cartridgeTypeByte {
        case 0x00, 0x08, 0x09:
            cartridgeType = ROM(romBytes: romBytes)
        case 0x01...0x03:
            cartridgeType = MBC1(romBytes: romBytes, ramBytes: externalRAMBytes, romSize: romSize, ramSize: ramSize)
        case 0x05, 0x06:
            throw Error.unsupportedCartridgeType(name: "MBC2")
        case 0x0b...0x0d:
            throw Error.unsupportedCartridgeType(name: "MMM01")
        case 0x0f...0x13:
            cartridgeType = MBC3(romBytes: romBytes, ramBytes: externalRAMBytes, romSize: romSize, ramSize: ramSize)
        case 0x19...0x1e:
            cartridgeType = MBC5(romBytes: romBytes, ramBytes: externalRAMBytes, romSize: romSize, ramSize: ramSize)
        case 0x20:
            throw Error.unsupportedCartridgeType(name: "MBC6")
        case 0x22:
            throw Error.unsupportedCartridgeType(name: "MBC7")
        case 0xfc:
            throw Error.unsupportedCartridgeType(name: "POCKET CAMERA")
        case 0xfd:
            throw Error.unsupportedCartridgeType(name: "BANDAI TAMA5")
        case 0xfe:
            throw Error.unsupportedCartridgeType(name: "HuC3")
        case 0xff:
            throw Error.unsupportedCartridgeType(name: "HuC1")
        default:
            throw Error.unsupportedCartridgeType(name: "Unknown \(cartridgeTypeByte.hexString)")
        }
        return CartridgeInfo(header: header, cartridge: cartridgeType)
    }

    // MARK: - Helpers

    private static func getCartridgeTitle(from romBytes: [Byte]) -> String {
        var titleByteRegion = romBytes[Registers.titleRange]
        var titleBytes: [Byte] = []
        while !titleByteRegion.isEmpty && titleByteRegion.first != 0x00 { // null terminator
            titleBytes.append(titleByteRegion.removeFirst())
        }
        return String(bytes: titleBytes, encoding: .ascii) ?? ""
    }
}
