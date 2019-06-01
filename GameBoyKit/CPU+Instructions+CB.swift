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
}
