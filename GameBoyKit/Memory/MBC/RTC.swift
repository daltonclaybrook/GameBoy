import Foundation

public final class RTC: RawRepresentable {
    private struct InternalClock {
        var seconds: UInt8 = 0 // 0-59
        var minutes: UInt8 = 0 // 0-59
        var hours: UInt8 = 0 // 0-23
        var days: UInt16 = 0 // 0-511
        var dayCounterCarried: Bool = false
    }

    public typealias Register = UInt8
    private enum Registers {
        static let seconds: Register = 0x08
        static let minutes: Register = 0x09
        static let hours: Register = 0x0a
        static let lowDays: Register = 0x0b
        static let highDaysCarryHalt: Register = 0x0c
    }

    public static let registerRange: ClosedRange<Register> = 0x08...0x0c
    public private(set) var rawValue: [Byte]

    private let ticksPerSecond: UInt64 = 10
    private var timer: Foundation.Timer?
    private var totalTicks: UInt64 = 0
    // Todo: since the clock is driven by a batter in the cartridge, it
    // should not be reset on instantiation
    private var internalClock = InternalClock()

    private var isTimerRunning: Bool {
        return timer?.isValid ?? false
    }

    private var highDaysCarryHaltValue: Byte {
        let offset = Self.registerRange.lowerBound.distance(to: Registers.highDaysCarryHalt)
        return rawValue[offset]
    }

    public init(rawValue: [Byte]) {
        guard rawValue.count == Self.registerRange.count else {
            fatalError("RTC must be initialized with exactly 5 bytes")
        }
        self.rawValue = rawValue
        startTimer()
    }

    public convenience init() {
        self.init(rawValue: [Byte](repeating: 0, count: Self.registerRange.count))
    }

    /// Updates the RTC register for the given address. The address must be
    /// in the range 0x08...0x0c.
    public func updateClockRegister(value: Byte, address: Register) {
        guard Self.registerRange.contains(address) else {
            fatalError("The provided address is outside of the allowed range")
        }
        update(value: value, for: address)
        handleRegisterWasUpdated(value: value, address: address)
    }

    /// Causes the internal clock data to be applied to the external registers
    public func latchClockData() {
        update(value: internalClock.seconds, for: Registers.seconds)
        update(value: internalClock.minutes, for: Registers.minutes)
        update(value: internalClock.hours, for: Registers.hours)

        let lowDays = Byte(internalClock.days & 0xff)
        update(value: lowDays, for: Registers.lowDays)

        let highDays = Byte((internalClock.days >> 8) & 0x01)
        // 7th bit is high if carry occurred
        let carryFlag: Byte = internalClock.dayCounterCarried ? 0x80 : 0x00
        // Preserve bits 1-6
        let preserve = highDaysCarryHaltValue & 0x7e
        let newHighDaysCarryHalt = carryFlag | preserve | highDays
        update(value: newHighDaysCarryHalt, for: Registers.highDaysCarryHalt)
    }

    // MARK: - Helpers

    private func startTimer() {
        let interval = 1.0 / Double(ticksPerSecond)
        self.timer = .scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.timerDidTick()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func timerDidTick() {
        totalTicks += 1
        guard totalTicks % ticksPerSecond == 0 else { return }
        internalClock.seconds += 1
        guard internalClock.seconds > 59 else { return }
        internalClock.seconds = 0
        internalClock.minutes += 1
        guard internalClock.minutes > 59 else { return }
        internalClock.minutes = 0
        internalClock.hours += 1
        guard internalClock.hours > 23 else { return }
        internalClock.hours = 0
        internalClock.days += 1
        guard internalClock.days > 511 else { return }
        internalClock.days = 0
        internalClock.dayCounterCarried = true
    }

    private func handleRegisterWasUpdated(value: Byte, address: Register) {
        switch address {
        case Registers.seconds:
            internalClock.seconds = value
        case Registers.minutes:
            internalClock.minutes = value
        case Registers.hours:
            internalClock.hours = value
        case Registers.lowDays:
            internalClock.days = (internalClock.days & 0x100) | UInt16(value)
        case Registers.highDaysCarryHalt:
            handleHighDaysCarryHaltRegisterWasUpdated(value: value)
        default:
            break // invalid address
        }
    }

    private func handleHighDaysCarryHaltRegisterWasUpdated(value: Byte) {
        internalClock.days = ((UInt16(value) & 0x01) << 8) | (internalClock.days & 0xff)
        internalClock.dayCounterCarried = (value >> 7) & 0x01 != 0

        let timerIsActive = (value >> 6) & 0x01 == 0
        if timerIsActive && !self.isTimerRunning {
            startTimer()
        } else if !timerIsActive && self.isTimerRunning {
            stopTimer()
        }
    }

    private func update(value: Byte, for register: Register) {
        let index = Self.registerRange.lowerBound.distance(to: register)
        rawValue[index] = value
    }
}
