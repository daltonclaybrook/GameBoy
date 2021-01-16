extension CPU {

    // MARK: 8-bit Loads

    func load(value: Byte, into address: Address, context: CPUContext) {
        context.writeCycle(byte: value, to: address)
    }

    func loadOperand(into register: inout Byte, context: CPUContext) {
        register = fetchByte(context: context)
    }

    func loadFromHRAMOperand(int register: inout Byte, context: CPUContext) {
        let offset = fetchByte(context: context)
        register = context.readCycle(address: 0xff00 | Word(offset))
    }

    func loadFromHRAMAddress(withLoadByte lowByte: Byte, into register: inout Byte, context: CPUContext) {
        register = context.readCycle(address: 0xff00 | Word(lowByte))
    }

    func loadFromAddressOperand(into register: inout Byte, context: CPUContext) {
        let address = fetchWord(context: context)
        register = context.readCycle(address: address)
    }

    func load(address: Address, into register: inout Byte, context: CPUContext) {
        register = context.readCycle(address: address)
    }

    func loadAddressAndIncrementHL(from register: Byte, context: CPUContext) {
        let address = hl
        hl &+= 1
        context.writeCycle(byte: register, to: address)
    }

    func loadFromAddressAndIncrementHL(to register: inout Byte, context: CPUContext) {
        let address = hl
        hl &+= 1
        register = context.readCycle(address: address)
    }

    func loadAddressAndDecrementHL(from register: Byte, context: CPUContext) {
        let address = hl
        hl &-= 1
        context.writeCycle(byte: register, to: address)
    }

    func loadOperand(into address: Address, context: CPUContext) {
        let value = fetchByte(context: context)
        context.writeCycle(byte: value, to: address)
    }

    func loadFromAddressAndDecrementHL(to register: inout Byte, context: CPUContext) {
        let address = hl
        hl &-= 1
        register = context.readCycle(address: address)
    }

    func load(value: Byte, into register: inout Byte) {
        register = value
    }

    func loadHRAMOperand(from register: Byte, context: CPUContext) {
        let lowByte = fetchByte(context: context)
        context.writeCycle(byte: register, to: 0xff00 | Word(lowByte))
    }

    func loadHRAM(from register: Byte, intoAddressWithLowByte lowByte: Byte, context: CPUContext) {
        context.writeCycle(byte: register, to: 0xff00 | Word(lowByte))
    }

    func loadIntoAddressOperand(byte: Byte, context: CPUContext) {
        let address = fetchWord(context: context)
        context.writeCycle(byte: byte, to: address)
    }

    // MARK: 16-bit Loads

    func loadOperand(into pair: inout Word, context: CPUContext) {
        pair = fetchWord(context: context)
    }

    func loadIntoAddressOperand(word: Word, context: CPUContext) {
        let address = fetchWord(context: context)
        context.writeCycle(word: word, to: address)
    }

    func load(value: Word, into pair: inout Word, context: CPUContext) {
        pair = value
        context.tickCycle()
    }

    func pop(pair: inout Word, context: CPUContext) {
        pair = popStack(context: context)
    }

    func push(pair: Word, context: CPUContext) {
        pushStack(value: pair, context: context)
    }

    /// Add signed operand to SP and store the result in HL
    func addSignedOperandToStackPointer(storeIn pair: inout Word, context: CPUContext) {
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
        context.tickCycle()
    }

    // MARK: 8-bit Arthithmetic/Logical

    /// Assuming the last arithmetic operation was between two BCD numbers, converts
    /// the result in `a` to BCD
    func decimalAdjustAccumulator() {
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
    }

    func increment(register: inout Byte) {
        flags.formIntersection(.fullCarry) // preserve old carry flag
        if register == 0xff { flags.formUnion(.zero) }
        if register & 0x0f == 0x0f { flags.formUnion(.halfCarry) }
        register &+= 1
    }

    func incrementValue(at address: Address, context: CPUContext) {
        flags.formIntersection(.fullCarry) // preserve the carry flag
        let value = context.readCycle(address: address)
        if value & 0x0f == 0x0f { flags.formUnion(.halfCarry) }
        if value == 0xff { flags.formUnion(.zero) }
        context.writeCycle(byte: value &+ 1, to: address)
    }

    func decrement(register: inout Byte) {
        flags.formIntersection(.fullCarry) // preserve old carry flag
        flags.formUnion(.subtract)
        if register == 1 { flags.formUnion(.zero) }
        if register & 0x0f == 0 { flags.formUnion(.halfCarry) }
        register &-= 1
    }

    func decrementValue(at address: Address, context: CPUContext) {
        flags.formIntersection(.fullCarry)
        flags.formUnion(.subtract)
        let value = context.readCycle(address: address)
        if value & 0x0f == 0 { flags.formUnion(.halfCarry) }
        if value == 1 { flags.formUnion(.zero) }
        context.writeCycle(byte: value &- 1, to: address)
    }

    func setCarryFlag() {
        flags.formIntersection(.zero) // preserve zero flag
        flags.formUnion(.fullCarry)
    }

    func complementAccumulator() {
        a = ~a
        flags.formUnion([.halfCarry, .subtract])
    }

    func complementCarryFlag() {
        flags.formSymmetricDifference(.fullCarry)
        flags.formIntersection([.zero, .fullCarry]) // preserve zero flag
    }

    func add(value: Byte, to register: inout Byte) {
        flags = []
        if register > register &+ value { flags.formUnion(.fullCarry) }
        if register & 0x0f + value & 0x0f > 0x0f { flags.formUnion(.halfCarry) }
        register &+= value
        if register == 0 { flags.formUnion(.zero) }
    }

    func add(address: Address, to register: inout Byte, context: CPUContext) {
        let value = context.readCycle(address: address)
        add(value: value, to: &register)
    }

    func addWithCarry(value: Byte, to register: inout Byte) {
        let carry: Byte = flags.contains(.fullCarry) ? 1 : 0
        flags = []
        if register > register &+ value { flags.formUnion(.fullCarry) }
        if register & 0x0f + value & 0x0f > 0x0f { flags.formUnion(.halfCarry) }
        register &+= value
        if register > register &+ carry { flags.formUnion(.fullCarry) }
        if register & 0x0f + carry > 0x0f { flags.formUnion(.halfCarry) }
        register &+= carry
        if register == 0 { flags.formUnion(.zero) }
    }

    func addWithCarry(address: Address, to register: inout Byte, context: CPUContext) {
        let value = context.readCycle(address: address)
        addWithCarry(value: value, to: &register)
    }

    func addOperand(to register: inout Byte, context: CPUContext) {
        let value = fetchByte(context: context)
        add(value: value, to: &register)
    }

    func addOperandWithCarry(to register: inout Byte, context: CPUContext) {
        let value = fetchByte(context: context)
        addWithCarry(value: value, to: &register)
    }

    func subtract(value: Byte, from register: inout Byte) {
        flags = .subtract
        if register < value { flags.formUnion(.fullCarry) }
        if register & 0x0f < value & 0x0f { flags.formUnion(.halfCarry) }
        if register == value { flags.formUnion(.zero) }
        register &-= value
    }

    func subtract(address: Address, from register: inout Byte, context: CPUContext) {
        let value = context.readCycle(address: address)
        subtract(value: value, from: &register)
    }

    func subtractWithCarry(value: Byte, from register: inout Byte) {
        let carry: Byte = flags.contains(.fullCarry) ? 1 : 0
        flags = .subtract
        if register < value { flags.formUnion(.fullCarry) }
        if register & 0x0f < value & 0x0f { flags.formUnion(.halfCarry) }
        register &-= value
        if register < carry { flags.formUnion(.fullCarry) }
        if register & 0x0f < carry { flags.formUnion(.halfCarry) }
        register &-= carry
        if register == 0 { flags.formUnion(.zero) }
    }

    func subtractWithCarry(address: Address, from register: inout Byte, context: CPUContext) {
        let value = context.readCycle(address: address)
        subtractWithCarry(value: value, from: &register)
    }

    func subtractOperand(from register: inout Byte, context: CPUContext) {
        let value = fetchByte(context: context)
        subtract(value: value, from: &register)
    }

    func subtractOperandWithCarry(from register: inout Byte, context: CPUContext) {
        let value = fetchByte(context: context)
        subtractWithCarry(value: value, from: &register)
    }

    func and(value: Byte, into register: inout Byte) {
        register &= value
        flags = register == 0 ? [.zero, .halfCarry] : .halfCarry
    }

    func and(address: Address, into register: inout Byte, context: CPUContext) {
        let value = context.readCycle(address: address)
        and(value: value, into: &register)
    }

    func andOperand(into register: inout Byte, context: CPUContext) {
        flags = .halfCarry
        register &= fetchByte(context: context)
        if register == 0 { flags.formUnion(.zero) }
    }

    func or(value: Byte, into register: inout Byte) {
        register |= value
        flags = register == 0 ? .zero : []
    }

    func or(address: Address, into register: inout Byte, context: CPUContext) {
        let value = context.readCycle(address: address)
        or(value: value, into: &register)
    }

    func orOperand(into register: inout Byte, context: CPUContext) {
        let value = fetchByte(context: context)
        register |= value
        flags = register == 0 ? .zero : []
    }

    func xor(value: Byte, into register: inout Byte) {
        register ^= value
        flags = register == 0 ? .zero : []
    }

    func xor(address: Address, into register: inout Byte, context: CPUContext) {
        let value = context.readCycle(address: address)
        xor(value: value, into: &register)
    }

    func xorOperand(into register: inout Byte, context: CPUContext) {
        let value = fetchByte(context: context)
        register ^= value
        flags = register == 0 ? .zero : []
    }

    func compare(address: Address, with register: Byte, context: CPUContext) {
        let value = context.readCycle(address: address)
        compare(value: value, with: register)
    }

    func compare(value: Byte, with register: Byte) {
        flags = .subtract
        if register < value { flags.formUnion(.fullCarry) }
        if register & 0x0f < value & 0x0f { flags.formUnion(.halfCarry) }
        if register == value { flags.formUnion(.zero) }
    }

    func compareOperand(with register: Byte, context: CPUContext) {
        let value = fetchByte(context: context)
        compare(value: value, with: register)
    }

    // MARK: 16-bit Arithmetic/Logical

    func increment(pair: inout Word, context: CPUContext) {
        pair &+= 1
        context.tickCycle()
    }

    func decrement(pair: inout Word, context: CPUContext) {
        pair &-= 1
        context.tickCycle()
    }

    func add(value: Word, to pair: inout Word, context: CPUContext) {
        flags.formIntersection(.zero) // preserve old zero flag
        if pair & 0x0fff + value & 0x0fff > 0x0fff { flags.formUnion(.halfCarry) }
        if pair > pair &+ value { flags.formUnion(.fullCarry) }
        pair &+= value
        context.tickCycle()
    }

    func addSignedOperandToStackPointer(context: CPUContext) {
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
        context.tickCycle()
        context.tickCycle()
    }

    // MARK: Jumps/Calls

    func jump(context: CPUContext) {
        pc = fetchWord(context: context)
        context.tickCycle()
    }

    func jump(to word: Word) {
        pc = word
    }

    func jump(condition: Bool, context: CPUContext) {
        let address = fetchWord(context: context)
        if condition {
            pc = address
            context.tickCycle()
        }
    }

    /// Jump relative to the current `pc` rather than to an absolute address.
    /// Slightly more efficient than a normal jump.
    func jumpRelative(context: CPUContext) {
        let distance = Int8(bitPattern: fetchByte(context: context))
        pc = pc.wrappingAdd(distance)
        context.tickCycle()
    }

    func jumpRelative(condition: Bool, context: CPUContext) {
        let distance = Int8(bitPattern: fetchByte(context: context))
        if condition {
            pc = pc.wrappingAdd(distance)
            context.tickCycle()
        }
    }

    func `return`(context: CPUContext) {
        pc = popStack(context: context)
        context.tickCycle()
    }

    func `return`(condition: Bool, context: CPUContext) {
        context.tickCycle()
        if condition {
            `return`(context: context)
        }
    }

    func returnEnableInterrupts(context: CPUContext) {
        interuptsEnabled = true
        return `return`(context: context)
    }

    func call(context: CPUContext) {
        let address = fetchWord(context: context)
        pushStack(value: pc, context: context)
        pc = address
    }

    func call(condition: Bool, context: CPUContext) {
        let address = fetchWord(context: context)
        if condition {
            pushStack(value: pc, context: context)
            pc = address
        }
    }

    func reset(vector: Byte, context: CPUContext) {
        pushStack(value: pc, context: context)
        pc = Word(vector)
    }

    // MARK: 8-bit Rotations/Shifts

    func rotateLeftCarryA() {
        let carry = a >> 7
        flags = carry != 0 ? .fullCarry : []
        a = a << 1 | carry
    }

    func rotateRightCarryA() {
        let carry = a << 7
        flags = carry != 0 ? .fullCarry : []
        a = a >> 1 | carry
    }

    /// Rotate `a` left moving bit 7 into the carry flag and the carry flag into bit 0.
    /// Updates carry flag, resets others.
    func rotateLeftA() {
        let carry: Byte = flags.contains(.fullCarry) ? 1 : 0
        flags = []
        if a & 0x80 != 0 { flags.formUnion(.fullCarry) }
        a = a << 1 | carry
    }

    /// Rotate `a` right moving bit 0 into the carry flag and the carry flag into bit 7.
    /// Updates carry flag, resets others.
    func rotateRightA() {
        let carry: Byte = flags.contains(.fullCarry) ? 0x80 : 0
        flags = []
        if a & 0x01 != 0 { flags.formUnion(.fullCarry) }
        a = a >> 1 | carry
    }

    // MARK: Misc/Control

    func nop() {
    }

    func stop() {
    }

    func halt() {
        isHalted = true
    }

    func disableInterrupts() {
        interuptsEnabled = false
    }
    
    func enableInterrupts() {
        interuptsEnabled = true
    }

    // MARK: Undefined

    func undefined() {
        assertionFailure("This is an error in the program and would crash a real Game Boy")
    }
}
