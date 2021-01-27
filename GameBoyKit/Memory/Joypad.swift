public protocol JoypadDelegate: AnyObject {
    func joypadDidRequestInterrupt(_ joypad: Joypad)
}

public final class Joypad: RawRepresentable {
    public enum Key {
        case right
        case left
        case up
        case down
        case a
        case b
        case select
        case start
    }

    public private(set) var rawValue: UInt8
    public weak var delegate: JoypadDelegate?

    private var pressedKeys: Set<Key> = []
    private var selectedKeysRegister: Register = .allKeysSelected

    public init?(rawValue: UInt8) {
        assertionFailure("Though required by the protocol, this initializer should not be used")
        return nil
    }

    public init() {
        self.rawValue = 0x00
        updateRawValue()
    }

    public func update(byte: Byte) {
        // to select direction keys, use byte:
        // 1110_1111
        //    ^ a cleared bit represents selection
        //
        // to check for selection of direction keys:
        // bitwise NOT the byte:
        // 0001_0000
        //    ^ indicates selection
        let invertedSelection = ~byte

        // Bits 4 & 5 are used for selection, so mask is 0011_0000, i.e. 0x30
        selectedKeysRegister = Register(rawValue: invertedSelection & 0x30)
        updateRawValue()
    }

    public func keyWasPressed(_ key: Key) {
        pressedKeys.insert(key)
        updateRawValue()
        delegate?.joypadDidRequestInterrupt(self)
    }

    public func keyWasReleased(_ key: Key) {
        pressedKeys.remove(key)
        updateRawValue()
    }

    // MARK: - Helpers

    private func updateRawValue() {
        var invertedRawValue = selectedKeysRegister.intersection(.allKeysSelected).rawValue
        if selectedKeysRegister.contains(.directionKeysSelected) {
            let pressedDirectionKeys = pressedKeys.intersection(Key.allDirectionKeys)
            invertedRawValue |= pressedDirectionKeys.registerMask.rawValue
        }
        if selectedKeysRegister.contains(.buttonKeysSelected) {
            let pressedButtonKeys = pressedKeys.intersection(Key.allButtonKeys)
            invertedRawValue |= pressedButtonKeys.registerMask.rawValue
        }
        self.rawValue = ~invertedRawValue
    }
}

public extension Joypad {
    struct Register: OptionSet {
        public let rawValue: UInt8

        // Direction keys
        public static let right = Register(rawValue: 1 << 0)
        public static let left = Register(rawValue: 1 << 1)
        public static let up = Register(rawValue: 1 << 2)
        public static let down = Register(rawValue: 1 << 3)
        public static let allDirectionKeys: Register = [.right, .left, .up, .down]

        // Button keys
        public static let a = Register(rawValue: 1 << 0)
        public static let b = Register(rawValue: 1 << 1)
        public static let select = Register(rawValue: 1 << 2)
        public static let start = Register(rawValue: 1 << 3)
        public static let allButtonKeys: Register = [.a, .b, .select, .start]

        // Selection
        public static let directionKeysSelected = Register(rawValue: 1 << 4)
        public static let buttonKeysSelected = Register(rawValue: 1 << 5)
        public static let allKeysSelected: Register = [.directionKeysSelected, .buttonKeysSelected]

        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }
    }
}

extension Joypad.Key {
    static let allDirectionKeys: Set<Joypad.Key> = [.right, .left, .up, .down]
    static let allButtonKeys: Set<Joypad.Key> = [.a, .b, .select, .start]

    var registerMask: Joypad.Register {
        switch self {
        case .right:
            return .right
        case .left:
            return .left
        case .up:
            return .up
        case .down:
            return .down
        case .a:
            return .a
        case .b:
            return .b
        case .select:
            return .select
        case .start:
            return .start
        }
    }
}

extension Set where Element == Joypad.Key {
    var registerMask: Joypad.Register {
        reduce(into: []) { register, key in
            register.formUnion(key.registerMask)
        }
    }
}
