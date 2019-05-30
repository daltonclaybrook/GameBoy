import Foundation

public final class CPU {
	private(set) public var a: UInt8 = 0
	private(set) public var f: UInt8 = 0
	private(set) public var b: UInt8 = 0
	private(set) public var c: UInt8 = 0
	private(set) public var d: UInt8 = 0
	private(set) public var e: UInt8 = 0
	private(set) public var h: UInt8 = 0
	private(set) public var l: UInt8 = 0
	private(set) public var sp: UInt16 = 0
	private(set) public var pc: UInt16 = 0

	init() {}
}
