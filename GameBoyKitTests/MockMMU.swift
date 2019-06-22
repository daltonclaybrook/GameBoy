@testable import GameBoyKit

struct MockMMU: MemoryAddressable {
	func read(address: Address) -> Byte {
		return 0
	}

	func write(byte: Byte, to address: Address) {
		// nop
	}
}
