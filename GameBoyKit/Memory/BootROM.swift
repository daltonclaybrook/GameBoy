import Foundation

/// Represents the original Game Boy boot ROM, or BIOS.
/// In the future, this might be more extensible to support
/// boot ROMs from multiple different kinds of systems such
/// as the Game Boy Color.
public final class BootROM: MemoryMasking {
    public let maskRange: ClosedRange<Address> = 0x00...0xff

    private let bytes: [Byte]

    public init(bytes: [Byte]) {
        self.bytes = bytes
    }

    public func write(byte: Byte, to address: Address) {
        // no-op
    }

    public func read(address: Address) -> Byte {
        bytes.read(address: address)
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
