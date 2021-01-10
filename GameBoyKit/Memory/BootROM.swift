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

extension BootROM {
    /// Used to make the boot ROM from the original Game Boy, code-named DMG.
    public static func dmgBootRom() throws -> BootROM {
        let fileURL = Bundle(for: BootROM.self).url(forResource: "bootrom", withExtension: "gb")!
        let fileData = try Data(contentsOf: fileURL)
        return self.init(bytes: [Byte](fileData))
    }
}
