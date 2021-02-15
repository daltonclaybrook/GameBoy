import Foundation

public struct Flags: OptionSet {
    public let rawValue: UInt8

    public static let fullCarry = Flags(rawValue: 1 << 4)
    public static let halfCarry = Flags(rawValue: 1 << 5)
    public static let subtract = Flags(rawValue: 1 << 6)
    public static let zero = Flags(rawValue: 1 << 7)

    public init(rawValue: UInt8) {
        // The lower nibble must always be zero
        self.rawValue = rawValue & 0xf0
    }
}

public final class CPU {
    public internal(set) var a: UInt8 = 0
    public internal(set) var b: UInt8 = 0
    public internal(set) var c: UInt8 = 0
    public internal(set) var d: UInt8 = 0
    public internal(set) var e: UInt8 = 0
    public internal(set) var h: UInt8 = 0
    public internal(set) var l: UInt8 = 0
    public internal(set) var sp: UInt16 = 0
    public internal(set) var pc: UInt16 = 0
    public internal(set) var flags: Flags = []

    internal var queuedEnableInterrupts = false
    public internal(set) var interruptsEnabled = false
    public internal(set) var isHalted = false

    public init() {}
}

extension CPU {
    /// Fetches a byte from the address at `PC`, and increments `PC`
    func fetchByte(context: CPUContext) -> Byte {
        let address = pc
        pc &+= 1
        return context.readCycle(address: address)
    }

    /// Fetches a word from the address at `PC`, and increments `PC` by 2
    func fetchWord(context: CPUContext) -> Word {
        let low = fetchByte(context: context)
        let high = fetchByte(context: context)
        return (Word(high) << 8) | Word(low)
    }

    /// Pushes the provided value onto the stack and decrements `SP`
    func pushStack(value: Word, context: CPUContext) {
        let low = Byte(truncatingIfNeeded: value)
        let high = Byte(value >> 8)
        context.tickCycle()
        sp &-= 1
        context.writeCycle(byte: high, to: sp)
        sp &-= 1
        context.writeCycle(byte: low, to: sp)
    }

    /// Pops a value off of the stack and increments `SP`
    func popStack(context: CPUContext) -> Word {
        let low = context.readCycle(address: sp)
        sp &+= 1
        let high = context.readCycle(address: sp)
        sp &+= 1
        return (Word(high) << 8) | Word(low)
    }
}

extension CPU {
    var af: UInt16 {
        get {
            return UInt16(a) << 8 | UInt16(flags.rawValue)
        }
        set {
            a = UInt8(newValue >> 8)
            flags = Flags(rawValue: UInt8(truncatingIfNeeded: newValue))
        }
    }

    var bc: UInt16 {
        get {
            return UInt16(b) << 8 | UInt16(c)
        }
        set {
            b = UInt8(newValue >> 8)
            c = UInt8(truncatingIfNeeded: newValue)
        }
    }

    var de: UInt16 {
        get {
            return UInt16(d) << 8 | UInt16(e)
        }
        set {
            d = UInt8(newValue >> 8)
            e = UInt8(truncatingIfNeeded: newValue)
        }
    }

    var hl: UInt16 {
        get {
            return UInt16(h) << 8 | UInt16(l)
        }
        set {
            h = UInt8(newValue >> 8)
            l = UInt8(truncatingIfNeeded: newValue)
        }
    }
}
