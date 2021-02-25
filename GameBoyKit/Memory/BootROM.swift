import Foundation

public protocol BootRomDelegate: AnyObject {
    func bootROMShouldBeDisabled(_ bootRom: BootROM)
}

/// Represents the original Game Boy boot ROM, or BIOS.
/// In the future, this might be more extensible to support
/// boot ROMs from multiple different kinds of systems such
/// as the Game Boy Color.
public final class BootROM: MemoryMasking {
    public weak var delegate: BootRomDelegate?

    private let bytes: [Byte]
    private let disableRegister: Address = 0xff50
    private let byteRange: ClosedRange<Address>

    public init(bytes: [Byte]) {
        self.bytes = bytes
        let upperBound = Address(bytes.count) - 1
        self.byteRange = 0x00...upperBound
    }

    /// Returns true if the byte range of the boot ROM contains the address and the address
    /// isn't part of the cartridge header
    public func isAddressMasked(_ address: Address) -> Bool {
        byteRange.contains(address) &&
            !CartridgeFactory.Registers.fullHeaderRange.contains(address)
    }

    public func write(byte: Byte, to address: Address) {
        if address == disableRegister && byte != 0 {
            delegate?.bootROMShouldBeDisabled(self)
        }
    }

    public func read(address: Address) -> Byte {
        guard address != disableRegister else { return 0xff }
        return bytes.read(address: address)
    }
}

public extension BootROM {
    /// Used to make the boot ROM for the appropriate system
    convenience init(system: GameBoy.System) throws {
        switch system {
        case .dmg:
            try self.init(fileName: "bootrom", fileExtension: "gb")
        case .cgb:
            try self.init(fileName: "bootrom", fileExtension: "gbc")
        }
    }

    private convenience init(fileName: String, fileExtension: String) throws {
        let fileURL = Bundle(for: BootROM.self).url(forResource: fileName, withExtension: fileExtension)!
        let fileData = try Data(contentsOf: fileURL)
        self.init(bytes: [Byte](fileData))
    }
}
