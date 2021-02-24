/// Type used to facilitate speed-switching on Game Boy Color
public final class SystemSpeed: MemoryAddressable {
    public enum Mode: UInt8 {
        case normal
        case double
    }

    public private(set) var isPreparedToSwitchModes = false
    public private(set) var currentMode: Mode = .normal

    private let prepareRegister: Address = 0xff4d
    private let system: GameBoy.System

    /// This initializer returns nil if the provided system does not support double speed mode
    init(system: GameBoy.System) {
        self.system = system
    }

    public func write(byte: Byte, to address: Address) {
        guard address == prepareRegister else {
            fatalError("Invalid address: \(address.hexString)")
        }
        switch system {
        case .dmg:
            break // This system does not support switching speeds
        case .cgb:
            isPreparedToSwitchModes = byte & 0x01 == 1
        }
    }

    public func read(address: Address) -> Byte {
        guard address == prepareRegister else {
            fatalError("Invalid address: \(address.hexString)")
        }
        switch system {
        case .dmg:
            // This system does not support switching speeds
            return 0
        case .cgb:
            let preparedBit: UInt8 = isPreparedToSwitchModes ? 1 : 0
            return (currentMode.rawValue << 7) | preparedBit
        }
    }

    public func toggleSpeedMode() {
        precondition(isPreparedToSwitchModes, "Cannot toggle the speed mode unless prepared")
        defer { isPreparedToSwitchModes = false }

        switch currentMode {
        case .normal:
            currentMode = .double
        case .double:
            currentMode = .normal
        }
    }
}
