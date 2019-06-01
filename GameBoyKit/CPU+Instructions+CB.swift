extension CPU {
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
		value = (value >> 1) | carry
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
}
