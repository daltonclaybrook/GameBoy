typealias BitIndex = UInt8

extension CPU {
    func prefixCB(context: CPUContext) -> Cycles {
        let opcodeIndex = Int(fetchByte(context: context))
        let opcode = CPU.cbOpcodes[opcodeIndex]
        return opcode.block(self, context)
    }

    func rotateLeftCarry(value: inout Byte) -> Cycles {
        flags = []
        let carry = value >> 7
        if carry != 0 { flags.formUnion(.fullCarry) }
        value = value << 1 | carry
        if value == 0 { flags.formUnion(.zero) }
        return 2
    }

    func rotateLeftCarry(address: Address, context: CPUContext) -> Cycles {
        var value = context.readCycle(address: address)
        _ = rotateLeftCarry(value: &value)
        context.writeCycle(byte: value, to: address)
        return 4
    }

    func rotateRightCarry(value: inout Byte) -> Cycles {
        flags = []
        let carry = (value & 0x01) << 7
        if carry != 0 { flags.formUnion(.fullCarry) }
        value = value >> 1 | carry
        if value == 0 { flags.formUnion(.zero) }
        return 2
    }

    func rotateRightCarry(address: Address, context: CPUContext) -> Cycles {
        var value = context.readCycle(address: address)
        _ = rotateRightCarry(value: &value)
        context.writeCycle(byte: value, to: address)
        return 4
    }

    func rotateLeft(value: inout Byte) -> Cycles {
        let carry: Byte = flags.contains(.fullCarry) ? 1 : 0
        flags = []
        if value & 0x80 != 0 { flags.formUnion(.fullCarry) }
        value = value << 1 | carry
        if value == 0 { flags.formUnion(.zero) }
        return 2
    }

    func rotateLeft(address: Address, context: CPUContext) -> Cycles {
        var value = context.readCycle(address: address)
        _ = rotateLeft(value: &value)
        context.writeCycle(byte: value, to: address)
        return 4
    }

    func rotateRight(value: inout Byte) -> Cycles {
        let carry: Byte = flags.contains(.fullCarry) ? 0x80 : 0
        flags = []
        if value & 0x01 != 0 { flags.formUnion(.fullCarry) }
        value = value >> 1 | carry
        if value == 0 { flags.formUnion(.zero) }
        return 2
    }

    func rotateRight(address: Address, context: CPUContext) -> Cycles {
        var value = context.readCycle(address: address)
        _ = rotateRight(value: &value)
        context.writeCycle(byte: value, to: address)
        return 4
    }

    func shiftLeftArithmetic(value: inout Byte) -> Cycles {
        flags = value & 0x80 != 0 ? .fullCarry : []
        value <<= 1
        if value == 0 { flags.formUnion(.zero) }
        return 2
    }

    func shiftLeftArithmetic(address: Address, context: CPUContext) -> Cycles {
        var value = context.readCycle(address: address)
        _ = shiftLeftArithmetic(value: &value)
        context.writeCycle(byte: value, to: address)
        return 4
    }

    func shiftRightArithmetic(value: inout Byte) -> Cycles {
        flags = value & 0x01 != 0 ? .fullCarry : []
        value = (value & 0x80) | (value >> 1)
        if value == 0 { flags.formUnion(.zero) }
        return 2
    }

    func shiftRightArithmetic(address: Address, context: CPUContext) -> Cycles {
        var value = context.readCycle(address: address)
        _ = shiftRightArithmetic(value: &value)
        context.writeCycle(byte: value, to: address)
        return 4
    }

    func swap(value: inout Byte) -> Cycles {
        value = (value << 4) | (value >> 4)
        flags = value == 0 ? .zero : []
        return 2
    }

    func swap(address: Address, context: CPUContext) -> Cycles {
        var value = context.readCycle(address: address)
        _ = swap(value: &value)
        context.writeCycle(byte: value, to: address)
        return 4
    }

    func shiftRightLogical(value: inout Byte) -> Cycles {
        flags = value & 0x01 != 0 ? .fullCarry : []
        value >>= 1
        if value == 0 { flags.formUnion(.zero) }
        return 2
    }

    func shiftRightLogical(address: Address, context: CPUContext) -> Cycles {
        var value = context.readCycle(address: address)
        _ = shiftRightLogical(value: &value)
        context.writeCycle(byte: value, to: address)
        return 4
    }

    func checkBit(index: BitIndex, of byte: Byte) -> Cycles {
        flags.formIntersection(.fullCarry) // preserve old carry flag
        flags.formUnion(.halfCarry)
        if (1 << index) & byte == 0 { flags.formUnion(.zero) }
        return 2
    }

    func checkBit(index: BitIndex, of address: Address, context: CPUContext) -> Cycles {
        let byte = context.readCycle(address: address)
        _ = checkBit(index: index, of: byte)
        return 3
    }

    func resetBit(index: BitIndex, of byte: inout Byte) -> Cycles {
        byte &= ~(1 << index)
        return 2
    }

    func resetBit(index: BitIndex, of address: Address, context: CPUContext) -> Cycles {
        var byte = context.readCycle(address: address)
        _ = resetBit(index: index, of: &byte)
        context.writeCycle(byte: byte, to: address)
        return 4
    }

    func setBit(index: BitIndex, of byte: inout Byte) -> Cycles {
        byte |= 1 << index
        return 2
    }

    func setBit(index: BitIndex, of address: Address, context: CPUContext) -> Cycles {
        var byte = context.readCycle(address: address)
        _ = setBit(index: index, of: &byte)
        context.writeCycle(byte: byte, to: address)
        return 4
    }
}
