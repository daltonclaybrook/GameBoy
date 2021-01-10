import Foundation

/// This is the implementation of the first Memory Bank Controller for Game Boy.
/// It enables a ROM to support up to 2MB of data instead of just the 32KB of
/// addressable data by using bank switching.
public final class MBC1: CartridgeType {
    private typealias BankNumber = UInt8

    public let title: String

    /// This mode determines whether writing to 0x4000...0x5fff sets the
    /// RAM bank number or the upper bits of the ROM bank number
    private enum BankMode {
        case ROM, RAM
    }

    private let romBankSize: UInt16 = 0x4000 // 16KB
    private let ramBankSize: UInt16 = 0x2000 // 8KB
    private let romBytes: [Byte]
    private var ramBytes: [Byte]

    /// Determines whether the the variable register is applied to the RAM bank number
    /// or the upper 2 bits of the ROM bank number
    private var currentBankMode: BankMode = .ROM
    /// This is initially bank 1 because bank 0 is always available at 0x0000...0x3fff
    private var currentLowROMBankNumber: Byte = 0x01
    /// The number affects either the RAM bank number or the upper 2 bits of the ROM
    /// bank number depending on the current bank mode
    private var currentRAMOrHighROMBankNumber: Byte = 0x00
    private var isRAMEnabled: Bool = false

    /// The calculated ROM bank number based on the current bank mode
    private var currentROMBank: BankNumber {
        switch currentBankMode {
        case .ROM:
            let highTwoBits = (currentRAMOrHighROMBankNumber & 0x03) << 5
            let bankNumber = highTwoBits | currentLowROMBankNumber
            return getAdjustedROMBankNumberIfNecessary(for: bankNumber)
        case .RAM:
            return getAdjustedROMBankNumberIfNecessary(for: currentLowROMBankNumber)
        }
    }

    /// The calculated RAM bank number base on the current bank mode
    private var currentRAMBank: BankNumber {
        switch currentBankMode {
        case .ROM:
            return 0x00 // Only RAM bank 0 can be used while in ROM mode
        case .RAM:
            return currentRAMOrHighROMBankNumber
        }
    }

    public init(title: String, bytes: [Byte]) {
        self.title = title
        self.romBytes = bytes
        // There can be up to 4 banks of RAM. When RAM banking is enabled,
        // each bank is 8KB.
        // To-do: RAM should be saved between runs of the program if
        // there's a battery in the cartridge.
        self.ramBytes = [Byte](repeating: 0, count: Int(ramBankSize) * 4)
    }

    public func write(byte: Byte, to address: Address) {
        switch address {
        case 0xa000...0xbfff: // Write to selected RAM bank
            guard isRAMEnabled else { return }
            let adjustedAddress = (address - 0xa000) + (Address(currentRAMBank) * ramBankSize)
            ramBytes.write(byte: byte, to: adjustedAddress)
        case 0x0000...0x1fff: // Set RAM enabled/disabled
            isRAMEnabled = byte & 0x0F == 0x0a
        case 0x2000...0x3fff: // Set ROM bank number (lower 5 bits)
            currentLowROMBankNumber = byte & 0x1f // mask of lower 5 bits
        case 0x4000...0x5fff: // Set RAM bank number ~or~ upper 2 bits of ROM bank number
            currentRAMOrHighROMBankNumber = byte & 0x03
        case 0x6000...0x7fff: // Set the current banking mode
            currentBankMode = byte & 0x01 == 1 ? .RAM : .ROM
        default:
            break
        }
    }

    public func read(address: Address) -> Byte {
        switch address {
        case 0x0000...0x3fff: // Always Bank 0x00
            return romBytes.read(address: address)
        case 0x4000...0x7fff: // Selected Bank 0x01-0x7f
            let adjustedAddress = (address - 0x4000) + (Address(currentROMBank) * romBankSize)
            return romBytes.read(address: adjustedAddress)
        case 0xa000...0xbfff: // Selected RAM Bank 0x00-0x03
            guard isRAMEnabled else { return 0 } // Is returning zero correct?
            let adjustedAddress = (address - 0xa000) + (Address(currentRAMBank) * ramBankSize)
            return ramBytes.read(address: adjustedAddress)
        default:
            return 0
        }
    }

    // MARK: - Helpers

    private func getAdjustedROMBankNumberIfNecessary(for bankNumber: BankNumber) -> BankNumber {
        switch bankNumber {
        case 0x00, 0x20, 0x40, 0x60:
            // These banks are unavailable so the next bank is selected
            return bankNumber + 1
        default:
            return bankNumber
        }
    }
}
