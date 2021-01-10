typealias BitIndex = UInt8

extension CPU {
    func prefixCB() -> Cycles {
        let opcodeIndex = Int(mmu.read(address: pc &+ 1))
        let opcode = CPU.cbOpcodes[opcodeIndex]
        return opcode.block(self)
    }

    func rotateLeftCarry(value: inout Byte) -> Cycles {
        flags = []
        let carry = value >> 7
        if carry != 0 { flags.formUnion(.fullCarry) }
        value = value << 1 | carry
        if value == 0 { flags.formUnion(.zero) }
        pc &+= 2
        return 2
    }

    func rotateLeftCarry(address: Address) -> Cycles {
        var value = mmu.read(address: address)
        _ = rotateLeftCarry(value: &value)
        mmu.write(byte: value, to: address)
        return 4
    }

    func rotateRightCarry(value: inout Byte) -> Cycles {
        flags = []
        let carry = (value & 0x01) << 7
        if carry != 0 { flags.formUnion(.fullCarry) }
        value = value >> 1 | carry
        if value == 0 { flags.formUnion(.zero) }
        pc &+= 2
        return 2
    }

    func rotateRightCarry(address: Address) -> Cycles {
        var value = mmu.read(address: address)
        _ = rotateRightCarry(value: &value)
        mmu.write(byte: value, to: address)
        return 4
    }

    func rotateLeft(value: inout Byte) -> Cycles {
        let carry: Byte = flags.contains(.fullCarry) ? 1 : 0
        flags = []
        if value & 0x80 != 0 { flags.formUnion(.fullCarry) }
        value = value << 1 | carry
        if value == 0 { flags.formUnion(.zero) }
        pc &+= 2
        return 2
    }

    func rotateLeft(address: Address) -> Cycles {
        var value = mmu.read(address: address)
        _ = rotateLeft(value: &value)
        mmu.write(byte: value, to: address)
        return 4
    }

    func rotateRight(value: inout Byte) -> Cycles {
        let carry: Byte = flags.contains(.fullCarry) ? 0x80 : 0
        flags = []
        if value & 0x01 != 0 { flags.formUnion(.fullCarry) }
        value = value >> 1 | carry
        if value == 0 { flags.formUnion(.zero) }
        pc &+= 2
        return 2
    }

    func rotateRight(address: Address) -> Cycles {
        var value = mmu.read(address: address)
        _ = rotateRight(value: &value)
        mmu.write(byte: value, to: address)
        return 4
    }

    func shiftLeftArithmetic(value: inout Byte) -> Cycles {
        flags = value & 0x80 != 0 ? .fullCarry : []
        value <<= 1
        if value == 0 { flags.formUnion(.zero) }
        pc &+= 2
        return 2
    }

    func shiftLeftArithmetic(address: Address) -> Cycles {
        var value = mmu.read(address: address)
        _ = shiftLeftArithmetic(value: &value)
        mmu.write(byte: value, to: address)
        return 4
    }

    func shiftRightArithmetic(value: inout Byte) -> Cycles {
        flags = value & 0x01 != 0 ? .fullCarry : []
        value = (value & 0x80) | (value >> 1)
        if value == 0 { flags.formUnion(.zero) }
        pc &+= 2
        return 2
    }

    func shiftRightArithmetic(address: Address) -> Cycles {
        var value = mmu.read(address: address)
        _ = shiftRightArithmetic(value: &value)
        mmu.write(byte: value, to: address)
        return 4
    }

    func swap(value: inout Byte) -> Cycles {
        value = (value << 4) | (value >> 4)
        flags = value == 0 ? .zero : []
        pc &+= 2
        return 2
    }

    func swap(address: Address) -> Cycles {
        var value = mmu.read(address: address)
        _ = swap(value: &value)
        mmu.write(byte: value, to: address)
        return 4
    }

    func shiftRightLogical(value: inout Byte) -> Cycles {
        flags = value & 0x01 != 0 ? .fullCarry : []
        value >>= 1
        if value == 0 { flags.formUnion(.zero) }
        pc &+= 2
        return 2
    }

    func shiftRightLogical(address: Address) -> Cycles {
        var value = mmu.read(address: address)
        _ = shiftRightLogical(value: &value)
        mmu.write(byte: value, to: address)
        return 4
    }

    func checkBit(index: BitIndex, of byte: Byte) -> Cycles {
        flags.formIntersection(.fullCarry) // preserve old carry flag
        flags.formUnion(.halfCarry)
        if (1 << index) & byte == 0 { flags.formUnion(.zero) }
        pc &+= 2
        return 2
    }

    func checkBit(index: BitIndex, of address: Address) -> Cycles {
        let byte = mmu.read(address: address)
        _ = checkBit(index: index, of: byte)
        return 3
    }

    func resetBit(index: BitIndex, of byte: inout Byte) -> Cycles {
        byte &= ~(1 << index)
        pc &+= 2
        return 2
    }

    func resetBit(index: BitIndex, of address: Address) -> Cycles {
        var byte = mmu.read(address: address)
        _ = resetBit(index: index, of: &byte)
        mmu.write(byte: byte, to: address)
        return 4
    }

    func setBit(index: BitIndex, of byte: inout Byte) -> Cycles {
        byte |= 1 << index
        pc &+= 2
        return 2
    }

    func setBit(index: BitIndex, of address: Address) -> Cycles {
        var byte = mmu.read(address: address)
        _ = setBit(index: index, of: &byte)
        mmu.write(byte: byte, to: address)
        return 4
    }
}
