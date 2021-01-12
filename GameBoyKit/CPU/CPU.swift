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
    internal(set) public var a: UInt8 = 0
    internal(set) public var b: UInt8 = 0
    internal(set) public var c: UInt8 = 0
    internal(set) public var d: UInt8 = 0
    internal(set) public var e: UInt8 = 0
    internal(set) public var h: UInt8 = 0
    internal(set) public var l: UInt8 = 0
    internal(set) public var sp: UInt16 = 0
    internal(set) public var pc: UInt16 = 0
    internal(set) public var flags: Flags = []

    internal(set) public var interuptsEnabled = false
    internal(set) public var isHalted = false

    let mmu: MemoryAddressable

    init(mmu: MemoryAddressable) {
        self.mmu = mmu
    }
}

extension CPU {
    /// Fetches a byte from the address at `PC`, and increments `PC`
    func fetchByte() -> Byte {
        let address = pc
        pc &+= 1
        return mmu.read(address: address)
    }

    /// Fetches a word from the address at `PC`, and increments `PC` by 2
    func fetchWord() -> Word {
        let low = fetchByte()
        let high = fetchByte()
        return Word(high << 8) | Word(low)
    }

    /// Pushes the provided value onto the stack and decrements `SP`
    func pushStack(value: Word) {
        let low = Byte(truncatingIfNeeded: value)
        let high = Byte(value >> 8)
        sp &-= 1
        mmu.write(byte: high, to: sp)
        sp &-= 1
        mmu.write(byte: low, to: sp)
    }

    /// Pops a value off of the stack and increments `SP`
    func popStack() -> Word {
        let low = mmu.read(address: sp)
        sp &+= 1
        let high = mmu.read(address: sp)
        sp &+= 1
        return Word(high << 8) | Word(low)
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
