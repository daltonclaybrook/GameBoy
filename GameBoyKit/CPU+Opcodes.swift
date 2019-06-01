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
		// 0x4n
		Opcode(mnemonic: "LD B, B") { $0.load(value: $0.b, into: &$0.b) },
		Opcode(mnemonic: "LD B, C") { $0.load(value: $0.c, into: &$0.b) },
		Opcode(mnemonic: "LD B, D") { $0.load(value: $0.d, into: &$0.b) },
		Opcode(mnemonic: "LD B, E") { $0.load(value: $0.e, into: &$0.b) },
		Opcode(mnemonic: "LD B, H") { $0.load(value: $0.h, into: &$0.b) },
		Opcode(mnemonic: "LD B, L") { $0.load(value: $0.l, into: &$0.b) },
		Opcode(mnemonic: "LD B, (HL)") { $0.load(address: $0.hl, into: &$0.b) },
		Opcode(mnemonic: "LD B, A") { $0.load(value: $0.a, into: &$0.b) },
		Opcode(mnemonic: "LD C, B") { $0.load(value: $0.b, into: &$0.c) },
		Opcode(mnemonic: "LD C, C") { $0.load(value: $0.c, into: &$0.c) },
		Opcode(mnemonic: "LD C, D") { $0.load(value: $0.d, into: &$0.c) },
		Opcode(mnemonic: "LD C, E") { $0.load(value: $0.e, into: &$0.c) },
		Opcode(mnemonic: "LD C, H") { $0.load(value: $0.h, into: &$0.c) },
		Opcode(mnemonic: "LD C, L") { $0.load(value: $0.l, into: &$0.c) },
		Opcode(mnemonic: "LD C, (HL)") { $0.load(address: $0.hl, into: &$0.c) },
		Opcode(mnemonic: "LD C, A") { $0.load(value: $0.a, into: &$0.c) },
		// 0x5n
		Opcode(mnemonic: "LD D, B") { $0.load(value: $0.b, into: &$0.d) },
		Opcode(mnemonic: "LD D, C") { $0.load(value: $0.c, into: &$0.d) },
		Opcode(mnemonic: "LD D, D") { $0.load(value: $0.d, into: &$0.d) },
		Opcode(mnemonic: "LD D, E") { $0.load(value: $0.e, into: &$0.d) },
		Opcode(mnemonic: "LD D, H") { $0.load(value: $0.h, into: &$0.d) },
		Opcode(mnemonic: "LD D, L") { $0.load(value: $0.l, into: &$0.d) },
		Opcode(mnemonic: "LD D, (HL)") { $0.load(address: $0.hl, into: &$0.d) },
		Opcode(mnemonic: "LD D, A") { $0.load(value: $0.a, into: &$0.d) },
		Opcode(mnemonic: "LD E, B") { $0.load(value: $0.b, into: &$0.e) },
		Opcode(mnemonic: "LD E, C") { $0.load(value: $0.c, into: &$0.e) },
		Opcode(mnemonic: "LD E, D") { $0.load(value: $0.d, into: &$0.e) },
		Opcode(mnemonic: "LD E, E") { $0.load(value: $0.e, into: &$0.e) },
		Opcode(mnemonic: "LD E, H") { $0.load(value: $0.h, into: &$0.e) },
		Opcode(mnemonic: "LD E, L") { $0.load(value: $0.l, into: &$0.e) },
		Opcode(mnemonic: "LD E, (HL)") { $0.load(address: $0.hl, into: &$0.e) },
		Opcode(mnemonic: "LD E, A") { $0.load(value: $0.a, into: &$0.e) },
		// 0x6n
		Opcode(mnemonic: "LD H, B") { $0.load(value: $0.b, into: &$0.h) },
		Opcode(mnemonic: "LD H, C") { $0.load(value: $0.c, into: &$0.h) },
		Opcode(mnemonic: "LD H, D") { $0.load(value: $0.d, into: &$0.h) },
		Opcode(mnemonic: "LD H, E") { $0.load(value: $0.e, into: &$0.h) },
		Opcode(mnemonic: "LD H, H") { $0.load(value: $0.h, into: &$0.h) },
		Opcode(mnemonic: "LD H, L") { $0.load(value: $0.l, into: &$0.h) },
		Opcode(mnemonic: "LD H, (HL)") { $0.load(address: $0.hl, into: &$0.h) },
		Opcode(mnemonic: "LD H, A") { $0.load(value: $0.a, into: &$0.h) },
		Opcode(mnemonic: "LD L, B") { $0.load(value: $0.b, into: &$0.l) },
		Opcode(mnemonic: "LD L, C") { $0.load(value: $0.c, into: &$0.l) },
		Opcode(mnemonic: "LD L, D") { $0.load(value: $0.d, into: &$0.l) },
		Opcode(mnemonic: "LD L, E") { $0.load(value: $0.e, into: &$0.l) },
		Opcode(mnemonic: "LD L, H") { $0.load(value: $0.h, into: &$0.l) },
		Opcode(mnemonic: "LD L, L") { $0.load(value: $0.l, into: &$0.l) },
		Opcode(mnemonic: "LD L, (HL)") { $0.load(address: $0.hl, into: &$0.l) },
		Opcode(mnemonic: "LD L, A") { $0.load(value: $0.a, into: &$0.l) },
		// 0x7n
		Opcode(mnemonic: "LD (HL), B") { $0.load(value: $0.b, into: $0.hl) },
		Opcode(mnemonic: "LD (HL), C") { $0.load(value: $0.c, into: $0.hl) },
		Opcode(mnemonic: "LD (HL), D") { $0.load(value: $0.d, into: $0.hl) },
		Opcode(mnemonic: "LD (HL), E") { $0.load(value: $0.e, into: $0.hl) },
		Opcode(mnemonic: "LD (HL), H") { $0.load(value: $0.h, into: $0.hl) },
		Opcode(mnemonic: "LD (HL), L") { $0.load(value: $0.l, into: $0.hl) },
		Opcode(mnemonic: "HALT") { $0.halt() },
		Opcode(mnemonic: "LD (HL), A") { $0.load(value: $0.a, into: $0.hl) },
		Opcode(mnemonic: "LD A, B") { $0.load(value: $0.b, into: &$0.a) },
		Opcode(mnemonic: "LD A, C") { $0.load(value: $0.c, into: &$0.a) },
		Opcode(mnemonic: "LD A, D") { $0.load(value: $0.d, into: &$0.a) },
		Opcode(mnemonic: "LD A, E") { $0.load(value: $0.e, into: &$0.a) },
		Opcode(mnemonic: "LD A, H") { $0.load(value: $0.h, into: &$0.a) },
		Opcode(mnemonic: "LD A, L") { $0.load(value: $0.l, into: &$0.a) },
		Opcode(mnemonic: "LD A, (HL)") { $0.load(address: $0.hl, into: &$0.a) },
		Opcode(mnemonic: "LD A, A") { $0.load(value: $0.a, into: &$0.a) },
		// 0x8n
		Opcode(mnemonic: "ADD A, B") { $0.add(value: $0.b, to: &$0.a) },
		Opcode(mnemonic: "ADD A, C") { $0.add(value: $0.c, to: &$0.a) },
		Opcode(mnemonic: "ADD A, D") { $0.add(value: $0.d, to: &$0.a) },
		Opcode(mnemonic: "ADD A, E") { $0.add(value: $0.e, to: &$0.a) },
		Opcode(mnemonic: "ADD A, H") { $0.add(value: $0.h, to: &$0.a) },
		Opcode(mnemonic: "ADD A, L") { $0.add(value: $0.l, to: &$0.a) },
		Opcode(mnemonic: "ADD A, (HL)") { $0.add(address: $0.hl, to: &$0.a) },
		Opcode(mnemonic: "ADD A, A") { $0.add(value: $0.a, to: &$0.a) },
		Opcode(mnemonic: "ADC A, B") { $0.addWithCarry(value: $0.b, to: &$0.a) },
		Opcode(mnemonic: "ADC A, C") { $0.addWithCarry(value: $0.c, to: &$0.a) },
		Opcode(mnemonic: "ADC A, D") { $0.addWithCarry(value: $0.d, to: &$0.a) },
		Opcode(mnemonic: "ADC A, E") { $0.addWithCarry(value: $0.e, to: &$0.a) },
		Opcode(mnemonic: "ADC A, H") { $0.addWithCarry(value: $0.h, to: &$0.a) },
		Opcode(mnemonic: "ADC A, L") { $0.addWithCarry(value: $0.l, to: &$0.a) },
		Opcode(mnemonic: "ADC A, (HL)") { $0.addWithCarry(address: $0.hl, to: &$0.a) },
		Opcode(mnemonic: "ADC A, A") { $0.addWithCarry(value: $0.a, to: &$0.a) },
		// 0x9n
		Opcode(mnemonic: "SUB B") { $0.subtract(value: $0.b, from: &$0.a) },
		Opcode(mnemonic: "SUB C") { $0.subtract(value: $0.c, from: &$0.a) },
		Opcode(mnemonic: "SUB D") { $0.subtract(value: $0.d, from: &$0.a) },
		Opcode(mnemonic: "SUB E") { $0.subtract(value: $0.e, from: &$0.a) },
		Opcode(mnemonic: "SUB H") { $0.subtract(value: $0.h, from: &$0.a) },
		Opcode(mnemonic: "SUB L") { $0.subtract(value: $0.l, from: &$0.a) },
		Opcode(mnemonic: "SUB (HL)") { $0.subtract(address: $0.hl, from: &$0.a) },
		Opcode(mnemonic: "SUB A") { $0.subtract(value: $0.a, from: &$0.a) },
		Opcode(mnemonic: "SBC A, B") { $0.subtractWithCarry(value: $0.b, from: &$0.a) },
		Opcode(mnemonic: "SBC A, C") { $0.subtractWithCarry(value: $0.c, from: &$0.a) },
		Opcode(mnemonic: "SBC A, D") { $0.subtractWithCarry(value: $0.d, from: &$0.a) },
		Opcode(mnemonic: "SBC A, E") { $0.subtractWithCarry(value: $0.e, from: &$0.a) },
		Opcode(mnemonic: "SBC A, H") { $0.subtractWithCarry(value: $0.h, from: &$0.a) },
		Opcode(mnemonic: "SBC A, L") { $0.subtractWithCarry(value: $0.l, from: &$0.a) },
		Opcode(mnemonic: "SBC A, (HL)") { $0.subtractWithCarry(address: $0.hl, from: &$0.a) },
		Opcode(mnemonic: "SBC A, A") { $0.subtractWithCarry(value: $0.a, from: &$0.a) },
		// 0xan
		Opcode(mnemonic: "AND B") { $0.and(value: $0.b, into: &$0.a) },
		Opcode(mnemonic: "AND C") { $0.and(value: $0.c, into: &$0.a) },
		Opcode(mnemonic: "AND D") { $0.and(value: $0.d, into: &$0.a) },
		Opcode(mnemonic: "AND E") { $0.and(value: $0.e, into: &$0.a) },
		Opcode(mnemonic: "AND H") { $0.and(value: $0.h, into: &$0.a) },
		Opcode(mnemonic: "AND L") { $0.and(value: $0.l, into: &$0.a) },
		Opcode(mnemonic: "AND (HL)") { $0.and(address: $0.hl, into: &$0.a) },
		Opcode(mnemonic: "AND A") { $0.and(value: $0.a, into: &$0.a) },
		Opcode(mnemonic: "XOR B") { $0.xor(value: $0.b, into: &$0.a) },
		Opcode(mnemonic: "XOR C") { $0.xor(value: $0.c, into: &$0.a) },
		Opcode(mnemonic: "XOR D") { $0.xor(value: $0.d, into: &$0.a) },
		Opcode(mnemonic: "XOR E") { $0.xor(value: $0.e, into: &$0.a) },
		Opcode(mnemonic: "XOR H") { $0.xor(value: $0.h, into: &$0.a) },
		Opcode(mnemonic: "XOR L") { $0.xor(value: $0.l, into: &$0.a) },
		Opcode(mnemonic: "XOR (HL)") { $0.xor(address: $0.hl, into: &$0.a) },
		Opcode(mnemonic: "XOR A") { $0.xor(value: $0.a, into: &$0.a) },
		// 0xbn
		Opcode(mnemonic: "OR B") { $0.or(value: $0.b, into: &$0.a) },
		Opcode(mnemonic: "OR C") { $0.or(value: $0.c, into: &$0.a) },
		Opcode(mnemonic: "OR D") { $0.or(value: $0.d, into: &$0.a) },
		Opcode(mnemonic: "OR E") { $0.or(value: $0.e, into: &$0.a) },
		Opcode(mnemonic: "OR H") { $0.or(value: $0.h, into: &$0.a) },
		Opcode(mnemonic: "OR L") { $0.or(value: $0.l, into: &$0.a) },
		Opcode(mnemonic: "OR (HL)") { $0.or(address: $0.hl, into: &$0.a) },
		Opcode(mnemonic: "OR A") { $0.or(value: $0.a, into: &$0.a) },
		Opcode(mnemonic: "CP B") { $0.compare(value: $0.b, with: $0.a) },
		Opcode(mnemonic: "CP C") { $0.compare(value: $0.c, with: $0.a) },
		Opcode(mnemonic: "CP D") { $0.compare(value: $0.d, with: $0.a) },
		Opcode(mnemonic: "CP E") { $0.compare(value: $0.e, with: $0.a) },
		Opcode(mnemonic: "CP H") { $0.compare(value: $0.h, with: $0.a) },
		Opcode(mnemonic: "CP L") { $0.compare(value: $0.l, with: $0.a) },
		Opcode(mnemonic: "CP (HL)") { $0.compare(address: $0.hl, with: $0.a) },
		Opcode(mnemonic: "CP A") { $0.compare(value: $0.a, with: $0.a) },
		// 0xcn
		Opcode(mnemonic: "RET NZ") { $0.return(condition: !$0.flags.contains(.zero)) },
		Opcode(mnemonic: "POP BC") { $0.pop(pair: &$0.bc) },
		Opcode(mnemonic: "JP NZ, nn") { $0.jump(condition: !$0.flags.contains(.zero)) },
		Opcode(mnemonic: "JP nn") { $0.jump() },
		Opcode(mnemonic: "CALL NZ, nn") { $0.call(condition: !$0.flags.contains(.zero)) },
		Opcode(mnemonic: "PUSH BC") { $0.push(pair: $0.bc) },
		Opcode(mnemonic: "ADD A, n") { $0.addOperand(to: &$0.a) },
		Opcode(mnemonic: "RST 0x00") { $0.reset(vector: 0x00) },
		Opcode(mnemonic: "RET Z") { $0.return(condition: $0.flags.contains(.zero)) },
		Opcode(mnemonic: "RET") { $0.return() },
		Opcode(mnemonic: "JP Z, nn") { $0.jump(condition: $0.flags.contains(.zero)) },
		Opcode(mnemonic: "PREFIX CB    4") { $0.nop() }, // todo
		Opcode(mnemonic: "CALL Z, nn") { $0.call(condition: $0.flags.contains(.zero)) },
		Opcode(mnemonic: "CALL") { $0.call() },
		Opcode(mnemonic: "ADC A, n") { $0.addOperandWithCarry(to: &$0.a) },
		Opcode(mnemonic: "RST 0x08") { $0.reset(vector: 0x08) },
		// 0xdn
		Opcode(mnemonic: "RET NC") { $0.return(condition: !$0.flags.contains(.fullCarry)) },
		Opcode(mnemonic: "POP DE") { $0.pop(pair: &$0.de) },
		Opcode(mnemonic: "JP NC, nn    16/12") { $0.jump(condition: !$0.flags.contains(.fullCarry)) },
		Opcode(mnemonic: "UNDEFINED") { $0.undefined() },
		Opcode(mnemonic: "CALL NC, nn") { $0.call(condition: !$0.flags.contains(.fullCarry)) },
		Opcode(mnemonic: "PUSH DE") { $0.push(pair: $0.de) },
		Opcode(mnemonic: "SUB n") { $0.subtractOperand(from: &$0.a) },
		Opcode(mnemonic: "RST 0x10") { $0.reset(vector: 0x10) },
		Opcode(mnemonic: "RET C") { $0.return(condition: $0.flags.contains(.fullCarry)) },
		Opcode(mnemonic: "RETI") { $0.returnEnableInterrupts() },
		Opcode(mnemonic: "JP C, nn") { $0.jump(condition: $0.flags.contains(.fullCarry)) },
		Opcode(mnemonic: "UNDEFINED") { $0.undefined() },
		Opcode(mnemonic: "CALL C, nn") { $0.call(condition: $0.flags.contains(.fullCarry)) },
		Opcode(mnemonic: "UNDEFINED") { $0.undefined() },
		Opcode(mnemonic: "SBC A, n") { $0.subtractOperandWithCarry(from: &$0.a) },
		Opcode(mnemonic: "RST 0x18") { $0.reset(vector: 0x18) },
	]
}
