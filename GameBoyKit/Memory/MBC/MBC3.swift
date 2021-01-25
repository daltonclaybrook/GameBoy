public final class MBC3: CartridgeType {
    private typealias BankNumber = UInt8

    private enum LatchPosition: UInt8 {
        case low = 0
        case high = 1
    }

    public private(set) var externalRAMBytes: [Byte]

    private let romBankSize: UInt32 = 0x4000 // 16KB
    private let ramBankSize: UInt16 = 0x2000 // 8KB
    private let ramBankRange: ClosedRange<UInt8> = 0x00...0x03

    private let romBytes: [Byte]
    private let clock = RTC()

    private var isRAMAndTimerEnabled: Bool = false
    private var currentROMBankNumber: Byte = 0x01
    /// If the value of this register is in the range 0x00...0x03, the
    /// corresponding RAM bank is mapped into 0xa000...0xbfff. If the
    /// value is in the range 0x0a...0x0c, the corresponding RTC
    /// register is mapped into that range instead.
    private var currentRAMBankNumberOrRTCRegister: Byte = 0x00
    private var currentLatchPosition = LatchPosition.low

    /// The calculated ROM bank number
    private var currentROMBank: BankNumber {
        // Values 0x01...0x7f
        max(currentROMBankNumber & 0x7f, 0x01)
    }

    public init(bytes: [Byte]) {
        self.romBytes = bytes
        self.externalRAMBytes = [Byte](repeating: 0, count: Int(ramBankSize) * 4)
    }

    public func write(byte: Byte, to address: Address) {
        switch address {
        case 0x0000...0x1fff: // Set RAM+Timer enabled/disabled
            isRAMAndTimerEnabled = byte & 0x0f == 0x0a
        case 0x2000...0x3fff: // Set ROM bank number
            currentROMBankNumber = byte
        case 0x4000...0x5fff: // Set RAM bank number or RTC register
            currentRAMBankNumberOrRTCRegister = byte
        case 0x6000...0x7fff: // Latch clock data
            // When this register goes from 0x00->0x01, the current
            // time is "latched" into the RTC registers.
            updateLatchPositionIfNecessary(byte: byte)
        case 0xa000...0xbfff: // Write to selected RAM bank or RTC registers
            writeToRAMOrRTC(byte: byte, to: address)
        default:
            break
        }
    }

    public func read(address: Address) -> Byte {
        switch address {
        case 0x0000...0x3fff: // Always ROM bank 0x00
            return romBytes.read(address: address)
        case 0x4000...0x7fff: // Selected ROM bank 0x01-0x7f
            let adjustedAddress = (UInt32(address) - 0x4000) + (UInt32(currentROMBank) * romBankSize)
            return romBytes.read(address: adjustedAddress)
        case 0xa000...0xbfff: // RAM or RTC access
            return readFromRAMOrRTC(at: address)
        default:
            return 0
        }
    }

    public func loadExternalRAM(bytes: [Byte]) {
        self.externalRAMBytes = bytes
    }

    // MARK: - Helpers

    private func readFromRAMOrRTC(at address: Address) -> Byte {
        guard isRAMAndTimerEnabled else { return 0x00 }
        switch currentRAMBankNumberOrRTCRegister {
        case ramBankRange: // RAM bank selected
            let adjustedAddress = (address - 0xa000) + (Address(currentRAMBankNumberOrRTCRegister) * ramBankSize)
            return externalRAMBytes.read(address: adjustedAddress)
        case RTC.registerRange: // RTC register selected
            return clock.read(register: currentRAMBankNumberOrRTCRegister)
        default:
            return 0x00 // If this the correct default?
        }
    }

    private func writeToRAMOrRTC(byte: Byte, to address: Address) {
        guard isRAMAndTimerEnabled else { return }
        switch currentRAMBankNumberOrRTCRegister {
        case ramBankRange: // RAM bank selected
            print("\(Date()): Writing to SRAM...")
            let adjustedAddress = (address - 0xa000) + (Address(currentRAMBankNumberOrRTCRegister) * ramBankSize)
            externalRAMBytes.write(byte: byte, to: adjustedAddress)
        case RTC.registerRange: // RTC register selected
            clock.updateClockRegister(value: byte, register: currentRAMBankNumberOrRTCRegister)
        default:
            break
        }
    }

    private func updateLatchPositionIfNecessary(byte: Byte) {
        guard let position = LatchPosition(rawValue: byte),
              position != currentLatchPosition
        else { return }

        self.currentLatchPosition = position
        if position == .high {
            clock.latchClockData()
        }
    }
}
