typealias BitIndex = UInt8

extension CPU {
    func prefixCB(context: CPUContext) {
        let opcodeIndex = Int(fetchByte(context: context))
        let opcode = CPU.cbOpcodes[opcodeIndex]
        opcode.executeBlock(self, context)
    }

    func rotateLeftCarry(value: inout Byte) {
        flags = []
        let carry = value >> 7
        if carry != 0 { flags.insert(.fullCarry) }
        value = value << 1 | carry
        if value == 0 { flags.insert(.zero) }
    }

    func rotateLeftCarry(address: Address, context: CPUContext) {
        var value = context.readCycle(address: address)
        rotateLeftCarry(value: &value)
        context.writeCycle(byte: value, to: address)
    }

    func rotateRightCarry(value: inout Byte) {
        flags = []
        let carry = (value & 0x01) << 7
        if carry != 0 { flags.insert(.fullCarry) }
        value = value >> 1 | carry
        if value == 0 { flags.insert(.zero) }
    }

    func rotateRightCarry(address: Address, context: CPUContext) {
        var value = context.readCycle(address: address)
        rotateRightCarry(value: &value)
        context.writeCycle(byte: value, to: address)
    }

    func rotateLeft(value: inout Byte) {
        let carry: Byte = flags.contains(.fullCarry) ? 1 : 0
        flags = []
        if value & 0x80 != 0 { flags.insert(.fullCarry) }
        value = value << 1 | carry
        if value == 0 { flags.insert(.zero) }
    }

    func rotateLeft(address: Address, context: CPUContext) {
        var value = context.readCycle(address: address)
        rotateLeft(value: &value)
        context.writeCycle(byte: value, to: address)
    }

    func rotateRight(value: inout Byte) {
        let carry: Byte = flags.contains(.fullCarry) ? 0x80 : 0
        flags = []
        if value & 0x01 != 0 { flags.insert(.fullCarry) }
        value = value >> 1 | carry
        if value == 0 { flags.insert(.zero) }
    }

    func rotateRight(address: Address, context: CPUContext) {
        var value = context.readCycle(address: address)
        rotateRight(value: &value)
        context.writeCycle(byte: value, to: address)
    }

    func shiftLeftArithmetic(value: inout Byte) {
        flags = value & 0x80 != 0 ? .fullCarry : []
        value <<= 1
        if value == 0 { flags.insert(.zero) }
    }

    func shiftLeftArithmetic(address: Address, context: CPUContext) {
        var value = context.readCycle(address: address)
        shiftLeftArithmetic(value: &value)
        context.writeCycle(byte: value, to: address)
    }

    func shiftRightArithmetic(value: inout Byte) {
        flags = value & 0x01 != 0 ? .fullCarry : []
        value = (value & 0x80) | (value >> 1)
        if value == 0 { flags.insert(.zero) }
    }

    func shiftRightArithmetic(address: Address, context: CPUContext) {
        var value = context.readCycle(address: address)
        shiftRightArithmetic(value: &value)
        context.writeCycle(byte: value, to: address)
    }

    func swap(value: inout Byte) {
        value = (value << 4) | (value >> 4)
        flags = value == 0 ? .zero : []
    }

    func swap(address: Address, context: CPUContext) {
        var value = context.readCycle(address: address)
        swap(value: &value)
        context.writeCycle(byte: value, to: address)
    }

    func shiftRightLogical(value: inout Byte) {
        flags = value & 0x01 != 0 ? .fullCarry : []
        value >>= 1
        if value == 0 { flags.insert(.zero) }
    }

    func shiftRightLogical(address: Address, context: CPUContext) {
        var value = context.readCycle(address: address)
        shiftRightLogical(value: &value)
        context.writeCycle(byte: value, to: address)
    }

    func checkBit(index: BitIndex, of byte: Byte) {
        flags.formIntersection(.fullCarry) // preserve old carry flag
        flags.insert(.halfCarry)
        if (1 << index) & byte == 0 { flags.insert(.zero) }
    }

    func checkBit(index: BitIndex, of address: Address, context: CPUContext) {
        let byte = context.readCycle(address: address)
        checkBit(index: index, of: byte)
    }

    func resetBit(index: BitIndex, of byte: inout Byte) {
        byte &= ~(1 << index)
    }

    func resetBit(index: BitIndex, of address: Address, context: CPUContext) {
        var byte = context.readCycle(address: address)
        resetBit(index: index, of: &byte)
        context.writeCycle(byte: byte, to: address)
    }

    func setBit(index: BitIndex, of byte: inout Byte) {
        byte |= 1 << index
    }

    func setBit(index: BitIndex, of address: Address, context: CPUContext) {
        var byte = context.readCycle(address: address)
        setBit(index: index, of: &byte)
        context.writeCycle(byte: byte, to: address)
    }
}
