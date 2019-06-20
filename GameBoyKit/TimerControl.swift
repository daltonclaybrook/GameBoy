import Foundation

public struct TimerControl: RawRepresentable {
	enum InputClock: Byte {
		case slow
		case fast
		case midFast
		case midSlow
	}

	private(set) public var rawValue: Byte

	public init(rawValue: Byte) {
		// We only care about the lower 3 bits
		self.rawValue = rawValue & 0x07
	}
}

extension TimerControl {
	var timerIsStarted: Bool {
		get { return rawValue & 0x04 != 0 }
		set { rawValue = newValue ? rawValue | 0x04 : rawValue & 0xfb }
	}

	var inputClock: InputClock {
		get { return InputClock(rawValue: rawValue & 0x03) ?? .slow }
		set { rawValue = (rawValue & 0x04) | newValue.rawValue }
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
