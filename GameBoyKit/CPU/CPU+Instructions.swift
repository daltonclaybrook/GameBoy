extension CPU {

    // MARK: 8-bit Loads

    func load(value: Byte, into address: Address, context: CPUContext) -> Cycles {
        context.writeCycle(byte: value, to: address)
        return 2
    }

    func loadOperand(into register: inout Byte, context: CPUContext) -> Cycles {
        register = fetchByte(context: context)
        return 2
    }

    func loadFromHRAMOperand(int register: inout Byte, context: CPUContext) -> Cycles {
        let offset = fetchByte(context: context)
        register = context.readCycle(address: 0xff00 | Word(offset))
        return 3
    }

    func loadFromHRAMAddress(withLoadByte lowByte: Byte, into register: inout Byte, context: CPUContext) -> Cycles {
        register = context.readCycle(address: 0xff00 | Word(lowByte))
        return 2
    }

    func loadFromAddressOperand(into register: inout Byte, context: CPUContext) -> Cycles {
        let address = fetchWord(context: context)
        register = context.readCycle(address: address)
        return 4
    }

    func load(address: Address, into register: inout Byte, context: CPUContext) -> Cycles {
        register = context.readCycle(address: address)
        return 2
    }

    func loadAddressAndIncrementHL(from register: Byte, context: CPUContext) -> Cycles {
        context.writeCycle(byte: register, to: hl)
        hl &+= 1
        return 2
    }

    func loadFromAddressAndIncrementHL(to register: inout Byte, context: CPUContext) -> Cycles {
        register = context.readCycle(address: hl)
        hl &+= 1
        return 2
    }

    func loadAddressAndDecrementHL(from register: Byte, context: CPUContext) -> Cycles {
        context.writeCycle(byte: register, to: hl)
        hl &-= 1
        return 2
    }

    func loadOperand(into address: Address, context: CPUContext) -> Cycles {
        let value = fetchByte(context: context)
        context.writeCycle(byte: value, to: address)
        return 3
    }

    func loadFromAddressAndDecrementHL(to register: inout Byte, context: CPUContext) -> Cycles {
        register = context.readCycle(address: hl)
        hl &-= 1
        return 2
    }

    func load(value: Byte, into register: inout Byte) -> Cycles {
        register = value
        return 1
    }

    func loadHRAMOperand(from register: Byte, context: CPUContext) -> Cycles {
        let lowByte = fetchByte(context: context)
        context.writeCycle(byte: register, to: 0xff00 | Word(lowByte))
        return 3
    }

    func loadHRAM(from register: Byte, intoAddressWithLowByte lowByte: Byte, context: CPUContext) -> Cycles {
        context.writeCycle(byte: register, to: 0xff00 | Word(lowByte))
        return 2
    }

    func loadIntoAddressOperand(byte: Byte, context: CPUContext) -> Cycles {
        let address = fetchWord(context: context)
        context.writeCycle(byte: byte, to: address)
        return 4
    }

    // MARK: 16-bit Loads

    func loadOperand(into pair: inout Word, context: CPUContext) -> Cycles {
        pair = fetchWord(context: context)
        return 3
    }

    func loadIntoAddressOperand(word: Word, context: CPUContext) -> Cycles {
        let address = fetchWord(context: context)
        context.writeCycle(word: word, to: address)
        return 5
    }

    func load(value: Word, into pair: inout Word) -> Cycles {
        pair = value
        return 2
    }

    func pop(pair: inout Word, context: CPUContext) -> Cycles {
        pair = popStack(context: context)
        return 3
    }

    func push(pair: Word, context: CPUContext) -> Cycles {
        pushStack(value: pair, context: context)
        return 4
    }

    /// Add signed operand to SP and store the result in HL
    func addSignedOperandToStackPointer(storeIn pair: inout Word, context: CPUContext) -> Cycles {
        flags = []

        let toAdd = Int8(bitPattern: fetchByte(context: context))
        pair = sp.wrappingAdd(toAdd)

        let sp32 = Int32(sp)
        let toAdd32 = Int32(toAdd)

        if sp32 & 0xff + toAdd32 & 0xff > 0xff {
            flags.formUnion(.fullCarry)
        }
        if sp32 & 0x0f + toAdd32 & 0x0f > 0x0f {
            flags.formUnion(.halfCarry)
        }
        return 3
    }

    // MARK: 8-bit Arthithmetic/Logical

    /// Assuming the last arithmetic operation was between two BCD numbers, converts
    /// the result in `a` to BCD
    func decimalAdjustAccumulator() -> Cycles {
        var register = UInt16(a)

        if !flags.contains(.subtract) {
            if flags.contains(.halfCarry) || register & 0x0f > 0x09 {
                register &+= 0x06
            }
            if flags.contains(.fullCarry) || register > 0x9f {
                register &+= 0x60
            }
        } else {
            if flags.contains(.halfCarry) {
                register = (register &- 0x06) & 0xff
            }
            if flags.contains(.fullCarry) {
                register &-= 0x60
            }
        }

        flags.formIntersection([.subtract, .fullCarry])

        if register & 0x100 != 0 {
            flags.formUnion(.fullCarry)
        }

        register &= 0xff

        if register == 0 {
            flags.formUnion(.zero)
        }
        a = UInt8(register)
        return 1
    }

    func increment(register: inout Byte) -> Cycles {
        flags.formIntersection(.fullCarry) // preserve old carry flag
        if register == 0xff { flags.formUnion(.zero) }
        if register & 0x0f == 0x0f { flags.formUnion(.halfCarry) }
        register &+= 1
        return 1
    }

    func incrementValue(at address: Address, context: CPUContext) -> Cycles {
        flags.formIntersection(.fullCarry) // preserve the carry flag
        let value = context.readCycle(address: address)
        if value & 0x0f == 0x0f { flags.formUnion(.halfCarry) }
        if value == 0xff { flags.formUnion(.zero) }
        context.writeCycle(byte: value &+ 1, to: address)
        return 3
    }

    func decrement(register: inout Byte) -> Cycles {
        flags.formIntersection(.fullCarry) // preserve old carry flag
        flags.formUnion(.subtract)
        if register == 1 { flags.formUnion(.zero) }
        if register & 0x0f == 0 { flags.formUnion(.halfCarry) }
        register &-= 1
        return 1
    }

    func decrementValue(at address: Address, context: CPUContext) -> Cycles {
        flags.formIntersection(.fullCarry)
        flags.formUnion(.subtract)
        let value = context.readCycle(address: address)
        if value & 0x0f == 0 { flags.formUnion(.halfCarry) }
        if value == 1 { flags.formUnion(.zero) }
        context.writeCycle(byte: value &- 1, to: address)
        return 3
    }

    func setCarryFlag() -> Cycles {
        flags.formIntersection(.zero) // preserve zero flag
        flags.formUnion(.fullCarry)
        return 1
    }

    func complementAccumulator() -> Cycles {
        a = ~a
        flags.formUnion([.halfCarry, .subtract])
        return 1
    }

    func complementCarryFlag() -> Cycles {
        flags.formSymmetricDifference(.fullCarry)
        flags.formIntersection([.zero, .fullCarry]) // preserve zero flag
        return 1
    }

    func add(value: Byte, to register: inout Byte) -> Cycles {
        flags = []
        if register > register &+ value { flags.formUnion(.fullCarry) }
        if register & 0x0f + value & 0x0f > 0x0f { flags.formUnion(.halfCarry) }
        register &+= value
        if register == 0 { flags.formUnion(.zero) }
        return 1
    }

    func add(address: Address, to register: inout Byte, context: CPUContext) -> Cycles {
        let value = context.readCycle(address: address)
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
        return 1
    }

    func addWithCarry(address: Address, to register: inout Byte, context: CPUContext) -> Cycles {
        let value = context.readCycle(address: address)
        _ = addWithCarry(value: value, to: &register)
        return 2
    }

    func addOperand(to register: inout Byte, context: CPUContext) -> Cycles {
        let value = fetchByte(context: context)
        _ = add(value: value, to: &register)
        return 2
    }

    func addOperandWithCarry(to register: inout Byte, context: CPUContext) -> Cycles {
        let value = fetchByte(context: context)
        _ = addWithCarry(value: value, to: &register)
        return 2
    }

    func subtract(value: Byte, from register: inout Byte) -> Cycles {
        flags = .subtract
        if register < value { flags.formUnion(.fullCarry) }
        if register & 0x0f < value & 0x0f { flags.formUnion(.halfCarry) }
        if register == value { flags.formUnion(.zero) }
        register &-= value
        return 1
    }

    func subtract(address: Address, from register: inout Byte, context: CPUContext) -> Cycles {
        let value = context.readCycle(address: address)
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
        return 1
    }

    func subtractWithCarry(address: Address, from register: inout Byte, context: CPUContext) -> Cycles {
        let value = context.readCycle(address: address)
        _ = subtractWithCarry(value: value, from: &register)
        return 2
    }

    func subtractOperand(from register: inout Byte, context: CPUContext) -> Cycles {
        let value = fetchByte(context: context)
        _ = subtract(value: value, from: &register)
        return 2
    }

    func subtractOperandWithCarry(from register: inout Byte, context: CPUContext) -> Cycles {
        let value = fetchByte(context: context)
        _ = subtractWithCarry(value: value, from: &register)
        return 2
    }

    func and(value: Byte, into register: inout Byte) -> Cycles {
        register &= value
        flags = register == 0 ? [.zero, .halfCarry] : .halfCarry
        return 1
    }

    func and(address: Address, into register: inout Byte, context: CPUContext) -> Cycles {
        let value = context.readCycle(address: address)
        _ = and(value: value, into: &register)
        return 2
    }

    func andOperand(into register: inout Byte, context: CPUContext) -> Cycles {
        flags = .halfCarry
        register &= fetchByte(context: context)
        if register == 0 { flags.formUnion(.zero) }
        return 2
    }

    func or(value: Byte, into register: inout Byte) -> Cycles {
        register |= value
        flags = register == 0 ? .zero : []
        return 1
    }

    func or(address: Address, into register: inout Byte, context: CPUContext) -> Cycles {
        let value = context.readCycle(address: address)
        _ = or(value: value, into: &register)
        return 2
    }

    func orOperand(into register: inout Byte, context: CPUContext) -> Cycles {
        let value = fetchByte(context: context)
        register |= value
        flags = register == 0 ? .zero : []
        return 2
    }

    func xor(value: Byte, into register: inout Byte) -> Cycles {
        register ^= value
        flags = register == 0 ? .zero : []
        return 1
    }

    func xor(address: Address, into register: inout Byte, context: CPUContext) -> Cycles {
        let value = context.readCycle(address: address)
        _ = xor(value: value, into: &register)
        return 2
    }

    func xorOperand(into register: inout Byte, context: CPUContext) -> Cycles {
        let value = fetchByte(context: context)
        register ^= value
        flags = register == 0 ? .zero : []
        return 2
    }

    func compare(address: Address, with register: Byte, context: CPUContext) -> Cycles {
        let value = context.readCycle(address: address)
        _ = compare(value: value, with: register)
        return 2
    }

    func compare(value: Byte, with register: Byte) -> Cycles {
        flags = .subtract
        if register < value { flags.formUnion(.fullCarry) }
        if register & 0x0f < value & 0x0f { flags.formUnion(.halfCarry) }
        if register == value { flags.formUnion(.zero) }
        return 1
    }

    func compareOperand(with register: Byte, context: CPUContext) -> Cycles {
        let value = fetchByte(context: context)
        _ = compare(value: value, with: register)
        return 2
    }

    // MARK: 16-bit Arithmetic/Logical

    func increment(pair: inout Word) -> Cycles {
        pair &+= 1
        return 2
    }

    func decrement(pair: inout Word) -> Cycles {
        pair &-= 1
        return 2
    }

    func add(value: Word, to pair: inout Word) -> Cycles {
        flags.formIntersection(.zero) // preserve old zero flag
        if pair & 0x0fff + value & 0x0fff > 0x0fff { flags.formUnion(.halfCarry) }
        if pair > pair &+ value { flags.formUnion(.fullCarry) }
        pair &+= value
        return 2
    }

    func addSignedOperandToStackPointer(context: CPUContext) -> Cycles {
        flags = []
        let toAdd = Int8(bitPattern: fetchByte(context: context))
        let newSP = sp.wrappingAdd(toAdd)

        let toAdd32 = Int32(toAdd)
        let sp32 = Int32(sp)

        if sp32 & 0xff + toAdd32 & 0xff > 0xff {
            flags.formUnion(.fullCarry)
        }
        if sp32 & 0x0f + toAdd32 & 0x0f > 0x0f {
            flags.formUnion(.halfCarry)
        }
        sp = newSP
        return 4
    }

    // MARK: Jumps/Calls

    func jump(context: CPUContext) -> Cycles {
        pc = fetchWord(context: context)
        return 4
    }

    func jump(to word: Word) -> Cycles {
        pc = word
        return 1
    }

    func jump(condition: Bool, context: CPUContext) -> Cycles {
        let address = fetchWord(context: context)
        if condition {
            pc = address
            return 4
        } else {
            return 3
        }
    }

    /// Jump relative to the current `pc` rather than to an absolute address.
    /// Slightly more efficient than a normal jump.
    func jumpRelative(context: CPUContext) -> Cycles {
        let distance = Int8(bitPattern: fetchByte(context: context))
        pc = pc.wrappingAdd(distance)
        return 3
    }

    func jumpRelative(condition: Bool, context: CPUContext) -> Cycles {
        let distance = Int8(bitPattern: fetchByte(context: context))
        if condition {
            pc = pc.wrappingAdd(distance)
            return 3
        } else {
            return 2
        }
    }

    func `return`(context: CPUContext) -> Cycles {
        pc = popStack(context: context)
        return 4
    }

    func `return`(condition: Bool, context: CPUContext) -> Cycles {
        if condition {
            _ = `return`(context: context)
            return 5
        } else {
            return 2
        }
    }

    func returnEnableInterrupts(context: CPUContext) -> Cycles {
        interuptsEnabled = true
        return `return`(context: context)
    }

    func call(context: CPUContext) -> Cycles {
        let address = fetchWord(context: context)
        pushStack(value: pc, context: context)
        pc = address
        return 6
    }

    func call(condition: Bool, context: CPUContext) -> Cycles {
        let address = fetchWord(context: context)
        if condition {
            pushStack(value: pc, context: context)
            pc = address
            return 6
        } else {
            return 3
        }
    }

    func reset(vector: Byte, context: CPUContext) -> Cycles {
        pushStack(value: pc, context: context)
        pc = Word(vector)
        return 4
    }

    // MARK: 8-bit Rotations/Shifts

    func rotateLeftCarryA() -> Cycles {
        let carry = a >> 7
        flags = carry != 0 ? .fullCarry : []
        a = a << 1 | carry
        return 1
    }

    func rotateRightCarryA() -> Cycles {
        let carry = a << 7
        flags = carry != 0 ? .fullCarry : []
        a = a >> 1 | carry
        return 1
    }

    /// Rotate `a` left moving bit 7 into the carry flag and the carry flag into bit 0.
    /// Updates carry flag, resets others.
    func rotateLeftA() -> Cycles {
        let carry: Byte = flags.contains(.fullCarry) ? 1 : 0
        flags = []
        if a & 0x80 != 0 { flags.formUnion(.fullCarry) }
        a = a << 1 | carry
        return 1
    }

    /// Rotate `a` right moving bit 0 into the carry flag and the carry flag into bit 7.
    /// Updates carry flag, resets others.
    func rotateRightA() -> Cycles {
        let carry: Byte = flags.contains(.fullCarry) ? 0x80 : 0
        flags = []
        if a & 0x01 != 0 { flags.formUnion(.fullCarry) }
        a = a >> 1 | carry
        return 1
    }

    // MARK: Misc/Control

    func nop() -> Cycles {
        return 1
    }

    func stop() -> Cycles {
        return 1
    }

    func halt() -> Cycles {
        isHalted = true
        return 1
    }

    func disableInterrupts() -> Cycles {
        interuptsEnabled = false
        return 1
    }
    
    func enableInterrupts() -> Cycles {
        interuptsEnabled = true
        return 1
    }

    // MARK: Undefined

    func undefined() -> Cycles {
        assertionFailure("This is an error in the program and would crash a real Game Boy")
        return 0
    }
}
