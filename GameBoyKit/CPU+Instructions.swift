extension CPU {

	// MARK: Misc/Control

	func nop() -> Cycles {
		pc &+= 1
		return 1
	}

	// MARK: 8-bit Loads

	func load(value: Byte, into address: Address) -> Cycles {
		mmu.write(byte: value, to: address)
		pc &+= 1
		return 2
	}

	func loadOperand(into register: inout Byte) -> Cycles {
		register = mmu.read(address: pc &+ 1)
		pc &+= 2
		return 2
	}

	func loadFromHRAMOperand(int register: inout Byte) -> Cycles {
		let offset = mmu.read(address: pc &+ 1)
		register = mmu.read(address: 0xff00 | Word(offset))
		pc &+= 2
		return 3
	}

	func loadFromHRAMAddress(withLoadByte lowByte: Byte, into register: inout Byte) -> Cycles {
		register = mmu.read(address: 0xff00 | Word(lowByte))
		pc &+= 1
		return 2
	}

	func loadFromAddressOperand(into register: inout Byte) -> Cycles {
		let address = mmu.readWord(address: pc &+ 1)
		register = mmu.read(address: address)
		pc &+= 3
		return 4
	}

	func load(address: Address, into register: inout Byte) -> Cycles {
		register = mmu.read(address: address)
		pc &+= 1
		return 2
	}

	func loadAddressAndIncrementHL(from register: Byte) -> Cycles {
		mmu.write(byte: register, to: hl)
		hl &+= 1
		pc &+= 1
		return 2
	}

	func loadFromAddressAndIncrementHL(to register: inout Byte) -> Cycles {
		register = mmu.read(address: hl)
		hl &+= 1
		pc &+= 1
		return 2
	}

	func loadAddressAndDecrementHL(from register: Byte) -> Cycles {
		mmu.write(byte: register, to: hl)
		hl &-= 1
		pc &+= 1
		return 2
	}

	func loadOperand(into address: Address) -> Cycles {
		let value = mmu.read(address: pc &+ 1)
		mmu.write(byte: value, to: address)
		pc &+= 2
		return 3
	}

	func loadFromAddressAndDecrementHL(to register: inout Byte) -> Cycles {
		register = mmu.read(address: hl)
		hl &-= 1
		pc &+= 1
		return 2
	}

	func load(value: Byte, into register: inout Byte) -> Cycles {
		register = value
		pc &+= 1
		return 1
	}

	func loadHRAMOperand(from register: Byte) -> Cycles {
		let lowByte = mmu.read(address: pc &+ 1)
		mmu.write(byte: register, to: 0xff00 | Word(lowByte))
		pc &+= 2
		return 3
	}

	func loadHRAM(from register: Byte, intoAddressWithLowByte lowByte: Byte) -> Cycles {
		mmu.write(byte: register, to: 0xff00 | Word(lowByte))
		pc &+= 1
		return 2
	}

	func loadIntoAddressOperand(byte: Byte) -> Cycles {
		let address = mmu.readWord(address: pc &+ 1)
		mmu.write(byte: byte, to: address)
		pc &+= 2
		return 4
	}

	// MARK: 16-bit Loads

	func loadOperand(into pair: inout Word) -> Cycles {
		pair = mmu.readWord(address: pc &+ 1)
		pc &+= 3
		return 3
	}

	func loadIntoAddressOperand(word: Word) -> Cycles {
		let address = mmu.readWord(address: pc &+ 1)
		mmu.write(word: word, to: address)
		pc &+= 3
		return 5
	}

	func load(value: Word, into pair: inout Word) -> Cycles {
		pair = value
		pc &+= 1
		return 2
	}

	func pop(pair: inout Word) -> Cycles {
		pair = mmu.readWord(address: sp)
		sp &+= 2
		pc &+= 1
		return 3
	}

	func push(pair: Word) -> Cycles {
		mmu.write(word: pair, to: sp - 2)
		sp &-= 2
		pc &+= 1
		return 4
	}

	/// Add signed operand to SP and store the result in HL
	func addSignedOperandToStackPointer(storeIn pair: inout Word) -> Cycles {
		flags = []
		let toAdd = Int32(Int8(bitPattern: mmu.read(address: pc &+ 1)))
		let sp32 = Int32(sp)
		pair = Word(truncatingIfNeeded: sp32 + toAdd)

		if sp32 & 0xff + toAdd & 0xff > 0xff {
			flags.formUnion(.fullCarry)
		}
		if sp32 & 0x0f + toAdd & 0x0f > 0x0f {
			flags.formUnion(.halfCarry)
		}
		pc &+= 2
		return 3
	}

	// MARK: 8-bit Arthithmetic/Logical

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

	func increment(register: inout Byte) -> Cycles {
		flags.formIntersection(.fullCarry) // preserve old carry flag
		if register == 0xff { flags.formUnion(.zero) }
		if register & 0x0f == 0x0f { flags.formUnion(.halfCarry) }
		register &+= 1
		pc &+= 1
		return 1
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

	func decrement(register: inout Byte) -> Cycles {
		flags.formIntersection(.fullCarry) // preserve old carry flag
		flags.formUnion(.subtract)
		if register == 1 { flags.formUnion(.zero) }
		if register & 0x0f == 0 { flags.formUnion(.halfCarry) }
		register &-= 1
		pc &+= 1
		return 1
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

	func setCarryFlag() -> Cycles {
		flags.formIntersection(.zero) // preserve zero flag
		flags.formUnion(.fullCarry)
		pc &+= 1
		return 1
	}

	func complementAccumulator() -> Cycles {
		a = ~a
		flags.formUnion([.halfCarry, .subtract])
		pc &+= 1
		return 1
	}

	func complementCarryFlag() -> Cycles {
		flags.formSymmetricDifference(.fullCarry)
		flags.formIntersection([.zero, .fullCarry]) // preserve zero flag
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

	func addOperand(to register: inout Byte) -> Cycles {
		let value = mmu.read(address: pc &+ 1)
		_ = add(value: value, to: &register)
		pc &+= 1
		return 2
	}

	func addOperandWithCarry(to register: inout Byte) -> Cycles {
		let value = mmu.read(address: pc &+ 1)
		_ = addWithCarry(value: value, to: &register)
		pc &+= 1
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

	func subtractOperand(from register: inout Byte) -> Cycles {
		let value = mmu.read(address: pc &+ 1)
		_ = subtract(value: value, from: &register)
		pc &+= 1
		return 2
	}

	func subtractOperandWithCarry(from register: inout Byte) -> Cycles {
		let value = mmu.read(address: pc &+ 1)
		_ = subtractWithCarry(value: value, from: &register)
		pc &+= 1
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

	func andOperand(into register: inout Byte) -> Cycles {
		flags = .halfCarry
		register &= mmu.read(address: pc &+ 1)
		if register == 0 { flags.formUnion(.zero) }
		pc &+= 2
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

	func orOperand(into register: inout Byte) -> Cycles {
		let value = mmu.read(address: pc &+ 1)
		register |= value
		flags = register == 0 ? .zero : []
		pc &+= 2
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

	func xorOperand(into register: inout Byte) -> Cycles {
		let value = mmu.read(address: pc &+ 1)
		register ^= value
		flags = register == 0 ? .zero : []
		pc &+= 2
		return 2
	}

	func compare(address: Address, with register: Byte) -> Cycles {
		let value = mmu.read(address: address)
		_ = compare(value: value, with: register)
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

	func compareOperand(with register: Byte) -> Cycles {
		let value = mmu.read(address: pc &+ 1)
		_ = compare(value: value, with: register)
		pc &+= 1
		return 2
	}

	// MARK: 16-bit Arithmetic/Logical

	func increment(pair: inout Word) -> Cycles {
		pair &+= 1
		pc &+= 1
		return 2
	}

	func decrement(pair: inout Word) -> Cycles {
		pair &-= 1
		pc &+= 1
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

	func addSignedOperandToStackPointer() -> Cycles {
		flags = []
		let toAdd = Int32(Int8(bitPattern: mmu.read(address: pc &+ 1)))
		let oldSP = Int32(sp)
		let newSP = oldSP + toAdd

		if oldSP & 0xff + toAdd & 0xff > 0xff {
			flags.formUnion(.fullCarry)
		}
		if oldSP & 0x0f + toAdd & 0x0f > 0x0f {
			flags.formUnion(.halfCarry)
		}
		sp = Word(truncatingIfNeeded: newSP)
		pc &+= 2
		return 4
	}

	// MARK: Uncategorized

	func rotateLeftCarryA() -> Cycles {
		let carry = a >> 7
		flags = carry != 0 ? .fullCarry : []
		a = a << 1 | carry
		pc &+= 1
		return 5
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
		let distance = Int16(Int8(bitPattern: mmu.read(address: pc &+ 1)))
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

	func halt() -> Cycles {
		pc &+= 1
		return 1
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

	func jump(condition: Bool) -> Cycles {
		if condition {
			pc = mmu.readWord(address: pc &+ 1)
			return 4
		} else {
			pc &+= 3
			return 3
		}
	}

	func jump() -> Cycles {
		pc = mmu.readWord(address: pc &+ 1)
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
		mmu.write(word: pc &+ 3, to: sp - 2)
		pc = mmu.readWord(address: pc &+ 1)
		sp &-= 2
		return 6
	}

	func reset(vector: Byte) -> Cycles {
		mmu.write(word: pc &+ 1, to: sp - 2)
		sp &-= 2
		pc = Word(vector)
		return 4
	}

	func undefined() -> Cycles {
		assertionFailure("This is an error in the program and would crash a real Game Boy")
		return 0
	}

	func returnEnableInterrupts() -> Cycles {
		interuptsEnabled = true
		return `return`()
	}

	func jump(to word: Word) -> Cycles {
		pc = word
		return 1
	}

	func disableInterrupts() -> Cycles {
		interuptsEnabled = false
		pc &+= 1
		return 1
	}

	func enableInterrupts() -> Cycles {
		interuptsEnabled = true
		pc &+= 1
		return 1
	}
}
