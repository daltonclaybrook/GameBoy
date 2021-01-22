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

    public enum SelectedKeys {
        case directionKeys
        case buttonKeys
    }

    public private(set) var rawValue: UInt8
    public weak var delegate: JoypadDelegate?

    private var pressedKeys: Set<Key> = []
    private var selectedKeys: SelectedKeys = .directionKeys

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public convenience init() {
        // Since a button is considered "selected" if its corresponding bit
        // is 0, setting all bits high means no buttons are selected.
        self.init(rawValue: 0xff)
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
        //
        // then bitwise AND with selection mask. Check if != 0.
        // 0001_0000 & 0001_0000 != 0
        let invertedSelection = ~byte
        if invertedSelection & SelectedKeys.directionKeys.selectionMask != 0 {
            selectedKeys = .directionKeys
        } else if invertedSelection & SelectedKeys.buttonKeys.selectionMask != 0 {
            selectedKeys = .buttonKeys
        }

        updateRawValue()
    }

    public func keyWasPressed(_ key: Key) {
        pressedKeys.insert(key)
        updateRawValue()
        if selectedKeys.allKeysInSelection.contains(key) {
            delegate?.joypadDidRequestInterrupt(self)
        }
    }

    public func keyWasReleased(_ key: Key) {
        pressedKeys.remove(key)
        updateRawValue()
    }

    // MARK: - Helpers

    private func updateRawValue() {
        var rawValue = 0xff ^ selectedKeys.selectionMask
        let keysInSelection = selectedKeys.allKeysInSelection
        let pressedKeysInSelection = pressedKeys.intersection(keysInSelection)
        pressedKeysInSelection.forEach { key in
            rawValue ^= key.inputMask
        }
        self.rawValue = rawValue
    }
}

extension Joypad.Key {
    var inputMask: Byte {
        switch self {
        case .right, .a:
            return 0b0001
        case .left, .b:
            return 0b0010
        case .up, .select:
            return 0b0100
        case .down, .start:
            return 0b1000
        }
    }
}

extension Joypad.SelectedKeys {
    var selectionMask: Byte {
        switch self {
        case .directionKeys:
            return 0b01_0000
        case .buttonKeys:
            return 0b10_0000
        }
    }

    var allKeysInSelection: Set<Joypad.Key> {
        switch self {
        case .directionKeys:
            return [.right, .left, .up, .down]
        case .buttonKeys:
            return [.a, .b, .select, .start]
        }
    }
}
