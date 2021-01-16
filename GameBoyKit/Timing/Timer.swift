public protocol TimerDelegate: AnyObject {
    func timer(_ timer: Timer, didRequest interrupt: Interrupts)
}

public final class Timer: MemoryAddressable {
    public struct Registers {
        public static let divider: Address = 0xff04
        public static let counter: Address = 0xff05
        public static let modulo: Address = 0xff06
        public static let control: Address = 0xff07
    }

    weak var delegate: TimerDelegate?
    private let dividerIncrementRate: Cycles = 64

    private var dividerIntermediate: Cycles = 0
    private var counterIntermediate: Cycles = 0

    private var divider: Byte = 0
    private var counter: Byte = 0
    private var modulo: Byte = 0
    private var control = TimerControl(rawValue: 0)

    public init() {}

    public func read(address: Address) -> Byte {
        switch address {
        case Registers.divider:
            return divider
        case Registers.counter:
            return counter
        case Registers.modulo:
            return modulo
        case Registers.control:
            return control.rawValue
        default:
            assertionFailure("Failed to read address: \(address)")
            return 0
        }
    }

    public func write(byte: Byte, to address: Address) {
        switch address {
        case Registers.divider:
            divider = 0 // byte is ignored and divider is reset
        case Registers.counter:
            counter = byte
        case Registers.modulo:
            modulo = byte
        case Registers.control:
            control = TimerControl(rawValue: byte)
            resetCounter()
        default:
            assertionFailure("Failed to write address: \(address)")
        }
    }

    public func emulate() {
        dividerIntermediate += 1
        if dividerIntermediate == dividerIncrementRate {
            divider &+= 1
            dividerIntermediate = 0
        }

        guard control.isTimerStarted else {
            resetCounter()
            return
        }

        var counterDidOverflow = false
        counterIntermediate += 1
        let counterIncrementRate = control.inputClock.counterIncrementRate
        if counterIntermediate == counterIncrementRate {
            counterDidOverflow = counter.incrementReportingOverflow()
            counterIntermediate = 0
        }

        if counterDidOverflow {
            // Counter overflowed, request interrupt
            counter = modulo
            delegate?.timer(self, didRequest: .timer)
        }
    }

    // MARK: - Helpers

    private func resetCounter() {
        counterIntermediate = 0
        counter = 0
    }
}
