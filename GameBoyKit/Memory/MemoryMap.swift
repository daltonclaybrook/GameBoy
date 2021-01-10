public typealias MemoryMap = ClosedRange<Address>

extension ClosedRange where Bound == Address {
	public static let ROM: ClosedRange<Address> = 0x0000...0x7fff
	public static let VRAM: ClosedRange<Address> = 0x8000...0x9fff
	public static let externalRAM: ClosedRange<Address> = 0xa000...0xbfff
	public static let WRAM: ClosedRange<Address> = 0xc000...0xdfff
	public static let ECHO: ClosedRange<Address> = 0xe000...0xfdff
	public static let OAM: ClosedRange<Address> = 0xfe00...0xfe9f
	public static let unusable: ClosedRange<Address> = 0xfea0...0xfeff
	public static let IO: ClosedRange<Address> = 0xff00...0xff7f
	public static let HRAM: ClosedRange<Address> = 0xff80...0xfffe
	public static let interruptEnable: Address = 0xffff
}

extension Array where Element == Byte {
    func read(address: Address) -> Byte {
        return self[Int(address)]
    }

	func read(address: Address, in range: ClosedRange<Address>) -> Byte {
		return self[Int(address - range.lowerBound)]
	}

    mutating func write(byte: Byte, to address: Address) {
        self[Int(address)] = byte
    }

	mutating func write(byte: Byte, to address: Address, in range: ClosedRange<Address>) {
		self[Int(address - range.lowerBound)] = byte
	}
}
