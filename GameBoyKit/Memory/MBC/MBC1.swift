import Foundation

/// This is the implementation of the first Memory Bank Controller for Game Boy.
/// It enables a ROM to support up to 2MB of data instead of just the 32KB of
/// addressable data by using bank switching.
public final class MBC1: MemoryAddressable {
    private typealias BankNumber = UInt8

    /// This mode determines whether writing to 0x4000...0x5fff sets the
    /// RAM bank number or the upper bits of the ROM bank number
    private enum BankingMode {
        case ROM, RAM
    }

    private var romBanks: [BankNumber: [Byte]]
    private var ramBanks: [BankNumber: [Byte]]
    private var currentROMBank: BankNumber = 0x01
    private var currentRAMBank: BankNumber = 0x00
    private var currentBankingMode: BankingMode = .ROM
    private var isRAMEnabled: Bool = false

    public init() {
        self.romBanks = Self.createROMBanks()
        self.ramBanks = Self.createRAMBanks()
    }

    public func write(byte: Byte, to address: Address) {
        switch address {
        case 0xa000...0xbfff: // Write to selected RAM bank
            guard isRAMEnabled else { return }
            ramBanks[currentRAMBank]!.write(byte: byte, to: address, in: .externalRAM)
        case 0x0000...0x1fff: // Set RAM enabled/disabled
            isRAMEnabled = byte & 0x0F == 0x0a
        case 0x2000...0x3fff: // Set ROM bank number (lower 5 bits)
            currentROMBank = (currentROMBank & 0b01100000) | (byte & 0b00011111)
            break // todo
        case 0x4000...0x5fff: // Set RAM bank number ~or~ upper 2 bits of ROM bank number depending on current mode
            switch currentBankingMode {
            case .ROM:
                currentROMBank = (currentROMBank & 0b00011111) | ((byte & 0x03) << 5)
            case .RAM:
                currentRAMBank = byte & 0x03
            }
            break
        case 0x6000...0x7fff: // Set the current banking mode
            currentBankingMode = byte & 0x01 == 1 ? .RAM : .ROM
        default:
            break
        }
    }

    public func read(address: Address) -> Byte {
        switch address {
        case 0x0000...0x3fff: // Always Bank 0x00
            return romBanks[0]!.read(address: address, in: .ROMBank0)
        case 0x4000...0x7fff: // Selected Bank 0x01-0x7f
            return romBanks[currentROMBank]!.read(address: address, in: .ROMBankN)
        case 0xa000...0xbfff: // Selected RAM Bank 0x00-0x03
            guard isRAMEnabled else { return 0 } // Is returning zero correct?
            return ramBanks[currentRAMBank]!.read(address: address, in: .externalRAM)
        default:
            return 0
        }
    }

    // MARK: - Helpers

    private static func createROMBanks() -> [BankNumber: [Byte]] {
        createMemoryBanks(
            count: 128,
            bytesPerBank: 0x4000, // 16KB
            skipBankNumbers: [0x20, 0x40, 0x60]
        )
    }

    private static func createRAMBanks() -> [BankNumber: [Byte]] {
        // 4 banks, 8KB each
        createMemoryBanks(count: 4, bytesPerBank: 0x2000)
    }

    private static func createMemoryBanks(count: BankNumber, bytesPerBank: Int, skipBankNumbers: Set<BankNumber> = []) -> [BankNumber: [Byte]] {
        var memoryBanks: [BankNumber: [Byte]] = [:]
        (0..<count).forEach { bankNumber in
            guard !skipBankNumbers.contains(bankNumber) else { return }
            memoryBanks[bankNumber] = [Byte](repeating: 0, count: bytesPerBank)
        }
        return memoryBanks
    }
}
