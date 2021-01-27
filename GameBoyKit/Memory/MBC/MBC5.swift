final class MBC5: CartridgeType {
    public private(set) var ramBytes: [Byte]
    public weak var delegate: CartridgeDelegate?

    private let romSize: ROMSize
    private let ramSize: RAMSize
    private let romBankSize: UInt32 = 0x4000 // 16KB
    private let ramBankSize: UInt32 = 0x2000 // 8KB
    private let romBytes: [Byte]

    private var currentROMBankNumber: UInt16 = 0x00
    private var currentRAMBankNumber: UInt8 = 0x00
    private var isRAMEnabled: Bool = false

    public init(romBytes: [Byte], ramBytes: [Byte]?, romSize: ROMSize, ramSize: RAMSize) {
        self.romBytes = romBytes
        // There can be up to 4 banks of RAM. When RAM banking is enabled,
        // each bank is 8KB.
        self.ramBytes = ramBytes ?? [Byte](repeating: 0, count: Int(ramSize.size))
        self.romSize = romSize
        self.ramSize = ramSize
    }

    public func write(byte: Byte, to address: Address) {
        switch address {
        case 0x0000...0x1fff: // Set RAM enabled/disabled
            isRAMEnabled = byte & 0x0f == 0x0a
        case 0x2000...0x2fff: // Set lower 8 bits of ROM bank number
            currentROMBankNumber = (currentROMBankNumber & 0xff00) | UInt16(byte)
        case 0x3000...0x3fff: // Set higher 1 bit of ROM bank number
            currentROMBankNumber = (UInt16(byte) & 0x01) << 8 | (currentROMBankNumber & 0x00ff)
        case 0x4000...0x5fff: // Set RAM bank number
            currentRAMBankNumber = byte & 0x0f
        case 0xa000...0xbfff: // Write to selected RAM bank
            guard isRAMEnabled else { return }
            let adjustedAddress = (UInt32(address) - 0xa000) + (UInt32(currentRAMBankNumber) * ramBankSize)
            guard Int(adjustedAddress) < ramSize.size else { return }
            ramBytes.write(byte: byte, to: adjustedAddress)
            delegate?.cartridge(self, didSaveExternalRAM: ramBytes)
        default:
            break
        }
    }

    public func read(address: Address) -> Byte {
        switch address {
        case 0x0000...0x3fff: // Always Bank 0x00
            return romBytes.read(address: address)
        case 0x4000...0x7fff: // Selected Bank 0x01-0x7f
            let adjustedAddress = (UInt32(address) - 0x4000) + (UInt32(currentROMBankNumber) * romBankSize)
            guard Int(adjustedAddress) < romSize.size else { return 0xff }
            return romBytes.read(address: adjustedAddress)
        case 0xa000...0xbfff: // Selected RAM Bank 0x00-0x03
            guard isRAMEnabled else { return 0 } // Is returning zero correct?
            let adjustedAddress = (UInt32(address) - 0xa000) + (UInt32(currentRAMBankNumber) * ramBankSize)
            guard Int(adjustedAddress) < ramSize.size else { return 0xff }
            return ramBytes.read(address: adjustedAddress)
        default:
            return 0xff
        }
    }
}
