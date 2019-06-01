extension CPU {
	func nop() -> Cycles {
		pc &+= 1
		return 1
	}

	func loadOperand(into pair: inout Word) -> Cycles {
		pair = mmu.readWord(address: pc + 1)
		pc &+= 3
		return 3
	}

	func load(register: Byte, into address: Address) -> Cycles {
		mmu.write(byte: register, to: address)
		pc &+= 1
		return 2
	}

	func increment(pair: inout Word) -> Cycles {
		pair &+= 1
		pc &+= 1
		return 2
	}

	func increment(register: inout Byte) -> Cycles {
		flags.formIntersection(.fullCarry) // preserve old carry flag
		if register == 0xff { flags.formUnion(.zero) }
		if register & 0x0f == 0x0f { flags.formUnion(.halfCarry) }
		register &+= 1
		pc &+= 1
		return 1
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
		return 2
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
		return 2
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

	func complementAccumulator() -> Cycles {
		a = ~a
		flags.formUnion([.halfCarry, .subtract])
		pc &+= 1
		return 1
	}

	func loadAddressAndDecrementHL(from register: Byte) -> Cycles {
		mmu.write(byte: register, to: hl)
		hl &-= 1
		pc &+= 1
		return 2
	}

	func incrementValue(at address: Address) -> Cycles {
		flags.formIntersection(.fullCarry) // preserve the carry flag
		let value = mmu.read(address: address)
		if value & 0x0f == 0x0f { flags.formUnion(.halfCarry) }
		if value == 0xff { flags.formUnion(.zero) }
		mmu.write(byte: value &+ 1, to: address)
		pc &+= 1
		return 3
	}

	func decrementValue(at address: Address) -> Cycles {
		flags.formIntersection(.fullCarry)
		flags.formUnion(.subtract)
		let value = mmu.read(address: address)
		if value & 0x0f == 0 { flags.formUnion(.halfCarry) }
		if value == 1 { flags.formUnion(.zero) }
		mmu.write(byte: value &- 1, to: address)
		pc &+= 1
		return 3
	}

	func loadOperand(into address: Address) -> Cycles {
		let value = mmu.read(address: pc + 1)
		mmu.write(byte: value, to: address)
		pc &+= 2
		return 3
	}

	func setCarryFlag() -> Cycles {
		flags.formIntersection(.zero) // preserve zero flag
		flags.formUnion(.fullCarry)
		pc &+= 1
		return 1
	}

	func loadFromAddressAndDecrementHL(to register: inout Byte) -> Cycles {
		register = mmu.read(address: hl)
		hl &-= 1
		pc &+= 1
		return 2
	}

	func complementCarryFlag() -> Cycles {
		flags.formSymmetricDifference(.fullCarry)
		flags.formIntersection([.zero, .fullCarry]) // preserve zero flag
		pc &+= 1
		return 1
	}

	func load(value: Byte, into register: inout Byte) -> Cycles {
		register = value
		pc &+= 1
		return 1
	}

	func load(value: Byte, into address: Address) -> Cycles {
		mmu.write(byte: value, to: address)
		pc &+= 1
		return 2
	}

	func halt() -> Cycles {
		pc &+= 1
		return 1
	}

	func add(value: Byte, to register: inout Byte) -> Cycles {
		flags = []
		if register > register &+ value { flags.formUnion(.fullCarry) }
		if register & 0x0f + value & 0x0f > 0x0f { flags.formUnion(.halfCarry) }
		register &+= value
		if register == 0 { flags.formUnion(.zero) }
		pc &+= 1
		return 1
	}

	func add(address: Address, to register: inout Byte) -> Cycles {
		let value = mmu.read(address: address)
		_ = add(value: value, to: &register)
		return 2
	}

	func addWithCarry(value: Byte, to register: inout Byte) -> Cycles {
		let carry: Byte = flags.contains(.fullCarry) ? 1 : 0
		flags = []
		if register > register &+ value { flags.formUnion(.fullCarry) }
		if register & 0x0f + value & 0x0f > 0x0f { flags.formUnion(.halfCarry) }
		register &+= value
		if register > register &+ carry { flags.formUnion(.fullCarry) }
		if register & 0x0f + carry > 0x0f { flags.formUnion(.halfCarry) }
		register &+= carry
		if register == 0 { flags.formUnion(.zero) }
		pc &+= 1
		return 1
	}

	func addWithCarry(address: Address, to register: inout Byte) -> Cycles {
		let value = mmu.read(address: address)
		_ = addWithCarry(value: value, to: &register)
		return 2
	}

	func subtract(value: Byte, from register: inout Byte) -> Cycles {
		flags = .subtract
		if register < value { flags.formUnion(.fullCarry) }
		if register & 0x0f < value & 0x0f { flags.formUnion(.halfCarry) }
		if register == value { flags.formUnion(.zero) }
		register &-= value
		pc &+= 1
		return 1
	}

	func subtract(address: Address, from register: inout Byte) -> Cycles {
		let value = mmu.read(address: address)
		_ = subtract(value: value, from: &register)
		return 2
	}

	func subtractWithCarry(value: Byte, from register: inout Byte) -> Cycles {
		let carry: Byte = flags.contains(.fullCarry) ? 1 : 0
		flags = .subtract
		if register < value { flags.formUnion(.fullCarry) }
		if register & 0x0f < value & 0x0f { flags.formUnion(.halfCarry) }
		register &-= value
		if register < carry { flags.formUnion(.fullCarry) }
		if register & 0x0f < carry { flags.formUnion(.halfCarry) }
		register &-= carry
		if register == 0 { flags.formUnion(.zero) }
		pc &+= 1
		return 1
	}

	func subtractWithCarry(address: Address, from register: inout Byte) -> Cycles {
		let value = mmu.read(address: address)
		_ = subtractWithCarry(value: value, from: &register)
		return 2
	}

	func and(value: Byte, into register: inout Byte) -> Cycles {
		register &= value
		flags = register == 0 ? [.zero, .halfCarry] : .halfCarry
		pc &+= 1
		return 1
	}

	func and(address: Address, into register: inout Byte) -> Cycles {
		let value = mmu.read(address: address)
		_ = and(value: value, into: &register)
		return 2
	}

	func xor(value: Byte, into register: inout Byte) -> Cycles {
		register ^= value
		flags = register == 0 ? .zero : []
		pc &+= 1
		return 1
	}

	func xor(address: Address, into register: inout Byte) -> Cycles {
		let value = mmu.read(address: address)
		_ = xor(value: value, into: &register)
		return 2
	}

	func or(value: Byte, into register: inout Byte) -> Cycles {
		register |= value
		flags = register == 0 ? .zero : []
		pc &+= 1
		return 1
	}

	func or(address: Address, into register: inout Byte) -> Cycles {
		let value = mmu.read(address: address)
		_ = or(value: value, into: &register)
		return 2
	}

	func compare(value: Byte, with register: Byte) -> Cycles {
		flags = .subtract
		if register < value { flags.formUnion(.fullCarry) }
		if register & 0x0f < value & 0x0f { flags.formUnion(.halfCarry) }
		if register == value { flags.formUnion(.zero) }
		pc &+= 1
		return 1
	}

	func compare(address: Address, with register: Byte) -> Cycles {
		let value = mmu.read(address: address)
		_ = compare(value: value, with: register)
		return 2
	}

	func `return`(condition: Bool) -> Cycles {
		if condition {
			_ = `return`()
			return 5
		} else {
			pc &+= 1
			return 2
		}
	}

	func `return`() -> Cycles {
		pc = mmu.readWord(address: sp)
		sp &+= 2
		return 4
	}

	func pop(pair: inout Word) -> Cycles {
		pair = mmu.readWord(address: sp)
		sp &+= 2
		pc &+= 1
		return 3
	}

	func jump(condition: Bool) -> Cycles {
		if condition {
			pc = mmu.readWord(address: pc + 1)
			return 4
		} else {
			pc &+= 3
			return 3
		}
	}

	func jump() -> Cycles {
		pc = mmu.readWord(address: pc + 1)
		return 4
	}

	func call(condition: Bool) -> Cycles {
		if condition {
			return call()
		} else {
			pc &+= 3
			return 3
		}
	}

	func call() -> Cycles {
		mmu.write(word: pc + 3, to: sp - 2)
		pc = mmu.readWord(address: pc + 1)
		sp &-= 2
		return 6
	}

	func push(pair: Word) -> Cycles {
		mmu.write(word: pair, to: sp - 2)
		sp &-= 2
		pc &+= 1
		return 4
	}

	func addOperand(to register: inout Byte) -> Cycles {
		let value = mmu.read(address: pc + 1)
		_ = add(value: value, to: &register)
		pc &+= 1
		return 2
	}

	func reset(vector: Byte) -> Cycles {
		mmu.write(word: pc + 1, to: sp - 2)
		sp &-= 2
		pc = Word(vector)
		return 4
	}

	func addOperandWithCarry(to register: inout Byte) -> Cycles {
		let value = mmu.read(address: pc + 1)
		_ = addWithCarry(value: value, to: &register)
		pc &+= 1
		return 2
	}
}
