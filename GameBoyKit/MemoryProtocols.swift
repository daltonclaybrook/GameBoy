public typealias Address = UInt16
public typealias Byte = UInt8
public typealias Word = UInt16

public protocol MemoryAddressable {
	func write(byte: Byte, to address: Address)
	func read(address: Address) -> Byte
}

extension MemoryAddressable {
	public func readWord(address: Address) -> Word {
		let little = read(address: address)
		let big = read(address: address + 1)
		return (UInt16(big) << 8) | UInt16(little)
	}

	public func write(word: Word, to address: Address) {
		let little = UInt8(truncatingIfNeeded: word)
		let big = word >> 8
		write(byte: Byte(little), to: address)
		write(byte: Byte(big), to: address + 1)
	}
}
