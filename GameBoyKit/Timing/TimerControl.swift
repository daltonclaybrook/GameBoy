import Foundation

public struct TimerControl: RawRepresentable {
    enum InputClock: Byte {
        case slow = 0b00 // 4096 Hz
        case fast = 0b01 // 262144 Hz
        case midFast = 0b10 // 65536 Hz
        case midSlow = 0b11 // 16384 Hz
    }

    private(set) public var rawValue: Byte

    public init(rawValue: Byte) {
        // We only care about the lower 3 bits
        self.rawValue = rawValue & 0x07
    }
}

extension TimerControl {
    var isTimerStarted: Bool {
        rawValue & 0b0100 != 0
    }

    var inputClock: InputClock {
        InputClock(rawValue: rawValue & 0b11) ?? .slow
    }
}

extension TimerControl.InputClock {
    /// The number of cycles which must elapse before counter is incremented
    var counterIncrementRate: Cycles {
        switch self {
        case .slow:
            return 256
        case .midSlow:
            return 64
        case .midFast:
            return 16
        case .fast:
            return 4
        }
    }
}
