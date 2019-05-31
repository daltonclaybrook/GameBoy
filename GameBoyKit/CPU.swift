import Foundation

public struct Flags: OptionSet {
	public let rawValue: UInt8

	public static let fullCarry = Flags(rawValue: 1 << 4)
	public static let halfCarry = Flags(rawValue: 1 << 5)
	public static let subtract = Flags(rawValue: 1 << 6)
	public static let zero = Flags(rawValue: 1 << 7)

	public init(rawValue: UInt8) {
		self.rawValue = rawValue
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

	let mmu: MMU

	init(mmu: MMU) {
		self.mmu = mmu
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
