extension CPU {
	func nop() -> Cycles {
		pc &+= 1
		return 1
	}

	func loadOperand(into pair: inout Word) -> Cycles {
		pair = mmu.readWord(address: pc + 1)
		pc &+= 3
		return 2
	}

	func load(register: Byte, into address: Address) -> Cycles {
		mmu.write(byte: register, to: address)
		pc &+= 1
		return 2
	}

	func increment(pair: inout Word) -> Cycles {
		pair &+= 1
		pc &+= 1
		return 1
	}

	func increment(register: inout Byte) -> Cycles {
		flags.formIntersection(.fullCarry) // preserve old carry flag
		if register == 0xff { flags.formUnion(.zero) }
		if register & 0x0f == 0x0f { flags.formUnion(.halfCarry) }
		register &+= 1
		pc &+= 1
		return 2
	}

	func decrement(register: inout Byte) -> Cycles {
		flags.formIntersection(.fullCarry) // preserve old carry flag
		flags.formUnion(.subtract)
		if register == 1 { flags.formUnion(.zero) }
		if register & 0x0f == 0 { flags.formUnion(.halfCarry) }
		register &-= 1
		pc &+= 1
		return 1
	}

	func loadOperand(into register: inout Byte) -> Cycles {
		register = mmu.read(address: pc + 1)
		pc &+= 2
		return 1
	}

	func rotateLeftCarryA() -> Cycles {
		let carry = a >> 7
		flags = carry != 0 ? .fullCarry : []
		a = a << 1 | carry
		pc &+= 1
		return 5
	}

	func loadIntoAddressOperand(word: Word) -> Cycles {
		let address = mmu.readWord(address: pc + 1)
		mmu.write(word: word, to: address)
		pc &+= 3
		return 2
	}

	func add(value: Word, to pair: inout Word) -> Cycles {
		flags.formIntersection(.zero) // preserve old zero flag
		if pair & 0x0fff + value & 0x0fff > 0x0fff { flags.formUnion(.halfCarry) }
		if pair > pair &+ value { flags.formUnion(.fullCarry) }
		pair &+= value
		pc &+= 1
		return 2
	}

	func load(address: Address, into register: inout Byte) -> Cycles {
		register = mmu.read(address: address)
		pc &+= 1
		return 2
	}

	func decrement(pair: inout Word) -> Cycles {
		pair &-= 1
		pc &+= 1
		return 1
	}

	func rotateRightCarryA() -> Cycles {
		let carry = a << 7
		flags = carry != 0 ? .fullCarry : []
		a = a >> 1 | carry
		pc &+= 1
		return 2
	}

	func stop() -> Cycles {
		pc &+= 1
		return 1
	}

	/// Rotate `a` left moving bit 7 into the carry flag and the carry flag into bit 0.
	/// Updates carry flag, resets others.
	func rotateLeftA() -> Cycles {
		let carry = a & 0x08
		a = a << 1
		if flags.contains(.fullCarry) { a += 1 }
		flags = carry > 0 ? .fullCarry : []
		pc &+= 1
		return 1
	}

	/// Jump relative to the current `pc` rather than to an absolute address.
	/// Slightly more efficient than a normal jump.
	func jumpRelative() -> Cycles {
		let distance = Int16(Int8(bitPattern: mmu.read(address: pc + 1)))
		pc &+= 2
		pc = UInt16(bitPattern: Int16(pc) &+ distance)
		return 3
	}

	/// Rotate `a` right moving bit 0 into the carry flag and the carry flag into bit 7.
	/// Updates carry flag, resets others.
	func rotateRightA() -> Cycles {
		let carry = a & 1
		a = a >> 1
		if flags.contains(.fullCarry) { a += 0x80 }
		flags = carry > 0 ? .fullCarry : []
		pc &+= 1
		return 1
	}

	func jumpRelative(condition: Bool) -> Cycles {
		if condition {
			return jumpRelative()
		} else {
			pc &+= 2
			return 2
		}
	}

	func loadAddressAndIncrementHL(from register: Byte) -> Cycles {
		mmu.write(byte: register, to: hl)
		hl &+= 1
		pc &+= 1
		return 2
	}

	/// Assuming the last arithmetic operation was between two BCD numbers, converts
	/// the result in `a` to BCD
	func decimalAdjustAccumulator() -> Cycles {
		if flags.contains(.subtract) {
			if flags.contains(.fullCarry) { a &-= 0x60 }
			if flags.contains(.halfCarry) { a &-= 0x06 }
		} else {
			if flags.contains(.fullCarry) || a & 0xff > 0x99 {
				a &+= 0x60
				flags.formUnion(.fullCarry)
			}
			if flags.contains(.halfCarry) || a & 0x0f > 0x09 {
				a &+= 0x06
			}
		}
		if a == 0 { flags.formUnion(.zero) }
		flags.subtract(.halfCarry)
		pc &+= 1
		return 1
	}

	func loadFromAddressAndIncrementHL(to register: inout Byte) -> Cycles {
		register = mmu.read(address: hl)
		hl &+= 1
		pc &+= 1
		return 2
	}

	func complement() -> Cycles {
		a = ~a
		flags.formUnion([.halfCarry, .subtract])
		pc &+= 1
		return 1
	}
}
