extension CPU {
	static let allOpcodes: [Opcode] = [
		// 0x0n
		Opcode(mnemonic: "NOP") { $0.nop() },
		Opcode(mnemonic: "LD BC, nn") { $0.loadOperand(into: &$0.bc) },
		Opcode(mnemonic: "LD (BC), A") { $0.load(register: $0.a, into: $0.bc) },
		Opcode(mnemonic: "INC BC") { $0.increment(pair: &$0.bc) },
		Opcode(mnemonic: "INC B") { $0.increment(register: &$0.b) },
		Opcode(mnemonic: "DEC B") { $0.decrement(register: &$0.b) },
		Opcode(mnemonic: "LD B, n") { $0.loadOperand(into: &$0.b) },
		Opcode(mnemonic: "RLCA") { $0.rotateLeftCarryA() },
		Opcode(mnemonic: "LD (nn), SP") { $0.loadIntoAddressOperand(word: $0.sp) },
		Opcode(mnemonic: "ADD HL, BC") { $0.add(value: $0.bc, to: &$0.hl) },
		Opcode(mnemonic: "LD A, (BC)") { $0.load(address: $0.bc, into: &$0.a) },
		Opcode(mnemonic: "DEC BC") { $0.decrement(pair: &$0.bc) },
		Opcode(mnemonic: "INC C") { $0.increment(register: &$0.c) },
		Opcode(mnemonic: "DEC C") { $0.decrement(register: &$0.c) },
		Opcode(mnemonic: "LD C, n") { $0.loadOperand(into: &$0.c) },
		Opcode(mnemonic: "RRCA") { $0.rotateRightCarryA() },
		// 0x1n
		Opcode(mnemonic: "STOP") { $0.stop() },
		Opcode(mnemonic: "LD DE, nn") { $0.loadOperand(into: &$0.de) },
		Opcode(mnemonic: "LD (DE), A") { $0.load(register: $0.a, into: $0.de) },
		Opcode(mnemonic: "INC DE") { $0.increment(pair: &$0.de) },
		Opcode(mnemonic: "INC D") { $0.increment(register: &$0.d) },
		Opcode(mnemonic: "DEC D") { $0.decrement(register: &$0.d) },
		Opcode(mnemonic: "LD D, n") { $0.loadOperand(into: &$0.d) },
		Opcode(mnemonic: "RLA") { $0.rotateLeftA() },
		Opcode(mnemonic: "JR n") { $0.jumpRelative() },
		Opcode(mnemonic: "ADD HL, DE") { $0.add(value: $0.de, to: &$0.hl) },
		Opcode(mnemonic: "LD A, (DE)") { $0.load(address: $0.de, into: &$0.a) },
		Opcode(mnemonic: "DEC DE") { $0.decrement(pair: &$0.de) },
		Opcode(mnemonic: "INC E") { $0.increment(register: &$0.e) },
		Opcode(mnemonic: "DEC E") { $0.decrement(register: &$0.e) },
		Opcode(mnemonic: "LD E, n") { $0.loadOperand(into: &$0.e) },
		Opcode(mnemonic: "RRA") { $0.rotateRightA() },
		// 0x2n
		Opcode(mnemonic: "JR NZ, n") { $0.jumpRelative(condition: !$0.flags.contains(.zero)) },
		Opcode(mnemonic: "LD HL, nn") { $0.loadOperand(into: &$0.hl) },
		Opcode(mnemonic: "LD (HL+), A") { $0.loadAddressAndIncrementHL(from: $0.a) },
		Opcode(mnemonic: "INC HL") { $0.increment(pair: &$0.hl) },
		Opcode(mnemonic: "INC H") { $0.increment(register: &$0.h) },
		Opcode(mnemonic: "DEC H") { $0.decrement(register: &$0.h) },
		Opcode(mnemonic: "LD H, n") { $0.loadOperand(into: &$0.h) },
		Opcode(mnemonic: "DAA") { $0.decimalAdjustAccumulator() },
		Opcode(mnemonic: "JR Z, n") { $0.jumpRelative(condition: $0.flags.contains(.zero)) },
		Opcode(mnemonic: "ADD HL, HL") { $0.add(value: $0.hl, to: &$0.hl) },
		Opcode(mnemonic: "LD A, (HL+)") { $0.loadFromAddressAndIncrementHL(to: &$0.a) },
		Opcode(mnemonic: "DEC HL") { $0.decrement(pair: &$0.hl) },
		Opcode(mnemonic: "INC L") { $0.increment(register: &$0.l) },
		Opcode(mnemonic: "DEC L") { $0.decrement(register: &$0.l) },
		Opcode(mnemonic: "LD L, n") { $0.loadOperand(into: &$0.l) },
		Opcode(mnemonic: "CPL") { $0.complementAccumulator() },
		// 0x3n
		Opcode(mnemonic: "JR NC, n") { $0.jumpRelative(condition: !$0.flags.contains(.fullCarry)) },
		Opcode(mnemonic: "LD SP, nn") { $0.loadOperand(into: &$0.sp) },
		Opcode(mnemonic: "LD (HL-), A") { $0.loadAddressAndDecrementHL(from: $0.a) },
		Opcode(mnemonic: "INC SP") { $0.increment(pair: &$0.sp) },
		Opcode(mnemonic: "INC (HL)") { $0.incrementValue(at: $0.hl) },
		Opcode(mnemonic: "DEC (HL)") { $0.decrementValue(at: $0.hl) },
		Opcode(mnemonic: "LD (HL), n") { $0.loadOperand(into: $0.hl) },
		Opcode(mnemonic: "SCF") { $0.setCarryFlag() },
		Opcode(mnemonic: "JR C, n") { $0.jumpRelative(condition: $0.flags.contains(.fullCarry)) },
		Opcode(mnemonic: "ADD HL, SP") { $0.add(value: $0.sp, to: &$0.hl) },
		Opcode(mnemonic: "LD A, (HL-)") { $0.loadFromAddressAndDecrementHL(to: &$0.a) },
		Opcode(mnemonic: "DEC SP") { $0.decrement(pair: &$0.sp) },
		Opcode(mnemonic: "INC A") { $0.increment(register: &$0.a) },
		Opcode(mnemonic: "DEC A") { $0.decrement(register: &$0.a) },
		Opcode(mnemonic: "LD A, n") { $0.loadOperand(into: &$0.a) },
		Opcode(mnemonic: "CCF") { $0.complementCarryFlag() },
	]
}
