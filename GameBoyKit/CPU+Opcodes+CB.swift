extension CPU {
	static let cbOpcodes: [Opcode] = [
		// Ox0n
		Opcode(mnemonic: "RLC B") { $0.rotateLeftCarry(value: &$0.b) },
		Opcode(mnemonic: "RLC C") { $0.rotateLeftCarry(value: &$0.c) },
		Opcode(mnemonic: "RLC D") { $0.rotateLeftCarry(value: &$0.d) },
		Opcode(mnemonic: "RLC E") { $0.rotateLeftCarry(value: &$0.e) },
		Opcode(mnemonic: "RLC H") { $0.rotateLeftCarry(value: &$0.h) },
		Opcode(mnemonic: "RLC L") { $0.rotateLeftCarry(value: &$0.l) },
		Opcode(mnemonic: "RLC (HL)") { $0.rotateLeftCarry(address: $0.hl) },
		Opcode(mnemonic: "RLC A") { $0.rotateLeftCarry(value: &$0.a) },
		Opcode(mnemonic: "RRC B") { $0.rotateRightCarry(value: &$0.b) },
		Opcode(mnemonic: "RRC C") { $0.rotateRightCarry(value: &$0.c) },
		Opcode(mnemonic: "RRC D") { $0.rotateRightCarry(value: &$0.d) },
		Opcode(mnemonic: "RRC E") { $0.rotateRightCarry(value: &$0.e) },
		Opcode(mnemonic: "RRC H") { $0.rotateRightCarry(value: &$0.h) },
		Opcode(mnemonic: "RRC L") { $0.rotateRightCarry(value: &$0.l) },
		Opcode(mnemonic: "RRC (HL)") { $0.rotateRightCarry(address: $0.hl) },
		Opcode(mnemonic: "RRC A") { $0.rotateRightCarry(value: &$0.a) },
	]
}
