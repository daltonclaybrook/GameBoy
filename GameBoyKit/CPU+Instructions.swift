extension CPU {
	func nop() {
		pc &+= 1
	}

	func loadOperand(into pair: inout Word) {
		pair = mmu.readWord(address: pc + 1)
		pc &+= 3
	}

	func load(byte: Byte, into address: Address) {
		mmu.write(byte: byte, to: address)
		pc &+= 1
	}

	func increment(pair: inout Word) {
		pair &+= 1
		pc &+= 1
	}

	func increment(register: inout Byte) {
		flags.formIntersection(.fullCarry) // preserve old carry flag
		if register == 0xff { flags.formUnion(.zero) }
		if register & 0x0f == 0x0f { flags.formUnion(.halfCarry) }
		register &+= 1
		pc &+= 1
	}

	func decrement(register: inout Byte) {
		flags.formIntersection(.fullCarry) // preserve old carry flag
		flags.formUnion(.subtract)
		if register == 1 { flags.formUnion(.zero) }
		if register & 0x0f == 0 { flags.formUnion(.halfCarry) }
		register &-= 1
		pc &+= 1
	}

	func loadOperand(into register: inout Byte) {
		register = mmu.read(address: pc + 1)
		pc &+= 2
	}

	func rotateLeftCarryA() {
		let carry = a >> 7
		flags = carry != 0 ? .fullCarry : []
		a = a << 1 | carry
		pc &+= 1
	}

	func loadIntoAddressOperand(word: Word) {
		let address = mmu.readWord(address: pc + 1)
		mmu.write(word: word, to: address)
		pc &+= 3
	}

	func add(value: Word, to pair: inout Word) {
		flags.formIntersection(.zero) // preserve old zero flag
		if pair & 0x0fff + value & 0x0fff > 0x0fff { flags.formUnion(.halfCarry) }
		if pair > pair &+ value { flags.formUnion(.fullCarry) }
		pair &+= value
		pc &+= 1
	}

	func load(address: Address, into register: inout Byte) {
		register = mmu.read(address: address)
		pc &+= 1
	}

	func decrement(pair: inout Word) {
		pair &-= 1
		pc &+= 1
	}

	func rotateRightCarryA() {
		let carry = a << 7
		flags = carry != 0 ? .fullCarry : []
		a = a >> 1 | carry
		pc &+= 1
	}
}
