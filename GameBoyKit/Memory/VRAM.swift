public final class VRAM: MemoryAddressable {
    public enum BankNumber: UInt8, CaseIterable {
        /// Contains tile data and tile map data
        case zero
        /// Contains tile data and tile map attribute data. Only available on CGB.
        case one
    }

    struct Constants {
        static let bankSize: UInt32 = 0x2000 // 8KB
        /// Used to select the current bank number for accessing VRAM
        static let bankSelectAddress: Address = 0xff4f
    }

    /// A thread-safe window into the current VRAM data
    var currentView: VRAMView {
        VRAMView(bytes: bytes)
    }

    /// The VRAM becomes locked when the PPU is drawing to the screen.
    /// At this time, reads/writes do not work and reads return a
    /// default value.
    var isBeingReadByPPU: Bool = false
    private(set) var bytes: [Byte]

    private let system: GameBoy.System
    private var currentBankNumber: BankNumber = .zero

    public init(system: GameBoy.System) {
        self.system = system
        self.bytes = [Byte](repeating: 0, count: Int(Constants.bankSize) * BankNumber.allCases.count)
    }

    public func write(byte: Byte, to address: Address) {
        guard !isBeingReadByPPU else { return }
        switch address {
        case MemoryMap.VRAM:
            bytes.write(byte: byte, to: address, in: currentBankNumber)
        case Constants.bankSelectAddress:
            switch system {
            case .dmg:
                break // Bank switching is not supported on the DMG
            case .cgb:
                currentBankNumber = BankNumber(rawValue: byte & 0x01)!
            }
        default:
            fatalError("Invalid address: \(address.hexString)")
        }
    }

    public func read(address: Address) -> Byte {
        read(address: address, privileged: false)
    }

    /// Privileged reads can be performed by the PPU when drawing to
    /// the screen. This will cause the `isLocked` setting to be
    /// ignored.
    public func read(address: Address, privileged: Bool) -> Byte {
        guard !isBeingReadByPPU || privileged else { return 0xff } // is this the right default?

        switch address {
        case MemoryMap.VRAM:
            return bytes.read(address: address, in: currentBankNumber)
        case Constants.bankSelectAddress:
            return currentBankNumber.registerValue
        default:
            fatalError("Invalid address: \(address.hexString)")
        }
    }

    public func readWord(address: Address, privileged: Bool) -> Word {
        let little = read(address: address, privileged: privileged)
        let big = read(address: address + 1, privileged: privileged)
        return (UInt16(big) << 8) | UInt16(little)
    }

    public func loadSavedBytes(_ bytes: [Byte]) {
        self.bytes = bytes
    }
}

public struct VRAMView {
    let bytes: [Byte]

    public func read(address: Address) -> Byte {
        bytes.read(address: address, in: .VRAM)
    }

    public func readWord(address: Address) -> Word {
        let little = read(address: address)
        let big = read(address: address + 1)
        return (UInt16(big) << 8) | UInt16(little)
    }
}

private extension Array where Element == Byte {
    func read(address: Address, in bankNumber: VRAM.BankNumber) -> Byte {
        let adjustedAddress = UInt32(address - MemoryMap.VRAM.lowerBound)
        let byteOffset = bankNumber.byteOffset + adjustedAddress
        return read(address: byteOffset)
    }

    mutating func write(byte: Byte, to address: Address, in bankNumber: VRAM.BankNumber) {
        let adjustedAddress = UInt32(address - MemoryMap.VRAM.lowerBound)
        let byteOffset = bankNumber.byteOffset + adjustedAddress
        write(byte: byte, to: byteOffset)
    }
}

private extension VRAM.BankNumber {
    var byteOffset: UInt32 {
        switch self {
        case .zero:
            return 0
        case .one:
            return VRAM.Constants.bankSize
        }
    }

    var registerValue: Byte {
        // bit 0 contains the bank number and bits 1-7 are all high
        0xfe | rawValue
    }
}
