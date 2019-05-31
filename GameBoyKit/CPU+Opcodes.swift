extension CPU {
	static let allOpcodes: [Opcode] = [
		// 0x0n
		Opcode(mnemonic: "NOP", cycles: 1) { $0.nop() },
		Opcode(mnemonic: "LD BC, nn", cycles: 2) { $0.loadOperand(into: &$0.bc) },
		Opcode(mnemonic: "LD (BC), A", cycles: 2) { $0.load(byte: $0.a, into: $0.bc) },
		Opcode(mnemonic: "INC BC", cycles: 1) { $0.increment(pair: &$0.bc) },
		Opcode(mnemonic: "INC B", cycles: 1) { $0.increment(register: &$0.b) },
		Opcode(mnemonic: "DEC B", cycles: 2) { $0.decrement(register: &$0.b) },
		Opcode(mnemonic: "LD B, n", cycles: 1) { $0.loadOperand(into: &$0.b) },
		Opcode(mnemonic: "RLCA", cycles: 5) { $0.rotateLeftCarryA() },
		Opcode(mnemonic: "LD (nn), SP", cycles: 2) { $0.loadIntoAddressOperand(word: $0.sp) },
		Opcode(mnemonic: "ADD HL, BC", cycles: 2) { $0.add(value: $0.bc, to: &$0.hl) },
		Opcode(mnemonic: "LD A, (BC)", cycles: 2) { $0.load(address: $0.bc, into: &$0.a) },
		Opcode(mnemonic: "DEC BC", cycles: 1) { $0.decrement(pair: &$0.bc) },
		Opcode(mnemonic: "INC C", cycles: 1) { $0.increment(register: &$0.c) },
		Opcode(mnemonic: "DEC C", cycles: 2) { $0.decrement(register: &$0.c) },
		Opcode(mnemonic: "LD C, n", cycles: 1) { $0.loadOperand(into: &$0.c) },
		Opcode(mnemonic: "RRCA", cycles: 2) { $0.rotateRightCarryA() },
	]
}
