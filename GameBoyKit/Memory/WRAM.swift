public final class WRAM: MemoryAddressable {
    private typealias BankNumber = UInt8

    struct Constants {
        static let numberOfBanks: UInt8 = 8
        static let bankSize: UInt32 = 0x1000 // 4KB
        /// Range for accessing bank 0
        static let lowerRange: ClosedRange<Address> = 0xc000...0xcfff
        /// Range for accessing banks 1-7
        static let upperRange: ClosedRange<Address> = 0xd000...0xdfff
        static let fullRange: ClosedRange<Address> = lowerRange.lowerBound...upperRange.upperBound
        /// Used to select the current bank number for accessing WRAM
        static let bankSelectAddress: Address = 0xff70
    }

    private let system: GameBoy.System

    private var bytes: [Byte]
    private var currentBankNumber: BankNumber = 0x01

    public init(system: GameBoy.System) {
        self.system = system
        self.bytes = [Byte](repeating: 0, count: Int(Constants.bankSize) * Int(Constants.numberOfBanks))
    }

    public func read(address: Address) -> Byte {
        switch address {
        case Constants.lowerRange:
            return bytes.read(address: address, in: Constants.lowerRange)
        case Constants.upperRange:
            let adjustedAddress = UInt32(address - Constants.lowerRange.lowerBound)
            let byteOffset = UInt32(currentBankNumber) * Constants.bankSize + adjustedAddress
            return bytes.read(address: byteOffset)
        case Constants.bankSelectAddress:
            return currentBankNumber
        default:
            fatalError("Invalid address: \(address.hexString)")
        }
    }

    public func write(byte: Byte, to address: Address) {
        switch address {
        case Constants.lowerRange:
            bytes.write(byte: byte, to: address, in: Constants.lowerRange)
        case Constants.upperRange:
            let adjustedAddress = UInt32(address - Constants.lowerRange.lowerBound)
            let byteOffset = UInt32(currentBankNumber) * Constants.bankSize + adjustedAddress
            bytes.write(byte: byte, to: byteOffset)
        case Constants.bankSelectAddress:
            switch system {
            case .dmg:
                break // DMG does not support WRAM bank switching
            case .cgb:
                // range 1-7
                currentBankNumber = max(byte & 0x07, 1)
            }
        default:
            fatalError("Invalid address: \(address.hexString)")
        }
    }

    public func loadSavedBytes(_ bytes: [Byte]) {
        self.bytes = bytes
    }
}
